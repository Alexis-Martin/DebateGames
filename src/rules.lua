local tools = require "tools"
local saa   = require "saa"
local yaml  = require "yaml"
local rules = {}

-- default values for the parameters
local default_p = {
  rule         = "mind_changed",
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

-- current parameters of the rule
local p = tools.deepcopy(default_p)

-- functionnal parameters
local fun_p = {}

-- list of players' votes
local players_votes = {}

-- parameters of the actual vote
local current_vote  = {}

-- list of all strokes
local historical_shots = {}

-- set names of the functions, you will find the definition at the end
local mindChanged
local bestMove
local betterMove
local testMove
local initRoundRobin
local roundRobin
local initRandom
local random
local doMove


-- Set the parameters of the rules
-- Add new parameters and change it if the key already exists
-- @param parameters table (key, values) of parameters
function rules.setParameters(parameters)
  assert(type(parameters) == "table")
  for k, v in pairs(parameters) do
    p[k] = v
  end
end

-- Restore the parameters to the default ones
function rules.resetParameters()
  p = tools.deepcopy(default_p)
end

-- Set the game to apply the rule on it
-- @param game the game
function rules.setGame(game)
  rules.game = game
end

-- reset each local list to an empty list
function rules.resetAll()
  fun_p            = {}
  players_votes    = {}
  current_vote     = {}
  historical_shots = {}
end

-- apply the rule on the game. If there is no game, the function raise an error.
function rules.apply()
  assert(rules.game)
  rules.resetAll()
  if p.rule == "mindChanged" then
    mindChanged()
  end
end

-- apply the rule on the specific game. if game is nil, the function raise an error.
function rules.applyOn(game)
  rules.setGame(game)
  rules.apply()
end

-- apply the rule with the parameters parameters on the game, game. If one of the argument is nil, the function raise an error.
function rules.applyOnWith(game, parameters)
  rules.setGame(game)
  rules.setParameters(parameters)
  rules.apply()
end


-- Compute the value with the aggregation of all players' votes
function rules.aggregationValue()
  assert(rules.game)
  rules.game.aggregation_value(p.fun, p.epsilon, p.val_question, p.precision)
end

-- Compute the mean players value
function rules.meanValue()
  assert(rules.game)
  rules.game.mean_value(p.fun, p.epsilon, p.val_question, p.precision)
end

-- compute the social abstract argumentation algorithm on the game
function rules.computeSAA(graph)
  if not graph then
    saa.computeSAA(rules.game, p.fun, p.epsilon, p.val_question, p.precision)
  else
    return saa.computeGraphSAA(#rules.game.players, graph, p.fun, p.epsilon, p.val_question, p.precision)
  end
end
-------------------------------------------------------
--                 ANNEX FUNCTIONS                   --
-------------------------------------------------------
-- These functions are used by the previous one but we can't call them directly.

mindChanged = function ()
  if p.log_file then
    local l_file = io.open(p.log_file, "w")
    io.output(l_file)
  end

  -- table which contains the current votes of the players
  players_votes = {}
  for _, v in ipairs(rules.game.players) do
    players_votes[v] = {}
  end

  -- count the number of mind changed and pass
  local changed = 0
  local pass    = 0

  -- select the right function for the votes
  fun_p.typeVote = bestMove
  if p.type_vote == "better" then
    fun_p.typeVote = betterMove
  end

  -- select the right function for the dynamique
  if     p.dynamique == "round_robin" then
    initRoundRobin()
    fun_p.dynamique = roundRobin
  elseif p.dynamique == "random" then
    initRandom()
    fun_p.dynamique = random
  end

  --compute the initial scores and some others metrics
  rules.computeSAA()

  if p.compute_agg then
    rules.aggregationValue()
  end

  if p.compute_mean then
    rules.meanValue()
  end

  local nb_nil = 0
  while nb_nil ~= #rules.game.players do
    -- take the current player
    current_vote.player = fun_p.dynamique()

    -- write logs if it asks
    if p.log_file and p.log_details == "all" then
      io.write("===================================\n")
      io.write(current_vote.player .. " : LM = " .. rules.game.graphs[current_vote.player].LM[#rules.game.graphs[current_vote.player].LM].value .. "\n")
      io.write("general : LM = " .. rules.game.graphs.general.LM[#rules.game.graphs.general.LM].value .. "\n")
      io.write("===================================\n")
    end

    -- reinitialise current_vote
    current_vote.lm     = nil
    current_vote.arg    = nil
    current_vote.vote   = nil
    current_vote.action = nil
    -- search the vote to do
    fun_p.typeVote()

    -- Application of the vote
    if current_vote.arg == nil then
      nb_nil = nb_nil + 1
      pass   = pass + 1
    else
      nb_nil      = 0
      changed     = changed + doMove()
      local graph = rules.game.graphs.general
      local lm    = rules.computeSAA(graph)

      -- save vote
      if not graph.LM then
        graph.LM = {}
      end
      graph.LM[#graph.LM + 1] = {
        run      = #graph.LM + 1,
        player   = current_vote.player,
        arg_vote = current_vote.arg or "none",
        vote     = current_vote.vote or 0,
        value    = lm
      }

      -- save last shot if it asks
      if p.check_cycle and not rules.game.cycle then
        if #historical_shots == 0 then
          local shot = {}
          for _, player in ipairs(rules.game.players) do
            shot[player] = {}
            for k, _ in pairs(graph.vertices) do
              shot[player][k] = 0
            end
          end
          historical_shots[1] = shot
        else
          local shot = tools.deepcopy(historical_shots[#historical_shots])
          shot[current_vote.player][current_vote.arg] = current_vote.vote
          table.insert(historical_shots, shot)
        end
      end

      -- write configuration into the log file
      if p.log_file and p.log_details == "all" then
        io.write("configuration : \n")
        io.write(yaml.dump(historical_shots[#historical_shots]) .. "\n")
      end

      -- search for cycle
      local cycle = false
      for i = 1, #historical_shots - 1 do
        cycle = tools.equals(historical_shots[i], historical_shots[#historical_shots])
        if cycle then
          --write logs if it asks
          if p.log_file then
            io.write("configurations identiques : \n")
            io.write("-------------------------------\n")
            io.write("configuration 1 : run = " .. #historical_shots .. "\n")
            io.write(yaml.dump(historical_shots[#historical_shots]) .. "\n")
            io.write("-------------------------------\n")
            io.write("configuration 2 : run = " .. i .. "\n")
            io.write(yaml.dump(historical_shots[i]) .. "\n")
            io.write("-------------------------------\n")
            break
          end
        end
      end
      if cycle then
        print("there is one here!!!!")
        rules.game.cycle = true
      end
    end

    if p.log_file then
      if p.log_details == "all" then
        io.write("decision :\n vote = " .. tostring(current_vote.arg) .. " bool = " .. tostring(current_vote.vote) .. "new lm = " .. (current_vote.lm or rules.game.graphs.general.LM[#rules.game.graphs.general.LM].value) .. "\n")
        io.write("==============================\n")
      elseif p.log_details == "strokes" then
        io.write(current_vote.player .. " :" ..
        " vote = " .. tostring(current_vote.arg) ..
        " bool = " .. tostring(current_vote.vote) ..
        " lm joueur = " .. rules.game.graphs[current_vote.player].LM[#rules.game.graphs[current_vote.player].LM].value ..
        " lm avant = " .. rules.game.graphs.general.LM[#rules.game.graphs.general.LM].value ..
        " lm après " .. (current_vote.lm or rules.game.graphs.general.LM[#rules.game.graphs.general.LM].value) .. "\n")
        io.write("============================== \n")
      end
    end
  end
end

local current_player = 0
initRoundRobin = function()
  current_player = 0
end

roundRobin = function()
  current_player = current_player + 1
  if current_player > #rules.game.players then
    current_player = 1
  end
  return rules.game.players[current_player]
end

local players_in
initRandom = function()
  players_in = tools.deepcopy(rules.game.players)
end

random = function()
  if current_vote.player and not current_vote.arg then
    for i,v in ipairs(players_in) do
      if v == current_vote.player then
        table.remove(players_in, i)
        break
      end
    end
  elseif #players_in ~= #rules.game.players then
    players_in = tools.deepcopy(rules.game.players)
  end

  if #players_in == 0 then return nil end

  local player = math.random(1, #players_in)

  return players_in[player]
end

bestMove = function()
  current_vote.lm = rules.game.graphs.general.LM[#rules.game.graphs.general.LM].value
  local player_lm = rules.game.graphs[current_vote.player].LM[#rules.game.graphs[current_vote.player].LM].value

  for arg, v in pairs(rules.game.graphs.general.vertices) do
    if v.tag ~= "question" then
      for _, type_vote in ipairs({"like", "dislike"}) do
        local value_vote, temp_lm, applyVote = testMove(arg, type_vote)

        if math.abs(temp_lm - player_lm) < math.abs(current_vote.lm - player_lm) then
          current_vote.arg    = arg
          current_vote.lm     = temp_lm
          current_vote.vote   = value_vote
          current_vote.action = applyVote
        end
      end
    end
  end
end

betterMove = function ()
  local player_lm = rules.game.graphs[current_vote.player].LM[#rules.game.graphs[current_vote.player].LM].value
  local gen_lm    = rules.game.graphs.general.LM[#rules.game.graphs.general.LM].value
  local better_votes = {}

  for arg, v in pairs(rules.game.graphs.general.vertices) do
    if v.tag ~= "question" then
      for _, type_vote in ipairs({"like", "dislike"}) do
        local value_vote, temp_lm, applyVote = testMove(arg, type_vote)

        if math.abs(temp_lm - player_lm) < math.abs(gen_lm - player_lm) then
          local vote = {
            arg     = arg,
            lm      = temp_lm,
            vote    = value_vote,
            action = applyVote
          }
          table.insert(better_votes, vote)
        end
      end
    end
  end

  -- choose vote if there is one.
  if #better_votes >= 1 then
    local i = math.random(1, #better_votes)
    current_vote.arg    = better_votes[i].arg
    current_vote.lm     = better_votes[i].lm
    current_vote.vote   = better_votes[i].vote
    current_vote.action = better_votes[i].action
  end

  if p.log_file and p.log_details == "strokes" then
    io.write(current_vote.player .. " : votes possibles = [")

    for i, v in ipairs(better_votes) do
      io.write("(".. v.arg .. ", " .. tostring(v.vote) .. ", " .. tostring(v.lm) ..")")
      if i < #better_votes then io.write(", ") end
    end
    io.write("] \n\n")
  end
end

testMove = function (arg, vote)
  local graph         = rules.game.graphs.general
  local vote_type     = ""
  local value_vote    = nil
  local player        = current_vote.player

  local print_log  = {}
  local applyVote  = {}
  local removeVote = {}
  -- application of the vote
  if vote == "like" and players_votes[player][arg] == 1 then
    applyVote[1]  = rules.game.removeLike
    removeVote[1] = rules.game.addLike
    vote_type  = "remove like"
    value_vote = nil

  elseif vote == "like"
     and players_votes[player][arg] == -1 then
    applyVote[1]  = rules.game.addLike
    applyVote[2]  = rules.game.removeDislike
    removeVote[1] = rules.game.removeLike
    removeVote[2] = rules.game.addDislike
    vote_type  = "change to like"
    value_vote = 1

  elseif vote == "like" then
    applyVote[1]  = rules.game.addLike
    removeVote[1] = rules.game.removeLike
    vote_type  = "vote like"
    value_vote = 1

  elseif vote == "dislike"
     and players_votes[player][arg] == 1 then
      applyVote[1]  = rules.game.addDislike
      applyVote[2]  = rules.game.removeLike
      removeVote[1] = rules.game.removeDislike
      removeVote[2] = rules.game.addLike
      vote_type  = "change to dislike"
       value_vote = -1

  elseif vote == "dislike"
     and players_votes[player][arg] == -1 then
      applyVote[1]  = rules.game.removeDislike
      removeVote[1] = rules.game.addDislike
       vote_type  = "remove dislike"
       value_vote = nil

  elseif vote == "dislike" then
    applyVote[1]  = rules.game.addDislike
    removeVote[1] = rules.game.removeDislike
    vote_type  = "vote dislike"
    value_vote = -1
  end

  -- Application of vote
  for _,v in ipairs(applyVote) do
    v(nil, arg)
  end
  -- graph value's computation
  local lm = rules.computeSAA(graph)

  -- write logs if it is asked
  if p.log_file and p.log_details == "all" then
    print_log.arg      = arg
    print_log.likes    = graph.vertices[arg].likes
    print_log.dislikes = graph.vertices[arg].dislikes
    print_log.new_lm   = lm
    io.write(vote_type .. "\n")
    for k, v in pairs(print_log) do
      io.write("\t" .. k .. " = " .. tostring(v) .. "\n")
    end
    io.write("--------------------------\n")
  end

  -- restoration of the previous values
  for _,v in ipairs(removeVote) do
    v(nil, arg)
  end

  return value_vote, lm, applyVote
end

doMove = function ()
  assert(type(current_vote.action) == "table")
  local changed = 0
  for _,v in ipairs(current_vote.action) do
    assert(type(v) == "function")
    v(nil, current_vote.arg)
  end

  if players_votes[current_vote.player][current_vote.arg] then
    changed = 1
  end

  --store the vote
  players_votes[current_vote.player][current_vote.arg] = current_vote.vote or 0

  return changed
end





return rules
