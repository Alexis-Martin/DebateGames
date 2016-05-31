local yaml = require 'yaml'

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

  graph.print_graph = function (self)
    print(yaml.dump(self))
  end

  return graph
end
return create_graph
