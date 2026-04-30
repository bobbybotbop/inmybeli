from backend.models.base import db, DateTime, get_utc_now
from backend.models.friendship import Friendship

class User(db.Model):
    """
    Users table stores the users information: name, password_hash, username, creation date, friends, recipes, and cookbooks. It has a one to many relationship to the session tables.

    Invariants:
    - for all users, they must all contain a unique username
    """
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)

    password_hash = db.Column(db.Text, nullable=False)
    name = db.Column(db.Text, nullable=False)
    username = db.Column(db.Text, unique=True, index=True, nullable=False)
    profile_picture_url = db.Column(db.Text, nullable = False)
    created_at = db.Column(DateTime(timezone=True), default=get_utc_now, nullable=False)
    cookbooks = db.relationship('Cookbook', backref='user', cascade='all, delete-orphan')
    profile_picture_s3_key = db.Column(db.Text, nullable = True)

    # delete tokens when user is deleted.
    tokens = db.relationship('SessionToken', cascade="all, delete-orphan", backref='user')

    def __init__(self, **kwargs):
        """Initialize a user with password_hash, name, and username"""
        self.password_hash = kwargs.get("password_hash")
        self.name = kwargs.get("name")
        self.username = kwargs.get("username")
        self.profile_picture_url = kwargs.get("profile_picture_url")
        self.profile_picture_s3_key = kwargs.get("profile_picture_s3_key")

    def _get_friendship_with(self, friend):
        """
        Returns friendship status and the direct comparison value of both user ids
        """
        smaller_id = min(self.id, friend.id)
        larger_id = max(self.id, friend.id)
        
        friendship = Friendship.query.filter_by(
            user_id=smaller_id,
            friend_id=larger_id
        ).first()
        
        is_current_user_smaller = self.id < friend.id
        return friendship, is_current_user_smaller

    def send_friend_request(self, friend):
        """
        Send friend request to another user.
        """
        friendship, _ = self._get_friendship_with(friend)
        
        if friendship:
            if friendship.status == 'accepted':
                raise ValueError("Already friends with this user")
            elif friendship.status == 'blocked':
                raise ValueError("This user has blocked you")
            else:
                raise ValueError("Friend request already sent")
        
        # Create new friendship with enforced ordering
        smaller_id = min(self.id, friend.id)
        larger_id = max(self.id, friend.id)
        
        new_friendship = Friendship(
            user_id=smaller_id, 
            friend_id=larger_id, 
            requester_id=self.id,
            status='pending'
        )
        db.session.add(new_friendship)
    
    def accept_friend_request(self, friend):
        """
        Accept a pending friend request from another user.
        """
        friendship, _ = self._get_friendship_with(friend)
        
        if not friendship:
            raise ValueError("No friendship record found")
        
        if friendship.status == 'accepted':
            raise ValueError("Already friends with this user")
        elif friendship.status == 'blocked':
            raise ValueError("This user has blocked you")
        elif friendship.status != 'pending':
            raise ValueError("Invalid friendship status")
        
        if friendship.requester_id == self.id:
            raise ValueError("You can only accept requests sent to you")
        
        friendship.status = 'accepted'
    
    def get_friends(self):
        """Get all accepted friends"""
        # get all where user id is smaller than friend id
        initiated = Friendship.query.filter_by(
            user_id=self.id,
            status='accepted'
        ).all()
        friends_from_initiated = [f.friend for f in initiated]
        
        # Get all accepted friendships where this user is friend_id (larger)
        received = Friendship.query.filter_by(
            friend_id=self.id,
            status='accepted'
        ).all()
        friends_from_received = [f.user for f in received]
        
        # return both
        return (friends_from_initiated + friends_from_received)
    
    def get_pending_recieved_requests(self):
        """Get pending friend requests recieved by you"""
        received = Friendship.query.filter(
            db.or_(Friendship.user_id == self.id, Friendship.friend_id == self.id),
            Friendship.status == 'pending',
            Friendship.requester_id != self.id
        ).all()

        requesters = [f.requester for f in received]
        return requesters
    
    def get_pending_sent_requests(self):
        """Get pending friend requests sent to you"""
        sent = Friendship.query.filter(
            Friendship.requester_id == self.id,
            Friendship.status == 'pending'
        ).all()

        receivers = []
        for f in sent:
            other_user = f.friend if f.user_id == self.id else f.user
            receivers.append(other_user)
        
        return receivers
    
    def is_friends_with(self, friend):
        """Return status of friend between two users"""
        friendship, _ = self._get_friendship_with(friend)
        
        if not friendship:
            return "None"
        
        return friendship.status
        
    def serialize(self):
        """Serialize user to dictionary."""
        return {
            "id": self.id,
            "name": self.name,
            "username": self.username,
            "profile_url" : self.profile_picture_url,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }