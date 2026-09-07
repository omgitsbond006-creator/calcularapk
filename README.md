# Calcular — Android build & Play Store publishing kit

This folder is a complete, ready-to-build Flutter/Android project, already
wired to a real release-signing keystore. You cannot compile this into an
.apk/.aab without Flutter + the Android SDK installed on your own machine
(that toolchain isn't available in the environment that generated this kit),
but every file here is real and build-ready — once you run one command
locally, you get a signed release build.

## 1. What's in this folder

```
calcular_project/
├── lib/main.dart                  the calculator app
├── pubspec.yaml                   version 1.0.0+1
├── upload-keystore.jks            REAL signing keystore (keep private)
├── .gitignore                     keeps the keystore/passwords out of git
└── android/
    ├── key.properties             REAL passwords, points at the keystore
    ├── build.gradle, settings.gradle, gradle.properties
    └── app/
        ├── build.gradle           applicationId + release signing config
        ├── proguard-rules.pro
        └── src/main/
            ├── AndroidManifest.xml
            ├── kotlin/com/calcular/app/MainActivity.kt
            └── res/ (launcher icons + launch theme)
```

## 2. Build it (run this on your own machine)

You need Flutter (stable channel, latest version) and the Android SDK
installed and on your PATH — `flutter doctor` should show no blockers.

```bash
cd calcular_project
flutter pub get
flutter build appbundle --release   # what you upload to Play Console
flutter build apk --release         # optional, for direct/manual installs
```

Output lands at:
- `build/app/outputs/bundle/release/app-release.aab` ← upload this to Play Console
- `build/app/outputs/flutter-apk/app-release.apk` ← sideloadable APK

Both will already be signed with `upload-keystore.jks` — Gradle picks up
`android/key.properties` automatically via the `android/app/build.gradle`
included here.

### If Gradle complains about a version mismatch

The `android/` folder here uses Android Gradle Plugin 8.5.0 and Kotlin
1.9.24, which are broadly compatible with recent Flutter versions. If your
installed Flutter version generates a conflict, the safest fix is:

```bash
flutter create --org com.calcular --project-name calcular temp_scaffold
```

then copy just these files from *this* kit into the freshly generated
`temp_scaffold` project (overwriting the equivalents it created):
`lib/main.dart`, `pubspec.yaml`, `upload-keystore.jks`,
`android/key.properties`, and the `signingConfigs`/`buildTypes`/
`applicationId` block from `android/app/build.gradle`. Then build from
`temp_scaffold` instead.

## 3. Package name (applicationId)

**`com.calcular.app`**

This is permanent — once you publish with this ID, it can never be changed
without publishing as a brand-new listing. It doesn't need to match a domain
you own; it just needs to be globally unique on Play Store. If you'd rather
use your own name/brand, change `applicationId` in `android/app/build.gradle`
(and the matching `namespace` value, and move/rename the `MainActivity.kt`
package folder to match) before your first build — not after.

## 4. Signing key — keep this section private

- **Keystore file:** `upload-keystore.jks` (PKCS12 format)
- **Alias:** `upload`
- **Store password / key password:** identical in PKCS12 — see
  `KEYSTORE_INFO.txt` alongside this project
- **Validity:** 10,000 days from generation (until ~2054)
- **SHA-1 and SHA-256 fingerprints:** in `KEYSTORE_INFO.txt`

This is your **upload key**, not Google's app signing key. When you publish
your first release, Play Console will offer **Play App Signing** (opt-in is
effectively required for new apps) — Google then generates and holds the
real app signing key, and this upload key is just what you use locally to
sign builds before uploading. That matters practically: if you ever lose
this keystore or its password, you are *not* locked out forever — you can
request an upload-key reset from Play Console support, because Google still
holds the actual signing key your users' installs trust.

Still, treat this file and its password as sensitive:
- Never commit `upload-keystore.jks` or `key.properties` to a public repo
  (the included `.gitignore` already excludes both).
- Keep a private backup somewhere durable (password manager + encrypted
  drive). If you lose both the keystore and Google's record of it, you'd
  need to publish under a new package name.

## 5. Everything else you'll need in Play Console

**Developer account**
- One-time $25 USD registration fee for a Google Play developer account.
- If this is a new *personal* account (created after Nov 13, 2023), Google
  requires a **closed test with at least 12 opted-in testers for 14
  continuous days** before Production and pre-registration unlock. Start
  this early — upload any working build to a Closed Testing track on day
  one, since the 14-day clock only runs while ≥12 testers stay opted in.
  Organization accounts are exempt from this.

**Build format**
- Play Store requires an **Android App Bundle (.aab)**, not a raw APK, for
  new app submissions. Use `flutter build appbundle --release`.

**Target API level**
- As of the Aug 31, 2026 policy update, new apps must target **Android 16
  (API level 36)** or higher. `android/app/build.gradle` here points
  `targetSdkVersion`/`compileSdk` at `flutter.targetSdkVersion` /
  `flutter.compileSdkVersion`, which Flutter's own Gradle plugin sets — so
  as long as you build with a current stable Flutter release, this is
  satisfied automatically. Run `flutter --version` and update
  (`flutter upgrade`) if it's old.

**App details you'll be asked for**
- App name: `Calcular`
- Short description / full description: in `store_listing.txt` (provided
  earlier)
- App icon (512×512): `icon.png` (provided earlier)
- Feature graphic (1024×500): `featured_image.png` (provided earlier)
- Phone screenshots: the four `screenshot_*.png` files (provided earlier) —
  minimum 2 required, up to 8
- Privacy policy URL: `privacy_policy.html` (provided earlier) must be
  hosted somewhere public (GitHub Pages, Netlify, your own site, etc.) —
  Play Console needs a live URL, not a file upload. Replace the
  `support@example.com` placeholder in it with your real contact email
  first.
- Data safety form: Calcular collects and shares no data at all, and
  requests no permissions, so you can answer "No data collected" throughout
  this section — truthfully, since the app has no network or storage access.
- Content rating questionnaire: a simple offline calculator with no user
  content, ads, or social features will rate as **Everyone/3+** in nearly
  every region.
- Category: Tools (or Productivity).

**Version info** (already set in `pubspec.yaml`)
- versionName: `1.0.0`, versionCode: `1` — bump both for every future
  update (`flutter build appbundle --release` reads these from
  `pubspec.yaml`'s `version: 1.0.0+1` line — format is
  `versionName+versionCode`).
