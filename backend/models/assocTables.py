from backend.models import db

"""
Represent many to many relationship between the recipes and cookbooks. 
"""
cookbookRecipes = db.Table(
    "cookbook_recipes",
    db.Model.metadata,
    db.Column("cookbook_id", db.Integer, db.ForeignKey("cookbooks.id")),
    db.Column("recipe_id", db.Integer, db.ForeignKey("recipes.id")),
    extend_existing=True
)