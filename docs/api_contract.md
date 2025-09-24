# SwapWing API Contract v1

This contract defines the REST API surface that the Flutter client and Django backend will share for the Accounts, Listings, Journeys, and Challenges domains. It assumes a versioned base path of `/api/v1` and JSON request/response bodies encoded in UTF-8.

## Conventions
- **Authentication:** Unless noted, endpoints require a `Bearer <access_token>` header issued via the login endpoint. Tokens represent DRF auth tokens persisted server-side.
- **Idempotency:** `POST` endpoints that mutate state return the created resource and are safe to retry when the client includes an `Idempotency-Key` header.
- **Timestamps:** All timestamps use ISO-8601 strings with timezone offsets (`2024-05-01T12:00:00Z`).
- **Pagination:** List endpoints accept `page` (1-based) and `page_size` (default 20, max 100). Responses include `count`, `next`, `previous`, and `results` fields.
- **Errors:** Errors return standard HTTP status codes plus a JSON body: `{ "detail": "human readable message", "code": "MACHINE_CODE" }`.

## Shared Data Shapes
```jsonc
// Listing summary used in feeds and search
{
  "id": "listing_001",
  "owner": {
    "id": "user_002",
    "username": "alex_trader",
    "profile_image_url": "https://cdn.swapwing.com/u2.jpg",
    "trust_score": 4.2,
    "is_verified": true
  },
  "title": "Vintage Polaroid Camera",
  "description": "Classic instant camera...",
  "category": "electronics",
  "tags": ["vintage", "camera", "photography"],
  "estimated_value": 180.0,
  "is_trade_up_eligible": true,
  "location": {
    "label": "San Francisco, CA",
    "lat": 37.7749,
    "lng": -122.4194
  },
  "media": [
    {
      "id": "media_001",
      "url": "https://cdn.swapwing.com/listings/1.jpg",
      "type": "image",
      "thumbnail_url": "https://cdn.swapwing.com/listings/1_thumb.jpg"
    }
  ],
  "created_at": "2024-05-06T10:25:00Z",
  "updated_at": "2024-05-06T10:25:00Z",
  "status": "active"
}
```

```jsonc
// Trade journey detail with embedded steps
{
  "id": "journey_001",
  "owner": {
    "id": "user_001",
    "username": "alex_trader",
    "profile_image_url": "https://cdn.swapwing.com/users/1.jpg"
  },
  "title": "Paperclip to iPhone",
  "description": "Starting with a simple paperclip...",
  "starting_listing_id": "listing_start_001",
  "starting_value": 0.1,
  "target_value": 800.0,
  "status": "active",
  "tags": ["paperclip", "challenge", "trading"],
  "metrics": {
    "likes": 24,
    "comments": 8,
    "shares": 5,
    "followers": 210
  },
  "steps": [
    {
      "id": "step_001",
      "sequence": 1,
      "from_listing_id": "listing_start_001",
      "to_listing_id": "listing_step_001",
      "from_value": 0.1,
      "to_value": 5.0,
      "notes": "Traded paperclip for pen",
      "media": [
        { "id": "media_step_001", "type": "image", "url": "https://cdn.swapwing.com/journeys/1.jpg" }
      ],
      "completed_at": "2024-04-06T09:00:00Z"
    }
  ],
  "created_at": "2024-03-15T08:00:00Z",
  "updated_at": "2024-04-06T09:00:00Z"
}
```

```jsonc
// Challenge detail with leaderboard entry
{
  "id": "challenge_001",
  "title": "Spring Trade-Up Sprint",
  "description": "Complete the biggest value increase in 30 days",
  "cover_image_url": "https://cdn.swapwing.com/challenges/spring.jpg",
  "category": "trade_up",
  "start_at": "2024-05-01T00:00:00Z",
  "end_at": "2024-05-30T23:59:59Z",
  "status": "active",
  "rules": ["Must document each step", "Minimum three trades"],
  "rewards": {
    "grand_prize": "VIP feature on SwapWing TV",
    "runner_up": "SwapWing merch pack"
  },
  "participant_count": 142,
  "leaderboard": [
    {
      "rank": 1,
      "user": {
        "id": "user_010",
        "username": "flipmaster",
        "profile_image_url": "https://cdn.swapwing.com/users/10.jpg"
      },
      "journey_id": "journey_500",
      "trade_delta_value": 1250.0,
      "steps_completed": 8,
      "last_updated": "2024-05-10T21:15:00Z"
    }
  ]
}
```

