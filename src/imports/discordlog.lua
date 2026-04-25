-- luacheck: push ignore 131
--- Discord webhook message builder (server-side). `createDiscordLog(url, botName [, opts])` -> builder object;
--- returns `false` for invalid webhook URL. String fields are clamped to Discord limits.
local hf = eCore.helper

local FIELD_NAME_MAX = 256
local FIELD_VALUE_MAX = 1024
local EMBED_DESC_MAX = 4096
local EMBED_TITLE_MAX = 256
local CONTENT_MAX = 2000
local USERNAME_MAX = 80

local NAMED_COLORS = {
    yellow = 16776960,
    green  = 52224,
    red    = 16711680,
    orange = 16753920,
    blue   = 3447003,
    purple = 10181046,
    grey   = 9807270,
    gray   = 9807270,
    teal   = 5301186,
    white  = 16777215,
    black  = 2302756,
}

--- Trims leading and trailing whitespace.
--- Uses `hf.trim` when available, otherwise fallback Lua pattern trimming.
--- @param s any Input value.
--- @return string trimmed Normalized string value.
local function trimStr(s)
    if not hf or not hf.trim then
        return type(s) == 'string' and s:gsub('^%s+', ''):gsub('%s+$', '') or ''
    end
    return hf.trim(s)
end

--- Validates expected Discord webhook URL shape.
--- @param url any Candidate webhook URL.
--- @return boolean isValid True when URL looks like a Discord webhook endpoint.
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

--- Converts any value to string and clamps length to Discord field limits.
--- @param s any Input value.
--- @param maxLen number Maximum allowed length.
--- @return string clamped Clamped string output.
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

--- Color resolver: named color (`green`), decimal int, or `#RRGGBB` / `RRGGBB`.
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

-- ---------------------------------------------------------------------------
local DiscordLog = {}
DiscordLog.__index = DiscordLog

--- @param webhook string
--- @param botName string|nil Default webhook username.
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

    local obj = setmetatable({}, DiscordLog)
    obj:_init(trimStr(webhook), botName, opts)
    return obj
end

--- Initializes internal object state.
--- @param webhook string Validated and trimmed webhook URL.
--- @param botName string|nil Default username.
--- @param opts table Runtime options.
--- @return nil
function DiscordLog:_init(webhook, botName, opts)
    self._webhook = webhook
    self._botName = botName
    self._opts = opts
    self._defaultColor = resolveColor(opts.defaultColor)
    self._embedId = 0
    self:reset()
end

-- ---------------------------------------------------------------------------
-- Private helpers

--- Appends an empty rich embed and sets it as active embed.
--- @return nil
function DiscordLog:_appendEmbed()
    self._embedId = #self._message.embeds + 1
    self._message.embeds[self._embedId] = {
        type = 'rich',
        title = '',
        description = '',
        color = self._defaultColor,
        fields = {},
    }
end

--- Ensures an active embed exists before embed field mutations.
function DiscordLog:_ensureEmbed()
    if self._embedId < 1 or not self._message.embeds[self._embedId] then
        self:_appendEmbed()
    end
end

-- ---------------------------------------------------------------------------
-- Public API

--- Resets current message payload to a clean state.
--- @return nil
function DiscordLog:reset()
    self._embedId = 0
    self._message = {
        username = type(self._botName) == 'string' and clampStr(trimStr(self._botName), USERNAME_MAX) or 'ECOBOT',
        content = '',
        tts = false,
        embeds = {},
    }
    local av = self._opts.avatar_url
    self._message.avatar_url = (type(av) == 'string' and trimStr(av) ~= '') and trimStr(av) or nil
end

--- Creates and selects a new embed.
--- @return nil
function DiscordLog:putEmbed()
    self:_appendEmbed()
end

--- Overrides webhook username for current message.
--- @param name string New username.
--- @return nil
function DiscordLog:username(name)
    if type(name) ~= 'string' then
        return
    end
    self._message.username = clampStr(trimStr(name), USERNAME_MAX)
end

