local yaml  = require 'yaml'
local tools = require 'tools'

local function create_graph(class, tags)
  local graph = {
    vertices = {},
    edges    = {},
    class    = class
  }

  if type(tags) == "table" then
    for i,v in pairs(tags) do
      graph[i] = v
    end
  end

  graph.addVertex = function(name, parameters, only_new)
    if not only_new then only_new = true else only_new = false end

    if (not only_new) or (not graph.vertices[name]) then
      graph.vertices[name] = {
        attack    = {},
        attackers = {},
        name      = name,
        addAttack = function(vertex)
          graph.vertices[name].attack[vertex] = true
        end,
        addAttacker = function(vertex)
          graph.vertices[name].attackers[vertex] = true
        end,
        removeAttack = function(vertex)
          graph.vertices[name].attack[vertex] = nil
        end,
        removeAttacker = function(vertex)
          graph.vertices[name].attackers[vertex] = nil
        end
      }

      if type(parameters) == "table" then
        for i,v in pairs(parameters) do
          graph.vertices[name][i] = v
        end
      end
      return true
    end
    return false
  end

  graph.setVertexParameters = function(name, parameters)
    if graph.vertices[name] then
      if type(parameters) == "table" then
        for i, v in pairs(parameters) do
          graph.vertices[name][i] = v
        end
      end
    end
  end

  graph.addEdge = function(source, target, create_news)
    graph.edges[#graph.edges + 1] = { source = source, target = target }
    if create_news == true then
      if graph.vertices[source] == nil then
        graph.addVertex(source)
      end
      if graph.vertices[target] == nil then
        graph.addVertex(target)
      end
    end

    if graph.vertices[source] ~= nil then
      graph.vertices[source].addAttack(target)
    end
    if graph.vertices[target] ~= nil then
      graph.vertices[target].addAttacker(source)
    end
  end

  graph.removeEdge = function(source, target)
    for i,v in ipairs(graph.edges) do
      if v.source == source and v.target == target then
        table.remove(graph.edges, i)
        break
      end
    end
    if graph.vertices[source] ~= nil then
      graph.vertices[source].removeAttack(target)
    end
    if graph.vertices[target] ~= nil then
      graph.vertices[target].removeAttacker(source)
    end
  end

  graph.print_graph = function (self)
    print(yaml.dump(self))
  end

  graph.export_tex = function(self, output, with_header)
    if output then
      local fic = io.open(output, "w")
      io.output(fic)
    end

    if with_header == true then
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
    end

    io.write("\\begin{figure}")
    io.write("\n")
    io.write("\\centering")
    io.write("\n")
    io.write("\\begin{tikzpicture}[>=stealth]")
    io.write("\n")
    io.write("\\graph [ layered layout, nodes = {scale=0.75, align=center} ] {")
    io.write("\n")

    local list_nodes = {}
    for _, v1 in pairs(self.edges) do
      io.write("\"" .. v1.source)
      io.write("\"")

      io.write(" -> \"" .. v1.target)
      io.write("\";")

      io.write("\n")
      list_nodes[v1.source] = true
      list_nodes[v1.target] = true
    end
    for k2,_ in pairs(self.vertices) do
      if list_nodes[k2] ~= true then
        io.write("\"" .. k2 .. "\"")
        io.write("\n")
      end
    end

    io.write("};")
    io.write("\n")
    io.write("\\end{tikzpicture}")
    io.write("\n")
    io.write("\\caption{graphe}")
    io.write("\n")
    io.write("\\end{figure}")

    if with_header then
      io.write("\n")
      io.write("\\end{document}")
    end
  end

  graph.isConnex = function()
    local exists = {__n = 0}
    for k, _ in pairs(graph.vertices) do
      exists[k] = true
      exists.__n = exists.__n + 1
    end

    local function explore(s)
      exists[s] = nil
      exists.__n = exists.__n - 1
      -- for k, _ in pairs(graph.vertices[s].attack) do
      --   if exists[k] then
      --     explore(k)
      --   end
      -- end
      for k, _ in pairs(graph.vertices[s].attackers) do
        if exists[k] then
          explore(k)
        end
      end
    end
    explore("q")

    if exists.__n == 0 then
      return true
    end
    exists.__n = nil
    return false, exists
  end

  graph.isAmbiguous = function()

    local function parity(s, deep, even, odd)
      s.__visit = deep
      deep = deep + 1

      for k, _ in pairs(s.attack) do
        if even and odd then return even, odd end
        local v = graph.vertices[k]
        if v.tag == "question" then
          if deep % 2 == 0 then
            even = true
          else
            odd = true
          end
        elseif not v.__visit then
          even, odd = parity(v, deep, even, odd)
        elseif v.__visit and
              math.abs(v.__visit - s.__visit) % 2 == 0 then
          return true, true
        end
      end
      return even, odd
    end

    for _, v in pairs(graph.vertices) do
      local even, odd = parity(v, 0, false, false)
      for _, v1 in pairs(graph.vertices) do
        v1.__visit = nil
      end
      if even and odd then return true end
    end
    return false
  end

  return graph
end
return create_graph
