local tokeniser = require("tokeniser")
local table_to_json = require("table_to_json")

local numbers = {
    [0] = "zero",
    [1] = "one",
    [2] = "two",
    [3] = "three",
    [4] = "four",
    [5] = "five",
    [6] = "six",
    [7] = "seven",
    [8] = "eight",
    [9] = "nine",
    [10] = "ten",
}

local operators = {
    op_add = "additive_distillation",
    op_sub = "subtractive_distillation",
    op_mul = "multiplicative_distillation",
    op_div = "division_distillation",
    op_and = "conjunction_distillation",
    op_xor = "exclusion_distillation",
    op_or  = "disjunction_distillation",
    op_eql = "equality_distillation",
    op_neq = "inequality_distillation",
    op_gte = "maximus_distillation_2",
    op_grt = "maximus_distillation",
    op_lte = "minimus_distillation_2",
    op_lst = "minimus_distillation",
}

---shift the scope to account for a number of values added to the stack (this is not mutative)
---@param scope table
---@param amount integer
local function scope_shift(scope, amount)
    if amount > 0 then
        for i = 1, amount do
            table.insert(scope, 1, i)
        end
    else
        for _ = 1, -amount do
            table.remove(scope, 1)
        end
    end
end

---add a new name to an existing scope and adjusts indices accordingly
---@param scope table
---@param name string
local function scope_add(scope, name)
    table.insert(scope, 1, name)
end

---finds the closest position of a name in the scope
---@param scope table
---@param name string
---@return integer index
local function scope_find(scope, name)
    for index, scope_name in ipairs(scope) do
        if scope_name == name then
            return index
        end
    end
    return -1
end

---remove the closest position of a name in the scope
---@param scope table
---@param name string
local function scope_remove(scope, name)
    for index, scope_name in ipairs(scope) do
        if scope_name == name then
            table.remove(scope, index)
            return
        end
    end
end

