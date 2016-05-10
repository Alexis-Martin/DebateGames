local function create_graph(class, tags)
  local graph = {
    vertices = {},
    edges    = {},
    class     = class
  }

  if type(tags) == "table" then
    for i,v in pairs(tags) do
      graph[i] = v
    end
  end
  --
  graph.addVertex = function(name, parameters)
    graph.vertices[name] = {
      attack    = {},
      attackers = {},
      addAttack = function(vertex)
        graph.vertices[name].attack[vertex] = true
      end,
      addAttacker = function(vertex)
        graph.vertices[name].attackers[vertex] = true
      end
    }

    if type(parameters) == "table" then
      for i,v in pairs(parameters) do
        graph.vertices[name][i] = v
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

  graph.print_graph = function ()
    local rec_print
    rec_print = function(t, tab)
      if tab == nil then tab = 0 end
      local tabs = ""
      if tab > 0 then
        for _ = 1, tab do
          tabs = tabs .. "\t"
        end
      end

      for k, v in pairs(t) do
        if type(v) == "table" then
          print(tabs .. k .. " = {")
          rec_print(v, tab + 1)
          print(tabs .. "}")
        elseif type(v) == "function" then
          print(tabs .. k .. " = function")
        else
          print(tabs .. k .. " = " .. tostring(v))
        end
      end
    end
    rec_print(graph)
  end

  return graph
end
return create_graph
