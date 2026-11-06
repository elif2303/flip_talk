# Flip Talk: Reverse Voice Game

A party game for 2–8 players on a single phone. One player secretly picks a word, the phone plays it **backwards**, and the next player has to work out what it was. Built with Flutter, Android first.

> Say it. Flip it. Guess it!

## How it works

1. **Speaker** secretly types or says a word.
2. The app reverses the audio.
3. **Guesser** listens (up to 3 times), then **imitates** the strange sound by recording themselves. The imitation is played backwards, and if it is a good copy, it sounds like the real word.
4. The guesser takes up to 3 tries to name the word and scores points.

### Two game modes

| Mode | How the word is made | How a guess is checked |
|---|---|---|
| **No headphones** | The word is typed and read aloud by the phone's text-to-speech engine, then reversed | Automatically, against the typed word (case, accents and punctuation are ignored) |
| **With headphones** | No typing: the speaker records their own voice | The speaker taps *Correct / Wrong* |

### Scoring

- Typed mode: the guesser gets 3 points minus 1 per hint used (minimum 1). Hints: letter count, first letter.
- Voice mode: 3 / 2 / 1 points depending on whether the guess was right on the 1st / 2nd / 3rd try.
- Only the player who guesses correctly scores.

## Features

- 2–8 players, each with their own colour, on one phone
- 1–3 rounds
- Playback speed 0.5× / 0.75× / 1× that keeps the pitch (WSOLA time-stretch, no "slow-motion" voice)
- Reversal pipeline: silence trimming, DC removal and high-pass filter, peak normalisation, soft fades to avoid clicks
- 4 languages: English, Türkçe, Deutsch, العربية (with right-to-left layout)
- Recordings are temporary and deleted after each turn; nothing is uploaded
- Ads via Google AdMob (banner on result screens, interstitial every 3rd turn) with the EU consent form (UMP)

## Tech

- Flutter / Dart, Material 3
- [`record`](https://pub.dev/packages/record), [`audioplayers`](https://pub.dev/packages/audioplayers), [`flutter_tts`](https://pub.dev/packages/flutter_tts), [`path_provider`](https://pub.dev/packages/path_provider), [`shared_preferences`](https://pub.dev/packages/shared_preferences), [`google_mobile_ads`](https://pub.dev/packages/google_mobile_ads)
- No state-management package: `ChangeNotifier` + `InheritedNotifier`
- Translations live in plain Dart maps (`lib/strings.dart`), no code generation

## Project structure

```
lib/
  main.dart           App entry point
  app_state.dart      Settings (language, speed, mode, names) + AppScope
  strings.dart        EN / TR / DE / AR translations
  theme.dart          Colours and Material theme
  audio_service.dart  Recording, TTS, playback, WAV reverse and time-stretch
  game.dart           Game state machine, scoring, word normalisation
  screens.dart        Home, setup, game pages (speak, guess, result, finish)
  widgets.dart        Shared widgets (hold-to-record button, language dialog)
  ads.dart            AdMob + consent handling
```

## Getting started

Requirements: Flutter SDK (stable), Android SDK, an Android device or emulator.

```bash
flutter pub get
flutter run
```

Recording needs a real microphone, so a physical device is recommended.

### Ads

`lib/ads.dart` ships with Google's **test** ad unit IDs (`kTestAds = true`). Before releasing:

1. Set `kTestAds = false`.
2. Fill in your own banner and interstitial unit IDs in `lib/ads.dart`.
3. Replace the test AdMob app ID in `android/app/src/main/AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`) with your own.

Never click your own live ads.

### Release build

Signing uses `android/key.properties`, which is **not** part of this repository. Create it locally:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=/path/to/your-keystore.jks
```

Then:

```bash
flutter build appbundle
```

The Android App Bundle is created at `build/app/outputs/bundle/release/app-release.aab`.

Keep your keystore and `key.properties` out of version control (see `.gitignore`).

## Permissions

| Permission | Why |
|---|---|
| `RECORD_AUDIO` | Voice mode and the imitation step. Recording only runs while the button is held. |
| `INTERNET` / ad ID | Added by the AdMob SDK for advertising |

## Privacy

Voice recordings stay on the device and are deleted after each turn. See the privacy policy: **[add your policy URL here]**.

## Author

Maez