---adds the contents of list2 to list1 (modifies list1)
---@param list1 table
---@param list2 table
local function list_combine(list1, list2)
    for i = 1, #list2 do
        list1[#list1 + 1] = list2[i]
    end
end

---combines multiple patterns into one
---@param ... string|table patterns
---@return table combined_pattern
local function patterns(...)
    local pattern = {}
    for _, v in ipairs({...}) do
        if type(v) == "table" then
            list_combine(pattern, v)
        else
            list_combine(pattern, {v})
        end
    end
    return pattern
end

---creates a pattern that adds a pattern to the stack
---@param pattern table
---@return table escaped_pattern
local function escape_pattern(pattern)
    if #pattern == 1 then
        return patterns(
            "consideration",
            pattern
        )
    end
    local escaped = {}
    for _, p in ipairs(pattern) do
        if
        --p == "introspection" or p == "retrospection" or 
        p == "consideration" or p == "evanition" then
            table.insert(escaped, "consideration")
        end
        table.insert(escaped, p)
    end
    return patterns(
        "introspection",
        escaped,
        "retrospection"
    )
end

---creates a pattern that adds number to the stack
---@param value integer
---@return table pattern
local function pattern_number(value)
    value = math.floor(value * 1000 + 0.5) / 1000
    if value < 0 then
        return patterns(
            "zero",
            pattern_number(-value),
            "subtractive_distillation"
        )
    end
    local int_value = math.floor(value)
    if value - int_value > 0.0005 then
        return patterns(
            pattern_number(value * 10),
            "ten",
            "division_distillation"
        )
    end
    if numbers[int_value] then
        return patterns(
            numbers[int_value]
        )
    end
    if int_value % 10 == 0 then
        return patterns(
            pattern_number(math.floor(int_value / 10)),
            "ten",
            "multiplicative_distillation"
        )
    end
    print(value)
    return patterns(
        pattern_number(math.floor(int_value / 10)),
        "ten",
        "multiplicative_distillation",
        numbers[int_value % 10],
        "additive_distillation"
    )
end

---creates a pattern that adds nulls to the stack
---@param count integer
---@return table pattern
local function pattern_nulls(count)
    if count == 0 then
        return patterns()
    elseif count == 1 then
        return patterns(
            "nullary_reflection"
        )
    elseif count == 2 then
        return patterns(
            "nullary_reflection",
            "nullary_reflection"
        )
    end
    return patterns(
        "nullary_reflection",
        pattern_number(count),
        "gemini_gambit"
    )
end

---creates a pattern to fetch a stack value
---@param index integer
---@return table pattern
local function pattern_stack_fetch(index)
    if index == 1 then
        return patterns()
    elseif index == 2 then
        return patterns(
            "jesters_gambit"
        )
    elseif index == 3 then
        return patterns(
            "rotation_gambit"
        )
    end
    return patterns(
        pattern_number(index),
        "fishermans_gambit"
    )
end

---creates a pattern to throw a stack value
---@param index integer
---@return table pattern
local function pattern_stack_throw(index)
    if index == 1 then
        return patterns()
    elseif index == 2 then
        return patterns(
            "jesters_gambit"
        )
    elseif index == 3 then
        return patterns(
            "rotation_gambit_2"
        )
    elseif index == 4 then
        return patterns(
            pattern_number(18),
            "swindlers_gambit"
        )
    elseif index == 5 then
        return patterns(
            pattern_number(105),
            "swindlers_gambit"
        )
    end
    return patterns(
        pattern_number(index),
        "flocks_gambit",
        "derivation_distillation",
        "speakers_distillation",
        "flocks_disintegration"
    )
    -- old method
    -- return patterns(
    --     "huginns_gambit",
    --     pattern_number(index - 1),
    --     "flocks_gambit",
    --     "muninns_reflection",
    --     "jesters_gambit",
    --     "flocks_disintegration"
    -- )
end

---creates a pattern to fetch a stack value without removing it
---@param index integer
---@return table pattern
local function pattern_stack_fetch_copy(index)
    if index == 1 then
        return patterns(
            "gemini_decomposition"
        )
    elseif index == 2 then
        return patterns(
            "prospectors_gambit"
        )
    end
    return patterns(
        pattern_number(index),
        "fishermans_gambit_2"
    )
end

---creates a pattern to throw a stack value that replaces an existing one
---@param index integer
---@return table pattern
local function pattern_stack_throw_copy(index)
    if index == 1 then
        return patterns(
            "bookkeepers_gambit_v-"
        )
    elseif index == 2 then
        return patterns(
            "bookkeepers_gambit_v--",
            "jesters_gambit"
        )
    elseif index == 3 then
        return patterns(
            "bookkeepers_gambit_v---",
            "rotation_gambit_2"
        )
    end
    return patterns(
        pattern_number(index + 1),
        "flocks_gambit",
        "derivation_distillation",
        "speakers_decomposition",
        "bookkeepers_gambit_v",
        "speakers_distillation",
        "flocks_disintegration"
    )
end

---creates a pattern for an if else statement
---@param condition_pattern table
---@param true_pattern table
---@param false_pattern any
---@return table pattern
local function pattern_if_else(condition_pattern, true_pattern, false_pattern)
    return patterns(
        condition_pattern,
        escape_pattern(true_pattern),
        escape_pattern(false_pattern),
        "augurs_exaltation",
        "hermes_gambit"
    )
end

local compile

---compiles a value structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_value(structure, scope)
    if structure.type == "value_null" then
        return true, pattern_nulls(1), "ok"
    elseif structure.type == "value_number" then
        return true, pattern_number(structure.value), "ok"
    elseif structure.type == "name" then
        local var_index = scope_find(scope, structure.value)
        print("scope", table_to_json(scope))
        print("var_index", var_index, structure.value)
        if var_index == nil then
            return false, {}, "variable '"..structure.value.."' not defined"
        end
        return true, pattern_stack_fetch_copy(var_index), "ok"
    end
    return false, {}, "unknown value type '"..tostring(structure.type)
end

---compiles an expression structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_expression(structure, scope)
    local left_ok, left_pattern, left_msg = compile(structure.left, scope)
    if not left_ok then
        return false, {}, "compile expression left failed:\n"..left_msg
    end
    scope_shift(scope, 1)
    local right_ok, right_pattern, right_msg = compile(structure.right, scope)
    if not right_ok then
        return false, {}, "compile expression right failed:\n"..right_msg
    end
    scope_shift(scope, -1)
    return true, patterns(
        left_pattern,
        right_pattern,
        operators[structure.op]
    ), "ok"
end

---compiles a variable assignment structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_variable_assignment(structure, scope)
    local var_index = scope_find(scope, structure.name)
    if var_index == nil and structure.is_declared then
        return false, {}, "variable '"..structure.name.."' not defined at "..tokeniser.location_string(structure.value.location)
    end
    local value_ok, value_pattern, value_msg = compile(structure.value, scope)
    if not value_ok then
        return false, {}, "compile variable assignment value failed:\n"..value_msg
    end
    if not structure.is_declared then
        scope_add(scope, structure.name)
        return true, value_pattern, "ok"
    end
    return true, patterns(
        value_pattern,
        pattern_stack_throw_copy(var_index)
    ), "ok"
end

---compiles a variable deletion structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_deletion(structure, scope)
    local var_index = scope_find(scope, structure.name)
    scope_remove(scope, structure.name)
    return true, patterns(
        pattern_stack_fetch(var_index),
        "bookkeepers_gambit_v"
    ), "ok"
end

---compiles an if statement structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_if_statement(structure, scope)
    local condition_ok, condition_pattern, condition_msg = compile(structure.condition, scope)
    if not condition_ok then
        return false, {}, "compile if condition failed:\n"..condition_msg
    end
    print("if scope 1", table_to_json(scope))
    print("if scope 2", table_to_json(scope))
    local if_block_ok, if_block_pattern, if_block_msg = compile(structure.if_block, scope)
    if not if_block_ok then
        return false, {}, "compile if block failed:\n"..if_block_msg
    end
    print("if scope 3", table_to_json(scope))
    local else_block_ok, else_block_pattern, else_block_msg = compile(structure.else_block, scope)
    if not else_block_ok then
        return false, {}, "compile else block failed:\n"..else_block_msg
    end
    print("if scope 4", table_to_json(scope))
    return true, pattern_if_else(
        condition_pattern,
        if_block_pattern,
        else_block_pattern
    ), "ok"
end

---compiles a block structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_block(structure, scope)
    local pattern = {}
    for _, statement in ipairs(structure.structures) do
        local statement_ok, statement_pattern, statement_msg = compile(statement, scope)
        if not statement_ok then
            return false, {}, "compile block statement failed:\n"..statement_msg
        end
        list_combine(pattern, statement_pattern)
    end
    return true, pattern, "ok"
end

---compiles a structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
function compile(structure, scope)
    print("compiling", structure.type, " with scope", table_to_json(scope), "at", tokeniser.location_string(structure.location))
    local compiler = ({
        block = compile_block,
        deletion = compile_deletion,
        variable_assignment = compile_variable_assignment,
        expression = compile_expression,
        value = compile_value,
        if_statement = compile_if_statement,
    })[structure.type]
    if compiler then
        return compiler(structure.value, scope)
    end
    return false, {}, "unknown structure type '"..tostring(structure.type).."' at "..tokeniser.location_string(structure.location)
end

return {
    compile = compile,
}