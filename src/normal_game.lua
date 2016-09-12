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
  local check_bst = {}
  for q, lm1 in ipairs(players_value) do
    for w, lm2 in ipairs(players_value) do
      if lm1 ~= lm2 then
        local b   = false
        local b_s = false
        for k, lm in pairs(normal_form) do
          if (lm1 < lm and lm < lm2) or (lm2 < lm and lm < lm1) then
            b = true

            if stability_check and b_s_t then
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
                      check_bst.player    = 1
                      check_bst.lm_player = lm1
                      check_bst.lm_other  = lm2
                      check_bst.lm        = lm
                      check_bst.better_lm = l
                      check_bst.votes1    = check_1[q]
                      check_bst.votes2    = check_1[w]
                      check_bst.last_vote = k
                      check_bst.new_vote  = str_v
                      b_l = false
                    elseif j == 2 and math.abs(lm2 - l) < math.abs(lm2 - lm) then
                      check_bst.player    = 2
                      check_bst.lm_player = lm2
                      check_bst.lm_other  = lm1
                      check_bst.lm        = lm
                      check_bst.better_lm = l
                      check_bst.votes1    = check_1[q]
                      check_bst.votes2    = check_1[w]
                      check_bst.last_vote = k
                      check_bst.new_vote  = str_v
                      b_l = false
                    end
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
        if not b_s and b_s_t then
          b_s_t = false
          print("b_s_t = " .. tostring(b_s_t))
          for k, v in pairs(check_bst) do
            print(k .. " = " .. tostring(v))
          end
        end
      end
    end
  end
  return true, b_s_t
end

local import_game     = require "import_xml"
local game = import_game("/home/talkie/Documents/Stage/DebateGames/src/game_1.xml")

local lsit = normal_game.normalForm(game)
local a, b = normal_game.isValueInside(game, lsit, true)
print(tostring(a), tostring(b))

return normal_game
