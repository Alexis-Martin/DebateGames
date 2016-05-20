local game_generator  = require "game_generator"
local graph_generator = require "graph_generator"
local export_game     = require "export_xml"
local import_game     = require "import_xml"
local lfs             = require "lfs"
local rules           = require "rules"
local saa             = require "saa"


local function test_random_games(val_question)
  local max_players  = 6
  local max_games    = 20
  local max_vertices = 20
  local nb_tests     = max_vertices * max_games * (max_players-1)
  -- apply a specific rule on game with 2 to max_players players, max_graphs different trees and max_games different games for each tree and each number of players.
  local dest = "../tests/tests_games_" .. os.date("%d_%m_%H_%M_%S") .. "/"
  lfs.mkdir(dest)

  for players = 2, max_players do
    local dest_p = dest .. players .. "_players/"
    lfs.mkdir(dest_p)
    for nb_vertices = 1, max_vertices do
      local dest_v = dest_p .. nb_vertices .. "_vertices/"
      lfs.mkdir(dest_v)
      for j = 1, max_games do
        print((players-2) * max_vertices * max_games + (nb_vertices-1) * max_games + j .. "/" .. nb_tests)
        -- local nb_vertices = 6 --math.random(2, 50)
        local graph  = graph_generator(nb_vertices)
        local dest_j = dest_v .. "game_" .. j .. ".xml"
        local game   = game_generator(players, graph)
        export_game(game, dest_j)
        -- test tau_1
        saa.computeSAA   (game, "tau_1", nil, val_question, 5)
        rules.mindChanged(game, "tau_1", nil, val_question, 5, players^nb_vertices)
        dest_j         = dest_v .. "game_" .. j .. "_tau_1.xml"
        local dest_png = dest_v .. "game_" .. j .. "_tau_1.png"
        game.plot  (nil, dest_png, false)
        export_game(game, dest_j)
        game.restoreGame()
        -- test tau_2
        saa.computeSAA   (game, "tau_2", nil, val_question, 5)
        rules.mindChanged(game, "tau_2", nil, val_question, 5, players^nb_vertices)
        dest_j   = dest_v .. "game_" .. j .. "_tau_2.xml"
        dest_png = dest_v .. "game_" .. j .. "_tau_2.png"
        game.plot  (nil, dest_png, false)
        export_game(game, dest_j)
        game.restoreGame()
        -- test L_&_M
        saa.computeSAA   (game, "L_&_M", 0.1, val_question, 5)
        rules.mindChanged(game, "L_&_M", 0.1, val_question, 5, players^nb_vertices)
        dest_j   = dest_v .. "game_" .. j .. "_L_&_M.xml"
        dest_png = dest_v .. "game_" .. j .. "_L_&_M.png"
        game.plot  (nil, dest_png, false)
        export_game(game, dest_j)
      end
    end
  end
end

do
  test_random_games(1)
end

-- do
--   local game = import_game("../tests/tests_games_20_05_10_55_31/2_players/9_vertices/game_3.xml")
--
--   saa.computeSAA(game, "tau_1", nil, 1, 5)
--   rules.mindChanged(game, "tau_1", nil, 1, 5, 300, false)
--   -- for k, v in pairs(game.graphs) do
--   --   if type(v) == "table" then
--   --     print("\n\n", k)
--   --     v.print_graph(v)
--   --   end
--   -- end
--   game.plot(nil, "output.png", true)
--   -- local dest_j = "tests_games_12_05_ 17_36_27/3_players/game_8_after.xml"
--   -- export_game(game, dest_j)
-- end
