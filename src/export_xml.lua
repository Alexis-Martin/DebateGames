local function export_game(game, dest)
  local nb_graph = 0
  local xml = "<game players=\"" .. #game.players .. "\">\n\t"
  for _, graph in pairs(game.graphs) do

    xml = xml .. "<" .. graph.class .. " view=\"" .. graph.view .. "\">"
    for name, vertex in pairs(graph.vertices) do
      if graph.view == "general" or
        (graph.view ~= "general" and (vertex.likes or vertex.dislikes)) then
        xml = xml .. "\n\t\t<vertex name=\"" .. name .. "\""
        for tag, value in pairs(vertex) do
          if tag         ~= "content" and
             tag         ~= "name"    and
             type(value) ~= "table"   and
             type(value) ~= "function"
          then
            xml = xml .. " " .. tag .. "=\"" .. value .. "\""
          end
        end
        if vertex.content then
          xml = xml .. ">" .. vertex.content .. "</vertex>"
        else
          xml = xml .. " />"
        end
      end
    end

    if graph.view == "general" then
      for _, edge in ipairs(graph.edges) do
        xml = xml .. "\n\t\t<edge source=\"" .. edge.source .. "\" target=\"" .. edge.target .. "\" />"
      end
    end

    if type(graph.LM) == "table" then
      xml = xml .. "\n\t\t<LM>"
      for i, LM in ipairs(graph.LM) do
        xml = xml .. "\n\t\t\t<LM run=\"" .. i .. "\">" .. LM .. "</LM>"
      end
      xml = xml .. "\n\t\t</LM>"
    end
    xml = xml .. "\n\t</" .. graph.class .. ">"
    if #game.players == nb_graph then
      xml = xml .. "\n"
    else
      xml = xml .. "\n\n\t"
    end
    nb_graph = nb_graph + 1
  end
  xml = xml .. "</game>"

  if type(dest) == 'string' then
    local fic  = io.open(dest, "w")
    if fic then
      io.output(fic)
      io.write(xml)
      io.flush()
    end
  end
  return xml
end

-- do
--   local game_generator  = require "game_generator"
--   local graph_generator = require "graph_generator"
--   local graph           = graph_generator(10)
--   local game            = game_generator(2, graph)
--   print(export_game(game))
--
-- end
return export_game