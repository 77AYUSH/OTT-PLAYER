# OTT Player — iOS Technical Assignment

A small OTT-style iOS app in UIKit: **Home → Content Detail → Video Player**.

- Home shows a full-bleed hero banner (**Play** and **Details**) and four horizontally scrolling rails that page one card at a time.
- The *Trailers* rail is an auto-advancing carousel: it moves on every 5 seconds, and the focused card is raised above its scaled-down neighbours.
- Every card and the hero CTA open the matching detail screen. Its artwork also runs to the top edge, under a transparent nav bar.
- **Play** opens an AVKit player that reports typed playback events to an analytics repository.

All content comes from a bundled JSON mock API through the data layer. View controllers and view models hold no content records.

---

## Requirements

| | |
|---|---|
| Minimum iOS (app) | **iOS 15.0** |
| Minimum iOS (unit tests) | iOS 17.0 (current XCTest is built for 17+) |
| Xcode | **Xcode 16 or later**. The project uses folder-synchronised groups (`objectVersion 77`). Built and tested with **Xcode 27.1** (Swift 6.4 toolchain). |
| Swift language mode | Swift 5, same as the reference project |
| Devices | iPhone, portrait and landscape |
| Third-party dependencies | **None.** Only UIKit, AVFoundation, AVKit, Combine and `os`. |

## Build and run

1. Open `OTTPlayer.xcodeproj`.
2. Select the **OTTPlayer** scheme and any iPhone simulator.
3. Press **Run** (⌘R).

No signing team is needed for the simulator. To run on a device, set your team under *Signing & Capabilities*.

From the command line:

```bash
xcodebuild -project OTTPlayer.xcodeproj -scheme OTTPlayer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**To see the error state:** in the scheme, enable the launch argument `-homeFeedFile missing_feed`. It is already present but switched off. The static data source then can't find its file, and Home shows the error view with **Try Again**.

**To watch analytics events:** check the Xcode console, or stream them from a booted simulator:

```bash
xcrun simctl spawn booted log stream --level info --predicate 'subsystem == "com.ayushgandhi.OTTPlayer" AND category == "analytics"'
```

## Tests

Run them with ⌘U, or:

```bash
xcodebuild -project OTTPlayer.xcodeproj -scheme OTTPlayer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

There are 27 unit tests in `OTTPlayerTests/`:

| File | What it covers |
|---|---|
| `HomeFeedMapperTests` | DTO → domain mapping: field and URL mapping, trimmed titles, banner fallback, rail order, rail style (`carousel` vs. standard, unknown → standard), unknown/duplicate IDs, empty and duplicate rails, invalid video URLs, hero fallback, malformed JSON, duration badge formatting |
| `ContentDataLayerTests` | The shipped `home_feed.json` decodes into a usable feed (hero plus ≥ 2 non-empty rails); a missing file maps to `fileNotFound`; the repository's detail lookup reuses the cached feed and returns `notFound` for unknown IDs |
| `HomeViewModelTests` | idle → loading → loaded; empty; error → retry → loaded; **stale results are dropped** when a slower earlier request finishes last |
| `PlayerEventHandlerTests` | Event rules with plain values (no AVPlayer): ready/start reported once; pause vs resume; one buffering pair per stall; transient waits ignored; end-of-item pause reported as completion only; error reported once and silences later signals; scrub bursts coalesced into one seek; correct seek origin; tiny jumps ignored |
| `PlayerViewModelTests` | Propagation **handler → view model → use case → repository** with content ID and position; events drive screen state; `stop()` records `PLAYER_CLOSED`, invalidates observers and ignores late events; the view model is released after `stop()` |

---

## Architecture

```
UI (VC + XIB) ──▶ ViewModel ──▶ UseCase ──▶ Repository ──▶ DataSource
   ▲                │  (@Published state, Combine)          │
   └── sink(on main)┘                                  JSON → DTO → Mapper → Domain
```

Player events take their own path:

