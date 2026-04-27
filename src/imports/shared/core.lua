--- Shared consumer bootstrap: single `getCore()` entry; curated fields merged by e_core at startup.
--- Use `eCore.framework`, `eCore.config`, `eCore.i18n`, `eCore.util` (and optional `eCore.log.discord` on server).
--- Legacy globals below are optional aliases for gradual migration only.
-- luacheck: push ignore 131
eCore = exports.e_core:getCore()
FRAMEWORK = eCore.framework
eCoreConfig = eCore.config
-- luacheck: pop
