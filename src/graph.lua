---test graph
-- @module graph
local yaml   = require 'yaml'
local edge   = require 'edge'
local vertex = require 'vertex'

--- A graph is a set of vertices, a set of edges and a class (tree, agraph, graph, ...).
-- You are allow to add or delete vertices and edges.
-- Class are not really used right now, except for the XML export.

local graph   = {}
graph.__index = graph

--- Constructor
-- @param class the class of graph you create
-- @tags a table of tags you want add to the graph. Possibly nil.
-- Return the graph
function graph.create(class, tags)
  assert(class)
  local g = {
    vertices = {},
    edges    = {},
    class    = class,
  }
  setmetatable(g, graph)
  if type(tags) == "table" then
    g:setTags(tags)
  end
  return g
end

--- Add or modify a set of tags
-- @param t a table
function graph:setTags(t)
  assert(type(t) == "table")
  for i, v in pairs(t) do
    assert(i ~= "vertices" and i ~= "edges" and i ~= "class")
    self[i] = v
  end
end

--- remove a set of tags
-- @param t a table of the form key = true
function graph:removeTags(t)
  assert(type(t) == table)
  for i, _ in pairs(t) do
    assert(i ~= "vertices" and i ~= "edges" and i ~= "class")
    self[i] = nil
  end
end

--- Add or modify a tag
-- @param key the key of the tag
-- @param value the value of the tag
function graph:setTag(key, value)
  assert(key ~= nil)
  assert(key ~= "vertices" and key ~= "edges" and key ~= "class")
  self[key] = value
end

--- Delete a tag
-- @param key the key of the tag
function graph:removeTag(key)
  assert(key ~= nil)
  assert(key ~= "vertices" and key ~= "edges" and key ~= "class")
  self[key] = nil
end

--- Add a vertex if the vertex exist and tags is not nil the tags won't be modified
-- @param name The name of the vertex, this name can't be modified later
-- @param tags A set of tags for this vertex.
-- @return true if the vertex is create false otherwise
-- @return the vertex itself
function graph:addVertex(name, tags)
  if not self.vertices[name] then
    self.vertices[name] = vertex.create(name, tags)
    return true, self.vertices[name]
  end
  return false, self.vertices[name]
end

--- Remove a vertex, doesn't work right now.
-- @param name The name of the vertex
function graph:removeVertex(name)
  assert(name)
  for _, v in pairs(self.edges) do
    print(tostring(v))
  end

end

--- Get a vertex
-- @param name The name of the vertex
-- @return the vertex if it exist, nil otherwise
function graph:getVertex(name)
  return self.vertices[name]
end

--- Add or modify a set of tags of a specific vertex
-- @param name the name of the vertex
-- @param tags a table
function graph:setVertexTags(name, tags)
  assert(self.vertices[name])
  self.vertices[name]:setTags(tags)
end

--- Remove a set of tags of a specific vertex
-- @param name the name of the vertex
-- @param tags a table of the form key = true
function graph:removeVertexTags(name, tags)
  assert(self.vertices[name])
  self.vertices[name]:removeTags(tags)
end

--- Add or modify a vertex's tag
-- @param name the vertex's name
-- @param key the key of the tag
-- @param value the value of the tag
function graph:setVertexTag(name, key, value)
  assert(self.vertices[name])
  self.vertices[name]:setTag(key, value)
end

--- Delete a tag
-- @param name the vertex's name
-- @param key the key of the tag
function graph:removeVertexTag(name, key)
  assert(self.vertices[name])
  self.vertices[name]:removeTag(key)
end

--- Add an edge if the edge exist and tags is not nil the tags won't be modified
-- @param source_name The name of the source.
-- @param target_name The name of the target.
-- @param create_news If it true and source or target doesn't exist then they will be created else if source or target doesn't exist then the edge is not create.
-- @param edge_tags A set of tags for this edge.
-- @return true if the edge is create false otherwise
function graph:addEdge(source_name, target_name, create_news, edge_tags)
  local source = self:getVertex(source_name)
  local target = self:getVertex(target_name)

  if create_news == true then
    source = source or self:addVertex(source_name)
    target = target or self:addVertex(target_name)
  end

  if (not source) or (not target) then
    return false
  end
  if not self.edges[source_name .. "," .. target_name] then
    self.edges[source_name .. "," .. target_name] = edge.create(source, target, edge_tags)
    source:addAttack(target_name)
    target:addAttacker(source_name)
    return true
  end
  return false
