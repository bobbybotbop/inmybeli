from backend.models.base import db, DateTime, get_utc_now

class Friendship(db.Model):
    """
    Association object set as user between each other. It stores the user_id, friend_id, and status (invariant is that it is only pending, accepted, blocked)
    
    Invariants:
    - Exactly one friendship record per user pair
    - A user cannot be friends with themself
    - Status is one of: pending, accepted, blocked
    - User id is always less than Friends id
    - requester id must always be either user id or receiver id
    """
    __tablename__ = 'friendships'
    
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), primary_key=True)
    friend_id = db.Column(db.Integer, db.ForeignKey('users.id'), primary_key=True)
    status = db.Column(db.String(20), default='pending')  # pending, accepted, blocked
    created_at = db.Column(DateTime(timezone=True), default=get_utc_now)
    requester_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)

    __table_args__ = (
        db.CheckConstraint('user_id != friend_id', name='not_reflexive'),
        db.CheckConstraint('user_id < friend_id', name='user_less_than_friend'),  # Add this
        db.UniqueConstraint('user_id', 'friend_id', name='unique_friendship'),
        db.CheckConstraint('requester_id IN (user_id, friend_id)', name='requester_is_pair_member'),
    )

    user = db.relationship('User', foreign_keys=[user_id], backref='friendships_as_user')
    friend = db.relationship('User', foreign_keys=[friend_id], backref='friendships_as_friend')
    requester = db.relationship('User', foreign_keys=[requester_id], backref='friendships_as_requester')

    def __init__(self, **kwargs):
        user_id = kwargs.get("user_id")
        friend_id = kwargs.get("friend_id")
        requester_id = kwargs.get("requester_id")
        
        if user_id == friend_id:
            raise ValueError("Cannot be friends with yourself")
        
        # Enforce user_id < friend_id
        if user_id > friend_id:
            user_id, friend_id = friend_id, user_id

        if requester_id not in (user_id, friend_id):
            raise ValueError("Requester must be one of the two users in the friendship")
        
        self.user_id = user_id
        self.friend_id = friend_id
        self.requester_id = requester_id
