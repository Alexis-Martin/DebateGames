local saa   = require "saa"
local rules = {}

function rules.mindChanged(game, parameters)
  assert(type(parameters) == 'table')
  local fun          = parameters.fun          or 'tau_1'
  local epsilon      = parameters.epsilon
  local val_question = parameters.val_question or 1
  local precision    = parameters.precision
  local stop_at      = parameters.stop_at
  local log_file     = parameters.log_file
  local log_details  = parameters.log_details  or "all"

  if log_file then
    local l_file = io.open(log_file, "w")
    io.output(l_file)
  end

  local players_votes = {}
  for _, v in ipairs(game.players) do
    players_votes[v] = {}
  end
  local changed = 0
  local pass    = 0

  local function test_move(player, arg, vote, print_log)
    local graph      = game.graphs.general
    local vote_type  = ""
    local value_vote = nil
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

  local function best_move(player)
    local player_lm = game.graphs[player].LM[#game.graphs[player].LM].value
    local gen_lm    = game.graphs.general.LM[#game.graphs.general.LM].value
    local best_vote = nil
    local best_lm   = gen_lm
    local vote      = nil
    local graph     = game.graphs.general
    local print_log = nil
    if log_file and log_details == "all" then
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

          if log_file and log_details == "all" then
            print_log = {
              best_lm = best_lm,
            }
          end

          value_vote, temp_lm = test_move(player, arg, type_vote, print_log)

          if math.abs(temp_lm - player_lm) < math.abs(best_lm - player_lm) then
            best_vote = arg
            best_lm   = temp_lm
            vote      = value_vote
          end
        end
      end
    end

    if log_file then
      if log_details == "all" then
        io.write("decision : best vote = " .. tostring(best_vote) .. " bool = " .. tostring(vote) .. " lm = " .. best_lm .. "\n")
        io.write("==============================\n")
      elseif log_details == "strokes" then
        io.write(player .. " : vote = " .. tostring(best_vote) .. " bool = " .. tostring(vote) .. " lm joueur = " .. player_lm .. " lm avant = " .. gen_lm .. " lm après " .. best_lm .. "\n")
        io.write("============================== \n")
      end
    end
    -- we compute the old value to restore all values in the graph
    saa.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)
    -- application of the best vote we found (if there is a best vote)
    if best_vote ~= nil then
      if vote == 1 then
        game.addLike("general", best_vote)
        if players_votes[player][best_vote] == 0 then
          changed = changed + 1
        end
        if players_votes[player][best_vote] == -1 then
          game.removeDislike("general", best_vote)
          changed = changed + 1
        end
      elseif vote == -1 then
        game.addDislike("general", best_vote)
        if players_votes[player][best_vote] == 0 then
          changed = changed + 1
        end
        if players_votes[player][best_vote] == 1 then
          game.removeLike("general", best_vote)
          changed = changed + 1
        end
      else
        changed = changed + 1
        if players_votes[player][best_vote] == 1 then
          game.removeLike("general", best_vote)
        else
          game.removeDislike("general", best_vote)
        end
      end
      --store the vote
      players_votes[player][best_vote] = vote or 0
    end

    -- computation of the new value of the game
    local lm = saa.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)
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
    if best_vote then return best_vote end

    pass = pass + 1
    return nil
  end

  local function round_robin()
    local nb_nil = 0
    for _, v in ipairs(game.players) do
      if best_move(v) == nil then
        nb_nil = nb_nil + 1
      end
    end
    return nb_nil
  end

  local function random_player()
    local nb_nil = 0
    for _ = 1, #game.players do
      local player = math.random(1, #game.players)
      if best_move(game.players[player]) == nil then
        nb_nil = nb_nil + 1
      end
    end
    return nb_nil
  end

  -- print("round 1")
  local dynamique = parameters.dynamique or "round_robin"
  if dynamique == "round_robin" then
    dynamique = round_robin
  elseif dynamique == "random" then
    dynamique = random_player
  end

  local nb_round = #game.players
  local nb_nil   = dynamique()

  while nb_nil < #game.players do
    nb_round = nb_round + #game.players
    nb_nil   = dynamique()

    if type(stop_at) == "number" and
       nb_round >= stop_at then
      break
    end
  end

  local mean = 0
  for i = 1, #game.players do
    mean = mean + game.graphs[game.players[i]].LM[1].value
  end
  mean = mean / (#game.players)
  game.mean       = mean
  game.dynamique  = dynamique
  game.rounds     = nb_round - #game.players
  game.changed    = changed
  game.pass       = pass - #game.players
  -- game.max_rounds = 3 ^ (#game.graphs.general.vertices)
end

return rules
