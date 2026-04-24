-- luacheck: push ignore 131
--- Discord webhook üzenet-építő (szerver). `createDiscordLog(url, botNév [, opts])` → építő objektum;
--- érvénytelen URL esetén `false`. A mezők hossza Discord limithez igazítva (csonkolás).
local hf = eCore.helper

local FIELD_NAME_MAX = 256
local FIELD_VALUE_MAX = 1024
local EMBED_DESC_MAX = 4096
local EMBED_TITLE_MAX = 256
local CONTENT_MAX = 2000
local USERNAME_MAX = 80

local NAMED_COLORS = {
    yellow = 16776960,
    green = 52224,
    red = 16711680,
    orange = 16753920,
    blue = 3447003,
    purple = 10181046,
    grey = 9807270,
    gray = 9807270,
    teal = 5301186,
    white = 16777215,
    black = 2302756,
}

local function trimStr(s)
    if not hf or not hf.trim then
        return type(s) == 'string' and s:gsub('^%s+', ''):gsub('%s+$', '') or ''
    end
    return hf.trim(s)
end

local function isValidWebhookUrl(url)
    if type(url) ~= 'string' then
        return false
    end
    local u = trimStr(url)
    if #u < 40 or u:sub(1, 8) ~= 'https://' then
        return false
    end
    return u:find('/api/webhooks/', 1, true) ~= nil
end

local function clampStr(s, maxLen)
    if s == nil then
        return ''
    end
    s = tostring(s)
    if #s <= maxLen then
        return s
    end
    if maxLen < 2 then
        return s:sub(1, maxLen)
    end
    return s:sub(1, maxLen - 1) .. '…'
end

--- Szín: név (`green`), decimális int, vagy `#RRGGBB` / `RRGGBB`.
local function resolveColor(c)
    if c == nil then
        return NAMED_COLORS.green
    end
    if type(c) == 'number' and c == c then
        return math.floor(c) % 16777216
    end
    if type(c) == 'string' then
        local named = NAMED_COLORS[c]
        if named then
            return named
        end
        local hex = c:match('^#?([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])$')
        if hex then
            return tonumber(hex, 16)
        end
    end
    return NAMED_COLORS.green
end

