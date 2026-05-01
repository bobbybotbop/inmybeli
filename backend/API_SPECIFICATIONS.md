# InMyBeli API Specifications

## Base URL

```
http://localhost:5001/api
```

## Authentication

Most endpoints require Bearer token authentication. Include the token in the Authorization header:

```
Authorization: Bearer <session_token>
```

### Public Endpoints (No Authentication Required)

- `POST /users/create`
- `POST /users/login`
- `POST /users/autologin`
- `GET /users/tokens`

---

## Users Endpoints

### 1. Create Account

**HTTP Method:** `POST`  
**Route:** `/users/create`  
**Authentication:** None (Public)  
**Description:** Create a new user account with optional profile picture upload

**Request Body:**

- Content-Type: `multipart/form-data`
- Fields:
  - `name` (string, required, 1-255 chars) - User's full name
  - `username` (string, required, 3-50 chars, unique) - User's username
  - `password` (string, required, minimum 8 chars) - User's password
  - `profile_picture` (file, optional) - User's profile image

**Example Request:**

```bash
curl -X POST http://localhost:5000/api/users/create \
  -F "name=John Doe" \
  -F "username=johndoe" \
  -F "password=securepass123" \
  -F "profile_picture=@/path/to/image.jpg"
```

**Example Response (201 Created):**

```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "username": "johndoe",
    "profile_url": "https://s3.amazonaws.com/inmybeli/pfp/default.jpg",
    "created_at": "2026-04-30T10:30:00+00:00"
  },
  "session_token": "abc123def456ghi789..."
}
```

**Error Responses:**

- `400 Bad Request` - Validation error (missing required fields, invalid field length)
- `400 Bad Request` - Username already exists
- `500 Internal Server Error` - Account creation failed or upload error

---

### 2. Login

**HTTP Method:** `POST`  
**Route:** `/users/login`  
**Authentication:** None (Public)  
**Description:** Authenticate user with username and password, returns session token

**Request Body:**

```json
{
  "username": "string (required)",
  "password": "string (required)"
}
```

**Example Request:**

```bash
curl -X POST http://localhost:5000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "johndoe",
    "password": "securepass123"
  }'
```

**Example Response (200 OK):**

```json
{
  "success": true,
  "user": {
    "id": 1,
    "name": "John Doe",
    "username": "johndoe",
    "profile_url": "https://s3.amazonaws.com/inmybeli/pfp/default.jpg",
    "created_at": "2026-04-30T10:30:00+00:00"
  },
  "token": "abc123def456ghi789..."
}
```

**Error Responses:**

- `400 Bad Request` - Validation error (missing required fields)
- `401 Unauthorized` - Invalid credentials (wrong username or password)

---

### 3. Auto Login

**HTTP Method:** `POST`  
**Route:** `/users/autologin`  
**Authentication:** None (Public)  
**Description:** Automatically authenticate user with existing session token

**Request Body:**

```json
{
  "token": "string (required)"
}
```

**Example Request:**

```bash
curl -X POST http://localhost:5000/api/users/autologin \
  -H "Content-Type: application/json" \
  -d '{
    "token": "abc123def456ghi789..."
  }'
```

**Example Response (200 OK):**

```json
{
  "success": true,
  "user": {
    "id": 1,
    "name": "John Doe",
    "username": "johndoe",
    "profile_url": "https://s3.amazonaws.com/inmybeli/pfp/default.jpg",
    "created_at": "2026-04-30T10:30:00+00:00"
  },
  "token": "abc123def456ghi789..."
}
```

**Error Responses:**

- `400 Bad Request` - Validation error (missing token)
- `401 Unauthorized` - Invalid or expired token

---

### 4. Get Current User

**HTTP Method:** `GET`  
**Route:** `/users`  
**Authentication:** Required (Bearer token)  
**Description:** Get information about the currently authenticated user

**Request Body:** None

**Example Request:**

