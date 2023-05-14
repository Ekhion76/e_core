local hf = eCore.helper

function createDiscordLog(webhook, botName)

    if type(webhook) ~= 'string' or hf.trim(webhook) == '' then return false end

    local self = {}
    local embedId = 0

    function self.reset()

        embedId = 0

        self._message = {
            username = botName or 'ECOBOT',
            content = '',
            tts = false,
            embeds = {}
        }
    end

    function self.putEmbed()

        embedId = #self._message.embeds + 1
        self._message.embeds[embedId] = {
            type = "rich",
            title = '',
            description = '',
            color = 52224,
            fields = {}
        }
    end

    function self.content(string)

        self._message.content = string
    end

    function self.title(string)

        self._message.embeds[embedId].title = string
    end

    function self.description(string)

        self._message.embeds[embedId].description = string
    end

    function self.color(string)

        local colors = {yellow = 16776960, green = 52224, red = 16711680}
        self._message.embeds[embedId].color = colors[string] and colors[string] or string
    end

    function self.putField(name, value, inline)

        table.insert(self._message.embeds[embedId].fields, {
            name = name,
            value = ('``` %s ```'):format(value),
            inline = inline
        })
    end

    function self.footer(string)

        self._message.embeds[embedId].footer = {
            text = string
        }
    end

    function self.send()

        PerformHttpRequest(webhook, function(statusCode, data, headers)

                if statusCode < 200 or statusCode > 299 then

                    print(statusCode .. ': E_CORE: Discord failed request...')
                end
        end, 'POST', json.encode(self._message), { ['Content-Type'] = 'application/json' })
    end

    self.reset()

    return self
end