local function show_tex (game, output)
  local fic         = io.open(output, "w")
  io.output(fic)

  local players_votes = {}

  if game.graphs.general.LM and #game.players <= 3 then
    for _, v in ipairs(game.graphs.general.LM) do
      if v.arg_vote and v.arg_vote ~= "none" then
        if not players_votes[v.arg_vote] then players_votes[v.arg_vote] = {} end

        players_votes[v.arg_vote][v.player] = v.vote
      end
    end
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

  for k,v in pairs(game.graphs) do
    io.write("\n")
    io.write("\\begin{figure}")
    io.write("\n")
    io.write("\\centering")
    io.write("\n")
    io.write("\\begin{tikzpicture}[>=stealth]")
    io.write("\n")
    io.write("\\graph [ layered layout, nodes = {scale=0.75, align=center} ] {")
    io.write("\n")

    local list_nodes = {}
    for _, v1 in pairs(game.graphs.general.edges) do
      io.write("\"" .. v1.source)
      if game.graphs.general.LM and players_votes[v1.source] and k == "general" and #game.players <= 3 then
        for _,p in ipairs(game.players) do
          local like
          local dislike
          if players_votes[v1.source][p] == 1 then like = 1 end
          if players_votes[v1.source][p] == -1 then dislike = 1 end
          io.write("\\\\ ("
            .. (like or 0) .. ","
            .. (dislike or 0) .. ")")
        end
      else
      io.write("\\\\ ("
        .. (v.vertices[v1.source].likes or 0) .. ","
        .. (v.vertices[v1.source].dislikes or 0) .. ")")
      end
      if  v.vertices[v1.source].tag == "question"
      and v.vertices[v1.source].LM then
        io.write("\\\\lm = " .. v.vertices[v1.source].LM)
      end
      io.write("\"")

      io.write(" -> \"" .. v1.target)
      if game.graphs.general.LM and players_votes[v1.target] and k == "general" and #game.players <= 3 then
        for _,p in ipairs(game.players) do
          local like
          local dislike
          if players_votes[v1.target][p] == 1 then like = 1 end
          if players_votes[v1.target][p] == -1 then dislike = 1 end
          io.write("\\\\ ("
            .. (like or 0) .. ","
            .. (dislike or 0) .. ")")
        end
      else
        io.write("\\\\ ("
        .. (v.vertices[v1.target].likes or 0) .. ","
        .. (v.vertices[v1.target].dislikes or 0) .. ")")
      end

      if  v.vertices[v1.target].tag == "question"
      and v.vertices[v1.target].LM then
        io.write("\\\\lm = " .. v.vertices[v1.target].LM)
      end
      io.write("\";")

      io.write("\n")
      list_nodes[v1.source] = true
      list_nodes[v1.target] = true
    end
    for k2,_ in pairs(game.graphs.general.vertices) do
      if list_nodes[k2] ~= true then
        io.write("\"" .. k2 .. "\\\\ ("
          .. (v.vertices[k2].likes or 0) .. ","
          .. (v.vertices[k2].dislikes or 0) .. ")\"")
        io.write("\n")
      end
    end

    io.write("};")
    io.write("\n")
    io.write("\\end{tikzpicture}")
    io.write("\n")
    io.write("\\caption{".. k .. "}")
    io.write("\n")
    io.write("\\end{figure}")
    io.write("\n")
  end

  if game.graphs.general.LM  then
    io.write("\\begin{tabular}{|c|")
    for _, _ in ipairs(game.players) do
      io.write("c|")
    end
    io.write("c|}")
    io.write("\n")
    io.write("\\hline")
    io.write("\n")
    io.write("& ")
    for _, p in ipairs(game.players) do
      io.write(p .. " & ")
    end
    io.write("general \\\\")
    io.write("\n")
    io.write("\\hline")
    io.write("\n")
    for _, v in pairs(game.graphs.general.LM) do
      io.write("tour " .. v.run .. " & ")
      for _, p in ipairs(game.players) do
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
      io.write(v.value .. " \\\\")
      io.write("\n")
      io.write("\\hline")
      io.write("\n")
    end
    io.write("\\end{tabular}")
  end
  io.write("\n")

  io.write("\\end{document}")
end

return show_tex
