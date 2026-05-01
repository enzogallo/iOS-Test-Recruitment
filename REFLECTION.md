# Reflection — The Good Corner (technical test)

## Time breakdown

This split reflects how work was **actually** distributed on the deliverable; it situates product thinking vs execution vs review.

| Phase | Duration | What it covered |
|--------|----------|-----------------|
| **Brief + architecture** | ~**1 h** | Re-read `README.md` / API contract, scope decisions (no detail endpoint, server feed order, no external libs), sketch navigation + ViewModel vs views. |
| **Development** | ~**3 h** | SwiftUI + networking + UI states, with **Cursor / agent** to speed up boilerplate and iterations (I stay the decision-maker on what gets merged). |
| **Review, tests, clean-up** | ~**2 h** | Code review, alignment with automated-test expectations from the brief, accessibility, FR/EN copy, small refactors (DRY, in-flight fetch cancellation), updates to this file. |

The total still fits the **4–6 h** order of magnitude stated in the brief, with a little implicit slack (builds, Simulator).

## API assumptions & ambiguity

- **Detail screen:** `server/swagger.yaml` exposes only `GET /listings` and `GET /categories` (no `GET /listings/{id}`). The listing payload already includes fields needed for a rich detail view (`description`, `creation_date`, images, etc.). **Assumption:** push the selected `Listing` into the detail screen via navigation (no second network call for the core scope).
- **`price`:** OpenAPI types it as a number; sample JSON uses integers. **Decision:** decode as `Double` in Swift for compatibility with possible decimal values.
- **`creation_date`:** **Decision:** kept as `String` in the model for simplicity and deterministic decoding in tests without configuring `JSONDecoder` date strategies everywhere. UI can parse to `Date` when formatting for display.
- **`images_url`:** Schema marks the object as nullable; inner `small` / `thumb` may be null. **Decision:** `ImagesURL?` with optional `small` and `thumb`.

## Naming

- **`ListingCategory`:** The JSON field names remain `id` / `name`; the Swift type is not named `Category` to avoid compiler ambiguity with other frameworks exporting `Category` (e.g. in test bundles).

## Encoding style

- **Explicit `CodingKeys`** for snake_case JSON keys instead of `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase`, so field mappings stay visible in one place and tests stay explicit.

## UI & visual direction

- **List screen:** The brief asks for a **list of listings** with **category filter** and **API order preserved**. The implementation uses **horizontal “rails” per category** (plus an **“Other”** rail when `category_id` is absent from `GET /categories`), with a **3-card preview** and a discreet **“See more”** row action (localized in the app) that expands to a **2-column grid** for that category. **Order within each rail** follows the feed order from `GET /listings`; **rail order** follows sorted category names, with **Other** last. This is a deliberate UX choice (marketplace-style discovery) while still honoring server ordering inside each bucket.
- **Multi-select filters** narrow which rails are shown (empty selection = all). **Single active filter** auto-expands that rail when it has more than **3** listings; adding a second filter collapses previews again (documented product rule).
- **Typography:** Plus Jakarta Sans bundled as static `.ttf` files (SIL Open Font License). No Swift package dependency; fonts are registered via `UIAppFonts` in `Info.plist`. **`navigationTitle` does not inherit SwiftUI `.font`** — large and inline bar titles use Plus Jakarta via `NavigationBarAppearanceConfigurator.applyJakartaNavigationFonts()` at launch (`NavigationBarAppearance+AppFonts.swift`).
- **Palette:** Custom color assets (`BrandOrange`, `NavyPrimary`, `PriceGreen`, surfaces, chips) for a cleaner, slightly more “premium” look than default system gray alone.
- **Search (bonus):** In-content field + **~350 ms debounce** in `ListingListViewModel` so `GET /listings?query=` is not fired on every keystroke. **In-flight fetches are superseded:** each new load or debounced refresh **cancels** the previous `Task` driving `async let` network work, so stale responses do not overwrite the UI when the query changes quickly (`runFetchReplacingInFlight` + `fetchSerial` guard on `isLoading` / published fields).

