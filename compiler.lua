local constants = require("constants")
local locations = require("locations")
local table_to_json = require("table_to_json")

local function scope_new()
    return {
        offset = 1,
        function_scopes = {},
        block_scopes = {},
        names = {}
    }
end

---shift the scope to account for a number of values added to the stack
---@param scope table
---@param amount integer
local function scope_shift(scope, amount)
    scope.offset = scope.offset + amount
    if amount < 0 then
        for i = 1, -amount do
            scope.names[scope.offset - amount - i] = nil
        end
    end
end

---add a new name to an existing scope
---@param scope table
---@param name string
local function scope_add(scope, name)
    scope.names[scope.offset] = name
    scope.offset = scope.offset + 1
end

---finds the closest position of a name in the scope
---@param scope table
---@param name string
---@return integer index
local function scope_find(scope, name)
    for i = scope.offset - 1, 1, -1 do
        if scope.names[i] == name then
            return scope.offset - i
        end
    end
    return -1
end

---remove the closest position of a name in the scope
---@param scope table
---@param name string
local function scope_remove(scope, name)
    for i = scope.offset - 1, 1, -1 do
        if scope.names[i] == name then
            for j = i + 1, scope.offset - 1 do
                scope.names[j - 1] = scope.names[j]
            end
            scope.offset = scope.offset - 1
            scope.names[scope.offset] = nil
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
    if #pattern == 0 then
        return patterns(
            "vacant_reflection"
        )
    elseif #pattern == 1 then
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
    if constants.number_patterns[int_value] then
        return patterns(
            constants.number_patterns[int_value]
        )
    end
    local tens_pattern = {}
    local tens = math.floor(int_value / 10)
    if tens == 1 then
        tens_pattern = patterns(
            "ten"
        )
    else
        tens_pattern = patterns(
            pattern_number(tens),
            "ten",
            "multiplicative_distillation"
        )
    end
    if int_value % 10 == 0 then
        return tens_pattern
    end
    return patterns(
        tens_pattern,
        constants.number_patterns[int_value % 10],
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

---creates a pattern that adds a boolean to the stack
---@param value boolean
---@return table pattern
local function pattern_bool(value)
    if value then
        return patterns(
            "true_reflection"
        )
    else
        return patterns(
            "false_reflection"
        )
    end
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
    end
    return patterns(
        pattern_number(index),
        "flocks_gambit",
        "derivation_distillation",
        "speakers_distillation",
        "flocks_disintegration"
    )
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

---creates a pattern to remove a number of values from the stack
---@param count integer
---@return table pattern
local function pattern_remove(count)
    if count == 0 then
        return patterns()
    elseif count == 1 then
        return patterns(
            "bookkeepers_gambit_v"
        )
    elseif count == 2 then
        return patterns(
            "bookkeepers_gambit_vv"
        )
    elseif count == 3 then
        return patterns(
            "bookkeepers_gambit_vvv"
        )
    elseif count == 4 then
        return patterns(
            "bookkeepers_gambit_vvv",
            "bookkeepers_gambit_v"
        )
    elseif count == 5 then
        return patterns(
            "bookkeepers_gambit_vvv",
            "bookkeepers_gambit_vv"
        )
    elseif count == 6 then
        return patterns(
            "bookkeepers_gambit_vvv",
            "bookkeepers_gambit_vvv"
        )
    end
    return patterns(
        pattern_number(count),
        "flocks_gambit",
        "bookkeepers_gambit_v"
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

local compile_structure

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
    elseif structure.type == "value_bool" then
        return true, pattern_bool(structure.value), "ok"
    elseif structure.type == "list" then
        local list_patterns = {}
        for _, value in ipairs(structure.value) do
            local value_ok, value_pattern, value_msg = compile_structure(value, scope)
            if not value_ok then
                return false, {}, "value failed to compile:\n"..value_msg
            end
            list_combine(list_patterns, value_pattern)
            scope_shift(scope, 1)
        end
        scope_shift(scope, -#structure.value)
        return true, patterns(
            list_patterns,
            pattern_number(#structure.value),
            "flocks_gambit"
        ), "ok"
    elseif structure.type == "vector" then
        local x_ok, x_pattern, x_msg = compile_structure(structure.value.x, scope)
        if not x_ok then
            return false, {}, "x failed to compile:\n"..x_msg
        end
        scope_shift(scope, 1)
        local y_ok, y_pattern, y_msg = compile_structure(structure.value.y, scope)
        if not y_ok then
            return false, {}, "y failed to compile:\n"..y_msg
        end
        scope_shift(scope, 1)
        local z_ok, z_pattern, z_msg = compile_structure(structure.value.z, scope)
        if not z_ok then
            return false, {}, "z failed to compile:\n"..z_msg
        end
        scope_shift(scope, -2)
        return true, patterns(
            x_pattern,
            y_pattern,
            z_pattern,
            "vector_exaltation"
        ), "ok"
    elseif structure.type == "function" then
        table.insert(scope.function_scopes, scope.offset)
        for _, name in ipairs(structure.value.params) do
            scope_add(scope, name)
        end
        local body_ok, body_pattern, body_msg = compile_structure(structure.value.body, scope)
        local scope_excess = scope.offset - table.remove(scope.function_scopes)
        scope_shift(scope, -scope_excess)
        if not body_ok then
            return false, {}, "function body failed to compile:\n"..body_msg
        end
        return true, escape_pattern(body_pattern), "ok"
    elseif structure.type == "inline_hex" then
        local pattern = {}
        for i, value_structure in ipairs(structure.value) do
            local value_ok, value_pattern, value_msg = compile_structure(value_structure, scope)
            if not value_ok then
                return false, {}, "failed to compile inline hex (value #"..i.."):\n"..value_msg
            end
            list_combine(pattern, value_pattern)
        end
        return true, pattern, "ok"
    elseif structure.type == "name" then
        local var_index = scope_find(scope, structure.value)
        if var_index < 1 then
            return false, {}, "variable '"..structure.value.."' not defined"
        end
        return true, pattern_stack_fetch_copy(var_index), "ok"
    end
    return false, {}, "unknown value type '"..tostring(structure.type)
end

---compiles an index structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_index(structure, scope)
    local value_ok, value_pattern, value_msg = compile_structure(structure.value, scope)
    if not value_ok then
        return false, {}, "compile indexed value failed:\n"..value_msg
    end
    scope_shift(scope, 1)
    local index_ok, index_pattern, index_msg = compile_structure(structure.index, scope)
    if not index_ok then
        return false, {}, "compile index failed:\n"..index_msg
    end
    scope_shift(scope, -1)
    return true, patterns(
        value_pattern,
        index_pattern,
        "selection_distillation"
    ), "ok"
end

---compiles a property structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_property(structure, scope)
    local value_ok, value_pattern, value_msg = compile_structure(structure.value, scope)
    if not value_ok then
        return false, {}, "compile property value failed:\n"..value_msg
    end
    scope_shift(scope, 1)
    local property_ok, property_pattern, property_msg = compile_structure(structure.property, scope)
    if not property_ok then
        return false, {}, "compile property access failed:\n"..property_msg
    end
    scope_shift(scope, -1)
    return true, patterns(
        value_pattern,
        property_pattern
    ), "ok"
end

---compiles a property access structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_property_access(structure, scope)
    local expected_arg_offsets = constants.property_call_arguments[structure.name]
    if structure.call and expected_arg_offsets == nil then
        return false, {}, "did not expect function call for "..structure.name.." property access"
    end
    local arg_patterns = {}
    if expected_arg_offsets then
        if #structure.arguments ~= #expected_arg_offsets then
            return false, {}, "excepted "..expected_arg_offsets.." arguments for property access function, got "..#structure.arguments.." instead"
        end
        local current_offset = 0
        for i, value_structure in ipairs(structure.arguments) do
            local shift = constants.property_call_arguments[structure.name][i] - current_offset
            current_offset = current_offset + shift
            scope_shift(scope, shift)
            local value_ok, value_pattern, value_msg = compile_structure(value_structure, scope)
            if not value_ok then
                return false, {}, "failed to compile property access call argument #"..i..":\n"..value_msg
            end
            table.insert(arg_patterns, value_pattern)
        end
        scope_shift(scope, -current_offset)
        local standard_pattern = constants.property_function_patterns[#expected_arg_offsets + 1][structure.name]
        if standard_pattern then
            return true, patterns(
                table.unpack(arg_patterns),
                standard_pattern
            ), "ok"
        end
    end
    local standard_pattern = constants.property_patterns[structure.name]
    if standard_pattern then
        return true, standard_pattern, "ok"
    end
    -- if structure.name == "x" then
    --     return true, patterns(
    --         "vector_disintegration",
    --         pattern_remove(2)
    --     ), "ok"
    -- elseif structure.name == "y" then
    --     return true, patterns(
    --         "vector_disintegration",
    --         "bookkeepers_gambit_v-v"
    --     ), "ok"
    -- elseif structure.name == "z" then
    --     return true, patterns(
    --         "vector_disintegration",
    --         "bookkeepers_gambit_vv-"
    --     ), "ok"
    -- end
    return false, {}, "invalid property access name"
end

---compiles a function call structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_call(structure, scope)
    local pattern = {}
    for _, arg in ipairs(structure.args) do
        local arg_ok, arg_pattern, arg_msg = compile_structure(arg, scope)
        if not arg_ok then
            return false, {}, "compile call argument failed:\n"..arg_msg
        end
        list_combine(pattern, arg_pattern)
        scope_shift(scope, 1)
    end
    local value_ok, value_pattern, value_msg = compile_structure(structure.value, scope)
    if not value_ok then
        return false, {}, "compile indexed value failed:\n"..value_msg
    end
    scope_shift(scope, -#structure.args)
    return true, patterns(
        pattern,
        value_pattern,
        "hermes_gambit"
    ), "ok"
end

---compiles an expression structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_expression(structure, scope)
    local left_ok, left_pattern, left_msg = compile_structure(structure.left, scope)
    if not left_ok then
        return false, {}, "compile expression left failed:\n"..left_msg
    end
    scope_shift(scope, 1)
    local right_ok, right_pattern, right_msg = compile_structure(structure.right, scope)
    if not right_ok then
        return false, {}, "compile expression right failed:\n"..right_msg
    end
    scope_shift(scope, -1)
    return true, patterns(
        left_pattern,
        right_pattern,
        constants.operators[structure.op]
    ), "ok"
end

---compiles a variable assignment structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_variable_assignment(structure, scope)
    local var_index = scope_find(scope, structure.variable.name)
    if var_index < 1 and structure.is_declared then
        return false, {}, "variable '"..structure.variable.name.."' not defined at "..locations.tostring(structure.value.location)
    end
    scope_shift(scope, 2 * #structure.variable.indicies)
    local value_ok, value_pattern, value_msg = compile_structure(structure.value, scope)
    if not value_ok then
        return false, {}, "compile variable assignment value failed:\n"..value_msg
    end
    scope_shift(scope, -2 * #structure.variable.indicies)
    if not structure.is_declared then
        scope_add(scope, structure.variable.name)
        return true, value_pattern, "ok"
    end
    if #structure.variable.indicies == 0 then
        return true, patterns(
            value_pattern,
            pattern_stack_throw_copy(var_index)
        ), "ok"
    end
    local pattern = pattern_stack_fetch_copy(var_index)
    scope_shift(scope, 1)
    for i, index_structure in ipairs(structure.variable.indicies) do
        local index_ok, index_pattern, index_msg = compile_structure(index_structure, scope)
        if not index_ok then
            return false, {}, "compile variable assignment index "..i.." failed:\n"..index_msg
        end
        if i == #structure.variable.indicies then
            list_combine(pattern, index_pattern)
            scope_shift(scope, 1)
        else
            list_combine(pattern, patterns(
                index_pattern,
                "dioscuri_gambit",
                "selection_distillation"
            ))
            scope_shift(scope, 2)
        end
    end
    list_combine(pattern, value_pattern)
    for _ = 1, #structure.variable.indicies do
        list_combine(pattern, patterns(
            "surgeons_exaltation"
        ))
    end
    return true, patterns(
        pattern,
        pattern_stack_throw_copy(var_index)
    ), "ok"
end

---compiles a bare value structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_bare_value(structure, scope)
    local value_ok, value_pattern, value_msg = compile_structure(structure, scope)
    if not value_ok then
        return false, {}, "compile bare value failed:\n"..value_msg
    end
    return true, patterns(
        value_pattern,
        "bookkeepers_gambit_v"
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
    if var_index < 1 then
        return false, {}, "variable '"..structure.name.."' not defined"
    end
    scope_remove(scope, structure.name)
    return true, patterns(
        pattern_stack_fetch(var_index),
        "bookkeepers_gambit_v"
    ), "ok"
end

---compiles an inline hex pattern structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_inline_hex_pattern(structure, scope)
    return true, patterns(
        structure
    ), "ok"
end

---compiles an inline hex value structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_inline_hex_value(structure, scope)
    local value_ok, value_pattern, value_msg = compile_structure(structure, scope)
    if not value_ok then
        return false, {}, "failed to compile inline hex value:\n"..value_msg
    end
    return true, value_pattern, "ok"
end

---compiles a return structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_return(structure, scope)
    local value_ok, value_pattern, value_msg = compile_structure(structure.value, scope)
    if not value_ok then
        return false, {}, "compile return value failed:\n"..value_msg
    end
    local scope_excess = scope.offset - scope.function_scopes[#scope.function_scopes]
    local jump_pattern = {}
    if not structure.tail then
        jump_pattern = {
            "charons_gambit"
        }
    end
    return true, patterns(
        value_pattern,
        pattern_stack_throw(scope_excess + 1),
        pattern_remove(scope_excess),
        jump_pattern
    ), "ok"
end

---compiles an if statement structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_if_statement(structure, scope)
    local condition_ok, condition_pattern, condition_msg = compile_structure(structure.condition, scope)
    if not condition_ok then
        return false, {}, "compile if condition failed:\n"..condition_msg
    end
    local if_block_ok, if_block_pattern, if_block_msg = compile_structure(structure.if_block, scope)
    if not if_block_ok then
        return false, {}, "compile if block failed:\n"..if_block_msg
    end
    local else_block_ok, else_block_pattern, else_block_msg = compile_structure(structure.else_block, scope)
    if not else_block_ok then
        return false, {}, "compile else block failed:\n"..else_block_msg
    end
    return true, pattern_if_else(
        condition_pattern,
        if_block_pattern,
        else_block_pattern
    ), "ok"
end

---compiles a foreach loop structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_foreach_loop(structure, scope)
    local iterator_ok, iterator_pattern, iterator_msg = compile_structure(structure.iterator, scope)
    if not iterator_ok then
        return false, {}, "compile foreach iterator failed:\n"..iterator_msg
    end
    scope_add(scope, structure.name)
    local block_ok, block_pattern, block_msg = compile_structure(structure.block, scope)
    if not block_ok then
        return false, {}, "compile foreach block failed:\n"..block_msg
    end
    scope_remove(scope, structure.name)
    return true, patterns(
        escape_pattern(block_pattern),
        iterator_pattern,
        "thoths_gambit",
        pattern_remove(1)
    ), "ok"
end

---compiles a for loop structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_for_loop(structure, scope)
    scope_shift(scope, 1) -- step
    scope_add(scope, structure.name)
    local block_ok, block_pattern, block_msg = compile_structure(structure.block, scope)
    if not block_ok then
        return false, {}, "compile for block failed:\n"..block_msg
    end
    scope_remove(scope, structure.name)
    scope_shift(scope, -1) -- step
    if  structure.start.type == "value" and structure.start.value.type == "value_number"
    and structure.stop.type  == "value" and structure.stop.value.type  == "value_number"
    and structure.step.type  == "value" and structure.step.value.type  == "value_number" then
        local start, stop, step =
        structure.start.value.value,
        structure.stop.value.value,
        structure.step.value.value
        local count = math.floor((stop - start) / step) + 1
        return true, patterns(
            escape_pattern(patterns(
                "muninns_reflection",       -- <index> step index
                block_pattern,              -- <index> step index
                constants.operators.op_add,           -- <index> new_index
                "huginns_gambit"            -- <new_index>
            )),
            pattern_number(start),          -- <?> [code...] start
            "huginns_gambit",               -- <start> [code...]
            pattern_number(step),           -- <start> [code...] step
            pattern_number(count),          -- <start> [code...] step count
            "gemini_gambit",                -- <start> [code...] step...
            pattern_number(count),          -- <start> [code...] step... count
            "flocks_gambit",                -- <start> [code...] [step...]
            "thoths_gambit",                -- <start> [returns...]
            pattern_remove(1)               -- <start>
        ), "ok"
    end
    scope_shift(scope, 1) -- [code...]
    local start_ok, start_pattern, start_msg = compile_structure(structure.start, scope)
    if not start_ok then
        return false, {}, "compile for start value failed:\n"..start_msg
    end
    scope_shift(scope, 1) -- start
    local step_ok, step_pattern, step_msg = compile_structure(structure.step, scope)
    if not step_ok then
        return false, {}, "compile for step value failed:\n"..step_msg
    end
    scope_shift(scope, 2) -- step step
    local stop_ok, stop_pattern, stop_msg = compile_structure(structure.stop, scope)
    if not stop_ok then
        return false, {}, "compile for stop value failed:\n"..stop_msg
    end
    scope_shift(scope, -4) -- [code...] step step stop
    return true, patterns(
        escape_pattern(patterns(
            "muninns_reflection",       -- <index> step index
            block_pattern,              -- <index> step index
            constants.operators.op_add,           -- <index> new_index
            "huginns_gambit"            -- <new_index>
        )),
        start_pattern,                  -- <?> [code...] start
        step_pattern,                   -- <?> [code...] start step
        pattern_stack_fetch_copy(1),    -- <?> [code...] start step step
        stop_pattern,                   -- <?> [code...] start step step stop
        pattern_stack_fetch_copy(4),    -- <?> [code...] start step step stop start
        constants.operators.op_sub,               -- <?> [code...] start step step delta
        pattern_stack_fetch(2),         -- <?> [code...] start step delta step
        constants.operators.op_div,               -- <?> [code...] start step count-1
        pattern_number(1),              -- <?> [code...] start step count-1 1
        constants.operators.op_add,               -- <?> [code...] start step count
        "huginns_gambit",               -- <count> [code...] start step
        "muninns_reflection",           -- <count> [code...] start step count
        "gemini_gambit",                -- <count> [code...] start step...
        "muninns_reflection",           -- <count> [code...] start step... count
        "flocks_gambit",                -- <count> [code...] start [step...]
        pattern_stack_fetch(2),         -- <count> [code...] [step...] start
        "huginns_gambit",               -- <start> [code...] [step...]
        "thoths_gambit",                -- <start> [returns...]
        pattern_remove(1)               -- <start>
    ), "ok"
end

---compiles a block structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
local function compile_block(structure, scope)
    table.insert(scope.block_scopes, scope.offset)
    local pattern = {}
    for _, statement in ipairs(structure.structures) do
        local statement_ok, statement_pattern, statement_msg = compile_structure(statement, scope)
        if not statement_ok then
            return false, {}, "compile block statement failed:\n"..statement_msg
        end
        list_combine(pattern, statement_pattern)
    end
    local scope_excess = scope.offset - table.remove(scope.block_scopes)
    scope_shift(scope, -scope_excess)
    list_combine(pattern, pattern_remove(scope_excess))
    return true, pattern, "ok"
end

---compiles a structure into a pattern
---@param structure table
---@param scope table
---@return boolean ok
---@return table pattern
---@return string msg
function compile_structure(structure, scope)
    local compiler = ({
        block = compile_block,
        inline_hex_pattern = compile_inline_hex_pattern,
        inline_hex_value = compile_inline_hex_value,
        deletion = compile_deletion,
        variable_assignment = compile_variable_assignment,
        expression = compile_expression,
        value = compile_value,
        index = compile_index,
        property = compile_property,
        property_access = compile_property_access,
        if_statement = compile_if_statement,
        foreach_loop = compile_foreach_loop,
        for_loop = compile_for_loop,
        call = compile_call,
        return_statement = compile_return,
        bare_value = compile_bare_value,
    })[structure.type]
    if compiler then
        local compiled_ok, compiled_pattern, compiled_msg = compiler(structure.value, scope)
        if not compiled_ok then
            return false, {}, "At "..locations.tostring(structure.location).." "..compiled_msg
        end
        return true, compiled_pattern, "ok"
    end
    return false, {}, "unknown structure type '"..tostring(structure.type).."' at "..locations.tostring(structure.location)
end

local function compile(structure)
    return compile_structure(structure, scope_new())
end

return {
    compile = compile,
}