--- Sets or clears avatar URL for current message.
--- @param url string|nil Avatar URL (empty clears avatar).
--- @return nil
function DiscordLog:avatarUrl(url)
    if type(url) ~= 'string' or trimStr(url) == '' then
        self._message.avatar_url = nil
        return
    end
    self._message.avatar_url = trimStr(url)
end

--- Sets top-level message content.
--- @param str any Content text.
--- @return nil
function DiscordLog:content(str)
    self._message.content = clampStr(str, CONTENT_MAX)
end

--- Sets active embed title.
--- @param str any Embed title text.
--- @return nil
function DiscordLog:title(str)
    self:_ensureEmbed()
    self._message.embeds[self._embedId].title = clampStr(str, EMBED_TITLE_MAX)
end

--- Sets active embed description.
--- @param str any Embed description text.
--- @return nil
function DiscordLog:description(str)
    self:_ensureEmbed()
    self._message.embeds[self._embedId].description = clampStr(str, EMBED_DESC_MAX)
end

--- Embed URL (for example: article, audit, or dashboard link).
--- @param str string|nil Embed URL.
--- @return nil
function DiscordLog:url(str)
    self:_ensureEmbed()
    if type(str) == 'string' and trimStr(str) ~= '' then
        self._message.embeds[self._embedId].url = trimStr(str)
    else
        self._message.embeds[self._embedId].url = nil
    end
end

--- Sets embed color (name, decimal, or hex string).
--- @param c string|number|nil Color token.
--- @return nil
function DiscordLog:color(c)
    self:_ensureEmbed()
    self._message.embeds[self._embedId].color = resolveColor(c)
end

--- @param name string
--- @param value string|number|boolean
--- @param inline boolean|nil
--- @param codeBlock boolean|nil Defaults to true for backward-compatible codeblock formatting.
function DiscordLog:putField(name, value, inline, codeBlock)
    self:_ensureEmbed()
    local useCode = codeBlock ~= false
    local valStr = clampStr(value, FIELD_VALUE_MAX)
    if useCode then
        valStr = ('``` %s ```'):format(valStr)
    end
    table.insert(self._message.embeds[self._embedId].fields, {
        name = clampStr(name, FIELD_NAME_MAX),
        value = valStr,
        inline = not not inline,
    })
end

--- Sets footer text on active embed.
--- @param str any Footer text.
--- @return nil
function DiscordLog:footer(str)
    self:_ensureEmbed()
    self._message.embeds[self._embedId].footer = {
        text = clampStr(str, 2048),
    }
end

--- Sets ISO timestamp on active embed.
--- @param unixTime number|nil Unix timestamp. Defaults to current time.
--- @return nil
function DiscordLog:timestamp(unixTime)
    self:_ensureEmbed()
    local t = tonumber(unixTime) or os.time()
    self._message.embeds[self._embedId].timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ', math.floor(t))
end

--- Sets embed author object.
--- @param name any Author display name.
--- @param url string|nil Optional author URL.
--- @param iconUrl string|nil Optional author icon URL.
--- @return nil
function DiscordLog:author(name, url, iconUrl)
    self:_ensureEmbed()
    self._message.embeds[self._embedId].author = {
        name = clampStr(name, 256),
        url = (type(url) == 'string' and trimStr(url) ~= '') and trimStr(url) or nil,
        icon_url = (type(iconUrl) == 'string' and trimStr(iconUrl) ~= '') and trimStr(iconUrl) or nil,
    }
end

--- Sets or clears embed thumbnail.
--- @param url string|nil Thumbnail URL.
--- @return nil
function DiscordLog:thumbnail(url)
    self:_ensureEmbed()
    if type(url) == 'string' and trimStr(url) ~= '' then
        self._message.embeds[self._embedId].thumbnail = { url = trimStr(url) }
    else
        self._message.embeds[self._embedId].thumbnail = nil
    end
end

--- Sets or clears embed image.
--- @param url string|nil Image URL.
--- @return nil
function DiscordLog:image(url)
    self:_ensureEmbed()
    if type(url) == 'string' and trimStr(url) ~= '' then
        self._message.embeds[self._embedId].image = { url = trimStr(url) }
    else
        self._message.embeds[self._embedId].image = nil
    end
end

