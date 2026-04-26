"""
Schemas for authentication-related endpoints
"""
 
from marshmallow import Schema, fields, validate
 
 
class CreateAccountSchema(Schema):
    """Schema for creating a new user account"""
    name = fields.Str(
        required=True,
        validate=validate.Length(min=1, max=255),
        error_messages={"required": "Name is required"}
    )
    username = fields.Str(
        required=True,
        validate=validate.Length(min=3, max=50),
        error_messages={"required": "Username is required"}
    )
    password = fields.Str(
        required=True,
        validate=validate.Length(min=8),
        error_messages={"required": "Password is required"}
    )
 
 
class LoginSchema(Schema):
    """Schema for user login"""
    username = fields.Str(
        required=True,
        error_messages={"required": "Username is required"}
    )
    password = fields.Str(
        required=True,
        error_messages={"required": "Password is required"}
    )
 
class AutoLoginSchema(Schema):
    """Schema for user login"""
    token = fields.Str(
        required=True,
        error_messages={"required": "Session Token is required"}
    )