local function table_to_json(tbl)
    local function serialize(o)
        if type(o) == "table" then
            local is_list = true
            for k, _ in pairs(o) do
                if type(k) ~= "number" then
                    is_list = false
                    break
                end
            end
            if is_list then
                local s = "["
                local length = 0
                for i, value in pairs(o) do
                    length = math.max(length, i)
                end
                for i = 1, length do
                    s = s .. serialize(o[i])
                    if i < length then
                        s = s .. ", "
                    end
                end
                return s.."]"
            else
                local s = "{"
                local i = 1
                local function tablelength(T)
                    local count = 0
                    for _ in pairs(T) do count = count + 1 end
                    return count
                end
                local len = tablelength(o)
                local keys = {}
                for k, v in pairs(o) do
                    table.insert(keys, k)
                end
                table.sort(keys)
                for _, k in ipairs(keys) do
                    s = s .. serialize(k) .. ': ' .. serialize(o[k])
                    if i < len then
                        s = s .. ", "
                    end
                    i = i + 1
                end
                return s.."}"
            end
        elseif type(o) == "number" then
            return tostring(o)
        elseif o == nil then
            return "null"
        else
            return '"'..tostring(o)..'"'
        end
    end
    return serialize(tbl)
end
return table_to_json