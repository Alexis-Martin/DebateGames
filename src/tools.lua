local tools = {}
local_random_seed = false

rawtype = type

type = function ( var )
  local _m = getmetatable(var);
  if _m and _m.__type then
   return _m.__type;
  end
  return rawtype(var);
 end

function tools.randomseed()
  if not local_random_seed then
    math.randomseed(os.time())
    local_random_seed = true
  end
end

function tools.deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[tools.deepcopy(orig_key)] = tools.deepcopy(orig_value)
    end
    setmetatable(copy, tools.deepcopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

function tools.equals(o1, o2, ignore_mt)
  if o1 == o2 then return true end

  local o1Type = type(o1)
  local o2Type = type(o2)

  if o1Type ~= o2Type then return false end
  if o1Type ~= 'table' then return false end

  if not ignore_mt then
    local mt1 = getmetatable(o1)
    if mt1 and mt1.__eq then
      --compare using built in method
      return o1 == o2
    end
  end

  local keySet = {}

  for key1, value1 in pairs(o1) do
    local value2 = o2[key1]
    if value2 == nil or tools.equals(value1, value2, ignore_mt) == false then
      return false
    end
    keySet[key1] = true
  end

  for key2, _ in pairs(o2) do
    if not keySet[key2] then return false end
  end
  return true
end

function tools.split(str, del)
  local s = {}
  for k1 in string.gmatch(str, del) do
    table.insert(s, k1)
  end
  return s
end

function tools.round(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

function tools.exportXmlTable(key, table)
  local function iter(k, t)
    local xml = "\n<" .. tostring(k)
    local xml_table
    for k1, v in pairs(t) do
      if type(v) == "table" then
        xml_table = (xml_table or "") .. iter(k1, v)
      else
        xml = xml .. " " .. tostring(k1) .."=\"" .. tostring(v) .. "\""
      end
    end

    xml = xml .. ((">\n" .. xml_table .. "\n</" .. tostring(k) .. ">") or "/>")
    return xml
  end
  return iter(key, table)
end
return tools
