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

local function applyCombination(graph, combination)
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
    local graph = tools.deepcopy(game.graphs.general)
    applyCombination(graph, v)
    local lm    = rules.computeSAA(graph)
    local str_v = table.concat({table.concat(v[1], ","), table.concat(v[2], ",")}, "|")
    normal_form[str_v] = lm
  end

  return normal_form
end

function normal_game.isValueInside(game, normal_form, stability_check)
  assert(#game.players == 2)

  local players_value = {}
  local check_1 = {}
  for k, lm in pairs(normal_form) do
    local s = tools.split(k, "[-,%w]+")
    if #s == 2 and s[1] == s[2] then
      table.insert(players_value, lm)
      table.insert(check_1, k)
    end
  end

  if stability_check then rules.setGame(game) end
  local b_s_t = true
  for q, lm1 in ipairs(players_value) do
    for w, lm2 in ipairs(players_value) do
      if lm1 ~= lm2 then
        local b = false
        local b_s = false
        for k, lm in pairs(normal_form) do
          if (lm1 < lm and lm < lm2) or (lm2 < lm and lm < lm1) then
            b = true

            if stability_check and not b_s_t then
              -- for both players we check if it is an equilibrium
              local b_l = true
              local s = tools.split(k, "[-,%w]+")
              for j = 1, 2 do
                local comb = tools.split(s[j], "[-%w]+")
                for h,_ in ipairs(comb) do
                  comb[h] = tonumber(comb[h])
                end

                -- for all arguments we check if there is a better move
                for i=1, #comb do

                  -- we check with the two other possible values
                  for _ = 1, 2 do
                    -- change the value of the vote i
                    comb[i] = comb[i] + 1
                    comb[i] = ((comb[i] + 1)%3) - 1


                    -- we create the index of the current vote
                    local str_v
                    if j == 1 then
                      str_v = table.concat(comb, ",") .. "|" .. s[2]
                    else
                      str_v = s[1] .. "|" .. table.concat(comb, ",")
                    end

                    -- value for the current vote
                    local l = normal_form[str_v]

                    -- if the value is nearest it's not an equilibrium
                    if j == 1 and math.abs(lm1 - l) < math.abs(lm1 - lm) then
                      if check_1[q] == "-1,-1,1|-1,-1,1" and check_1[w] == "1,1,0|-1,1,0" and lm1 == 0.019608 and lm2 == 0.0198 then
                        print(str_v, k, lm1, l, lm, lm2)
                      end
                      b_l = false
                    elseif j == 2 and math.abs(lm2 - l) < math.abs(lm2 - lm) then
                      if check_1[q] == "-1,-1,1|-1,-1,1" and check_1[w] == "1,1,0|-1,1,0" and lm1 == 0.019608 and lm2 == 0.0198 then
                        print(str_v, k, lm2, l, lm, lm1)
                      end
                      b_l = false
                    end
                    if b_l == false then break end
                  end
                  comb[i] = comb[i] + 1
                  comb[i] = ((comb[i] + 1)%3) - 1
                  if b_l == false then break end
                end
                if b_l == false then break end
              end
              b_s = b_l
              if b_s then break end
            end

          end
          if b == true and not stability_check then break end

          if b == true and b_s then break end
        end
        if b == false then return false, false end
        if not b_s then
          b_s_t = false
        end
      end
    end
  end
  return true, b_s_t
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

local lsit = normal_game.normalForm(game)
local a, b = normal_game.isValueInside(game, lsit, true)
print(tostring(a), tostring(b))
