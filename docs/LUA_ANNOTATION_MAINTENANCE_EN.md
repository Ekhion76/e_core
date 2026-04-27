# Lua annotation – maintenance policy (e_core)

**What this is:** the **ongoing rules** and **review priority** for LuaLS annotations after the **0.0.56** full-repo sweep (see `changelog.md`).

**What this is not:** a **todo / deficit / “backlog” list**. There is **no** standing batch of “missing annotation blocks” to burn down. The former filename `LUA_ANNOTATION_BACKLOG_EN.md` was **misleading** and was **removed**—do not look for a “backlog” file for Lua annotations in this repo.

**Canonical pair:** style = [`docs/LUA_ANNOTATION_STYLE_EN.md`](LUA_ANNOTATION_STYLE_EN.md) · policy (this file) · Cursor rule = [`.cursor/rules/lua-annotation-style.mdc`](../.cursor/rules/lua-annotation-style.mdc).

---

## 1. Baseline (closed)

- Older notes about **“337 missing blocks”** are **obsolete**.
- **`changelog.md` → 0.0.56:** full-repo annotation sweep — **451/451** functions annotated, **0** missing blocks (at the time of that audit).
- **Do not** treat any Lua annotation document as a **todo count** for missing blocks.

---

## 2. Ongoing rules (always)

| Trigger | Action |
|--------|--------|
| New or refactored **public** Lua API (exports, bridge-facing methods, shared helpers used across modules) | Add LuaLS blocks per **`docs/LUA_ANNOTATION_STYLE_EN.md`** and **`.cursor/rules/lua-annotation-style.mdc`**. |
| Internal-only change with no contract impact | Annotations follow the same style where they help; no separate “deficit list” or backlog file entry. |

---

## 3. Optional: re-count after large moves

After **new files** or a **large `src/` relocation**, a one-off **annotation coverage recount** is **optional** (not a standing process). Record the result in a **PR description** or **commit message**, not necessarily here.

---

## 4. Priority paths (contract review order)

When touching annotations for a big change, prefer checking these areas first — **not** because they are unfinished, but because they define the **public surface** or high-risk integration.

**Paths are under `src/`** unless noted. **`overrides/`** is at repo root (inventory / core overrides).

### A — Public contract

- `src/server/exports.lua`
- `src/client/exports.lua`
- `src/bridge/main.lua`
- `src/imports/server/discord_log.lua`
- `src/imports/shared/utils.lua`

### B — Bridge + domain core

- `src/bridge/global/shared.lua`
- `src/bridge/global/server.lua`
- `src/bridge/esx/server.lua`
- `src/bridge/qb/server.lua`
- `src/server/meta.lua`
- `src/server/labor.lua`
- `src/server/db.lua`
- `src/server/professions.lua`

### C — Overrides + NUI / admin bridges

- `overrides/**/*.lua`
- `src/client/nui_admin_bridge.lua`
- `src/client/nui_diagnostics_bridge.lua`
- `src/server/nui_admin_bridge.lua`
- `src/server/nui_diagnostics_bridge.lua`

---

## 5. Notes

- **`types/fivem_ox_stubs.lua`:** intentionally minimal; full semantic docs are low value. Do not hold it to public-contract strictness.
- All annotation **wording** must follow **`docs/LUA_ANNOTATION_STYLE_EN.md`** (English).
