local game_generator  = require "game_generator"
local graph_generator = require "graph_generator"
local lfs             = require "lfs"
local mind_changed    = require "rules_mind_changed"
local yaml            = require "yaml"
local import_game     = require "import_xml"
local tools           = require "tools"
local boxplot         = require "boxplot"

local function test_random_games(val_question)
  local max_players  = 3
  local max_games    = 5
  local max_vertices = 15
  local precision    = 8
  local dynamique    = "round_robin"
  local type_vote    = "best"
  local compute_agg  = true
  local compute_mean = true
  local log_details  = "all"
  local check_cycle  = false
  local graphGen     = graph_generator.generateTree
  local start        = "aggregation"

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
    check_cycle  = check_cycle,
    start        = start
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
      end
    end
  end
end
-- --
do
  test_random_games(1)
end










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













-- STATS MOYENNE AND AGGREGATION
-- do
--   local function stats(nb_tests, nb_players, nb_vertices, graph_fun, param)
--     local values_mean  = {}
--     local values_agg   = {}
--     local lms          = {}
--     local lms_mean     = {}
--     local lms_agg      = {}
--     local nb_same_mean = 0
--     local nb_same_agg  = 0
--     local total_test   = nb_tests
--
--     while nb_tests > 0 do
--       nb_tests       = nb_tests - 1
--       if nb_tests % 100 == 0 then
--         print("intern test : " .. nb_tests)
--       end
--       local graph    = graph_fun(nb_vertices)
--       local game     = game_generator(nb_players, graph)
--       local rule     = mind_changed.create(game)
--       if param then rule:setParameters(param) end
--       rule:apply()
--
--       -- save results
--       local dist_LM_m = math.abs(game:getLM()[#game:getLM()].value - game:getTag("mean"))
--
--       if dist_LM_m == 0 then nb_same_mean = nb_same_mean + 1 end
--
--       if not values_mean.min then
--         values_mean.min = tools.round(dist_LM_m, 2)
--       elseif values_mean.min > dist_LM_m then
--         values_mean.min = tools.round(dist_LM_m, 2)
--       end
--
--       if not values_mean.max then
--         values_mean.max = tools.round(dist_LM_m, 2)
--       elseif values_mean.max < dist_LM_m then
--         values_mean.max = tools.round(dist_LM_m, 2)
--       end
--       table.insert(lms_mean, dist_LM_m)
--
--       local dist_LM_a = math.abs(game:getLM()[#game:getLM()].value - game:getTag("aggregate_value"))
--
--       if dist_LM_a == 0 then nb_same_agg = nb_same_agg + 1 end
--
--       if not values_agg.min then
--         values_agg.min = tools.round(dist_LM_a, 2)
--       elseif values_agg.min > dist_LM_a then
--         values_agg.min = tools.round(dist_LM_a, 2)
--       end
--
--       if not values_agg.max then
--         values_agg.max = tools.round(dist_LM_a, 2)
--       elseif values_agg.max < dist_LM_a then
--         values_agg.max = tools.round(dist_LM_a, 2)
--       end
--       table.insert(lms, game:getLM()[#game:getLM()].value)
--       table.insert(lms_agg     , dist_LM_a)
--     end
--
--     values_mean.moyenne_valeur_jeu = 0
--     for _, v in ipairs(lms) do
--       values_mean.moyenne_valeur_jeu = values_mean.moyenne_valeur_jeu + v
--     end
--     values_mean.moyenne_valeur_jeu = tools.round(values_mean.moyenne_valeur_jeu / #lms, 2)
--
--     values_mean.mean = 0
--     for _, v in ipairs(lms_mean) do
--       values_mean.mean = values_mean.mean + v
--     end
--     values_mean.mean = tools.round(values_mean.mean / #lms_mean, 2)
--
--     table.sort(lms_mean)
--     if #lms_mean % 4 == 0 then
--       values_mean.q1   = tools.round(lms_mean[#lms_mean/4], 2)
--       values_mean.q3   = tools.round(lms_mean[(#lms_mean/4) * 3], 2)
--       values_mean.med  = tools.round(lms_mean[#lms_mean/2], 2)
--     else
--       local f = math.floor(#lms_mean/4)
--       values_mean.q1   = tools.round((lms_mean[f] + lms_mean[f+1]) / 2, 2)
--       values_mean.q3   = tools.round((lms_mean[f * 3] + lms_mean[f * 3+1]) / 2, 2)
--       values_mean.med  = tools.round((lms_mean[math.floor(#lms_mean/2)] + lms_mean[math.ceil(#lms_mean/2)]) / 2, 2)
--     end
--
--     values_agg.moyenne_valeur_jeu = values_mean.moyenne_valeur_jeu
--     values_agg.mean = 0
--     for _, v in ipairs(lms_agg) do
--       values_agg.mean = values_agg.mean + v
--     end
--     values_agg.mean = tools.round(values_agg.mean / #lms_agg, 2)
--
--     table.sort(lms_agg)
--     if #lms_agg % 4 == 0 then
--       values_agg.q1   = tools.round(lms_agg[#lms_agg/4], 2)
--       values_agg.q3   = tools.round(lms_agg[(#lms_agg/4) * 3], 2)
--       values_agg.med  = tools.round(lms_agg[#lms_agg/2], 2)
--     else
--       local f = math.floor(#lms_agg/4)
--       values_agg.q1   = tools.round((lms_agg[f] + lms_agg[f]) / 2, 2)
--       values_agg.q3   = tools.round((lms_agg[f * 3] + lms_agg[f * 3 + 1]) / 2, 2)
--       values_agg.med  = tools.round((lms_agg[math.floor(#lms_agg/2)] + lms_agg[math.ceil(#lms_agg/2)]) / 2, 2)
--     end
--
--     nb_same_mean = (nb_same_mean / total_test) * 100
--     nb_same_agg  = (nb_same_agg  / total_test) * 100
--
--     return values_mean, values_agg, nb_same_mean, nb_same_agg
--   end
--
--
--   local max_players  = 8
--   local nb_vertices  = 15
--   local graphGen     = graph_generator.generateTree
--   local nb_tests     = 5000
--   local x_label      = "nombres de joueurs"
--   local y_label      = "valeur du jeu"
--   local title_mean   = "Distance à la moyenne, Arbre, " .. nb_vertices .. " arguments (" .. nb_tests .. " tests)"
--   local title_agg    = "Distance à l'aggregation, Arbre, " .. nb_vertices .. " arguments (" .. nb_tests .. " tests)"
--   local output_mean  = "../tests/stats/" .. nb_vertices .. "_" .. nb_tests .. "_mean.tex"
--   local output_agg  = "../tests/stats/" .. nb_vertices .. "_" .. nb_tests .. "_agg.tex"
--   local color_mean   = {
--     moyenne_valeur_jeu = "0066ff",
--     mean         = "cc0000"
--   }
--   local color_agg    = {
--     moyenne_valeur_jeu  = "0066ff",
--     mean                = "cc0000"
--   }
--
--
--   -- rules parameters
--   local param = {
--     compute_agg  = true,
--     compute_mean = true,
--     start        = "aggregation"
--   }
--
--   local save_values_m = {}
--   local save_values_a = {}
--   local success_m     = {}
--   local success_a     = {}
--
--   for i = 2, max_players do
--     local values_m, values_a, percent_m, percent_a = stats(nb_tests, i, nb_vertices, graphGen, param)
--     values_m.x = i
--     values_a.x = i
--     table.insert(save_values_a, values_a)
--     table.insert(save_values_m, values_m)
--     success_a[i] = percent_a
--     success_m[i] = percent_m
--   end
--   save_values_m.color   = color_mean
--   save_values_m.x_label = x_label
--   save_values_m.y_label = y_label
--   save_values_m.title   = title_mean
--   save_values_m.success = success_m
--   boxplot(save_values_m, output_mean)
--
--   save_values_a.color   = color_agg
--   save_values_a.x_label = x_label
--   save_values_a.y_label = y_label
--   save_values_a.title   = title_agg
--   save_values_a.success = success_a
--   boxplot(save_values_a, output_agg)
-- end










-- IMPORT GAME AND PLAY WITH IT
-- do
--   local game = import_game("/home/talkie/Documents/Stage/DebateGames/tests/BUG_CYCLE_LM/4_vertices_1/cycle_LM.xml")
--   local rules = mind_changed.create(game)
--   -- rules:setParameters {fun = "L_&_M", epsilon = 3.4, }
--   rules:apply()
--   -- rules:saveParameters()
--   -- print(game:getGraph("general"):dump())
--   rules:plot({output ="../tests/just_test_plot.png", open = true})
-- end
