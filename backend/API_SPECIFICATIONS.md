# InMyBeli API Specifications

## Base URL

```
http://localhost:5000/api
```

## Authentication

Most endpoints require Bearer token authentication. Include the token in the Authorization header:

```
Authorization: Bearer <session_token>
```

Public endpoints (no auth required):

- `POST /users/create/`
- `POST /users/login/`
- `POST /users/autologin/`
- `GET /users/tokens`

---

## Users Endpoints

### 1. Create Account

**Route:** `/users/create/`  
**Method:** `POST`  
**Authentication:** None (Public)  
**Description:** Create a new user account

**Request Body:**

```json
{
  "name": "string (required, 1-255 chars)",
  "username": "string (required, 3-50 chars, must be unique)",
  "password": "string (required, minimum 8 chars)"
}
```

**Example Request:**

```json
{
  "name": "John Doe",
  "username": "johndoe",
  "password": "securepass123"
}
```

**Example Response (201 Created):**

```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "username": "johndoe",
    "created_at": "2026-04-29T10:30:00+00:00"
  },
  "session_token": "abc123def456..."
}
```

**Error Responses:**

- `400 Bad Request` - Validation error (missing fields, invalid length)
- `400 Bad Request` - Username already exists

---

### 2. Login

**Route:** `/users/login/`  
**Method:** `POST`  
**Authentication:** None (Public)  
**Description:** Login a user with username and password

**Request Body:**

```json
{
  "username": "string (required)",
  "password": "string (required)"
}
```

**Example Request:**

```json
{
  "username": "johndoe",
  "password": "securepass123"
}
```

**Example Response (200 OK):**

```json
{
  "success": true,
  "user": {
    "id": 1,
    "name": "John Doe",
    "username": "johndoe",
    "created_at": "2026-04-29T10:30:00+00:00"
  },
  "token": "xyz789abc123..."
}
```

**Error Responses:**

- `400 Bad Request` - Validation error (missing fields)
- `401 Unauthorized` - Invalid credentials

---

### 3. Auto Login

**Route:** `/users/autologin/`  
**Method:** `POST`  
**Authentication:** None (Public)  
**Description:** Automatically login a user with a valid session token

**Request Body:**

```json
{
  "token": "string (required, valid session token)"
}
```

**Example Request:**

```json
{
  "token": "abc123def456..."
}
```

**Example Response (200 OK):**

```json
{
  "success": true,
  "user": {
    "id": 1,
    "name": "John Doe",
    "username": "johndoe",
    "created_at": "2026-04-29T10:30:00+00:00"
  },
  "token": "abc123def456..."
}
```

**Error Responses:**

- `400 Bad Request` - Validation error (missing token)
- `401 Unauthorized` - Invalid or expired token
- `500 Internal Server Error` - User not found in database

---

### 4. Get Current User

**Route:** `/users/`  
**Method:** `GET`  
**Authentication:** Required (Bearer token)  
**Description:** Get information about the currently authenticated user

**Request Body:** None

**Example Response (200 OK):**

