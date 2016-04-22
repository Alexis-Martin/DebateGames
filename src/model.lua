local game = require "import_xml"

function game.SAA(players, graph, precision)
  -- initialisation
  local tho = {}
  for k, v in pairs(graph.vertices) do
    local eps     = -players / math.log(0.04)
    local int_exp = (v.likes - v.dislikes) / eps
    --
    -- if v.likes == 0 and v.dislikes == players then
    --   tho[k] = 0
    -- elseif v.dislikes == 0 and v.likes == players then
    --   tho[k] = 1
    if v.likes - v.dislikes < 0 then
      tho[k] = 0.5 * math.exp(int_exp)
    else
      tho[k] = 1 - 0.5 * math.exp(-int_exp)
    end
    v.LM = tho[k]
  end

  local function iter()
    local loop = false

    local last_LM = {}
    for k, v in pairs(graph.vertices) do
      last_LM[k] = v.LM
    end

    for k, v in pairs(graph.vertices) do
      local conorm = 0

      if type(v.attackers) == "table" then
        for k1, _ in pairs(v.attackers) do
          conorm = conorm + last_LM[k1] - conorm * last_LM[k1]
        end
      end

      v.LM = tho[k] * (1 - conorm)

      if math.abs(v.LM - last_LM[k]) > precision then
        loop = true
      end
    end

    if loop then
      iter()
    end
  end

  iter()
  for _,v in pairs(graph.vertices) do
    if v.tag == "question" then
      graph.LM = v.LM
      break
    end
  end
end

do
  for _, g in pairs(game.graphs) do
    game.SAA(game.players, g, 0.001)
  end
end

-- game.print_table(game)
for k, v in pairs(game.graphs) do
  for k1, v1 in pairs(v.vertices) do
    print (k, k1, v1.LM)
  end
end

return game