```bash
curl -X GET http://localhost:5000/api/users \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "id": 1,
  "name": "John Doe",
  "username": "johndoe",
  "profile_url": "https://s3.amazonaws.com/inmybeli/pfp/default.jpg",
  "created_at": "2026-04-30T10:30:00+00:00"
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token
- `401 Unauthorized` - User not found

---

## Recipes Endpoints

### 1. Create Recipe

**HTTP Method:** `POST`  
**Route:** `/recipes`  
**Authentication:** Required (Bearer token)  
**Description:** Create a new recipe with optional image upload. Current user becomes the recipe owner.

**Request Body:**

- Content-Type: `multipart/form-data`
- Fields:
  - `title` (string, required, 1-255 chars) - Recipe title
  - `description` (string, optional, max 2000 chars) - Recipe description
  - `image` (file, optional) - Recipe image
  - `time_minutes` (integer, optional, 0-10000) - Cooking time in minutes
  - `cuisine` (string, optional, max 100 chars) - Cuisine type (e.g., "Italian", "Asian")
  - `servings` (integer, optional, 1-1000) - Number of servings
  - `ingredients` (JSON array, optional) - List of ingredients with details
  - `instructions` (JSON array, optional) - Step-by-step cooking instructions

**Example Request:**

```bash
curl -X POST http://localhost:5000/api/recipes \
  -H "Authorization: Bearer abc123def456ghi789..." \
  -F "title=Pasta Carbonara" \
  -F "description=Classic Italian pasta dish" \
  -F "image=@/path/to/recipe.jpg" \
  -F "time_minutes=30" \
  -F "cuisine=Italian" \
  -F "servings=4" \
  -F 'ingredients=[{"name":"spaghetti","amount":"400g"},{"name":"eggs","amount":"3"}]' \
  -F 'instructions=["Boil water","Cook pasta","Mix eggs"]'
```

**Example Response (201 Created):**

```json
{
  "id": 5,
  "creator_id": 1,
  "title": "Pasta Carbonara",
  "description": "Classic Italian pasta dish",
  "recipe_image_url": "https://s3.amazonaws.com/inmybeli/recipe/abc123.jpg",
  "time_minutes": 30,
  "cuisine": "Italian",
  "servings": 4,
  "ingredients": [
    { "name": "spaghetti", "amount": "400g" },
    { "name": "eggs", "amount": "3" }
  ],
  "instructions": ["Boil water", "Cook pasta", "Mix eggs"],
  "created_at": "2026-04-30T10:30:00+00:00",
  "updated_at": "2026-04-30T10:30:00+00:00"
}
```

**Error Responses:**

- `400 Bad Request` - Validation error (missing title, invalid field lengths)
- `401 Unauthorized` - Missing or invalid token
- `500 Internal Server Error` - Recipe creation failed or upload error

---

### 2. Get Recipe

**HTTP Method:** `GET`  
**Route:** `/recipes/<recipe_id>`  
**Authentication:** Required (Bearer token)  
**Description:** Get a single recipe by ID with full details

**Request Body:** None

**Example Request:**

```bash
curl -X GET http://localhost:5000/api/recipes/5 \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "id": 5,
  "creator_id": 1,
  "title": "Pasta Carbonara",
  "description": "Classic Italian pasta dish",
  "recipe_image_url": "https://s3.amazonaws.com/inmybeli/recipe/abc123.jpg",
  "time_minutes": 30,
  "cuisine": "Italian",
  "servings": 4,
  "ingredients": [
    { "name": "spaghetti", "amount": "400g" },
    { "name": "eggs", "amount": "3" }
  ],
  "instructions": ["Boil water", "Cook pasta", "Mix eggs"],
  "created_at": "2026-04-30T10:30:00+00:00",
  "updated_at": "2026-04-30T10:30:00+00:00"
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Recipe not found

---

### 3. Update Recipe

**HTTP Method:** `POST`  
**Route:** `/recipes/<recipe_id>`  
**Authentication:** Required (Bearer token)  
**Description:** Update an existing recipe. Only the recipe creator can update it. All fields are optional.

**Request Body:**

- Content-Type: `multipart/form-data`
- Fields (all optional):
  - `title` (string, 1-255 chars)
  - `description` (string, max 2000 chars)
  - `image` (file) - Replaces existing image
  - `time_minutes` (integer, 0-10000)
  - `cuisine` (string, max 100 chars)
  - `servings` (integer, 1-1000)
  - `ingredients` (JSON array)
  - `instructions` (JSON array)

**Example Request:**

```bash
curl -X POST http://localhost:5000/api/recipes/5 \
  -H "Authorization: Bearer abc123def456ghi789..." \
  -F "servings=6" \
  -F "time_minutes=35"
```

**Example Response (200 OK):**

