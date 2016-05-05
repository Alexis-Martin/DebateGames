local function generate_graph(n_vertices,
                              n_edges,
                              min_vertices,
                              max_vertices,
                              min_edges,
                              max_edges,
                              connex,
                              directed)

  if n_vertices == (nil or 0) then
    n_vertices = rand() * max_vertices + min_vertices -- FIXME
  end
  if n_edges == (nil or 0) then
    n_edges = rand() * max_edges + min_edges -- FIXME
  end
  connex   = connex   or false
  directed = directed or false


end
