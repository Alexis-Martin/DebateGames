local game = require "model"

local players_votes = {}
for i=1,game.players do
  players_votes[i] = {}
end

local function best_move(player)
  local lm = game.graphs[player].LM
  local gen_lm = game.graphs.general.LM
  local best_vote = nil
  local positive = nil
  local graph = game.graphs.general
  for arg, v in pairs(graph.vertices) do
    if v.tag ~= "question" and players_votes[player][arg] ~= true then
      v.likes = v.likes + 1
      game.SAA(game.players, graph, 0.001)
      print("player = "      .. player ..
            " arg = "        .. arg ..
            " positive "     .. v.likes ..
            " lm_player = "  .. lm ..
            " general_lm = " .. gen_lm ..
            " new lm = "     .. graph.LM
          )
      if math.abs(graph.LM - lm) <= math.abs(gen_lm - lm) then
        best_vote = arg
        positive = true
      end

      v.likes = v.likes - 1
      v.dislikes = v.dislikes + 1
      game.SAA(game.players, graph, 0.001)
      print("player = "      .. player ..
            " arg = "        .. arg ..
            " negative "     .. v.dislikes ..
            " lm_player = "  .. lm ..
            " general_lm = " .. gen_lm ..
            " new lm = "     .. graph.LM
          )
      print("\n \n")
      if math.abs(graph.LM - lm) <= math.abs(gen_lm - lm) then
        best_vote = arg
        positive = false
      end
      v.dislikes = v.dislikes - 1
    end
  end
  print("decision : best vote = " .. tostring(best_vote) .. " bool = " .. tostring(positive))
  game.SAA(game.players, graph, 0.001)
  if best_vote ~= nil then
    if positive == true then
      game.graphs.general.vertices[best_vote].likes = game.graphs.general.vertices[best_vote].likes + 1
    else
      game.graphs.general.vertices[best_vote].dislikes = game.graphs.general.vertices[best_vote].dislikes + 1
    end
    game.SAA(game.players, graph, 0.001)
    players_votes[player][best_vote] = true
    return best_vote
  end
  return nil
end

local function one_round()
  local nb_nil = 0
  for i=1, game.players do

    if best_move(i) == nil then
      nb_nil = nb_nil + 1
    end
  end
  return nb_nil
end

local nb_nil = one_round()
print ("nb_nil = " .. nb_nil)
while nb_nil < game.players do
  nb_nil = one_round()
  print ("nb_nil = " .. nb_nil)
end

print("LM = " .. game.graphs.general.LM)

game.print_table(game)