```json
{
  "id": 5,
  "creator_id": 1,
  "title": "Pasta Carbonara",
  "description": "Classic Italian pasta dish",
  "recipe_image_url": "https://s3.amazonaws.com/inmybeli/recipe/abc123.jpg",
  "time_minutes": 35,
  "cuisine": "Italian",
  "servings": 6,
  "ingredients": [
    { "name": "spaghetti", "amount": "400g" },
    { "name": "eggs", "amount": "3" }
  ],
  "instructions": ["Boil water", "Cook pasta", "Mix eggs"],
  "created_at": "2026-04-30T10:30:00+00:00",
  "updated_at": "2026-04-30T11:45:00+00:00"
}
```

**Error Responses:**

- `400 Bad Request` - Validation error
- `401 Unauthorized` - Missing or invalid token
- `403 Forbidden` - User is not the recipe creator
- `404 Not Found` - Recipe not found
- `500 Internal Server Error` - Update failed

---

### 4. Delete Recipe

**HTTP Method:** `DELETE`  
**Route:** `/recipes/<recipe_id>`  
**Authentication:** Required (Bearer token)  
**Description:** Delete a recipe. Only the recipe creator can delete it.

**Request Body:** None

**Example Request:**

```bash
curl -X DELETE http://localhost:5000/api/recipes/5 \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Recipe deleted"
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token
- `403 Forbidden` - User is not the recipe creator
- `404 Not Found` - Recipe not found

---

### 5. Get Recipes by User

**HTTP Method:** `GET`  
**Route:** `/users/<user_id>/recipes`  
**Authentication:** Required (Bearer token)  
**Description:** Get all recipes created by a specific user (returns previews, not full details)

**Request Body:** None

**Example Request:**

```bash
curl -X GET http://localhost:5000/api/users/1/recipes \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "user_id": 1,
  "recipes": [
    {
      "id": 5,
      "creator_id": 1,
      "title": "Pasta Carbonara",
      "image_url": "https://s3.amazonaws.com/inmybeli/recipe/abc123.jpg",
      "time_minutes": 30,
      "cuisine": "Italian"
    },
    {
      "id": 6,
      "creator_id": 1,
      "title": "Risotto",
      "image_url": "https://s3.amazonaws.com/inmybeli/recipe/def456.jpg",
      "time_minutes": 45,
      "cuisine": "Italian"
    }
  ]
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token

---

### 6. Get Recipe Feed

**HTTP Method:** `GET`  
**Route:** `/feed/recipes`  
**Authentication:** Required (Bearer token)  
**Description:** Get all recipes for the Discover feed. Recipes are ordered by date (newest first), with recipes from friends prioritized within each day. Includes save counts.

**Request Body:** None

**Example Request:**

```bash
curl -X GET http://localhost:5000/api/feed/recipes \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "recipes": [
    {
      "id": 5,
      "creator_id": 1,
      "title": "Pasta Carbonara",
      "image_url": "https://s3.amazonaws.com/inmybeli/recipe/abc123.jpg",
      "time_minutes": 30,
      "cuisine": "Italian",
      "total_saves_count": 12
    },
    {
      "id": 6,
      "creator_id": 2,
      "title": "Risotto",
      "image_url": "https://s3.amazonaws.com/inmybeli/recipe/def456.jpg",
      "time_minutes": 45,
      "cuisine": "Italian",
      "total_saves_count": 8
    }
  ]
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token

---

## Reviews Endpoints

### 1. Create or Update Review

**HTTP Method:** `POST`  
**Route:** `/recipes/<recipe_id>/reviews`  
**Authentication:** Required (Bearer token)  
**Description:** Create a new review for a recipe or update existing review. A user can have only one review per recipe. If a review already exists, it will be updated.

**Request Body:**

```json
{
  "rating": "integer (required, 1-5)",
  "text": "string (optional, max 2000 chars)"
}
```

**Example Request:**

```bash
curl -X POST http://localhost:5000/api/recipes/5/reviews \
  -H "Authorization: Bearer abc123def456ghi789..." \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 5,
    "text": "Amazing pasta! Perfect carbonara."
  }'
