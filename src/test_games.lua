local game_generator  = require "game_generator"
local graph_generator = require "graph_generator"
local export_game     = require "export_xml"
local export_tex      = require "tex_representation"
local import_game     = require "import_xml"
local lfs             = require "lfs"
local rules           = require "rules"
local saa             = require "saa"


local function test_random_games(val_question)
  local max_players  = 2
  local max_games    = 30
  local max_vertices = 15
  local precision    = 8
  local dynamique    = "round_robin"
  local type_vote    = "better"
  local nb_tests     = max_vertices * max_games * (max_players)
  local options      = {
    xlabel = "round",
    ylabel = "value",
    title  = nil
  }
  -- apply a specific rule on game with 2 to max_players players, max_graphs different trees and max_games different games for each tree and each number of players.
  local dest = "../tests/" .. os.date("%d_%m_%H_%M_") .. dynamique .. "_" .. val_question .. "/"
  lfs.mkdir(dest)

  local parameters = {
    val_question = val_question,
    precision    = precision,
    type_vote    = type_vote,
    dynamique    = dynamique,
    log_details  = "all"
  }

  for players = 1, max_players do
    local dest_p = dest .. players .. "_players/"
    lfs.mkdir(dest_p)
    for nb_vertices = 1, max_vertices do
      local dest_v = dest_p .. nb_vertices .. "_vertices/"
      lfs.mkdir(dest_v)
      for j = 1, max_games do
        print((players-1) * max_vertices * max_games + (nb_vertices-1) * max_games + j .. "/" .. nb_tests)

        local graph    = graph_generator(nb_vertices)
        local dest_j   = dest_v .. "game_" .. j .. ".xml"
        local dest_tex = dest_v .. "game_" .. j .. ".tex"
        local game     = game_generator(players, graph)
        export_game(game, dest_j)
        export_tex(game, dest_tex)

        -- test tau_1 with best
        parameters.type_vote = "best"
        local dest_log      = dest_v .. "best_"
                           .. j .. "_tau_1_log.log"
        parameters.fun      = "tau_1"
        parameters.log_file = dest_log
        game.aggregation_value("tau_1", nil, val_question, precision)
        game.strongest_move("tau_1", nil, val_question, precision)
        game.weakest_move("tau_1", nil, val_question, precision)
        saa.computeSAA   (game, "tau_1", nil, val_question, precision)
        rules.mindChanged(game, parameters)
        dest_j         = dest_v .. "best_" .. j .. "_tau_1.xml"
        dest_tex       = dest_v .. "best_" .. j .. "_tau_1.tex"
        local dest_png = dest_v .. "best_" .. j .. "_tau_1.png"

        options.title  = players     .. " players "
                      .. nb_vertices .. " vertices "
                      .. "best "     .. j
                      .. " function tau_1"
        game.plot  (dest_png, false, options)
        export_game(game, dest_j)
        export_tex(game, dest_tex)
        game.restoreGame()

        -- test tau_1 with better
        parameters.type_vote = "better"
        dest_log             = dest_v .. "better_"
                             .. j .. "_tau_1_log.log"
        parameters.fun      = "tau_1"
        parameters.log_file = dest_log
        game.aggregation_value("tau_1", nil, val_question, precision)
        game.strongest_move("tau_1", nil, val_question, precision)
        game.weakest_move("tau_1", nil, val_question, precision)
        saa.computeSAA   (game, "tau_1", nil, val_question, precision)
        rules.mindChanged(game, parameters)
        dest_j         = dest_v .. "better_" .. j .. "_tau_1.xml"
        dest_tex       = dest_v .. "better_" .. j .. "_tau_1.tex"
        dest_png       = dest_v .. "better_" .. j .. "_tau_1.png"

        options.title  = players     .. " players "
                      .. nb_vertices .. " vertices "
                      .. "better "     .. j
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

-- do
--   test_random_games(1)
-- end


-- do
-- local c = 0
-- print (c)
-- local players = 2
-- local vertices = 10
-- local precision    = 8
-- local dynamique    = "round_robin"
-- local type_vote    = "better"
-- local options      = {
--   xlabel = "round",
--   ylabel = "value",
--   title  = nil
-- }
--
-- local parameters = {
--   val_question = 1,
--   precision    = precision,
--   type_vote    = type_vote,
--   dynamique    = dynamique,
--   log_details  = "all"
-- }
-- parameters.fun      = "tau_1"
-- parameters.log_file = "better_different_value_log.log"
-- local graph    = graph_generator(vertices)
-- local game     = game_generator(players, graph)
-- export_game(game, "better_different_value_init.xml")
-- game.aggregation_value("tau_1", nil, 1, precision)
-- saa.computeSAA   (game, "tau_1", nil, 1, precision)
-- rules.mindChanged(game, parameters)
-- c = c+1
-- local different = false
-- if ((game.graphs["joueur 1"].LM[1].value <= game.graphs.general.LM[1].value  and
--      game.graphs.general.LM[1].value <= game.graphs["joueur 2"].LM[1].value) or
--     (game.graphs["joueur 2"].LM[1].value <= game.graphs.general.LM[1].value  and
--      game.graphs.general.LM[1].value <= game.graphs["joueur 1"].LM[1].value)) and
--     game.graphs.general.LM[1].value ~= game.graphs.general.LM[#game.graphs.general.LM].value
--   then
--     different = true
-- end
-- while (not different) do
--   print(c)
--   graph    = graph_generator(vertices)
--   game     = game_generator(players, graph)
--   export_game(game, "better_different_value_init.xml")
--
--   game.aggregation_value("tau_1", nil, 1, precision)
--   saa.computeSAA   (game, "tau_1", nil, 1, precision)
--   rules.mindChanged(game, parameters)
--   if ((game.graphs["joueur 1"].LM[1].value <= game.graphs.general.LM[1].value  and
--        game.graphs.general.LM[1].value <= game.graphs["joueur 2"].LM[1].value) or
--       (game.graphs["joueur 2"].LM[1].value <= game.graphs.general.LM[1].value  and
--        game.graphs.general.LM[1].value <= game.graphs["joueur 1"].LM[1].value)) and
--       game.graphs.general.LM[1].value ~= game.graphs.general.LM[#game.graphs.general.LM].value
--     then
--       different = true
--   end
--   c = c + 1
-- end
-- options.title  = players     .. " players "
--               .. vertices .. " vertices "
--               .. "better " .. " function tau_1"
-- game.plot  ("better_different_value.png", false, options)
-- export_game(game, "better_different_value.xml")
-- export_tex(game, "better_different_value.tex")
--
-- end



do
  local game = import_game("/home/talkie/Documents/Stage/DebateGames/src/example/differents_values/better_different_value.xml")
  game:print_game()
  -- game.aggregation_value("tau_1", 0.1, 1, 8)
  saa.computeSAA(game, "tau_1", 0.1, 1, 8)
  -- rules.mindChanged(game, {
  --   fun = "tau_1",
  --   val_question = 1,
  --   precision = 8,
  --   log_details = "all",
  --   log_file = "output_log.log",
  --   dynamique    = "round_robin",
  --   type_vote    = "best",
  -- })
  print("-------------------------------------------------")
  game:print_game()
  -- print(game.graphs.general.LM[1].value)

  -- export_game(game,"output.xml")
  -- game.plot("output.png", true)
  -- export_tex(game, "/home/talkie/Documents/Stage/DebateGames/src/output.tex")

end
