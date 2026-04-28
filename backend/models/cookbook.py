from backend.models import db, cookbookRecipes

class Cookbook(db.Model):
    """
    Cookbook table stores cookbook
    Each cookbook has name, description, list of recipes, and number of friends saving it
    
    Invariants:
    - every cookbook must refer to a valid recipe in the database
    """
    __tablename__ = "cookbooks"

    id = db.Column(db.Integer, primary_key=True)
    creator_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)

    name = db.Column(db.Text, nullable=False)
    description = db.Column(db.Text, nullable=True)

    recipes = db.relationship(
        'Recipe',
        secondary=cookbookRecipes,
        backref='cookbooks',
        lazy='dynamic'
    )

    def __init__(self, **kwargs):        
        self.name = kwargs.get("name")
        self.description = kwargs.get("description")


    def serialize(self):
        """Full cookbook view"""
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "recipes": [r.serialize_preview() for r in self.recipes],
        }
    
    def simple_serialize(self):
        """Partial cookbook view"""
        return {
            "id": self.id,
            "name" : self.name, 
            "description" : self.description
        }