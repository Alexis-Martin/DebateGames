local game_generator  = require "game_generator"
local graph_generator = require "graph_generator"
local export_game     = require "export_xml"
local import_game     = require "import_xml"
local lfs             = require "lfs"
local rules           = require "rules"
local saa             = require "saa"


local function test_random_games(is_tho1)
  local max_players = 10
  local max_games   = 10

  -- apply a specific rule on game with 2 to max_players players, max_graphs different trees and max_games different games for each tree and each number of players.
  local dest = "tests_games_" .. os.date("%d_%m_%H_%M_%S") .. "/"
  lfs.mkdir(dest)

  for players = 2, max_players do
    local dest_p = dest .. players .. "_players/"
    lfs.mkdir(dest_p)
    for j = 1, max_games do
      local nb_vertices = 2 --math.random(2, 50)
      local graph       = graph_generator(nb_vertices)
      local dest_j = dest_p .. "game_" .. j .. ".xml"
      local game = game_generator(players, graph)
      export_game(game, dest_j)
      saa.computeSAA(game, is_tho1, 0.001)
      rules.mindChanged(game, is_tho1, 0.001)
      dest_j = dest_p .. "game_" .. j .. "_after.xml"
      export_game(game, dest_j)
    end
  end
end

do
  test_random_games(false)
end

-- do
--   local game = import_game("tests_games_12_05_ 17_36_27/3_players/game_8.xml")
--   saa.computeSAA(game, true, 0.001)
--   rules.mindChanged(game, true, 0.001, 300)
--   for k, v in pairs(game.graphs.general.LM) do
--     print(k, v)
--   end
--   -- local dest_j = "tests_games_12_05_ 17_36_27/3_players/game_8_after.xml"
--   -- export_game(game, dest_j)
-- end
