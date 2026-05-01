from datetime import timezone
from collections import defaultdict

from sqlalchemy import func
import json

from backend.routes.dependencies import (
    Blueprint,
    request,
    db,
    g,
    Cookbook,
    Recipe,
    Review,
    User,
    error,
    success,
    require_auth,
    ValidationError,
    IntegrityError,
    CreateRecipeSchema,
    UpdateRecipeSchema,
    CreateReviewSchema,
    upload_to_s3,
    delete_from_s3,
    allowed_file
)
from backend.models.assocTables import cookbookRecipes

recipes_bp = Blueprint("recipes", __name__)


def _feed_day_key(created_at):
    if created_at is None:
        return None
    dt = created_at
    if dt.tzinfo is not None:
        dt = dt.astimezone(timezone.utc)
    return dt.date()


def _total_saves_by_recipe_id():
    """Distinct users per recipe via global per-user cookbook named 'saved'."""
    rows = (
        db.session.query(
            cookbookRecipes.c.recipe_id,
            func.count(func.distinct(Cookbook.creator_id)),
        )
        .join(Cookbook, Cookbook.id == cookbookRecipes.c.cookbook_id)
        .filter(Cookbook.name == "saved")
        .group_by(cookbookRecipes.c.recipe_id)
        .all()
    )
    return {recipe_id: int(cnt) for recipe_id, cnt in rows}


def _friend_saved_profile_urls_by_recipe(recipe_ids, friend_ids, limit=2):
    """
    For each recipe id, return up to `limit` profile picture URLs of accepted
    friends who saved the recipe via their global 'saved' cookbook. Savers are
    ordered by User.id ascending for deterministic results.
    """
    if not recipe_ids or not friend_ids:
        return {}

    rows = (
        db.session.query(
            cookbookRecipes.c.recipe_id,
            User.id,
            User.profile_picture_url,
        )
        .join(Cookbook, Cookbook.id == cookbookRecipes.c.cookbook_id)
        .join(User, User.id == Cookbook.creator_id)
        .filter(
            Cookbook.name == "saved",
            Cookbook.creator_id.in_(friend_ids),
            cookbookRecipes.c.recipe_id.in_(recipe_ids),
        )
        .order_by(cookbookRecipes.c.recipe_id.asc(), User.id.asc())
        .all()
    )

    urls_by_recipe = defaultdict(list)
    for recipe_id, _user_id, profile_url in rows:
        bucket = urls_by_recipe[recipe_id]
        if len(bucket) < limit:
            bucket.append(profile_url)
    return urls_by_recipe


def _recipes_feed_ordered(recipes, friend_ids):
    """
    Newest calendar days first; within each day, recipes by friends first,
    then others; preserving descending created_at within each subgroup.
    """
    buckets = defaultdict(list)
    for recipe in recipes:
        buckets[_feed_day_key(recipe.created_at)].append(recipe)

    ordered_days = sorted(buckets.keys(), reverse=True)
    ordered_recipes = []
    for day in ordered_days:
        day_recipes = buckets[day]
        friends_first = [r for r in day_recipes if r.creator_id in friend_ids]
        others = [r for r in day_recipes if r.creator_id not in friend_ids]
        friends_first.sort(key=lambda r: r.created_at, reverse=True)
        others.sort(key=lambda r: r.created_at, reverse=True)
        ordered_recipes.extend(friends_first + others)
    return ordered_recipes

