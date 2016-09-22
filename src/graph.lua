--- A graph is a set of vertices, a set of edges and a class (tree, agraph, graph, ...).
-- You are allow to add or delete vertices and edges.
-- Class are not really used right now, except for the XML export.
-- @module graph
local yaml   = require 'yaml'
local edge   = require 'edge'
local vertex = require 'vertex'
local tools  = require 'tools'

local graph   = {}
graph.__index = graph
graph.__type  = "graph"

--- Constructor
-- @param class the class of graph you create
-- @tags a table of tags you want add to the graph. Possibly nil.
-- @return the graph
function graph.create(class, tags)
  assert(class)
  local g = {
    vertices = {},
    edges    = {},
    class    = class,
    tags     = {}
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
    self.tags[i] = v
  end
end

--- remove a set of tags
-- @param t a table of the form key = true
function graph:removeTags(t)
  assert(type(t) == "table")
  for _, v in ipairs(t) do
    self.tags[v] = nil
  end
end

--- Add or modify a tag
-- @param key the key of the tag
-- @param value the value of the tag
function graph:setTag(key, value)
  assert(key ~= nil)
  self.tags[key] = value
end

--- Get a tag
-- @param key The tag
-- @return The value of key
function graph:getTag(key)
  return self.tags[key]
end

--- Delete a tag
-- @param key the key of the tag
function graph:removeTag(key)
  assert(key ~= nil)
  self.tags[key] = nil
end

--- Get the number of vertices.
-- @return The number of vertices
function graph:getNVertices()
  -- To optimize with a proxy and a variable n_vertices to count them
  local n_vertices = 0
  for _, _ in pairs(self:getVertices()) do
    n_vertices = n_vertices + 1
  end
  return n_vertices
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

--- Get the table vertices
-- @return set of vertices
function graph:getVertices()
  return self.vertices
end

--- Add or modify a set of tags of a specific vertex
-- @param name the name of the vertex
-- @param tags a table
function graph:setVertexTags(name, tags)
  assert(self.vertices[name])
  self.vertices[name]:setTags(tags)
end

--- Get vertex tags
-- @param name The name of the vertex
-- @return the table tags of the vertex
function graph:getVertexTags(name)
  assert(self:getVertex(name))
  return self:getVertex(name):getTags()
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

--- Get vertex tag
-- @param name The name of the vertex
-- @param key The key of the tag
-- @return the value of the tag
function graph:getVertexTag(name, key)
  assert(self:getVertex(name))
  return self:getVertex(name):getTag(key)
end

--- Delete a tag
-- @param name the vertex's name
-- @param key the key of the tag
function graph:removeVertexTag(name, key)
  assert(self.vertices[name])
  self.vertices[name]:removeTag(key)
end

--- Get the number of edges.
-- @return The number of edges
function graph:getNEdges()
  -- To optimize with a proxy and a variable n_edges to count them
  local n_edges = 0
  for _, _ in pairs(self:getEdges()) do
    n_edges = n_edges + 1
  end
  return n_edges
end

--- Get the table edges
-- @return set of edges
function graph:getEdges()
  return self.edges
end

--- Add an edge if the edge exist and tags is not nil the tags won't be modified
-- @param source_name The name of the source.
-- @param target_name The name of the target.
-- @param create_news If it true and source or target doesn't exist then they will be created else if source or target doesn't exist then the edge is not create.
-- @param edge_tags A set of tags for this edge.
-- @return true and the edge if the edge is create false and the edge (or nil) otherwise
function graph:addEdge(source_name, target_name, create_news, edge_tags)
  local source = self:getVertex(source_name)
  local target = self:getVertex(target_name)

  if create_news == true then
    if not source then
      local _
      _, source = self:addVertex(source_name)
    end
    if not target then
      local _
      _, target = self:addVertex(target_name)
    end
  end

  if (not source) or (not target) then
    return false
  end
  if not self.edges[source_name .. "," .. target_name] then
    self.edges[source_name .. "," .. target_name] = edge.create(source, target, edge_tags)
    source:addAttack(target_name)
    target:addAttacker(source_name)
    return true, self.edges[source_name .. "," .. target_name]
  end
  return false, self.edges[source_name .. "," .. target_name]
end

--- Return the edge (source_name, target_name)
-- @param source_name The source name of the edge
-- @param target_name The target name of the edge
-- @return The edge if exist, nil otherwise
function graph:getEdge(source_name, target_name)
  return self.edges[source_name .. "," .. target_name]
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
-- @param header it is a boolean. If it true the basic header of Latex document will be create. This header will contains the packages that are needed.
-- @param vertex_table it's a list with two parameters. The first one is the function apply to each vertex, and the second is the table's parameter of the function. if vertex_table is nil then the default function of each vertex is perform.
-- @param edge_table same as vertex_table for each edge.
-- @return a string which contains the Tex form.
function graph:exportTex(header, vertex_table, edge_table)
  local tex = ""

  if header == true then
    tex = tex .."\\documentclass{article}"
    tex = tex .."\n\n"
    tex = tex .."\\usepackage{graphicx}"
    tex = tex .."\n"
    tex = tex .."\\usepackage{tikz}"
    tex = tex .."\n"
    tex = tex .."\\usetikzlibrary{graphdrawing,graphs}"
    tex = tex .."\n"
    tex = tex .."\\usegdlibrary{layered}"
    tex = tex .."\n"
    tex = tex .."%Becareful if you use package fontenc, it might be raise an error. If it does, you have to remove it and use \\usepackage[utf8x]{luainputenc} in place of \\usepackage[utf8]{inputenc}"
    tex = tex .."\n\n"
    tex = tex .."\\begin{document}"
    tex = tex .."\n"
  end

  tex = tex .."\\begin{figure}"
  tex = tex .."\n"
  tex = tex .."\\centering"
  tex = tex .."\n"
  tex = tex .."\\begin{tikzpicture}[>=stealth]"
  tex = tex .."\n"
  tex = tex .."\\graph [ layered layout, nodes = {scale=0.75, align=center} ] {"
  tex = tex .."\n"

  local list_nodes = {}
  for _, v1 in pairs(self.edges) do
    if type(edge_table) == "table" then
      tex = tex ..v1:exportTex(edge_table[1], edge_table[2], vertex_table)
    else
      tex = tex ..v1:exportTex(nil, nil, vertex_table)
    end
    tex = tex .."\n"
    list_nodes[tostring(v1.source)] = true
    list_nodes[tostring(v1.target)] = true
  end
  for k2, v2 in pairs(self.vertices) do
    if list_nodes[k2] ~= true then
      tex = tex ..v2:exportTex(vertex_table[1], vertex_table[2])
      tex = tex .."\n"
    end
  end

  tex = tex .."};"
  tex = tex .."\n"
  tex = tex .."\\end{tikzpicture}"
  tex = tex .."\n"
  tex = tex .."\\caption{graphe}"
  tex = tex .."\n"
  tex = tex .."\\end{figure}"

  if header then
    tex = tex .."\n"
    tex = tex .."\\end{document}"
  end
  return tex
end

--- Export the graph into an XML form. Note that import need both vertices and edges.
-- @param with_tags If with_tags = "all" then all tags will be print else if with_tags must be a table.
-- @param with_vertices indicate if the vertices will be export.
-- @param with_edges indicate if the edges will be export.
-- @return a string which contains the result.
function graph:exportXml(with_tags, with_vertices, with_edges)
  local xml = "<graph class=\"" .. self.class .. "\""
  local xml_tags = ""

  if with_tags == "all" then
    for k, v in pairs(self.tags) do
      if type(v) == "table" then
        xml_tags = (xml_tags or "") .. tools.exportXmlTable(k, v)
      else
        xml = xml .. " " .. tostring(k) .. "=\"" .. tostring(v) .. "\""
      end
    end
  elseif type(with_tags) == "table" then
    for _, v in ipairs(with_tags) do
      if type(self.tags[v]) == "table" then
        xml_tags = (xml_tags or nil) .. tools.exportXmlTable(v, self.tags[v])
      elseif self.tags[v] then
        xml = xml .. " " .. tostring(v) .. "=\"" .. tostring(self.tags[v]) .. "\""
      end
    end
  end
  xml = xml .. ">\n" .. xml_tags .. "\n"

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
  xml = xml .. "</graph>"
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
