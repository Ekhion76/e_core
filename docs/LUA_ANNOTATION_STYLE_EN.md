# Lua Annotation Style Guide (English)

This file defines the annotation standard for Lua code in `e_core`.
Use this format for new code and when refactoring existing modules.

## Goals

- Keep function contracts clear for maintainers and consumers.
- Improve LuaLS IntelliSense and diagnostics quality.
- Keep docs and code comments consistent in one language: **English**.

## Scope

- **Required:** public API functions (exports, bridge-facing methods, shared helpers used by other modules).
- **Recommended:** non-trivial internal helpers.
- **Optional:** short private utility functions that are obvious from code.

## Core Rules

1. Write annotations and function comments in **English only**.
2. Put annotation blocks **directly above** the target function.
3. Use concise, behavior-focused first sentence.
4. Always document:
   - `@param` for each parameter
   - `@return` for each returned value
5. Prefer explicit union types over vague `any` or generic `table`.
6. If a table has known fields, describe the shape in the comment.
7. Keep comments synchronized with behavior when refactoring.

## Annotation Template

```lua
--- One-line purpose in present tense.
--- @param input string Description.
--- @param opts table|nil Optional settings.
--- @return boolean ok True on success, false otherwise.
--- @return string|nil err Error code when not ok.
local function example(input, opts)
```

## Naming and Type Style

- Use LuaLS-compatible type expressions:
  - `string`, `number`, `boolean`, `table`, `function`, `nil`
  - union: `string|number`
  - optional-like style: `table|nil`
- Prefer semantic return names in text: `ok`, `result`, `reason`, `err`.
- Keep parameter descriptions short and concrete.

## Table Shape Documentation

When a function accepts an options table, document expected keys in prose:

```lua
--- Build a Discord log object.
--- @param webhook string Valid Discord webhook URL.
--- @param botName string|nil Optional bot display name.
--- @param opts table|nil Optional settings: { defaultColor=number|string, avatar_url=string, onError=function }.
--- @return table|false logger Logger instance or false if webhook is invalid.
function createDiscordLog(webhook, botName, opts)
```

For list-style tables, document item shape explicitly:

```lua
--- Append fields to current embed in order.
--- @param fields table Array-like list: { { name=string, value=string|number|boolean, inline=boolean|nil, codeBlock=boolean|nil }, ... }.
--- @return table self
function DiscordLog:appendFields(fields)
```

## Return Contract Rules

- If function can fail without throw, return explicit status pair:
  - `boolean ok, <result or error>`
- If function returns `false` as valid data, avoid ambiguous checks in caller and document it clearly.
- Keep return order stable across modules (`ok` first where applicable).

## Method Annotations (`:` syntax)

For class-like tables and methods:

```lua
--- Send current Discord payload.
--- @param doneCb function|nil Callback: function(ok, statusCode, responseBody).
--- @return nil
function DiscordLog:send(doneCb)
```

If method is chainable, mention it:

```lua
--- @return table self
```

## Comment Language Policy

- Allowed: English in annotations and technical comments.
- Not allowed: mixed-language annotation blocks in same file.
- Domain constants, error codes, and user-facing localized text can remain unchanged.

## Example: Good vs Weak

Good:

```lua
--- Remove multiple inventory items with validation.
--- @param xPlayer table Framework player object.
--- @param items table Array-like list: { { name=string, amount=number }, ... }.
--- @return boolean ok
--- @return string reason eCoreErr code when not ok.
```

Weak:

```lua
--- item remove
--- @param a table
--- @param b table
```

## Minimum Checklist (Per Function)

- [ ] English one-line description
- [ ] All params documented with meaningful types
- [ ] Return values documented in correct order
- [ ] Failure contract documented (`ok/reason` or equivalent)
- [ ] Optional fields and defaults explained where relevant

## Rollout Strategy

1. Start with `imports/`, `src/runtime/exports/client.lua`, `src/runtime/exports/server.lua`.
2. Continue with `bridge/global/*` and active override modules.
3. Touch-up annotations opportunistically during refactors/bugfixes.

## CI / Review Guidance

- Reviewer verifies annotation correctness, not only presence.
- Do not accept PRs adding public functions without annotation block.
- Keep this guide aligned with `docs/LUA_LS_AND_CI_HU.md`.

## See also (not a “backlog” list)

- **`docs/LUA_ANNOTATION_MAINTENANCE_EN.md`** – post–0.0.56 **policy** (ongoing rules, A–C review order). It is **not** a todo or missing-block count; the old misleading filename was removed.
