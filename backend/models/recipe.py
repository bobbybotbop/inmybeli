from backend.models.base import db, DateTime, get_utc_now

class Recipe(db.Model):
    """
    Recipe table stores user recipes
    Each recipe belongs to one creator and can be rated, commented, and saved by others.
    
    Invariants:
    -every recipe must have at least title and creator
    -the ingredients and instructions are stored as JSONs
    """
    __tablename__ = "recipes"

    id = db.Column(db.Integer, primary_key=True)
    creator_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    title = db.Column(db.Text, nullable=False)
    description = db.Column(db.Text, nullable=True)
    recipe_image_url = db.Column(db.Text, nullable=True)
    recipe_image_s3_key = db.Column(db.Text, nullable=True)
    time_minutes = db.Column(db.Integer, nullable=True)
    cuisine = db.Column(db.Text, nullable=True)
    servings = db.Column(db.Integer, nullable=True)

    ingredients = db.Column(db.JSON, nullable=False, default=list)
    instructions = db.Column(db.JSON, nullable=False, default=list)

    created_at = db.Column(DateTime(timezone=True), default=get_utc_now, nullable=False)
    updated_at = db.Column(
        DateTime(timezone=True),
        default=get_utc_now,
        onupdate=get_utc_now,
        nullable=False,
    )

    def __init__(self, **kwargs):
        self.creator_id = kwargs.get("creator_id")
        self.title = kwargs.get("title")
        self.description = kwargs.get("description")
        self.recipe_image_url = kwargs.get("recipe_image_url")
        self.recipe_image_s3_key = kwargs.get("recipe_image_s3_key")
        self.time_minutes = kwargs.get("time_minutes")
        self.cuisine = kwargs.get("cuisine")
        self.servings = kwargs.get("servings")
        self.ingredients = kwargs.get("ingredients", [])
        self.instructions = kwargs.get("instructions", [])

    def serialize(self):
        """Full recipe view"""
        return {
            "id": self.id,
            "creator_id": self.creator_id,
            "title": self.title,
            "description": self.description,
            "recipe_image_url": self.recipe_image_url,
            "time_minutes": self.time_minutes,
            "cuisine": self.cuisine,
            "servings": self.servings,
            "ingredients": self.ingredients,
            "instructions": self.instructions,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def serialize_preview(self, *, total_saves_count=None, friend_saved_profile_picture_urls=None):
        """Recipe preview for feed/discover cards"""
        data = {
            "id": self.id,
            "creator_id": self.creator_id,
            "title": self.title,
            "image_url": self.recipe_image_url,
            "time_minutes": self.time_minutes,
            "cuisine": self.cuisine,
        }
        if total_saves_count is not None:
            data["total_saves_count"] = total_saves_count
        if friend_saved_profile_picture_urls is not None:
            data["friend_saved_profile_picture_urls"] = friend_saved_profile_picture_urls
        return data