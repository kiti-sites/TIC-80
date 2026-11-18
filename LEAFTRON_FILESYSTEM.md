# Leaftron Filesystem

## 1. Architecture

Leaftron inherits TIC-80's filesystem abstraction (`tic_fs`, implemented in
`src/studio/fs.c`). It exposes a virtual current-working-directory (`fs->work`)
relative to a physical root directory (`fs->dir`). Commands such as `dir`,
`cd`, `save`, `load`, `add` and `get` operate on this virtual tree, while the
actual bytes are stored in the host filesystem (or its web equivalent).

There is no separate in-memory virtual filesystem for file contents: directories
and files are created on the backing store. The virtual part is only the
current-directory string (`fs->work`) and navigation logic.

## 2. Storage backend

- Desktop (Windows/macOS/Linux): native OS filesystem. The root is the
  per-application data folder (see below). Standard `fopen`/`mkdir`/`dirent`
  calls are used (`src/studio/fs.c`).
- Web (Emscripten): Emscripten's `IDBFS` is mounted onto the application data
  directory (`FS.mount(IDBFS, {}, dir)` in `src/system/sokol/main.c`), backed
  by the browser's IndexedDB. A sync (`FS.syncfs`) persists changes.
- Android: native app folder (`make_folder`), as provided by the platform.
- Embedded (baremetalpi/3DS/Switch/Tanmatsu): platform-specific storage (SD
  card / fatfs), where applicable.

No server-side storage is used by the console filesystem. The `surf` browser
fetches carts over HTTP, but saved files stay local.

## 3. Real location of data

Root directory (`fs->dir`) is built from `TIC_PACKAGE`/`TIC_NAME`
(`com.leafole.Leaftron` / `Leaftron`) in `getAppFolder()`:

- Windows: `%APPDATA%\com.leafole.Leaftron\Leaftron\`
- macOS: `~/Library/Application Support/com.leafole.Leaftron/Leaftron/`
- Linux: `$XDG_DATA_HOME/com.leafole.Leaftron/Leaftron/` or
  `~/.local/share/com.leafole.Leaftron/Leaftron/`
- Web: `/com.leafole.Leaftron/Leaftron/` inside the Emscripten virtual FS,
  persisted to IndexedDB under that mount point.
- Android: the app's data folder.

The console also creates `TIC_LOCAL` and `TIC_LOCAL_VERSION` subdirectories
for internal data (`src/studio/studio.c`).

## 4. Persistence

- Desktop: files persist on disk between runs.
- Web: IDBFS persists to IndexedDB; data survives browser restarts, subject
  to browser storage quotas and eviction policies. `syncfs` must complete for
  writes to be flushed.
- No server persistence.

## 5. Platform differences

Desktop uses the real OS filesystem; web uses IDBFS over IndexedDB; mobile/
embedded use their platform folders. The virtual navigation (`fs->work`) behaves
the same on all platforms; only the backing store differs.

## 6. Navigation commands

- `dir`: prints `fs->work` (current virtual directory).
- `cd <dir>`: appends `dir` to `fs->work`, normalising separators; `cd ..`
  goes up one level (`tic_fs_changedir` / `tic_fs_dirback`).
- `surf`: opens the SURF browser (web catalogue), which fetches carts over HTTP
  into the current directory; it does not change `fs->work` itself.

The strange "leafole.dev" directory seen in the console is the web root's first
path component as exposed by Emscripten's IDBFS mount; it is not a server
folder.

## 7. Backup / export

- Desktop: copy the data folder listed above.
- Web: use the browser's "Export" / DevTools IndexedDB inspection, or the
  console `get <file>` command to download individual carts.
- `add` imports a file into the current directory.

If any detail cannot be confirmed from the code, it is noted above as
platform-dependent.