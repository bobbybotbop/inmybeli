# InMyBeli API Specifications

## Base URL

Default local server:

```
http://127.0.0.1:5000
```

Blueprints are mounted as follows (full paths below each endpoint):

| Area     | Prefix            |
|----------|-------------------|
| Users    | `/api/users`      |
| Friends  | `/api/friends`    |
| Cookbooks| `/api/cookbooks`  |
| Recipes  | `/api`            |

## Authentication

Most endpoints require Bearer token authentication. Include the token in the Authorization header:

```
Authorization: Bearer <session_token>
```

Public endpoints (no auth required):

- `POST /api/users/create` or `POST /api/users/create/`
- `POST /api/users/login/`
- `POST /api/users/autologin/`
- `GET /api/users/tokens`

---

## Users Endpoints

### 1. Create Account

**Route:** `POST /api/users/create` or `POST /api/users/create/`  
**Method:** `POST`  
**Authentication:** None (Public)  
**Description:** Create a new user account (multipart form-data; optional profile picture upload to S3)

**Request:** `multipart/form-data`

| Field             | Type   | Required |
|-------------------|--------|----------|
| `name`            | text   | Yes      |
| `username`        | text   | Yes      |
| `password`        | text   | Yes (min 8 chars) |
| `profile_picture` | file   | No       |

**Example (Postman / curl):** form fields `name`, `username`, `password`, optional file key `profile_picture`.

**Example Response (201 Created):**

```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "username": "johndoe",
    "profile_url": "https://appdev-inmybeli.s3.us-east-2.amazonaws.com/assets/blankpfp.png",
    "created_at": "2026-04-29T10:30:00+00:00"
  },
  "session_token": "abc123def456..."
}
```

**Error Responses:**

- `400 Bad Request` - Validation error (missing fields, invalid length); body may be Marshmallow field errors
- `400 Bad Request` - Username already exists
- `500 Internal Server Error` - Profile picture S3 upload failed (e.g. missing AWS credentials)

---

### 2. Login

**Route:** `POST /api/users/login/`  
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
    "profile_url": "https://example.com/pfp.jpg",
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

**Route:** `POST /api/users/autologin/`  
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
    "profile_url": "https://example.com/pfp.jpg",
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

**Route:** `GET /api/users/`  
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
  "profile_url": "https://example.com/pfp.jpg",
  "created_at": "2026-04-29T10:30:00+00:00"
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token

---

### 5. Get All Tokens

