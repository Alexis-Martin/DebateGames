local create_game = require "game"
local function game_generator(nb_players, graph)
  local players = {}
  for i = 1, nb_players do
    players[i] = "joueur " .. i
  end
  local game = create_game.create(players, graph)

  for _, player in ipairs(players) do
    for k, v in pairs(game:getGraph(player):getVertices()) do
      if v:getTag("tag") ~= "question" then
        local vote = math.random(0, 2)
        if     vote == 1 then
          game:addLike(player, k)
        elseif vote == 2 then
          game:addDislike(player, k)
        end
      end
    end
  end
  return game
end
return game_generator
