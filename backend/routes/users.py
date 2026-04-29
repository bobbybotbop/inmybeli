from backend.routes.dependencies import (
    Blueprint, 
    request, 
    check_password_hash, 
    generate_password_hash, 
    IntegrityError, 
    ValidationError,
    User,
    SessionToken,
    db,
    error,
    success,
    generate_token,
    CreateAccountSchema,
    LoginSchema,
    AutoLoginSchema,
    require_auth,
    g
)

users_bp = Blueprint("users", __name__)

@users_bp.post("/create/")
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

@users_bp.post("/login/")
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
    SessionToken.query.filter_by(user_id = user.id).delete()
    
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

@users_bp.post("/autologin/")
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

    user = User.query.filter_by(id=session.user_id).first()

    if user is None:
        return error("Something went wrong on the backend", 500)
    
    return success(
        {
            "success": True,
            "user" : user.serialize(),
            "token" : session.token
        }
    )

@users_bp.get("/")
@require_auth
def get_user():
    """
    Get user information by user_id.
    
    Path params:
        user_id: int - The ID of the user to retrieve
    """

    return success(
        g.user.serialize(), 200
    )
 
@users_bp.route('/tokens', methods=['GET'])
def get_all_tokens():
    tokens = SessionToken.query.all()
    return success({"tokens" : [token.serialize() for token in tokens]}, 200)