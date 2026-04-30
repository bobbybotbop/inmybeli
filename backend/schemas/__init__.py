"""
Schemas package containing all request/response validation schemas
"""
from backend.schemas.users import CreateAccountSchema, LoginSchema, AutoLoginSchema
from backend.schemas.friends import FriendRequestSchema
from backend.schemas.cookbooks import CreateCookbookSchema, UpdateCookbookSchema, AddRecipeToCookbookSchema
from backend.schemas.recipes import CreateRecipeSchema, UpdateRecipeSchema
from backend.schemas.reviews import CreateReviewSchema

__all__ = [
    "CreateAccountSchema",
    "LoginSchema",
    "AutoLoginSchema",
    "FriendRequestSchema",
    "CreateCookbookSchema",
    "UpdateCookbookSchema",
    "AddRecipeToCookbookSchema",
    "CreateRecipeSchema",
    "UpdateRecipeSchema",
    "CreateReviewSchema",
]