# Kontak Perkasa Futures (KPF) App

Multi-platform Flutter application (Android & iOS) integrating KPF WebView configurations.

## Features
- **WebView Integration**: Displays the KPF website (kpf-dev.kp-futures.com).
- **Native Navigation**: Bottom Navigation Bar with 5 main menus (Home, About, Products, Procedures, News).
- **External Link Handling**: Handles external links (WhatsApp, Tel, Email, Maps, Social Media) to open in native applications.
- **Adaptive Icons**: Responsive app icons for various Android and iOS versions.

## Project Structure
- `lib/main.dart`: App entry point.
- `lib/home_screen.dart`: Main screen with Bottom Navigation.
- `lib/webview_manager.dart`: Logic for WebView and URL navigation.
- `android/`: Native Android configurations (Permissions, Icons).
- `ios/`: Native iOS configurations (Info.plist, Icons).

## How to Run

Prerequisites: Flutter SDK installed.

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Run Application**
   ```bash
   flutter run
   ```

## Troubleshooting

If build errors occur (such as `Daemon compilation failed` or `Resource not found`):

1. **Clean Project**
   ```bash
   flutter clean
   ```

2. **Delete `.gradle` Folder (Optional if error persists)**
   Delete the `android/.gradle` folder inside the `kpf_app` directory.

3. **Retry**
   Try running the `run` command again.
