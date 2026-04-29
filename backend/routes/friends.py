from backend.routes.dependencies import (
    Blueprint,
    request,
    db,
    User,
    Friendship,
    error,
    success,
    require_auth,
    ValidationError,
    FriendRequestSchema,
    g
)

friends_bp = Blueprint("friends", __name__)

@friends_bp.get("/")
@require_auth
def get_friends():
    """
    Get all the friends for user
    """    
    friends = g.user.get_friends()

    return success(
        {
        "user_id": g.user.id,
        "friends": [{"id": f.id, "username": f.username} for f in friends]
        }, 200
    )


@friends_bp.get("/pending/received/")
@require_auth
def get_pending_received():
    """
    Get all receieved requests to be friends
    """
    pending_users = g.user.get_pending_recieved_requests()

    return success({
        "user_id": g.user.id,
        "received_pending_requests": [
            {"id": u.id, "username": u.username, "name": u.name}
            for u in pending_users
        ]
    }, 200)

@friends_bp.get("/pending/sent/")
@require_auth
def get_pending_sent():
    """
    Get all sent requests to be friends
    """
    pending_users = g.user.get_pending_sent_requests()

    return success({
        "user_id": g.user.id,
        "sent_pending_requests": [
            {"id": u.id, "username": u.username, "name": u.name}
            for u in pending_users
        ]
    }, 200)

@friends_bp.get("/search/<string:name>")
@require_auth
def search_users(name):
    """
    Returns top 20 users that start with specified string
    """
    results = User.query.filter(
        User.username.ilike(f"%{name}%")
    ).all()
    
    return success({'results': [r.serialize() for r in results]}, 200)

@friends_bp.post("/request/")
@require_auth
def send_friend_request():
    """
    Send a friend request to the user
    """
    schema = FriendRequestSchema()
 
    try:
        data = schema.load(request.get_json(silent=True) or {})
    except ValidationError as err:
        return error(err.messages, 400)
 
    friend_id = data["friend_id"]
 
    if g.user.id == friend_id:
        return error("Cannot be friends with yourself", 400)
 
    friend = User.query.get(friend_id)
 
    if not friend:
        return error("Friend not found", 404)
 
    try:
        g.user.send_friend_request(friend)
        db.session.commit()
    except ValueError as err:
        return error(str(err), 400)
    
    return success({'success': True, 'message': 'Friend request sent'}, 201)


@friends_bp.post("/accept/")
@require_auth
def accept_friend_request():
    """
    Accepting a friend request to the user
    """
    schema = FriendRequestSchema()

    try:
        data = schema.load(request.get_json(silent=True) or {})
    except ValidationError as err:
        return error(err.messages, 400)
    
    friendId = data["friend_id"]
    
    if g.user.id == friendId:
        return error("Cannot be friends with yourself", 400)
    
    friend = User.query.get(friendId)
    if not friend:
        return error("Friend not found", 404)
    
    try:
        g.user.accept_friend_request(friend)
        db.session.commit()
    except ValueError as err:
        return error(str(err), 400)
    
    return success({'success': True, 'message': 'Friend request accepted'}, 200)


@friends_bp.delete('/<int:friend_id>/')
@require_auth
def remove_friend(friend_id):
    """
    Delete a friend
    """
    if g.user.id == friend_id:
        return error("Cannot remove yourself", 400)
    
    friend = User.query.get(friend_id)
    if not friend:
        return error("Friend not found", 404)
    
    # Get friendship with enforced ordering (user_id < friend_id)
    smaller_id = min(g.user.id, friend_id)
    larger_id = max(g.user.id, friend_id)
    
    friendship = Friendship.query.filter_by(
        user_id=smaller_id,
        friend_id=larger_id,
        status='accepted'
    ).first()
    
    if not friendship:
        return error("Friendship not found", 404)
    
    db.session.delete(friendship)
    db.session.commit()
    
    return success({'success': True, 'message': 'Friend removed'}, 200)


@friends_bp.get('/<int:friend_id>/')
@require_auth
def check_status(friend_id):
    """
    Returns status of relation between two users
    """
    if g.user.id == friend_id:
        return error("Cannot check friendship with yourself", 400)
    
    friend = User.query.get(friend_id)
    if not friend:
        return error("Friend not found", 404)
    
    # Use the helper method from User model
    is_friend = g.user.is_friends_with(friend)
    
    return success({'user_id': g.user.id, 'friend_id': friend_id, 'is_friend': is_friend}, 200)

@friends_bp.post("/decline/")
@require_auth
def decline_friend_request():
    """
    Decline a pending friend request
    """
    schema = FriendRequestSchema()
 
    try:
        data = schema.load(request.get_json(silent=True) or {})
    except ValidationError as err:
        return error(err.messages, 400)
    
    friend_id = data["friend_id"]
    
    if g.user.id == friend_id:
        return error("Cannot decline your own request", 400)
    
    friend = User.query.get(friend_id)
    if not friend:
        return error("Friend not found", 404)
    
    # Get friendship with enforced ordering
    smaller_id = min(g.user.id, friend_id)
    larger_id = max(g.user.id, friend_id)
    
    friendship = Friendship.query.filter_by(
        user_id=smaller_id,
        friend_id=larger_id,
        status='pending'
    ).first()
    
    if not friendship:
        return error("No pending friend request found", 404)
    
    # Can only decline if you are NOT the requester
    if friendship.requester_id == g.user.id:
        return error("You can only decline requests sent to you", 400)
    
    db.session.delete(friendship)
    db.session.commit()
    
    return success({'success': True, 'message': 'Friend request declined'}, 200)