# productivity-diary

Auto-generated productivity diary for the **Productivity Widget**.

This is a **separate** git repository (not the widget itself). The widget writes
diary content here, and this repo publishes it as a small static dashboard on
GitHub Pages.

- Remote: `https://github.com/juwpegatron/productivity-diary.git`
- Local path: `C:\Users\juwen_lie\Desktop\opencode_project\productivity-diary`

## What lives here

| Path | Writer | Purpose |
| --- | --- | --- |
| `diary/YYYY-MM-DD.md` | Productivity Widget | One Markdown entry per day |
| `diary/README.md` | Productivity Widget | Reverse-chronological index |
| `data.json` | Productivity Widget | Structured data for the dashboard |
| `index.html` | Dashboard | Static, zero-backend GitHub Pages site |
| `.github/workflows/pages.yml` | Dashboard | Deploys `index.html` to GitHub Pages |

`diary/`, `data.json` and `index.html` are **committed** (they are the published
artifact) — they are intentionally *not* ignored by `.gitignore`.

## Publishing

`publish.ps1` initialises the repo (if needed), stages everything, commits with a
timestamped message (`diary: update YYYY-MM-DD HH:MM`) and pushes to `main`:

```powershell
powershell -ExecutionPolicy Bypass -File .\publish.ps1
```

Authentication uses the **existing Git Credential Manager** — no token is stored
in this repo or passed by the script.

> **Note:** `git` is not on `PATH` on this machine. Both scripts use the full path
> `C:\Users\juwen_lie\AppData\Local\Programs\Git\cmd\git.exe`.

## Creating the repository (one time)

`create_repo.ps1` creates the **private** GitHub repo non-interactively:

1. Reads the stored GitHub token via `git credential fill` (non-interactive).
2. Calls `POST https://api.github.com/user/repos` with that token.
3. Sets the `origin` remote on success. `HTTP 422` (already exists) is treated as success.

```powershell
powershell -ExecutionPolicy Bypass -File .\create_repo.ps1
```

If no token is available, the script prints a fallback: create an **empty** repo
named `productivity-diary` once on github.com, then run `publish.ps1`.

The token is never printed, logged, or committed — it is used only in the
`Authorization` header of the API request.

## Typical workflow

1. **First time only:** run `create_repo.ps1` (or create the empty repo manually).
2. Let the widget generate diary files / `data.json`.
3. Run `publish.ps1` to push. GitHub Pages picks up the change.
