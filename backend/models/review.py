from backend.models import db, DateTime, get_utc_now

class Review(db.Model):
    """
    Review table stores user reviews recipes
    This includes a star rating out of five, and optional text
    One review per user per recipe and when a user updates a review
    it overwrites the existing row instead of creating a new one.

    Invariants:
    - rating is int 1 to 5
    - (user_id, recipe_id) is unique
    """
    __tablename__ = "reviews"

    id = db.Column(db.Integer, primary_key=True)

    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    recipe_id = db.Column(db.Integer, db.ForeignKey('recipes.id'), nullable=False, index=True)
    rating = db.Column(db.Integer, nullable=False)
    text = db.Column(db.Text, nullable=True)
    created_at = db.Column(DateTime(timezone=True), default=get_utc_now, nullable=False)
    updated_at = db.Column(
        DateTime(timezone=True),
        default=get_utc_now,
        onupdate=get_utc_now,
        nullable=False,
    )

    __table_args__ = (
        db.UniqueConstraint('user_id', 'recipe_id', name='uq_review_user_recipe'),
    )

    def __init__(self, **kwargs):
        self.user_id = kwargs.get("user_id")
        self.recipe_id = kwargs.get("recipe_id")
        self.rating = kwargs.get("rating")
        self.text = kwargs.get("text")

    def serialize(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "recipe_id": self.recipe_id,
            "rating": self.rating,
            "text": self.text,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }