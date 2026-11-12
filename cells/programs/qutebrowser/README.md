# Browser alternatives

`cells/programs/qutebrowser.nix` contributes to `desktop.hmModules`;
`cells/programs/terminal-browsers.nix` contributes Lynx and ELinks to
`base.hmModules`. `import-tree` discovers both: no host imports, extra input,
or replacement of Brave's default browser, launcher, profile or extensions.

## qutebrowser

Launch `qutebrowser` from a terminal or the application launcher. Settings are
managed with Home Manager. Explicit site permissions in `autoconfig.yml` are
loaded before managed defaults; global Nix settings win after a restart.

### Adblocking and privacy

- The pinned nixpkgs package includes Python `adblock` **0.6.0**, wrapping
  **Brave's Rust engine**. `content.blocking.method = "adblock"` explicitly
  selects it, without silently falling back to weaker host-only blocking.
- EasyList and EasyPrivacy are pinned to a generated upstream commit with
  fixed hashes. A compatible serialized engine cache is built in Nix and linked
  into the profile: blocking is ready on first launch, **without runtime list
  downloads**. Both lists retain their upstream licensing/attribution in the
  fetched source: <https://easylist.to/pages/licence.html>.
- **Do not use `:adblock-update`**: the cache is intentionally Nix-owned and
  read-only. To update, select a reviewed `gh-pages` commit from
  <https://github.com/easylist/easylist>, prefetch its `easylist.txt` and
  `easyprivacy.txt` with `nix store prefetch-file --json URL`, and update
  `listRevision` and both hashes in `../qutebrowser.nix`. Rebuild, then restart
  qutebrowser. `nix flake update` alone does not update these separate pins.
- Third-party cookies/storage, autoplay, DNS prefetch, hyperlink pings,
  notifications and geolocation are blocked/disabled. WebRTC is restricted to
  the default public interface, **not completely disabled or anonymized**.
  JavaScript remains enabled for compatibility. No sandbox/TLS weakening flags.
- Dark pages use QtWebEngine's native dark mode, not Dark Reader. Images are
  left uninverted. `,d` toggles dark rendering for this session.
- Local focus-mode CSS hides YouTube's home feed, recommendations, comments,
  Shorts shelves and end-screen suggestions. `,f` toggles it until a full reload.
  This is a limited Undistracted alternative, not its cross-site feature set.
- This is **not uBlock Origin or all of Brave Shields**: qutebrowser's Rust
  integration only blocks network requests, not generic cosmetic filters or
  the full extension functionality. Focus CSS is separate and YouTube-only.

**Engine update caution:** the tested pin reports qutebrowser 3.7.0, Qt 6.12.0,
QtWebEngine 6.140, Chromium base 140.0.7339.225, and security patches through
152.0.7977.83 (plus distribution patches). An old base number alone does not
prove missing fixes, but this does **not establish parity with current Brave**.
Review QtWebEngine advisories/patches before relying on it for sensitive browsing;
keep the lock and engine current rather than suppressing update warnings.

### SponsorBlock

