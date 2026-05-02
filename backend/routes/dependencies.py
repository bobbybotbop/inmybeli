"""
Dependencies toolbox for route files.
"""
from flask import Blueprint, request, g, jsonify
from werkzeug.security import check_password_hash, generate_password_hash
from sqlalchemy.exc import IntegrityError
from marshmallow import ValidationError
from backend.models import User, SessionToken, db, Friendship, Cookbook, Recipe, Review
from backend.utils import error, success, generate_token, upload_to_s3, delete_from_s3, allowed_file
from backend.configs import DEFAULT_PFP, DEFAULT_RECIPE_IMAGE
import uuid
from backend.schemas import (
    CreateAccountSchema, 
    LoginSchema, 
    AutoLoginSchema, 
    FriendRequestSchema,
    CreateCookbookSchema, 
    UpdateCookbookSchema, 
    AddRecipeToCookbookSchema,
    CreateRecipeSchema,
    UpdateRecipeSchema,
    CreateReviewSchema,
)
from backend.middleware.customauth import require_auth

__all__ = [
    "Blueprint", 
    "request", 
    "g", 
    "jsonify", 
    "check_password_hash", 
    "generate_password_hash", 
    "IntegrityError", 
    "ValidationError", 
    "User", 
    "SessionToken", 
    "db", 
    "Friendship",
    "Cookbook",
    "Recipe",
    "error", 
    "success", 
    "generate_token", 
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
    "require_auth",
    "upload_to_s3",
    "uuid",
    "delete_from_s3",
    "DEFAULT_PFP",
    "DEFAULT_RECIPE_IMAGE",
]