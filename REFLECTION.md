# Reflection — The Good Corner (technical test)

## Time budget

- Estimated effort communicated for this exercise: **4–6 hours** of focused work, ideally completed **within about one week** (no hard day-by-day deadline).

## API assumptions & ambiguity

- **Detail screen:** `server/swagger.yaml` exposes only `GET /listings` and `GET /categories` (no `GET /listings/{id}`). The listing payload already includes fields needed for a rich detail view (`description`, `creation_date`, images, etc.). **Assumption:** push the selected `Listing` into the detail screen via navigation (no second network call for the core scope).
- **`price`:** OpenAPI types it as a number; sample JSON uses integers. **Decision:** decode as `Double` in Swift for compatibility with possible decimal values.
- **`creation_date`:** **Decision:** kept as `String` in the model for simplicity and deterministic decoding in tests without configuring `JSONDecoder` date strategies everywhere. UI can parse to `Date` when formatting for display.
- **`images_url`:** Schema marks the object as nullable; inner `small` / `thumb` may be null. **Decision:** `ImagesURL?` with optional `small` and `thumb`.

## Naming

- **`ListingCategory`:** The JSON field names remain `id` / `name`; the Swift type is not named `Category` to avoid compiler ambiguity with other frameworks when running unit tests.

## Encoding style

- **Explicit `CodingKeys`** for snake_case JSON keys instead of `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase`, so field mappings stay visible in one place and tests stay explicit.

## Automated tests

- Unit tests decode bundled JSON fixtures so tests **do not require** the local server (per brief). See `TheGoodCornerTests` and `Resources/listing_feed_fixture.json`.

## AI usage

*(Update as you work: tools used, one AI suggestion you rejected or corrected, and architecture choices you owned.)*

- **Tools:** …
- **Rejected / corrected suggestion:** …
- **Owned decisions:** …
