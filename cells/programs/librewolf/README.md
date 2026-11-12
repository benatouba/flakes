# LibreWolf alternative

`cells/programs/librewolf.nix` contributes Home Manager configuration to the
`desktop` branch. Hosts select branches as before; there are no host-specific
imports. Brave remains the default browser and its profile is untouched.

Launch `librewolf` after activating the configuration yourself. No activation,
account sign-in, browser-data import or Sync enrollment is performed by this
module. Existing LibreWolf profiles are not replaced with a managed profile.

## Privacy and blocking

LibreWolf is a strong privacy alternative, **not identical Brave Shields**.
It uses Gecko rather than Chromium and full **uBlock Origin**, including network
and cosmetic filtering, rather than Brave's Rust blocker. Keep uBO's default
filters; stacking another general-purpose adblocker is unnecessary.

The upstream hardening is preserved: strict tracking protection and cookie
partitioning, anti-fingerprinting, HTTPS-only mode, no browser telemetry, disabled
Sync and WebGL, and cookies/site data cleared on close by default. This can break
some sites or require repeat logins. **Google Safe Browsing and DRM are disabled
upstream**; privacy is not the same as phishing protection or anonymity. These
defaults were explicitly approved; no exceptions are silently added.

The `persist` branch conditionally retains `.librewolf` under `/persist` when
LibreWolf is enabled. This retains bookmarks, history and extension state,
including encrypted Bitwarden cache after login, but does not override
clear-on-close behavior. HTTP cache is not separately persisted. Existing backups
covering `/persist` may include the profile; no new backup, retention period,
automatic deletion or sync service is configured. Protect those backups like
other browser/vault state. Closing the browser does not guarantee removal from
backups or recovery of already-cleared site data.

## Brave extension counterparts

| Brave extension | LibreWolf configuration |
| --- | --- |
| Bitwarden | Official Firefox extension; sign in manually using your existing service |
| Vimium C | Firefox version, including Vim navigation and link hints |
| Dark Reader | Firefox version; use its toolbar control for site exceptions |
| React Developer Tools | Official Firefox version |
| Zotero Connector | Official Firefox XPI from Zotero; existing desktop/service setup still needed |
| ColorZilla | Official Firefox version |
| UnDistracted | Firefox version |
| SponsorBlock | **Manual opt-in**, as agreed; see below |
| Claude-in-Chrome | Not supported on Firefox/LibreWolf; continue using Brave |
| Brave Shields adblocking | Full uBlock Origin, supplied from a pinned release |

Extensions are installed using `ExtensionSettings` with `normal_installed`, so
you can disable them in `about:addons`. The upstream uBO private-window policy
is retained. Other extensions are not automatically granted private-window
access. Several have broad page/tab/history/clipboard permissions: matching the
Brave setup adds trusted code and attack surface, not extra privacy by itself.
ColorZilla and UnDistracted have proprietary/custom terms; their exact releases
and license references, along with all other pins, are in `addons.json`.

No account metadata, credentials or private service endpoints are configured.
For Bitwarden, choose your existing server **before signing in**, directly in
the extension UI; no vault material belongs in Nix or chat. No native messaging
host or desktop-unlock integration is newly enabled.

### SponsorBlock: deliberate manual opt-in

The signed Firefox extension enables segment-view reporting by default. Unlike
our qutebrowser script, it cannot be configured with a supported enterprise
policy to switch that off. It is therefore **not auto-installed**.

If wanted, install [the official SponsorBlock extension][sponsorblock] yourself
and open its settings **before opening YouTube**. Disable the option for counting
skips/views (including private-window reporting), review automatic downvote
reporting and experiments, and leave optional reporting off. Wording can vary by
release. Segment lookups still contact SponsorBlock and disclose your IP and
video-related lookup data; submitting/voting sends additional information.
This repository does not control that service's storage location, retention or
international transfers. No compliance conclusion is implied.

## Downloads and updates

`addons.json` pins the **initial install artifacts**, fetched at build time by
`pkgs.fetchurl`. AMO entries use version-specific release URLs and the hashes
published by the AMO API; Zotero uses its version-specific official download.
The original XPIs are not modified or re-signed. Public vendor extension IDs that
look like email addresses are identifiers, not user account metadata.

No new flake input, NUR overlay, cache or downloader activation script is needed.
The browser stays pinned by `flake.lock`; update nixpkgs promptly for browser
security fixes. Refresh extension versions/URLs/hashes in `addons.json` as well:
`nix flake update` alone does not update these initial-release pins. For AMO,
inspect `https://addons.mozilla.org/api/v5/addons/addon/<slug>/`, including the
publisher, GUID, permissions, license and `current_version.file` fields. Do not
reuse Chromium extension IDs. Validate XPI manifest IDs/versions after changes.

**Extension auto-updates are not disabled.** Installed extensions can update
through their normal upstream mechanisms; running profile state is therefore
not fully pinned to the initial XPI hashes. uBO also refreshes filter data.
Normal network recipients include Mozilla/add-on distribution endpoints and
filter-list hosts, plus Bitwarden/Zotero services when used. Optional cloud
accounts and extension telemetry are not configured by this module.

## Validation and first launch

```sh
nix build --no-write-lock-file --no-link .#nixosConfigurations.thinkpad.config.system.build.toplevel
nix build --no-write-lock-file --no-link .#checks.x86_64-linux.branch-needs .#checks.x86_64-linux.branch-enable
```

These build without activation. The separate existing `host-seam` check has an
unrelated thinkpad Home Manager module-count failure (two vs one allowed);
browser setup does not change the hosts or that allowlist.

After your own activation, open `about:policies` and check for errors, then
`about:addons` and confirm uBO plus the seven Brave counterparts are present.
Inspect requested permissions and disable anything you do not need. Test Vimium
C (`j/k`, `f`, `H/L`), Dark Reader, a synthetic Bitwarden login and Zotero capture
before depending on them. Installation policy, not copied Brave extension data,
provides the extensions; preferences and logins are independent.

## Primary references

- [LibreWolf features](https://librewolf.net/docs/features/)
- [LibreWolf recommended extensions](https://librewolf.net/docs/addons/)
- [Mozilla extension policy documentation](https://mozilla.github.io/policy-templates/#extensionsettings)
- [uBlock Origin](https://github.com/gorhill/uBlock)
- [Official Zotero downloads](https://www.zotero.org/download/)
- [SponsorBlock privacy](https://sponsor.ajay.app/privacy/)
- [SponsorBlock configuration defaults](https://github.com/ajayyy/SponsorBlock/blob/master/src/config.ts)

[sponsorblock]: https://addons.mozilla.org/firefox/addon/sponsorblock/
