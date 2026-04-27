--- Client-side e_core NUI shell lifecycle (independent of `ClientMetaStore` / meta sync).
--- Gates `SendNUIMessage` until the web UI reports initialization via the `nuiReady` NUI callback.

local shellReady = false

eCoreNui = {}

--- Returns whether the configured `ui_page` shell has signaled it can receive NUI messages.
--- @return boolean
function eCoreNui.isReady()
    return shellReady
end

--- Marks the NUI shell as ready (call from `RegisterNUICallback('nuiReady', …)` in `client/main.lua`).
--- @return nil
function eCoreNui.markShellReady()
    shellReady = true
end
