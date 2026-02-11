-- Minimal JSON decoder for SketchyBar
local json = {}

local function skip_ws(s, i)
  return s:match("^%s*()", i)
end

local function decode_string(s, i)
  -- skip opening quote
  i = i + 1
  local parts = {}
  while i <= #s do
    local c = s:sub(i, i)
    if c == '"' then
      return table.concat(parts), i + 1
    elseif c == '\\' then
      i = i + 1
      local esc = s:sub(i, i)
      if esc == '"' or esc == '\\' or esc == '/' then
        parts[#parts + 1] = esc
      elseif esc == 'n' then parts[#parts + 1] = '\n'
      elseif esc == 't' then parts[#parts + 1] = '\t'
      elseif esc == 'r' then parts[#parts + 1] = '\r'
      elseif esc == 'u' then
        -- basic \uXXXX — skip surrogate handling, just insert replacement
        local hex = s:sub(i + 1, i + 4)
        local code = tonumber(hex, 16)
        if code and code < 128 then
          parts[#parts + 1] = string.char(code)
        else
          parts[#parts + 1] = "?"
        end
        i = i + 4
      end
      i = i + 1
    else
      parts[#parts + 1] = c
      i = i + 1
    end
  end
  error("unterminated string")
end

local decode_value -- forward declaration

local function decode_array(s, i)
  i = i + 1 -- skip [
  local arr = {}
  i = skip_ws(s, i)
  if s:sub(i, i) == ']' then return arr, i + 1 end
  while true do
    local val
    val, i = decode_value(s, i)
    arr[#arr + 1] = val
    i = skip_ws(s, i)
    local c = s:sub(i, i)
    if c == ']' then return arr, i + 1 end
    if c == ',' then i = skip_ws(s, i + 1) end
  end
end

local function decode_object(s, i)
  i = i + 1 -- skip {
  local obj = {}
  i = skip_ws(s, i)
  if s:sub(i, i) == '}' then return obj, i + 1 end
  while true do
    local key, val
    key, i = decode_string(s, i)
    i = skip_ws(s, i)
    i = i + 1 -- skip :
    i = skip_ws(s, i)
    val, i = decode_value(s, i)
    obj[key] = val
    i = skip_ws(s, i)
    local c = s:sub(i, i)
    if c == '}' then return obj, i + 1 end
    if c == ',' then i = skip_ws(s, i + 1) end
  end
end

decode_value = function(s, i)
  i = skip_ws(s, i)
  local c = s:sub(i, i)
  if c == '"' then return decode_string(s, i)
  elseif c == '{' then return decode_object(s, i)
  elseif c == '[' then return decode_array(s, i)
  elseif c == 't' then return true, i + 4
  elseif c == 'f' then return false, i + 5
  elseif c == 'n' then return nil, i + 4
  else
    local num_str = s:match("^-?%d+%.?%d*[eE]?[+-]?%d*", i)
    return tonumber(num_str), i + #num_str
  end
end

function json.decode(s)
  local val, _ = decode_value(s, 1)
  return val
end

return json
