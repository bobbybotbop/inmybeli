# Auth Design: Firebase Auth + SQLAlchemy

This document describes how to bridge **Firebase Authentication** (identity provider) with our **SQLAlchemy-backed application database** (source of truth for app data) for the `inmybeli` iOS + backend project.

> **Assumed stack.** iOS client using the Firebase Auth SDK, Python backend (FastAPI recommended) using `firebase-admin` for token verification and SQLAlchemy 2.x for persistence. Everything below still applies to Flask/Django if you swap the HTTP layer.

---

## 1. Guiding principles

1. **Firebase owns identity, we own the user.**
   Firebase handles credentials, password resets, email verification, OAuth providers (Apple/Google), MFA, and session-token issuance. Our DB stores the *application* view of a user: profile, preferences, relationships, app data, audit trails.
2. **The Firebase UID is the only stable link.** Never key on email — users can change it, and it can collide across providers.
3. **The backend never trusts the client's claim of "who I am."** The client sends a Firebase ID token on every request; the backend verifies it with `firebase-admin` and derives the user from the verified claims.
4. **Just-in-time (JIT) provisioning.** The first time a verified Firebase UID hits the backend, we create the local DB row. No separate "register with our server" endpoint is needed.
5. **Stateless auth on the server.** No server-side sessions, no cookies. The ID token *is* the session. This keeps the iOS + (future web) story simple and horizontally scalable.

---

## 2. High-level flow

```
┌────────────┐     1. sign in (email / Apple / Google)    ┌──────────────┐
│            │ ─────────────────────────────────────────▶ │              │
│  iOS app   │                                            │   Firebase   │
│            │ ◀───────── 2. ID token (JWT) ───────────── │     Auth     │
└─────┬──────┘                                            └──────────────┘
      │
      │ 3. HTTPS request
      │    Authorization: Bearer <ID token>
      ▼
┌────────────────────────────────────────────────────────────────────┐
│ FastAPI backend                                                    │
│                                                                    │
│  a. verify_id_token()  ──▶ firebase-admin SDK (checks sig, exp,    │
│                             audience, issuer, revocation)          │
│  b. get_or_create_user(uid, claims)  ──▶ SQLAlchemy                │
│  c. attach `current_user` to the request                           │
│  d. execute business logic                                         │
└────────────────────────────────────────────────────────────────────┘
```

### Step-by-step

1. **iOS** performs the auth flow via the Firebase SDK (`Auth.auth().signIn(...)` or Sign in with Apple via Firebase). The SDK stores the refresh token securely in the Keychain and hands us a short-lived (≈1 hour) **ID token**.
2. **iOS** attaches `Authorization: Bearer <idToken>` to every backend request. Before each request, it calls `currentUser?.getIDToken(forcingRefresh: false)` — the SDK silently refreshes if needed.
3. **Backend** verifies the token with `firebase-admin`, runs JIT provisioning, and proceeds.
4. On logout, iOS calls `Auth.auth().signOut()`. The backend is stateless, so no server call is required — but we *can* call `revokeRefreshTokens(uid)` from an admin endpoint if we need to force-invalidate sessions (e.g. account compromise).

---

## 3. Database model

Keep the `users` table minimal and stable. Push mutable profile data into a sibling table if you expect a lot of churn.

```python
# backend/app/models/user.py
from datetime import datetime
from sqlalchemy import String, DateTime, Boolean, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db import Base

class User(Base):
    __tablename__ = "users"

    # Internal surrogate key — use this for all FKs inside our DB.
    id: Mapped[int] = mapped_column(primary_key=True)

    # Firebase UID — the bridge. Immutable, unique, indexed.
    firebase_uid: Mapped[str] = mapped_column(String(128), unique=True, index=True, nullable=False)

    # Denormalized snapshots from Firebase claims. Treat as *cache*, not source of truth.
    email: Mapped[str | None] = mapped_column(String(320), index=True)
    email_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    display_name: Mapped[str | None] = mapped_column(String(255))
    photo_url: Mapped[str | None] = mapped_column(String(1024))
    provider: Mapped[str | None] = mapped_column(String(64))  # "password" | "apple.com" | "google.com" | ...

    # Our own app-level fields
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    disabled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
```

### Why two IDs (`id` + `firebase_uid`)?

- `firebase_uid` is the identity anchor. It's what Firebase gives us and what we verify on every request.
- Internal integer `id` keeps FKs small, keeps Firebase as a swappable implementation detail, and avoids leaking provider IDs into URLs or joins.
- Public-facing references to a user (API URLs, share links) should use a separate `public_id` (UUID or short slug) so you never expose either of the above.

