local game_generator  = require "game_generator"
local graph_generator = require "graph_generator"
local export_game     = require "export_xml"
local export_tex      = require "tex_representation"
local import_game     = require "import_xml"
local lfs             = require "lfs"
local rules           = require "rules"


local function test_random_games(val_question)
  local max_players  = 2
  local max_games    = 30
  local max_vertices = 15
  local precision    = 8
  local dynamique    = "round_robin"
  local type_vote    = "best"
  local compute_agg  = true
  local compute_mean = false
  local log_details  = "strokes"
  local check_cycle  = true
  local graphGen     = graph_generator.generateGraph

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
    log_details  = log_details,
    compute_agg  = compute_agg,
    compute_mean = compute_mean,
    rule         = "mindChanged",
    check_cycle  = check_cycle
  }

  for players = 1, max_players do
    local dest_p = dest .. players .. "_players/"
    lfs.mkdir(dest_p)
    for nb_vertices = 1, max_vertices do
      local dest_v = dest_p .. nb_vertices .. "_vertices/"
      lfs.mkdir(dest_v)
      for j = 1, max_games do
        io.stderr:write((players-1) * max_vertices * max_games + (nb_vertices-1) * max_games + j .. "/" .. nb_tests)

        local graph    = graphGen {
                          n_vertices = nb_vertices, max_edges  = 2*nb_vertices
                        }
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

        rules.setGame(game)
        rules.setParameters(parameters)
        rules.apply()
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
        if game.cycle then
          return
        end
        -- game.restoreGame()

        -- -- test tau_1 with better
        -- parameters.type_vote = "better"
        -- dest_log             = dest_v .. "better_"
        --                      .. j .. "_tau_1_log.log"
        -- parameters.fun      = "tau_1"
        -- parameters.log_file = dest_log
        -- rules.setParameters(parameters)
        -- rules.apply()
        -- dest_j         = dest_v .. "better_" .. j .. "_tau_1.xml"
        -- dest_tex       = dest_v .. "better_" .. j .. "_tau_1.tex"
        -- dest_png       = dest_v .. "better_" .. j .. "_tau_1.png"
        --
        -- options.title  = players     .. " players "
        --               .. nb_vertices .. " vertices "
        --               .. "better "     .. j
        --               .. " function tau_1"
        -- game.plot  (dest_png, false, options)
        -- export_game(game, dest_j)
        -- export_tex(game, dest_tex)
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
--
-- do
--   test_random_games(1)
-- end


-- do
-- local c = 0
-- print (c)
-- local players = 2
-- local vertices = 10
-- local precision    = 8
-- local dynamique    = "random"
-- local type_vote    = "best"
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
-- parameters.log_file = "best_different_value_log1.log"
-- local graph    = graph_generator.generateTree(vertices)
-- local game     = game_generator(players, graph)
-- export_game(game, "best_different_value_init1.xml")
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
--   graph    = graph_generator.generateTree(vertices)
--   game     = game_generator(players, graph)
--   export_game(game, "best_different_value_init1.xml")
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
--               .. "best " .. " function tau_1"
-- game.plot  ("best_different_value1.png", false, options)
-- export_game(game, "best_different_value1.xml")
-- export_tex(game, "best_different_value1.tex")
--
-- end

-- do
--   local players      = 4
--   local vertices     = 15
--   local precision    = 8
--   local dynamique    = "random"
--   local type_vote    = "better"
--   local compute_agg  = false
--   local compute_mean = false
--   local log_details  = "all"
--   local check_cycle  = true
--
--   local options      = {
--     xlabel = "round",
--     ylabel = "value",
--     title  = nil
--   }
--
--   local parameters = {
--     val_question = 1,
--     precision    = precision,
--     type_vote    = type_vote,
--     dynamique    = dynamique,
--     log_details  = log_details,
--     compute_agg  = compute_agg,
--     compute_mean = compute_mean,
--     rule         = "mindChanged",
--     check_cycle  = check_cycle
--   }
--   parameters.fun      = "tau_1"
--   parameters.log_file = "output_log.log"
--
--   rules.setParameters(parameters)
--
--   local cycle = false
--   local game
--   local compt = 1
--
--   while not cycle do
--     print(compt)
--     compt = compt + 1
--     local graph    = graph_generator.generateTree(vertices)
--     game     = game_generator(players, graph)
--
--     rules.setGame(game)
--     rules.apply()
--     cycle = game.cycle
--   end
--
--   game.plot  ("output.png", false, options)
--   export_game(game, "output.xml")
--   export_tex(game, "output.tex")
-- end

do
  local game = import_game("/home/talkie/Documents/Stage/DebateGames/docs/final_report/asterix.xml")
  -- game:print_game()
  -- game.aggregation_value("tau_1", 0.1, 1, 8)

  rules.setGame(game)
  rules.setParameters {compute_agg = false, compute_mean = false, log_file = "../docs/final_report/asterix_log.log"}
  -- rules.computeSAA()
  rules.apply()
  -- game:print_game()
  -- print(game.graphs.general.LM[1].value)

  export_game(game,"/home/talkie/Documents/Stage/DebateGames/docs/final_report/asterix_final.xml")
  -- game.plot("output.png", true)
  export_tex(game, "/home/talkie/Documents/Stage/DebateGames/docs/final_report/asterix.tex")

end
