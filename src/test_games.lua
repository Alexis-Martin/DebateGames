local game_generator  = require "game_generator"
local graph_generator = require "graph_generator"
local export_game     = require "export_xml"
local export_tex      = require "tex_representation"
local import_game     = require "import_xml"
local lfs             = require "lfs"
local rules           = require "rules"
local saa             = require "saa"


local function test_random_games(val_question)
  local max_players  = 6
  local max_games    = 10
  local max_vertices = 20
  local dynamique    = "random"
  local nb_tests     = max_vertices * max_games * (max_players)
  local options      = {
    xlabel = "round",
    ylabel = "value",
    title  = nil
  }
  -- apply a specific rule on game with 2 to max_players players, max_graphs different trees and max_games different games for each tree and each number of players.
  local dest = "../tests/" .. os.date("%d_%m_%H_%M_%S_") .. dynamique .. "_q_" .. val_question .. "/"
  lfs.mkdir(dest)

  local parameters = {
    val_question = val_question,
    precision    = 8,
    dynamique    = "random",
    log_details  = "strokes"
  }

  for players = 1, max_players do
    local dest_p = dest .. players .. "_players/"
    lfs.mkdir(dest_p)
    for nb_vertices = 1, max_vertices do
      local dest_v = dest_p .. nb_vertices .. "_vertices/"
      lfs.mkdir(dest_v)
      for j = 1, max_games do
        print((players-1) * max_vertices * max_games + (nb_vertices-1) * max_games + j .. "/" .. nb_tests)
        -- local nb_vertices = 6 --math.random(2, 50)
        local graph    = graph_generator(nb_vertices)
        local dest_j   = dest_v .. "game_" .. j .. ".xml"
        local dest_tex = dest_v .. "game_" .. j .. ".tex"
        local game     = game_generator(players, graph)
        export_game(game, dest_j)
        export_tex(game, dest_tex)

        -- test tau_1
        local dest_log      = dest_v .. "game_"
                           .. j .. "_tau_1.log"
        parameters.fun      = "tau_1"
        parameters.log_file = dest_log
        game.aggregation_value("tau_1", nil, val_question, 5)
        game.strongest_shot("tau_1", nil, val_question, 5)
        game.weakest_shot("tau_1", nil, val_question, 5)
        saa.computeSAA   (game, "tau_1", nil, val_question, 5)
        rules.mindChanged(game, parameters)
        dest_j         = dest_v .. "game_" .. j .. "_tau_1.xml"
        dest_tex       = dest_v .. "game_" .. j .. "_tau_1.tex"
        local dest_png = dest_v .. "game_" .. j .. "_tau_1.png"

        options.title  = players     .. " players "
                      .. nb_vertices .. " vertices "
                      .. "game "     .. j
                      .. " function tau_1"
        game.plot  (dest_png, false, options)
        export_game(game, dest_j)
        export_tex(game, dest_tex)
        -- game.restoreGame()
        --
        -- -- test tau_2
        -- dest_log = dest_v .. "game_" .. j .. "_tau_2.log"
        -- parameters.fun      = "tau_2"
        -- parameters.log_file = dest_log
        -- game.aggregation_value("tau_2", nil, val_question, 5)
        -- saa.computeSAA   (game, "tau_2", nil, val_question, 5)
        -- rules.mindChanged(game, parameters)
        -- dest_j        = dest_v .. "game_" .. j .. "_tau_2.xml"
        -- dest_tex      = dest_v .. "game_" .. j .. "_tau_2.tex"
        -- dest_png      = dest_v .. "game_" .. j .. "_tau_2.png"
        -- options.title = players     .. " players "
        --              .. nb_vertices .. " vertices "
        --              .. "game "     .. j
        --              .. " function tau_2"
        -- game.plot  (dest_png, false, options)
        -- export_game(game, dest_j)
        -- export_tex (game, dest_tex)
        -- game.restoreGame()
        --
        -- -- test L_&_M
        -- dest_log = dest_v .. "game_" .. j .. "_L_&_M.log"
        -- parameters.fun      = "L_&_M"
        -- parameters.log_file = dest_log
        -- game.aggregation_value("L_&_M", 0.1, val_question, 5)
        -- saa.computeSAA   (game, "L_&_M", 0.1, val_question, 5)
        -- rules.mindChanged(game, parameters)
        -- dest_j        = dest_v .. "game_" .. j .. "_L_&_M.xml"
        -- dest_tex      = dest_v .. "game_" .. j .. "_L_&_M.tex"
        -- dest_png      = dest_v .. "game_" .. j .. "_L_&_M.png"
        -- options.title = players     .. " players "
        --              .. nb_vertices .. " vertices "
        --              .. "game "     .. j
        --              .. " function L&M"
        -- game.plot  (dest_png, false, options)
        -- export_tex (game, dest_tex)
        -- export_game(game, dest_j)
      end
    end
  end
end

do
  test_random_games(1)
end


-- do
--   local game = import_game("/home/talkie/Documents/Stage/DebateGames/tests/13_06_14_46_27_random_q_1/4_players/11_vertices/game_1_tau_1.xml", true)
--   -- game:print_game()
--   -- game.aggregation_value("tau_1", 0.1, 1, 8)
--   -- saa.computeSAA(game, "tau_1", 0.1, 1, 8)
--   -- rules.mindChanged(game, {
--   --   fun = "tau_1",
--   --   val_question = 1,
--   --   precision = 8,
--   --   log_details = "all",
--   --   log_file = "test.log",
--   --   dynamique    = "random",
--   -- })
--
--   export_game(game,"output.xml")
--   game.plot("output.png", true)
--   export_tex(game, "/home/talkie/Documents/Stage/DebateGames/src/output.tex")
--
-- end
