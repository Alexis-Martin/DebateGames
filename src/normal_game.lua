local saa   = require "saa"
local rules = require "rules"
local yaml  = require "yaml"
local tools = require "tools"

local normal_game = {}

local gridEnumeration

local function strokesList(game)
    -- All possible strokes by arguments
  local arg_list = {}
  for _, v in pairs(game.graphs.general.vertices) do
    if v.tag ~= "question" then
      table.insert(arg_list, {-1, 0, 1})
    end
  end

  local list = gridEnumeration(arg_list)

  return list
end

function gridEnumeration(list)
  local pointers = {}
  local grid     = {}

  for _, _ in pairs(list) do
    table.insert(pointers, 1)
  end

  local sum = 0
  local global_sum = 0
  for _,v in ipairs(list) do
    global_sum = global_sum + #v
  end

  while sum ~= global_sum do
    local case = {}
    for i, v in ipairs(pointers) do
      table.insert(case, tools.deepcopy(list[i][v]))
    end

    table.insert(grid, case)

    sum = 0
    for _, p in ipairs(pointers) do
      sum = sum + p
    end

    pointers[1] = pointers[1] + 1
    local i = 1
    while i < #pointers and pointers[i] == #list[i] + 1 do
      pointers[i] = 1
      i = i + 1
      pointers[i] = pointers[i] + 1
    end
  end


  return grid
end

local function applyCombination(game, combination)
  local graph = tools.deepcopy(game.graphs.general)
  for _, c in ipairs(combination) do
    local na = 1
    for k, a in pairs(graph.vertices) do
      if a.tag ~= "question" then
        if c[na] == -1 then
          if not graph.vertices[k].dislikes then
            graph.vertices[k].dislikes = 0
          end
          graph.vertices[k].dislikes = graph.vertices[k].dislikes + 1
        elseif c[na] == 1 then
          if not graph.vertices[k].likes then
            graph.vertices[k].likes = 0
          end
          graph.vertices[k].likes = graph.vertices[k].likes + 1
        end
        na = na + 1
      end
    end
  end

  return graph
end

function normal_game.normalForm(game)
  local players_strokes = {}
  for _, _ in ipairs(game.players) do
    table.insert(players_strokes, strokesList(game))
  end

  local combinations = gridEnumeration(players_strokes)

  local normal_form = {}
  rules.setGame(game)
  for _, v in ipairs(combinations) do
    local graph = applyCombination(game, v)
    local lm    = rules.computeSAA(graph)
    table.insert(normal_form, {[tools.deepcopy(v)] = lm})
  end

  return normal_form
end

