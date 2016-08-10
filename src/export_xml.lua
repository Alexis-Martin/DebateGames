local function export_game(game, dest)
  local nb_graph = 0
  local xml = "<game players=\"" .. #game.players .. "\""
  for k, v in pairs(game) do
    if type(v) == "number" then
      xml = xml .. " " .. k .. "=\"" .. v .. "\""
    end
  end
  xml = xml .. ">\n\t"
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
      for _, LM in ipairs(graph.LM) do
        xml = xml .. "\n\t\t\t<LM "
        for k, v in pairs(LM) do
          if k ~= "value" then
            xml = xml .. k .. "=\"" .. v .. "\" "
          end
        end
        xml = xml .. ">" .. LM.value .."</LM>"
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

  if type(game.game_parameters) == "table" then
    xml = xml .. "<game_parameters"
    for k, v in pairs(game.game_parameters) do
      xml = xml .. " " .. k .. "=\"" .. tostring(v) .. "\""
    end
    xml = xml .. " />"
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

return export_game
