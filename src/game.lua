local gp      = require 'gnuplot'
local yaml    = require 'yaml'
local tools   = require 'tools'
local players = require 'players'

local game   = {}
game.__index = game
game.__type  = "game"

function game.create(ps, graph, tags)
  assert(rawtype(ps) == "table" and type(graph) == "graph")

  graph:setTag("view", "general")
  local g = {
    graphs = {
      general = graph
    },
    tags   = {}
  }
  if type(ps) == "players" then
    g.players = ps
  else
    g.players = players.create()
    for _, v in ipairs(ps) do
      g.players:newPlayer(v)
    end
  end

  for player, _ in pairs(g.players) do

    g.graphs[player] = tools.deepcopy(graph)
    g.graphs[player]:setTag("view", player)
  end


  if type(tags) == "table" then
    g:setTags(tags)
  end

  setmetatable(g, game)
  return g
end

--- Add or modify a set of tags
-- @param t a table
function game:setTags(t)
  assert(type(t) == "table")
  for i, v in pairs(t) do
    self.tags[i] = v
  end
end

--- remove a set of tags
-- @param t a table of the form key = true
function game:removeTags(t)
  assert(type(t) == "table")
  for _, v in ipairs(t) do
    self.tags[v] = nil
  end
end

--- Add or modify a tag
-- @param key the key of the tag
-- @param value the value of the tag
function game:setTag(key, value)
  assert(key ~= nil)
  self.tags[key] = value
end

--- get a tag
-- @param key the key of the tag
-- @return the value of the tag
function game:getTag(key)
  assert(key ~= nil)
  return self.tags[key]
end


--- Delete a tag
-- @param key the key of the tag
function game:removeTag(key)
  assert(key ~= nil)
  self.tags[key] = nil
end

function game:dump()
  return yaml.dump(self)
end

function game:restoreGame()
  for k, _ in pairs(self.graphs.general) do
    self.graphs.general:removeVertexTags(k, {"likes", "dislikes", "LM"})
  end

  self.graphs.general:removeTag("LM")

  for _,p in pairs(players) do
    self.graphs[p]:removeTag("LM")
    for k, _ in pairs(self.graphs[p]:getVertices()) do
      self.graphs[p]:removeVertexTag(k, "LM")
    end
  end
  self:removeTags {"changed", "rounds", "pass", "mean", "aggregate_value",
                   "strongest_shot", "weakest_shot"}
end

function game:setDislikes(player, arg, nb)
  if not player then
    player = "general"
  end
  assert(self.graphs[player])
  self.graphs[player]:setVertexTag(arg, "dislikes", nb)
end

function game:getLikes(player, arg)
  if not player then
    player = "general"
  end
  assert(self.graphs[player])
  return self.graphs[player]:getVertexTag(arg, "likes")
end

function game:getDislikes(player, arg)
  if not player then
    player = "general"
  end
  assert(self.graphs[player])
  return self.graphs[player]:getVertexTag(arg, "dislikes")
end

function game:setLikes(player, arg, nb)
  if not player then
    player = "general"
  end
  assert(self.graphs[player])
  self.graphs[player]:setVertexTag(arg, "likes", nb)
end

function game:addDislike(player, arg)
  if not player then
    player = "general"
  end
  assert(self.graphs[player])
  if not self.graphs[player]:getVertexTag(arg, "dislikes") then
    self:setDislikes(player, arg, 0)
  end
  local d = self.graphs[player]:getVertexTag(arg, "dislikes") + 1
  self.graphs[player]:setVertexTag(arg, "dislikes", d)
  return d
end

function  game:addLike(player, arg)
  if not player then
    player = "general"
  end
  assert(self.graphs[player])
  if not self.graphs[player]:getVertexTag(arg, "likes") then
    self:setLikes(player, arg, 0)
  end
  local d = self.graphs[player]:getVertexTag(arg, "likes") + 1
  self.graphs[player]:setVertexTag(arg, "likes", d)
  return d
end