function normal_game.isValueInside(game, normal_form)
  assert(#game.players == 2)

  local players_value = {}

  for _, v in pairs(normal_form) do
    local t1
    local t2
    local lm
    for k, l in pairs(v) do
      t1 = k[1]
      t2 = k[2]
      lm = l
    end

    if tools.equals(t1, t2) then
      table.insert(players_value, lm)
    end
  end


  for _, lm1 in ipairs(players_value) do
    for _, lm2 in ipairs(players_value) do
      if lm1 ~= lm2 then
        local b = false
        for _, v in pairs(normal_form) do
          for _, l in pairs(v) do
            if (lm1 < l and l < lm2) or (lm2 < l and l < lm1) then
              print(lm1, l, lm2)
              b = true
            end
          end
          if b == true then break end
        end
        if b == false then
          return false
        end
      end
    end
  end
  return true
end
  -- assert(#game.players == 2)
  -- game.restoreGame()
  -- local lm_start = saa.computeGraphSAA(2, game.graphs.general, "tau_1", nil, 1, 8)
  -- local nb = 0
  -- for _, j1_a1 in ipairs({-1, 0, 1}) do
  --   for _, j1_a2 in ipairs({-1, 0, 1}) do
  --     for _, j1_a3 in ipairs({-1, 0, 1}) do
  --       for _, j2_a1 in ipairs({-1, 0, 1}) do
  --         for _, j2_a2 in ipairs({-1, 0, 1}) do
  --           for _, j2_a3 in ipairs({-1, 0, 1}) do
  --             game.restoreGame()
  --             if j1_a1 == -1 then
  --               --game.addDislike(nil, "a1")
  --               game.addDislike("joueur 1", "a1")
  --             elseif j1_a1 == 1 then
  --               --game.addLike(nil, "a1")
  --               game.addLike("joueur 1", "a1")
  --             end
  --
  --
  --             if j1_a2 == -1 then
  --               --game.addDislike(nil, "a2")
  --               game.addDislike("joueur 1", "a2")
  --             elseif j1_a2 == 1 then
  --               --game.addLike(nil, "a2")
  --               game.addLike("joueur 1", "a2")
  --             end
  --
  --
  --             if j1_a3 == -1 then
  --               --game.addDislike(nil, "a3")
  --               game.addDislike("joueur 1", "a3")
  --             elseif j1_a3 == 1 then
  --               --game.addLike(nil, "a3")
  --               game.addLike("joueur 1", "a3")
  --             end
  --
  --
  --             if j2_a1 == -1 then
  --               --game.addDislike(nil, "a1")
  --               game.addDislike("joueur 2", "a1")
  --             elseif j2_a1 == 1 then
  --               --game.addLike(nil, "a1")
  --               game.addLike("joueur 2", "a1")
  --             end
  --
  --
  --             if j2_a2 == -1 then
  --               --game.addDislike(nil, "a2")
  --               game.addDislike("joueur 2", "a2")
  --             elseif j2_a2 == 1 then
  --               --game.addLike(nil, "a2")
  --               game.addLike("joueur 2", "a2")
  --             end
  --
  --
  --             if j2_a3 == -1 then
  --               --game.addDislike(nil, "a3")
  --               game.addDislike("joueur 2", "a3")
  --             elseif j2_a3 == 1 then
  --               --game.addLike(nil, "a3")
  --               game.addLike("joueur 2", "a3")
  --             end
  --
  --             nb = nb + 1
  --
  --             local lm1 = saa.computeGraphSAA(1, game.graphs["joueur 1"], "tau_1", nil, 1, 8)
  --             local lm2 = saa.computeGraphSAA(1, game.graphs["joueur 2"], "tau_1", nil, 1, 8)
  --             local play = false
  --             if (lm1 <= lm_start  and lm_start <= lm2) or
  --                (lm2 <= lm_start and lm_start <= lm1) then
  --               saa.computeSAA   (game, "tau_1", nil, 1, 8)
  --               rules.mindChanged(game)
  --               play = true
  --             end
  --
  --             print("a1\t\t|a2\t\t|a3")
  --             print("(".. (game.graphs.general.vertices.a1.likes or 0) .. ", " .. (game.graphs.general.vertices.a1.dislikes or 0) .. ")" ..
  --             "\t\t|("..(game.graphs.general.vertices.a2.likes or 0) .. ", " .. (game.graphs.general.vertices.a2.dislikes or 0) .. ")" ..
  --             "\t\t|("..(game.graphs.general.vertices.a3.likes or 0) .. ", " .. (game.graphs.general.vertices.a3.dislikes or 0) .. ")")
  --             print(lm1 .. "\t|" .. lm2 .. "\t|" .. lm_start .. "\t|" .. tostring(play))
  --             print("-----------------------------")
  --
  --             if j2_a3 == -1 then
  --               game.removeDislike(nil, "a3")
  --               game.removeDislike("joueur 2", "a3")
  --             elseif j2_a3 == 1 then
  --               game.removeLike(nil, "a3")
  --               game.removeLike("joueur 2", "a3")
  --             end
  --
  --             if j2_a2 == -1 then
  --               game.removeDislike(nil, "a2")
  --               game.removeDislike("joueur 2", "a2")
  --             elseif j2_a2 == 1 then
  --               game.removeLike(nil, "a2")
  --               game.removeLike("joueur 2", "a2")
  --             end
  --
  --             if j2_a1 == -1 then
  --               game.removeDislike(nil, "a1")
  --               game.removeDislike("joueur 2", "a1")
  --             elseif j2_a1 == 1 then
  --               game.removeLike(nil, "a1")
  --               game.removeLike("joueur 2", "a1")
  --             end
  --
  --             if j1_a3 == -1 then
  --               game.removeDislike(nil, "a3")
  --               game.removeDislike("joueur 1", "a3")
  --             elseif j1_a3 == 1 then
  --               game.removeLike(nil, "a3")
  --               game.removeLike("joueur 1", "a3")
  --             end
  --
  --             if j1_a2 == -1 then
  --               game.removeDislike(nil, "a2")
  --               game.removeDislike("joueur 1", "a2")
  --             elseif j1_a2 == 1 then
  --               game.removeLike(nil, "a2")
  --               game.removeLike("joueur 1", "a2")
  --             end
  --
  --             if j1_a1 == -1 then
  --               game.removeDislike(nil, "a1")
  --               game.removeDislike("joueur 1", "a1")
  --             elseif j1_a1 == 1 then
  --               game.removeLike(nil, "a1")
  --               game.removeLike("joueur 1", "a1")
  --             end
  --           end
  --         end
  --       end
  --     end
  --   end
  -- end
  -- print (nb, nb / 27)

local import_game     = require "import_xml"
local game = import_game("/home/talkie/Documents/Stage/DebateGames/src/game_1.xml")
-- normal_game.NormalForm(game)

local lsit = normal_game.normalForm(game)
print(tostring(normal_game.isValueInside(game, lsit)))
