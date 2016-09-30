local tools = require "tools"

local function boxplot(t, output)
  assert(#t > 0)
  --[[
    t = {
      x_label     = "bla",
      y_label     = "blo",
      title       = "bliblablo",
      color{ other = "RRGGBB" },
      [1]         = {
        x     = ...,
        min   = ...,
        max   = ...,
        med   = ...,
        mean  = ...,
        other = ...,
        q1    = ...,
        q3    = ...,
      }
    }
  --]]
  if output then
    local fic = io.open(output, "w")
    io.output(fic)
  end

  io.write("\\documentclass{article}")
  io.write("\n\n")
  io.write("\\usepackage{tikz}")
  io.write("\n")
  io.write("\\usepackage[utf8x]{luainputenc}")
  io.write("\n")
  io.write("\\usepackage{xcolor}")
  io.write("\n")
  io.write("%Becareful if you use package fontenc, it might be raise an error. If it does, you have to remove it and use \\usepackage[utf8x]{luainputenc} in place of \\usepackage[utf8]{inputenc}")
  io.write("\n\n")

  if t.color then
    for k, v in pairs(t.color) do
      io.write("\\definecolor{" .. k .. "}{HTML}{" .. v .. "}")
      io.write("\n")
    end
    io.write("\n\n")
  end
  io.write("\\begin{document}")
  io.write("\n")
  io.write("\\begin{tikzpicture}[very thick]")
  io.write("\n")
  io.write("\\draw (0,0) -- (12,0);")
  io.write("\n")
  local x_dt = 12/#t
  local min
  local max
  for i,v in ipairs(t) do
    io.write("\\draw (" .. i * x_dt .. ",0.1) -- (" .. i * x_dt .. ",-0.1);")
    io.write("\n")
    io.write("\\node at (" .. i * x_dt .. ",-0.5) {" .. (v.x or "") .. "};")
    io.write("\n")

    if not min and v.min then
      min = v.min
    elseif v.min and min > v.min then
      min = v.min
    end

    if not max and v.max then
      max = v.max
    elseif v.max and max < v.max then
      max = v.max
    end
  end
  min = min or 0
  max = max or 1
  io.write("\\draw (0,0.5) -- (0,8.5);")
  io.write("\n")

  local y_scale  = 5
  local y_dt     = 8 / (y_scale-1)
  for i = 0, y_scale - 1 do
    io.write("\\draw (0.1," .. i * y_dt + 0.5 .. ") -- (-0.1," .. i * y_dt + 0.5 .. ");")
    io.write("\n")

    local value = tools.round(min + i * ((max - min) / (y_scale-1)), 2)
    io.write("\\node at (-0.5," .. i * y_dt + 0.5 .. ") {" .. (value or "") .. "};")
    io.write("\n")
  end
  io.write("\\scriptsize\n")
  for i, v in ipairs(t) do
    assert(v.med, v.q1, v.q2)
    local y_q1 = ((v.q1 - min) / (max - min)) * (y_scale - 1)
    local y_q3 = ((v.q3 - min) / (max - min)) * (y_scale - 1)
    if v.min then
      local y_min = ((v.min - min) / (max - min)) * (y_scale - 1)
      io.write("\\draw[draw=black!20] (" ..
        i * x_dt .. "," .. y_min * y_dt + 0.5 .. ") -- (" ..
        i * x_dt .. "," .. y_q1  * y_dt + 0.5 .. ");"
      )
      io.write("\n")
    end
    io.write("\\draw[draw=black!20] (" ..
      i * x_dt - 0.3 * x_dt .. "," .. y_q1 * y_dt + 0.5 ..
      ") -- (" ..
      i * x_dt - 0.3 * x_dt .. "," .. y_q3 * y_dt + 0.5 .. ");"
    )
    io.write("\n")
    io.write("\\draw[draw=black!20] (" ..
      i * x_dt + 0.3 * x_dt .. "," .. y_q1 * y_dt + 0.5 ..
      ") -- (" ..
      i * x_dt + 0.3 * x_dt .. "," .. y_q3 * y_dt + 0.5 .. ");"
    )
    io.write("\n")
    if v.max then
      local y_max = ((v.max - min) / (max - min)) * (y_scale - 1)
      io.write("\\draw[draw=black!20] (" ..
        i * x_dt .. "," .. y_max * y_dt + 0.5 .. ") -- (" ..
        i * x_dt .. "," .. y_q3  * y_dt + 0.5 .. ");"
      )
      io.write("\n")
    end

    for k, val in pairs(v) do
      if k ~= "x" then
        local y = ((val - min) / (max - min)) * (y_scale - 1)
        if t.color[k] then
          io.write("\\draw [draw=" .. k .. "](" ..
            i * x_dt - 0.3 * x_dt .. "," .. y * y_dt + 0.5 .. ") -- (" ..
            i * x_dt + 0.3 * x_dt .. "," .. y * y_dt + 0.5 .. ");"
          )
        else
          io.write("\\draw (" ..
            i * x_dt - 0.3 * x_dt .. "," .. y * y_dt + 0.5 .. ") -- (" ..
            i * x_dt + 0.3 * x_dt .. "," .. y * y_dt + 0.5 .. ");"
          )
        end
        io.write("\n")
        if t.color[k] then
          io.write("\\node [text=" .. k .. "] at (" ..
            i * x_dt .. "," .. y * y_dt + 0.36 .. ") {" .. (val or "") .. "};")
        else
          io.write("\\node at (" ..
            i * x_dt .. "," .. y * y_dt + 0.36 .. ") {" .. (val or "") .. "};")
        end
        io.write("\n")
      end
    end
  end
  io.write("\\large\n")
  if t.x_label then
    io.write("\\node at (6,-1) {" .. t.x_label .. "};\n")
  end
  if t.y_label then
    io.write("\\node[rotate=90] at (-1.5,4.1) {" .. t.y_label .. "};\n")
  end
  io.write("\\normalsize\n")

  local i = -2
  for k, _ in pairs(t.color) do
    io.write("\\draw [draw=" .. k .. "] (0," .. i .. ") -- (1, " .. i .. ");\n")
    local text = string.gsub(k, "_", " ")
    io.write("\\node [anchor=west, text=" .. k .. "] at (1.2, " .. i .. ") {" .. text .. "};\n")
    i = i - 0.5
  end
  if t.title then
    io.write("\\large\n")
    io.write("\\node at (6," .. i - 1 .. ") {\\textbf{" .. t.title .. "}};\n")
    io.write("\\normalsize\n")
  end
  io.write("\\end{tikzpicture} ")
  io.write("\n")
  if t.success then
    for k, v in pairs(t.success) do
      io.write("\nLe pourcentage de success (distance égale à 0) pour " .. k .. " est " .. v .. "\\%\n")
    end
  end
  io.write("\\end{document}")

  io.flush()
end
--
-- do
--   local t = {
--     x_label = "blabalbalbalbalb",
--     y_label = "blabalbalbalbalbal",
--     color = { aggregation = "00cc00" },
--     [1] = {
--       x           = 2,
--       min         = 0.2,
--       max         = 0.8,
--       mean        = 0.5,
--       med         = 0.45,
--       aggregation = 0.7,
--       moyenne     = 0.55,
--       q1          = 0.35,
--       q3          = 0.65
--     },
--     [2] = {
--       x           = 3,
--       min         = 0.11,
--       max         = 0.89,
--       mean        = 0.7,
--       med         = 0.45,
--       aggregation = 0.7,
--       moyenne     = 0.55,
--       q1          = 0.35,
--       q3          = 0.65
--     },
--     [3] = {
--       x           = 4,
--       min         = 0.31,
--       max         = 0.91,
--       mean        = 0.5,
--       med         = 0.45,
--       aggregation = 0.7,
--       moyenne     = 0.55,
--       q1          = 0.35,
--       q3          = 0.65
--     },
--     [4] = {
--       x           = 5,
--       min         = 0.2,
--       max         = 0.8,
--       mean        = 0.5,
--       med         = 0.45,
--       aggregation = 0.7,
--       moyenne     = 0.55,
--       q1          = 0.35,
--       q3          = 0.65
--     },
--     [5] = {
--       x           = 6,
--       min         = 0.2,
--       max         = 0.8,
--       mean        = 0.5,
--       med         = 0.45,
--       aggregation = 0.7,
--       moyenne     = 0.55,
--       q1          = 0.35,
--       q3          = 0.65
--     },
--     [6] = {
--       x           = 7,
--       min         = 0.2,
--       max         = 0.8,
--       mean        = 0.5,
--       med         = 0.45,
--       aggregation = 0.7,
--       moyenne     = 0.55,
--       q1          = 0.35,
--       q3          = 0.65
--     },
--     [7] = {
--       x           = 8,
--       min         = 0.2,
--       max         = 0.8,
--       mean        = 0.5,
--       med         = 0.45,
--       aggregation = 0.7,
--       moyenne     = 0.55,
--       q1          = 0.35,
--       q3          = 0.65
--     },
--     [8] = {
--       x           = 9,
--       min         = 0.2,
--       max         = 0.8,
--       mean        = 0.5,
--       med         = 0.45,
--       aggregation = 0.7,
--       moyenne     = 0.55,
--       q1          = 0.35,
--       q3          = 0.65
--     },
--
--   }
--   boxplot(t, "test_boxplot.tex")
-- end
return boxplot
