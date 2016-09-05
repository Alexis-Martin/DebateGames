local tools = require "tools"

local rules   = {}
rules.__index = rules
rules.__type  = "rules"

function rules.create()
  local r = {
    temp = {
      fun_p            = {},
      players_votes    = {},
      current_vote     = {},
      historical_shots = {},
      changed          = nil,
      pass             = nil,
      nb_nil           = nil
    },
    p = {}
  }
  setmetatable(r, rules)
  return r
end

rules.parameters = {
  rule         = "mindChanged",
  type_vote    = "best",
  dynamique    = "round_robin",
  compute_mean = true,
  compute_agg  = true,
  fun          = "tau_1",
  epsilon      = 0.1,
  val_question = 1,
  precision    = 8,
  log_details  = "all",
  check_cycle  = false
}


--- Change the parameters of the rules
-- Add new parameters and change them if the key already exists
-- @param parameters table (key, values) of parameters, if nil, back to default.
function rules:setParameters(parameters)
  if not self.p then self.p = {} end
  if type(parameters) == "table" then
    for k, v in pairs(parameters) do
      self.p[k] = v
    end
  else
    self.p = tools.deepcopy(rules.parameters)
  end
end

-- Set the game to apply the rule on it
-- @param game the game
function rules:setGame(game)
  self.game = game
end

-- reset each list of t to an empty list. if t = "all" then reset all lists.
function rules:reset(t)
  if t == "all" then
    self.temp.fun_p            = {}
    self.temp.players_votes    = {}
    self.temp.current_vote     = {}
    self.temp.historical_shots = {}
  elseif type(t) == "table" then
    for k, _ in ipairs(t) do
      if self.temp[k] then
        if type(self.temp[k]) == "table" then
          self.temp[k] = {}
        else
          self.temp[k] = nil
        end
      end
    end
  end
end

-- apply the rule on the game. If there is no game, the function raise an error.
function rules:apply()
  assert(self.game)
  self:reset("all")
  self:init()
  self:start()
end

-- apply the rule on the specific game. if game is nil, the function raise an error.
function rules:applyOn(game)
  self:setGame(game)
  self:apply()
end

-- apply the rule with the parameters parameters on the game, game. If one of the argument is nil, the function raise an error.
function rules:applyOnWith(game, parameters)
  self:setGame(game)
  self:setParameters(parameters)
  self:apply()
end


-- Compute the value with the aggregation of all players' votes
function rules:aggregationValue()
  assert(self.game)
  local graph = tools.deepcopy(self.game:getGraph("general"))
  for _, v in pairs(graph.vertices) do
    v:setTag("likes"   , 0)
    v:setTag("dislikes", 0)
  end

  for player, _ in pairs(self.game:getPlayers()) do
    for k, v in pairs(self.game:getGraph(player):getVertices()) do
      local like = graph:getVertexTag(k, "like")
      graph:setVertexTag(k, "like", like + (v:getTag("likes") or 0))
      local dislike = graph:getVertexTag(k, "dislike")
      graph:setVertexTag(k, "dislike", dislike + (v:getTag("dislikes") or 0))
    end
  end
  local result = rules.computeSAA(graph)
  self.game:setTag("aggregate_value", result)
  return result
end

-- Compute the mean players value
function rules.meanValue()
  assert(rules.game)
  local mean = 0
    for k, _ in pairs(rules.game:getGraphs()) do
      if k ~= "general" then
        assert(type(rules.game.getLM(k)) == "table")
        mean = mean + rules.game.getLM(k)[1].value
      end
    end
    mean = mean / #rules.game:getPlayers()
    rules.game:setTag("mean", mean)
    return mean
end

-- compute the social abstract argumentation algorithm on the game
function rules:computeSAA(graph)
  local function computeGraph(graph, nb_players)
    local I    = {}
    nb_players = nb_players or #self.game:getPlayers()
    local tho  = {}

    -- initialize I, a sequence which converge to LM
    for k, _ in pairs(graph:getVertices()) do
      I[k] = 0
    end

    -- compute the value of tau for each arg
    local eps = -nb_players / math.log(0.04)
    for k, v in pairs(graph:getVertices()) do
      v:setTag("likes",    (v:getTag("likes")    or 0))
      v:setTag("dislikes", (v:getTag("dislikes") or 0))
      local likes, dislikes = v:getTag("likes"), v:getTag("dislikes")
      local int_exp = (likes - dislikes) / eps

      if type(self.p.val_question) == "number" and v:getTag("tag") == "question" then
        tho[k] = self.p.val_question
      elseif self.p.fun == "tau_2" and likes == 0 and dislikes == nb_players then
        tho[k] = 0
      elseif self.p.fun == "tau_2" and dislikes == 0 and likes == nb_players then
        tho[k] = 1
      elseif (self.p.fun == "tau_1" or self.p.fun == "tau_2") and likes - dislikes < 0 then
        tho[k] = 0.5 * math.exp(int_exp)
      elseif (self.p.fun == "tau_1" or self.p.fun == "tau_2") and likes - dislikes >= 0 then
        tho[k] = 1 - 0.5 * math.exp(-int_exp)
      elseif self.p.fun == "L_&_M" and likes + dislikes + self.p.epsilon == 0 then
        tho[k] = 0
      elseif self.p.fun == "L_&_M" then
        tho[k] = likes / (likes + dislikes + self.p.epsilon)
      end
    end

    -- compute the sequence
    local loop = true
    local count = 0

    while loop do
      count = count + 1
      -- if count == 300 then print("======================") end
      loop = false
      local new_LM = {}
      for k, v in pairs(graph:getVertices()) do
        new_LM[k] = tho[k]
        if type(v:getAttackers()) == "table" then
          for k1, _ in pairs(v:getAttackers()) do
            new_LM[k] = new_LM[k] * (1 - I[k1])
          end
        end
        if math.abs(I[k] - new_LM[k]) >= 10^(-self.p.precision) then
          loop = true
        end
      end
      for k, _ in pairs(I) do
        I[k] = new_LM[k]
        -- if count >= 300 then print("I[" .. k .. "] = " .. I[k]) end
      end
      -- if count == 300 then export_tex(rules.game, "cycle_LM.tex") end
      -- if count >= 300 then print("---------------") end
    end

    -- save the values
    for k, v in pairs(graph:getVertices()) do
      v:setTag("LM", tools.round(I[k], self:getParameter("precision")))
    end

    -- return graph value
    for _, v in pairs(graph:getVertices()) do
      if v:getTag("tag") == "question" then
        return v:getTag("LM")
      end
    end
  end

  if not graph then
    for k, g in pairs(self.game:getGraphs()) do
      local lm
      if k == "general" then
        lm = computeGraph(g)
      else
        lm = computeGraph(g, 1)
      end
      if not self.game:getLM(k) then
        self.game:setLM(k, {})
      end
      self.game:addLM(k, {run = #self.game:getLM(k) + 1, value = lm})
    end
  else
    return computeGraph(graph)
  end
end

function rules:getParameter(param)
  return self.p[param]
end

function rules:getLastLM(graph)
  local lm = self.game:getGraph(graph):getTag("LM")
  return lm[#lm]
end

function rules:init()
  for k, _ in pairs(self.game:getPlayers()) do
    self.temp.players_votes[k] = {}
  end

  self:computeSAA()

  if self:getParameter("compute_agg") == true then
    self:aggregationValue()
  end

  if self:getParameter("compute_mean") == true then
    self:meanValue()
  end

  if self:getParameter("log_file") then
    local l_file = io.open(self:getParameter("log_file"), "w")
    io.output(l_file)
  end

  self.temp.pass    = 0
  self.temp.changed = 0
  self.temp.nb_nil     = 0

  -- select the right function for the dynamique
  if     self:getParameter("dynamique") == "round_robin" then
    self.temp.fun_p.dynamique = self.roundRobin
  elseif self:getParameter("dynamique") == "random" then
    self:initRandom()
    self.temp.fun_p.dynamique = self.random
  end
end

function rules:applyVote()
  local graph = self.game:getGraph("general")
  -- Application of the vote
  if self.temp.current_vote.arg == nil then
    self.temp.nb_nil = self.temp.nb_nil + 1
    self.temp.pass   = self.temp.pass   + 1
  else
    self.temp.nb_nil          = 0
    self.temp.changed         = self.temp.changed + self:doMove()
    self.temp.current_vote.lm = self:computeSAA(graph)
  end
end

function rules:saveVote()
  if not self.game:getLM("general") then
    self.game:setLM("general", {})
  end
  local t = {
    run      = #self.game:getLM("general") + 1,
    player   = self.temp.current_vote.player,
    arg_vote = self.temp.current_vote.arg or "none",
    vote     = self.temp.current_vote.vote or 0,
    value    = self.temp.current_vote.lm or "unknown"
  }
  self.game:addLM("general", t)
end

function rules:saveConfiguration()
  local hs = self.temp.historical_shots
  if #hs == 0 then
    local shot = {}
    for player, _ in pairs(self.game:getPlayers()) do
      shot[player] = {}
      for k, _ in pairs(self.game:getGraph():getVertices()) do
        shot[player][k] = 0
      end
    end
    hs[1] = shot
  end
  local shot = tools.deepcopy(hs[#hs])
  shot[self.temp.current_vote.player][self.temp.current_vote.arg] = self.temp.current_vote.vote
  table.insert(hs, shot)

end

function rules:plot(t)
  local p = {
    graphs = {},
    tags   = {}
  }
  for k,_ in pairs(self.game:getGraphs()) do
    p.graphs[k] = {
      name = k,
      tags = {LM = "lm"}
    }
  end
  if self:getParameter("compute_mean") then
    p.tags.mean = "moyenne"
  end
  if self:getParameter("compute_agg") then
    p.tags.aggregate_value = "aggregation"
  end
  for k,v in pairs(t) do
    p[k] = v
  end

  self.game:plot(p)
end

function rules:roundRobin()
  local player, _ = next(self.game:getPlayers(), self.temp.current_vote.player)
  if not player then
    player = next(self.game:getPlayers(), nil)
  end

  return player
end

local players_in
function rules:initRandom()
  players_in = tools.deepcopy(self.game:getPlayers():getNames())
end

function rules:random()
  if self.temp.current_vote.player and not self.temp.current_vote.arg then
    for i, v in ipairs(players_in) do
      if v == self.temp.current_vote.player then
        table.remove(players_in, i)
        break
      end
    end
  elseif #players_in ~= #self.temp.game.players then
    players_in = self:initRandom()
  end

  if #players_in == 0 then return nil end

  local player = math.random(1, #players_in)

  return players_in[player]
end

function rules:testMove(arg, vote)
  local graph         = self.game:getGraph("general")
  local vote_type     = ""
  local value_vote    = nil
  local player        = self.temp.current_vote.player

  local print_log  = {}
  local applyVote  = {}
  local removeVote = {}
  -- application of the vote
  if vote == "like" and self.temp.players_votes[player][arg] == 1 then
    applyVote[1]  = self.game.removeLike
    removeVote[1] = self.game.addLike
    vote_type     = "remove like"
    value_vote    = nil

  elseif vote == "like" and
         self.temp.players_votes[player][arg] == -1 then
    applyVote[1]  = self.game.addLike
    applyVote[2]  = self.game.removeDislike
    removeVote[1] = self.game.removeLike
    removeVote[2] = self.game.addDislike
    vote_type     = "change to like"
    value_vote    = 1

  elseif vote == "like" then
    applyVote[1]  = self.game.addLike
    removeVote[1] = self.game.removeLike
    vote_type     = "vote like"
    value_vote    = 1

  elseif vote == "dislike" and
         self.temp.players_votes[player][arg] == 1 then
    applyVote[1]  = self.game.addDislike
    applyVote[2]  = self.game.removeLike
    removeVote[1] = self.game.removeDislike
    removeVote[2] = self.game.addLike
    vote_type     = "change to dislike"
    value_vote    = -1

  elseif vote == "dislike"
     and self.temp.players_votes[player][arg] == -1 then
    applyVote[1]  = self.game.removeDislike
    removeVote[1] = self.game.addDislike
    vote_type     = "remove dislike"
    value_vote    = nil

  elseif vote == "dislike" then
    applyVote[1]  = self.game.addDislike
    removeVote[1] = self.game.removeDislike
    vote_type     = "vote dislike"
    value_vote    = -1
  end

  -- Application of vote
  for _,v in ipairs(applyVote) do
    v(self.game,nil, arg)
  end
  -- graph value's computation
  local lm = self:computeSAA(graph)

  -- write logs if it is asked
  if self:getParameter("log_file") and
     self:getParameter("log_details") == "all" then
    print_log.arg      = arg
    print_log.likes    = self.game:getlikes(arg)
    print_log.dislikes = self.game:getDislikes(arg)
    print_log.new_lm   = lm
    io.write(vote_type .. "\n")
    for k, v in pairs(print_log) do
      io.write("\t" .. k .. " = " .. tostring(v) .. "\n")
    end
    io.write("--------------------------\n")
    io.flush()
  end

  -- restoration of the previous values
  for _,v in ipairs(removeVote) do
    v(self.game, nil, arg)
  end

  self:computeSAA(graph)

  return value_vote, lm, applyVote
end

function rules:doMove()
  assert(type(self.temp.current_vote.action) == "table")
  local changed = 0
  for _,v in ipairs(self.temp.current_vote.action) do
    assert(type(v) == "function")
    v(nil, self.temp.current_vote.arg)
  end

  if self.temp.players_votes[self.temp.current_vote.player][self.temp.current_vote.arg] then
    changed = 1
  end

  --store the vote
  self.temp.players_votes[self.temp.current_vote.player][self.temp.current_vote.arg] = self.temp.current_vote.vote or 0

  return changed
end

return rules
