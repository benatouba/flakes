# Terminal mail workflow

The `personal` branch configures NeoMutt and aerc against the same local Maildirs.
mbsync synchronizes them with the existing providers. NeoMutt sends through the
msmtp queue; aerc currently sends directly through SMTP.

## Attach files

In NeoMutt's compose screen, **`A`** opens Yazi in `~/documents`. Navigate with
`h/j/k/l`, select multiple files with Space, and press Enter to return the selection.
Quit Yazi with `q` to cancel. Lowercase **`a`** keeps the manual filename prompt,
prefilled with `~/documents/`. Both clients save attachments to `~/documents` by default.

The picker preserves spaces and punctuation in filenames and passes selections
as literal attachment names, not commands. Its temporary selection file is private
and is removed on exit. Directories and control-character filenames are rejected.

The picker uses a dedicated Vim-style keymap and retains Yazi's appearance/settings.
Its selection transport is NUL-separated so newline filenames cannot turn into
additional attachments. aerc keeps its existing manual attachment-path entry:
its picker API interprets filenames as glob patterns rather than literal paths.

## Search across accounts

notmuch indexes the existing Maildirs locally. It does not move mail or create
server-side labels. The index contains searchable message metadata and text and
lives under `~/mail/.notmuch`, alongside the already-persistent mail storage.
The index directory is created with a private umask. It is derived data: it can be
rebuilt from the Maildirs, but custom notmuch tags need a separate export if you
choose to use them.

Indexing runs after successful scheduled syncs, after IMAP arrival callbacks, and
on the existing five-minute address-book timer. **`mail-index`** refreshes it
manually without contacting a server. The first refresh can take longer.

NeoMutt has four `Search · …` virtual mailboxes:

- **Unread** — unread mail across accounts.
- **Flagged** — flagged messages across accounts.
- **Attachments** — messages containing attachments, not a full-text index of PDFs.
- **All mail** — indexed mail, subject to notmuch's deleted/spam exclusions.

Press **`gU`** for Unread, **`gF`** for Flagged, or **`\`** for a free-form notmuch
query. For example:

```text
from:someone@example.org AND tag:attachment
subject:invoice AND date:2026-01-01..
folder:account-name/Inbox
```

Standard read/flag state follows Maildir flags. Arbitrary notmuch tags remain
local. Replies from cross-account views select the corresponding account's
sendmail command and Sent folder based on the From identity. When composing a
new message from a search, check the From identity as usual.

## Invitations and the local calendar

In NeoMutt, open the attachment list with `l` while reading a message, select an
ICS attachment, and press **`I`** to import it. In aerc, select the calendar MIME
part with `J`/`K` and press **`I`**. khal shows its normal confirmation prompts,
including confirmation before updating an existing UID.

The default ICS opener remains a read-only preview. Import is a separate action:
it does **not** send an acceptance reply to the organizer.

Use **`ikhal`** for the interactive calendar or **`khal list`** for an agenda.
You can also import a saved invitation:

```sh
mail-calendar-import invitation.ics
```

The local calendar stores standard `.ics` files in
`~/.local/state/calendars/local`, covered by the existing `.local/state`
persistence. These files may contain titles, dates, attendees and locations;
they stay on this machine, have private permissions, and are removed through
calendar editing rather than an automatic retention rule. Persistence is not a
separate backup policy.

This vdir layout can later be connected with vdirsyncer to a Google or CalDAV
calendar. That requires a provider choice, approved private metadata and runtime
credentials. No calendar synchronization or remote account has been enabled.

`mail-calendar-import --batch` is available for deliberate unattended imports;
it also authorizes replacing an existing event with the same UID.

## HTML mail

Plain text is preferred when the message provides it. HTML-only messages are
rendered automatically in NeoMutt; both clients now use the same clean w3m-based
text rendering. Rendering uses aerc's network-blocking wrapper and does not fetch
remote images. Opening an HTML attachment in the browser remains an explicit
action through the attachment list.

Three renderings were compared with synthetic headings, paragraphs, a table,
links and a tracking image:

| Variant | Useful properties |
| --- | --- |
| `lynx` | Readable headings and text; reference lists and link numbers suppressed. |
| `w3m` (default) | Compact text and table layout; keeps link labels without long tracking URLs. |
| `aerc` | The existing w3m-based aerc filter, including displayed link targets. |

For a local HTML file, compare them yourself without opening a browser:

```sh
mail-html --compare message.html | less
mail-html --renderer lynx message.html | less
```

Use **`U`** in NeoMutt to choose URLs from the original message; the HTML renderer
does not rewrite link targets. In urlscan, `/` searches URLs and context, `c`
toggles context, `s`/`S` shorten one/all displayed URLs, `l` or Enter opens a link,
and `q` returns directly to NeoMutt.

## Checks

```sh
nix build --no-link .#checks.x86_64-linux.mail-tools
```

This runs Python type checks plus offline tests for picker cancellation and
literal filenames, actual NeoMutt attachment creation, notmuch queries over
synthetic Maildirs, khal import into a temporary calendar, and HTML readability.
The same check runs from the repository's pre-commit hook for affected files.
