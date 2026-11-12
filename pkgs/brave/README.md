# Local Brave package

Packages the official Brave stable `.deb` for `x86_64-linux`; it does not
compile Chromium/Brave. The existing package-directory overlay exposes it as
`pkgs.brave`, replacing the removed nixpkgs alias without another flake input.

The packaging is adapted from Nixpkgs revision
`1d060086d60cb76a40cf37109f979d88a5bd6396`, under its MIT license:
<https://github.com/NixOS/nixpkgs/tree/1d060086d60cb76a40cf37109f979d88a5bd6396/pkgs/applications/networking/browsers/brave>.
The packaging's license notice is preserved in `COPYING.nixpkgs`; Brave's
own bundled licenses remain in the installed application.

For the privacy/Vim-browser comparison, see [alternatives.md](alternatives.md).

## Security and updates

Nixpkgs removed Brave on 2026-11-03 because its maintainers lacked committers
to unblock security issues. This package makes **this repository responsible
for promptly tracking and packaging security releases**. Updating flake inputs
alone does **not** update Brave. Do not freeze an old release indefinitely.

1. Check the latest **stable**, non-prerelease release and its Chromium security
   fixes: <https://github.com/brave/brave-browser/releases/latest>.
2. Download the versioned `brave-browser_<version>_amd64.deb` using
   `nix store prefetch-file --json <release-asset-URL>`.
3. Compare its SHA-256 with the release's `.deb.sha256` file and asset digest;
   verify the signed checksum against Brave's independently trusted signing key
   where available: <https://brave.com/signing-keys/>. A matching download hash
   ensures reproducibility, not independent publisher authentication.
4. Update `version` and `src.hash` in `default.nix`; review upstream packaging
   changes and security advisories. Never use a mutable `latest` download URL
   inside the derivation.
5. Build the package and the exact host before activation:

   ```sh
   nix build --no-link --expr 'let f = builtins.getFlake (toString ./.); in f.nixosConfigurations.thinkpad.pkgs.brave' --impure
   nix build --no-link .#nixosConfigurations.thinkpad.config.system.build.toplevel
   ```

The install check runs the patched executable's `--version` and verifies the
desktop launcher. It is not a GUI or renderer-sandbox test. This package does
not pass `--no-sandbox` or install a privileged setuid helper; normal Chromium
user-namespace sandboxing must remain available. Check `brave://sandbox` after
launching the updated browser. Outdated-build warnings are not suppressed.

Existing Brave profile persistence, managed extensions (including Vimium C),
and policies remain in the desktop branch. No profile data is copied or
deleted. Normal Brave networking and optional features remain upstream's;
this package does not enable Sync, Rewards, Leo, or another hosted integration.

## Brave Sync (runtime enrollment)

Sync was requested for this desktop and other personally controlled devices.
The repo does not disable Sync; **creating/joining a chain must happen in Brave**,
not through a store-readable Nix option or an activation script. The existing
`.config/BraveSoftware` persistence retains this device's profile/enrollment.
No Sync chain has been created by the package build.

1. In Brave open `brave://settings/braveSync` (or Settings → Sync) and choose
   **Start a new sync chain**, then the other device type.
2. On the other device open Brave's Sync settings and choose to scan/enter an
   existing chain code. Transfer the displayed QR/code **directly between your
   devices**; never paste it into chat, logs, screenshots, Git, Nix or shell
   commands. It grants access to the chain. Use the currently displayed code,
   not a stale saved code.
3. Review data categories on each device. Start with **bookmarks only**; enable
   history, open tabs or other categories only if you want those shared too.
   Keep passwords/autofill off unless separately wanted: Bitwarden already
   handles your passwords, and syncing extensions/settings may overlap HM.
4. Verify both devices appear and a synthetic test bookmark synchronizes.

Brave documents client-side encryption of Sync data. Encrypted selected data
is nevertheless transmitted to Brave's Sync service; service metadata such as
IP/timing can remain visible. This is distinct from local-only qutebrowser data.
Review Brave's privacy/Sync documentation for hosting, retention and transfers;
this repo does not choose a legal basis or a retention period. To stop syncing,
leave the chain in the UI. Deleting the Sync account affects **all** devices
and server-side data, so never do that as routine troubleshooting.

Sources: [setup](https://support.brave.com/hc/en-us/articles/360021218111),
[Sync design](https://support.brave.com/hc/en-us/articles/360059793111),
[privacy](https://brave.com/privacy/browser/).
