--- An edge join too vertices, it more an arc in this definition because an edge have a source and a target.
-- Source and target are both vertices, w.r.t. the vertex definition.
--@module edge
local yaml  = require 'yaml'

local edge   = {}
edge.__index = edge

--- Constructor
-- @param source the vertex source.
-- @param target the vertex target.
-- @param tags Some optionnal tags for the edge.
-- @return the edge
function edge.create(source, target, tags)
  assert(source and target)
  local e = {
    source = source,
    target = target
  }
  setmetatable(e, edge)
  if type(tags) == "table" then
    e:setTags(tags)
  end
  return e
end

--- Get the source
-- @return the source
function edge:getSource()
  return self.source
end

--- Get the target
-- @return the target
function edge:getTarget()
  return self.target
end

--- Add or modify a set of tags
-- @param t a table
function edge:setTags(t)
  assert(type(t) == "table")
  for i, v in pairs(t) do
    assert(i ~= "source" and i ~= "target")
    self[i] = v
  end
end

--- remove a set of tags
-- @param t a table of the form key = true
function edge:removeTags(t)
  assert(type(t) == table)
  for i, _ in pairs(t) do
    assert(i ~= "source" and i ~= "target")
    self[i] = nil
  end
end

--- Add or modify a tag
-- @param key the key of the tag
-- @param value the value of the tag
function edge:setTag(key, value)
  assert(key ~= nil)
  assert(key ~= "source" and key ~= "target")
  self[key] = value
end

--- Delete a tag
-- @param key the key of the tag
function edge:removeTag(key)
  assert(key ~= nil)
  assert(key ~= "source" and key ~= "target")
  self[key] = nil
end

--- Export the edge into an XML form.
-- @param with_tags If with_tags = "all" then all tags will be print else if with_tags is a table then she should be of the form tag = true.
-- @return a string which contains the result.
function edge:exportXml(with_tags)
  local xml = "<edge source=\"" .. tostring(self.source) .. "\""
              .. " target=\"" .. tostring(self.target) .. "\""

  if with_tags == "all" then
    for k, v in pairs(self) do
      if k ~= "source" and k ~= "target" then
        xml = xml .. tostring(k) .. "=\"" .. tostring(v) .. "\" "
      end
    end
  elseif type(with_tags) == "table" then
    for k, v in pairs(with_tags) do
      if self[k] and k ~= "source" and k ~= "target" then
        xml = xml .. tostring(k) .. "=\"" .. tostring(v) .. "\" "
      end
    end
  end
  xml = xml .. "/>"
  return xml
end

--- Export the edge into a LaTeX form
-- @param with_vertex_votes If it true the votes are display
-- @param with_vertex_lm If it true the value is display
-- @return the edge in TeX form.
function edge:exportTex(with_vertex_votes, with_vertex_lm)
  local tex = ""
  if type(self.source)           == table and
     type(self.source.exportTex) == "function" then
    tex = tex .. self.source:exportTex(with_vertex_votes, with_vertex_lm)
  else
      tex = tex .. "\"$" .. tostring(self.source) .. "$\""
  end

  tex = tex .. " -> "

  if type(self.target)           == table and
     type(self.target.exportTex) == "function" then
    tex = tex .. self.target:exportTex(with_vertex_votes, with_vertex_lm)
  else
      tex = tex .. "\"$" .. tostring(self.target) .. "$\""
  end

  tex = tex .. ";"
  return tex
end

--- Define the basic view of an edge
-- return a string of the form (source, target)
function edge:__tostring()
  return "(" .. tostring(self.source) .. ", " .. tostring(self.target) .. ")"
end

-- Dump an edge into yaml form
-- @return a string contains the yaml
function edge:dump()
  return yaml.dump(self)
end

return edge
