"""
Schemas for recipe endpoints
"""
from marshmallow import Schema, fields, validate, pre_load
from backend.schemas.helper import ImageField
import json


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
    # image = ImageField(required=False)
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

    @pre_load
    def parse_json_fields(self, data, **kwargs):
        """Convert JSON strings to actual objects"""
        
        # Parse ingredients if it's a string
        if isinstance(data.get('ingredients'), str):
            try:
                data['ingredients'] = json.loads(data['ingredients'])
            except (json.JSONDecodeError, TypeError):
                data['ingredients'] = []
        
        # Parse instructions if it's a string
        if isinstance(data.get('instructions'), str):
            try:
                data['instructions'] = json.loads(data['instructions'])
            except (json.JSONDecodeError, TypeError):
                data['instructions'] = []
        
        return data


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
    # image = ImageField(required=False)
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

    @pre_load
    def parse_json_fields(self, data, **kwargs):
        """Convert JSON strings to actual objects"""
        
        # Parse ingredients if it's a string
        if isinstance(data.get('ingredients'), str):
            try:
                data['ingredients'] = json.loads(data['ingredients'])
            except (json.JSONDecodeError, TypeError):
                data['ingredients'] = []
        
        # Parse instructions if it's a string
        if isinstance(data.get('instructions'), str):
            try:
                data['instructions'] = json.loads(data['instructions'])
            except (json.JSONDecodeError, TypeError):
                data['instructions'] = []
        
        return data