```json
{
  "id": 1,
  "name": "John Doe",
  "username": "johndoe",
  "created_at": "2026-04-29T10:30:00+00:00"
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token

---

### 5. Get All Tokens

**Route:** `/users/tokens`  
**Method:** `GET`  
**Authentication:** None (Public)  
**Description:** Get all active session tokens (for debugging/testing only)

**Request Body:** None

**Example Response (200 OK):**

```json
{
  "tokens": [
    {
      "id": 1,
      "token": "abc123def456...",
      "user_id": 1,
      "created_at": "2026-04-29T10:30:00+00:00"
    }
  ]
}
```

---

## Friends Endpoints

All friends endpoints require authentication.

### 1. Get Friends

**Route:** `/users/friends/`  
**Method:** `GET`  
**Authentication:** Required  
**Description:** Get all accepted friends for the current user

**Request Body:** None

**Example Response (200 OK):**

```json
{
  "user_id": 1,
  "friends": [
    {
      "id": 2,
      "username": "janedoe"
    },
    {
      "id": 3,
      "username": "bobsmith"
    }
  ]
}
```

---

### 2. Get Received Friend Requests

**Route:** `/users/friends/pending/received/`  
**Method:** `GET`  
**Authentication:** Required  
**Description:** Get all received pending friend requests

**Request Body:** None

**Example Response (200 OK):**

```json
{
  "user_id": 1,
  "received_pending_requests": [
    {
      "id": 4,
      "username": "alicekim",
      "name": "Alice Kim"
    }
  ]
}
```

---

### 3. Get Sent Friend Requests

**Route:** `/users/friends/pending/sent/`  
**Method:** `GET`  
**Authentication:** Required  
**Description:** Get all sent pending friend requests

**Request Body:** None

**Example Response (200 OK):**

```json
{
  "user_id": 1,
  "sent_pending_requests": [
    {
      "id": 5,
      "username": "mikechen",
      "name": "Mike Chen"
    }
  ]
}
```

---

### 4. Search Users

**Route:** `/users/friends/search/<string:name>`  
**Method:** `GET`  
**Authentication:** Required  
**Description:** Search for users by username (case-insensitive, supports partial matches)

**Path Parameters:**

- `name` (string) - Search query (substring of username)

**Request Body:** None

**Example Request:** `/users/friends/search/john`

**Example Response (200 OK):**

```json
{
  "results": [
    {
      "id": 1,
      "name": "John Doe",
      "username": "johndoe",
      "created_at": "2026-04-29T10:30:00+00:00"
    },
    {
      "id": 6,
      "name": "Johnny Walker",
      "username": "johnnywalker",
      "created_at": "2026-04-29T11:00:00+00:00"
    }
  ]
}
```

---

### 5. Send Friend Request

**Route:** `/users/friends/request/`  
**Method:** `POST`  
**Authentication:** Required  
**Description:** Send a friend request to another user

**Request Body:**

```json
{
  "friend_id": "integer (required, ID of user to request)"
}
```

**Example Request:**

```json
{
  "friend_id": 2
}
```

**Example Response (201 Created):**

```json
{
  "success": true,
  "message": "Friend request sent"
}
```

**Error Responses:**

- `400 Bad Request` - Cannot be friends with yourself
- `400 Bad Request` - Friend request already sent / already friends
- `404 Not Found` - Friend not found

---

### 6. Accept Friend Request

**Route:** `/users/friends/accept/`  
**Method:** `POST`  
**Authentication:** Required  
**Description:** Accept a pending friend request

**Request Body:**

```json
{
  "friend_id": "integer (required, ID of user to accept)"
}
```

**Example Request:**

```json
{
  "friend_id": 4
}
```

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Friend request accepted"
}
```

**Error Responses:**

- `400 Bad Request` - Cannot be friends with yourself
- `400 Bad Request` - No pending request / already friends
- `404 Not Found` - Friend not found

---

### 7. Decline Friend Request

**Route:** `/users/friends/decline/`  
**Method:** `POST`  
**Authentication:** Required  
**Description:** Decline a pending friend request

**Request Body:**

```json
{
  "friend_id": "integer (required, ID of user to decline)"
}
```

**Example Request:**

```json
{
  "friend_id": 5
}
```

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Friend request declined"
}
```

**Error Responses:**

- `400 Bad Request` - Cannot decline yourself
- `400 Bad Request` - No pending request to decline
- `404 Not Found` - Friend not found

---

### 8. Remove Friend

**Route:** `/users/friends/<int:friend_id>/`  
**Method:** `DELETE`  
**Authentication:** Required  
**Description:** Remove an accepted friend

**Path Parameters:**

- `friend_id` (integer) - ID of friend to remove

**Request Body:** None

**Example Request:** `/users/friends/2/`

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Friend removed"
}
```

**Error Responses:**

- `400 Bad Request` - Cannot remove yourself
- `404 Not Found` - Friend not found / friendship not found

---

### 9. Check Friendship Status

