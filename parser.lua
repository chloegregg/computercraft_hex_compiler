local tokeniser = require("tokeniser")
local table_to_json = require("table_to_json")

local op_order = {
    {"op_exp"}, -- exponents first
    {"op_mul", "op_div"}, -- then multiplication and division
    {"op_add", "op_sub"}, -- then addition and subtraction,
    {"op_eql", "op_grt", "op_gte", "op_lst", "op_lte", "op_neq"}, -- then boolean conditions
    {"op_and", "op_or", "op_xor"}, -- then boolean combinations
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

---adds a list of values to a set
---@param tokens table
---@param index integer
local function get_token(tokens, index)
    if index <= #tokens and index >= 1 then
        return tokens[index]
    end
    return {
        type = "eof",
        location = {
            line = -1,
            column = -1
        },
        location_end = {
            line = -1,
            column = -1
        },
        value = {}
    }
end

local test_parse_expression
local test_parse_block
local test_parse_function

local property_parsers = {
    ---attempts to parse a vector component property from tokens starting at the given index
    ---@param tokens table
    ---@param index integer
    ---@return boolean ok
    ---@return integer index
    ---@return table structure
    ---@return string msg
    prop_vector_component = function(tokens, index)
        local property_token = get_token(tokens, index)
        if property_token.type ~= "prop_vector_component" then
            return false, index, {}, "incorrect property parser for "..property_token.type
        end
        index = index + 1
        return true, index, {
            type = "property_access",
            location = property_token.location,
            location_end = property_token.location_end,
            value = {
                type = "vector_access",
                value = {
                    component = property_token.value
                }
            }
        }, "ok"
    end
}

---attempts to parse an index from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
local function test_parse_index(tokens, index)
    local open_bracket_token = get_token(tokens, index)
    if open_bracket_token.type ~= "index_open" then
        return false, index, {}, "missing opening bracket for index"
    end
    index = index + 1
    local value_ok, value_structure, value_msg
    value_ok, index, value_structure, value_msg = test_parse_expression(tokens, index)
    if not value_ok then
        return false, index, {}, "failed to parse index expression:\n"..value_msg
    end
    local close_bracket_token = get_token(tokens, index)
    if close_bracket_token.type ~= "index_close" then
        return false, index, {}, "missing closing bracket for index"
    end
    index = index + 1
    return true, index, value_structure, "ok"
end

---attempts to parse a function call from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
local function test_parse_call(tokens, index)
    local open_bracket_token = get_token(tokens, index)
    if open_bracket_token.type ~= "paren_open" then
        return false, index, {}, "missing opening bracket for function call at "..tokeniser.location_string(open_bracket_token.location)
    end
    index = index + 1
    local args = {}
    local no_arg_token = get_token(tokens, index)
    if no_arg_token.type ~= "paren_close" then
        while true do
            local value_ok, value_structure, value_msg
            value_ok, index, value_structure, value_msg = test_parse_expression(tokens, index)
            if not value_ok then
                return false, index, {}, "failed to parse function call argument "..(#args + 1)..":\n"..value_msg
            end
            table.insert(args, value_structure)
            local comma_token = get_token(tokens, index)
            if comma_token.type == "paren_close" then
                break
            end
            if comma_token.type ~= "comma" then
                return false, index, {}, "expected comma for function call argument "..(#args + 1).." at "..tokeniser.location_string(comma_token.location)
            end
            index = index + 1
        end
    end
    index = index + 1
    return true, index, args, "ok"
end

---attempts to parse a value from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
local function test_parse_value(tokens, index)
    local token = get_token(tokens, index)
    if token.type == "paren_open" then
        local value_ok, value_structure, value_msg
        value_ok, index, value_structure, value_msg = test_parse_expression(tokens, index)
        if not value_ok then
            return false, index, {}, "failed to parse value: \n"..value_msg
        end
        local close_token = get_token(tokens, index)
        if close_token.type ~= "paren_close" then
            return false, index, {}, "missing close parenthesis for expression"
        end
        return true, index, value_structure, "ok"
    end
    index = index + 1
    local value
    if token.type == "value_null" then
        value = {}
    elseif token.type == "value_bool" then
        value = {
            value = token.value == "true"
        }
    elseif token.type == "value_number" then
        value = {
            value = tonumber(token.value)
        }
    elseif token.type == "name" then
        value = {
            value = token.value
        }
    elseif token.type == "index_open" then
        local list_value_structures = {}
        local empty_list_token = get_token(tokens, index)
        if empty_list_token.type ~= "index_close" then
            while true do
                local value_ok, value_structure, value_msg
                value_ok, index, value_structure, value_msg = test_parse_expression(tokens, index)
                if not value_ok then
                    return false, index, {}, "failed to parse list value for index"..(#list_value_structures + 1)..": \n"..value_msg
                end
                table.insert(list_value_structures, value_structure)
                local comma_token = get_token(tokens, index)
                if comma_token.type == "index_close" then
                    break
                end
                if comma_token.type ~= "comma" then
                    return false, index, {}, "expected comma for index"..(#list_value_structures + 1).." at "..tokeniser.location_string(comma_token.location)
                end
                index = index + 1
            end
        end
        index = index + 1
        value = {
            type = "list",
            value = list_value_structures
        }
    elseif token.type == "block_open" then
        local vector_value_structures = {}
        for _, axis in ipairs({"x", "y", "z"}) do
            local value_ok, value_structure, value_msg
            value_ok, index, value_structure, value_msg = test_parse_expression(tokens, index)
            if not value_ok then
                return false, index, {}, "failed to parse vector value for "..axis.." component: \n"..value_msg
            end
            vector_value_structures[axis] = value_structure
            if axis ~= "z" then
                local comma_token = get_token(tokens, index)
                if comma_token.type ~= "comma" then
                    return false, index, {}, "expected comma after "..axis.." component at "..tokeniser.location_string(comma_token.location)
                end
                index = index + 1
            end
        end
        local close_vector_token = get_token(tokens, index)
        if close_vector_token.type ~= "block_close" then
            return false, index, {}, "expected closing block token for vector"
        end
        index = index + 1
        value = {
            type = "vector",
            value = vector_value_structures
        }
    elseif token.type == "statement_function" then
        local function_ok, function_structure, function_msg
        function_ok, index, function_structure, function_msg = test_parse_function(tokens, index)
        if not function_ok then
            return false, index, {}, "failed to parse function:\n"..function_msg
        end
        local function_structures = function_structure.body.value.structures
        local has_return = false
        if function_structures then
            local last_structure = function_structures[#function_structures]
            if last_structure.type == "return_statement" then
                has_return = true
                last_structure.value.tail = true
            end
        end
        if not has_return then
            table.insert(function_structures, {
                type = "return_statement",
                location = function_structure.location_end,
                location_end = function_structure.location_end,
                value = {
                    tail = true,
                    value = {
                        type = "value",
                        location = function_structure.location_end,
                        location_end = function_structure.location_end,
                        value = {
                            type = "value_null"
                        }
                    }
                }
            })
        end
        value = {
            type = "function",
            value = function_structure
        }
    end
    if value == nil then
        return false, index, {}, "not a valid value token at "..tokeniser.location_string(token.location)
    end
    if value.type == nil then
        value.type = token.type
    end
    local structure = {
        type = "value",
        location = token.location,
        location_end = tokens[index - 1].location_end,
        value = value
    }
    while true do
        local access_modifier_token = get_token(tokens, index)
        if access_modifier_token.type == "index_open" then
            local index_ok, index_structure, index_msg
            index_ok, index, index_structure, index_msg = test_parse_index(tokens, index)
            if not index_ok then
                return false, index, {}, "failed to parse index:\n"..index_msg
            end
            structure = {
                type = "index",
                location = structure.location,
                location_end = index_structure.location_end,
                value = {
                    value = structure,
                    index = index_structure
                }
            }
        elseif access_modifier_token.type == "paren_open" then
            local call_ok, call_structure, call_msg
            call_ok, index, call_structure, call_msg = test_parse_call(tokens, index)
            if not call_ok then
                return false, index, {}, "failed to parse function call:\n"..call_msg
            end
            structure = {
                type = "call",
                location = structure.location,
                location_end = call_structure.location_end,
                value = {
                    value = structure,
                    args = call_structure
                }
            }
        elseif property_parsers[access_modifier_token.type] then
            local prop_parser = property_parsers[access_modifier_token.type]
            local property_ok, property_structure, property_msg
            property_ok, index, property_structure, property_msg = prop_parser(tokens, index)
            if not property_ok then
                return false, index, {}, "failed to parse property "..access_modifier_token.type..":\n"..property_msg
            end
            structure = {
                type = "property",
                location = structure.location,
                location_end = tokens[index - 1].location_end,
                value = {
                    value = structure,
                    property = property_structure
                }
            }
        else
            break
        end
    end
    return true, index, structure, "ok"
end

---attempts to parse an expression from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
function test_parse_expression(tokens, index)
    local paren_token = get_token(tokens, index)
    local has_parens = paren_token.type == "paren_open"
    if has_parens then
        index = index + 1
    end
    local value_structures = {}
    local op_tokens = {}
    while true do
        local ok, value_structure, msg
        ok, index, value_structure, msg = test_parse_value(tokens, index)
        if not ok then
            return false, index, {}, "failed to parse expression value:\n"..msg
        end
        table.insert(value_structures, value_structure)
        local op_token = get_token(tokens, index)
        if not starts_with(op_token.type, "op_") then
            break
        end
        index = index + 1
        table.insert(op_tokens, op_token)
    end
    if has_parens then
        local close_paren_token = get_token(tokens, index)
        if close_paren_token.type ~= "paren_close" then
            return false, index, {}, "missing closing parenthesis"
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
        return false, index, {}, "operator cascading failed, remaining values:\n"..
        table.concat(map(value_structures, function(value_structure) return value_structure.type..": "..value_structure.value end), ", ")..
        "\nremaining operators:\n"..
        table.concat(map(op_tokens, function(token) return token.type..": "..token.value end), ", ")
    end
    return true, index, value_structures[1], "ok"
end

---attempts to parse an assignment name from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
local function test_parse_assignment_name(tokens, index)
    local name_token = get_token(tokens, index)
    if name_token.type ~= "name" then
        return false, index, {}, "variable assignment requires a name"
    end
    index = index + 1
    local indicies = {}
    while true do
        local open_bracket_token = get_token(tokens, index)
        if open_bracket_token.type ~= "index_open" then
            break
        end
        local index_ok, index_structure, index_msg
        index_ok, index, index_structure, index_msg = test_parse_index(tokens, index)
        if not index_ok then
            return false, index, {}, "failed to parse variable assignment index:\n"..index_msg
        end
        table.insert(indicies, index_structure)
    end
    return true, index, {
        name = name_token.value,
        indicies = indicies
    }, "ok"
end

---attempts to parse an assignment statement from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
local function test_parse_assignment_statement(tokens, index)
    local start_token = get_token(tokens, index)
    local name_ok, name_structure, name_msg
    name_ok, index, name_structure, name_msg = test_parse_assignment_name(tokens, index)
    if not name_ok then
        return false, index, {}, "failed to parse variable name:\n"..name_msg
    end
    local op_token = get_token(tokens, index)
    if not (op_token.type == "assignment" or starts_with(op_token.type, "op_")) then
        return false, index, {}, "variable assignment missing operator"
    end
    index = index + 1
    local acc_op_token
    if op_token.type ~= "assignment" then
        acc_op_token = op_token
        op_token = get_token(tokens, index)
        if op_token.type ~= "assignment" then
            return false, index, {}, "non-assignment operator used as a statement"
        end
        index = index + 1
    end
    local expression_ok, expression_structure, expression_msg
    expression_ok, index, expression_structure, expression_msg = test_parse_expression(tokens, index)
    if not expression_ok then
        return false, index, {}, "failed to parse expression:\n"..expression_msg
    end
    local semicolon_token = get_token(tokens, index)
    if semicolon_token.type ~= "semicolon" then
        return false, index, {}, "missing semicolon"
    end
    index = index + 1
    if acc_op_token then
        expression_structure = {
            type = "expression",
            location = start_token.location,
            location_end = semicolon_token.location_end,
            value = {
                op = acc_op_token.type,
                left = {
                    type = "value",
                    location = start_token.location,
                    location_end = start_token.location_end,
                    value = {
                        type = "name",
                        value = name_structure.name
                    }
                },
                right = expression_structure
            }
        }
    end
    return true, index, {
        type = "variable_assignment",
        location = start_token.location,
        location_end = semicolon_token.location_end,
        value = {
            variable = name_structure,
            is_declared = true,
            value = expression_structure
        }
    }, "ok"
end

---attempts to parse a variable increment/decrement statement from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
local function test_parse_modifier_statement(tokens, index)
    local start_token = get_token(tokens, index)
    local name_ok, name_structure, name_msg
    name_ok, index, name_structure, name_msg = test_parse_assignment_name(tokens, index)
    if not name_ok then
        return false, index, {}, "failed to parse variable name:\n"..name_msg
    end
    local modifier
    local modifier_token = get_token(tokens, index)
    if modifier_token.type == "increment" then
        modifier = "op_add"
    end
    if modifier_token.type == "decrement" then
        modifier = "op_sub"
    end
    if not modifier then
        return false, index, {}, "failed to parse modifier"
    end
    index = index + 1
    local semicolon_token = get_token(tokens, index)
    if semicolon_token.type ~= "semicolon" then
        return false, index, {}, "missing semicolon"
    end
    index = index + 1
    return true, index, {
        type = "variable_assignment",
        location = start_token.location,
        location_end = semicolon_token.location_end,
        value = {
            variable = name_structure,
            is_declared = true,
            value = {
            type = "expression",
            location = start_token.location,
            location_end = semicolon_token.location_end,
            value = {
                op = modifier,
                left = {
                    type = "value",
                    location = start_token.location,
                    location_end = start_token.location_end,
                    value = {
                        type = "name",
                        value = name_structure.name
                    }
                },
                right = {
                    type = "value",
                    location = semicolon_token.location,
                    location_end = semicolon_token.location_end,
                    value = {
                        type = "value_number",
                        value = 1
                    }
                }
            }
        }
        }
    }, "ok"
end

---attempts to parse a declaration statement from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
local function test_parse_declaration_statement(tokens, index)
    local declare_token = get_token(tokens, index)
    if declare_token.type ~= "statement_declare" then
        return false, index, {}, "declaration requires a declare token"
    end
    index = index + 1
    local name_token = get_token(tokens, index)
    if name_token.type ~= "name" then
        return false, index, {}, "declaration requires a variable name"
    end
    local assignment_ok, new_index, assignment_structure, _ = test_parse_assignment_statement(tokens, index)
    if assignment_ok then
        if #assignment_structure.value.variable.indicies > 0 then
            return false, index, {}, "cannot declare a variable with indicies"
        end
        assignment_structure.value.is_declared = false
        return true, new_index, assignment_structure, "ok"
    end
    index = index + 1
    local semicolon_token = get_token(tokens, index)
    if semicolon_token.type ~= "semicolon" then
        return false, index, {}, "missing semicolon"
    end
    index = index + 1
    return true, index, {
        type = "variable_assignment",
        location = declare_token.location,
        location_end = semicolon_token.location_end,
        value = {
            variable = {
                name = name_token.value,
                indicies = {}
            },
            indicies = {},
            is_declared = false,
            value = {
                type = "value",
                location = name_token.location_end,
                location_end = name_token.location_end,
                value = {
                    type = "value_null"
                }
            }
        }
    }, "ok"
end

---attempts to parse a bare value from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
local function test_parse_bare_value(tokens, index)
    local start_token = get_token(tokens, index)
    local value_ok, value_structure, value_msg
    value_ok, index, value_structure, value_msg = test_parse_expression(tokens, index)
    if not value_ok then
        return false, index, {}, "failed to parse bare value expression:\n"..value_msg
    end
    local semicolon_token = get_token(tokens, index)
    if semicolon_token.type ~= "semicolon" then
        return false, index, {}, "missing semicolon"
    end
    index = index + 1
    return true, index, {
        type = "bare_value",
        location = start_token.location,
        location_end = semicolon_token.location_end,
        value = value_structure
    }, "ok"
end

---attempts to parse a deletion statement from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
local function test_parse_deletion_statement(tokens, index)
    local delete_token = get_token(tokens, index)
    if delete_token.type ~= "statement_delete" then
        return false, index, {}, "deletion requires a declare token"
    end
    index = index + 1
    local name_token = get_token(tokens, index)
    if name_token.type ~= "name" then
        return false, index, {}, "deletion requires a variable name"
    end
    index = index + 1
    local semicolon_token = get_token(tokens, index)
    if semicolon_token.type ~= "semicolon" then
        return false, index, {}, "missing semicolon"
    end
    index = index + 1
    return true, index, {
        type = "deletion",
        location = delete_token.location,
        location_end = semicolon_token.location_end,
        value = {
            name = name_token.value
        }
    }, "ok"
end

---attempts to parse a return statement from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
local function test_parse_return_statement(tokens, index)
    local return_token = get_token(tokens, index)
    if return_token.type ~= "statement_return" then
        return false, index, {}, "return requires a return token"
    end
    index = index + 1
    local return_structure = {
        type = "value",
        location = return_token.location,
        location_end = return_token.location_end,
        value = {
            type = "value_null"
        }
    }
    local value_ok, value_structure, value_msg
    value_ok, index, value_structure, value_msg = test_parse_expression(tokens, index)
    if value_ok then
        return_structure = value_structure
    end
    local semicolon_token = get_token(tokens, index)
    if semicolon_token.type ~= "semicolon" then
        return false, index, {}, "missing semicolon"
    end
    index = index + 1
    return true, index, {
        type = "return_statement",
        location = return_token.location,
        location_end = semicolon_token.location_end,
        value = {
            tail = false,   -- set to indicate this return statement is at the end of a function
            value = return_structure
        }
    }, "ok"
end

---attempts to parse an if statement from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
local function test_parse_if_statement(tokens, index)
    local conditions = {}
    local blocks = {}
    local final_structure = {
        type = "block",
        location = get_token(tokens, index).location,
        location_end = get_token(tokens, index).location,
        value = {
            structures = {}
        }
    }
    while true do
        local if_token = get_token(tokens, index)
        if if_token.type ~= "statement_if" then
            return false, index, {}, "if statement must start with a statement_if token"
        end
        index = index + 1
        local open_condition_token = get_token(tokens, index)
        if open_condition_token.type ~= "paren_open" then
            return false, index, {}, "if statement missing open parenthesis"
        end
        index = index + 1
        local condition_ok, condition_structure, condition_msg
        condition_ok, index, condition_structure, condition_msg = test_parse_expression(tokens, index)
        if not condition_ok then
            return false, index, {}, "failed to parse if condition:\n"..condition_msg
        end
        table.insert(conditions, condition_structure)
        local close_condition_token = get_token(tokens, index)
        if close_condition_token.type ~= "paren_close" then
            return false, index, {}, "if statement missing close parenthesis"
        end
        index = index + 1
        local open_block_token = get_token(tokens, index)
        if open_block_token.type ~= "block_open" then
            return false, index, {}, "if statement missing open block"
        end
        index = index + 1
        local block_ok, block_structure, block_msg
        block_ok, index, block_structure, block_msg = test_parse_block(tokens, index)
        if not block_ok then
            return false, index, {}, "failed to parse if block:\n"..block_msg
        end
        table.insert(blocks, block_structure)
        local close_block_token = get_token(tokens, index)
        if close_block_token.type ~= "block_close" then
            return false, index, {}, "if statement missing close block"
        end
        index = index + 1
        local else_token = get_token(tokens, index)
        if else_token.type ~= "statement_else" then
            break
        end
        index = index + 1
        local open_else_block_token = get_token(tokens, index)
        if open_else_block_token.type == "block_open" then
            index = index + 1
            local else_block_ok, else_block_msg
            else_block_ok, index, final_structure, else_block_msg = test_parse_block(tokens, index)
            if not else_block_ok then
                return false, index, {}, "failed to parse else block:\n"..else_block_msg
            end
            local close_else_block_token = get_token(tokens, index)
            if close_else_block_token.type ~= "block_close" then
                return false, index, {}, "else statement missing close block"
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
    return true, index, final_structure, "ok"
end

---attempts to parse a foreach loop from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
local function test_parse_foreach_loop(tokens, index)
    local for_token = get_token(tokens, index)
    if for_token.type ~= "statement_for" then
        return false, index, {}, "missing for token"
    end
    index = index + 1
    local open_paren_token = get_token(tokens, index)
    if open_paren_token.type ~= "paren_open" then
        return false, index, {}, "missing open parenthesis"
    end
    index = index + 1
    local name_token = get_token(tokens, index)
    if name_token.type ~= "name" then
        return false, index, {}, "missing iterator name"
    end
    index = index + 1
    local in_token = get_token(tokens, index)
    if in_token.type ~= "statement_in" then
        return false, index, {}, "missing in token"
    end
    index = index + 1
    local value_ok, value_structure, value_msg
    value_ok, index, value_structure, value_msg = test_parse_expression(tokens, index)
    if not value_ok then
        return false, index, {}, "failed to parse iterator value:\n"..value_msg
    end
    local close_paren_token = get_token(tokens, index)
    if close_paren_token.type ~= "paren_close" then
        return false, index, {}, "missing close parenthesis"
    end
    index = index + 1
    local open_block_token = get_token(tokens, index)
    if open_block_token.type ~= "block_open" then
        return false, index, {}, "missing open block"
    end
    index = index + 1
    local block_ok, block_structure, block_msg
    block_ok, index, block_structure, block_msg = test_parse_block(tokens, index)
    if not block_ok then
        return false, index, {}, "failed to parse block:\n"..block_msg
    end
    local close_block_token = get_token(tokens, index)
    if close_block_token.type ~= "block_close" then
        return false, index, {}, "missing close block"
    end
    index = index + 1
    return true, index, {
        type = "foreach_loop",
        location = for_token.location,
        location_end = close_block_token.location_end,
        value = {
            name = name_token.value,
            iterator = value_structure,
            block = block_structure
        }
    }, "ok"
end

---attempts to parse a for loop from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
local function test_parse_for_loop(tokens, index)
    local for_token = get_token(tokens, index)
    if for_token.type ~= "statement_for" then
        return false, index, {}, "missing for token"
    end
    index = index + 1
    local open_paren_token = get_token(tokens, index)
    if open_paren_token.type ~= "paren_open" then
        return false, index, {}, "missing open parenthesis"
    end
    index = index + 1
    local name_token = get_token(tokens, index)
    if name_token.type ~= "name" then
        return false, index, {}, "missing iterator name"
    end
    index = index + 1
    local start_structure, stop_structure, step_structure
    local assignment_token = get_token(tokens, index)
    if assignment_token.type == "assignment" then
        index = index + 1
        local start_ok, start_msg
        start_ok, index, start_structure, start_msg = test_parse_expression(tokens, index)
        if not start_ok then
            return false, index, {}, "failed to parse start value:\n"..start_msg
        end
    else
        start_structure = {
            type = "value",
            location = assignment_token.location_end,
            location_end = assignment_token.location_end,
            value = {
                type = "value_number",
                value = 1
            }
        }
    end
    local arrow_token = get_token(tokens, index)
    if arrow_token.type ~= "statement_arrow" then
        return false, index, {}, "missing arrow"
    end
    index = index + 1
    local stop_ok, stop_msg
    stop_ok, index, stop_structure, stop_msg = test_parse_expression(tokens, index)
    if not stop_ok then
        return false, index, {}, "failed to parse end value:\n"..stop_msg
    end
    local by_token = get_token(tokens, index)
    if by_token.type == "statement_by" then
        index = index + 1
        local step_ok, step_msg
        step_ok, index, step_structure, step_msg = test_parse_expression(tokens, index)
        if not step_ok then
            return false, index, {}, "failed to parse step value:\n"..step_msg
        end
    else
        step_structure = {
            type = "value",
            location = by_token.location,
            location_end = by_token.location,
            value = {
                type = "value_number",
                value = 1
            }
        }
    end
    local close_paren_token = get_token(tokens, index)
    if close_paren_token.type ~= "paren_close" then
        return false, index, {}, "missing close parenthesis"
    end
    index = index + 1
    local open_block_token = get_token(tokens, index)
    if open_block_token.type ~= "block_open" then
        return false, index, {}, "missing open block"
    end
    index = index + 1
    local block_ok, block_structure, block_msg
    block_ok, index, block_structure, block_msg = test_parse_block(tokens, index)
    if not block_ok then
        return false, index, {}, "failed to parse block:\n"..block_msg
    end
    local close_block_token = get_token(tokens, index)
    if close_block_token.type ~= "block_close" then
        return false, index, {}, "missing close block"
    end
    index = index + 1
    return true, index, {
        type = "for_loop",
        location = for_token.location,
        location_end = close_block_token.location_end,
        value = {
            name = name_token.value,
            start = start_structure,
            stop = stop_structure,
            step = step_structure,
            block = block_structure
        }
    }, "ok"
end

---attempts to parse a function (excluding the function statement) from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
function test_parse_function(tokens, index)
    local param_open_token = get_token(tokens, index)
    if param_open_token.type ~= "paren_open" then
        return false, index, {}, "function missing parameters at "..tokeniser.location_string(param_open_token.location)
    end
    index = index + 1
    local params = {}
    local no_param_token = get_token(tokens, index)
    if no_param_token.type ~= "paren_close" then
        while true do
            local param_name_token = get_token(tokens, index)
            if param_name_token.type ~= "name" then
                return false, index, {}, "function parameter name missing at "..tokeniser.location_string(param_name_token.location)
            end
            index = index + 1
            table.insert(params, param_name_token.value)
            local comma_token = get_token(tokens, index)
            if comma_token.type ~= "comma" then
                break
            end
            index = index + 1
        end
    end
    index = index + 1
    local block_open_token = get_token(tokens, index)
    if block_open_token.type ~= "block_open" then
        return false, index, {}, "function missing open block at "..tokeniser.location_string(block_open_token.location)
    end
    index = index + 1
    local block_ok, block_structure, block_msg
    block_ok, index, block_structure, block_msg = test_parse_block(tokens, index)
    if not block_ok then
        return false, index, {}, "failed to parse function block:\n"..block_msg
    end
    local block_close_token = get_token(tokens, index)
    if block_close_token.type ~= "block_close" then
        return false, index, {}, "function missing close block at "..tokeniser.location_string(block_close_token.location)
    end
    index = index + 1
    return true, index, {
        params = params,
        body = block_structure
    }, "ok"
end

---attempts to parse a statement from tokens starting at the given index
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
local function test_parse_statement(tokens, index)
    local msgs = {}
    for _, statement_parser_pair in ipairs({
        {name = "declaration_statement", parser = test_parse_declaration_statement},
        {name = "deletion_statement", parser = test_parse_deletion_statement},
        {name = "assignment_statement", parser = test_parse_assignment_statement},
        {name = "modifier", parser = test_parse_modifier_statement},
        {name = "if_statement", parser = test_parse_if_statement},
        {name = "foreach_loop", parser = test_parse_foreach_loop},
        {name = "for_loop", parser = test_parse_for_loop},
        {name = "bare_value", parser = test_parse_bare_value},
        {name = "return_statement", parser = test_parse_return_statement}
    }) do
        local ok, new_index, structure, msg = statement_parser_pair.parser(tokens, index)
        if ok then
            return true, new_index, structure, "ok"
        end
        table.insert(msgs, statement_parser_pair.name..":   "..msg)
    end
    return false, index, {}, "no statement matched:\n- "..table.concat(msgs, "\n- ")
end

---attempts to parse a block of code from tokens starting at the given index, stops at a closing block token
---@param tokens table
---@param index integer
---@return boolean ok
---@return integer index
---@return table structure
---@return string msg
function test_parse_block(tokens, index)
    local start_token = get_token(tokens, index)
    local structures = {}
    while index <= #tokens do
        local token = get_token(tokens, index)
        if token.type == "block_close" then
            break
        end
        local ok, msg, sub_structure
        ok, index, sub_structure, msg = test_parse_statement(tokens, index)
        if not ok then
            return false, index, {}, "failed to parse statement:\n"..msg
        end
        table.insert(structures, sub_structure)
    end
    return true, index, {
        type = "block",
        location = start_token.location,
        location_end = tokens[index - 1].location_end,
        value = {
            structures = structures
        }
    }, "ok"
end

local function parse(tokens)
    local ok, index, structure, msg = test_parse_block(tokens, 1)
    if not ok then
        local offending_token = get_token(tokens, index)
        return false, {}, "error parsing at "..tokeniser.location_string(offending_token.location).."\n"..msg
    end
    return true, structure, "ok"
end

return {
    parse = parse
}