@recipes_bp.post("/recipes/")
@require_auth
def create_recipe():
    """
    Create new recipe owned by the current user.
    """
    schema = CreateRecipeSchema()

    try:
        raw_data = request.form.to_dict()
        form_data = schema.load(raw_data)
    except ValidationError as err:
        return error(err.messages, 400)

    file = request.files.get("image")
    recipe_image_s3_key = None
    recipe_image_url = None

    if file:
        try:
            s3_result = upload_to_s3(file, folder="recipe/")
            if not s3_result["success"]:
                msg = s3_result.get("error") or "Failed to upload recipe image"
                return error(msg, 500)

            recipe_image_s3_key = s3_result["s3_key"]
            recipe_image_url = s3_result["s3_url"]

        except Exception as e:
            return error(f"Upload error: {str(e)}", 500)

    try:
        recipe = Recipe(
            creator_id=g.user.id,
            title=form_data["title"],
            description=form_data.get("description"),
            recipe_image_url=recipe_image_url,
            recipe_image_s3_key=recipe_image_s3_key,
            time_minutes=form_data.get("time_minutes"),
            cuisine=form_data.get("cuisine"),
            servings=form_data.get("servings"),
            ingredients=form_data.get("ingredients", []),
            instructions=form_data.get("instructions", []),
        )
        db.session.add(recipe)
        db.session.commit()

    except Exception as e:
        db.session.rollback()
        if recipe_image_s3_key:
            delete_from_s3(recipe_image_s3_key)
        return error(f"Recipe creation failed: {str(e)}", 500)

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


@recipes_bp.post("/recipes/<int:recipe_id>/")
@require_auth
def update_recipe(recipe_id):
    """Update existing recipe. Only creator can update."""
    recipe = Recipe.query.get(recipe_id)

    if recipe is None:
        return error("Recipe not found", 404)

    if recipe.creator_id != g.user.id:
        return error("Forbidden: you do not own this recipe", 403)
        
    # Validate form data
    schema = UpdateRecipeSchema()
    expected_fields = ['title', 'description', 'instructions', 'time_minutes', 'cuisine', 'servings', 'ingredients', 'instructions']
    raw_data = {field: request.form.get(field) for field in expected_fields if field in request.form}
    try:
        # Pass only the form text to Marshmallow
        form_data = schema.load(raw_data)

    except ValidationError as err:
        return error(err.messages, 400)
        
    new_s3_key = None
    old_s3_key = recipe.recipe_image_s3_key  
    file = request.files.get("image")
    if file and file.filename != '':
        try:      
            # Upload to S3
            upload_result = upload_to_s3(file, folder="recipes/")
            
            if not upload_result['success']:
                return error(f"Failed to upload image", 500)
            
            new_s3_key = upload_result['s3_key']
            form_data['recipe_image_url'] = upload_result['s3_url']
            form_data['recipe_image_s3_key'] = new_s3_key
            
        except Exception as e:
            return error(f"Upload error: {str(e)}", 500)
    # Update recipe
    try:
        for field, value in form_data.items():
            if value is not None:
                setattr(recipe, field, value)

        db.session.commit()
        
        # Delete old image AFTER successful commit
        if new_s3_key and old_s3_key and old_s3_key != new_s3_key:
            delete_from_s3(old_s3_key)

        
    except Exception as e:
        db.session.rollback()
        
        # Clean up newly uploaded file if DB fails
        if new_s3_key:
            delete_from_s3(new_s3_key)
        
        return error(f"Recipe update failed: {str(e)}", 500)

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


@recipes_bp.get("/feed/recipes/")
@require_auth
def get_recipe_feed():
    """
    All recipes for Discover: reverse chronological by day; friends prioritized within each day.
    Preview includes total_saves_count from each user's global 'saved' cookbook and
    up to two profile picture URLs of accepted friends who also saved the recipe.
    """
    saves_counts = _total_saves_by_recipe_id()
    recipes = Recipe.query.order_by(Recipe.created_at.desc()).all()
    friend_ids = {u.id for u in g.user.get_friends()}
    ordered = _recipes_feed_ordered(recipes, friend_ids)
    recipe_ids = [r.id for r in ordered]
    friend_saver_urls = _friend_saved_profile_urls_by_recipe(recipe_ids, friend_ids)
    payload = [
        r.serialize_preview(
            total_saves_count=saves_counts.get(r.id, 0),
            friend_saved_profile_picture_urls=friend_saver_urls.get(r.id, []),
        )
        for r in ordered
    ]
    return success({"recipes": payload}, 200)


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