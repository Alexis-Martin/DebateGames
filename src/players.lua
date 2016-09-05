local player = require "player"

local players   = { __n = 0 }
players.__index = players
players.__type  = "players"

function players.create()
  local ps = {}
  setmetatable(ps, players)
  return ps
end

function players.__len(_)
  return players.__n
end

function players:__next(k)
  if players.__order then
    local i
    if k then i = players.__reverse_order[k] else i = 0 end
    if i + 1 > #players.__order then return nil end
    return players.__order[i + 1], self[players.__order[i + 1]]
  end
  return next(self, k)
end

function players:__pairs()
  return players.__next, self, nil
end

function players:newPlayer(name, tags)
  assert(name)
  if not self[name] then
    self[name]  = player.create(name, tags)
    players.__n = players.__n + 1
    if players.__order then
      table.insert(players.__order, name)
      players.__reverse_order[name] = #players.__order
    end
  end
end

function players:setOrder(table)
  if not table then
    players.__order         = nil
    players.__reverse_order = nil
    return
  end
  assert(type(table) == "table")
  players.__order         = {}
  players.__reverse_order = {}
  for i, v in ipairs(table) do
    if self[v] then
      players.__order[i]         = v
      players.__reverse_order[v] = i
    end
  end
end

function players:removePlayer(name)
  if self[name] then
    self[name] = nil
    players.__n      = players.__n - 1
    if players.__order then
      table.remove(players.__order, players.__reverse_order[name])
      for i, v in ipairs(players.__order) do
        players.__reverse_order[v] = i
      end
    end
  end
end

function players:getNames()
  local names = {}
  for k, _ in pairs(self) do
    table.insert(names, k)
  end
  return names
end
--
-- do
--   local proxy = players.create()
--   proxy:newPlayer("p1")
--   proxy:newPlayer("p2")
--   print("before")
--   for k,v in pairs(proxy) do
--     print(k, v)
--   end
--   proxy:setOrder{"p1", "p2", "p4"}
--   print("after")
--   for k,v in pairs(proxy) do
--     print(k, v)
--   end
--   proxy:newPlayer("p3")
--   print("add")
--   for k,v in pairs(proxy) do
--     print(k, v)
--   end
--   proxy:removePlayer("p1")
--   print("remove")
--   for k,v in pairs(proxy) do
--     print(k, v)
--   end
--   proxy:setOrder(nil)
--   print('order nil')
--   for k,v in pairs(proxy) do
--     print(k, v)
--   end
-- end


return players
