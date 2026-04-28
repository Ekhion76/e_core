local M = {}

local function trim(s)
    if type(s) ~= 'string' then
        return ''
    end
    return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function isValidId(id)
    return trim(id) ~= ''
end

local function createInstance()
    local self = {
        enabled = false,
        handlerId = nil,
        allowAll = false,
        allowedById = {},
        registeredById = {},
    }

    local function canSync(id)
        if self.allowAll then
            return true
        end
        return self.allowedById[id] == true
    end

    local function onSync(payload)
        if type(payload) ~= 'table' then
            return
        end
        local id = trim(payload.id)
        if not isValidId(id) or not canSync(id) then
            return
        end
        local data = self.registeredById[id]
        if type(data) ~= 'table' or type(data.onSync) ~= 'function' then
            return
        end
        data.onSync(payload)
    end

    function self.enable()
        if self.enabled then
            return true
        end
        self.handlerId = AddEventHandler('e_core:hud:sync:position', onSync)
        self.enabled = true
        return true
    end

    function self.disable()
        if self.handlerId then
            RemoveEventHandler(self.handlerId)
            self.handlerId = nil
        end
        self.enabled = false
    end

    function self.allow(id)
        if id == nil then
            self.allowAll = true
            return true
        end
        if not isValidId(id) then
            return false
        end
        self.allowedById[trim(id)] = true
        return true
    end

    function self.deny(id)
        if id == nil then
            self.allowAll = false
            self.allowedById = {}
            return true
        end
        if not isValidId(id) then
            return false
        end
        self.allowedById[trim(id)] = nil
        return true
    end

    function self.registerElement(id, data)
        if not isValidId(id) or type(data) ~= 'table' then
            return false
        end
        self.registeredById[trim(id)] = data
        return true
    end

    function self.unregisterElement(id)
        if not isValidId(id) then
            return false
        end
        self.registeredById[trim(id)] = nil
        return true
    end

    return self
end

function M.new()
    return createInstance()
end

return M
