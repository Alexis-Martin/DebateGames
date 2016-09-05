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

--- return the set of attackers
-- @return the set of attackers
function vertex:getAttackers()
  return self.attackers
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
  if xml_tags then
    xml = xml .. ">" .. xml_tags .. "</vertex>"
  else
    xml = xml .. "/>"
  end
  return xml
end

--- Export the vertex into a LaTeX form
-- @param f apply and return the function f. The return must be a string and parameters of f are the vertex itself and the parameter table.By default, if f isn't a function, it return the name of the arg.
-- @param table The extra argument of f.
-- @return a string which contains the Tex form.
function vertex:exportTex(f, table)
  if type(f) == "function" then
    return f(self, table)
  end
  return "$" .. self.name .. "$"
end

--- Define the basic view of a vertex
-- return the name of the vertex
function vertex:__tostring()
  return tostring(self.name)
end

--- Dump an vertex into yaml form
-- @return a string contains the yaml
function vertex:dump()
  return yaml.dump(self)
end

return vertex
