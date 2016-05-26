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
  local nb_tests     = max_vertices * max_games * (max_players-1)
  local options      = {
    xlabel = "round",
    ylabel = "value",
    title  = nil
  }
  -- apply a specific rule on game with 2 to max_players players, max_graphs different trees and max_games different games for each tree and each number of players.
  local dest = "../tests/tests_games_q_" .. val_question .. "_" .. os.date("%d_%m_%H_%M_%S") .. "/"
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
        local graph    = graph_generator(nb_vertices)
        local dest_j   = dest_v .. "game_" .. j .. ".xml"
        local dest_tex = dest_v .. "game_" .. j .. ".tex"
        local game     = game_generator(players, graph)
        export_game(game, dest_j)
        export_tex(game, dest_tex)
        -- test tau_1
        local dest_log = dest_v .. "game_" .. j .. "_tau_1.log"
        saa.computeSAA   (game, "tau_1", nil, val_question, 5)
        rules.mindChanged(game, "tau_1", nil, val_question, 5, {view = "all", file = dest_log})
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
        game.restoreGame()
        -- test tau_2
        dest_log = dest_v .. "game_" .. j .. "_tau_2.log"
        saa.computeSAA   (game, "tau_2", nil, val_question, 5)
        rules.mindChanged(game, "tau_2", nil, val_question, 5, {view = "all", file = dest_log})
        dest_j        = dest_v .. "game_" .. j .. "_tau_2.xml"
        dest_tex      = dest_v .. "game_" .. j .. "_tau_2.tex"
        dest_png      = dest_v .. "game_" .. j .. "_tau_2.png"
        options.title = players     .. " players "
                     .. nb_vertices .. " vertices "
                     .. "game "     .. j
                     .. " function tau_2"
        game.plot  (dest_png, false, options)
        export_game(game, dest_j)
        export_tex(game, dest_tex)
        game.restoreGame()
        -- test L_&_M
        dest_log = dest_v .. "game_" .. j .. "_L_&_M.log"
        saa.computeSAA   (game, "L_&_M", 0.1, val_question, 5)
        rules.mindChanged(game, "L_&_M", 0.1, val_question, 5, {view = "all", file = dest_log})
        dest_j        = dest_v .. "game_" .. j .. "_L_&_M.xml"
        dest_tex      = dest_v .. "game_" .. j .. "_L_&_M.tex"
        dest_png      = dest_v .. "game_" .. j .. "_L_&_M.png"
        options.title = players     .. " players "
                     .. nb_vertices .. " vertices "
                     .. "game "     .. j
                     .. " function L&M"
        game.plot  (dest_png, false, options)
        export_tex(game, dest_tex)
        export_game(game, dest_j)
      end
    end
  end
end

-- do
--   test_random_games(1)
-- end

-- do
--   local change  = false
--   local game
--   local players
--   local nb_vertices
--   local options = {
--     xlabel = "round",
--     ylabel = "value",
--     title  = nil
--   }
--   while not change do
--     nb_vertices = 5
--     players     = 2
--     local graph       = graph_generator(nb_vertices)
--     game              = game_generator(players, graph)
--
--     -- test tau_1
--     saa.computeSAA   (game, "tau_1", nil, 1, 5)
--     rules.mindChanged(game, "tau_1", nil, 1, 5)
--     if game.changed > 0 then change = true else game = nil end
--   end
--   local dest = "../tests/test_changement_q_1_" .. os.date("%d_%m_%H_%M_%S") .. "/"
--   lfs.mkdir(dest)
--   local dest_j = dest .. "game_change_tau_1.xml"
--   export_game(game, dest_j)
--   dest_j         = dest .. "game_change.xml"
--   local dest_png = dest .. "game_change_tau_1.png"
--   local dest_tex = dest .. "game_change_tau_1.tex"
--   export_tex(game, dest_tex)
--   options.title  = players     .. " players "
--                 .. nb_vertices .. " vertices "
--                 .. " function tau_1"
--   game.plot  (dest_png, false, options)
--   game.restoreGame()
--   export_game(game, dest_j)
--
-- end


-- do
--   local sup_or_inf  = false
--   local game
--   local players
--   local nb_vertices
--   local options = {
--     xlabel = "round",
--     ylabel = "value",
--     title  = nil
--   }
--   while not sup_or_inf do
--     nb_vertices = 6
--     players     = 2
--     local graph       = graph_generator(nb_vertices)
--     game              = game_generator(players, graph)
--
--     -- test tau_1
--     saa.computeSAA   (game, "tau_1", nil, 1, 5)
--     rules.mindChanged(game, "tau_1", nil, 1, 5, players^nb_vertices)
--     local max_value = 0
--     local min_value = 1
--     for _,v in ipairs(game.players) do
--       if game.graphs[v].LM[1] > max_value then
--         max_value = game.graphs[v].LM[1]
--       end
--       if game.graphs[v].LM[1] < min_value then
--         min_value = game.graphs[v].LM[1]
--       end
--     end
--     if game.graphs.general.LM[#game.graphs.general.LM] > max_value or
--        game.graphs.general.LM[#game.graphs.general.LM] < min_value
--     then
--       sup_or_inf = true
--     else
--       game = nil
--     end
--   end
--   local dest = "../tests/tests_games_" .. os.date("%d_%m_%H_%M_%S") .. "/"
--   lfs.mkdir(dest)
--   local dest_j = dest .. "game_change.xml"
--   export_game(game, dest_j)
--   dest_j         = dest .. "game_change_tau_1.xml"
--   local dest_png = dest .. "game_change_tau_1.png"
--   options.title  = players     .. " players "
--                 .. nb_vertices .. " vertices "
--                 .. " function tau_1"
--   game.plot  (dest_png, false, options)
--   export_game(game, dest_j)
-- end



--
--
--
do
  local game = import_game("/home/talkie/Documents/Stage/DebateGames/tests/test_changement_q_0,5_26_05_10_49_06/game_change.xml")

  saa.computeSAA(game, "tau_1", nil, 1, 10)
  rules.mindChanged(game, "tau_1", nil, 1, 10, 300)
  -- for k, v in pairs(game.graphs) do
  --   if type(v) == "table" then
  --     print("\n\n", k)
  --     v.print_graph(v)
  --   end
  -- end
  game.plot("output.png", true)
  -- local dest_j = "tests_games_12_05_ 17_36_27/3_players/game_8_after.xml"
  -- export_game(game, "/home/talkie/Documents/Stage/DebateGames/tests/tests_games_20_05_16_55_15/3_players/10_vertices/game_16_tau_1_bis.xml")
end