## 1. Accounts & Identity
### 1.1 Register
- **Endpoint:** `POST /api/v1/accounts/register`
- **Body:**
  ```json
  {
    "email": "alex@example.com",
    "password": "SwapWing!234",
    "password2": "SwapWing!234",
    "first_name": "Alex",
    "last_name": "Trader",
    "username": "alex-trader"
  }
  ```
- **Responses:**
  - `201 Created`
    ```json
    {
      "message": "Successful",
      "data": {
        "email": "alex@example.com",
        "expires_in_minutes": 60
      }
    }
    ```
  - `400 Bad Request` when validation fails (duplicate email, weak password, password mismatch).

### 1.2 Verify Email
- **Endpoint:** `POST /api/v1/accounts/email/verify`
- **Body:** `{ "email": "alex@example.com", "code": "123456" }` (alternatively pass `token` for deep-link verification).
- **Responses:**
  - `200 OK`
    ```json
    {
      "message": "Successful",
      "data": {
        "user_id": "user_001",
        "email": "alex@example.com",
        "first_name": "Alex",
        "last_name": "Trader",
        "token": "abcdef123456"
      }
    }
    ```
  - `400 Bad Request` for invalid or expired codes with error slug `token`.
  - `404 Not Found` if the email does not match any account.

### 1.3 Resend Verification
- **Endpoint:** `POST /api/v1/accounts/email/resend`
- **Body:** `{ "email": "alex@example.com" }`
- **Responses:**
  - `202 Accepted`
    ```json
    {
      "message": "Successful",
      "data": {
        "email": "alex@example.com",
        "expires_in_minutes": 60
      }
    }
    ```
  - `200 OK` when the user is already verified (payload includes `"status": "already_verified"`).

### 1.4 Login
- **Endpoint:** `POST /api/v1/accounts/login`
- **Body:** `{ "email": "alex@example.com", "password": "SwapWing!234" }`
- **Responses:**
  - `200 OK`
    ```json
    {
      "access_token": "abcdef123456",
      "token_type": "Bearer",
      "user": {
        "id": "user_001",
        "email": "alex@example.com",
        "first_name": "Alex",
        "last_name": "Trader",
        "email_verified": true,
        "profile_complete": false
      }
    }
    ```
  - `403 Forbidden` when email is not verified (`code: "EMAIL_UNVERIFIED"`).

### 1.5 Logout
- **Endpoint:** `POST /api/v1/accounts/logout`
- **Auth:** Required.
- **Behavior:** Revokes the active token. Returns `204 No Content`.

### 1.6 Get Current User
- **Endpoint:** `GET /api/v1/accounts/me`
- **Auth:** Required.
- **Response:**
  ```json
  {
    "id": "user_001",
    "email": "alex@example.com",
    "first_name": "Alex",
    "last_name": "Trader",
    "email_verified": true,
    "joined_at": "2024-03-01T08:00:00Z"
  }
  ```

### 1.7 Profile & identity documents
- **Endpoints:**
  - `GET /api/user-profile/me/` returns the authenticated trader’s profile.
  - `PATCH /api/user-profile/me/` accepts multipart or JSON payloads to update identity data, avatar, ID document, and social links.
  - `GET /api/user-profile/{user_id}/` exposes read-only public profile details for another trader.
- **Response (`200 OK`):**
  ```json
  {
    "user_id": "user_001",
    "email": "alex@example.com",
    "first_name": "Alex",
    "last_name": "Trader",
    "gender": "Male",
    "phone": "+1-415-555-0199",
    "about_me": "Passionate trader...",
    "country": "USA",
    "id_type": "Passport",
    "id_number": "A1234567",
    "profile_complete": true,
    "verified": false,
    "photo_url": "https://cdn.swapwing.com/users/user_001/avatar.jpg",
    "id_card_document_url": "https://cdn.swapwing.com/users/user_001/id.pdf",
    "social_links": [
      {"id": 1, "name": "Instagram", "link": "https://instagram.com/alex", "active": true}
    ]
  }
  ```
- **Update example (`multipart/form-data`):**
  ```
  PATCH /api/user-profile/me/
  Content-Type: multipart/form-data

  photo: <avatar.jpg>
  id_card_image: <passport.pdf>
  id_type: Passport
  id_number: A1234567
  phone: +1-415-555-0199
  about_me: Passionate trader...
  social_links: [
    {"name": "Instagram", "link": "https://instagram.com/alex", "active": true},
    {"name": "Twitter", "link": "https://twitter.com/alex", "active": false}
  ]
  ```
