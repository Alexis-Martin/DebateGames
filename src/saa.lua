local SAA = {}

-- if is_tho1 is true then we use the first definition of tho else we use the second definition
local function round(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end
function SAA.computeGraphSAA(nb_players, graph, fun, epsilon, val_question, precision)
  local tho = {}
  epsilon = epsilon or 0
  for k, v in pairs(graph.vertices) do
    local eps     = -nb_players / math.log(0.04)
    v.likes       = v.likes    or 0
    v.dislikes    = v.dislikes or 0
    local int_exp = (v.likes - v.dislikes) / eps
    if type(val_question) == "number" and v.tag == "question" then
      tho[k] = val_question
    elseif fun == "tau_2" and v.likes == 0 and v.dislikes == nb_players then
      tho[k] = 0
    elseif fun == "tau_2" and v.dislikes == 0 and v.likes == nb_players then
      tho[k] = 1
    elseif (fun == "tau_1" or fun == "tau_2") and v.likes - v.dislikes < 0 then
      tho[k] = 0.5 * math.exp(int_exp)
    elseif (fun == "tau_1" or fun == "tau_2") and v.likes - v.dislikes >= 0 then
      tho[k] = 1 - 0.5 * math.exp(-int_exp)
    elseif fun == "L_&_M" and v.likes + v.dislikes + epsilon == 0 then
      tho[k] = 0
    elseif fun == "L_&_M" then
      tho[k] = v.likes / (v.likes + v.dislikes + epsilon)
    end
    v.LM = round(tho[k], precision)
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
      v.LM = round(v.LM, precision)
      if math.abs(v.LM - last_LM[k]) > 10^-precision then

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
      return v.LM
    end
  end
end

function SAA.computeSAA(game, fun, epsilon, val_question, precision)
  for k, graph in pairs(game.graphs) do
    local lm
    if k == "general" then
      lm = SAA.computeGraphSAA(#game.players, graph, fun, epsilon, val_question, precision)
    else
      lm = SAA.computeGraphSAA(1, graph, fun, epsilon, val_question, precision)
    end
    if not graph.LM then
      graph.LM = {}
    end
    graph.LM[#graph.LM + 1] = {run = #graph.LM + 1, value = lm}
  end
end

return SAA