### What *not* to store

- **Passwords, password hashes, password reset tokens.** Firebase handles this.
- **Firebase ID tokens or refresh tokens.** They're short-lived / bearer credentials; storing them is a liability.
- **MFA secrets, phone numbers for 2FA.** Live in Firebase.

---

## 4. Backend: token verification + JIT provisioning

### 4.1 Initialize the Admin SDK once at boot

```python
# backend/app/auth/firebase.py
import firebase_admin
from firebase_admin import credentials, auth as fb_auth
from app.config import settings

_app: firebase_admin.App | None = None

def init_firebase() -> None:
    global _app
    if _app is not None:
        return
    cred = credentials.Certificate(settings.firebase_service_account_path)
    _app = firebase_admin.initialize_app(cred)

def verify_id_token(token: str, check_revoked: bool = True) -> dict:
    # Raises on expired, revoked, tampered, or wrong-audience tokens.
    return fb_auth.verify_id_token(token, check_revoked=check_revoked)
```

Pass a service account JSON via an environment-mounted secret (never commit it). In production on GCP/Cloud Run, use Application Default Credentials instead of a key file.

### 4.2 FastAPI dependency

```python
# backend/app/auth/deps.py
from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.orm import Session
from firebase_admin import auth as fb_auth

from app.auth.firebase import verify_id_token
from app.db import get_db
from app.models.user import User

def get_current_user(
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> User:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()

    try:
        claims = verify_id_token(token)
    except fb_auth.RevokedIdTokenError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token revoked; please sign in again")
    except fb_auth.ExpiredIdTokenError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token expired")
    except (fb_auth.InvalidIdTokenError, ValueError):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid token")

    user = get_or_create_user(db, claims)
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Account disabled")
    return user
```

### 4.3 JIT provisioning + profile sync

```python
# backend/app/auth/provisioning.py
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from sqlalchemy.dialects.postgresql import insert as pg_insert
from app.models.user import User

def get_or_create_user(db: Session, claims: dict) -> User:
    uid = claims["uid"]

    # Single-statement upsert avoids race conditions when two concurrent
    # requests from a brand-new user hit us at the same time.
    stmt = (
        pg_insert(User)
        .values(
            firebase_uid=uid,
            email=claims.get("email"),
            email_verified=bool(claims.get("email_verified", False)),
            display_name=claims.get("name"),
            photo_url=claims.get("picture"),
            provider=(claims.get("firebase", {}).get("sign_in_provider")),
        )
        .on_conflict_do_nothing(index_elements=["firebase_uid"])
        .returning(User)
    )
    db.execute(stmt)

    user = db.query(User).filter(User.firebase_uid == uid).one()

    # Keep denormalized fields fresh, but cheaply.
    dirty = False
    for attr, key in [
        ("email", "email"),
        ("display_name", "name"),
        ("photo_url", "picture"),
    ]:
        new = claims.get(key)
        if new is not None and getattr(user, attr) != new:
            setattr(user, attr, new); dirty = True

    if bool(claims.get("email_verified", False)) != user.email_verified:
        user.email_verified = bool(claims["email_verified"]); dirty = True

    user.last_seen_at = datetime.now(timezone.utc)
    if dirty:
        db.add(user)
    db.commit()
    return user
```

Notes:

- The `ON CONFLICT DO NOTHING` + select is the standard SQLAlchemy/Postgres pattern to make JIT creation idempotent under concurrency. On SQLite/MySQL use `INSERT ... ON DUPLICATE KEY UPDATE` or a `SELECT ... FOR UPDATE` + insert inside a transaction.
- `last_seen_at` on every request is one write per request. If that's too hot, only update when it's more than N minutes stale, or push it to a background queue.

### 4.4 Using it in a route

```python
@app.get("/me")
def me(user: User = Depends(get_current_user)):
    return {"id": user.id, "email": user.email, "display_name": user.display_name}
```

---

## 5. Keeping Firebase and the DB in sync

Two directions to worry about:

### 5.1 Firebase → DB

- **Read-through on every request.** Already handled by JIT provisioning above. Good enough for most fields.
- **Out-of-band changes** (user deleted in Firebase console, email changed via password reset, account disabled) won't reach us until the user makes another request. If that's acceptable, stop here.
- **Push-based sync (optional).** Wire up Firebase **Auth blocking functions** or **Cloud Functions** triggered on `user.onDelete` / `user.onCreate` to call a privileged backend webhook. Secure it with a shared secret or OIDC. Use this when:
  - You need to hard-delete app data when a user is deleted (GDPR / right-to-be-forgotten).
  - You need to provision related rows *before* the user makes their first request.

