local player   = {}
player.__index = player
player.__type  = "player"

function player.create(name, tags)
  assert(name)
  local p = {
    tags = {},
    name = name
  }

  setmetatable(p, player)
  if type(tags) == "table" then
    p:setTags(tags)
  end
  return p
end

--- Add or modify a set of tags
-- @param t a table
function player:setTags(t)
  assert(type(t) == "table")
  for i, v in pairs(t) do
    self.tags[i] = v
  end
end

--- remove a set of tags
-- @param t a table of the form key = true
function player:removeTags(t)
  assert(type(t) == table)
  for i, _ in pairs(t) do
    self.tags[i] = nil
  end
end

--- Add or modify a tag
-- @param key the key of the tag
-- @param value the value of the tag
function player:setTag(key, value)
  assert(key ~= nil)
  self.tags[key] = value
end

--- Delete a tag
-- @param key the key of the tag
function player:removeTag(key)
  assert(key ~= nil)
  self.tags[key] = nil
end

function player:getName()
  return self.name
end

-- function player:setName(name)
--   self.name = name
-- end

function player:__tostring()
  return self.name
end

return player