**Route:** `GET /api/users/tokens`  
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
      "expiresAt": "2026-04-30T10:30:00",
      "created_at": "2026-04-29T10:30:00+00:00"
    }
  ]
}
```

---

## Friends Endpoints

All friends endpoints require authentication.

### 1. Get Friends

**Route:** `/api/friends/`  
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

**Route:** `/api/friends/pending/received/`  
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

**Route:** `/api/friends/pending/sent/`  
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

**Route:** `/api/friends/search/<string:name>`  
**Method:** `GET`  
**Authentication:** Required  
**Description:** Search for users by username (case-insensitive, supports partial matches)

**Path Parameters:**

- `name` (string) - Search query (substring of username)

**Request Body:** None

**Example Request:** `/api/friends/search/john`

**Example Response (200 OK):**

```json
{
  "results": [
    {
      "id": 1,
      "name": "John Doe",
      "username": "johndoe",
      "profile_url": "https://example.com/pfp1.jpg",
      "created_at": "2026-04-29T10:30:00+00:00"
    },
    {
      "id": 6,
      "name": "Johnny Walker",
      "username": "johnnywalker",
      "profile_url": "https://example.com/pfp2.jpg",
      "created_at": "2026-04-29T11:00:00+00:00"
    }
  ]
}
```

---

### 5. Send Friend Request

**Route:** `/api/friends/request/`  
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

**Route:** `/api/friends/accept/`  
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

**Route:** `/api/friends/decline/`  
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

**Route:** `/api/friends/<int:friend_id>/`  
**Method:** `DELETE`  
**Authentication:** Required  
**Description:** Remove an accepted friend

**Path Parameters:**

- `friend_id` (integer) - ID of friend to remove

**Request Body:** None

**Example Request:** `/api/friends/2/`

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

**Route:** `/api/friends/<int:friend_id>/`  
**Method:** `GET`  
**Authentication:** Required  
**Description:** Check the relationship status between current user and another user

**Path Parameters:**

- `friend_id` (integer) - ID of user to check

**Request Body:** None

**Example Request:** `/api/friends/2/`

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

**Route:** `/api/cookbooks/`  
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

**Route:** `/api/cookbooks/`  
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

**Route:** `/api/cookbooks/<int:cookbook_id>/`  
**Method:** `GET`  
**Authentication:** Required  
**Description:** Get a specific cookbook by ID with all recipes

**Path Parameters:**

- `cookbook_id` (integer) - ID of cookbook to retrieve

**Request Body:** None

**Example Request:** `/api/cookbooks/1/`

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

**Route:** `/api/cookbooks/<int:cookbook_id>/`  
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

**Route:** `/api/cookbooks/<int:cookbook_id>/`  
**Method:** `DELETE`  
**Authentication:** Required  
**Description:** Delete a cookbook (only creator can delete)

**Path Parameters:**

- `cookbook_id` (integer) - ID of cookbook to delete

**Request Body:** None

**Example Request:** `/api/cookbooks/1/`

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

**Route:** `/api/cookbooks/<int:cookbook_id>/recipes/`  
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

**Route:** `/api/cookbooks/<int:cookbook_id>/recipes/<int:recipe_id>/`  
**Method:** `DELETE`  
**Authentication:** Required  
**Description:** Remove a recipe from a cookbook

**Path Parameters:**

- `cookbook_id` (integer) - ID of cookbook
- `recipe_id` (integer) - ID of recipe to remove

**Request Body:** None

**Example Request:** `/api/cookbooks/1/recipes/5/`

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

All recipe endpoints require authentication (`Authorization: Bearer <token>`).

### 1. Create Recipe

**Route:** `POST /api/recipes/`  
**Method:** `POST`  
**Authentication:** Required  
**Description:** Create a new recipe for the current user. Uses **multipart/form-data** (same pattern as account creation). Optional file field `image` is uploaded to S3; `ingredients` / `instructions` may be sent as JSON strings so Marshmallow can parse them.

**Request:** `multipart/form-data`

| Field            | Type | Notes |
|------------------|------|--------|
| `title`          | text | Required |
| `description`    | text | Optional |
| `time_minutes`   | text | Optional integer string |
| `cuisine`        | text | Optional |
| `servings`       | text | Optional integer string |
| `ingredients`    | text | Optional; JSON array of objects, e.g. `[{"name":"flour","amount":"2 cups"}]` |
| `instructions` | text | Optional; JSON array of strings |
| `image`          | file | Optional in schema; **recommended** — model stores `recipe_image_url` / `recipe_image_s3_key` |

**Example request (conceptual):** form fields + file `image`.

**Example Response (201 Created):** `Recipe.serialize()` — full recipe

```json
{
  "id": 1,
  "creator_id": 1,
  "title": "Chocolate Chip Cookies",
  "description": "Classic cookies",
  "recipe_image_url": "https://your-bucket.s3.amazonaws.com/recipe/uuid.jpg",
  "time_minutes": 30,
  "cuisine": "American",
  "servings": 24,
  "ingredients": [{ "name": "flour", "amount": "2 cups" }],
  "instructions": ["Preheat oven", "Mix", "Bake"],
  "created_at": "2026-04-29T10:30:00+00:00",
  "updated_at": "2026-04-29T10:30:00+00:00"
}
```

**Error Responses:** `400` validation; `500` S3 upload or DB error.

---

### 2. Get Recipe

**Route:** `GET /api/recipes/<recipe_id>/`  
**Method:** `GET`  
**Authentication:** Required  

**Example Request:** `GET /api/recipes/1/`

**Example Response (200 OK):** same shape as create response (full `Recipe.serialize()`).

**Error Responses:** `404` recipe not found.

---

### 3. Update Recipe

**Route:** `POST /api/recipes/<recipe_id>/`  
**Method:** `POST` (not PUT)  
**Authentication:** Required  
**Description:** Update recipe; **only the creator** may update. Uses **multipart/form-data**. Include only fields you want to change. Optional file `image` replaces the image (new S3 upload under `recipes/` folder).

**Request:** `multipart/form-data` — any of: `title`, `description`, `time_minutes`, `cuisine`, `servings`, `ingredients` (JSON string), `instructions` (JSON string), file `image`.

**Example Response (200 OK):** full `Recipe.serialize()` as in create.

**Error Responses:** `400` validation; `403` not owner; `404` not found; `500` upload/DB.

---

### 4. Delete Recipe

**Route:** `DELETE /api/recipes/<recipe_id>/`  
**Method:** `DELETE`  
**Authentication:** Required  
**Description:** Delete recipe (creator only).

**Example Request:** `DELETE /api/recipes/1/`

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Recipe deleted"
}
```