The pinned, non-loader [SB.js](https://github.com/mchangrh/sb.js) userscript is
LGPL-3.0-or-later and is listed in SponsorBlock's
[third-party ports](https://github.com/ajayyy/SponsorBlock/wiki/3rd-Party-Ports).
It is restricted to `https://www.youtube.com/*`, sponsor-category skipping only,
and has skip reporting disabled. The local modifications also allow injection on
the homepage for subsequent YouTube single-page navigation. No CDN loader,
segment submission, voting, account, or persistent userscript storage is added.

**External recipient:** lookups send the YouTube video ID and your IP to
`https://sponsor.ajay.app`; normal request metadata may also be visible. This
integration was explicitly approved. API responses stay in page memory, not a
new local history/database. It is less precise than the full extension, with no
player-bar UI. CORS, site CSP, API failures or YouTube changes can break it.
Remote retention, hosting location and transfers are governed by SponsorBlock,
not configured by this repo; see its [privacy policy](https://sponsor.ajay.app/privacy/)
and [API/data license](https://github.com/ajayyy/SponsorBlock/wiki/Database-and-API-License).
Disable it by removing `sponsorblock` from `greasemonkey` and rebuilding; no
extra local SponsorBlock data needs deleting. No optional skip-count telemetry.

### Existing Brave extensions

| Brave feature | qutebrowser equivalent / boundary |
| --- | --- |
| Bitwarden | `,p` opens existing `rofi-rbw` with Wayland typing support when the personal branch enables rbw. No second login/configuration workflow. |
| Vimium C | Native modal navigation, including internal pages. |
| Dark Reader | Native dark rendering; `,d` toggles it. |
| React Developer Tools | `:devtools` provides ordinary web devtools, **not React's component inspector**. Use Brave for the extension. |
| Zotero Connector | No compatible connector installed; use Brave for reliable capture into your existing Zotero setup. |
| SponsorBlock | Limited SB.js userscript described above. |
| ColorZilla | No compatible extension installed; ordinary devtools CSS inspection is available, not full ColorZilla. |
| Undistracted | Local YouTube-only focus rules; `,f`. |
| Claude-in-Chrome | Not compatible. `,b` opens the current URL in Brave; any automation still requires its normal approval. |

**Password safety:** focus the correct input, press Escape then `,p`, explicitly
select the matching entry, and inspect the URL and focused form before typing.
The picker uses OS-level typing, not origin-checked extension autofill. Wrong
window/form focus can expose credentials. Never invoke it on an untrusted site.
No vault entry names, URLs, accounts or credentials are added to Nix. The
upstream `qute-bitwarden` script is deliberately not installed: it warns that
passwords may appear in qutebrowser's debug log. Existing Super+B still works.

### Navigation cheat sheet

Commands and single-letter shortcuts work in **normal mode**. Press **Escape**
to leave an input and return to it. Sequences such as `gg` mean successive keys.

| Keys | Action |
| --- | --- |
| `o` / `O` | Open URL/search here / in a new tab; Tab completes. |
| `f` / `F` | Show link hints; type a hint to open here / in a new tab. |
| `h j k l` | Scroll left / down / up / right. |
| `Ctrl+d` / `Ctrl+u` | Half-page down / up. |
| `gg` / `G` | Top / bottom. |
| `H` / `L` | Back / forward. |
| `J` / `K` | Next / previous tab. |
| `d` / `u` | Close tab / undo close. |
| `r` / `R` | Reload / reload bypassing cache. |
| `/` then `n` / `N` | Find text, next / previous match. |
| `gi` / `i` | Focus an input / enter insert mode. |
| `yy` / `pp` / `Pp` | Copy URL / open clipboard here / in a new tab. |
| `m` / `b` / `B` | Save quickmark / open quickmark here / in a new tab. |
| `M` / `gb` | Bookmark current page / open a bookmark. |
| `:` | Command prompt; `:help`, `:devtools`, `:version`, `:quit`. |
| `Ctrl+v` / `Shift+Escape` | Enter / leave passthrough mode (useful for web apps). |
| `,p` | Explicit Bitwarden picker (see safety notes). |
| `,b` | Open current URL in Brave without changing the default browser. |
| `,a` | Temporarily toggle adblocking for the current hostname only. |
| `,d` / `,f` | Session dark-mode toggle / YouTube focus-mode toggle. |

Use `:session-save NAME` and `:session-load NAME` for explicit tab sessions;
automatic session restore is off. `:open -p URL` opens a private window.
For a broken login, allow third-party cookies only on that site with
`:set -u example.org content.cookies.accept all`; review exceptions rather than
turning protections off globally. Never include sensitive real URLs in Git.

The `persist` branch conditionally retains `.config/qutebrowser` and
`.local/share/qutebrowser`: cookies, history, site storage, explicit sessions,
bookmarks, quickmarks and per-site permissions remain local across reboots.
HTTP cache is not persisted. There is no qutebrowser sync or new backup service;
existing backups that include `/persist` may also contain this profile. No new
automatic expiry is imposed: use browser data-clearing controls as needed.
Persistence is not encryption; treat profile files and backups as private.

## Lynx and ELinks

Run `lynx https://example.org` or `elinks https://example.org` in a terminal.
Both are additional commands, not MIME handlers or a changed `$BROWSER`.
Both pinned builds have TLS support; keep certificate verification enabled.
Lynx does not run JavaScript and this ELinks build has no JavaScript engine,
so they are useful for text documentation, not a replacement for modern apps
or Brave extensions. They do not inherit qutebrowser's adblock engine or vault.

- **Lynx:** `g` opens a URL, arrows select links, Right/Enter follows, Left
  goes back, `/` searches, `n` repeats, `h` shows help, `q` quits.
- **ELinks:** `g` opens a URL, arrows select links, Enter follows, Left goes
  back, `/` searches, `n` repeats, Escape opens menus, `q` quits.

No terminal-browser cookie/history/bookmark directories are added to `/persist`.
They retain upstream defaults and the host's existing home persistence behavior.
Use ordinary browsing only; do not send credentials to an unverified URL.

## Validation before activation

```sh
nix build --no-write-lock-file --no-link .#nixosConfigurations.thinkpad.config.system.build.toplevel
nix build --no-write-lock-file --no-link .#checks.x86_64-linux.host-seam .#checks.x86_64-linux.branch-needs .#checks.x86_64-linux.branch-enable
```

Building is not activation. On first launch check `:version` for `adblock` and
the backend, exercise hints/dark mode, check sponsor skipping on a public video,
and test the password picker only with synthetic credentials. Synthetic tests
are not proof of current YouTube/SponsorBlock compatibility.

Implementation validation passed: the ThinkPad system build, `branch-needs`
and `branch-enable`, serialized-engine blocking/allowing tests, mock
SponsorBlock SPA/skip/no-telemetry tests, local HTML dumps in both terminal
browsers, and an isolated offscreen qutebrowser startup with the generated
configuration (software rendering for the test only, sandbox unchanged).
The existing `host-seam` check fails because the ThinkPad already contributes
two host-local Home Manager modules while its allowlist permits one; these
browser features add no host-local modules and do not change that allowlist.

Upstream references: [FAQ](https://qutebrowser.org/doc/faq.html),
[settings](https://qutebrowser.org/doc/help/settings.html),
[quick start](https://qutebrowser.org/doc/quickstart.html).
