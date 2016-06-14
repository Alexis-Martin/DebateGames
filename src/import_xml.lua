local xml          = require "xml"
local create_graph = require "graph"
local create_game  = require "game"
local rules        = require "rules"
local saa          = require "saa"

local function import_game(fic, play)

  local data = xml.loadpath(fic)

  -- Construct table of players
  local players = {}
  for _,v in pairs(data) do
    if type(v) == "table" and v.view ~= "general" then
      players[#players + 1] = v.view
    end
  end

  -- Construct general graph
  local class
  for _,g in pairs(data) do
    if type(g) == "table" and g.view == "general" then
      class = g.xml
    end
  end
  local graph = create_graph(class, { view = "general" })

  for _,g in pairs(data) do
    if type(g) == "table" and g.view == "general" then
      for _, v in pairs(g) do
        if type(v) == 'table' and v.xml == 'vertex' then
          if not graph.addVertex(v.name, { content = v[1], tag = v.tag }) then
            graph.setVertexParameters(v.name, { content = v[1], tag = v.tag })
          end
        elseif type(v) == 'table' and v.xml == 'edge' then
          graph.addEdge(v.source, v.target, true)
        end
      end
    end
  end

  --construct game
  local game = create_game(players, graph)
  for _,g in pairs(data) do
    if type(g) == "table" and g.view ~= "general" then
      for _, v in pairs(g) do
        if type(v) == 'table' and v.xml == 'vertex' then
          game.setDislikes(g.view, v.name, tonumber(v.dislikes))
          game.setLikes(g.view, v.name, tonumber(v.likes))
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