**Route:** `/users/friends/<int:friend_id>/`  
**Method:** `GET`  
**Authentication:** Required  
**Description:** Check the relationship status between current user and another user

**Path Parameters:**

- `friend_id` (integer) - ID of user to check

**Request Body:** None

**Example Request:** `/users/friends/2/`

**Example Response (200 OK):**

```json
{
  "user_id": 1,
  "friend_id": 2,
  "is_friend": "accepted"
}
```

**Possible values for `is_friend`:** "accepted", "pending", "blocked", "None"

**Error Responses:**

- `400 Bad Request` - Cannot check friendship with yourself
- `404 Not Found` - Friend not found

---

## Cookbooks Endpoints

All cookbook endpoints require authentication.

### 1. Get All Cookbooks

**Route:** `/users/cookbooks/`  
**Method:** `GET`  
**Authentication:** Required  
**Description:** Get all cookbooks created by the current user

**Request Body:** None

**Example Response (200 OK):**

```json
{
  "user_id": 1,
  "cookbooks": [
    {
      "id": 1,
      "name": "Italian Favorites",
      "description": "My favorite Italian recipes"
    },
    {
      "id": 2,
      "name": "Quick Weeknight Dinners",
      "description": null
    }
  ]
}
```

---

### 2. Create Cookbook

**Route:** `/users/cookbooks/`  
**Method:** `POST`  
**Authentication:** Required  
**Description:** Create a new cookbook

**Request Body:**

```json
{
  "name": "string (required, 1-255 chars)",
  "description": "string (optional, max 1000 chars)"
}
```

**Example Request:**

```json
{
  "name": "Desserts",
  "description": "Collection of favorite dessert recipes"
}
```

**Example Response (201 Created):**

```json
{
  "success": true,
  "message": "Cookbook created successfully",
  "cookbook": {
    "id": 3,
    "name": "Desserts",
    "description": "Collection of favorite dessert recipes",
    "recipes": []
  }
}
```

**Error Responses:**

- `400 Bad Request` - Validation error (missing name)

---

### 3. Get Cookbook

**Route:** `/users/cookbooks/<int:cookbook_id>/`  
**Method:** `GET`  
**Authentication:** Required  
**Description:** Get a specific cookbook by ID with all recipes

**Path Parameters:**

- `cookbook_id` (integer) - ID of cookbook to retrieve

**Request Body:** None

**Example Request:** `/users/cookbooks/1/`

**Example Response (200 OK):**

```json
{
  "cookbook": {
    "id": 1,
    "name": "Italian Favorites",
    "description": "My favorite Italian recipes",
    "recipes": [
      {
        "id": 1,
        "creator_id": 1,
        "title": "Spaghetti Carbonara",
        "image_url": "https://example.com/image.jpg",
        "time_minutes": 30,
        "cuisine": "Italian"
      }
    ]
  }
}
```

**Error Responses:**

- `404 Not Found` - Cookbook not found or not owned by current user

---

### 4. Update Cookbook

**Route:** `/users/cookbooks/<int:cookbook_id>/`  
**Method:** `PUT`  
**Authentication:** Required  
**Description:** Update name and/or description of a cookbook (only creator can update)

**Path Parameters:**

- `cookbook_id` (integer) - ID of cookbook to update

**Request Body:**

```json
{
  "name": "string (optional, 1-255 chars)",
  "description": "string (optional, max 1000 chars)"
}
```

**Example Request:**

```json
{
  "name": "Italian Classics",
  "description": "Updated description"
}
```

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Cookbook updated successfully",
  "cookbook": {
    "id": 1,
    "name": "Italian Classics",
    "description": "Updated description",
    "recipes": []
  }
}
```

**Error Responses:**

- `400 Bad Request` - Validation error
- `404 Not Found` - Cookbook not found or not owned by current user

---

### 5. Delete Cookbook

**Route:** `/users/cookbooks/<int:cookbook_id>/`  
**Method:** `DELETE`  
**Authentication:** Required  
**Description:** Delete a cookbook (only creator can delete)

**Path Parameters:**

- `cookbook_id` (integer) - ID of cookbook to delete

**Request Body:** None

**Example Request:** `/users/cookbooks/1/`

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Cookbook deleted successfully"
}
```

