from backend.routes.dependencies import (
    Blueprint,
    request,
    db,
    Cookbook,
    Recipe,
    error,
    success,
    require_auth,
    ValidationError,
    g,
    CreateCookbookSchema,
    UpdateCookbookSchema,
    AddRecipeToCookbookSchema
)

cookbooks_bp = Blueprint("cookbooks", __name__)

@cookbooks_bp.get("/")
@require_auth
def get_all_cookbooks():
    """
    Get all cookbooks for the current user
    """
    cookbooks = Cookbook.query.filter_by(creator_id=g.user.id).all()
    
    return success(
        {
            "user_id": g.user.id,
            "cookbooks": [c.simple_serialize() for c in cookbooks]
        }, 200
    )


@cookbooks_bp.post("/")
@require_auth
def create_cookbook():
    """
    Create a new cookbook
    """
    schema = CreateCookbookSchema()
    
    try:
        data = schema.load(request.get_json(silent=True) or {})
    except ValidationError as err:
        return error(err.messages, 400)
    
    cookbook = Cookbook(
        creator_id=g.user.id,
        name=data["name"],
        description=data.get("description")
    )
    
    db.session.add(cookbook)
    db.session.commit()
    
    return success(
        {
            "success": True,
            "message": "Cookbook created successfully",
            "cookbook": cookbook.serialize()
        }, 201
    )


@cookbooks_bp.get("/<int:cookbook_id>/")
@require_auth
def get_cookbook(cookbook_id):
    """
    Get a specific cookbook by ID
    """
    cookbook = Cookbook.query.get(cookbook_id)
    
    if not cookbook:
        return error("Cookbook not found", 404)
    
    return success(
        {
            "cookbook": cookbook.serialize()
        }, 200
    )


@cookbooks_bp.put("/<int:cookbook_id>/")
@require_auth
def update_cookbook(cookbook_id):
    """
    Update description or name of existing cookbook
    """
    cookbook = Cookbook.query.get(cookbook_id)
    
    # users are not allowed to look at others cookbooks
    if not cookbook or (cookbook.creator_id != g.user.id):
        return error("Cookbook not found", 404)
    
    schema = UpdateCookbookSchema()
    
    try:
        data = schema.load(request.get_json(silent=True) or {})
    except ValidationError as err:
        return error(err.messages, 400)
    
    if "name" in data:
        cookbook.name = data["name"]
    if "description" in data:
        cookbook.description = data["description"]
    
    db.session.commit()
    
    return success(
        {
            "success": True,
            "message": "Cookbook updated successfully",
            "cookbook": cookbook.serialize()
        }, 200
    )


@cookbooks_bp.delete("/<int:cookbook_id>/")
@require_auth
def delete_cookbook(cookbook_id):
    """
    Delete a cookbook
    """
    cookbook = Cookbook.query.get(cookbook_id)
    
    if not cookbook or (cookbook.creator_id != g.user.id):
        return error("Cookbook not found", 404)
    
    db.session.delete(cookbook)
    db.session.commit()
    
    return success(
        {
            "success": True,
            "message": "Cookbook deleted successfully"
        }, 200
    )


@cookbooks_bp.post("/<int:cookbook_id>/recipes/")
@require_auth
def add_recipe_to_cookbook(cookbook_id):
    """
    Add a recipe to a cookbook
    """
    cookbook = Cookbook.query.get(cookbook_id)
    
    if not cookbook or (cookbook.creator_id != g.user.id):
        return error("Cookbook not found", 404)
    
    schema = AddRecipeToCookbookSchema()
    
    try:
        data = schema.load(request.get_json(silent=True) or {})
    except ValidationError as err:
        return error(err.messages, 400)
    
    recipe = Recipe.query.get(data["recipe_id"])
    
    if not recipe:
        return error("Recipe not found", 404)
    
    if recipe in cookbook.recipes:
        return error("Recipe already in cookbook", 409)
    
    cookbook.recipes.append(recipe)
    db.session.commit()
    
    return success(
        {
            "success": True,
            "message": "Recipe added to cookbook",
            "cookbook": cookbook.serialize()
        }, 201
    )


@cookbooks_bp.delete("/<int:cookbook_id>/recipes/<int:recipe_id>/")
@require_auth
def remove_recipe_from_cookbook(cookbook_id, recipe_id):
    """
    Remove a recipe from a cookbook
    """
    cookbook = Cookbook.query.get(cookbook_id)
    
    if not cookbook or (cookbook.creator_id != g.user.id):
        return error("Cookbook not found", 404)
    
    recipe = Recipe.query.get(recipe_id)
    
    if not recipe:
        return error("Recipe not found", 404)
    
    if recipe not in cookbook.recipes:
        return error("Recipe not in cookbook", 404)
    
    cookbook.recipes.remove(recipe)
    db.session.commit()
    
    return success(
        {
            "success": True,
            "message": "Recipe removed from cookbook",
            "cookbook": cookbook.serialize()
        }, 200
    )