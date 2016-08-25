--- A vertex is the smallest part of a graph.
-- He add a name, a set of vertices that attack it and a set of vertices that are attack by it.
-- @module vertex
local yaml  = require 'yaml'
local tools = require 'tools'

local vertex   = {}
vertex.__index = vertex
vertex.__type  = "vertex"
--- Constructor
-- @param name the name of the vertex.
-- @tags a table of tags you want add to the graph. Possibly nil.
-- @return the vertex
function vertex.create(name, tags)
  assert(name)
  local v = {
    attacks   = {},
    attackers = {},
    tags      = {}
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
    self.tags[i] = v
  end
end

--- Get all tags
-- @return The table of tags
function vertex:getTags()
  return self.tags
end

--- remove a set of tags
-- @param t a table of the form key = true
function vertex:removeTags(t)
  assert(type(t) == table)
  for _, v in ipairs(t) do
    self.tags[v] = nil
  end
end

--- Add or modify a tag
-- @param key the key of the tag
-- @param value the value of the tag
function vertex:setTag(key, value)
  assert(key ~= nil)
  self.tags[key] = value
end

--- Get the value of a tag
-- @param key The key of the tag
-- @return The value
function vertex:getTag(key)
  return self.tags[key]
end

--- Delete a tag
-- @param key the key of the tag
function vertex:removeTag(key)
  assert(key ~= nil)
  self.tags[key] = nil
end

--- Export the graph into an XML form.
-- @param with_tags If with_tags = "all" then all tags will be print else if with_tags must be a table
-- @return A string with the xml output.
function vertex:exportXml(with_tags)
  local xml = "<vertex name=\"" .. tostring(self.name) .. "\""
  local xml_tags = nil

  if with_tags == "all" then
    for k, v in pairs(self.tags) do
      if type(v) == "table" then
        xml_tags = (xml_tags or nil) .. tools.exportXmlTable(k, v)
      else
        xml = xml .. " " .. tostring(k) .. "=\"" .. tostring(v) .. "\""
      end
    end
  elseif type(with_tags) == "table" then
    for _, v in ipairs(with_tags) do
      if type(self.tags[v]) == "table" then
        xml_tags = (xml_tags or nil) .. tools.exportXmlTable(v, self.tags[v])
      elseif self.tags[v] then
        xml = xml .. " " .. tostring(v) .. "=\"" .. tostring(self.tags[v]) .. "\""
      end
    end
  end

  xml = xml .. ((">" .. xml_tags .. "</vertex>") or "/>")
  return xml
end

--- Export the vertex into a LaTeX form
-- @param with_votes show the votes on the export
-- @param with_lm display the value of the vertex
-- @return a string which contains the Tex form.
function vertex:exportTex(with_votes, with_lm)
  local tex = "\"$" .. self.name .. "$"
  if with_votes then
    tex = tex .. "\\\\ (" .. (self.tags.likes or 0) .. ","
              .. (self.tags.dislikes or 0) .. ")"
  end
  if with_lm then
    tex = tex .. "\\\\ lm = " .. (self.tags.LM[#self.tags.LM].value or "unknown")
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