**Error Responses:**

- `404 Not Found` - Cookbook not found or not owned by current user

---

### 6. Add Recipe to Cookbook

**Route:** `/users/cookbooks/<int:cookbook_id>/recipes/`  
**Method:** `POST`  
**Authentication:** Required  
**Description:** Add a recipe to a cookbook

**Path Parameters:**

- `cookbook_id` (integer) - ID of cookbook

**Request Body:**

```json
{
  "recipe_id": "integer (required, ID of recipe to add)"
}
```

**Example Request:**

```json
{
  "recipe_id": 5
}
```

**Example Response (201 Created):**

```json
{
  "success": true,
  "message": "Recipe added to cookbook",
  "cookbook": {
    "id": 1,
    "name": "Italian Favorites",
    "description": "My favorite Italian recipes",
    "recipes": [
      {
        "id": 5,
        "creator_id": 2,
        "title": "Pesto Pasta",
        "image_url": "https://example.com/pesto.jpg",
        "time_minutes": 20,
        "cuisine": "Italian"
      }
    ]
  }
}
```

**Error Responses:**

- `400 Bad Request` - Validation error
- `404 Not Found` - Cookbook not found or not owned by current user
- `404 Not Found` - Recipe not found
- `409 Conflict` - Recipe already in cookbook

---

### 7. Remove Recipe from Cookbook

**Route:** `/users/cookbooks/<int:cookbook_id>/recipes/<int:recipe_id>/`  
**Method:** `DELETE`  
**Authentication:** Required  
**Description:** Remove a recipe from a cookbook

**Path Parameters:**

- `cookbook_id` (integer) - ID of cookbook
- `recipe_id` (integer) - ID of recipe to remove

**Request Body:** None

