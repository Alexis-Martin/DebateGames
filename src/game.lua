local gp = require('gnuplot')
local function create_game(players, graph)
  local game = {
    graphs = {
      general = graph
    },
    players = players
  }

  game.restoreGame = function()
    for _, v in pairs(game.graphs.general.vertices) do
      v.likes    = 0
      v.dislikes = 0
      v.LM       = nil
    end
    game.graphs.general.LM = nil
    for _,p in ipairs(players) do
      game.graphs[p].LM = nil
    end
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
    for i = 1, #list_players -2 do
      mean = mean + game.graphs[list_players[i]].LM[1]
    end
    mean = mean / (#list_players - 2)
    print(mean, #list_players - 2)
    for i = 0, #game.graphs.general.LM-1 do
      table.insert(values[1], i)
      for p = 2, #list_players do
        table.insert(values[p], game.graphs[list_players[p-1]].LM[i+1] or game.graphs[list_players[p-1]].LM[1])
      end
      table.insert(values[#values], mean)
    end

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



  for _,player in ipairs(players) do
    game.graphs[player] = deepcopy(graph)
    game.graphs[player].view = player
  end

  return game
end
return create_game
