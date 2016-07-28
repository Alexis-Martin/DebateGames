local create_graph = require "graph"
local tools        = require "tools"
-- local function generate_graph(n_vertices,
--                               n_edges,
--                               min_vertices,
--                               max_vertices,
--                               min_edges,
--                               max_edges,
--                               connex,
--                               directed)
--
--   if n_vertices == (nil or 0) then
--     n_vertices = rand() * max_vertices + min_vertices -- FIXME
--   end
--   if n_edges == (nil or 0) then
--     n_edges = rand() * max_edges + min_edges -- FIXME
--   end
--   connex   = connex   or false
--   directed = directed or false
--
-- end

-- generate tree with n_vertices nodes.
-- if n_vertices = nil or 0 then the number of vertices is generate uniformaly between min_vertices and max_vertices.
-- The default value for min_vertices is 1 and the default value for max_vertices is 100.
local function generate_tree(n_vertices, min_vertices, max_vertices)
  tools.randomseed()
  if n_vertices == (nil or 0) then
    if min_vertices == (nil or 0) then min_vertices = 1 end
    if max_vertices == (nil or 0) then max_vertices = 100 end

    n_vertices = math.random(min_vertices, max_vertices)
  end

  local tree = create_graph("tree")
  tree.addVertex("q", {tag = "question"})
  for i=1, n_vertices do
    tree.addVertex("a" .. i)
    local attack = math.random(0, i - 1)
    if attack == 0 then
      tree.addEdge("a" .. i, "q", true)
    else
      tree.addEdge("a" .. i, "a" .. attack, true)
    end
  end
  return tree
end

return generate_tree
