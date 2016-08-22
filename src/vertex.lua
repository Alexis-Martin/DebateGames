local yaml  = require 'yaml'

local vertex   = {}
vertex.__index = vertex

-- constructor
function vertex.create(name, tags)
  assert(name)
  local v = {
    attacks   = {},
    attackers = {}
  }
  setmetatable(v, vertex)
  if type(tags) == "table" then
    v:setTags(tags)
  end
  v.name = name
  return v
end


function vertex:addAttack(v)
  assert(v)
  self.attacks[v] = true
end

function vertex:addAttacker(v)
  assert(v)
  self.attackers[v] = true
end

function vertex:removeAttack(v)
  assert(v)
  self.attacks[v] = nil
end

function vertex:removeAttacker(v)
  assert(v)
  self.attackers[v] = nil
end

function vertex:setTags(t)
  assert(type(t) == "table")
  for i, v in pairs(t) do
    assert(i ~= "attacks" and i ~= "attackers")
    self[i] = v
  end
end

function vertex:removeTags(t)
  assert(type(t) == table)
  for i, _ in pairs(t) do
    assert(i ~= "attacks" and i ~= "attackers")
    self[i] = nil
  end
end

function vertex:setTag(key, value)
  assert(key ~= nil)
  assert(key ~= "attacks" and key ~= "attackers")
  self[key] = value
end

function vertex:removeTag(key)
  assert(key ~= nil)
  assert(key ~= "attacks" and key ~= "attackers")
  self[key] = nil
end

-- export_xml export the vertex in a XML form.
-- @param with_tags it's a table of tags that are export.
-- If you want to export the tag 'class' write class = true.
-- If you want to export all the tags you can just write "all" in place of the table.
-- @return A string with the xml output.
function vertex:exportXml(with_tags)
  local xml = "<vertex name=\"" .. tostring(self.name) .. "\" "

  if with_tags == "all" then
    for k, v in pairs(self) do
      if k ~= "attacks"   and k ~= "attackers" and
         k ~= "name"      and k ~= "content"   then
        xml = xml .. tostring(k) .. "=\"" .. tostring(v) .. "\" "
      end
    end
  elseif type(with_tags) == "table" then
    for k, v in pairs(with_tags) do
      if self[k] then
        xml = xml .. tostring(k) .. "=\"" .. tostring(v) .. "\" "
      end
    end
  end

  xml = xml .. ((">" .. self.content .. "</vertex>") or "/>")
  return xml
end

function vertex:exportTex(with_votes, with_lm)
  local tex = "\"$" .. self.name .. "$"
  if with_votes then
    tex = tex .. "\\\\ (" .. (self.likes or 0) .. ","
              .. (self.dislikes or 0) .. ")"
  end
  if with_lm then
    tex = tex .. "\\\\ lm = " .. (self.LM[#self.LM].value or "unknown")
  end
  tex = tex .. "\""
  return tex
end

function vertex:__tostring()
  return tostring(self.name)
end

function vertex:dump()
  return yaml.dump(self)
end

return vertex
-- do
--   local v = vertex.create("a")
--   v:addAttack("b")
--   print(v)
--
-- end