```

**Example Response (200 OK or 201 Created):**

```json
{
  "id": 12,
  "user_id": 1,
  "recipe_id": 5,
  "rating": 5,
  "text": "Amazing pasta! Perfect carbonara.",
  "created_at": "2026-04-30T10:30:00+00:00",
  "updated_at": "2026-04-30T10:30:00+00:00"
}
```

**Error Responses:**

- `400 Bad Request` - Validation error (missing rating, invalid rating value)
- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Recipe not found

---

### 2. Get Reviews for Recipe

**HTTP Method:** `GET`  
**Route:** `/recipes/<recipe_id>/reviews`  
**Authentication:** Required (Bearer token)  
**Description:** Get all reviews for a specific recipe, ordered by most recently updated first

**Request Body:** None

**Example Request:**

```bash
curl -X GET http://localhost:5000/api/recipes/5/reviews \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "recipe_id": 5,
  "reviews": [
    {
      "id": 12,
      "user_id": 1,
      "recipe_id": 5,
      "rating": 5,
      "text": "Amazing pasta! Perfect carbonara.",
      "created_at": "2026-04-30T10:30:00+00:00",
      "updated_at": "2026-04-30T10:30:00+00:00"
    },
    {
      "id": 13,
      "user_id": 2,
      "recipe_id": 5,
      "rating": 4,
      "text": "Very good, but a bit salty",
      "created_at": "2026-04-29T15:20:00+00:00",
      "updated_at": "2026-04-29T15:20:00+00:00"
    }
  ]
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Recipe not found

---

### 3. Delete Review

**HTTP Method:** `DELETE`  
**Route:** `/recipes/<recipe_id>/reviews`  
**Authentication:** Required (Bearer token)  
**Description:** Delete current user's review of a recipe

**Request Body:** None

**Example Request:**

```bash
curl -X DELETE http://localhost:5000/api/recipes/5/reviews \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Review deleted"
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Review not found

---

## Cookbooks Endpoints

### 1. Get All Cookbooks

**HTTP Method:** `GET`  
**Route:** `/cookbooks`  
**Authentication:** Required (Bearer token)  
**Description:** Get all cookbooks for the current user

**Request Body:** None

**Example Request:**

```bash
curl -X GET http://localhost:5000/api/cookbooks \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "user_id": 1,
  "cookbooks": [
    {
      "id": 1,
      "name": "Saved Recipes",
      "description": "My favorite recipes"
    },
    {
      "id": 2,
      "name": "Italian Dishes",
      "description": "Classic Italian cuisine"
    }
  ]
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token

---

### 2. Create Cookbook

**HTTP Method:** `POST`  
**Route:** `/cookbooks`  
**Authentication:** Required (Bearer token)  
**Description:** Create a new cookbook for the current user

**Request Body:**

```json
{
  "name": "string (required, 1-255 chars)",
  "description": "string (optional, max 1000 chars)"
}
```

**Example Request:**

```bash
curl -X POST http://localhost:5000/api/cookbooks \
  -H "Authorization: Bearer abc123def456ghi789..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Breakfast Ideas",
    "description": "Quick and easy breakfast recipes"
  }'
```

**Example Response (201 Created):**

```json
{
  "success": true,
  "message": "Cookbook created successfully",
  "cookbook": {
    "id": 3,
    "name": "Breakfast Ideas",
    "description": "Quick and easy breakfast recipes",
    "recipes": []
  }
}
```

**Error Responses:**

- `400 Bad Request` - Validation error (missing name, invalid lengths)
- `401 Unauthorized` - Missing or invalid token

---

### 3. Get Cookbook

**HTTP Method:** `GET`  
**Route:** `/cookbooks/<cookbook_id>`  
**Authentication:** Required (Bearer token)  
**Description:** Get a specific cookbook by ID with all its recipes

**Request Body:** None

**Example Request:**

```bash
curl -X GET http://localhost:5000/api/cookbooks/1 \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "cookbook": {
    "id": 1,
    "name": "Saved Recipes",
    "description": "My favorite recipes",
    "recipes": [
      {
        "id": 5,
        "creator_id": 1,
        "title": "Pasta Carbonara",
        "image_url": "https://s3.amazonaws.com/inmybeli/recipe/abc123.jpg",
        "time_minutes": 30,
        "cuisine": "Italian"
      }
    ]
  }
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Cookbook not found

---

### 4. Update Cookbook

**HTTP Method:** `PUT`  
**Route:** `/cookbooks/<cookbook_id>`  
**Authentication:** Required (Bearer token)  
**Description:** Update cookbook name or description. Only the cookbook creator can update it.

**Request Body:**

```json
{
  "name": "string (optional, 1-255 chars)",
  "description": "string (optional, max 1000 chars)"
}
```

**Example Request:**

```bash
curl -X PUT http://localhost:5000/api/cookbooks/1 \
  -H "Authorization: Bearer abc123def456ghi789..." \
  -H "Content-Type: application/json" \
  -d '{
    "description": "My absolute favorite recipes"
  }'
