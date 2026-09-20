# Simple Mirror 照下鏡／就是鏡

[![Last Updated](https://img.shields.io/badge/Last%20Updated-2026--09--20-brightgreen.svg)](https://github.com/tomfong/simple_mirror)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

<p align="center">
	<img src="web/icons/Icon-512.png" alt="Simple Mirror app icon" width="128"><br>
	<strong>Simple Mirror</strong><br>
	A simple app that lets you see yourself as others see you, in real time.
</p>
<br>
<p align="center">
  <img height="300" src="https://raw.githubusercontent.com/tomfong/simple_mirror/main/.github/images/01.jpg">
  <img height="300" src="https://raw.githubusercontent.com/tomfong/simple_mirror/main/.github/images/02.jpg">
  <img height="300" src="https://raw.githubusercontent.com/tomfong/simple_mirror/main/.github/images/03.jpg">
</p>


## About

Simple Mirror is a simple, privacy-first mirror app that lets you see yourself as others see you, in real time. It presents a live front-camera preview without taking or saving photos. The camera is released whenever you leave the mirror screen, and it is also released while the app is inactive.

See yourself as others see you.

讓你看見別人眼中的自己。

| Android | iOS / Web | GitHub | 
|:-:|:-:|:-:|
| [<img src="https://raw.githubusercontent.com/tomfong/simple_mirror/main/.github/images/google-play-badge.png" height="50">](https://play.google.com/store/apps/details?id=com.tomfong.simplemirror) | [<img src="https://raw.githubusercontent.com/tomfong/simple_mirror/main/.github/images/pwa-badge.png" height="50">](https://simple-mirror.pages.dev/) | [<img src="https://raw.githubusercontent.com/tomfong/simple_mirror/main/.github/images/github-badge.png" height="50">](https://github.com/tomfong/simple_mirror/releases/latest) | 

Author: Tom FONG

[![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat&logo=github&logoColor=white)](https://github.com/tomfong)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/tom-lh-fong/)

## Features

- Full-screen live front-camera preview
- Horizontal flip control for a view of how other people see you or how you look in a mirror
- Camera access released when opening settings or when the app goes inactive
- English, Traditional Chinese, and Traditional Chinese (Hong Kong) interface
- Light, dark, and black color themes
- Direct shortcut to the operating system's app settings
- No photo capture, backend, ads, or data collection

## Platforms

- Android / Google Play
- iOS (PWA only)
- Web / PWA

For web deployment, serve the app through HTTPS. Browsers require a secure context before allowing camera access.

## Install

### Android

Install from [Google Play](https://play.google.com/store/apps/details?id=com.tomfong.simplemirror).

### iOS / PWA

Open [Simple Mirror](https://simple-mirror.pages.dev/) in Safari, tap the Share button, then select **Add to Home Screen**. The app will open as a PWA from the home screen.

### Web / PWA

Open [simple-mirror.pages.dev](https://simple-mirror.pages.dev/) in a modern browser. Camera access requires HTTPS and browser permission.

## Build The Project

```sh
flutter pub get
flutter run
```

Build release artifacts with:

```sh
flutter build apk
flutter build ios
flutter build web
```

## Make Commands

The `Makefile` provides short commands for the common development workflow:

```sh
make help
make check
make run
make run-web WEB_PORT=8081
make build-android
make build-ios
make build-web
```

`make run-web` selects the next available port when `WEB_PORT` is already in use. Use `make help` to list every available command.

## Privacy

Simple Mirror requests camera permission only to show the live mirror preview. It does not take photos, record video, upload camera content, or collect personal data.

## License

Simple Mirror is released under the [MIT License](LICENSE).

## Contribute

- Open an issue for bugs or ideas at [GitHub Issues](https://github.com/tomfong/simple_mirror/issues).
- Star the [repository](https://github.com/tomfong/simple_mirror).
- Sponsor the project.

  [![GitHub Sponsor](https://img.shields.io/badge/sponsor-30363D?style=flat&logo=GitHub-Sponsors&logoColor=#white)](https://github.com/sponsors/tomfong?frequency=one-time)
  [![Buy me a Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=flat&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/tomfong)

---

_SIMPLE DEV . SIMPLER WORLD_