**Error Responses:** `403`, `404`.

---

### 5. Get Recipes by User

**Route:** `GET /api/users/<user_id>/recipes/`  
**Method:** `GET`  
**Authentication:** Required  
**Description:** List recipes by `creator_id` (preview cards).

**Example Request:** `GET /api/users/1/recipes/`

**Example Response (200 OK):**

```json
{
  "user_id": 1,
  "recipes": [
    {
      "id": 1,
      "creator_id": 1,
      "title": "Chocolate Chip Cookies",
      "image_url": "https://your-bucket.s3.amazonaws.com/recipe/uuid.jpg",
      "time_minutes": 30,
      "cuisine": "American"
    }
  ]
}
```

---

### 6. Get Recipe Feed (Discover)

**Route:** `GET /api/feed/recipes/`  
**Method:** `GET`  
**Authentication:** Required  
**Description:** All recipes for discover: ordered by calendar day (newest days first); within each day, friends’ recipes first. Each preview may include `total_saves_count` (distinct users who saved the recipe via a per-user cookbook named `"saved"`) and `friend_saved_profile_picture_urls` — up to two profile picture URLs of the current user’s accepted friends who saved the recipe via their `"saved"` cookbook, ordered by friend user id ascending. The list is empty when no friend has saved the recipe.

**Example Request:** `GET /api/feed/recipes/`

**Example Response (200 OK):**

```json
{
  "recipes": [
    {
      "id": 1,
      "creator_id": 2,
      "title": "Pasta",
      "image_url": "https://your-bucket.s3.amazonaws.com/recipe/uuid.jpg",
      "time_minutes": 20,
      "cuisine": "Italian",
      "total_saves_count": 5,
      "friend_saved_profile_picture_urls": [
        "https://your-bucket.s3.amazonaws.com/profile/friend-a.jpg",
        "https://your-bucket.s3.amazonaws.com/profile/friend-b.jpg"
      ]
    }
  ]
}
```

---

### 7. Create or Update Review

**Route:** `POST /api/recipes/<recipe_id>/reviews/`  
**Method:** `POST`  
**Authentication:** Required  
**Content-Type:** `application/json`

**Request body:**

```json
{
  "rating": 5,
  "text": "Absolutely delicious! Will make again."
}
```

**Example Response (201)** new review / **(200)** updated review — `Review.serialize()`:

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

**Error Responses:** `400`, `404`, `409` — body: `{"error": "Review already exists; retry as an update"}` (race / concurrent create).

---

### 8. Get Reviews for Recipe

**Route:** `GET /api/recipes/<recipe_id>/reviews/`  
**Method:** `GET`  
**Authentication:** Required  

**Example Request:** `GET /api/recipes/1/reviews/`

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
    }
  ]
}
```

---

### 9. Delete My Review

**Route:** `DELETE /api/recipes/<recipe_id>/reviews/`  
**Method:** `DELETE`  
**Authentication:** Required  
**Description:** Deletes the **current user’s** review for that recipe.

**Example Response (200 OK):**

```json
{
  "success": true,
  "message": "Review deleted"
}
```

**Error Responses:** `404` if this user has no review for that recipe.

---

## Error Handling

Most errors from `error()` / `success()` helpers return JSON with an `error` key. The value is usually a **string**, but **Marshmallow validation** failures may pass a **nested object** (field names to message lists), for example:

```json
{
  "error": {
    "username": ["Username is required"]
  }
}
```

Simple string error:

```json
{
  "error": "Recipe not found"
}
```

The `@require_auth` decorator uses `jsonify` for missing/invalid tokens with the same `{"error": "..."}` shape and HTTP `401`.

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
- `GET /api/cookbooks/<id>/` returns the cookbook if it exists (ownership is enforced on update/delete/add/remove recipe, not on this single GET in the current code).
- Success responses are JSON bodies produced by `json.dumps`; set `Content-Type: application/json` on the client when sending JSON bodies.
