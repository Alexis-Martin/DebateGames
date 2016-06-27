local saa   = require "saa"
local rules = {
  mind_changed = {},
  one_shot     = {}
}

function rules.mind_changed.test_move(player, arg, vote, print_log)
  local parameters    = rules.mind_changed.parameters
  local game          = parameters.game
  local graph         = game.graphs.general
  local players_votes = parameters.players_votes
  local fun           = parameters.fun
  local epsilon       = parameters.epsilon
  local val_question  = parameters.val_question
  local precision     = parameters.precision
  local vote_type     = ""
  local value_vote    = nil

  -- application of the vote
  if vote == "like" and players_votes[player][arg] == 1 then

    game.removeLike(nil, arg)
    vote_type  = "remove like"
    value_vote = nil

  elseif vote == "like"
     and players_votes[player][arg] == -1 then

    game.addLike      (nil, arg)
    game.removeDislike(nil, arg)
    vote_type  = "change to like"
    value_vote = 1

  elseif vote == "like" then

    game.addLike(nil, arg)
    vote_type  = "vote like"
    value_vote = 1

  elseif vote == "dislike"
     and players_votes[player][arg] == 1 then

       game.addDislike(nil, arg)
       game.removeLike(nil, arg)
       vote_type  = "change to dislike"
       value_vote = -1

  elseif vote == "dislike"
     and players_votes[player][arg] == -1 then

       game.removeDislike(nil, arg)
       vote_type  = "remove dislike"
       value_vote = nil

  elseif vote == "dislike" then

    game.addDislike(nil, arg)
    vote_type  = "vote dislike"
    value_vote = -1
  end

  -- graph value's computation
  local lm = saa.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)

  -- write logs if it is asked
  if type(print_log) == "table" then
    print_log.arg      = arg
    print_log.likes    = graph.vertices[arg].likes
    print_log.dislikes = graph.vertices[arg].dislikes
    print_log.new_lm   = lm
    io.write(vote_type)
    for k, v in pairs(print_log) do
      io.write("\t" .. k .. " = " .. tostring(v) .. "\n")
    end
    io.write("--------------------------")
  end

  -- restoration of the previous values
  if vote == "like" and players_votes[player][arg] == 1 then
    game.addLike(nil, arg)
  elseif vote == "like"
     and players_votes[player][arg] == -1 then
    game.removeLike(nil, arg)
    game.addDislike(nil, arg)
  elseif vote == "like" then
    game.removeLike(nil, arg)
  elseif vote == "dislike"
     and players_votes[player][arg] == 1 then
       game.removeDislike(nil, arg)
       game.addLike(nil, arg)
  elseif vote == "dislike"
     and players_votes[player][arg] == -1 then
       game.addDislike(nil, arg)
  elseif vote == "dislike" then
    game.removeDislike(nil, arg)
  end

  return value_vote, lm
end

