local args = {...}
local tokeniser = require("tokeniser")
local parser = require("parser")
local compiler = require("compiler")
local table_to_json = require("table_to_json")




local file = io.open("numbers.hex")

local tokenised_ok, tokens, tokenised_msg = tokeniser.tokenise(file:read("a"))
if not tokenised_ok then
    print("error tokenising:\n"..tokenised_msg)
    return
end
local token_file = io.open("tokens.json", "w")
token_file:write(table_to_json(tokens))
token_file:close()

local parsed_ok, structure, parsed_msg = parser.parse(tokens)
if not parsed_ok then
    print("error parsing:\n"..parsed_msg)
    return
end
local structure_file = io.open("structure.json", "w")
structure_file:write(table_to_json(structure))
structure_file:close()

local compiled_ok, pattern, compiled_msg = compiler.compile(structure, {}, 0)
if not compiled_ok then
    print("error compiling:\n"..compiled_msg)
    return
end
local pattern_file = io.open("pattern.json", "w")
pattern_file:write(table_to_json(pattern))