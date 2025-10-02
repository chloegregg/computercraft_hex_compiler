
local token_patterns = {
    {name = "statement_if", pattern = "if%s"},
    {name = "statement_else", pattern = "else%s"},
    {name = "statement_for", pattern = "for%s"},
    {name = "statement_while", pattern = "while%s"},
    {name = "statement_function", pattern = "function%s"},
    {name = "value_number", pattern = "(%d*%.%d+)"},
    {name = "value_number", pattern = "(%d+)"},
    {name = "paren_open", pattern = "%("},
    {name = "paren_close", pattern = "%)"},
    {name = "block_open", pattern = "{"},
    {name = "block_close", pattern = "}"},
    {name = "index_open", pattern = "%["},
    {name = "index_close", pattern = "%]"},
    {name = "increment", pattern = "%+%+"},
    {name = "decrement", pattern = "%-%-"},
    {name = "op_add", pattern = "%+"},
    {name = "op_sub", pattern = "%-"},
    {name = "op_mul", pattern = "%*"},
    {name = "op_div", pattern = "%/"},
    {name = "op_eql", pattern = "=="},
    {name = "op_neq", pattern = "!="},
    {name = "op_gte", pattern = ">="},
    {name = "op_grt", pattern = ">"},
    {name = "op_lte", pattern = "<="},
    {name = "op_lst", pattern = "<"},
    {name = "op_and", pattern = "(&&)"},
    {name = "op_and", pattern = "(and)"},
    {name = "op_or", pattern = "(||)"},
    {name = "op_or", pattern = "(or)"},
    {name = "op_xor", pattern = "(^^)"},
    {name = "op_xor", pattern = "(xor)"},
    {name = "assignment", pattern = "="},
    {name = "semicolon", pattern = ";"},
    {name = "name", pattern = "(%a%w*)"},
    {name = "_whitespace", pattern = "%s+"},
    {name = "_comment_line", pattern = "//[^\n]*"},
    {name = "_comment_block", pattern = "/%*.-%*/"},
}

---finds the 2d location of an index
---@param code string
---@param index integer
---@return table location
local function get_location(code, index)
    local line = 0
    local last_index, current_index = 0, 0
    while current_index <= index do
        local next = code:find("\n", current_index + 1, true)
        if next then
            last_index = current_index
            current_index = next
            line = line + 1
        else
            last_index = current_index
            line = line + 1
            break
        end
    end
    return {
        line = line,
        column = index - last_index
    }
end

---converts a location to a string
---@param location table
---@return string
local function location_string(location)
    return tostring(location.line)..":"..tostring(location.column)
end

---tests a pattern on code
---@param code string
---@param pattern string
---@param init integer
---@return boolean
---@return integer
---@return string
---@return string
local function test_pattern(code, pattern, init)
    local start_index, end_index, match = code:find(pattern, init)
    if start_index == nil or start_index > init then
        return false, init, "", ""
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
    local location = get_location(code, index)
    for _, token_type in ipairs(token_patterns) do
        local ok, raw, match
        ok, index, raw, match = test_pattern(code, token_type.pattern, index)
        if ok then
            return true, index, {
                type = token_type.name,
                value = match,
                raw = raw,
                index = index,
                location = location
            }, "ok"
        end
    end
    return false, 0, {}, "no token matched at "..location_string(location)
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
    tokenise = tokenise,
    location_string = location_string
}