function rules.mind_changed.better_move(player)
  local parameters = rules.mind_changed.parameters
  local game       = parameters.game
  local changed    = 0

  local player_lm = game.graphs[player].LM[#game.graphs[player].LM].value
  local gen_lm    = game.graphs.general.LM[#game.graphs.general.LM].value
  local better_votes = {}
  local graph     = game.graphs.general
  local print_log = nil
  if parameters.log_file and parameters.log_details == "all" then
    io.write("===================================\n")
    io.write(player .. " : LM = " .. player_lm .. "\n")
    io.write("general : LM = " .. gen_lm .. "\n")
    io.write("===================================\n")
  end

  for arg, v in pairs(graph.vertices) do
    local temp_lm
    local value_vote
    if v.tag ~= "question" then
      for _, type_vote in ipairs({"like", "dislike"}) do

        if parameters.log_file and parameters.log_details == "all" then
          print_log = {
            general_lm = gen_lm,
          }
        end

        value_vote, temp_lm = rules.mind_changed.test_move(player, arg, type_vote, print_log)

        if math.abs(temp_lm - player_lm) < math.abs(gen_lm - player_lm) then
          local vote = {
            arg  = arg,
            lm   = temp_lm,
            vote = value_vote,
          }
          table.insert(better_votes, vote)
        end
      end
    end
  end

  -- choose vote if there is one.
  local vote = {}
  if #better_votes >= 1 then
    local i = math.random(1, #better_votes)
    vote = better_votes[i]
  end

  if parameters.log_file then
    if parameters.log_details == "all" then
      io.write("decision : vote = " .. tostring(vote.arg or "none") .. " bool = " .. tostring(vote.vote or 0) .. " lm = " .. tostring(vote.lm or gen_lm) .. "\n")
      io.write("==============================\n")
    elseif parameters.log_details == "strokes" then
      io.write(player .. " : votes possibles = [")

      for i, v in ipairs(better_votes) do
        io.write("(".. v.arg .. ", " .. tostring(v.vote) .. ", " .. tostring(v.lm) ..")")
        if i < #better_votes then io.write(", ") end
      end

      io.write("] \n\t\tvote = " .. tostring(vote.arg or "none") .. " bool = " .. tostring(vote.vote or 0) .. " lm joueur = " .. player_lm .. " lm avant = " .. gen_lm .. " lm après " .. tostring(vote.lm or gen_lm) .. "\n")
      io.write("============================== \n")
    end
  end
  -- -- we compute the old value to restore all values in the graph
  -- saa.computeGraphSAA(#game.players, graph, parameters.fun, parameters.epsilon, parameters.val_question, parameters.precision)

  -- application of the best vote we found (if there is a best vote)
  if #better_votes >= 1 then
    changed = rules.mind_changed.do_move(player, vote.arg, vote.vote)
  end

  -- computation of the new value of the game
  local lm = saa.computeGraphSAA(#game.players, graph, parameters.fun, parameters.epsilon, parameters.val_question, parameters.precision)
  if not graph.LM then
    graph.LM = {}
  end
  graph.LM[#graph.LM + 1] = {
    run      = #graph.LM + 1,
    player   = player,
    arg_vote = vote.arg or "none",
    vote     = vote.vote or 0,
    value    = lm
  }
  if #better_votes >= 1 then return vote.arg, changed, 0 end

  return nil, 0, 1
end

function rules.mind_changed.best_move(player)
  local parameters = rules.mind_changed.parameters
  local game       = parameters.game
  local changed    = 0

  local player_lm = game.graphs[player].LM[#game.graphs[player].LM].value
  local gen_lm    = game.graphs.general.LM[#game.graphs.general.LM].value
  local best_vote = nil
  local best_lm   = gen_lm
  local vote      = nil
  local graph     = game.graphs.general
  local print_log = nil
  if parameters.log_file and parameters.log_details == "all" then
    io.write("===================================\n")
    io.write(player .. " : LM = " .. player_lm .. "\n")
    io.write("general : LM = " .. gen_lm .. "\n")
    io.write("===================================\n")
  end

  for arg, v in pairs(graph.vertices) do
    local temp_lm
    local value_vote
    if v.tag ~= "question" then
      for _, type_vote in ipairs({"like", "dislike"}) do

        if parameters.log_file and parameters.log_details == "all" then
          print_log = {
            best_lm = best_lm,
          }
        end

        value_vote, temp_lm = rules.mind_changed.test_move(player, arg, type_vote, print_log)

        if math.abs(temp_lm - player_lm) < math.abs(best_lm - player_lm) then
          best_vote = arg
          best_lm   = temp_lm
          vote      = value_vote
        end
      end
    end
  end

  if parameters.log_file then
    if parameters.log_details == "all" then
      io.write("decision : best vote = " .. tostring(best_vote) .. " bool = " .. tostring(vote) .. " lm = " .. best_lm .. "\n")
      io.write("==============================\n")
    elseif parameters.log_details == "strokes" then
      io.write(player .. " : vote = " .. tostring(best_vote) .. " bool = " .. tostring(vote) .. " lm joueur = " .. player_lm .. " lm avant = " .. gen_lm .. " lm après " .. best_lm .. "\n")
      io.write("============================== \n")
    end
  end

  -- application of the best vote we found (if there is a best vote)
  if best_vote then
    changed = rules.mind_changed.do_move(player, best_vote, vote)
  end

  -- computation of the new value of the game
  local lm = saa.computeGraphSAA(#game.players, graph, parameters.fun, parameters.epsilon, parameters.val_question, parameters.precision)
  if not graph.LM then
    graph.LM = {}
  end
  graph.LM[#graph.LM + 1] = {
    run      = #graph.LM + 1,
    player   = player,
    arg_vote = best_vote or "none",
    vote     = vote or 0,
    value    = lm
  }
  if best_vote then return best_vote, changed, 0 end

  return nil, 0, 1
end

function rules.mind_changed.do_move(player, arg, value_vote)
  local parameters    = rules.mind_changed.parameters
  local game          = parameters.game
  local players_votes = parameters.players_votes
  local changed       = 0

  if value_vote == 1 then
    game.addLike("general", arg)
    if players_votes[player][arg] == 0 then
      changed = 1
    end
    if players_votes[player][arg] == -1 then
      game.removeDislike("general", arg)
      changed = 1
    end
  elseif value_vote == -1 then
    game.addDislike("general", arg)
    if players_votes[player][arg] == 0 then
      changed = 1
    end
    if players_votes[player][arg] == 1 then
      game.removeLike("general", arg)
      changed = 1
    end
  else
    changed = 1
    if players_votes[player][arg] == 1 then
      game.removeLike("general", arg)
    else
      game.removeDislike("general", arg)
    end
  end
  --store the vote
  players_votes[player][arg] = value_vote or 0
  return changed
end


function rules.mind_changed.playOnce(player, arg, vote)
  local parameters         = rules.mind_changed.parameters
  local game               = parameters.game
  local graph              = game.graphs.general
  local changed            = 0

  if arg and arg ~= "none" then
    changed = rules.mind_changed.do_move(player, arg, vote)
  end

  -- computation of the new value of the game
  local lm = saa.computeGraphSAA(#game.players, graph, parameters.fun, parameters.epsilon, parameters.val_question, parameters.precision)

  if not graph.LM then
    graph.LM = {}
  end
  graph.LM[#graph.LM + 1] = {
    run      = #graph.LM + 1,
    player   = player,
    arg_vote = arg or "none",
    vote     = vote or 0,
    value    = lm
  }
  game.rounds  = (game.rounds or 0) + 1
  print("round = " .. game.rounds + 1, "like = " .. graph.vertices.a3.likes, "dislikes = " .. graph.vertices.a3.dislikes)
  game.changed = (game.changed or 0) + changed
  if not arg or arg == "none" then
    game.pass  = (game.pass or 0) + 1
  end
end



function rules.mind_changed.mindChanged(game)
  local parameters = rules.mind_changed.parameters

  if parameters.log_file then
    local l_file = io.open(parameters.log_file, "w")
    io.output(l_file)
  end

  parameters.players_votes = {}
  for _, v in ipairs(game.players) do
    parameters.players_votes[v] = {}
  end
  local changed = 0
  local pass    = 0
  local type_vote = rules.mind_changed.best_move
  if parameters.type_vote == "better" then
    type_vote = rules.mind_changed.better_move
  end
  local function round_robin()
    local nb_nil = 0
    for _, v in ipairs(game.players) do
      local is_nil, is_changed, is_pass = type_vote(v)
      if not is_nil then
        nb_nil = nb_nil + 1
      end
      changed = changed + is_changed
      pass    = pass    + is_pass
    end
    return nb_nil
  end

  local function random_player()
    local players = {}
    for _, v in ipairs(game.players) do
      table.insert(players, v)
    end
    local nil_players = {}
    local nb_round = 0

    while #players >= 1 do
      nb_round = nb_round + 1

      local player = math.random(1, #players)
      local is_nil, is_changed, is_pass = type_vote(players[player])

      if not is_nil then
        table.insert(nil_players, players[player])
        table.remove(players, player)
      elseif #nil_players >= 1 then
        for _, v in ipairs(nil_players) do
          table.insert(players, v)
        end
        nil_players = {}
      end
      changed = changed + is_changed
      pass    = pass    + is_pass

      if type(parameters.stop_at) == "number" and
         nb_round >= parameters.stop_at then
        break
      end
    end

    return #game.players + 1
  end

  -- print("round 1")
  local dynamique
  if     parameters.dynamique == "round_robin" then
    dynamique = round_robin
  elseif parameters.dynamique == "random" then
    dynamique = random_player
  end

  local nb_round = #game.players
  local nb_nil   = dynamique()

  while nb_nil < #game.players do
    nb_round = nb_round + #game.players
    nb_nil   = dynamique()

    if type(parameters.stop_at) == "number" and
       nb_round >= parameters.stop_at then
      break
    end
  end

  local mean = 0
  for i = 1, #game.players do
    mean = mean + game.graphs[game.players[i]].LM[1].value
  end
  mean = mean / (#game.players)
  game.mean            = mean
  game.rounds          = nb_round - #game.players
  game.changed         = changed
  game.pass            = pass - #game.players
  -- game.max_rounds = 3 ^ (#game.graphs.general.vertices)
end

function rules.playOnce(game, vote)
  rules.mind_changed.parameters.game = game
  if rules.mind_changed.parameters.rule == "mindChanged" then
    rules.mind_changed.playOnce(vote.player, vote.arg, vote.vote)
  end
end

function rules.setParameters(parameters)
  if type(parameters) ~= 'table' then
    parameters = {
      fun          = 'tau_1',
      val_question = 1,
      precision    = 5,
      log_details  = "all",
      type_vote    = "best",
      dynamique    = "round_robin"
    }
  else
    parameters.fun          = parameters.fun or 'tau_1'
    parameters.val_question = parameters.val_question or 1
    parameters.precision    = parameters.precision or 5
    parameters.epsilon      = parameters.epsilon or 0.1
    parameters.log_details  = parameters.log_details or "all"
    parameters.type_vote    = parameters.type_vote or "best"
    parameters.dynamique    = parameters.dynamique or "round_robin"
  end

  parameters.players_votes = {}
  for _, v in ipairs(parameters.game.players) do
    parameters.players_votes[v] = {}
  end

  parameters.game.game_parameters = {
    fun          = parameters.fun,
    val_question = parameters.val_question,
    epsilon      = parameters.epsilon,
    stop_at      = parameters.stop_at,
    type_vote    = parameters.type_vote,
    dynamique    = parameters.dynamique,
    precision    = parameters.precision,
    rule         = parameters.rule
  }

  if parameters.rule == "mindChanged" then
    rules.mind_changed.parameters = parameters
  end
end

function rules.mindChanged(game, parameters)
  parameters.game = game
  parameters.rule = "mindChanged"
  rules.setParameters(parameters)
  rules.mind_changed.mindChanged(game)
end

return rules
