local game = require "import_xml"

local function SAA(players, graph, precision)
  -- initialisation
  local tho = {}
  for k, v in pairs(graph.vertices) do
    local sgn
    if v.likes - v.dislikes < 0 then sgn = -1 else sgn = 1 end

    local eps     = players / math.log(0.04)
    local int_exp = - math.abs(v.likes - v.dislikes) / eps
    tho[k]        = 0.5 * (1 + sgn * (1 - math.exp(int_exp)))
    v.LM          = tho[k]
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
end

do
  for _, g in pairs(game.graphs) do
    SAA(game.players, g, 0.001)
  end
end

-- game.print_table(game)
for k, v in pairs(game.graphs) do
  print (k, "q", v.vertices.q.LM)
end
