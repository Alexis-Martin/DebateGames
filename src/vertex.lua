--- A vertex is the smallest part of a graph.
-- He add a name, a set of vertices that attack it and a set of vertices that are attack by it.
-- @module vertex
local yaml  = require 'yaml'

local vertex   = {}
vertex.__index = vertex

--- Constructor
-- @param name the name of the vertex.
-- @tags a table of tags you want add to the graph. Possibly nil.
-- @return the vertex
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

--- add an attacked vertex
-- @param v the vertex attacked
function vertex:addAttack(v)
  assert(v)
  self.attacks[v] = true
end

--- add an attacker
-- @param v the vertex attacker
function vertex:addAttacker(v)
  assert(v)
  self.attackers[v] = true
end

--- Remove an attack
-- @param v the attacked vertex to remove
function vertex:removeAttack(v)
  assert(v)
  self.attacks[v] = nil
end

--- Remove an attacker
-- @param v the attacker vertex to remove
function vertex:removeAttacker(v)
  assert(v)
  self.attackers[v] = nil
end

--- Add or modify a set of tags
-- @param t a table
function vertex:setTags(t)
  assert(type(t) == "table")
  for i, v in pairs(t) do
    assert(i ~= "attacks" and i ~= "attackers")
    self[i] = v
  end
end

--- remove a set of tags
-- @param t a table of the form key = true
function vertex:removeTags(t)
  assert(type(t) == table)
  for i, _ in pairs(t) do
    assert(i ~= "attacks" and i ~= "attackers")
    self[i] = nil
  end
end

--- Add or modify a tag
-- @param key the key of the tag
-- @param value the value of the tag
function vertex:setTag(key, value)
  assert(key ~= nil)
  assert(key ~= "attacks" and key ~= "attackers")
  self[key] = value
end

--- Delete a tag
-- @param key the key of the tag
function vertex:removeTag(key)
  assert(key ~= nil)
  assert(key ~= "attacks" and key ~= "attackers")
  self[key] = nil
end

--- Export the graph into an XML form.
-- @param with_tags If with_tags = "all" then all tags will be print else if with_tags is a table then she should be of the form tag = true.
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
      if self[k]          and k ~= "attacks" and
         k ~= "attackers" and k ~= "name"    and
         k ~= "content"   then
        xml = xml .. tostring(k) .. "=\"" .. tostring(v) .. "\" "
      end
    end
  end

  xml = xml .. ((">" .. self.content .. "</vertex>") or "/>")
  return xml
end

--- Export the vertex into a LaTeX form
-- @param with_votes show the votes on the export
-- @param with_lm display the value of the vertex
-- @return a string which contains the Tex form.
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

--- Define the basic view of a vertex
-- return the name of the vertex
function vertex:__tostring()
  return tostring(self.name)
end

-- Dump an vertex into yaml form
-- @return a string contains the yaml
function vertex:dump()
  return yaml.dump(self)
end

return vertex
