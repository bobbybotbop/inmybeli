"""
Routes package: Exposes only the Blueprints for app registration.
"""
from backend.routes.users import users_bp
from backend.routes.friends import friends_bp
from backend.routes.cookbooks import cookbooks_bp
from backend.routes.recipes import recipes_bp

__all__ = ["users_bp", "friends_bp", "cookbooks_bp", "recipes_bp"]