```

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Cookbook updated successfully",
  "cookbook": {
    "id": 1,
    "name": "Saved Recipes",
    "description": "My absolute favorite recipes",
    "recipes": []
  }
}
```

**Error Responses:**

- `400 Bad Request` - Validation error
- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Cookbook not found

---

### 5. Delete Cookbook

**HTTP Method:** `DELETE`  
**Route:** `/cookbooks/<cookbook_id>`  
**Authentication:** Required (Bearer token)  
**Description:** Delete a cookbook. Only the cookbook creator can delete it.

**Request Body:** None

**Example Request:**

```bash
curl -X DELETE http://localhost:5000/api/cookbooks/2 \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Cookbook deleted successfully"
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Cookbook not found

---

### 6. Add Recipe to Cookbook

**HTTP Method:** `POST`  
**Route:** `/cookbooks/<cookbook_id>/recipes`  
**Authentication:** Required (Bearer token)  
**Description:** Add a recipe to a cookbook. Only the cookbook creator can add recipes to their cookbook.

**Request Body:**

```json
{
  "recipe_id": "integer (required)"
}
```

**Example Request:**

```bash
curl -X POST http://localhost:5000/api/cookbooks/1/recipes \
  -H "Authorization: Bearer abc123def456ghi789..." \
  -H "Content-Type: application/json" \
  -d '{
    "recipe_id": 5
  }'
```

**Example Response (201 Created):**

```json
{
  "success": true,
  "message": "Recipe added to cookbook",
  "cookbook": {
    "id": 1,
    "name": "Saved Recipes",
    "description": "My favorite recipes",
    "recipes": [
      {
        "id": 5,
        "creator_id": 1,
        "title": "Pasta Carbonara",
        "image_url": "https://s3.amazonaws.com/inmybeli/recipe/abc123.jpg",
        "time_minutes": 30,
        "cuisine": "Italian"
      }
    ]
  }
}
```

**Error Responses:**

- `400 Bad Request` - Validation error
- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Cookbook or recipe not found
- `409 Conflict` - Recipe already in cookbook

---

### 7. Remove Recipe from Cookbook

**HTTP Method:** `DELETE`  
**Route:** `/cookbooks/<cookbook_id>/recipes/<recipe_id>`  
**Authentication:** Required (Bearer token)  
**Description:** Remove a recipe from a cookbook. Only the cookbook creator can remove recipes.

**Request Body:** None

**Example Request:**

```bash
curl -X DELETE http://localhost:5000/api/cookbooks/1/recipes/5 \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Recipe removed from cookbook",
  "cookbook": {
    "id": 1,
    "name": "Saved Recipes",
    "description": "My favorite recipes",
    "recipes": []
  }
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Cookbook, recipe, or association not found

---

## Friends Endpoints

### 1. Get Friends

**HTTP Method:** `GET`  
**Route:** `/friends`  
**Authentication:** Required (Bearer token)  
**Description:** Get all accepted friends for the current user

**Request Body:** None

**Example Request:**

```bash
curl -X GET http://localhost:5000/api/friends \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "user_id": 1,
  "friends": [
    {
      "id": 2,
      "username": "alice"
    },
    {
      "id": 3,
      "username": "bob"
    }
  ]
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token

---

### 2. Get Pending Received Friend Requests

**HTTP Method:** `GET`  
**Route:** `/friends/pending/received`  
**Authentication:** Required (Bearer token)  
**Description:** Get all pending friend requests received by the current user

**Request Body:** None

**Example Request:**

```bash
curl -X GET http://localhost:5000/api/friends/pending/received \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "user_id": 1,
  "received_pending_requests": [
    {
      "id": 4,
      "username": "charlie",
      "name": "Charlie Brown"
    },
    {
      "id": 5,
      "username": "diana",
      "name": "Diana Prince"
    }
  ]
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token

---

### 3. Get Pending Sent Friend Requests

**HTTP Method:** `GET`  
**Route:** `/friends/pending/sent`  
**Authentication:** Required (Bearer token)  
**Description:** Get all pending friend requests sent by the current user

**Request Body:** None

**Example Request:**

