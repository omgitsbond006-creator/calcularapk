# Building Calcular with no local setup (GitHub Actions)

This lets GitHub's own servers install Flutter + the Android SDK and
produce your signed .aab/.apk — you never install anything locally.
`.github/workflows/build.yml` is already included and configured.

## One-time setup

1. Create a new **private** repository on GitHub (private matters — see
   step 3) and push this folder's contents to it:

   ```bash
   cd calcular_project
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/<your-username>/<repo-name>.git
   git push -u origin main
   ```

   The `.gitignore` here already excludes `upload-keystore.jks`,
   `android/key.properties`, `KEYSTORE_INFO.txt`, and
   `keystore_base64.txt` — none of your signing material gets pushed.
   Good, because GitHub Actions builds the signing material back in from
   **repository secrets** instead (step 2).

2. In the repo on GitHub: **Settings → Secrets and variables → Actions →
   New repository secret**. Add two secrets:

   | Secret name | Value |
   |---|---|
   | `KEYSTORE_BASE64` | the full contents of `keystore_base64.txt` (one long line) |
   | `KEYSTORE_PASSWORD` | `rlfl2gtauKa7EYIBrZqE4zDb` |

3. Go to the **Actions** tab and run the "Build signed Calcular release"
   workflow (or just push a commit — it also runs automatically on every
   push to `main`). It takes a few minutes.

4. When it finishes, open the completed run — two downloadable artifacts
   will be attached: `calcular-release-aab` (upload this to Play Console)
   and `calcular-release-apk` (for sideloading/testing directly on a
   phone). Both are signed with your real `upload-keystore.jks`, so an
   `.aab` built this way is accepted by Play Console exactly as if you'd
   built it locally.

## Why private, and why secrets instead of committing the file

`KEYSTORE_BASE64` decodes back into your actual signing key. GitHub
repository secrets are encrypted and never exposed in logs or to forks,
which is why the workflow reads the keystore that way instead of you
committing `upload-keystore.jks` into the repo — keep the repo private
too, since secrets protect the keystore's *contents* but a public repo
would still expose your source, package name, and app structure.