- **Validation rules:**
  - Avatars must be JPG/PNG/WEBP images within 5 MB (configurable via `PROFILE_AVATAR_MAX_SIZE_MB`).
  - Identification documents accept JPG/PNG/WEBP/PDF within 10 MB and require `id_type` + `id_number` to be present.
  - `social_links` replaces the trader’s active links; each entry enforces the predefined platform enum and a valid URL.
  - Profile completion toggles to `true` once avatar, ID document, `id_type`, and `id_number` are stored.

## 2. Listings
The marketplace API now backs the Flutter Home and Search tabs with real listings. All endpoints live under `/api/listings/` and require a valid token.

### 2.1 Browse Listings
- **Endpoint:** `GET /api/listings/`
- **Query Params:**
  - `search` – keyword search across `title`, `description`, `tags`, and `location`.
  - `category` – repeatable enum (`goods`, `services`, `digital`, `automotive`, `electronics`, `fashion`, `home`, `sports`).
  - `status` – repeatable enum (`active`, `traded`, `expired`). Deleted listings are omitted automatically.
  - `trade_up_eligible` – `true`/`false` toggle.
  - `min_value` / `max_value` – decimal value filters on the `estimated_value` field.
  - `owner` – filter by trader (`me` for the authenticated user or a `user_id`).
  - `ordering` – comma separated ordering fields (e.g. `-created_at,estimated_value`).
- **Response:** Array of listing resources sorted newest-first.

### 2.2 Listing Detail
- **Endpoint:** `GET /api/listings/{listing_id}/`
- **Response:** Listing resource including owner metadata and resolved media URLs.

### 2.3 Create Listing
- **Endpoint:** `POST /api/listings/`
- **Body:** `multipart/form-data`
  - Scalar fields: `title`, `description`, `category`, `estimated_value`, `is_trade_up_eligible`, `location`, `status`.
  - `tags` – JSON array of strings (`["vintage", "camera"]`).
  - `media_files` – repeated file uploads (max 10 per request).
  - `media_urls` – JSON array of already-hosted assets that should be referenced.
- **Response:** `201 Created` with the full listing payload (including uploaded media URLs). The authenticated user automatically becomes the owner.

### 2.4 Update Listing
- **Endpoint:** `PATCH /api/listings/{listing_id}/`
- **Behavior:** Partial updates on any scalar field, plus media management:
  - `media_files` / `media_urls` append additional assets.
  - `remove_media_ids` removes previously attached media records.
- **Response:** `200 OK` with the updated listing.

### 2.5 Delete Listing
- **Endpoint:** `DELETE /api/listings/{listing_id}/`
- **Behavior:** Permanently removes the listing record and its media. Returns `204 No Content`.

## 3. Trade Journeys
### 3.1 List Journeys
- **Endpoint:** `GET /api/v1/journeys`
- **Query Params:** `owner_id`, `status` (`draft`, `active`, `completed`), `following=true` (feed of followed traders), `challenge_id`.
- **Response:** Paginated journey summaries.

### 3.2 Journey Detail
- **Endpoint:** `GET /api/v1/journeys/{journey_id}`
- **Response:** Journey detail shape shown above plus `followers` array (limited to first 10) and `next_steps_hint` copy for UI coaching.

### 3.3 Create Journey
- **Endpoint:** `POST /api/v1/journeys`
- **Body:**
  ```json
  {
    "title": "Paperclip to iPhone",
    "description": "Starting with a simple paperclip...",
    "starting_listing_id": "listing_start_001",
    "starting_value": 0.1,
    "target_value": 800.0,
    "tags": ["paperclip", "challenge"],
    "visibility": "public"
  }
  ```
- **Response:** `201 Created` with journey detail (no steps yet). Journeys start as `draft` until first step is published.

### 3.4 Update Journey Metadata
- **Endpoint:** `PATCH /api/v1/journeys/{journey_id}`
- **Allows:** `title`, `description`, `target_value`, `visibility`, `status` transitions (`draft -> active -> completed`).

