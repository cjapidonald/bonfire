# Prompt 0 — Project Bootstrap & Capabilities

- Create a new SwiftUI iOS app named Bonfire targeting iOS 16.4 or later.
- Set Bundle ID to `com.bon.bonfire`; set Team to `59Q6X62P3A`.
- Add Localizations: English (Base) and Vietnamese.
- Add Capabilities: iCloud (CloudKit), Sign in with Apple, Microphone, Background Modes (Audio), Keychain Sharing.
- Add iCloud container: `iCloud.com.bonefire.myapp` and enable CloudKit services.
- Add Info.plist usage strings for microphone and a placeholder for camera/speech (future).
- Create folders: AppShell, DesignSystem, Reader, Audio, Vocab, Achievements, Cloud, Storage, Dictionary, Analytics, Utilities, DevTools.
- Constraints: Do not add external pods yet; keep stock Apple frameworks.
- Acceptance Criteria: Project builds; empty TabView with 4 tabs appears; entitlements show iCloud + SIWA; localizations present.

# Prompt 1 — Source Control & Project Hygiene

- Initialize a Git repo with main branch `main`.
- Add a `.gitignore` suitable for Xcode and derived data.
- Add a `CONTRIBUTING.md` with commit message style and branching strategy (`feature/*`, `fix/*`).
- Create a `Docs/` folder with this spec exported as README section headings.
- Constraints: No binary assets checked in except placeholder textures.
- Acceptance Criteria: Repo initialized; README references app IDs; branching rules documented.
