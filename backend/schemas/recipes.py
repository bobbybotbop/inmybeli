"""
Schemas for recipe endpoints
"""
from marshmallow import Schema, fields, validate
from backend.schemas.helper import ImageField


class CreateRecipeSchema(Schema):
    """Schema for creating a new recipe"""
    title = fields.Str(
        required=True,
        validate=validate.Length(min=1, max=255),
        error_messages={"required": "Recipe title is required"}
    )
    description = fields.Str(
        required=False,
        allow_none=True,
        validate=validate.Length(max=2000)
    )
    image = ImageField(required=False)
    time_minutes = fields.Int(
        required=False,
        allow_none=True,
        validate=validate.Range(min=0, max=10000)
    )
    cuisine = fields.Str(
        required=False,
        allow_none=True,
        validate=validate.Length(max=100)
    )
    servings = fields.Int(
        required=False,
        allow_none=True,
        validate=validate.Range(min=1, max=1000)
    )
    ingredients = fields.List(
        fields.Dict(),
        required=False,
        load_default=list
    )
    instructions = fields.List(
        fields.Str(),
        required=False,
        load_default=list
    )


class UpdateRecipeSchema(Schema):
    """Schema for updating an existing recipe with fields optional"""
    title = fields.Str(
        required=False,
        validate=validate.Length(min=1, max=255)
    )
    description = fields.Str(
        required=False,
        allow_none=True,
        validate=validate.Length(max=2000)
    )
    image = ImageField(required = False)
    time_minutes = fields.Int(
        required=False,
        allow_none=True,
        validate=validate.Range(min=0, max=10000)
    )
    cuisine = fields.Str(
        required=False,
        allow_none=True,
        validate=validate.Length(max=100)
    )
    servings = fields.Int(
        required=False,
        allow_none=True,
        validate=validate.Range(min=1, max=1000)
    )
    ingredients = fields.List(
        fields.Dict(),
        required=False
    )
    instructions = fields.List(
        fields.Str(),
        required=False
    )