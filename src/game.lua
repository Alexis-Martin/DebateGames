local gp   = require 'gnuplot'
local yaml = require 'yaml'
local saa  = require "saa"

local function create_game(players, graph)
  local game = {
    graphs = {
      general = graph
    },
    players = players
  }

  game.print_game  = function(self)
    print(yaml.dump(self))
  end

  game.restoreGame = function()
    for _, v in pairs(game.graphs.general.vertices) do
      v.likes    = 0
      v.dislikes = 0
      v.LM       = nil
    end
    game.graphs.general.LM = nil
    for _,p in ipairs(players) do
      game.graphs[p].LM = nil
      for _, v in pairs(game.graphs[p].vertices) do
        v.LM = nil
      end
    end
    game.changed         = nil
    game.rounds          = nil
    game.pass            = nil
    game.mean            = nil
    game.aggregate_value = nil
    game.strongest_shot  = nil
    game.weakest_shot    = nil
  end

  game.setDislikes = function(player, arg, nb)
    if not player or not game.graphs[player] then
      player = "general"
    end
    game.graphs[player].vertices[arg].dislikes = nb
    return game.graphs[player].vertices[arg].dislikes
  end

  game.setLikes = function(player, arg, nb)
    if not player or not game.graphs[player] then
      player = "general"
    end
    game.graphs[player].vertices[arg].likes = nb
    return game.graphs[player].vertices[arg].likes
  end

  game.addDislike = function(player, arg)
    if not player or not game.graphs[player] then
      player = "general"
    end

    if not game.graphs[player].vertices[arg].dislikes then
      game.graphs[player].vertices[arg].dislikes = 0
    end

    game.graphs[player].vertices[arg].dislikes = game.graphs[player].vertices[arg].dislikes + 1
    return game.graphs[player].vertices[arg].dislikes
  end

  game.addLike = function(player, arg)
    if not player or not game.graphs[player] then
      player = "general"
    end

    if not game.graphs[player].vertices[arg].likes then
      game.graphs[player].vertices[arg].likes = 0
    end

    game.graphs[player].vertices[arg].likes = game.graphs[player].vertices[arg].likes + 1
    return game.graphs[player].vertices[arg].likes
  end

  game.removeDislike = function(player, arg)
    if not player or not game.graphs[player] then
      player = "general"
    end

    if not game.graphs[player].vertices[arg].dislikes then
      game.graphs[player].vertices[arg].dislikes = 0
    end
    if game.graphs[player].vertices[arg].dislikes ~= 0 then
      game.graphs[player].vertices[arg].dislikes = game.graphs[player].vertices[arg].dislikes - 1
    end
    return game.graphs[player].vertices[arg].dislikes
  end

  game.removeLike = function(player, arg)
    if not player or not game.graphs[player] then
      player = "general"
    end

    if not game.graphs[player].vertices[arg].likes then
      game.graphs[player].vertices[arg].likes = 0
    end
    if game.graphs[player].vertices[arg].likes ~= 0 then
      game.graphs[player].vertices[arg].likes = game.graphs[player].vertices[arg].likes - 1
    end
    return game.graphs[player].vertices[arg].likes
  end

  game.plot = function(output, open, option)
    local list_players = {}
    for _, player in ipairs(players) do
      table.insert(list_players, player)
    end
    table.insert(list_players, "general")
    table.insert(list_players, "moyenne")

    local agg = 0
    if game.aggregate_value then
      table.insert(list_players, "aggregation")
      agg = 1
    end

    local values         = {}
    local using          = {}
    local players_title  = {}

    values[1] = {}
    table.insert(using, 1)
    for i = 2, #list_players + 1 do
      values[i] = {}
      table.insert(using, i)
      table.insert(players_title, list_players[i-1])
    end

    local mean = 0
    for i = 1, #list_players - agg - 2 do
      mean = mean + game.graphs[list_players[i]].LM[1].value
    end
    mean = mean / (#list_players - agg - 2)
    for i = 0, #game.graphs.general.LM-1 do
      table.insert(values[1], i)
      for p = 2, #list_players - agg do
        if list_players[p-1] == "general" then
          table.insert(values[p], game.graphs[list_players[p-1]].LM[i+1].value)
        else
          table.insert(values[p], game.graphs[list_players[p-1]].LM[1].value)
        end
      end
      table.insert(values[#values - agg], mean)
      if game.aggregate_value then table.insert(values[#values], game.aggregate_value) end
    end
    option  = option or {}
    local g = gp{
        -- all optional, with sane defaults
        width  = option.width  or 640,
        height = option.height or 480,
        xlabel = option.xlabel or "X axis",
        ylabel = option.ylabel or "Y axis",
        key    = option.key    or "top left",
        title  = option.title  or nil,
        consts = {
            gamma = 2.5
        },

        data = {
            gp.array {values, title = players_title, using = using, with  = 'linespoints'},
        }
    }

    g:plot(output, open)

  end

  local deepcopy
  deepcopy = function (orig)
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

  game.graphs.general.view = "general"

  game.aggregationValue = function(fun, epsilon, val_question, precision)
    local graph = deepcopy(game.graphs.general)
    for _, v in pairs(graph.vertices) do
      v.likes    = 0
      v.dislikes = 0
    end
    for _, player in ipairs(game.players) do
      for k,v in pairs(game.graphs[player].vertices) do
        graph.vertices[k].likes    = graph.vertices[k].likes + (v.likes or 0)
        graph.vertices[k].dislikes = graph.vertices[k].dislikes + (v.dislikes or 0)
      end
    end
    game.aggregate_value = saa.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)
  end

  game.meanValue = function(fun, epsilon, val_question, precision)
    game.mean_value = 0
    for k, p in pairs(game.graphs) do
      if k ~= "general" then
        assert(type(p.LM) == "table")
        game.mean_value = game.mean_value + p.LM[1].value
      end
    end

    game.mean_value = game.mean_value / #game.players

  end

  game.strongest_move = function(fun, epsilon, val_question, precision)
    local graph = deepcopy(game.graphs.general)
    for _, v in pairs(graph.vertices) do
      v.likes    = 0
      v.dislikes = 0
    end
    local strongest_lm = saa.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)
    local start_lm     = strongest_lm

    for k, _ in pairs(graph.vertices.q.attackers) do
      graph.vertices[k].dislikes = 1
      local temp_lm = saa.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)
      if temp_lm > strongest_lm then strongest_lm = temp_lm end
      graph.vertices[k].dislikes = 0
    end
    game.strongest_shot = strongest_lm - start_lm
  end

  game.weakest_move = function(fun, epsilon, val_question, precision)
    local graph = deepcopy(game.graphs.general)
    for _, v in pairs(graph.vertices) do
      v.likes    = 0
      v.dislikes = 0
    end
    local weakest_lm = saa.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)
    local start_lm   = weakest_lm

    for k, _ in pairs(graph.vertices.q.attackers) do
      graph.vertices[k].likes = 1
      local temp_lm = saa.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)
      if temp_lm < weakest_lm then weakest_lm = temp_lm end
      graph.vertices[k].likes = 0
    end
    game.weakest_shot = weakest_lm - start_lm
  end

  for _,player in ipairs(players) do
    game.graphs[player] = deepcopy(graph)
    game.graphs[player].view = player
  end

  return game
end
return create_game
