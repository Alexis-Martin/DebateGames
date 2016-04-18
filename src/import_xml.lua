local xml  = require "xml"
local data = xml.loadpath("arbre1.xml")

local game = {
  graphs = {},
  players = data.players
}

-- transform general graph and players graphs
for _, g in pairs(data) do
  if type(g) == "table" then
    game.graphs[g.view] = {
      type      = g.xml,
      view      = g.view,
      vertices  = {},
      edges     = {},
      addVertex = function (graph, name, str_content, n_likes, n_dislikes, other_tags)
        graph.vertices[name] = {
          attack    = {},
          attackers = {},
          content   = str_content or nil,
          likes     = n_likes or 0,
          dislikes  = n_dislikes or 0
        }
        if type(other_tags) == "table" then
          for k,v in pairs(other_tags) do
            graph.vertices[name][k] = v
          end
        end

        return graph.vertices[name]
      end,
    }

    local graph = game.graphs[g.view]
    local n_edge = 1

    for _, v in pairs(g) do
      if type(v) == 'table' and v.xml == 'vertex' and graph.vertices[v.name] == nil then
          graph.addVertex(graph, v.name, v[1], v.likes, v.dislikes, {tag = v.tag})
      end

      if type(v) == "table" and v.xml == "edge" then
        graph.edges[n_edge] = { source = v.source, target = v.target }

        if graph.vertices[v.source] == nil then
          graph.addVertex(graph, v.name, v[1], v.likes, v.dislikes, {tag = v.tag})
        end
        if graph.vertices[v.target] == nil then
          graph.addVertex(graph, v.name, v[1], v.likes, v.dislikes, {tag = v.tag})
        end

        local att = graph.vertices[v.source]
        att.attack[v.target] = true

        local att2 = graph.vertices[v.target]
        att2.attackers[v.source] = true

        n_edge = n_edge + 1
      end
    end
  end
end

local function deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[deepcopy(orig_key)] = deepcopy(orig_value)
    end
    setmetatable(copy, deepcopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

local function addDistinct(table_1, table_2, apply)
  for k, v in pairs(table_2) do
    if table_1[k] == nil then
      table_1[k] = deepcopy(v)
      if type(apply) == 'function' then
        apply(table_1[k])
      end
    end
  end
end

for _, graph in pairs(game.graphs) do
  if graph.view ~= 'general' then
    for k, v in pairs(graph) do
      if k == 'vertices' then
        for k1, v1 in pairs(v) do
          addDistinct(v1.attack, game.graphs.general.vertices[k1].attack)
          addDistinct(v1.attackers, game.graphs.general.vertices[k1].attackers)
        end
      end
      if type(v) == 'table' then
          addDistinct(v, game.graphs.general[k])
      end
    end
  end
end
game.print_table = nil
game.print_table = function (t, tab)
  if tab == nil then tab = 0 end
  local tabs = ""
  if tab > 0 then
    for _ = 1, tab do
      tabs = tabs .. "\t"
    end
  end

  for k, v in pairs(t) do
    if type(v) == "table" then
      print(tabs .. k .. " = {")
      game.print_table(v, tab + 1)
      print(tabs .. "}")
    elseif type(v) == "function" then
      print(tabs .. k .. " = function")
    else
      print(tabs .. k .. " = " .. tostring(v))
    end
  end
end

-- game.print_table(game)

return game
