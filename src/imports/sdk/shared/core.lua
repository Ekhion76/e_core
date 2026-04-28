--- Shared consumer bootstrap: single `getCore()` entry; curated fields merged by e_core at startup.
--- Use `eCore.framework`, `eCore.config`, `eCore.i18n`, `eCore.util` (and optional `eCore.log.discord` on server).
--- Also: `eCore.ecoreVersion`, `eCore.bridgeContract` (0.1.9+) for semver + stable key list — see `docs/PUBLIC_API_HU.md` §1.
--- Legacy globals below are optional aliases for gradual migration only.
-- luacheck: push ignore 131
eCore = exports.e_core:getCore()
FRAMEWORK = eCore.framework
eCoreConfig = eCore.config
-- luacheck: pop
