# frontend

Ceylon Heritage mobile client built with Flutter.

## Local configuration

The API URL, Google sign-in client ID, and (optionally) Google Places API key are supplied at build time. To show Google place photos, enable Places API (New) with billing in Google Cloud and restrict the key to the app/platform and Places API. The key is part of the client app, so use an appropriately restricted key.

```sh
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8081 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=your_google_server_client_id \
  --dart-define=GOOGLE_PLACES_API_KEY=your_restricted_places_api_key
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
