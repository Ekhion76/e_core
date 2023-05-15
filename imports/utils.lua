--function print_r(data)
--
--    print(json.encode(data, { indent = true }))
--end

function print_r(t)
    local print_r_cache = {}
    local function sub_print_r(t, indent)
        if (print_r_cache[tostring(t)]) then
            print(indent .. "*" .. tostring(t))
        else
            print_r_cache[tostring(t)] = true
            if (type(t) == "table") then
                for pos, val in pairs(t) do
                    if (type(val) == "table") then
                        print(indent .. "[" .. pos .. "] => " .. tostring(t) .. " {")
                        sub_print_r(val, indent .. string.rep(" ", string.len(pos) + 8))
                        print(indent .. string.rep(" ", string.len(pos) + 6) .. "}")
                    else
                        print(indent .. "[" .. pos .. "] => " .. tostring(val))
                    end
                end
            else
                print(indent .. tostring(t))
            end
        end
    end

    sub_print_r(t, "  ")
end

function cLog(k, v, level) -- console log for debug

    if not Config.debugLevel or Config.debugLevel < 1 then
        return
    end

    if level and level > Config.debugLevel then
        return
    end

    local v_type = type(v)

    if v_type == 'table' or v_type == 'function' then

        print('^3DEBUG', k, '^4')
        print_r(v)
        print('^7')
    else

        if v_type == 'boolean' then

            v = v and 'true' or 'false'
        end

        if v == nil then

            v = 'nil'
        end

        print('^3DEBUG', k, '->^4', v, '^7')
    end
end


