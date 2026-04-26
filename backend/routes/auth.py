from flask import Blueprint, request
from werkzeug.security import check_password_hash, generate_password_hash
from sqlalchemy.exc import IntegrityError

from backend.models import User, SessionToken, db
from backend.utils import error, success, generate_token
from backend.schemas import CreateAccountSchema, LoginSchema, AutoLoginSchema

from marshmallow import ValidationError


auth_bp = Blueprint("auth", __name__)

@auth_bp.post("/create")
def create_account():
    """
    Create a new user account
    """
    schema = CreateAccountSchema()

    try:
        data = schema.load(request.get_json(silent=True) or {})
    except ValidationError as err:
        return error(err.messages, 400)

    user = User(
        name=data["name"],
        username=data["username"],
        password_hash=generate_password_hash(data["password"]),
    )
    db.session.add(user)
    
    try:
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        return error("Username already exists", 400)
    
    # create token session
    session = SessionToken(token=generate_token(), user_id = user.id)
    db.session.add(session)
    db.session.commit()

    return success(
        {
            "user" : user.serialize(), 
            "session_token" : session.token 
        },
        201,
    )

@auth_bp.post("/login")
def login():
    """
    Login a user with username and password.
    """
    schema = LoginSchema()

    try:
        data = schema.load(request.get_json(silent=True) or {})
    except ValidationError as err:
        return error(err.messages, 400)

    username = data["username"]
    password = data["password"]

    user = User.query.filter_by(username=username).first()

    if user is None or not check_password_hash(user.password_hash, password):
        return error("Invalid credentials", 401)

    # Delete any existing session tokens user is using
    SessionToken.query.filter_by(user_id=user.id).delete()
    
    # create token session
    session = SessionToken(token=generate_token(), user_id = user.id)
    db.session.add(session)
    db.session.commit()

    return success(
        {
            "success": True,
            "user" : user.serialize(),
            "token" : session.token
        }
    )

@auth_bp.post("/autologin")
def auto_login():
    """
    Automatically login in a user with session tokens
    """
    schema = AutoLoginSchema()

    try:
        data = schema.load(request.get_json(silent=True) or {})
    except ValidationError as err:
        return error(err.messages, 400)

    token = data["token"]
    session = SessionToken.query.filter_by(token=token).first()

    if session is None or not (session.is_valid()):
        return error("Invalid credentials", 401)

    user = User.query.filter_by(id=session.id).first()

    if user is None:
        return error("Something went wrong on the backend", 500)
    
    return success(
        {
            "success": True,
            "user" : user.serialize(),
            "token" : session.token
        }
    )