**Example Request:** `/users/cookbooks/1/recipes/5/`

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Recipe removed from cookbook"
}
```

**Error Responses:**

- `404 Not Found` - Cookbook not found or not owned by current user
- `404 Not Found` - Recipe not found
- `404 Not Found` - Recipe not in cookbook

---

## Recipes Endpoints

All recipe endpoints require authentication.

### 1. Create Recipe

**Route:** `/recipes/`  
**Method:** `POST`  
**Authentication:** Required  
**Description:** Create a new recipe owned by the current user

**Request Body:**

```json
{
  "title": "string (required, 1-255 chars)",
  "description": "string (optional, max 2000 chars)",
  "image_url": "string (optional, max 500 chars)",
  "time_minutes": "integer (optional, 0-10000)",
  "cuisine": "string (optional, max 100 chars)",
  "servings": "integer (optional, 1-1000)",
  "ingredients": "array of objects (optional)",
  "instructions": "array of strings (optional)"
}
```

**Example Request:**

```json
{
  "title": "Chocolate Chip Cookies",
  "description": "Classic chocolate chip cookies",
  "image_url": "https://example.com/cookies.jpg",
  "time_minutes": 30,
  "cuisine": "American",
  "servings": 24,
  "ingredients": [
    { "name": "flour", "amount": "2 cups" },
    { "name": "butter", "amount": "1 cup" }
  ],
  "instructions": [
    "Preheat oven to 375F",
    "Mix ingredients",
    "Bake for 12 minutes"
  ]
}
```

**Example Response (201 Created):**

```json
{
  "id": 1,
  "creator_id": 1,
  "title": "Chocolate Chip Cookies",
  "description": "Classic chocolate chip cookies",
  "image_url": "https://example.com/cookies.jpg",
  "time_minutes": 30,
  "cuisine": "American",
  "servings": 24,
  "ingredients": [
    { "name": "flour", "amount": "2 cups" },
    { "name": "butter", "amount": "1 cup" }
  ],
  "instructions": [
    "Preheat oven to 375F",
    "Mix ingredients",
    "Bake for 12 minutes"
  ],
  "created_at": "2026-04-29T10:30:00+00:00",
  "updated_at": "2026-04-29T10:30:00+00:00"
}
```

**Error Responses:**

- `400 Bad Request` - Validation error (missing title)

---

### 2. Get Recipe

**Route:** `/recipes/<int:recipe_id>/`  
**Method:** `GET`  
**Authentication:** Required  
**Description:** Get a specific recipe by ID (full view with all details)

**Path Parameters:**

- `recipe_id` (integer) - ID of recipe to retrieve

**Request Body:** None

**Example Request:** `/recipes/1/`

**Example Response (200 OK):**

```json
{
  "id": 1,
  "creator_id": 1,
  "title": "Chocolate Chip Cookies",
  "description": "Classic chocolate chip cookies",
  "image_url": "https://example.com/cookies.jpg",
  "time_minutes": 30,
  "cuisine": "American",
  "servings": 24,
  "ingredients": [
    { "name": "flour", "amount": "2 cups" },
    { "name": "butter", "amount": "1 cup" }
  ],
  "instructions": [
    "Preheat oven to 375F",
    "Mix ingredients",
    "Bake for 12 minutes"
  ],
  "created_at": "2026-04-29T10:30:00+00:00",
  "updated_at": "2026-04-29T10:30:00+00:00"
}
```

**Error Responses:**

- `404 Not Found` - Recipe not found

---

### 3. Update Recipe

**Route:** `/recipes/<int:recipe_id>/`  
**Method:** `PUT`  
**Authentication:** Required  
**Description:** Update an existing recipe (only creator can update)

**Path Parameters:**

- `recipe_id` (integer) - ID of recipe to update

**Request Body:**

```json
{
  "title": "string (optional, 1-255 chars)",
  "description": "string (optional, max 2000 chars)",
  "image_url": "string (optional, max 500 chars)",
  "time_minutes": "integer (optional, 0-10000)",
  "cuisine": "string (optional, max 100 chars)",
  "servings": "integer (optional, 1-1000)",
  "ingredients": "array of objects (optional)",
  "instructions": "array of strings (optional)"
}
```

**Example Request:**

```json
{
  "time_minutes": 25,
  "servings": 32
}
```

**Example Response (200 OK):**

```json
{
  "id": 1,
  "creator_id": 1,
  "title": "Chocolate Chip Cookies",
  "description": "Classic chocolate chip cookies",
  "image_url": "https://example.com/cookies.jpg",
  "time_minutes": 25,
  "cuisine": "American",
  "servings": 32,
  "ingredients": [
    { "name": "flour", "amount": "2 cups" },
    { "name": "butter", "amount": "1 cup" }
  ],
  "instructions": [
    "Preheat oven to 375F",
    "Mix ingredients",
    "Bake for 12 minutes"
  ],
  "created_at": "2026-04-29T10:30:00+00:00",
  "updated_at": "2026-04-29T10:31:00+00:00"
}
```

**Error Responses:**

- `400 Bad Request` - Validation error
- `403 Forbidden` - You do not own this recipe
- `404 Not Found` - Recipe not found

---

### 4. Delete Recipe

**Route:** `/recipes/<int:recipe_id>/`  
**Method:** `DELETE`  
**Authentication:** Required  
**Description:** Delete a recipe (only creator can delete)

**Path Parameters:**

- `recipe_id` (integer) - ID of recipe to delete

**Request Body:** None

**Example Request:** `/recipes/1/`

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Recipe deleted"
}
```

**Error Responses:**

- `403 Forbidden` - You do not own this recipe
- `404 Not Found` - Recipe not found

---

### 5. Get Recipes by User

**Route:** `/users/<int:user_id>/recipes/`  
**Method:** `GET`  
**Authentication:** Required  
**Description:** Get all recipes created by a specific user (returns previews, not full recipes)

**Path Parameters:**

- `user_id` (integer) - ID of user whose recipes to retrieve

**Request Body:** None

**Example Request:** `/users/1/recipes/`

**Example Response (200 OK):**

