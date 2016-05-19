local function create_game(players, graph)
  local game = {
    graphs = {
      general = graph
    },
    players = players
  }

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