```
AVPlayer / AVPlayerItem ──▶ PlayerEventHandler ──▶ PlayerViewModel ──▶ TrackPlayerEventUseCase ──▶ PlayerEventRepository
 (KVO, notifications,        (de-duplicates,         (adds content ID,      (domain)                   (LoggingPlayerEventRepository:
  periodic time observer)     typed PlayerEvent.Kind)  updates UI state)                                PLAYER_STARTED …)
```

- **Presentation:** `Screens/*/View` (UIViewController + XIB) and `Screens/*/ViewModel`. View models are `@MainActor`, expose `@Published private(set) var state`, and talk only to use-case protocols.
- **Domain:** `Domain/Models` (`ContentItem`, `HomeFeed`, `ContentRail`, `HomeHero`, `PlayerEvent`, `ContentError`), `Domain/Repositories` (protocols), and `Domain/UseCases` (protocol plus default implementation). No UIKit or data-layer imports.
- **Data:** `Data/DTO` (Decodable wire models), `Data/Mapper` (`HomeFeedMapper`), `Data/DataSources` (`HomeFeedDataSource` protocol and `StaticHomeFeedDataSource`), and `Data/Repositories` (`DefaultContentRepository` actor, `LoggingPlayerEventRepository`).
- **Composition root:** `DI/AppDependencyContainer` builds the whole graph and every screen. View controllers navigate through the `ScreenFactory` protocol, so they never construct each other's dependencies.

### Project structure

```
OTTPlayer/
├── Appdelegates/            AppDelegate (audio session), SceneDelegate (window + container)
├── DI/                      AppDependencyContainer, ScreenFactory
├── Constants/               Constants (colors, player tuning, feed file name)
├── Network/                 NetworkError, NetworkManager (URLSession wrapper)
├── Helper/                  JsonHelper, ImageLoader, NavHelper, PlayerEventHandler, AppLogger
│   └── Extensions/          UICollectionView, UIImageView, UIView, UIViewController, Error, TimeInterval, ContentItem+Formatting
├── CustomReusableFiles/     StateMessageView (empty/error + retry), GradientView (top/bottom scrim), AppLogoView
├── CollectionCellsAndHeaders/
│   ├── HeroBannerCell/      .swift + .xib
│   ├── ContentCardCell/     .swift + .xib
│   ├── FeaturedCarouselCell/ FeaturedCarouselCell + CarouselCardCell (.swift + .xib), CarouselFlowLayout
│   └── RailHeaderView/      .swift + .xib
├── Domain/                  Models, Repositories (protocols), UseCases
├── Data/                    DTO, Mapper, DataSources, Repositories
├── Screens/
│   ├── Splash/              View/SplashView (animated launch overlay)
│   ├── Home/                View/HomeVC(.xib), ViewModel/HomeViewModel
│   ├── ContentDetail/       View/ContentDetailVC(.xib), ViewModel/ContentDetailViewModel
│   └── Player/              View/PlayerVC(.xib), ViewModel/PlayerViewModel
├── Resources/               home_feed.json, Assets.xcassets (AppIcon, colours)
└── Info.plist
OTTPlayerTests/              unit tests + TestDoubles
```

### How it follows the reference architecture

The reference project (Sortd, `SortdApps/SortdApps`) was used for structure and conventions only. No code, models, endpoints, assets or content were copied. Every type here was written fresh for this app.

| Reference convention | Reference example | Here |
|---|---|---|
| Top-level folders by role | `Appdelegates/`, `Constants/`, `Network/`, `Helper/`, `Helper/Extensions/`, `CustomReusableFiles/`, `CollectionCellsAndHeaders/<Cell>/`, `Screens/<Feature>/View` + `/ViewModel` | Same names and nesting |
| XIB-backed screens and cells created with `nibName:` | `AuthorDetailVC(.xib)`, `StoryPagerVC(nibName:bundle:)` | `HomeVC`, `ContentDetailVC`, `PlayerVC`, each cell with its own XIB |
| VM → VC binding through `@Published` state + Combine `sink` on main, `[weak self]` | `HomeVM.updates` / `HomeVC.setupBindings()` | `viewModel.$state.receive(on: .main).sink { [weak self] … }` in every VC |
| Nested `Event`/state enum in a VM extension | `AuthorDetailViewModel.Event` | `HomeViewModel.State`, `PlayerViewModel.State`, … |
| Async work in a stored `Task`, cancelled on restart, stale results guarded by a session ID | `HomeVM.fetchTask`, `loadSessionID`, `cancelLoading()` | `HomeViewModel.loadTask` + `activeRequestID`; `deinit` cancels |
| Typed `NetworkError` with readable messages; async `throws` API | `Network/NetworkManager.swift` | `Network/NetworkError.swift` + a much smaller `NetworkManager` |
| `JsonHelper` for bundled JSON | `Helper/JSonHelper.swift` | `Helper/JsonHelper.swift` (throws instead of returning nil) |
| `NavHelper` for nav-bar appearance | `Helper/NavHelper.swift` | Same role |
| Collection-view helpers: `reuseIdentifier`, `register(cell:)`, `registerHeader(header:)`, `dequeue(for:)` | `UICollectionView+Extensions.swift` | Same API shape; dequeue fails with a clear message instead of `as!` |
| `UIImageView.setImage(...)` extension for remote artwork | `UIImageView+Extensions.swift` (SDWebImage) | Same call site, backed by our own `ImageLoader` |
| `UIView` loader + VC-level error view with retry closure | `showLoaderr()`, `showErrorView(type:)` | `showLoader()/hideLoader()`, `showStateView(type:retryAction:)` |
| Player/analytics concerns kept in a helper rather than the VC | `Helper/VideoPlaybackHelper.swift` | `Helper/PlayerEventHandler.swift` |
| Diffable data source + compositional layout with horizontal sections | `HomeVC`, `AuthorDetailVC.configureDataSource()` | `HomeVC` |

**Deviations, and why:**

1. **Use cases, repositories, data sources, DTOs and a mapper were added.** The reference's view models call `NetworkManager.shared` directly. The assignment requires *UI → ViewModel → UseCase → Repository → DataSource*, so those layers were added under `Domain/` and `Data/`. The reference keeps its Codable models in `CommonModel/`; that role is now `Data/DTO`, so DTOs stay separate from domain models.
2. **Dependency injection instead of singletons and static factories.** The reference builds screens through static `VCHelper` methods and reaches for `.shared` singletons. Here `AppDependencyContainer` owns the graph and passes protocols in through initialisers, so tests can swap any layer. `NetworkManager.shared` and `ImageLoader.shared` stay as shared caches, which is the one place a singleton earns its keep.
3. **No Alamofire or SDWebImage.** The brief asks for Apple frameworks. `NetworkManager` wraps `URLSession`, and `ImageLoader` replaces SDWebImage with an `NSCache` + `URLCache` setup in about 60 lines.
4. **`@MainActor` view models.** The reference hops back with `MainActor.run` / `DispatchQueue.main.async` inside non-isolated VMs. Annotating the VMs gives the same guarantee and lets the compiler check it.
5. **`NetworkManager` is intentionally small.** It only has `data(from:)`, because that's all the app uses (artwork). There's no token refresh, reachability or upload code.

---

## Key decisions

- **Splash and app icon.** The static launch screen is the `LaunchBackground` colour, so it hands over seamlessly to `SplashView`. That view is laid over Home by `SceneDelegate`, so the feed loads while it animates: the ring draws, the play button springs in, the title rises, and then it zooms away (about 2 s). With Reduce Motion on it just shows briefly and fades out. The app icon uses the same ring and play mark (`Assets.xcassets/AppIcon`, single 1024 px image).
- **One collection view on Home**, using a compositional layout. Standard rails are orthogonal sections with `.groupPaging` and one card per group, so each swipe moves exactly one card. Item identity includes the rail ID, because the same title can appear in several rails and a diffable data source rejects duplicate identifiers.
- **The carousel is data-driven and self-contained.** A rail with `"style": "carousel"` in the JSON maps to `RailStyle.carousel`; nothing is hard-coded to the *Trailers* ID.
  - `FeaturedCarouselCell` hosts its own horizontal collection view rather than using an orthogonal section. That way it can observe dragging and drive programmatic scrolling reliably, which an orthogonal section doesn't expose.
  - `CarouselFlowLayout` shrinks, fades and lowers the z-order of cards as they move away from the centre, and the focused card carries a downward shadow, so it reads as raised.
  - Cards are separated by a positive 12pt gap and only ever scaled *down*. The distance between neighbouring centres therefore always exceeds their combined half widths, so cards never overlap, even mid-scroll. An earlier version tucked neighbours behind the focused card with negative spacing; that overlap looked distorted and was removed.
  - Paging is one card per swipe, measured from the card it last settled on, so a hard flick can't skip a card.
  - Auto-advance uses a one-shot 5 s timer, re-armed after every move. It pauses while you drag and only runs while the carousel is on screen and Home is in front (`willDisplay`/`didEndDisplaying`, `viewDidAppear`/`viewWillDisappear`). It is off when Reduce Motion is enabled.
- **Full-bleed artwork.** Home hides the navigation bar and ignores the top safe area, so the hero runs under the status bar. A top scrim keeps the clock legible, and a blurred strip fades in behind the status bar as the hero's text scrolls under it.
  - The detail screen uses a per-screen transparent nav bar over its header. It turns frosted (showing the title) once the artwork scrolls away.
  - Pulling down stretches the header from its top edge, and scrolling up gives it a light parallax.
  - Pull-to-refresh was removed: with full-bleed artwork the spinner would sit behind the status bar, and the bundled feed doesn't change. Retry remains on the error and empty states.
- **The detail screen loads by ID through its own use case**, not from the object Home passed along. The repository (an `actor`) caches the last feed, so this costs nothing, and the screen would work just as well from a deep link.
- **The mapper is defensive.** It drops items without a playable `http(s)` URL, rail entries with unknown IDs, empty rails, and duplicate rail or content IDs. It falls back to the thumbnail when a banner is missing, and to the description when the hero has no tagline.
- **Images:** a memory cache (`NSCache`, cost-limited) sits on top of a 150 MB disk `URLCache`. Concurrent requests for the same URL share one download, and decoding happens off the main thread (`preparingForDisplay`). Each image view cancels its previous load before starting a new one, and the cell also cancels in `prepareForReuse`, so a reused cell never shows another title's artwork. There's a placeholder while loading and a fallback icon on failure.
- **States:** Home and Detail have `loading`, `loaded`, `empty` (Home only) and `error` states, all with retry.
- **The static data source sleeps for 0.4 s** (`Constants.simulatedFeedLatency`) so the loading state and request cancellation behave like a real network call. Tests pass `0`.
- **Native AVKit controls** (`AVPlayerViewController` embedded as a child) give play/pause, ±10 s skip, scrubbing and progress for free. `PlayerVC` adds only a close/title bar, a loading indicator and an error view with retry.

---

## Player events

| Event name | Source | De-duplication / rule |
|---|---|---|
| `PLAYER_READY` | `AVPlayerItem.status == .readyToPlay` (KVO) | Once per item |
| `PLAYER_STARTED` | `timeControlStatus → .playing` (KVO) | The first time only |
| `PLAYER_PAUSED` | `timeControlStatus → .paused` | Only after playing. Suppressed at end-of-item (reported as completion) and after a failure. |
| `PLAYER_RESUMED` | `.playing` after a pause | Leaving buffering is **not** a resume |
| `PLAYER_SEEKED` (`from` → position) | `AVPlayerItem.timeJumpedNotification` + periodic time observer | Bursts within 0.4 s are coalesced; jumps under 1 s ignored |
| `PLAYER_BUFFERING_STARTED` / `_ENDED` | `.waitingToPlayAtSpecifiedRate` with reason `.toMinimizeStalls` | Only after playback has started; one pair per stall. The initial load and the brief "evaluating buffering rate" step after a seek don't count. |
| `PLAYER_COMPLETED` | `AVPlayerItemDidPlayToEndTime` | Once per playthrough; seeking back allows another |
| `PLAYER_ERROR` | `AVPlayerItem.status == .failed`, `AVPlayerItemFailedToPlayToEndTime` | Once per item, even when AVFoundation reports the failure on several channels |
| `PLAYER_CLOSED` | Player screen dismissed | Recorded before observers are removed |

Every event is a `PlayerEvent` (typed `Kind`, `contentId`, `position` in seconds, `timestamp`). The repository logs lines like these, which were captured from a simulator run:

```
PLAYER_READY content=studio-reel position=0.0s
PLAYER_STARTED content=studio-reel position=0.0s
PLAYER_SEEKED content=studio-reel position=19.4s from=9.4s
PLAYER_PAUSED content=studio-reel position=20.3s
PLAYER_RESUMED content=studio-reel position=174.9s
PLAYER_SEEKED content=studio-reel position=175.1s from=20.3s
PLAYER_PAUSED content=studio-reel position=180.4s      ← app sent to background
PLAYER_CLOSED content=studio-reel position=180.4s
```

### Observers and cleanup

- `PlayerEventHandler` uses Combine publishers for KVO and notifications, delivered on the main queue and stored in a `Set<AnyCancellable>`. It also holds a periodic time observer token.
- `invalidate()` cancels the publishers, cancels any pending seek work item, and removes the time observer **from the same player instance** that created it. Every closure captures `[weak self]`.
- `PlayerViewModel.stop()` runs when `PlayerVC` is actually dismissed (`isBeingDismissed`), not when AVKit's own full-screen mode covers it. It records `PLAYER_CLOSED`, invalidates the handler, removes lifecycle observers, then pauses and clears the item. Observers are removed *before* pausing, so teardown doesn't log a fake `PLAYER_PAUSED`.
- **App lifecycle:** when the app enters the background, the player is paused explicitly, which produces a deterministic `PLAYER_PAUSED`. It stays paused on return. PiP and background audio are disabled, so there is no background playback to manage.
- **Retry** after an error rebuilds the `AVPlayerItem`, re-attaches the handler with fresh state, and seeks back to the last known position once the new item is ready.

### Seek detection with native controls: limitations

AVKit on iOS has no public callback for scrubber or skip-button seeks (the `AVPlayerViewControllerDelegate` seek callbacks are tvOS-only). Seeks are therefore *inferred*:

- `timeJumpedNotification` says *that* a jump happened, not where it came from. The origin is taken from the periodic time observer (every 0.5 s), so it can be off by up to about 0.5 s. When the observer's jump tick arrives before the notification, the handler uses the tick before it.
- Jumps under 1 s are ignored, and a scrub is reported once, 0.4 s after it settles. That means `PLAYER_SEEKED` can be logged just after a following `RESUMED`, but its `from`/position values are correct.
- A programmatic seek, such as the resume-after-retry seek, is reported as a seek too.

---

## Replacing the static JSON with a real API

Only the data source changes. Screens, view models, use cases, domain models, the repository protocol and the mapper stay as they are, as long as the API returns the same JSON shape.

```swift
final class RemoteHomeFeedDataSource: HomeFeedDataSource {
    private let url: URL
    private let networkManager: NetworkManager

    init(url: URL, networkManager: NetworkManager = .shared) {
        self.url = url
        self.networkManager = networkManager
    }

    func fetchHomeFeed() async throws -> HomeFeedResponseDTO {
        let data = try await networkManager.data(from: url)
        return try JsonHelper.decode(HomeFeedResponseDTO.self, from: data)
    }
}
```

Then make the one-line swap in `AppDependencyContainer.contentRepository`:

```swift
DefaultContentRepository(dataSource: RemoteHomeFeedDataSource(url: feedURL))
```

`NetworkManager` already maps HTTP status codes, connectivity failures and decoding failures to `NetworkError`, and those messages flow through to the existing error/retry UI. If the API's shape differs, only the DTOs and `HomeFeedMapper` need to change.