--- Clears all fields from the current embed (useful before rebuilding content).
function DiscordLog:clearFields()
    self:_ensureEmbed()
    self._message.embeds[self._embedId].fields = {}
    return self
end

--- Array-based field list: `{ { name, value, inline?, codeBlock? }, ... }` (order preserved).
function DiscordLog:appendFields(fields)
    if type(fields) ~= 'table' then
        return self
    end
    for i = 1, #fields do
        local f = fields[i]
        if type(f) == 'table' and f.name ~= nil then
            self:putField(f.name, f.value, f.inline, f.codeBlock)
        end
    end
    return self
end

--- Fills one embed from a table payload. **newEmbed:** `true` -> append a new embed;
--- otherwise `_ensureEmbed()` is used (current/first embed flow).
--- Supported top-level fields: **content**, **username** / **avatarUrl**; embed fields:
--- **color**, **title**, **description**, **url**, **footer**, **timestamp** (`true` = now),
--- **author** `{ name, url?, icon_url? }`, **thumbnail**, **image**, **fields** (see `appendFields`).
function DiscordLog:embed(opts)
    if type(opts) ~= 'table' then
        return self
    end
    if opts.newEmbed then
        self:putEmbed()
    else
        self:_ensureEmbed()
    end
    if type(opts.username) == 'string' then
        self:username(opts.username)
    end
    if opts.avatarUrl ~= nil then
        self:avatarUrl(opts.avatarUrl)
    end
    if opts.content ~= nil then
        self:content(opts.content)
    end
    if opts.color ~= nil then
        self:color(opts.color)
    end
    if opts.title ~= nil then
        self:title(opts.title)
    end
    if opts.description ~= nil then
        self:description(opts.description)
    end
    if opts.url ~= nil then
        self:url(opts.url)
    end
    if opts.footer ~= nil then
        self:footer(opts.footer)
    end
    if opts.timestamp then
        if opts.timestamp == true then
            self:timestamp()
        else
            self:timestamp(opts.timestamp)
        end
    end
    if type(opts.author) == 'table' and opts.author.name ~= nil then
        self:author(opts.author.name, opts.author.url, opts.author.icon_url)
    end
    if opts.thumbnail ~= nil then
        self:thumbnail(opts.thumbnail)
    end
    if opts.image ~= nil then
        self:image(opts.image)
    end
    if type(opts.fields) == 'table' then
        self:appendFields(opts.fields)
    end
    return self
end

local ALERT_LEVEL_COLOR = {
    error = 'red',
    warning = 'yellow',
    info = 'blue',
    ok = 'green',
}

--- Quick status embed: color is derived from **level** (`error` / `warning` / `info` / `ok`),
--- with optional **content**, **title**, **description**, **footer**, **fields**.
--- Does not open a new embed by default (compatible with "green base -> red error" flow in `eco_crafting`).
function DiscordLog:alert(opts)
    if type(opts) ~= 'table' then
        return self
    end
    self:_ensureEmbed()
    local lvl = opts.level or 'error'
    self:color(ALERT_LEVEL_COLOR[lvl] or ALERT_LEVEL_COLOR.error)
    if opts.content ~= nil then
        self:content(opts.content)
    end
    if opts.title ~= nil then
        self:title(opts.title)
    end
    if opts.description ~= nil then
        self:description(opts.description)
    end
    if opts.footer ~= nil then
        self:footer(opts.footer)
    end
    if type(opts.fields) == 'table' then
        self:appendFields(opts.fields)
    end
    return self
end

--- Skips send when both content and embeds are empty (spam / HTTP 400 protection).
--- @param doneCb function|nil function(ok, statusCode, responseBody)
function DiscordLog:send(doneCb)
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
    local opts = self._opts
    PerformHttpRequest(self._webhook, function(statusCode, data, _headers)
        local ok = type(statusCode) == 'number' and statusCode >= 200 and statusCode <= 299
        if not ok then
            local snippet = type(data) == 'string' and clampStr(data, 500) or tostring(data)
            if cLog then
                cLog(('[e_core][DiscordLog] HTTP %s'):format(tostring(statusCode)), snippet, 1)
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

-- luacheck: pop
