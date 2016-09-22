local xml          = require "xml"
local graph = require "graph"
local create_game  = require "game"
local rules        = require "rules"
local saa          = require "saa"

local function import_game(fic, play)

  local data = xml.loadpath(fic)

  -- Construct table of players
  local players = {}
  local class
  for _,v in pairs(data) do
    if type(v) == "table" and
       v.xml   == "graph" and
       v.view  ~= "general"
    then
      table.insert(players, v.view)
    elseif type(v) == "table" and
           v.xml   == "graph" and
           v.view  == "general"
    then
      class = v.class or "graph"
    end
  end

  local gen_g = graph.create(class, { view = "general" })

  for _,g in pairs(data) do
    if type(g) == "table" and
       g.xml   == "graph" and
       g.view  == "general"
    then
      for _, v in pairs(g) do
        if type(v) == 'table' and
           v.xml   == 'vertex'
        then
          local tags = {}
          for k, t in pairs(v) do
            if k ~= "xml" and k ~= "name" then
              tags[k] = t
            end
          end
          local _, vertex = gen_g:addVertex(v.name)
          vertex:setTags(tags)
        elseif type(v) == 'table' and
               v.xml   == 'edge'
        then
          local tags = {}
          for k, t in pairs(v) do
            if k ~= "xml"    and
               k ~= "source" and
               k ~= "target"
            then
              tags[k] = t
            end
          end
          local _, edge = gen_g:addEdge(v.source, v.target, true)
          edge:setTags(tags)
        end
      end
    end
  end

  --construct game
  local game = create_game.create(players, gen_g)
  for _, g in pairs(data) do
    if type(g) == "table" and g.xml == "graph" then
      for _, v in pairs(g) do
        if type(v) == 'table' and v.xml == 'vertex' then
          game:setDislikes(g.view, v.name, tonumber(v.dislikes or 0))
          game:setLikes(g.view, v.name, tonumber(v.likes or 0))
        end
      end
    end
  end

  if play then
    for _,g in pairs(data) do
      if type(g) == "table" and g.xml == "game_parameters" then
        local parameters = {
          fun          = g.fun,
          precision    = tonumber(g.precision),
          val_question = tonumber(g.val_question),
          epsilon      = tonumber(g.epsilon),
          stop_at      = tonumber(g.stop_at),
          dynamique    = g.dynamique,
          rule         = g.rule,
          game         = game,
        }
        rules.setParameters(parameters)
        for _,g1 in pairs(data) do
          if type(g1) == "table" and g1.view == "general" then
            for _, v in pairs(g1) do
              if type(v) == 'table' and v.xml == 'LM' then
                game.aggregation_value(parameters.fun,
                                       parameters.epsilon,
                                       parameters.val_question,
                                       parameters.precision
                                      )
                saa.computeSAA        (game,
                                       parameters.fun,
                                       parameters.epsilon,
                                       parameters.val_question,
                                       parameters.precision
                                      )
                for i = 2, #v do
                  local vote = {
                    player = v[i].player,
                    vote   = tonumber(v[i].vote),
                    arg    = v[i].arg_vote
                  }
                  rules.playOnce(game, vote)
                end
              end
            end
            break
          end
        end
        break
      end
    end
  end

  return game
end

return import_game
