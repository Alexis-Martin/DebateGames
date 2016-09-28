local game_generator  = require "game_generator"
local graph_generator = require "graph_generator"
local lfs             = require "lfs"
local mind_changed    = require "rules_mind_changed"
local yaml            = require "yaml"
local import_game     = require "import_xml"
local tools           = require "tools"
local boxplot         = require "boxplot"

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


-- STATS MOYENNE AND AGGREGATION
do
  local function stats(nb_tests, nb_players, nb_vertices, graph_fun, param)
    local values       = {}
    local means        = {}
    local aggregations = {}
    local lms          = {}

    while nb_tests > 0 do
      nb_tests       = nb_tests - 1
      if nb_tests % 100 == 0 then
        print("intern test : " .. nb_tests)
      end
      local graph    = graph_fun(nb_vertices)
      local game     = game_generator(nb_players, graph)
      local rule     = mind_changed.create(game)
      if param then rule:setParameters(param) end
      rule:apply()

      -- save results
      local LM = game:getLM()[#game:getLM()].value
      if not values.min then
        values.min = tools.round(LM, 2)
      elseif values.min > LM then
        values.min = tools.round(LM, 2)
      end

      if not values.max then
        values.max = tools.round(LM, 2)
      elseif values.max < LM then
        values.max = tools.round(LM, 2)
      end
      table.insert(means       , game:getTag("mean"))
      table.insert(aggregations, game:getTag("aggregate_value"))
      table.insert(lms         , LM)
    end
    values.mean_players = 0
    for _, v in ipairs(means) do
      values.mean_players = values.mean_players + v
    end
    values.mean_players = tools.round(values.mean_players / #means, 2)

    values.aggregation = 0
    for _, v in ipairs(aggregations) do
      values.aggregation = values.aggregation + v
    end
    values.aggregation = tools.round(values.aggregation / #aggregations, 2)

    values.mean = 0
    for _, v in ipairs(lms) do
      values.mean = values.mean + v
    end
    values.mean = tools.round(values.mean / #lms, 2)

    table.sort(lms)
    if #lms % 4 == 0 then
      values.q1   = tools.round(lms[#lms/4], 2)
      values.q3   = tools.round(lms[(#lms/4) * 3], 2)
      values.med  = tools.round(lms[#lms/2], 2)
    else
      local f = math.floor(#lms/4)
      local c = math.ceil(#lms/4)
      values.q1   = tools.round((lms[f] + lms[c]) / 2, 2)
      values.q3   = tools.round((lms[f * 3] + lms[c * 3]) / 2, 2)
      values.med  = tools.round((lms[math.floor(#lms/2)] + lms[math.ceil(#lms/2)]) / 2, 2)
    end
    return values
  end


  local max_players  = 8
  local nb_vertices  = 10
  local graphGen     = graph_generator.generateTree
  local nb_tests     = 5000
  local x_label      = "nombres de joueurs"
  local y_label      = "valeur du jeu"
  local output       = "../tests/stats_test.tex"
  local color        = {
    mean_players = "0066ff",
    aggregation  = "00cc66",
    mean         = "cc0000"
  }


  -- rules parameters
  local param = {
    compute_agg  = true,
    compute_mean = true,
  }

  local save_values = {}
  for i = 2, max_players do
    local values = stats(nb_tests, i, nb_vertices, graphGen, param)
    values.x = i
    table.insert(save_values, values)
  end
  save_values.color   = color
  save_values.x_label = x_label
  save_values.y_label = y_label
  boxplot(save_values, output)

  -- while nb_tests > 0 do
  --   nb_tests       = nb_tests - 1
  --   print(nb_tests)
  --   local vertices = math.random(2, max_vertices)
  --   local graph    = graphGen(vertices)
  --   local players  = math.random(2, max_players)
  --   local game     = game_generator(players, graph)
  --   local rule     = mind_changed.create(game)
  --   rule:setParameters(param)
  --   rule:apply()
  --
  --   local values = {
  --     start       = "no vote",
  --     normalise   = "without normalisation",
  --     graph       = game:getGraph():getClass(),
  --     dynamique   = rule:getParameter("dynamique"),
  --     type_vote   = rule:getParameter("type_vote"),
  --     fun         = rule:getParameter("fun"),
  --     test        = nb_tests,
  --     players     = players,
  --     vertices    = vertices,
  --     mean        = game:getTag("mean"),
  --     aggregation = game:getTag("aggregate_value"),
  --     gen_init    = game:getLM()[1].value,
  --     gen_final   = game:getLM()[#game:getLM()].value
  --   }
  --   for k, _ in pairs(game:getPlayers()) do
  --     values[k] = game:getLM(k)[1].value
  --   end
  --
  --   table.insert(save_values, values)
  -- end
  --
  -- local fic = "../tests/" .. os.date("%d_%m_%H_%M_") .."_stat_moy_agg.yaml"
  -- local file = io.open(fic, "w")
  -- io.output(file)
  -- io.write(yaml.dump(save_values))
  -- io.flush()
  --
  -- local g = {
  --   max_mean = math.abs(save_values[1].gen_final - save_values[1].mean),
  --   min_mean = math.abs(save_values[1].gen_final - save_values[1].mean),
  --   max_agg  = math.abs(save_values[1].gen_final - save_values[1].aggregation),
  --   min_agg  = math.abs(save_values[1].gen_final - save_values[1].aggregation),
  --   moy_mean = 0,
  --   moy_agg  = 0
  -- }
  --
  -- for _, v in ipairs(save_values) do
  --   if math.abs(v.gen_final - v.mean) > g.max_mean then
  --     g.max_mean = math.abs(v.gen_final - v.mean)
  --   end
  --   if math.abs(v.gen_final - v.mean) < g.min_mean then
  --     g.min_mean = math.abs(v.gen_final - v.mean)
  --   end
  --   if math.abs(v.gen_final - v.aggregation) > g.max_agg then
  --     g.max_agg = math.abs(v.gen_final - v.aggregation)
  --   end
  --   if math.abs(v.gen_final - v.aggregation) < g.min_agg then
  --     g.min_agg = math.abs(v.gen_final - v.aggregation)
  --   end
  --   g.moy_agg  = g.moy_agg  + math.abs(v.gen_final - v.aggregation)
  --   g.moy_mean = g.moy_mean + math.abs(v.gen_final - v.mean)
  -- end
  -- g.moy_agg  = g.moy_agg  / #save_values
  -- g.moy_mean = g.moy_mean / #save_values
  --
  -- for k,v in pairs(g) do
  --   print(k, v)
  -- end
end


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
