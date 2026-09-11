# Mobile TV Studio

One Android + iOS app that turns phones into a full TV-style broadcast studio.

Install the same app on every phone. Choose what each phone does:

- **Camera** — sends live video
- **Director** — control room with multiview, switching, and streaming out
- **Both** — send and control from the same device

## Features

- Multiple phone cameras over Wi-Fi, Bluetooth, or internet
- ATEM-style control center: cut, fade, multiview, audio mixer
- Commercial break insertion ("we'll be back" button)
- Stream out to YouTube, Facebook, Twitch, custom RTMP
- Works across 12 km via cloud relay
- Data budget mode for metered networks
- Local recording as backup

## Platform support

| Feature | Android | iOS |
|---|---|---|
| Camera streaming (foreground) | Yes | Yes |
| Camera streaming (background) | Yes | Limited |
| Multiple cameras | Yes | Yes |
| Bluetooth video (RFCOMM) | Yes | Blocked by Apple |
| Wi-Fi / WebRTC video | Yes | Yes |
| Internet relay (long distance) | Yes | Yes |
| RTMP out | Yes | Yes |
| USB / HDMI capture | Yes | Limited |

iOS cannot do Bluetooth video. That is an Apple policy, not a code limit.
Everything else runs on both platforms.

## Build

### In GitHub Codespaces (no local install)

1. Open this repo on github.com
2. Click **Code → Codespaces → Create codespace on main**
3. Wait for setup to finish
4. Run: `flutter pub get`
5. Run: `flutter run`

### On your own machine

```bash
flutter pub get
flutter run
