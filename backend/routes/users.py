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
    g,
    delete_from_s3,
    upload_to_s3,
    DEFAULT_PFP
)


users_bp = Blueprint("users", __name__)

@users_bp.post("/create")
@users_bp.post("/create/")
def create_account():
    """Endpoint for creating account"""   
    schema = CreateAccountSchema()

    try:
        raw_data = request.form.to_dict() 
        form_data = schema.load(raw_data)
    except ValidationError as err:
        return error(err.messages, 400)

    file = request.files.get("profile_picture")

    uploaded_s3_key = None
    profile_picture_url = DEFAULT_PFP

    if file:
        try:
            s3_result = upload_to_s3(file, folder="pfp/")
            if not s3_result["success"]:
                msg = s3_result.get("error") or "Failed to upload profile picture"
                return error(msg, 500)

            uploaded_s3_key = s3_result["s3_key"]
            profile_picture_url = s3_result["s3_url"]

        except Exception as e:
            return error(f"Upload error: {str(e)}", 500)

    try:
        user = User(
            name=form_data["name"],
            username=form_data["username"],
            password_hash=generate_password_hash(form_data["password"]),
            profile_picture_url=profile_picture_url,
            profile_picture_s3_key=uploaded_s3_key,
        )

        db.session.add(user)
        db.session.flush()

        session = SessionToken(
            token=generate_token(),
            user_id=user.id,
        )

        db.session.add(session)
        db.session.commit()

    except IntegrityError:
        db.session.rollback()
        if uploaded_s3_key:
            delete_from_s3(uploaded_s3_key)
        return error("Username already exists", 400)

    except Exception as e:
        db.session.rollback()
        if uploaded_s3_key:
            delete_from_s3(uploaded_s3_key)
        return error(f"Account creation failed: {str(e)}", 500)

    return success(
        {
            "user": user.serialize(),
            "session_token": session.token,
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