### 5.2 DB → Firebase

Rare, but useful. Use the Admin SDK:

- **Disable / re-enable:** `fb_auth.update_user(uid, disabled=True)` from an admin panel.
- **Force sign-out everywhere:** `fb_auth.revoke_refresh_tokens(uid)` — combined with `check_revoked=True` in `verify_id_token`, every device is kicked on its next refresh.
- **Custom claims for roles:** `fb_auth.set_custom_user_claims(uid, {"role": "admin"})`. Claims flow into the ID token and can be read by the client (to show/hide UI) and by the backend (as a fast-path check before hitting the DB). Keep payload < 1000 bytes.

> **Role of truth.** For anything more than a coarse role flag, keep authorization data (roles, permissions, org membership) in **our DB**, not custom claims. Custom claims require a token refresh to propagate; DB checks are instant.

---

## 6. Client responsibilities (iOS)

- Use the Firebase iOS SDK; never roll your own token handling.
- On every outgoing request, call `currentUser?.getIDToken(forcingRefresh: false)` and set the `Authorization` header. The SDK caches and refreshes transparently.
- On **401 from backend**, retry exactly once with `forcingRefresh: true`. If it still 401s, sign the user out locally.
- Store nothing auth-related in `UserDefaults`. Firebase already persists the refresh token in the Keychain.
- When the user deletes their account, call `currentUser?.delete()` **after** you've confirmed the backend purge succeeded — otherwise you'll have orphan DB rows tied to a UID that no longer exists.

---

## 7. Security checklist

- **Always verify tokens** server-side. Never trust `uid` or `email` passed in a request body or header.
- **Enforce HTTPS** end-to-end; ID tokens are bearer credentials.
- **Set `check_revoked=True`** on verification if you care about forced sign-out; it costs one extra network call to Firebase but is cached.
- **Validate audience/issuer** — `firebase-admin` does this by default against your project ID. Double-check `GOOGLE_CLOUD_PROJECT` / `FIREBASE_PROJECT_ID` is set in the environment.
- **Rate-limit `/auth/*` and unauthenticated endpoints** independently from authenticated ones; login endpoints are abuse targets even though Firebase handles the heavy lifting.
- **Require email verification** for sensitive flows: check `claims["email_verified"]` in a dependency (`require_verified_user`) and gate accordingly.
- **Log the `uid`, not the email**, in audit logs. Emails change; UIDs don't.
- **Rotate service account keys** on a schedule, or switch to workload identity / ADC in production.
- **Treat custom claims as public.** They're in a JWT that the client can decode.

---

## 8. Testing strategy

- **Unit tests:** mock `verify_id_token` to return canned claims. Exercise JIT provisioning, upsert idempotency, and the disabled-account path.
- **Integration tests:** point `firebase-admin` at the **Auth Emulator** (`FIREBASE_AUTH_EMULATOR_HOST=localhost:9099`) and mint real tokens in tests. This catches signature/audience/issuer bugs that mocks hide.
- **Contract test with iOS:** in CI, run the backend against the emulator and have an iOS UI test sign in, hit `/me`, and assert the row exists.

---

## 9. Open questions / decisions to make

- [ ] Confirm backend framework (FastAPI vs Flask vs Django). This doc assumes FastAPI.
- [ ] Choose the DB engine (Postgres strongly recommended for the `ON CONFLICT` upsert pattern).
- [ ] Decide whether we need Auth blocking functions for pre-signup validation (e.g. invite-only launch).
- [ ] Decide on the `last_seen_at` update policy (every request vs throttled vs queued).
- [ ] Define the account-deletion flow (who deletes first — Firebase or the DB — and what happens on partial failure).
- [ ] Decide how roles/permissions are represented (DB table vs custom claims vs both).

---

## 10. Minimal reference layout

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app, wires init_firebase() on startup
│   ├── config.py               # pydantic-settings: firebase_service_account_path, db url, ...
│   ├── db.py                   # SQLAlchemy engine, SessionLocal, Base, get_db()
│   ├── auth/
│   │   ├── firebase.py         # init_firebase, verify_id_token
│   │   ├── deps.py             # get_current_user, require_verified_user
│   │   └── provisioning.py     # get_or_create_user
│   ├── models/
│   │   └── user.py
│   └── routes/
│       └── users.py            # /me, /users/{id}, ...
├── migrations/                 # alembic
└── pyproject.toml
```

That's the whole loop: **Firebase verifies who you are, SQLAlchemy remembers what you do, and the Firebase UID is the only thread connecting them.**
