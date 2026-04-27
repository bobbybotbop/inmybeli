from datetime import datetime, timedelta, timezone
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import DateTime

db = SQLAlchemy()

def get_utc_now():
    """Return current UTC time"""
    return datetime.now()

from backend.models.user import User
from backend.models.session_token import SessionToken
from backend.models.recipe import Recipe
from backend.models.review import Review

__all__ = ['db', 'datetime', 'timedelta', 'timezone', 'DateTime', 'func', 'get_utc_now', 'User', 'SessionToken', 'Recipe', 'Review']
