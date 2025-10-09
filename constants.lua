return {
    -- defines all valid tokens and the order in which they are checked
    -- name: name of token
    -- pattern: lua pattern used to match with, the capture group is the actual token taken
    -- padding: optional, specifies the number of characters before the capture group
    -- (used to remove the dot from property access token values, but still include it in the
    -- characters a token advances)
    token_patterns = {
        {name = "_comment_line", pattern = "//[^\n]*"},
        {name = "_comment_block", pattern = "/%*.-%*/"},

        {name = "inline_hex_marker", pattern = "\""},

        {name = "statement_if", pattern = "(if)[^a-zA-Z_0-9]"},
        {name = "statement_else", pattern = "(else)[^a-zA-Z_0-9]"},
        {name = "statement_for", pattern = "(for)[^a-zA-Z_0-9]"},
        {name = "statement_while", pattern = "(while)[^a-zA-Z_0-9]"},
        {name = "statement_function", pattern = "(function)[^a-zA-Z_0-9]"},
        {name = "statement_return", pattern = "(return)[^a-zA-Z_0-9]"},
        {name = "statement_declare", pattern = "(let)[^a-zA-Z_0-9]"},
        {name = "statement_delete", pattern = "(delete)[^a-zA-Z_0-9]"},
        {name = "statement_by", pattern = "(by)[^a-zA-Z_0-9]"},
        {name = "statement_arrow", pattern = "(%->)[^a-zA-Z_0-9]"},
        {name = "statement_in", pattern = "(in)[^a-zA-Z_0-9]"},

        {name = "property", pattern = "%.([a-zA-Z_][a-zA-Z_0-9]*)[^a-zA-Z_0-9]", padding = 1},

        {name = "value_null", pattern = "null"},
        {name = "value_bool", pattern = "(true)"},
        {name = "value_bool", pattern = "(false)"},
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
        {name = "op_and", pattern = "&&"},
        {name = "op_and", pattern = "(and)[^a-zA-Z_0-9]"},
        {name = "op_or", pattern = "||"},
        {name = "op_or", pattern = "(or)[^a-zA-Z_0-9]"},
        {name = "op_xor", pattern = "%^%^"},
        {name = "op_xor", pattern = "(xor)[^a-zA-Z_0-9]"},

        {name = "assignment", pattern = "="},
        {name = "comma", pattern = ","},
        {name = "semicolon", pattern = ";"},
        {name = "name", pattern = "([a-zA-Z_][a-zA-Z_0-9]*)"},
        {name = "_whitespace", pattern = "%s+"},
    },
    -- defines the order that operations are evaluated, each entry is a list
    -- that is evaluated left to right simultaneously
    op_order = {
        {"op_exp"}, -- exponents first
        {"op_mul", "op_div"}, -- then multiplication and division
        {"op_add", "op_sub"}, -- then addition and subtraction,
        {"op_eql", "op_grt", "op_gte", "op_lst", "op_lte", "op_neq"}, -- then boolean conditions
        {"op_and", "op_or", "op_xor"}, -- then boolean combinations
    },
    -- defines patterns associated with operator tokens
    operators = {
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
    },
    -- defines valid number patterns
    number_patterns = {
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
    },
    -- lists of argument scope offsets for compiling, also determines which
    -- properties are functions
    property_call_arguments = {
        raycast = {1}
    },
    -- defines basic property access patterns
    property_patterns = {
        eyes = {"compass_purification"},
        feet = {"compass_purification_2"},
        looking = {"alidades_purification"},
        height = {"stadiometers_purification"},
        velocity = {"pace_purification"},
    },

    property_function_patterns = {
        { -- 0 args
        
        },
        { -- 1 arg
            raycast = {"archers_distillation"},
            raycast_side = {"architects_distillation"},
            raycast_entity = {"scouts_distillation"},
        },
        { -- 2 args

        }
    }
}