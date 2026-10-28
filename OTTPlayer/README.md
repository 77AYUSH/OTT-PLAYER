# OTT Player

A small OTT-style iOS app in UIKit: **Home → Content Detail → Video Player**.

- Home has a full-bleed hero banner and horizontal rails that page one card at a time. The *Trailers* rail is a carousel that auto-advances every 5 seconds.
- Each card opens a detail screen, and **Play** opens an AVKit player that reports typed playback events.
- All content comes from a bundled JSON mock API, loaded through the data layer.

## Requirements

- iOS 15.0+ (unit tests need an iOS 17+ simulator)
- Xcode 16 or later
- No third-party dependencies: UIKit, AVFoundation, AVKit, Combine and `os` only

## Run

Open `OTTPlayer.xcodeproj`, pick the **OTTPlayer** scheme and an iPhone simulator, then press ⌘R. Run the tests with ⌘U.

- **Error state:** enable the scheme's launch argument `-homeFeedFile missing_feed`.
- **Player events:** they're logged to the Xcode console under the `analytics` category.

## Architecture

```
UI (VC + XIB) → ViewModel → UseCase → Repository → DataSource
                                                   JSON → DTO → Mapper → Domain
```

- **Presentation:** `Screens/<Feature>/View` and `/ViewModel`. View models are `@MainActor`, publish a `state` enum through Combine, and depend only on use-case protocols.
- **Domain:** models, repository protocols and use cases, with no UIKit or data-layer imports.
- **Data:** DTOs, a defensive mapper (drops invalid URLs, unknown or duplicate IDs, and empty rails), the data source and the repositories.
- **DI:** `AppDependencyContainer` builds the object graph. Screens navigate through a `ScreenFactory` protocol.

```
OTTPlayer/
├── Appdelegates/  DI/  Constants/  Network/
├── Helper/ (+ Extensions/)       JsonHelper, ImageLoader, NavHelper, PlayerEventHandler, AppLogger
├── CustomReusableFiles/          StateMessageView, GradientView, AppLogoView
├── CollectionCellsAndHeaders/    Hero, content card, carousel, rail header
├── Domain/  Data/
├── Screens/                      Splash, Home, ContentDetail, Player
└── Resources/                    home_feed.json, Assets.xcassets
OTTPlayerTests/                   27 unit tests
```

## Player events

`AVPlayer → PlayerEventHandler → PlayerViewModel → TrackPlayerEventUseCase → PlayerEventRepository`

| Event | Trigger |
|---|---|
| `PLAYER_READY` | Item becomes ready to play |
| `PLAYER_STARTED` | First playback |
| `PLAYER_PAUSED` / `PLAYER_RESUMED` | Pause and resume (an end-of-item pause isn't reported) |
| `PLAYER_SEEKED` | Time jump of 1 s or more; scrub bursts are combined into one event |
| `PLAYER_BUFFERING_STARTED` / `_ENDED` | A real stall after playback has started |
| `PLAYER_COMPLETED` | Reached the end |
| `PLAYER_ERROR` | Item failed (reported once) |
| `PLAYER_CLOSED` | Player dismissed |

Observers are KVO publishers, notifications and a periodic time observer. All of them are removed when the player closes. The app pauses playback when it goes to the background.

## Switching to a real API

Only the data source changes:

```swift
final class RemoteHomeFeedDataSource: HomeFeedDataSource {
    func fetchHomeFeed() async throws -> HomeFeedResponseDTO {
        let data = try await NetworkManager.shared.data(from: feedURL)
        return try JsonHelper.decode(HomeFeedResponseDTO.self, from: data)
    }
}
```

Then pass it to `DefaultContentRepository` in `AppDependencyContainer`. Nothing else needs to change.

## Tests

The tests cover:
- the mapper and the bundled feed
- the data layer and repository
- the Home view model, including retry and dropping stale results
- the player event rules
- event propagation from the player handler to the repository

## Known limitations

- Media and artwork are public test URLs and may change or disappear.
- Seeks from the native controls are inferred from time jumps, because AVKit exposes no seek callback on iOS.
- There's no background playback or Picture in Picture. iPhone only, with fixed font sizes.

## Credits

Big Buck Bunny, Sintel and Tears of Steel are © Blender Foundation (CC BY 3.0). The other clips are public test media from Apple, Mux, Unified Streaming, W3C and test-videos.co.uk. Placeholder artwork comes from picsum.photos.