end

--- Remove an edge.
-- @param source_name The source name of the edge
-- @param target_name The target name of the edge
function graph:removeEdge(source_name, target_name)
  if self.edges[source_name .. "," .. target_name] then
    self.edges[source_name .. "," .. target_name] = nil
    self:getVertex(source_name):removeAttack(target_name)
    self:getVertex(target_name):removeAttacker(source_name)
  end
end

--- Dump the graph into a yaml form
-- @return a string wich contains the yaml
function graph:dump()
  return yaml.dump(self)
end

--- Export the graph into a LaTeX form
-- @param output a string of the output filepath
-- @param with_header it is a boolean. If it true the basic header of Latex document will be create. This header will contains the packages that are needed.
-- @param with_details It is a boolean. If it true some details of the vertices will be shown. In the future I would like to change it by a function.
function graph:exportTex(output, with_header, with_details)
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
    io.write(v1:exportTex(with_details, with_details))
    io.write("\n")
    list_nodes[tostring(v1.source)] = true
    list_nodes[tostring(v1.target)] = true
  end
  for k2, v2 in pairs(self.vertices) do
    if list_nodes[k2] ~= true then
      io.write(v2:exportTex(with_details, with_details))
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

--- Export the graph into an XML form. Note that import need both vertices and edges.
-- @param with_tags if it true the tags will be export too. If with_tags = "all" then all tags will be print else if with_tags is a table then she should be of the form tag = true.
-- @param with_vertices indicate if the vertices will be export.
-- @param with_edges indicate if the edges will be export.
-- @return a string which contains the result.
function graph:exportXml(with_tags, with_vertices, with_edges)
  local xml = "<" .. self.class

  if with_tags == "all" then
    for k, v in pairs(self) do
      if k ~= "edges" and k ~= "vertices" and k ~= "class" then
        xml = xml .. tostring(k) .. "=\"" .. tostring(v) .. "\" "
      end
    end
  elseif type(with_tags) == "table" then
    for k, v in pairs(with_tags) do
      if self[k]         and k ~= "edges" and
         k ~= "vertices" and k ~= "class" then
        xml = xml .. tostring(k) .. "=\"" .. tostring(v) .. "\" "
      end
    end
  end
  xml = xml .. ">\n"

  if with_vertices then
    for _, v in pairs(self.vertices) do
      xml = xml .. v:exportXml(with_tags) .. "\n"
    end
  end
  if with_edges then
    for _, v in pairs(self.edges) do
      xml = xml .. v:exportXml(with_tags) .. "\n"
    end
  end
  xml = xml .. "</" .. self.class .. ">"
  return xml
end

--- Check if the graph is connex, but not if it is strongly connex.
--@return true if it the case, false otherwise.
function graph:isConnex()
  local exists = {__n = 0}
  for k, _ in pairs(self.vertices) do
    exists[k] = true
    exists.__n = exists.__n + 1
  end

  local function explore(s)
    exists[s] = nil
    exists.__n = exists.__n - 1
    for k, _ in pairs(self:getVertex(s).attacks) do
      if exists[k] then
        explore(k)
      end
    end
    for k, _ in pairs(self:getVertex(s).attackers) do
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

--- Check if the graph is bipartite
-- @return true if it is the case, false otherwise
function graph:isBipartite()
  local function parity(s, deep, even, odd)
    s.__visit = deep
    deep = deep + 1

    for k, _ in pairs(s.attack) do
      if even and odd then return even, odd end
      local v = self:getVertex(k)
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

  for _, v in pairs(self.vertices) do
    local even, odd = parity(v, 0, false, false)
    for _, v1 in pairs(self.vertices) do
      v1.__visit = nil
    end
    if even and odd then return true end
  end
  return false
end

return graph
