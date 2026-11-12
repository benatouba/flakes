# Privacy-focused browsers with Vim handling

Research date: **2026-11-08**. Scope: desktop Linux/NixOS; recommendations, not configuration changes. Sources below are first-party documentation/source. Upstream statements are not independent security audits.

## Shortlist

- **Best privacy-oriented mainstream alternative: LibreWolf + Vimium C**, or **Tridactyl** for a command line and deeper Vim workflow. Expect deliberate compatibility trade-offs.
- **Best native Vim interface: qutebrowser**. Prefer it for keyboard ergonomics, not because it automatically provides stronger anti-tracking or anonymity than LibreWolf/Brave.
- **Least migration friction: Brave + existing Vimium C**, provided someone owns timely updates of the local package. Its removal from this nixpkgs pin makes maintenance an explicit responsibility.
- **Conservative compatibility choice: Firefox + Tridactyl** with reviewed privacy settings. **Zen** is worth considering for its workspace UI, not as the strongest privacy or Vim-first choice. **Nyxt** is a specialist Lisp/keyboard option rather than the default recommendation.

## Privacy is not anonymity or security

**Privacy** reduces tracking, telemetry and unnecessary disclosure. **Anonymity** additionally requires resisting identification/linkability: none of these ordinary browser setups hides the source IP by default or makes logged-in activity anonymous. LibreWolf explicitly recommends **Tor Browser**, not LibreWolf routed through Tor, for that threat model. **Security** concerns exploit resistance, isolation, malicious-site protection and timely patches; disabling telemetry does not establish security superiority. LibreWolf's disabled Safe Browsing is a concrete privacy/security trade-off, not an unqualified improvement. [1][2]

## Comparison

| Browser | Vim handling and practical fit | Privacy/security considerations | Engine/update dependency |
| --- | --- | --- | --- |
| **LibreWolf + Vimium C / Tridactyl** | Both Firefox extensions are viable candidates. Vimium C preserves a familiar cross-browser workflow; Tridactyl adds modal commands, rich hints and optional external-editor integration. Test actual sites and native messaging before migrating. [3][4] | No telemetry; uBlock Origin included, strict tracking protection, cookie partitioning and Resist Fingerprinting. Cookies/site data clear on exit by default. RFP, disabled WebGL and DRM can break sites; use narrow exceptions. Safe Browsing is disabled and upstream notes incomplete support without a build-time key. [1][2] | Gecko/Firefox fork. Upstream says releases usually follow Firefox stable within **three days**; Linux updates depend on package management. Fork delay plus nixpkgs/lock delay matters. [1] |
| **qutebrowser** | The strongest fit for an integrated Vim-style browser: hints, modes, command line, configurable bindings and external editor, without depending on page-injected Vim extensions. [5][6] | Upstream states no telemetry and no unsolicited application requests without interaction. Network blocking uses the optional Rust-backed adblock library, included by this nixpkgs package; unlike uBO, its documented blocker lacks cosmetic filtering. Not a complete hardened anti-fingerprinting browser. Do not assume Chrome extension compatibility just because its engine derives from Chromium. [5][7] | **QtWebEngine**, not desktop Chrome. Upstream describes Chromium major rebases with Qt minor releases (~six months), with security fixes backported in Qt patch releases. Keep Qt updated; an older Chromium base number alone does not prove missing fixes. Avoid the obsolete QtWebKit backend. [5] |
| **Firefox + Tridactyl** | Mature mainstream browser plus a powerful Vim command layer. Tridactyl cannot run normally on protected/internal pages and AMO; native messaging is optional for advanced functionality, not required for basic navigation. [4] | Tracking/cookie protections, but upstream also documents telemetry, studies, search suggestions, sponsored New Tab content and a separately controlled daily usage ping. Review these rather than assuming stock Firefox is equivalent to LibreWolf; retaining Safe Browsing avoids LibreWolf's particular trade-off. [8] | Direct Gecko upstream: no additional browser-fork rebase delay. Mozilla's release dashboard lists Firefox **159** as current; the pin evaluates to **159.0.1**. Package/lock maintenance still controls deployed updates. [9] |
| **Zen + Vim extension** | Firefox add-ons are supported; Vimium C/Tridactyl are plausible choices, but not tested here. Its distinguishing features are vertical tabs/workspaces and split views, not native Vim modality. [10][11] | Claims telemetry/crash-report removal, but its policy explicitly acknowledges possibly missed Mozilla telemetry and necessary startup connections. Do not interpret “no data collection” as no third-party traffic or as LibreWolf-equivalent hardening. [10] | Gecko/Firefox fork. Maintainers state **0–72 hours** to follow Firefox releases; that is an upstream claim, not an SLA or a measurement of installed freshness. Not present under `zen`/`zen-browser` in this pin. [12] |
| **Nyxt** | Native vi/Emacs bindings and extensive Lisp programmability. Good for someone specifically wanting a programmable browser, not a drop-in extension-compatible replacement. [13] | Provides host-list blocking, not the same functionality as uBO. Its Lisp extensibility is not itself evidence of strong privacy defaults or anti-fingerprinting. Review the configured modes and engine security before using it for sensitive browsing. [14] | This pin's **Nyxt 3.12.0 uses WebKitGTK**, regardless of other upstream development backends. WebKitGTK publishes independent releases/security advisories; keep that dependency current. [15][16] |
| **Brave + Vimium C** | Familiar Chromium compatibility and existing Vimium C navigation; preserves the Chromium extension ecosystem. [3] | Shields provides built-in blocking. Brave also documents product analytics, crash reporting, sponsored surfaces and optional services: review/disable unnecessary ones rather than calling it telemetry-free. Safe Browsing is proxied on desktop. Leave hosted AI, Sync, Rewards and other integrations off unless separately approved. [17] | Upstream stable release notes list **1.99.55**, **Chromium 157.0.8103.39**, **Nov 5, 2026**; major releases approximately every four weeks. Local packaging must keep pace with security updates between majors too. [18] |

