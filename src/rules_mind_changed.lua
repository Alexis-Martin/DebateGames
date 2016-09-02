local rules = require 'rules'
local yaml  = require 'yaml'
local tools = require 'tools'

local mind_changed   = rules.create()
mind_changed.__index = mind_changed

function mind_changed.create(game)
  local mc = {}
  if type(game) == "game" then
    mc:setGame(game)
  end

  setmetatable(mc, mind_changed)
  return mc
end

function mind_changed:start()
  self:init()

  -- select the right function for the votes
  self.temp.fun_p.typeVote = self.bestMove
  if self.temp.p.type_vote == "better" then
    self.temp.fun_p.typeVote = self.betterMove
  end

  while self.temp.nb_nil ~= #self.game:getPlayers() do
    -- take the current player
    self.temp.current_vote.player = self.temp.fun_p.dynamique()

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
    self.temp.fun_p.typeVote()
    self:computeSAA(self.game:getGraph("general"))
    self:applyVote()
    self:saveVote()
    -- save last shot if it asks
    if self:getParameter("check_cycle") then
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

return mind_changed
