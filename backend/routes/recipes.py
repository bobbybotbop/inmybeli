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
    upload_to_s3,
    delete_from_s3,
    allowed_file
)

recipes_bp = Blueprint("recipes", __name__)

@recipes_bp.post("/recipes/")
@require_auth
def create_recipe():
    """
    Create new recipe owned by the current user.
    """
    schema = CreateRecipeSchema()

    try:
        raw_data = request.form.to_dict()
        # Remove ingredients and instructions before schema validation since they'll be empty lists
        raw_data.pop('ingredients', None)
        raw_data.pop('instructions', None)
        form_data = schema.load(raw_data)
    except ValidationError as err:
        return error(err.messages, 400)

    file = request.files.get("image")

    recipe_image_s3_key = None
    recipe_image_url = None
    
    # Set ingredients and instructions to empty lists
    form_data['ingredients'] = []
    form_data['instructions'] = []

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


@recipes_bp.put("/recipes/<int:recipe_id>/")
@require_auth
def update_recipe(recipe_id):
    """Update existing recipe. Only creator can update."""
    
    recipe = Recipe.query.get(recipe_id)
    if recipe is None:
        return error("Recipe not found", 404)

    if recipe.creator_id != g.user.id:
        return error("Forbidden: you do not own this recipe", 403)

    # Parse form data
    form_data_dict = request.form.to_dict()
    
    # Handle JSON arrays (ingredients, instructions)
    if 'ingredients' in form_data_dict:
        try:
            form_data_dict['ingredients'] = json.loads(form_data_dict['ingredients'])
        except:
            form_data_dict['ingredients'] = []
    
    if 'instructions' in form_data_dict:
        try:
            form_data_dict['instructions'] = json.loads(form_data_dict['instructions'])
        except:
            form_data_dict['instructions'] = []
    
    # Validate form data
    schema = UpdateRecipeSchema()
    try:
        form_data = schema.load(form_data_dict)
    except ValidationError as err:
        return error(err.messages, 400)
    
    # Handle image upload if provided
    new_s3_key = None
    old_s3_key = recipe.recipe_image_s3_key  # Store old key for deletion
    
    if 'image' in request.files:
        file = request.files['image']
        
        # Only process if file was actually selected
        if file and file.filename != '':
            if not allowed_file(file.filename):
                return error("Invalid file type. Allowed: jpg, jpeg, png, gif, webp, heic, heif, svg", 400)
            
            try:
                # Reset file pointer before upload
                file.seek(0)
                
                # Upload to S3
                upload_result = upload_to_s3(file, folder="recipes/")  # Changed from "recipe/" to "recipes/"
                
                if not upload_result['success']:
                    return error(f"Failed to upload image: {upload_result['error']}", 500)
                
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