### Extension boundaries

Vim extensions need broad page access to implement hints/navigation; minimize installed extensions. Choose **one** Vim extension per profile to avoid conflicting bindings. Tridactyl's optional native helper can run external programs and access local configuration: configure it declaratively only if needed, not by piping an installer into a shell. Internal pages, extension stores and some document viewers remain exceptions to extension-based Vim control. [1][3][4]

**Claude in Chrome is a Chromium-extension integration, not a generic browser feature.** Anthropic's Claude Code documentation explicitly describes connecting Brave and other Chromium browsers. This does **not** imply Firefox/LibreWolf/Zen support, nor qutebrowser support through QtWebEngine, nor Nyxt support. A separate Brave profile/browser for an explicitly approved integration is a practical coexistence option; no integration is added by this research. [19]

## Verified Nix availability at this repository's pin

Inspected `flake.nix` and the root `nixpkgs` input in `flake.lock`: revision **`f9a75f41be3a74eab55d3a7679d34ad6cc0da977`**. Imported that exact nixpkgs source directly for **`x86_64-linux`**, without evaluating private flake inputs or changing the lock. This verifies evaluation/metadata, **not successful builds or runtime behavior**.

| Attribute | Evaluation result |
| --- | --- |
| `qutebrowser` | **3.7.0**, not marked broken; PyQt6-WebEngine and `adblock` included. Its evaluated `qt6Packages.qtwebengine` dependency reports **6.140.0-rc**; this unusual prerelease-labelled value warrants checking the actual runtime/backend and advisories before relying on it. [7] |
| `librewolf` | **159.0.1-1**, not marked broken. |
| `firefox` | **159.0.1**, not marked broken. |
| `nyxt` | **3.12.0**, not marked broken; `webkitgtk_4_1` evaluates to **2.54.1**. Upstream released **2.54.2 on Oct 23**: this is demonstrably behind upstream, though that release announcement does not establish an unpatched CVE. [15][16] |
| `tridactyl-native` | **0.4.1**, not marked broken; this is the helper, **not the browser extension**. |
| `zen-browser`, `zen` | Neither attribute exists. Another packaging source would need separate pinning, trust and update review; none is proposed here. |
| `brave`, `brave-origin` | Removed aliases throw an evaluation error: no committers among maintainers to unblock security issues; alias dated **2026-11-03**. A local official-binary package is a separate maintenance decision, not evidence that upstream Brave stopped releasing. [20] |

For Nix-managed browsers, upstream auto-update promises do not update immutable store packages. Keep the chosen pinned package current, rebuild the intended configuration and restart the browser; never freeze a browser on an old nixpkgs merely to recover a removed package. No package, input, service, telemetry setting or host activation was changed for this note.

## Primary sources

1. [LibreWolf FAQ: update lag, Tor, Safe Browsing, extensions, compatibility](https://librewolf.net/docs/faq/)
2. [LibreWolf default features](https://librewolf.net/docs/features/)
3. [Vimium C: supported browsers and bindings](https://github.com/gdh1995/vimium-c)
4. [Tridactyl: native messaging, features and restricted pages](https://github.com/tridactyl/tridactyl)
5. [qutebrowser FAQ: backend security, ad blocking and application privacy policy](https://qutebrowser.org/doc/faq.html)
6. [qutebrowser settings: bindings, modes and external editor](https://qutebrowser.org/doc/help/settings.html)
7. [Pinned nixpkgs qutebrowser package](https://github.com/NixOS/nixpkgs/blob/f9a75f41be3a74eab55d3a7679d34ad6cc0da977/pkgs/by-name/qu/qutebrowser/package.nix)
8. [Mozilla Firefox Privacy Notice](https://www.mozilla.org/en-US/privacy/firefox/)
9. [Mozilla release engineering: Firefox trains](https://whattrainisitnow.com/)
10. [Zen privacy policy: add-ons, startup connections and telemetry qualifications](https://zen-browser.app/privacy-policy)
11. [Zen FAQ: vertical tabs and split view](https://docs.zen-browser.app/faq)
12. [Zen security documentation: claimed Firefox update delay](https://docs.zen-browser.app/security)
13. [Nyxt official README](https://github.com/atlas-engineer/nyxt)
14. [Nyxt 3.12.0 host-list blocker source](https://github.com/atlas-engineer/nyxt/blob/3.12.0/source/mode/blocker.lisp)
15. [Pinned nixpkgs Nyxt package/backend](https://github.com/NixOS/nixpkgs/blob/f9a75f41be3a74eab55d3a7679d34ad6cc0da977/pkgs/applications/networking/browsers/nyxt/default.nix)
16. [WebKitGTK advisories](https://webkitgtk.org/security.html) and [2.54.2 release notes](https://webkitgtk.org/2026/10/23/webkitgtk2.54.2-released.html)
17. [Brave browser privacy policy](https://brave.com/privacy/browser/)
18. [Brave official release notes and release-channel cadence](https://brave.com/latest/)
19. [Anthropic: Claude Code with Chrome, including Chromium/Brave prerequisites](https://code.claude.com/docs/en/chrome)
20. [Pinned nixpkgs removed-package aliases](https://github.com/NixOS/nixpkgs/blob/f9a75f41be3a74eab55d3a7679d34ad6cc0da977/pkgs/top-level/aliases.nix#L461-L462)
