local game = require "import_xml"

local function SAA(graph, eps)
  -- initialisation
  for _, v in pairs(graph.vertices) do
    v.LM = (1 + v.likes) / (1 + v.likes + v.dislikes + eps)
  end

  local function iter(marge)
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

      v.LM = ((1 + v.likes) / (1 + v.likes + v.dislikes + eps)) * (1 - conorm)

      if math.abs(v.LM - last_LM[k]) > marge then
        loop = true
      end
    end

    if loop then
      iter(marge)
    end
  end

  iter(0,00001)
end

do
  for _, g in pairs(game.graphs) do
    -- if g.view ~= "general" then
      SAA(g, 0.2)
    -- end
  end
end

-- game.print_table(game)

for k, v in pairs(game.graphs) do
  print (k, "q", v.vertices.q.LM)
end
