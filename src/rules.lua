local saa   = require "saa"
local rules = {}

function rules.mindChanged(game, fun, epsilon, val_question, precision, stop_at, print_log)
  local log_file
  if type(print_log) == "table" then
    log_file = io.open(print_log.file, "w")
    io.output(log_file)
  end

  local players_votes = {}
  for _, v in ipairs(game.players) do
    players_votes[v] = {}
  end
  local changed = 0
  local pass    = 0

  local function best_move(player)
    local player_lm = game.graphs[player].LM[#game.graphs[player].LM].value
    local gen_lm    = game.graphs.general.LM[#game.graphs.general.LM].value
    local best_vote = nil
    local best_lm   = gen_lm
    local vote      = nil
    local graph     = game.graphs.general
    if type(print_log) == "table" then
      if print_log.view == "all" then
        io.write("===================================\n")
        io.write(player .. " : LM = " .. player_lm .. "\n")
        io.write("general : LM = " .. gen_lm .. "\n")
        io.write("===================================\n")
      end
    end
    for arg, v in pairs(graph.vertices) do
      local temp_lm
      if v.tag ~= "question" then
        -- if player has already voted positively in argument arg
        if players_votes[player][arg] == 1 then
          -- what append if he removes his vote
          v.likes = v.likes - 1
          temp_lm = saa.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)
          if type(print_log) == "table" then
            if print_log.view == "all" then
              io.write(" arg = "        .. arg .. "\n")
              io.write(" abandon like \n")
              io.write("likes = " .. v.likes .. " dislikes = " .. v.dislikes .. "\n")
              io.write(" best lm = "    .. best_lm .. "\n")
              io.write(" new lm = "     .. temp_lm .. "\n")
              io.write("--------------------------------\n")
            end
          end
          if math.abs(temp_lm - player_lm) < math.abs(best_lm - player_lm) then
            best_vote = arg
            best_lm   = temp_lm
            vote      = nil
          end

          -- what append if he changes his mind and vote negatively
          v.dislikes = v.dislikes + 1
          temp_lm = saa.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)
          if type(print_log) == "table" then
            if print_log.view == "all" then
              io.write(" arg = "        .. arg .. "\n")
              io.write(" changement pour dislike \n")
              io.write("likes = " .. v.likes .. " dislikes = " .. v.dislikes .. "\n")
              io.write(" best lm = "    .. best_lm .. "\n")
              io.write(" new lm = "     .. temp_lm .. "\n")
              io.write("--------------------------------\n")
            end
          end
          if math.abs(temp_lm - player_lm) < math.abs(best_lm - player_lm) then
            best_vote = arg
            best_lm   = temp_lm
            vote      = -1
          end
          -- all possibilities have been seen, we restore previous values
          v.dislikes = v.dislikes - 1
          v.likes = v.likes + 1

        -- if player has already voted negatively in argument arg
        elseif players_votes[player][arg] == -1 then
          -- what append if he removes his vote
          v.dislikes = v.dislikes - 1
          temp_lm = saa.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)
          if type(print_log) == "table" then
            if print_log.view == "all" then
              io.write(" arg = "        .. arg .. "\n")
              io.write(" abandon dislike \n")
              io.write("likes = " .. v.likes .. " dislikes = " .. v.dislikes .. "\n")
              io.write(" best lm = "    .. best_lm.. "\n")
              io.write(" new lm = "     .. temp_lm.. "\n")
              io.write("-------------------------------- \n")
            end
          end
          if math.abs(temp_lm - player_lm) < math.abs(best_lm - player_lm) then
            best_vote = arg
            best_lm   = temp_lm
            vote      = nil
          end

          -- what append if he changes his mind and vote positively
          v.likes = v.likes + 1
          temp_lm = saa.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)
          if type(print_log) == "table" then
            if print_log.view == "all" then
              io.write(" arg = "        .. arg .. "\n")
              io.write(" changement pour like \n")
              io.write("likes = " .. v.likes .. " dislikes = " .. v.dislikes .. "\n")
              io.write(" best lm = "    .. best_lm .. "\n")
              io.write(" new lm = "     .. temp_lm .. "\n")
              io.write("-------------------------------- \n")
            end
          end
          if math.abs(temp_lm - player_lm) < math.abs(best_lm - player_lm) then
            best_vote = arg
            best_lm   = temp_lm
            vote      = 1
          end
          -- all possibilities have been seen, we restore previous values
          v.dislikes = v.dislikes + 1
          v.likes = v.likes - 1

        -- if player have'nt a vote on this argument
        else
          -- what append if he likes this argument
          v.likes = v.likes + 1
          temp_lm = saa.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)
          if type(print_log) == "table" then
            if print_log.view == "all" then
              io.write(" arg = "        .. arg .. "\n")
              io.write(" vote like \n")
              io.write("likes = " .. v.likes .. " dislikes = " .. v.dislikes .. "\n")
              io.write(" best lm = "    .. best_lm .. "\n")
              io.write(" new lm = "     .. temp_lm .. "\n")
              io.write("--------------------------------\n")
            end
          end
          if math.abs(temp_lm - player_lm) < math.abs(best_lm - player_lm) then
            best_vote = arg
            best_lm   = temp_lm
            vote      = 1
          end

          -- what append if he dislikes this argument
          v.likes = v.likes - 1
          v.dislikes = v.dislikes + 1
          temp_lm = saa.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)
          if type(print_log) == "table" then
            if print_log.view == "all" then
              io.write(" arg = "        .. arg .. "\n")
              io.write(" vote dislike \n")
              io.write("likes = " .. v.likes .. " dislikes = " .. v.dislikes .. "\n")
              io.write(" best lm = "    .. best_lm .. "\n")
              io.write(" new lm = "     .. temp_lm .. "\n")
              io.write("--------------------------------\n")
            end
          end
          if math.abs(temp_lm - player_lm) < math.abs(best_lm - player_lm) then
            best_vote = arg
            best_lm   = temp_lm
            vote      = -1
          end
          -- we restore previous values
          v.dislikes = v.dislikes - 1
        end
      end
    end
    if type(print_log) == "table" then
      if print_log.view == "all" then
        io.write("decision : best vote = " .. tostring(best_vote) .. " bool = " .. tostring(vote) .. " lm = " .. best_lm .. "\n")
        io.write("==============================\n")
      elseif print_log.view == "strokes" then
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
      -- computation of the new value of the game
      local lm = saa.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)
      if not graph.LM then
        graph.LM = {}
      end
      graph.LM[#graph.LM + 1] = {
        run      = #graph.LM + 1,
        player   = player,
        arg_vote = best_vote,
        vote     = vote or 0,
        value    = lm
      }
      return best_vote
    end
    local lm = saa.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)
    if not graph.LM then
      graph.LM = {}
    end
    graph.LM[#graph.LM + 1] = {
      run      = #graph.LM + 1,
      player   = player,
      arg_vote = "none",
      value    = lm
    }
    pass = pass + 1
    return nil
  end

  local function one_round()
    local nb_nil = 0
    for _, v in ipairs(game.players) do
      if best_move(v) == nil then
        nb_nil = nb_nil + 1
      end
    end
    return nb_nil
  end

  -- print("round 1")
  local nb_round = #game.players
  local nb_nil   = one_round()
  while nb_nil < #game.players do
    nb_round = nb_round + #game.players
    nb_nil   = one_round()
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
  game.rounds     = nb_round - #game.players
  game.changed    = changed
  game.pass       = pass - #game.players
  -- game.max_rounds = 3 ^ (#game.graphs.general.vertices)
end

return rules
