local rules = require 'rules'
local yaml  = require 'yaml'
local tools = require 'tools'

local mind_changed   = rules.create()
mind_changed.__index = mind_changed

function mind_changed.create(game)
  local mc = {}
  if type(game) == "game" then
    mc.game = game
  end

  setmetatable(mc, mind_changed)
  return mc
end

function mind_changed:start()
  -- select the right function for the votes
  self.temp.fun_p.typeVote = self.bestMove
  if self.p.type_vote == "better" then
    self.temp.fun_p.typeVote = self.betterMove
  end

  while self.temp.nb_nil ~= #self.game:getPlayers() do
    -- take the current player
    self.temp.current_vote.player = self.temp.fun_p.dynamique(self)

    -- write logs if it asks
    if self:getParameter("log_file")             and
       self:getParameter("log_details") == "all" then

      io.write("===================================\n")
      io.write(self.temp.current_vote.player .. " : LM = " .. self.game:getLastLM(self.temp.current_vote.player).value .. "\n")
      io.write("general : LM = " .. self.game:getLastLM().value .. "\n")
      io.write("===================================\n")
      io.flush()
    end

    self:reset{"current_vote"}

    -- search the vote to do
    local move = self.temp.fun_p.typeVote(self)
    self:computeSAA(self.game:getGraph("general"))
    if move then
      self.temp.current_vote:applyVote()
    else
      self.temp.nb_nil = self.temp.nb_nil + 1
    end
    self:saveVote()

    -- save last shot if it asks
    if self:getParameter("check_cycle") and move then
      self:saveConfiguration()

      -- write configuration into the log file
      if self:getParameter("log_file")             and
         self:getParameter("log_details") == "all" then
        io.write("configuration : \n")
        io.write(yaml.dump(self.temp.historical_shots[#self.temp.historical_shots]) .. "\n")
        io.flush()
      end

      -- search for cycle
      local cycle = false
      for i = 1, #self.temp.historical_shots - 1 do
        cycle = tools.equals(self.temp.historical_shots[i], self.temp.historical_shots[#self.temp.historical_shots])
        if cycle then
          --write logs if it asks
          if self:getParameter("log_file") then
            io.write("configurations identiques : \n")
            io.write("-------------------------------\n")
            io.write("configuration 1 : run = " .. #self.temp.historical_shots .. "\n")
            io.write(yaml.dump(self.temp.historical_shots[#self.temp.historical_shots]) .. "\n")
            io.write("-------------------------------\n")
            io.write("configuration 2 : run = " .. i .. "\n")
            io.write(yaml.dump(self.temp.historical_shots[i]) .. "\n")
            io.write("-------------------------------\n")
            io.flush()
            break
          end
        end
      end --end for

      if cycle then
        self.game.cycle = true
        return
      end
    end

    if self:getParameter("log_file") then
      if self:getParameter("log_details") == "all" then
        io.write("decision :\n vote = " .. tostring(self.temp.current_vote.arg) .. " bool = " .. tostring(self.temp.current_vote.vote) .. "new lm = " .. (self.temp.current_vote.lm or self:getLastLM("general").value) .. "\n")
        io.write("==============================\n")
      elseif self:getParameter("log_details") == "strokes" then
        io.write(self.temp.current_vote.player .. " :" ..
        " vote = " .. tostring(self.temp.current_vote.arg) ..
        " bool = " .. tostring(self.temp.current_vote.vote) ..
        " lm joueur = " .. self:getLastLM(self.temp.current_vote.player).value ..
        " lm avant = " .. self:getLastLM("general").value ..
        " lm après " .. (self.temp.current_vote.lm or self:getLastLM("general").value) .. "\n")
        io.write("============================== \n")
        io.flush()
      end
    end
  end
end

function mind_changed:bestMove()
  self.temp.current_vote.lm = self:getLastLM().value
  local player_lm = self:getLastLM(self.temp.current_vote.player).value
  local b = false
  for arg, v in pairs(self.game:getGraph("general"):getVertices()) do
    if v:getTag("tag") ~= "question" then
      for _, type_vote in ipairs({"like", "dislike"}) do
        local value_vote, temp_lm, applyVote = self:testMove(arg, type_vote)

        if math.abs(temp_lm - player_lm) < math.abs(self.temp.current_vote.lm - player_lm) then
          self.temp.current_vote.arg    = arg
          self.temp.current_vote.lm     = temp_lm
          self.temp.current_vote.vote   = value_vote
          self.temp.current_vote.action = applyVote
          b = true
        end
      end
    end
  end
  return b
end

function mind_changed:betterMove()
  local player_lm    = self:getLastLM(self.temp.current_vote.player).value
  local gen_lm       = self:getLastLM().value
  local better_votes = {}
  local b = false

  for arg, v in pairs(self.game:getGraph("general"):getVertices()) do
    if v:getTag("tag") ~= "question" then
      for _, type_vote in ipairs({"like", "dislike"}) do
        local value_vote, temp_lm, applyVote = self:testMove(arg, type_vote)

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
    self.temp.current_vote.arg    = better_votes[i].arg
    self.temp.current_vote.lm     = better_votes[i].lm
    self.temp.current_vote.vote   = better_votes[i].vote
    self.temp.current_vote.action = better_votes[i].action
    b = true
  end

  if self:getParameter("log_file") and self:getParameter("log_details") == "strokes" then
    io.write(self.temp.current_vote.player .. " : votes possibles = [")

    for i, v in ipairs(better_votes) do
      io.write("(".. v.arg .. ", " .. tostring(v.vote) .. ", " .. tostring(v.lm) ..")")
      if i < #better_votes then io.write(", ") end
    end
    io.write("] \n\n")
    io.flush()
  end

  return b
end



return mind_changed