---

## Sample media and artwork

All streams are publicly hosted test media, accessed over HTTPS.

| Content | Stream | Source |
|---|---|---|
| Tears of Steel | HLS | Unified Streaming demo server (`demo.unified-streaming.com`) |
| Tears of Steel (Subtitled) | fMP4 HLS | Mux test streams (`test-streams.mux.dev/tos_ismc`) |
| Big Buck Bunny | HLS | Mux test streams (`test-streams.mux.dev/x36xhzz`) |
| Sintel · Trailer, Big Buck Bunny · Trailer, Studio Reel | MP4 | W3C media test files (`media.w3.org/2010/05/…`) |
| Sintel · HD Trailer | MP4 | Blender Foundation (`download.blender.org/durian`) |
| Jellyfish Drift, Bunny Bite | 10 s MP4 | test-videos.co.uk |
| Adaptive Stream · Advanced / 16:9 / 4:3 | HLS | Apple's HLS examples (`devstreaming-cdn.apple.com`) |

Big Buck Bunny, Sintel and Tears of Steel are Blender Foundation open movies (© Blender Foundation, CC BY 3.0). Their artwork comes from the films' official Blender project sites, and the trailer posters from the W3C test set. Artwork for the generic test clips comes from `picsum.photos` (Unsplash photos, chosen by seed). It is placeholder imagery and doesn't depict the clip. All titles and descriptions in `home_feed.json` were written for this project.

## Known limitations

- **Network-dependent:** media and artwork are third-party URLs that may change or disappear. Google's long-used `gtv-videos-bucket` samples now return 403, which is why they aren't used. A dead URL shows the player's error view with retry, or the artwork failure placeholder.
- Seek detection is inferred (see above).
- Background playback, Picture in Picture, AirPlay-specific handling, captions styling, Now Playing info and audio-session interruption handling (e.g. incoming calls) are out of scope. AVFoundation's default interruption behaviour applies.
- After returning from the background, playback stays paused by design.
- Fixed font sizes; Dynamic Type isn't supported in the rails, because card heights are fixed.
- iPhone only (`TARGETED_DEVICE_FAMILY = 1`).
- Unit tests need an iOS 17+ simulator, though the app itself targets iOS 15.
- No UI tests. Flows were verified manually in the simulator (see below).

## Verification performed

On Xcode 27.1, iPhone 17 Pro simulator (iOS 26.5):

- Clean build with no compiler warnings; 27/27 unit tests pass, stable across repeated runs.
- **Manual simulator checks:**
  - Home: full-bleed hero under the status bar with no nav title; status-bar backdrop fades in on scroll; artwork loading and placeholders.
  - Rails: one-card paging.
  - Trailers carousel: auto-advances every 5 s and wraps; the focused card is raised with clear gaps and no overlap; one card per swipe in both directions (confirmed with temporary drag logging, since removed).
  - Navigation: card → detail, hero **Details** → detail, hero **Play** → player, back (Home's bar stays hidden, Detail's shows).
  - Detail: full-bleed header under a transparent bar.
  - Playback: MP4 and HLS; play, pause, ±10 s skip, scrubbing; landscape.
  - Lifecycle: background pause, stays paused on return.
  - Completion and replay.
  - Errors: home error state with retry (`-homeFeedFile missing_feed`); player error view with retry (using a temporary feed with a 404 URL, placed only in the simulator's installed copy).
  - Close player.
- **Cleanup:** after closing the player, a heap inspection showed no live `PlayerViewModel`/`PlayerVC`/handler objects, and `leaks` reported 0 leaks. After popping the detail screen, its view model was gone too.
- **Not verified:** the detail header's stretch and parallax, and the transparent → frosted bar switch, were not captured on screen (the bundled descriptions are too short to scroll past the header); physical devices, iOS 15/16 runtimes (none installed), real network stalls (`BUFFERING_*` is covered by unit tests, not observed live), audio interruptions.
