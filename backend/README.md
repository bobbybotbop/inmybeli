# inmybeli backend (Flask)

Unprotected (temporary) account endpoints for local development.

## Setup

From `backend/`:

```bash
python -m venv .venv
# Windows PowerShell:
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## Run

From `root`:

```bash
python -m backend.app
```

The server runs on `http://127.0.0.1:5000`.

## API

### Create account

```bash
curl -X POST http://127.0.0.1:5000/api/create ^
  -H "Content-Type: application/json" ^
  -d "{\"name\":\"Bobby\",\"username\":\"bobby1\",\"email\":\"bobby@example.com\",\"password\":\"secret\"}"
```

### Login

```bash
curl -X POST http://127.0.0.1:5000/api/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"bobby@example.com\",\"password\":\"secret\"}"
```

### Get user

```bash
curl http://127.0.0.1:5000/api/users/1
```
