local graph = require "graph"
local tools        = require "tools"

local generate_graph = {}

local initializeP
local try = 0

function generate_graph.generateNAGraph(p)
  p = initializeP(p)

  local graph = create_graph("graph")
  graph.addVertex("q", {tag = "question"})

  for i=1, p.n_vertices do
    graph.addVertex("a" .. i)
  end
  local old_edges = p.n_edges

  local same = 0
  local old  = p.n_edges
  while p.n_edges > 0 do
    if old == p.n_edges then
      same = same + 1
    else
      same = 0
    end
    old = p.n_edges
    if same >= 10 then break end

    local b = false

    local input  = math.random(1, p.n_vertices)
    local output = math.random(0, p.n_vertices)

    if input ~= output then
      if output == 0 then
        if not graph.vertices["a" .. input].attack["q"] then
          graph.addEdge("a" .. input, "q")
          if graph.isAmbiguous() then
            graph.removeEdge("a" .. input, "q")
          else
            b = true
          end
        end
      else
        if not graph.vertices["a" .. input].attack["a" .. output] then
          graph.addEdge("a" .. input, "a" .. output)
          if graph.isAmbiguous() then
            graph.removeEdge("a" .. input, "a" .. output)
          else
            b = true
          end
        end
      end
    end

    if b then p.n_edges = p.n_edges - 1 end
  end

  local is_connex, non_connex = graph.isConnex()
  local count = 0

  while not is_connex do
    if count >= 15 then
      if p.max_edges or p.min_edges then
        p.n_edges = nil
      else
        p.n_edges = old_edges
      end
      try = try + 1
      return generate_graph.generateNAGraph(p)
    end
    count = count + 1

    for k, _ in pairs(non_connex) do
      local output = math.random(0, p.n_vertices)

      if k ~= output then
        if output == 0 then
          if not graph.vertices[k].attack["q"] then
            graph.addEdge(k, "q")
            if graph.isAmbiguous() then
              graph.removeEdge(k, "q")
            end
          end
        else
          if not graph.vertices[k].attack["a" .. output] then
            graph.addEdge(k, "a" .. output)
            if graph.isAmbiguous() then
              graph.removeEdge(k, "a" .. output)
            end
          end
        end
      end
    end
    is_connex, non_connex = graph.isConnex()
  end
  return graph
end

function generate_graph.generateGraph(p)
  p = initializeP(p)

  local graph = create_graph("graph")
  graph.addVertex("q", {tag = "question"})

  for i=1, p.n_vertices do
    graph.addVertex("a" .. i)
  end

  while p.n_edges > 0 do
    local b = false

    local input  = math.random(1, p.n_vertices)
    local output = math.random(0, p.n_vertices)

    if input ~= output then
      if output == 0 then
        if not graph.vertices["a" .. input].attack["q"] then
          graph.addEdge("a" .. input, "q")
          b = true
        end
      else
        if not graph.vertices["a" .. input].attack["a" .. output] then
          graph.addEdge("a" .. input, "a" .. output)
          b = true
        end
      end
    end

    if b then p.n_edges = p.n_edges - 1 end
  end

  local is_connex, non_connex = graph.isConnex()
  while not is_connex do
    for k, _ in pairs(non_connex) do
      local output = math.random(0, p.n_vertices)

      if k ~= output then
        if output == 0 then
          if not graph.vertices[k].attack["q"] then
            graph.addEdge(k, "q")
          end
        else
          if not graph.vertices[k].attack["a" .. output] then
            graph.addEdge(k, "a" .. output)
          end
        end
      end
    end
    is_connex, non_connex = graph.isConnex()
  end
  return graph
end

-- generate tree with n_vertices nodes.
-- if n_vertices = nil or 0 then the number of vertices is generate uniformaly between min_vertices and max_vertices.
-- The default value for min_vertices is 1 and the default value for max_vertices is 100.
function generate_graph.generateTree(n_vertices, min_vertices, max_vertices)
  tools.randomseed()
  if n_vertices == (nil or 0) then
    if min_vertices == (nil or 0) then min_vertices = 1 end
    if max_vertices == (nil or 0) then max_vertices = 100 end

    n_vertices = math.random(min_vertices, max_vertices)
  end

  local tree = graph.create("tree")
  tree:addVertex("q", {tag = "question"})
  for i=1, n_vertices do
    tree:addVertex("a" .. i)
    local attack = math.random(0, i - 1)
    if attack == 0 then
      tree:addEdge("a" .. i, "q", true)
    else
      tree:addEdge("a" .. i, "a" .. attack, true)
    end
  end
  return tree
end

function initializeP(p)
  tools.randomseed()
  if p.n_vertices == (0 or nil) then
    p.max_vertices = p.max_vertices or 20
    p.min_vertices = p.min_vertices or 2
    assert(p.max_vertices >= p.min_vertices)
    assert(p.min_vertices >= 0)
    p.n_vertices = math.random(p.min_vertices, p.max_vertices)
  end

  if (not p.n_edges) or p.n_edges == 0  then
    p.max_edges = p.max_edges or (p.n_vertices * (p.n_vertices - 1) + p.n_vertices)

    if p.max_edges > (p.n_vertices * (p.n_vertices - 1) + p.n_vertices) then
      p.max_edges = (p.n_vertices * (p.n_vertices - 1) + p.n_vertices)
    end

    p.min_edges = p.min_edges or (p.n_vertices - 1)
    assert(p.max_edges >= p.min_edges)
    assert(p.min_edges >= 0)
    p.n_edges = math.random(p.min_edges, p.max_edges)
  end
  return p
end

do
  local tree = generate_graph.generateTree(10)
  print(tree:exportXml({"tag"}, true, true))
  io.output(io.open("test_graph.tex", "w"))
  io.write(tree:exportTex(true, true))
end

return generate_graph
