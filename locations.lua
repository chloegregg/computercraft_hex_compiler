
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

return {
    get = get_location,
    tostring = location_string,
}