--- An edge join too vertices, it more an arc in this definition because an edge have a source and a target.
-- Source and target are both vertices, w.r.t. the vertex definition.
--@module edge
local yaml  = require 'yaml'
local tools = require 'tools'

local edge   = {}
edge.__index = edge
edge.__type  = "edge"
--- Constructor
-- @param source the vertex source.
-- @param target the vertex target.
-- @param tags Some optionnal tags for the edge.
-- @return the edge
function edge.create(source, target, tags)
  assert(source and target)
  local e = {
    source = source,
    target = target,
    tags   = {}
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
    self.tags[i] = v
  end
end

--- Get all tags
--@return the table of tags
function edge:getTags()
  return self.tags
end

--- remove a set of tags
-- @param t a table of the form key = true
function edge:removeTags(t)
  assert(type(t) == table)
  for _, v in ipairs(t) do
    assert(v ~= "source" and v ~= "target")
    self[v] = nil
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

--- Get the value of a tag
-- @param key The key of the tag
-- @return the value of the tag
function edge:getTag(key)
  return self.tags[key]
end

--- Delete a tag
-- @param key the key of the tag
function edge:removeTag(key)
  assert(key ~= nil)
  assert(key ~= "source" and key ~= "target")
  self[key] = nil
end

--- Export the edge into an XML form.
-- @param with_tags If with_tags = "all" then all tags will be print else if with_tags must be a table.
-- @return a string which contains the result.
function edge:exportXml(with_tags)
  local xml = "<edge source=\"" .. tostring(self.source) .. "\""
              .. " target=\"" .. tostring(self.target) .. "\""
  local xml_tags

  if with_tags == "all" then
    for k, v in pairs(self.tags) do
      if type(v) == "table" then
        xml_tags = (xml_tags or "") .. tools.exportXmlTable(k, v)
      else
        xml = xml ..' ' .. tostring(k) .. "=\"" .. tostring(v) .. "\""
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

--- Export the edge into a LaTeX form
-- @param f apply and return the function f. The return must be a string and parameters of f are the edge itself, the parameter table and vertex_table. By default, if f isn't a function, it return the basic definition of edges in luaLatex and for each vertex it apply with vertex_table.
-- @param table The extra argument of f.
-- @param vertex_table it's a list with two parameters. The first one is the function apply to each vertex, and the second is the table's parameter of the function. If it's nil, it apply the default function of vertex.
-- @return a string which contains the Tex form.
function edge:exportTex(f, table, vertex_table)
  if type(f) == "function" then return f(self, table, vertex_table) end

  local tex = ""
  tex = tex .. "\"$" .. self.source:exportTex(vertex_table[1], vertex_table[2]) .. "$\""
  tex = tex .. " -> "
  tex = tex .. "\"$" .. self.source:exportTex(vertex_table[1], vertex_table[2]) .. "$\""
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