--- @param webhook string
--- @param botName string|nil alap felhasználónév
--- @param opts table|nil { defaultColor=number, onError=function(code,body), avatar_url=string }
--- @return table|false
function createDiscordLog(webhook, botName, opts)
    opts = type(opts) == 'table' and opts or {}

    if not isValidWebhookUrl(webhook) then
        if cLog then
            cLog('[e_core][DiscordLog]', 'invalid webhook URL (expected https://…/api/webhooks/…)', 1)
        end
        return false
    end

    webhook = trimStr(webhook)

    local defaultColor = resolveColor(opts.defaultColor)

    local self = {}
    local embedId = 0

    local function appendEmbed()
        embedId = #self._message.embeds + 1
        self._message.embeds[embedId] = {
            type = 'rich',
            title = '',
            description = '',
            color = defaultColor,
            fields = {},
        }
    end

    --- Belső: első embed-mező művelet előtt garantált aktív embed.
    local function ensureEmbed()
        if embedId < 1 or not self._message.embeds[embedId] then
            appendEmbed()
        end
    end

    function self.reset()
        embedId = 0
        self._message = {
            username = type(botName) == 'string' and clampStr(trimStr(botName), USERNAME_MAX) or 'ECOBOT',
            content = '',
            tts = false,
            embeds = {},
        }
        if type(opts.avatar_url) == 'string' and trimStr(opts.avatar_url) ~= '' then
            self._message.avatar_url = trimStr(opts.avatar_url)
        else
            self._message.avatar_url = nil
        end
    end

    function self.putEmbed()
        appendEmbed()
    end

    function self.username(name)
        if type(name) ~= 'string' then
            return
        end
        self._message.username = clampStr(trimStr(name), USERNAME_MAX)
    end

    function self.avatarUrl(url)
        if type(url) ~= 'string' or trimStr(url) == '' then
            self._message.avatar_url = nil
            return
        end
        self._message.avatar_url = trimStr(url)
    end

    function self.content(str)
        self._message.content = clampStr(str, CONTENT_MAX)
    end

    function self.title(str)
        ensureEmbed()
        self._message.embeds[embedId].title = clampStr(str, EMBED_TITLE_MAX)
    end

    function self.description(str)
        ensureEmbed()
        self._message.embeds[embedId].description = clampStr(str, EMBED_DESC_MAX)
    end

    --- Embed URL (pl. cikk / napló link).
    function self.url(str)
        ensureEmbed()
        if type(str) == 'string' and trimStr(str) ~= '' then
            self._message.embeds[embedId].url = trimStr(str)
        else
            self._message.embeds[embedId].url = nil
        end
    end

    function self.color(c)
        ensureEmbed()
        self._message.embeds[embedId].color = resolveColor(c)
    end

    --- @param name string
    --- @param value string|number|boolean
    --- @param inline boolean|nil
    --- @param codeBlock boolean|nil alap: true (visszafelé kompatibilis ``` blokk)
    function self.putField(name, value, inline, codeBlock)
        ensureEmbed()
        local useCode = codeBlock ~= false
        local valStr = clampStr(value, FIELD_VALUE_MAX)
        if useCode then
            valStr = ('``` %s ```'):format(valStr)
        end
        table.insert(self._message.embeds[embedId].fields, {
            name = clampStr(name, FIELD_NAME_MAX),
            value = valStr,
            inline = not not inline,
        })
    end

    function self.footer(str)
        ensureEmbed()
        self._message.embeds[embedId].footer = {
            text = clampStr(str, 2048),
        }
    end

    function self.timestamp(unixTime)
        ensureEmbed()
        local t = tonumber(unixTime) or os.time()
        self._message.embeds[embedId].timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ', math.floor(t))
    end

    function self.author(name, url, iconUrl)
        ensureEmbed()
        self._message.embeds[embedId].author = {
            name = clampStr(name, 256),
            url = (type(url) == 'string' and trimStr(url) ~= '') and trimStr(url) or nil,
            icon_url = (type(iconUrl) == 'string' and trimStr(iconUrl) ~= '') and trimStr(iconUrl) or nil,
        }
    end

    function self.thumbnail(url)
        ensureEmbed()
        if type(url) == 'string' and trimStr(url) ~= '' then
            self._message.embeds[embedId].thumbnail = { url = trimStr(url) }
        else
            self._message.embeds[embedId].thumbnail = nil
        end
    end

    function self.image(url)
        ensureEmbed()
        if type(url) == 'string' and trimStr(url) ~= '' then
            self._message.embeds[embedId].image = { url = trimStr(url) }
        else
            self._message.embeds[embedId].image = nil
        end
    end

    --- Üres tartalom esetén nem küld (spam / 400 elkerülése).
    --- @param doneCb function|nil function(ok, statusCode, responseBody)
    function self.send(doneCb)
        local hasContent = trimStr(self._message.content or '') ~= ''
        local hasEmbeds = #self._message.embeds > 0
        if not hasContent and not hasEmbeds then
            if cLog then
                cLog('[e_core][DiscordLog]', 'send skipped: empty content and no embeds', 2)
            end
            if doneCb then
                doneCb(false, 0, 'skipped_empty')
            end
            return
        end

        local payload = json.encode(self._message)
        PerformHttpRequest(webhook, function(statusCode, data, _headers)
            local ok = type(statusCode) == 'number' and statusCode >= 200 and statusCode <= 299
            if not ok then
                local snippet = type(data) == 'string' and clampStr(data, 500) or tostring(data)
                if cLog then
                    cLog(
                        ('[e_core][DiscordLog] HTTP %s'):format(tostring(statusCode)),
                        snippet,
                        1
                    )
                end
                if type(opts.onError) == 'function' then
                    opts.onError(statusCode, data)
                end
            end
            if doneCb then
                doneCb(ok, statusCode, data)
            end
        end, 'POST', payload, { ['Content-Type'] = 'application/json' })
    end

    self.reset()

    return self
end

-- luacheck: pop
