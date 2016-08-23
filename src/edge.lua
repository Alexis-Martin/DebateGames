local yaml  = require 'yaml'

local edge   = {}
edge.__index = edge

-- TODO ajouter getSource et getTarget
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

function edge:setTags(t)
  assert(type(t) == "table")
  for i, v in pairs(t) do
    assert(i ~= "source" and i ~= "target")
    self[i] = v
  end
end

function edge:removeTags(t)
  assert(type(t) == table)
  for i, _ in pairs(t) do
    assert(i ~= "source" and i ~= "target")
    self[i] = nil
  end
end

function edge:setTag(key, value)
  assert(key ~= nil)
  assert(key ~= "source" and key ~= "target")
  self[key] = value
end

function edge:removeTag(key)
  assert(key ~= nil)
  assert(key ~= "source" and key ~= "target")
  self[key] = nil
end

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

function edge:__tostring()
  return "(" .. tostring(self.source) .. ", " .. tostring(self.target) .. ")"
end

function edge:dump()
  return yaml.dump(self)
end


return edge