function game:removeDislike(player, arg)
  if not player then
    player = "general"
  end
  assert(self.graphs[player])
  local d = self.graphs[player]:getVertexTag(arg, "dislikes") - 1
  if d < 0 then d = 0 end
  self.graphs[player]:setVertexTag(arg, "dislikes", d)
  return d
end

function game:removeLike(player, arg)
  if not player then
    player = "general"
  end
  assert(self.graphs[player])
  local d = self.graphs[player]:getVertexTag(arg, "likes") - 1
  if d < 0 then d = 0 end
  self.graphs[player]:setVertexTag(arg, "likes", d)
  return d
end

function game:getGraphs()
  return self.graphs
end

function game:getGraph(graph)
  if graph then
    return self.graphs[graph]
  end
  return self.graphs.general
end

function game:getPlayers()
  return self.players
end

function game:getLM(graph)
  if not graph then return self.graphs.general:getTag("LM") end
  return self.graphs[graph]:getTag("LM")
end

function game:getLastLM(player)
  if not player then
    player = "general"
  end
  local lm = self:getGraph(player):getTag("LM")
  return lm[#lm]
end

function game:setLM(graph, t)
  self.graphs[graph]:setTag("LM", t)
end

function game:addLM(graph, t)
  if type(self.graphs[graph]:getTag("LM")) == "table" then
    table.insert(self.graphs[graph]:getTag("LM"), t)
  end
end

function game:plot(t)
  assert(type(t) == "table" and t.output)

  -- t = {
  --   graphs = {
  --     p1 = {
  --       name = "bla"
  --       tags = {LM = "lm"}
  --     }
  --   }
  --  tags = {
  --    mean = "moyenne"
  --  }
  -- }

  local values         = {}
  local using          = {}
  local players_title  = {}

  values[1] = {}
  table.insert(using, 1)

  local i   = 2
  local max = 1
  for k, v in pairs(t.graphs) do
    for k1, v1 in pairs(v.tags) do
      table.insert(values, {})
      table.insert(using, #using + 1)
      table.insert(players_title, v1 .. " " .. v.name)
      local tag = self.graphs[k]:getTag(k1)
      if type(tag) == "number" then
        table.insert(values[i], tag)
      elseif type(tag) == "table" then
        for j = 1, #tag do
          table.insert(values[i], tag[j].value)
        end
        if #tag > max then max = #tag end
      end
      i = i + 1
    end
  end

  if type(t.tags) == "table" then
    for k, v in pairs(t.tags) do
      table.insert(values, {})
      table.insert(using, #using + 1)
      table.insert(players_title, v)
      if type(self[k]) == "number" then
        table.insert(values[i], self[k])
      elseif type(self[k]) == "table" then
        for j = 1, #self[k] do
          table.insert(values[i], self[k][j])
        end
        if #self[k] > max then max = #self[k] end
      end
      i = i + 1
    end
  end

  for j = 0, max - 1 do
    table.insert(values[1], j)
  end

  for j, v in ipairs(values) do
    if j ~= 1 and #v ~= max then
      for _ = #v + 1, max do
        table.insert(v, v[#v])
      end
    end
  end

  t.option  = t.option or {}
  local g = gp{
      -- all optional, with sane defaults
      width  = t.option.width  or 640,
      height = t.option.height or 480,
      xlabel = t.option.xlabel or "X axis",
      ylabel = t.option.ylabel or "Y axis",
      key    = t.option.key    or "top left",
      title  = t.option.title  or nil,
      consts = {
          gamma = 2.5
      },

      data = {
          gp.array {values, title = players_title, using = using, with  = 'linespoints'},
      }
  }

  g:plot(t.output, t.open)
end

function game:exportTex(output)
  if output then
    local fic = io.open(output, "w")
    io.output(fic)
  end

  io.write("\\documentclass{article}")
  io.write("\n\n")
  io.write("\\usepackage{graphicx}")
  io.write("\n")
  io.write("\\usepackage{tikz}")
  io.write("\n")
  io.write("\\usetikzlibrary{graphdrawing,graphs}")
  io.write("\n")
  io.write("\\usegdlibrary{layered}")
  io.write("\n")
  io.write("%Becareful if you use package fontenc, it might be raise an error. If it does, you have to remove it and use \\usepackage[utf8x]{luainputenc} in place of \\usepackage[utf8]{inputenc}")
  io.write("\n\n")
  io.write("\\begin{document}")
  io.write("\n")

  local players_votes = {}

  if self.graphs.general:getTag("LM") and #self.players <= 3 then
    for _, v in ipairs(self.graphs.general:getTag("LM")) do
      if v.arg_vote and v.arg_vote ~= "none" then
        if not players_votes[v.arg_vote] then players_votes[v.arg_vote] = {} end
        players_votes[v.arg_vote][v.player] = v.vote
      end
    end
  end
  local function v_func(v)
    local tex = "$" .. tostring(v) .. "$"
    tex = tex .. "\\\\ $(" .. (v:getTag("likes")    or 0)
              .. ","      .. (v:getTag("dislikes") or 0) .. ")$"

    if v:getTag("tag") and v:getTag("LM") then
      tex = tex .. "\\\\ $LM = " .. (v:getTag("LM") or "unknown") .. "$"
    end
    return tex
  end

  for _, v in pairs(self.graphs) do
      io.write(v:exportTex(false, {v_func}))
  end

  if self.graphs.general:getTag("LM")  then
    io.write("\\begin{tabular}{|c|")
    for _, _ in pairs(self.players) do
      io.write("c|")
    end
    io.write("c|}")
    io.write("\n")
    io.write("\\hline")
    io.write("\n")
    io.write("& ")
    for p, _ in pairs(self.players) do
      io.write(p .. " & ")
    end
    io.write("général \\\\")
    io.write("\n")
    io.write("\\hline")
    io.write("\n")
    for _, v in pairs(self.graphs.general:getTag("LM")) do
      io.write("tour " .. v.run .. " & ")
      for _, p in pairs(self.players) do
        if v.player == p then
          if v.arg_vote == "none" then
            io.write("pass & ")
          elseif v.vote == 1 then
            io.write(v.arg_vote .. " like " .. "& ")
          elseif v.vote == -1 then
            io.write(v.arg_vote .. " dislike " .. "& ")
          else
            io.write(v.arg_vote .. " annule " .. "& ")
          end
        else
          io.write("\\_" .. " & ")
        end
      end
      io.write((v.value or "err") .. " \\\\")
      io.write("\n")
      io.write("\\hline")
      io.write("\n")
    end
    io.write("\\end{tabular}")
  end
  io.write("\n")
  io.write("\\end{document}")
  io.flush()
end

function game:exportXml(output, with_tags)
  if output then
    local fic = io.open(output, 'w')
    io.output(fic)
  end

  local xml = "<game players=\"" .. #self.players .. "\""
  local xml_tags = ""

  if with_tags == "all" then
    for k, v in pairs(self.tags) do
      if type(v) == "table" then
        xml_tags = (xml_tags or nil) .. tools.exportXmlTable(k, v)
      else
        xml = xml .. " " .. tostring(k) .. "=\"" .. tostring(v) .. "\""
      end
    end
  elseif type(with_tags) == "table" then
    for _, v in ipairs(with_tags) do
      if type(self.tags[v]) == "table" then
        xml_tags = (xml_tags or nil) .. tools.exportXmlTable(v, self.tags[v])
      elseif self.tags[v] then
        xml = xml .. " " .. tostring(v) .. "=\"" .. tostring(self.tags[v]) .. "\""
      end
    end
  end
  xml = xml .. ">\n" .. xml_tags

  for k,v in pairs(self.graphs) do
    if k == "general" then
      xml = xml .. "\n" .. v:exportXml(with_tags, true, true)
    else
      xml = xml .. "\n" .. v:exportXml(with_tags, true)
    end
  end
  xml = xml .. "\n" .. "</game>"
  if output then
    io.write(xml)
  end
  return xml
end

return game
