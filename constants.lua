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
        {name = "value_number", pattern = "(-?%d*%.%d+)"},
        {name = "value_number", pattern = "(-?%d+)"},

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
        {name = "op_mod", pattern = "%%"},
        {name = "op_exp", pattern = "%*%*"},
        {name = "op_eql", pattern = "=="},
        {name = "op_neq", pattern = "!="},
        {name = "op_gte", pattern = ">="},
        {name = "op_grt", pattern = ">"},
        {name = "op_lte", pattern = "<="},
        {name = "op_lst", pattern = "<"},
        {name = "op_and", pattern = "&"},
        {name = "op_and", pattern = "(and)[^a-zA-Z_0-9]"},
        {name = "op_or", pattern = "|"},
        {name = "op_or", pattern = "(or)[^a-zA-Z_0-9]"},
        {name = "op_xor", pattern = "%^"},
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
        {"op_mul", "op_div", "op_mod"}, -- then multiplication and division
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
        op_exp = "power_distillation",
        op_mod = "modulus_distillation",
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
    -- defines property access patterns
    -- method defines if this property is a function
    -- arguments is the names used in the pattern with their stack offsets
    -- pattern has the actual pattern with arguments embedded
    -- returns specifies if this results in a return value
    property_patterns = {
        x = {
            method = false,
            arguments = {},
            pattern = {"vector_disintegration", "bookkeepers_gambit_vv"},
            returns = true
        },
        y = {
            method = false,
            arguments = {},
            pattern = {"vector_disintegration", "bookkeepers_gambit_v-v"},
            returns = true
        },
        z = {
            method = false,
            arguments = {},
            pattern = {"vector_disintegration", "bookkeepers_gambit_vv-"},
            returns = true
        },
        
        eyes = {
            method = false,
            arguments = {},
            pattern = {"compass_purification"},
            returns = true
        },
        feet = {
            method = false,
            arguments = {},
            pattern = {"compass_purification_2"},
            returns = true
        },
        looking = {
            method = false,
            arguments = {},
            pattern = {"alidades_purification"},
            returns = true
        },
        height = {
            method = false,
            arguments = {},
            pattern = {"stadiometers_purification"},
            returns = true
        },
        velocity = {
            method = false,
            arguments = {},
            pattern = {"pace_purification"},
            returns = true
        },

        axis = {
            method = false,
            arguments = {},
            pattern = {"axial_purification"},
            returns = true
        },

        raycast = {
            method = true,
            arguments = {{name = "direction", offset = 0}},
            pattern = {"direction", "archers_distillation"},
            returns = true
        },
        raycast_side = {
            method = true,
            arguments = {{name = "direction", offset = 0}},
            pattern = {"direction", "architects_distillation"},
            returns = true
        },
        raycast_entity = {
            method = true,
            arguments = {{name = "direction", offset = 0}},
            pattern = {"direction", "scouts_distillation"},
            returns = true
        },
        
        get_entity = {
            method = false,
            arguments = {},
            pattern = {"entity_purification"},
            returns = true
        },
        get_animal = {
            method = false,
            arguments = {},
            pattern = {"entity_purification_animal"},
            returns = true
        },
        get_monster = {
            method = false,
            arguments = {},
            pattern = {"entity_purification_monster"},
            returns = true
        },
        get_item = {
            method = false,
            arguments = {},
            pattern = {"entity_purification_item"},
            returns = true
        },
        get_player = {
            method = false,
            arguments = {},
            pattern = {"entity_purification_player"},
            returns = true
        },
        get_living = {
            method = false,
            arguments = {},
            pattern = {"entity_purification_living"},
            returns = true
        },

        nearby_animal = {
            method = true,
            arguments = {{name = "radius", offset = 0}},
            pattern = {"radius", "zone_distillation_animal"},
            returns = true
        },
        nearby_non_animal = {
            method = true,
            arguments = {{name = "radius", offset = 0}},
            pattern = {"radius", "zone_distillation_non_animal"},
            returns = true
        },
        nearby_monster = {
            method = true,
            arguments = {{name = "radius", offset = 0}},
            pattern = {"radius", "zone_distillation_monster"},
            returns = true
        },
        nearby_non_monster = {
            method = true,
            arguments = {{name = "radius", offset = 0}},
            pattern = {"radius", "zone_distillation_mnon_onster"},
            returns = true
        },
        nearby_item = {
            method = true,
            arguments = {{name = "radius", offset = 0}},
            pattern = {"radius", "zone_distillation_item"},
            returns = true
        },
        nearby_non_item = {
            method = true,
            arguments = {{name = "radius", offset = 0}},
            pattern = {"radius", "zone_distillationon_n_item"},
            returns = true
        },
        nearby_player = {
            method = true,
            arguments = {{name = "radius", offset = 0}},
            pattern = {"radius", "zone_distillation_player"},
            returns = true
        },
        nearby_non_player = {
            method = true,
            arguments = {{name = "radius", offset = 0}},
            pattern = {"radius", "zone_distillation_non_player"},
            returns = true
        },
        nearby_living = {
            method = true,
            arguments = {{name = "radius", offset = 0}},
            pattern = {"radius", "zone_distillation_living"},
            returns = true
        },
        nearby_non_living = {
            method = true,
            arguments = {{name = "radius", offset = 0}},
            pattern = {"radius", "zone_distillation_non_living"},
            returns = true
        },
        nearby_any = {
            method = true,
            arguments = {{name = "radius", offset = 0}},
            pattern = {"radius", "zone_distillation_any"},
            returns = true
        },
        
        slice = {
            method = true,
            arguments = {{name = "start", offset = 0}, {name = "stop", offset = 1}},
            pattern = {"start", "stop", "selection_exaltation"},
            returns = true
        },
    }
}