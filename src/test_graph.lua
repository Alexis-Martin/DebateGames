local create_graph = require "graph"

local graph = create_graph("tree", {view = "general"})

for i,v in pairs(graph) do
  print(i, v)
end

graph.addVertex("a")
print()
for i,v in pairs(graph.vertices.a) do
  print(i, v)
end

graph.vertices.a.addAttacker("b")
print()
for i,v in pairs(graph.vertices.a.attackers) do
  print(i, v)
end

print(math.random(0, 0))


local generate_graph = require "graph_generator"
local tree = generate_graph.generateTree(15)

tree.print_graph()
