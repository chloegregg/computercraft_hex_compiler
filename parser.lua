local tokeniser = require("tokeniser")

local op_order = {
    {"op_exp"}, -- exponents first
    {"op_mul", "op_div"}, -- then multiplication and division
    {"op_add", "op_sub"}, -- then addition and subtraction
    {"op_eql", "op_grt", "op_gte", "op_lst", "op_lte", "op_neq"} -- then boolean
}

---check if a string has a substring at a location
---@param text string
---@param substr string
---@param init integer
---@return boolean
local function contains_at(text, substr, init)
    return text:sub(init, init + #substr - 1) == substr
end
---check if a string has a prefix
---@param text string
---@param prefix string
---@return boolean
local function starts_with(text, prefix)
    return contains_at(text, prefix, 1)
end

---maps a table given a function
---@param list table
---@param fun function
---@return table
local function map(list, fun)
    local mapped = {}
    for _, value in pairs(list) do
        table.insert(mapped, fun(value))
    end
    return mapped
end

---adds a list of values to a set
---@param list table
---@param values table
local function set_inserts(list, values)
    for _, value in pairs(values) do
        local found = false
        for _, existing in pairs(list) do
            if value == existing then
                found = true
                break
            end
        end
        if not found then
            table.insert(list, value)
        end
    end
end

local test_parse_expression
local test_parse_block
---attempts to parse a value from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return table names
---@return string msg
local function test_parse_value(tokens, index)
    local token = tokens[index]
    if token.type == "paren_open" then
        local ok, value_structure, value_names, msg
        ok, index, value_structure, value_names, msg = test_parse_expression(tokens, index)
        if not ok then
            return false, index, {}, {}, "failed to parse value: \n"..msg
        end
        local close_token = tokens[index]
        if close_token.type ~= "paren_close" then
            return false, index, {}, {}, "missing close parenthesis for expression"
        end
        return true, index, value_structure, value_names, "ok"
    end
    index = index + 1
    local value
    if token.type == "name" then
        value = token.value
    elseif token.type == "value_number" then
        value = tonumber(token.value)
    end
    if value ~= nil then
        return true, index, {
            type = "value",
            location = token.location,
            location_end = tokens[index].location,
            value = {
                type = token.type,
                value = value
            }
        }, {}, "ok"
    end
    return false, index, {}, {}, "not a valid value token"
end

---attempts to parse an expression from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return table names
---@return string msg
function test_parse_expression(tokens, index)
    local paren_token = tokens[index]
    local has_parens = paren_token.type == "paren_open"
    if has_parens then
        index = index + 1
    end
    local names = {}
    local value_structures = {}
    local op_tokens = {}
    while true do
        local ok, value_structure, value_names, msg
        ok, index, value_structure, value_names, msg = test_parse_value(tokens, index)
        if not ok then
            return false, index, {}, {}, "failed to parse expression value:\n"..msg
        end
        table.insert(value_structures, value_structure)
        set_inserts(names, value_names)
        local op_token = tokens[index]
        if not starts_with(op_token.type, "op_") then
            break
        end
        index = index + 1
        table.insert(op_tokens, op_token)
    end
    if has_parens then
        local close_paren_token = tokens[index]
        if close_paren_token.type ~= "paren_close" then
            return false, index, {}, {}, "missing closing parenthesis"
        end
    end
    for _, pass in pairs(op_order) do
        local op_index = 1
        while op_index <= #op_tokens do
            for _, acting_op in pairs(pass) do
                if op_tokens[op_index].type == acting_op then
                    local combined_structure = {
                        type = "expression",
                        location = value_structures[op_index].location,
                        location_end = value_structures[op_index + 1].location_end,
                        value = {
                            op = acting_op,
                            left = value_structures[op_index],
                            right = value_structures[op_index + 1]
                        }
                    }
                    table.remove(value_structures, op_index + 1)
                    value_structures[op_index] = combined_structure
                    table.remove(op_tokens, op_index)
                    op_index = op_index - 1
                    break
                end
            end
            op_index = op_index + 1
        end
    end
    if #value_structures > 1 then
        return false, index, {}, {}, "operator cascading failed, remaining values:\n"..
        table.concat(map(value_structures, function(value_structure) return value_structure.type..": "..value_structure.value end), ", ")..
        "\nremaining operators:\n"..
        table.concat(map(op_tokens, function(token) return token.type..": "..token.value end), ", ")
    end
    return true, index, value_structures[1], names, "ok"
end

---attempts to parse an assignment statement from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return table names
---@return string msg
local function test_parse_assignment_statement(tokens, index)
    local name_token = tokens[index]
    if name_token.type ~= "name" then
        return false, index, {}, {}, "variable assignment requires a name"
    end
    index = index + 1
    local op_token = tokens[index]
    if not (op_token.type == "assignment" or starts_with(op_token.type, "op_")) then
        return false, index, {}, {}, "variable assignment missing operator"
    end
    index = index + 1
    local acc_op_token
    if op_token.type ~= "assignment" then
        acc_op_token = op_token
        op_token = tokens[index]
        if op_token.type ~= "assignment" then
            return false, index, {}, {}, "non-assignment operator used as a statement"
        end
        index = index + 1
    end
    local ok, expression_structure, expression_names, msg
    ok, index, expression_structure, expression_names, msg = test_parse_expression(tokens, index)
    if not ok then
        return false, index, {}, {}, "failed to parse expression:\n"..msg
    end
    local semicolon_token = tokens[index]
    if semicolon_token.type ~= "semicolon" then
        return false, index, {}, {}, "missing semicolon"
    end
    index = index + 1
    if acc_op_token then
        expression_structure = {
            type = "expression",
            location = name_token.location,
            location_end = tokens[index].location,
            value = {
                op = acc_op_token.type,
                left = {
                    type = "value",
                    location = name_token.location,
                    location_end = acc_op_token.location,
                    value = {
                        type = "name",
                        value = name_token.value
                    }
                },
                right = expression_structure
            }
        }
    else
        set_inserts(expression_names, {name_token.value})
    end
    return true, index, {
        type = "variable_assignment",
        location = name_token.location,
        location_end = tokens[index - 1].location,
        value = {
            name = name_token.value,
            value = expression_structure
        }
    }, expression_names, "ok"
end

---attempts to parse an if statement from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return table names
---@return string msg
local function test_parse_if_statement(tokens, index)
    local conditions = {}
    local condition_names = {}
    local blocks = {}
    local final_structure = {
        type = "block",
        location = tokens[index].location,
        location_end = tokens[index].location,
        value = {
            structures = {},
            names = {}
        }
    }
    local names = {}
    while true do
        local if_token = tokens[index]
        if if_token.type ~= "statement_if" then
            return false, index, {}, {}, "if statement must start with a statement_if token"
        end
        index = index + 1
        local open_condition_token = tokens[index]
        if open_condition_token.type ~= "paren_open" then
            return false, index, {}, {}, "if statement missing open parenthesis"
        end
        index = index + 1
        local condition_ok, condition_structure, condition_names, condition_msg
        condition_ok, index, condition_structure, condition_names, condition_msg = test_parse_expression(tokens, index)
        if not condition_ok then
            return false, index, {}, {}, "failed to parse if condition:\n"..condition_msg
        end
        set_inserts(names, condition_names)
        table.insert(conditions, condition_structure)
        local close_condition_token = tokens[index]
        if close_condition_token.type ~= "paren_close" then
            return false, index, {}, {}, "if statement missing close parenthesis"
        end
        index = index + 1
        local open_block_token = tokens[index]
        if open_block_token.type ~= "block_open" then
            return false, index, {}, {}, "if statement missing open block"
        end
        index = index + 1
        local block_ok, block_structure, block_names, block_msg
        block_ok, index, block_structure, block_names, block_msg = test_parse_block(tokens, index)
        if not block_ok then
            return false, index, {}, {}, "failed to parse if block:\n"..block_msg
        end
        table.insert(blocks, block_structure)
        local close_block_token = tokens[index]
        if close_block_token.type ~= "block_close" then
            return false, index, {}, {}, "if statement missing close block"
        end
        index = index + 1
        local else_token = tokens[index]
        if else_token.type ~= "statement_else" then
            break
        end
        index = index + 1
        local open_else_block_token = tokens[index]
        if open_else_block_token.type == "block_open" then
            index = index + 1
            local else_block_ok, else_block_names, else_block_msg
            else_block_ok, index, final_structure, else_block_names, else_block_msg = test_parse_block(tokens, index)
            if not else_block_ok then
                return false, index, {}, {}, "failed to parse else block:\n"..else_block_msg
            end
            local close_else_block_token = tokens[index]
            if close_else_block_token.type ~= "block_close" then
                return false, index, {}, {}, "else statement missing close block"
            end
            index = index + 1
            break
        end
    end
    local else_chain_index = #blocks
    while else_chain_index >= 1 do
        final_structure = {
            type = "if_statement",
            location = blocks[else_chain_index].location,
            location_end = blocks[else_chain_index].location_end,
            value = {
                condition = conditions[else_chain_index],
                if_block = blocks[else_chain_index],
                else_block = final_structure
            }
        }
        else_chain_index = else_chain_index - 1
    end
    return true, index, final_structure, condition_names, "ok"
end

---attempts to parse a statement from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return table names
---@return string msg
local function test_parse_statement(tokens, index)
    local msgs = {}
    for _, statement_parser in ipairs({
        test_parse_assignment_statement,
        test_parse_if_statement
    }) do
        local ok, new_index, structure, names, msg = statement_parser(tokens, index)
        if ok then
            return true, new_index, structure, names, "ok"
        end
        table.insert(msgs, msg)
    end
    return false, index, {}, {}, "no statement matched:\n- "..table.concat(msgs, "\n- ")
end

---attempts to parse a block of code from tokens starting at the given index, stops at a closing block token
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return table names always empty
---@return string msg
function test_parse_block(tokens, index)
    local start_token = tokens[index]
    local names = {}
    local structures = {}
    while index <= #tokens do
        local token = tokens[index]
        if token.type == "block_close" then
            break
        end
        local ok, msg, sub_structure, sub_names
        ok, index, sub_structure, sub_names, msg = test_parse_statement(tokens, index)
        if not ok then
            return false, index, {}, {}, "failed to parse statement:\n"..msg
        end
        set_inserts(names, sub_names)
        table.insert(structures, sub_structure)
    end
    return true, index, {
        type = "block",
        location = start_token.location,
        location_end = tokens[index - 1].location,
        value = {
            structures = structures,
            names = names
        }
    }, {}, "ok"
end

local function parse(tokens)
    local ok, index, structure, _, msg = test_parse_block(tokens, 1)
    if not ok then
        local offending_token = tokens[index]
        return false, {}, "error parsing at "..tokeniser.location_string(offending_token.location).."\n"..msg
    end
    return true, structure, "ok"
end


return {
    parse = parse
}