local Json = {}

local encode_map = {
    ["\\"] = "\\\\",
    ["\""] = "\\\"",
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
}

local function encode_string(value)
    return "\"" .. value:gsub("[\\\"\b\f\n\r\t]", encode_map) .. "\""
end

local function is_array(tbl)
    local count = 0
    for key in pairs(tbl) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            return false
        end
        count = math.max(count, key)
    end

    for index = 1, count do
        if tbl[index] == nil then
            return false
        end
    end

    return true
end

local function encode_value(value)
    local value_type = type(value)

    if value_type == "nil" then
        return "null"
    end

    if value_type == "boolean" or value_type == "number" then
        return tostring(value)
    end

    if value_type == "string" then
        return encode_string(value)
    end

    if value_type == "table" then
        local parts = {}
        if is_array(value) then
            for index = 1, #value do
                parts[#parts + 1] = encode_value(value[index])
            end
            return "[" .. table.concat(parts, ",") .. "]"
        end

        for key, item in pairs(value) do
            parts[#parts + 1] = encode_string(tostring(key)) .. ":" .. encode_value(item)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end

    error("unsupported JSON type: " .. value_type)
end

function Json.encode(value)
    return encode_value(value)
end

local function decode_error(text, index, message)
    error(string.format("JSON decode error at %d: %s near '%s'", index, message, text:sub(index, index + 12)))
end

local function skip_whitespace(text, index)
    while true do
        local char = text:sub(index, index)
        if char == "" then
            return index
        end
        if char ~= " " and char ~= "\n" and char ~= "\r" and char ~= "\t" then
            return index
        end
        index = index + 1
    end
end

local parse_value

local function parse_string(text, index)
    index = index + 1
    local parts = {}

    while true do
        local char = text:sub(index, index)
        if char == "" then
            decode_error(text, index, "unterminated string")
        end

        if char == "\"" then
            return table.concat(parts), index + 1
        end

        if char == "\\" then
            local escaped = text:sub(index + 1, index + 1)
            local map = {
                ["\""] = "\"",
                ["\\"] = "\\",
                ["/"] = "/",
                b = "\b",
                f = "\f",
                n = "\n",
                r = "\r",
                t = "\t",
            }

            if escaped == "u" then
                local hex = text:sub(index + 2, index + 5)
                if not hex:match("^%x%x%x%x$") then
                    decode_error(text, index, "invalid unicode escape")
                end
                local codepoint = tonumber(hex, 16)
                if codepoint < 128 then
                    parts[#parts + 1] = string.char(codepoint)
                else
                    local ok, utf8lib = pcall(require, "utf8")
                    if ok and utf8lib and utf8lib.char then
                        parts[#parts + 1] = utf8lib.char(codepoint)
                    else
                        parts[#parts + 1] = "?"
                    end
                end
                index = index + 6
            else
                if not map[escaped] then
                    decode_error(text, index, "invalid escape sequence")
                end
                parts[#parts + 1] = map[escaped]
                index = index + 2
            end
        else
            parts[#parts + 1] = char
            index = index + 1
        end
    end
end

local function parse_number(text, index)
    local start_index = index
    local pattern = "^%-?%d+%.?%d*[eE]?[+%-]?%d*"
    local slice = text:sub(index)
    local matched = slice:match(pattern)
    if not matched or matched == "" then
        decode_error(text, index, "invalid number")
    end

    local number = tonumber(matched)
    if not number then
        decode_error(text, index, "invalid numeric value")
    end

    return number, start_index + #matched
end

local function parse_literal(text, index, literal, value)
    if text:sub(index, index + #literal - 1) ~= literal then
        decode_error(text, index, "invalid literal")
    end
    return value, index + #literal
end

local function parse_array(text, index)
    local result = {}
    index = skip_whitespace(text, index + 1)

    if text:sub(index, index) == "]" then
        return result, index + 1
    end

    while true do
        local value
        value, index = parse_value(text, index)
        result[#result + 1] = value
        index = skip_whitespace(text, index)

        local char = text:sub(index, index)
        if char == "]" then
            return result, index + 1
        end
        if char ~= "," then
            decode_error(text, index, "expected ',' or ']'")
        end
        index = skip_whitespace(text, index + 1)
    end
end

local function parse_object(text, index)
    local result = {}
    index = skip_whitespace(text, index + 1)

    if text:sub(index, index) == "}" then
        return result, index + 1
    end

    while true do
        if text:sub(index, index) ~= "\"" then
            decode_error(text, index, "expected string key")
        end

        local key
        key, index = parse_string(text, index)
        index = skip_whitespace(text, index)
        if text:sub(index, index) ~= ":" then
            decode_error(text, index, "expected ':'")
        end

        local value
        value, index = parse_value(text, skip_whitespace(text, index + 1))
        result[key] = value
        index = skip_whitespace(text, index)

        local char = text:sub(index, index)
        if char == "}" then
            return result, index + 1
        end
        if char ~= "," then
            decode_error(text, index, "expected ',' or '}'")
        end
        index = skip_whitespace(text, index + 1)
    end
end

parse_value = function(text, index)
    index = skip_whitespace(text, index)
    local char = text:sub(index, index)

    if char == "\"" then
        return parse_string(text, index)
    end
    if char == "{" then
        return parse_object(text, index)
    end
    if char == "[" then
        return parse_array(text, index)
    end
    if char == "-" or char:match("%d") then
        return parse_number(text, index)
    end
    if char == "t" then
        return parse_literal(text, index, "true", true)
    end
    if char == "f" then
        return parse_literal(text, index, "false", false)
    end
    if char == "n" then
        return parse_literal(text, index, "null", nil)
    end

    decode_error(text, index, "unexpected character")
end

function Json.decode(text)
    local value, index = parse_value(text, 1)
    index = skip_whitespace(text, index)
    if index <= #text then
        decode_error(text, index, "trailing characters")
    end
    return value
end

return Json
