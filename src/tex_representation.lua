local import_game = require "import_xml"
local game        = import_game("/home/talkie/Documents/Stage/DebateGames/tests/test_changement_q_1_24_05_11_09_40/game_change.xml")
local fic         = io.open("game.tex", "w")
io.output(fic)

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
    io.write("\"" .. v1.source .. "\\\\ ("
      .. (v.vertices[v1.source].likes or 0) .. ","
      .. (v.vertices[v1.source].dislikes or 0) .. ")\""
      .. " -> \"" .. v1.target .. "\\\\ ("
      .. (v.vertices[v1.target].likes or 0) .. ","
      .. (v.vertices[v1.target].dislikes or 0) .. ")\""
      .. ";")
    io.write("\n")
    list_nodes[v1.source] = true
    list_nodes[v1.target] = true
  end
  for k2,_ in pairs(game.graphs.general.vertices) do
    if list_nodes[k2] ~= true then
      io.write("\"" .. k2 .. "\\\\ ("
        .. v.vertices[k2].likes or 0 .. ","
        .. v.vertices[k2].dislikes or 0 .. ")\"")
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

io.write("\\end{document}")