### 3.5 Manage Steps
- **Add Step:** `POST /api/v1/journeys/{journey_id}/steps`
  ```json
  {
    "from_listing_id": "listing_step_001",
    "to_listing_id": "listing_step_002",
    "from_value": 5.0,
    "to_value": 25.0,
    "notes": "Traded pen for notebook set",
    "completed_at": "2024-04-01T12:00:00Z",
    "media_ids": ["media_step_100"]
  }
  ```
  - Response: `201 Created` with step detail, server assigns sequential `sequence`.
- **Edit Step:** `PATCH /api/v1/journeys/{journey_id}/steps/{step_id}` for corrections.
- **Delete Step:** `DELETE /api/v1/journeys/{journey_id}/steps/{step_id}` (only when journey not completed).

### 3.6 Publish Journey Updates
- **Endpoint:** `POST /api/v1/journeys/{journey_id}/publish`
- **Behavior:** Transitions draft steps to published state, triggers notifications to followers and challenge leaderboards.

### 3.7 Follow Journey
- **Endpoint:** `POST /api/v1/journeys/{journey_id}/follow`
- **Response:** `{ "following": true }`. Delete to unfollow.

### 3.8 Journey Notifications Stream
- **Endpoint:** `GET /api/v1/journeys/{journey_id}/events`
- **Protocol:** Server-Sent Events (SSE) streaming JSON payloads for new steps, likes, comments. Flutter falls back to polling if SSE unavailable.

## 4. Challenges
### 4.1 List Challenges
- **Endpoint:** `GET /api/v1/challenges`
- **Query Params:** `status` (`upcoming`, `active`, `completed`), `enrolled=true` (current user), `category`.
- **Response:** Paginated summaries containing `id`, `title`, `cover_image_url`, `status`, `start_at`, `end_at`, `participant_count`, `is_enrolled`.

### 4.2 Challenge Detail
- **Endpoint:** `GET /api/v1/challenges/{challenge_id}`
- **Response:** Detail shape above plus `cta_copy`, `milestones` (array of value thresholds), `prizes` (tiered rewards), and `leaderboard` (top 20 plus current user rank if outside top 20).

### 4.3 Enroll in Challenge
- **Endpoint:** `POST /api/v1/challenges/{challenge_id}/enroll`
- **Body:** optional `{ "journey_id": "journey_123" }` to link an existing journey.
- **Responses:**
  - `201 Created` when enrollment is new.
  - `200 OK` when already enrolled (`code: "ALREADY_ENROLLED"`).
  - `409 Conflict` if journey already linked elsewhere.

### 4.4 Submit Progress
- **Endpoint:** `POST /api/v1/challenges/{challenge_id}/progress`
- **Body:**
  ```json
  {
    "journey_id": "journey_123",
    "step_id": "step_456",
    "trade_delta_value": 75.0,
    "notes": "Unlocked major upgrade!"
  }
  ```
- **Response:** `202 Accepted` and pushes update to leaderboard feed.

### 4.5 Leaderboard Stream
- **Endpoint:** `GET /api/v1/challenges/{challenge_id}/leaderboard/stream`
- **Protocol:** WebSocket (Channels) sending JSON payloads `{ "rank": 3, "journey_id": "journey_123", "trade_delta_value": 860.0, "updated_at": "..." }` whenever standings change.

### 4.6 Leave Challenge
- **Endpoint:** `DELETE /api/v1/challenges/{challenge_id}/enroll`
- **Response:** `204 No Content` if removed, `404` if not enrolled.

## 5. Analytics & Telemetry Hooks
For analytics parity, clients emit the following events to `/api/v1/analytics/events` (fire-and-forget, `202 Accepted`):
- `listing_search_performed` with `query`, `filters`, `result_count`.
- `journey_step_published` with `journey_id`, `step_id`, `trade_delta_value`.
- `challenge_rank_changed` with `challenge_id`, `from_rank`, `to_rank`.

## 6. Security Considerations
- Rate limit sensitive endpoints (auth, media upload) via Django Rest Framework throttling.
- Validate all geo inputs (lat/lng) before storing.
- Media uploads return pre-signed URLs where possible to offload uploads directly to S3/GCS.
- All endpoints require HTTPS; reject plain HTTP.

## 7. Contract Change Management
- Breaking changes require bumping the version prefix to `/api/v2` and documenting migration steps.
- Additive fields must be optional and documented in this contract before deployment.
- Backend publishes an OpenAPI 3.1 spec generated from DRF schema at `/api/schema/` and the Flutter team consumes it to update API clients.
