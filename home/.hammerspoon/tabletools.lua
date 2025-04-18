-- tabletools.lua: Utility functions for working with tables
-- Based on code from http://lua-users.org/wiki/TableSerialization
-- with improvements for readability and performance

-- Format tables with cycles recursively to any depth
-- Returns a string representation of the table
-- References to other tables are shown as values
-- Self references are indicated
function table.show(t, name, indent)
  local cart = ""    -- Table for storing serialized results
  local autoref = "" -- For storing self references

  -- Returns true if the table is empty
  local function isemptytable(t) 
    return next(t) == nil 
  end

  -- Serializes primitive types
  local function basicSerialize(o)
    local so = tostring(o)
    if type(o) == "function" then
      local info = debug.getinfo(o, "S")
      if info.what == "C" then
        return string.format("%q", so .. ", C function")
      else
        return string.format("%q", so .. ", defined in (" ..
          info.linedefined .. "-" .. info.lastlinedefined ..
          ")" .. info.source)
      end
    elseif type(o) == "number" or type(o) == "boolean" then
      return so
    else
      return string.format("%q", so)
    end
  end

  -- Add an item to the serialization cart
  local function addtocart(value, name, indent, saved, field)
    indent = indent or ""
    saved = saved or {}
    field = field or name

    cart = cart .. indent .. field

    if type(value) ~= "table" then
      cart = cart .. " = " .. basicSerialize(value) .. ";\n"
    else
      if saved[value] then
        cart = cart .. " = {}; -- " .. saved[value]
                   .. " (self reference)\n"
        autoref = autoref ..  name .. " = " .. saved[value] .. ";\n"
      else
        saved[value] = name
        if isemptytable(value) then
          cart = cart .. " = {};\n"
        else
          cart = cart .. " = {\n"
          for k, v in pairs(value) do
            k = basicSerialize(k)
            local fname = string.format("%s[%s]", name, k)
            field = string.format("[%s]", k)
            addtocart(v, fname, indent .. "   ", saved, field)
          end
          cart = cart .. indent .. "};\n"
        end
      end
    end
  end

  name = name or "__unnamed__"
  if type(t) ~= "table" then
    return name .. " = " .. basicSerialize(t)
  end
  cart, autoref = "", ""
  addtocart(t, name, indent)
  return cart .. autoref
end