```json
{
  "user_id": 1,
  "recipes": [
    {
      "id": 1,
      "creator_id": 1,
      "title": "Chocolate Chip Cookies",
      "image_url": "https://example.com/cookies.jpg",
      "time_minutes": 30,
      "cuisine": "American"
    },
    {
      "id": 2,
      "creator_id": 1,
      "title": "Spaghetti Carbonara",
      "image_url": "https://example.com/carbonara.jpg",
      "time_minutes": 30,
      "cuisine": "Italian"
    }
  ]
}
```

---

### 6. Create or Update Review

**Route:** `/recipes/<int:recipe_id>/reviews/`  
**Method:** `POST`  
**Authentication:** Required  
**Description:** Create a new review or update an existing one for a recipe. A user can have at most one review per recipe — calling when one already exists updates the existing review.

**Path Parameters:**

- `recipe_id` (integer) - ID of recipe to review

**Request Body:**

```json
{
  "rating": "integer (required, 1-5)",
  "text": "string (optional, max 2000 chars)"
}
```

**Example Request:**

```json
{
  "rating": 5,
  "text": "Absolutely delicious! Will make again."
}
```

**Example Response (201 Created) - New Review:**

```json
{
  "id": 1,
  "user_id": 1,
  "recipe_id": 1,
  "rating": 5,
  "text": "Absolutely delicious! Will make again.",
  "created_at": "2026-04-29T10:30:00+00:00",
  "updated_at": "2026-04-29T10:30:00+00:00"
}
```

**Example Response (200 OK) - Updated Review:**

```json
{
  "id": 1,
  "user_id": 1,
  "recipe_id": 1,
  "rating": 4,
  "text": "Pretty good, but a bit too sweet.",
  "created_at": "2026-04-29T10:30:00+00:00",
  "updated_at": "2026-04-29T10:35:00+00:00"
}
```

**Error Responses:**

- `400 Bad Request` - Validation error (invalid rating, missing required fields)
- `404 Not Found` - Recipe not found
- `409 Conflict` - Review already exists (use PUT to update instead)

---

### 7. Get Reviews for Recipe

**Route:** `/recipes/<int:recipe_id>/reviews/`  
**Method:** `GET`  
**Authentication:** Required  
**Description:** Get all reviews for a specific recipe, sorted by most recent first

**Path Parameters:**

- `recipe_id` (integer) - ID of recipe

**Request Body:** None

**Example Request:** `/recipes/1/reviews/`

**Example Response (200 OK):**

```json
{
  "recipe_id": 1,
  "reviews": [
    {
      "id": 2,
      "user_id": 2,
      "recipe_id": 1,
      "rating": 5,
      "text": "Love this recipe!",
      "created_at": "2026-04-29T11:00:00+00:00",
      "updated_at": "2026-04-29T11:00:00+00:00"
    },
    {
      "id": 1,
      "user_id": 1,
      "recipe_id": 1,
      "rating": 4,
      "text": "Pretty good, but a bit too sweet.",
      "created_at": "2026-04-29T10:30:00+00:00",
      "updated_at": "2026-04-29T10:35:00+00:00"
    }
  ]
}
```

**Error Responses:**

- `404 Not Found` - Recipe not found

---

## Error Handling

All error responses follow this format:

```json
{
  "error": "Error message describing what went wrong"
}
```

### Common HTTP Status Codes

- `200 OK` - Request successful
- `201 Created` - Resource created successfully
- `400 Bad Request` - Invalid input or validation error
- `401 Unauthorized` - Missing or invalid authentication token
- `403 Forbidden` - Authenticated user doesn't have permission (e.g., trying to delete another user's recipe)
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource conflict (e.g., duplicate entry)
- `500 Internal Server Error` - Server error

---

## Notes

- All timestamps are in ISO 8601 format with UTC timezone
- Passwords are hashed using secure algorithms and never returned in responses
- Session tokens are generated automatically and should be stored securely on the client
- Users can only modify/delete their own resources (recipes, cookbooks)
- Friendship relationships require mutual consent (pending → accepted)
