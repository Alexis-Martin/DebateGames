local SAA = {}

-- if is_tho1 is true then we use the first definition of tho else we use the second definition
local function round(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end
function SAA.computeGraphSAA(nb_players, graph, is_tho1, val_question, precision, save_value)
  local tho = {}
  for k, v in pairs(graph.vertices) do
    local eps     = -nb_players / math.log(0.04)
    v.likes       = v.likes    or 0
    v.dislikes    = v.dislikes or 0
    local int_exp = (v.likes - v.dislikes) / eps
    if type(val_question) == "number" and v.tag == "question" then
      tho[k] = val_question
    elseif (not is_tho1) and v.likes == 0 and v.dislikes == nb_players then
      tho[k] = 0
    elseif (not is_tho1) and v.dislikes == 0 and v.likes == nb_players then
      tho[k] = 1
    elseif v.likes - v.dislikes < 0 then
      tho[k] = 0.5 * math.exp(int_exp)
    else
      tho[k] = 1 - 0.5 * math.exp(-int_exp)
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
      if save_value and not graph.LM then
        graph.LM = {}
      end
      if save_value then graph.LM[#graph.LM + 1] = v.LM end
      return v.LM
    end
  end
end

function SAA.computeSAA(game, is_tho1,val_question, precision)
  for k, graph in pairs(game.graphs) do
    if k == "general" then
      SAA.computeGraphSAA(#game.players, graph, is_tho1,val_question, precision, true)
    else
      SAA.computeGraphSAA(1, graph, is_tho1, val_question, precision, true)
    end
  end
end

return SAA
