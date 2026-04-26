from backend.models import db, DateTime, timedelta, get_utc_now

class SessionToken(db.Model):
    """
    Session Tokens table that stores the token itself, expiration date, user id, and creation time. This table has a many to one relationship to user id. 

    Invariants:
    - a user may only have one valid token at all times. Valid is defined as a token that has not been expired.
    """
    __tablename__ = "session_tokens"

    id = db.Column(db.Integer, primary_key=True)

    token = db.Column(db.Text, unique=True, nullable=False)
    expiresAt = db.Column(db.DateTime, nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), unique = True, nullable=False)
    created_at = db.Column(DateTime(timezone=True), default=get_utc_now, nullable=False)

    def __init__(self, **kwargs):
        """Initialize a session token with token, user_id, and optional expires_in_hours."""
        self.token = kwargs.get("token")
        self.user_id = kwargs.get("user_id")
        
        # allow for custom expiration
        expires_in_hours = kwargs.get("expires_in_hours", 24)
        self.expiresAt = get_utc_now() + timedelta(hours=expires_in_hours)

    def serialize(self):
        """Serialize session token to dictionary."""
        return {
            "id": self.id,
            "token": self.token,
            "user_id": self.user_id,
            "expiresAt": self.expiresAt.isoformat() if self.expiresAt else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

    def is_valid(self):
        """Check if the session token is still valid (not expired)."""
        return get_utc_now() < self.expiresAt