## Localization

- **`fr.lproj` / `en.lproj`** hold UI strings; **`CFBundleDevelopmentRegion` = `fr`** so French is the default where the system has no preference.
- **Language selection** follows **iOS Settings** (per-app language for The Good Corner when available); there is no in-app language menu—`Locale` and `String(localized:)` pick up the system choice automatically.
- **Listing titles, descriptions, and category names from the API** are shown as returned by the server (often French); labels, errors, accessibility, and formatted numbers/dates follow the **system UI language**.

## iOS 26 Liquid Glass vs iOS 16 floor

- **`LiquidGlassCompat`:** On **iOS 26+**, **empty search** and **load error** message panels use **`.glassEffect`** in a rounded rectangle; on **iOS 16–25** the same areas use **`.ultraThinMaterial`**. Category filter chips stay **solid fills** (glass would be barely visible under opaque pills; not used there on purpose).
- Deployment remains **`IPHONEOS_DEPLOYMENT_TARGET = 16.0`**; newer APIs sit behind `#available(iOS 26.0, *)`.

## Automated tests

- Tests are **deterministic** and **do not require** the local server (per brief).
- **`ListingFeedDecodingTests`:** JSON fixture + inline category array decoding.
- **`ListingEndpointTests`:** URL construction for listings (with/without `query`) and categories, plus absolute URL resolution from `APIConfiguration`.
- **`ListingListViewModelTests`:** stub `ListingAPIClient` — **rail bucketing** (sort + “Other”), **visible rails vs multi-select** (including **`trimmedSearchQuery`** derived from `searchText`), and **superseded fetch** (a slow first request is replaced by a second `load()` so only the latest response is published).

## AI usage

- **How I used it:** I used **Cursor** (and its agent) as a **productivity assist**—to draft boilerplate faster, explore API edge cases, and run builds/tests in the environment—**not** to outsource the exercise. The goal was to **save time on execution** so I could focus on **structure, quality, and alignment with the brief**.

- **What I owned end to end:** I **piloted the whole project**: product and screen flow, **networking and models** (decoding strategy, error mapping), **SwiftUI architecture** (view model responsibilities, navigation), **UI/UX decisions** (typography, colors, search debounce, cancellation, accessibility, localization), and **what ships in the repo** (naming, file layout, tests, `REFLECTION.md`). Every line was **reviewed, adjusted, and validated** by me; I accepted, rejected, or rewrote assistant suggestions whenever they did not match my intent or the constraints (no third-party deps, iOS 16 floor, etc.).

- **Honest boundary:** The assistant **accelerated typing and iteration**; **judgment, trade-offs, and ownership** stay mine—exactly how I would use AI **on the job**: as a lever under **clear direction**, not as a substitute for understanding or accountability.

- **Also used:** Xcode **`xcodebuild`** locally for builds and unit tests on the Simulator.

### One concrete AI suggestion I rejected, corrected, or rewrote

- **Rejected / reframed:** a **single flat list** + category filter (e.g. one 2-column grid over the whole feed) would have been the fastest path against the README wording, but it **did not match** the product intent of “browsing the feed like a marketplace” (several categories visible at once, server order readable in blocks). **What shipped instead:** **horizontal rails per category** + multi-select filters that **hide non-selected rails**, an **“Other”** rail for `category_id` values missing from `GET /categories`, a **3-card preview** + **See more** (and a product rule: **exactly one** category selected → auto-expand beyond three listings). The assistant helped iterate on implementing that direction, not to force the most minimal interpretation of the brief.

- **Rewrote in review:** for ViewModel **tests**, an isolated test case for `trimmedSearchQuery` hit **XCTest / `@MainActor`** friction (instant failure depending on the test worker). I **folded** those assertions into an existing test (`visible rails` + search) instead of stacking brittle workarounds—same coverage intent, more reliable execution.
