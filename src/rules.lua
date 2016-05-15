local saa   = require "saa"
local rules = {}

function rules.mindChanged(game, is_tho1, precision, stop_at)
  local players_votes = {}
  for _, v in ipairs(game.players) do
    players_votes[v] = {}
  end

  local function best_move(player)
    local player_lm = game.graphs[player].LM[#game.graphs[player].LM]
    local gen_lm    = game.graphs.general.LM[#game.graphs.general.LM]
    local best_vote = nil
    local best_lm   = gen_lm
    local vote      = nil
    local graph     = game.graphs.general

    for arg, v in pairs(graph.vertices) do
      local temp_lm
      if v.tag ~= "question" then
        -- if player has already voted positively in argument arg
        if players_votes[player][arg] == 1 then
          -- what append if he removes his vote
          v.likes = v.likes - 1
          temp_lm = saa.computeGraphSAA(#game.players, graph, is_tho1, precision)
          -- print("player = "      .. player ..
          --       " arg = "        .. arg ..
          --       " abandon like " .. v.likes ..
          --       " lm_player = "  .. lm ..
          --       " general_lm = " .. gen_lm ..
          --       " new lm = "     .. graph.LM
          --     )
          if math.abs(temp_lm - player_lm) <= math.abs(best_lm - player_lm) then
            best_vote = arg
            best_lm   = temp_lm
            vote      = nil
          end

          -- what append if he changes his mind and vote negatively
          v.dislikes = v.dislikes + 1
          temp_lm = saa.computeGraphSAA(#game.players, graph, is_tho1, precision)
          -- print("player = "        .. player ..
          --       " arg = "          .. arg ..
          --       " changement neg " .. v.dislikes ..
          --       " lm_player = "    .. lm ..
          --       " general_lm = "   .. gen_lm ..
          --       " new lm = "       .. graph.LM
          --     )
          -- print("\n \n")
          if math.abs(temp_lm - player_lm) <= math.abs(best_lm - player_lm) then
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
          temp_lm = saa.computeGraphSAA(#game.players, graph, is_tho1, precision)
          -- print("player = "         .. player ..
          --       " arg = "           .. arg ..
          --       " abandon dislike " .. v.dislikes ..
          --       " lm_player = "     .. lm ..
          --       " general_lm = "    .. gen_lm ..
          --       " new lm = "        .. graph.LM
          --     )
          if math.abs(temp_lm - player_lm) <= math.abs(best_lm - player_lm) then
            best_vote = arg
            best_lm   = temp_lm
            vote      = nil
          end

          -- what append if he changes his mind and vote positively
          v.likes = v.likes + 1
          temp_lm = saa.computeGraphSAA(#game.players, graph, is_tho1, precision)
          -- print("player = "        .. player ..
          --       " arg = "          .. arg ..
          --       " changement pos " .. v.likes ..
          --       " lm_player = "    .. lm ..
          --       " general_lm = "   .. gen_lm ..
          --       " new lm = "       .. graph.LM
          --     )
          -- print("\n \n")
          if math.abs(temp_lm - player_lm) <= math.abs(best_lm - player_lm) then
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
          temp_lm = saa.computeGraphSAA(#game.players, graph, is_tho1, precision)
          -- print("player = "      .. player ..
          --       " arg = "        .. arg ..
          --       " positive "     .. v.likes ..
          --       " lm_player = "  .. lm ..
          --       " general_lm = " .. gen_lm ..
          --       " new lm = "     .. graph.LM
          --     )
          if math.abs(temp_lm - player_lm) <= math.abs(best_lm - player_lm) then
            best_vote = arg
            best_lm   = temp_lm
            vote      = 1
          end

          -- what append if he dislikes this argument
          v.likes = v.likes - 1
          v.dislikes = v.dislikes + 1
          temp_lm = saa.computeGraphSAA(#game.players, graph, is_tho1, precision)
          -- print("player = "      .. player ..
          --       " arg = "        .. arg ..
          --       " negative "     .. v.dislikes ..
          --       " lm_player = "  .. lm ..
          --       " general_lm = " .. gen_lm ..
          --       " new lm = "     .. graph.LM
          --     )
          -- print("\n \n")
          if math.abs(temp_lm - player_lm) <= math.abs(best_lm - player_lm) then
            best_vote = arg
            best_lm   = temp_lm
            vote      = -1
          end
          -- we restore previous values
          v.dislikes = v.dislikes - 1
        end
      end
    end
    -- print("decision : best vote = " .. tostring(best_vote) .. " bool = " .. tostring(vote))
    -- we compute the old value to restore all values in the graph
    saa.computeGraphSAA(#game.players, graph, is_tho1, precision, false)
    -- application of the best vote we found (if there is a best vote)
    if best_vote ~= nil then
      if vote == 1 then
        game.graphs.general.vertices[best_vote].likes = game.graphs.general.vertices[best_vote].likes + 1
        if players_votes[player][best_vote] == -1 then
          game.graphs.general.vertices[best_vote].dislikes = game.graphs.general.vertices[best_vote].dislikes - 1
        end
      elseif vote == -1 then
        game.graphs.general.vertices[best_vote].dislikes = game.graphs.general.vertices[best_vote].dislikes + 1
        if players_votes[player][best_vote] == 1 then
          game.graphs.general.vertices[best_vote].likes = game.graphs.general.vertices[best_vote].likes - 1
        end
      else
        if players_votes[player][best_vote] == 1 then
          game.graphs.general.vertices[best_vote].likes = game.graphs.general.vertices[best_vote].likes - 1
        else
          game.graphs.general.vertices[best_vote].dislikes = game.graphs.general.vertices[best_vote].dislikes - 1
        end
      end
      --store the vote
      players_votes[player][best_vote] = vote
      -- computation of the new value of the game
      saa.computeGraphSAA(#game.players, graph, is_tho1, precision, true)
      return best_vote
    end
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

  print("round 1")
  local nb_round = 2
  local nb_nil   = one_round()
  while nb_nil < #game.players do
    print("round " .. nb_round)
    nb_round = nb_round + 1
    nb_nil   = one_round()
    if type(stop_at) == "number" and
       #game.graphs.general.LM >= stop_at then
      break
    end
  end
end

return rules
