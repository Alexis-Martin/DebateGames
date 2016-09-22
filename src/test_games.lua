local game_generator  = require "game_generator"
local graph_generator = require "graph_generator"
local lfs             = require "lfs"
local mind_changed    = require "rules_mind_changed"
local yaml            = require "yaml"
local import_game     = require "import_xml"


local function test_random_games(val_question)
  local max_players  = 2
  local max_games    = 1
  local max_vertices = 15
  local precision    = 8
  local dynamique    = "round_robin"
  local type_vote    = "best"
  local compute_agg  = false
  local compute_mean = false
  local log_details  = "strokes"
  local check_cycle  = true
  local graphGen     = graph_generator.generateTree

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

  for players = 2, max_players do
    local dest_p = dest .. players .. "_players/"
    lfs.mkdir(dest_p)
    for nb_vertices = 1, max_vertices do
      local dest_v = dest_p .. nb_vertices .. "_vertices/"
      lfs.mkdir(dest_v)
      for j = 1, max_games do
        print((players-1) * max_vertices * max_games + (nb_vertices-1) * max_games + j .. "/" .. nb_tests)

        local graph    = graphGen(nb_vertices)
        local dest_j   = dest_v .. "game_" .. j .. ".xml"
        local dest_tex = dest_v .. "game_" .. j .. ".tex"
        local game     = game_generator(players, graph)
        game:exportXml(dest_j, "all")
        game:exportTex(dest_tex)

        -- test tau_1 with best
        parameters.type_vote = "best"
        local dest_log      = dest_v .. "best_"
                           .. j .. "_tau_1_log.log"
        parameters.fun      = "tau_1"
        parameters.log_file = dest_log

        local rules = mind_changed.create(game)
        rules:setParameters(parameters)
        rules:apply()
        dest_j         = dest_v .. "best_" .. j .. "_tau_1.xml"
        dest_tex       = dest_v .. "best_" .. j .. "_tau_1.tex"
        local dest_png = dest_v .. "best_" .. j .. "_tau_1.png"
        local normal_f = dest_v .. "normal_form_" .. j .. "_tau_1.yaml"
        options.title  = players     .. " players "
                      .. nb_vertices .. " vertices "
                      .. "best "     .. j
                      .. " function tau_1"
        rules:plot  {
            output = dest_png,
            open   = false,
            option = options
          }

        game:exportXml(dest_j, "all")
        game:exportTex(dest_tex)
        rules:equilibriumExistence()
        --
        -- local fic = io.open(normal_f, "w")
        -- io.output(fic)
        -- io.write(yaml.dump())

        if game.cycle then
          return
        end
      end
    end
  end
end
--
-- do
--   test_random_games(1)
-- end
--
-- do
--   local nb_vertices = 4
--   local players     = 2
--   local graphGen    = graph_generator.generateGraph
--
--   local b = true
--   local graph
--   local game
--   local dump
--   local count = 0
--
--   while b do
--     print (count)
--     count = count + 1
--     graph       = graphGen({n_vertices = nb_vertices})
--     game        = game_generator(players, graph)
--     local rules = mind_changed.create(game)
--     b, dump     = rules:equilibriumExistence()
--   end
--
--   local date = os.date("%d_%m_%H_%M")
--   local dest_xml   = "game_" .. date .. ".xml"
--   local dest_tex   = "game_" .. date .. ".tex"
--   local dest_log   = "game_" .. date .. "_log.log"
--   game:exportXml(dest_xml, "all")
--   game:exportTex(dest_tex)
--   local fic = io.open(dest_log, "w")
--   io.output(fic)
--   io.write(dump)
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
--   local players      = 2
--   local vertices     = 4
--   local precision    = 8
--   local dynamique    = "round_robin"
--   local type_vote    = "best"
--   local compute_agg  = false
--   local compute_mean = false
--   local log_details  = "all"
--   local check_cycle  = true
--   local epsilon      = 0.1
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
--   parameters.fun      = "L_&_M"
--   parameters.log_file = "cycle_test_na_graph_log.log"
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
--     local graph    = graph_generator.generateNAGraph{
--                       n_vertices = vertices, max_edges  = 2*vertices
--                     }
--     game     = game_generator(players, graph)
--     export_game(game, "cycle_test_na_graph_init.xml")
--     export_tex(game, "cycle_test_na_graph_init.tex")
--
--     rules.setGame(game)
--     rules.apply()
--     cycle = game.cycle
--   end
--
--   game.plot  ("cycle_test_na_graph.png", false, options)
--   export_game(game, "cycle_test_na_graph.xml")
--   export_tex(game, "cycle_test_na_graph.tex")
-- end





do
  local game = import_game("/home/talkie/Documents/Stage/DebateGames/tests/BUG_CYCLE_LM/4_vertices_1/cycle_LM.xml")
  local rules = mind_changed.create(game)
  rules:setParameters {fun = "L_&_M", epsilon = 3.4, }
  rules:computeSAA()

  print(game:getGraph("general"):dump())
end