```bash
curl -X GET http://localhost:5000/api/friends/pending/sent \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "user_id": 1,
  "sent_pending_requests": [
    {
      "id": 6,
      "username": "eve",
      "name": "Eve Wilson"
    }
  ]
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token

---

### 4. Search Users

**HTTP Method:** `GET`  
**Route:** `/friends/search/<name>`  
**Authentication:** Required (Bearer token)  
**Description:** Search for users by username. Returns top 20 results containing the search string (case-insensitive partial match).

**Request Body:** None

**Example Request:**

```bash
curl -X GET http://localhost:5000/api/friends/search/al \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "results": [
    {
      "id": 2,
      "name": "Alice Smith",
      "username": "alice",
      "profile_url": "https://s3.amazonaws.com/inmybeli/pfp/alice.jpg",
      "created_at": "2026-04-20T10:30:00+00:00"
    },
    {
      "id": 7,
      "name": "Albert Johnson",
      "username": "albertj",
      "profile_url": "https://s3.amazonaws.com/inmybeli/pfp/albert.jpg",
      "created_at": "2026-04-15T14:20:00+00:00"
    }
  ]
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token

---

### 5. Send Friend Request

**HTTP Method:** `POST`  
**Route:** `/friends/request`  
**Authentication:** Required (Bearer token)  
**Description:** Send a friend request to another user

**Request Body:**

```json
{
  "friend_id": "integer (required)"
}
```

**Example Request:**

```bash
curl -X POST http://localhost:5000/api/friends/request \
  -H "Authorization: Bearer abc123def456ghi789..." \
  -H "Content-Type: application/json" \
  -d '{
    "friend_id": 4
  }'
```

**Example Response (201 Created):**

```json
{
  "success": true,
  "message": "Friend request sent"
}
```

**Error Responses:**

- `400 Bad Request` - Validation error or invalid friend request (already friends, request already sent, etc.)
- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Friend not found

---

### 6. Accept Friend Request

**HTTP Method:** `POST`  
**Route:** `/friends/accept`  
**Authentication:** Required (Bearer token)  
**Description:** Accept a pending friend request from another user

**Request Body:**

```json
{
  "friend_id": "integer (required)"
}
```

**Example Request:**

```bash
curl -X POST http://localhost:5000/api/friends/accept \
  -H "Authorization: Bearer abc123def456ghi789..." \
  -H "Content-Type: application/json" \
  -d '{
    "friend_id": 4
  }'
```

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Friend request accepted"
}
```

**Error Responses:**

- `400 Bad Request` - Validation error or invalid friendship state
- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Friend not found

---

### 7. Decline Friend Request

**HTTP Method:** `POST`  
**Route:** `/friends/decline`  
**Authentication:** Required (Bearer token)  
**Description:** Decline a pending friend request from another user. You can only decline requests sent to you, not those you sent.

**Request Body:**

```json
{
  "friend_id": "integer (required)"
}
```

**Example Request:**

```bash
curl -X POST http://localhost:5000/api/friends/decline \
  -H "Authorization: Bearer abc123def456ghi789..." \
  -H "Content-Type: application/json" \
  -d '{
    "friend_id": 4
  }'
```

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Friend request declined"
}
```

**Error Responses:**

- `400 Bad Request` - Validation error or invalid state (e.g., trying to decline request you sent)
- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - No pending friend request found

---

### 8. Remove Friend

**HTTP Method:** `DELETE`  
**Route:** `/friends/<friend_id>`  
**Authentication:** Required (Bearer token)  
**Description:** Remove a friend from the friend list

**Request Body:** None

**Example Request:**

```bash
curl -X DELETE http://localhost:5000/api/friends/2 \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Friend removed"
}
```

**Error Responses:**

- `400 Bad Request` - Cannot remove yourself
- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Friendship not found

---

### 9. Check Friend Status

**HTTP Method:** `GET`  
**Route:** `/friends/<friend_id>`  
**Authentication:** Required (Bearer token)  
**Description:** Check if two users are friends

**Request Body:** None

**Example Request:**

```bash
curl -X GET http://localhost:5000/api/friends/2 \
  -H "Authorization: Bearer abc123def456ghi789..."
```

**Example Response (200 OK):**

```json
{
  "user_id": 1,
  "friend_id": 2,
  "is_friend": true
}
```

**Error Responses:**

- `400 Bad Request` - Cannot check friendship with yourself
- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Friend not found
