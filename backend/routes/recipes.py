from backend.routes.dependencies import (
    Blueprint,
    request,
    db,
    g,
    Recipe,
    Review,
    error,
    success,
    require_auth,
    ValidationError,
    IntegrityError,
    CreateRecipeSchema,
    UpdateRecipeSchema,
    CreateReviewSchema,
)

recipes_bp = Blueprint("recipes", __name__)

@recipes_bp.post("/recipes/")
@require_auth
def create_recipe():
    """
    Create =new recipe owned by the current user.
    """
    schema = CreateRecipeSchema()
    try:
        data = schema.load(request.get_json(silent=True) or {})
    except ValidationError as err:
        return error(err.messages, 400)

    recipe = Recipe(
        creator_id=g.user.id,
        title=data["title"],
        description=data.get("description"),
        image_url=data.get("image_url"),
        time_minutes=data.get("time_minutes"),
        cuisine=data.get("cuisine"),
        servings=data.get("servings"),
        ingredients=data.get("ingredients", []),
        instructions=data.get("instructions", []),
    )
    db.session.add(recipe)
    db.session.commit()

    return success(recipe.serialize(), 201)


@recipes_bp.get("/recipes/<int:recipe_id>/")
@require_auth
def get_recipe(recipe_id):
    """
    Get single recipe by id (full view).
    """
    recipe = Recipe.query.get(recipe_id)
    if recipe is None:
        return error("Recipe not found", 404)

    return success(recipe.serialize(), 200)


@recipes_bp.put("/recipes/<int:recipe_id>/")
@require_auth
def update_recipe(recipe_id):
    """
    Update existing recipe. Only creator can update.
    """
    recipe = Recipe.query.get(recipe_id)
    if recipe is None:
        return error("Recipe not found", 404)

    if recipe.creator_id != g.user.id:
        return error("Forbidden: you do not own this recipe", 403)

    schema = UpdateRecipeSchema()
    try:
        data = schema.load(request.get_json(silent=True) or {})
    except ValidationError as err:
        return error(err.messages, 400)

    for field in (
        "title", "description", "image_url",
        "time_minutes", "cuisine", "servings",
        "ingredients", "instructions",
    ):
        if field in data:
            setattr(recipe, field, data[field])

    db.session.commit()
    return success(recipe.serialize(), 200)


@recipes_bp.delete("/recipes/<int:recipe_id>/")
@require_auth
def delete_recipe(recipe_id):
    """
    Delete recipe. Only creator can delete.
    """
    recipe = Recipe.query.get(recipe_id)
    if recipe is None:
        return error("Recipe not found", 404)

    if recipe.creator_id != g.user.id:
        return error("Forbidden: you do not own this recipe", 403)

    db.session.delete(recipe)
    db.session.commit()

    return success({"success": True, "message": "Recipe deleted"}, 200)


@recipes_bp.get("/users/<int:user_id>/recipes/")
@require_auth
def get_recipes_by_user(user_id):
    """
    Get all recipes created by specific user
    Returns previews, not full recipes.
    """
    recipes = (
        Recipe.query
        .filter_by(creator_id=user_id)
        .order_by(Recipe.created_at.desc())
        .all()
    )
    return success(
        {
            "user_id": user_id,
            "recipes": [r.serialize_preview() for r in recipes],
        },
        200,
    )

@recipes_bp.post("/recipes/<int:recipe_id>/reviews/")
@require_auth
def create_or_update_review(recipe_id):
    """
    Create/update current user review of a recipe.
    A user can have at most one review per recipe — calling when
    one already exists updates the existing review.
    """
    recipe = Recipe.query.get(recipe_id)
    if recipe is None:
        return error("Recipe not found", 404)

    schema = CreateReviewSchema()
    try:
        data = schema.load(request.get_json(silent=True) or {})
    except ValidationError as err:
        return error(err.messages, 400)

    existing = Review.query.filter_by(
        user_id=g.user.id, recipe_id=recipe_id
    ).first()

    if existing is not None:
        existing.rating = data["rating"]
        existing.text = data.get("text")
        db.session.commit()
        return success(existing.serialize(), 200)

    review = Review(
        user_id=g.user.id,
        recipe_id=recipe_id,
        rating=data["rating"],
        text=data.get("text"),
    )
    db.session.add(review)

    try:
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        return error("Review already exists; retry as an update", 409)

    return success(review.serialize(), 201)


@recipes_bp.get("/recipes/<int:recipe_id>/reviews/")
@require_auth
def get_reviews_for_recipe(recipe_id):
    """
    Get all reviews for recipe.
    """
    recipe = Recipe.query.get(recipe_id)
    if recipe is None:
        return error("Recipe not found", 404)

    reviews = (
        Review.query
        .filter_by(recipe_id=recipe_id)
        .order_by(Review.updated_at.desc())
        .all()
    )
    return success(
        {
            "recipe_id": recipe_id,
            "reviews": [r.serialize() for r in reviews],
        },
        200,
    )


@recipes_bp.delete("/recipes/<int:recipe_id>/reviews/")
@require_auth
def delete_review(recipe_id):
    """
    Delete current user's review of recipe.
    """
    review = Review.query.filter_by(
        user_id=g.user.id, recipe_id=recipe_id
    ).first()
    if review is None:
        return error("Review not found", 404)

    db.session.delete(review)
    db.session.commit()

    return success({"success": True, "message": "Review deleted"}, 200)