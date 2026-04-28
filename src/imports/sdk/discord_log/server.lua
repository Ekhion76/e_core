local M = {}
local hf = lib.require('src/imports/sdk/helper_base/shared')

local function isValidWebhookUrl(url)
    if type(url) ~= 'string' then
        return false
    end
    local u = hf.trim(url)
    return u:sub(1, 8) == 'https://' and u:find('/api/webhooks/', 1, true) ~= nil
end

local function resolveColor(c)
    local map = { red = 16711680, yellow = 16776960, green = 52224, blue = 3447003, orange = 16753920 }
    if type(c) == 'number' then
        return math.floor(c) % 16777216
    end
    if type(c) == 'string' then
        return map[c] or map.green
    end
    return map.green
end

local DiscordLog = {}
DiscordLog.__index = DiscordLog

function DiscordLog:embed(opts)
    opts = type(opts) == 'table' and opts or {}
    local embed = {
        type = 'rich',
        title = tostring(opts.title or ''),
        description = tostring(opts.description or ''),
        color = resolveColor(opts.color),
        fields = opts.fields or {},
    }
    if opts.timestamp then
        embed.timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    end
    table.insert(self._message.embeds, embed)
    return self
end

function DiscordLog:send(doneCb)
    local payload = json.encode(self._message)
    PerformHttpRequest(self._webhook, function(statusCode, data)
        local ok = type(statusCode) == 'number' and statusCode >= 200 and statusCode <= 299
        if doneCb then
            doneCb(ok, statusCode, data)
        end
    end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end

--- @param webhook string
--- @param botName string|nil
--- @param opts table|nil
--- @return table|false
function M.createDiscordLog(webhook, botName, opts)
    opts = type(opts) == 'table' and opts or {}
    if not isValidWebhookUrl(webhook) then
        return false
    end
    local normalizedWebhook = hf.trim(webhook)
    local normalizedBotName = type(botName) == 'string' and hf.trim(botName) or ''
    local self = setmetatable({}, DiscordLog)
    self._webhook = normalizedWebhook
    self._message = {
        username = normalizedBotName ~= '' and normalizedBotName or 'ECOBOT',
        content = '',
        embeds = {},
    }
    return self
end

return M
