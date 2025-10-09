local constants = require("constants")
local locations = require("locations")

---tests a pattern on code
---@param code string
---@param pattern string
---@param init integer
---@return boolean matched
---@return integer new_index
---@return string raw
---@return string|nil match
local function test_pattern(code, pattern, init)
    local start_index, end_index, match = code:find(pattern, init)
    if start_index == nil or start_index > init then
        return false, init, "", ""
    end
    if match then
        return true, start_index + #match, match, match
    end
    return true, end_index + 1, code:sub(start_index, end_index), match
end

---gets the next token that matches at the positions
---@param code string
---@param index integer
---@return boolean
---@return integer
---@return table
---@return string
local function get_next_token(code, index)
    local location = locations.get(code, index)
    for _, token_type in ipairs(constants.token_patterns) do
        local ok, raw, match
        ok, index, raw, match = test_pattern(code, token_type.pattern, index)
        if ok then
            local location_end = locations.get(code, index - 1)
            return true, index + (token_type.padding or 0), {
                type = token_type.name,
                value = match,
                raw = raw,
                index = index,
                location = location,
                location_end = location_end
            }, "ok"
        end
    end
    return false, 0, {}, "no token matched at "..locations.tostring(location)
end

---tokenises the code
---@param code string
---@return boolean ok
---@return table tokens
---@return string msg
local function tokenise(code)
    local tokens = {}
    local index = 1
    while index <= #code do
        local ok, token, msg
        ok, index, token, msg = get_next_token(code, index)
        if not ok then
            return false, {}, "tokenisation error:\n"..msg
        end
        if token.type:sub(1, 1) ~= "_" then
            table.insert(tokens, token)
        end
    end
    return true, tokens, "ok"
end

return {
    tokenise = tokenise
}