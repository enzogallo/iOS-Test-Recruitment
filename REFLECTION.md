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

## UI & visual direction

- **Inspiration:** Marketplace-style hierarchy (search, category shortcuts, 2-column grid, detail hero + card) inspired by common patterns in production classified apps, without copying proprietary assets.
- **Typography:** Plus Jakarta Sans bundled as static `.ttf` files (SIL Open Font License — same family as “Jakarta” you had in mind). No Swift package dependency; fonts are registered via `UIAppFonts` in `Info.plist`. **`navigationTitle` does not inherit SwiftUI `.font`** — large and inline bar titles use Plus Jakarta via `NavigationBarAppearanceConfigurator.applyJakartaNavigationFonts()` at launch (`NavigationBarAppearance+AppFonts.swift`).
- **Palette:** Custom color assets (`BrandOrange`, `NavyPrimary`, `PriceGreen`, surfaces, chips) for a cleaner, slightly more “premium” look than default system gray alone.
- **Search (bonus):** `searchable` + debounce (~350ms) in `ListingListViewModel` so `GET /listings?query=` is not fired on every keystroke.
- **Category filter:** Client-side filter on the current result set using `category_id` plus names from `GET /categories`.

## Localization

- **`fr.lproj` / `en.lproj`** hold UI strings; **`CFBundleDevelopmentRegion` = `fr`** so French is the default where the system has no preference.
- **Language selection** follows **iOS Settings** (per-app language for The Good Corner when available); there is no in-app language menu—`Locale` and `String(localized:)` pick up the system choice automatically.
- **Listing titles, descriptions, and category names from the API** are shown as returned by the server (often French); labels, errors, accessibility, and formatted numbers/dates follow the **system UI language**.

## iOS 26 Liquid Glass vs iOS 16 floor

- **`LiquidGlassCompat`:** On **iOS 26+**, **empty search** and **load error** message panels use **`.glassEffect`** in a rounded rectangle; on **iOS 16–25** the same areas use **`.ultraThinMaterial`**. Category filter chips stay **solid fills** (glass would be barely visible under opaque pills; not used there on purpose).
- Deployment remains **`IPHONEOS_DEPLOYMENT_TARGET = 16.0`**; newer APIs sit behind `#available(iOS 26.0, *)`.

## Automated tests

- Unit tests decode bundled JSON fixtures so tests **do not require** the local server (per brief). See `TheGoodCornerTests` and `Resources/listing_feed_fixture.json`.

## AI usage

- **How I used it:** I used **Cursor** (and its agent) as a **productivity assist**—to draft boilerplate faster, explore API edge cases, and run builds/tests in the environment—**not** to outsource the exercise. The goal was to **save time on execution** so I could focus on **structure, quality, and alignment with the brief**.

- **What I owned end to end:** I **piloted the whole project**: product and screen flow, **networking and models** (decoding strategy, error mapping), **SwiftUI architecture** (view model responsibilities, navigation), **UI/UX decisions** (typography, colors, search debounce, accessibility, localization), and **what ships in the repo** (naming, file layout, tests, `REFLECTION.md`). Every line was **reviewed, adjusted, and validated** by me; I accepted, rejected, or rewrote assistant suggestions whenever they did not match my intent or the constraints (no third-party deps, iOS 16 floor, etc.).

- **Honest boundary:** The assistant **accelerated typing and iteration**; **judgment, trade-offs, and ownership** stay mine—exactly how I would use AI **on the job**: as a lever under **clear direction**, not as a substitute for understanding or accountability.

- **Also used:** Xcode **`xcodebuild`** locally for builds and unit tests on the Simulator.
