local saa = require "saa"
local rules           = require "rules"
local normal_game = {}

function normal_game.NormalForm(game, parameters)
  assert(#game.players == 2)
  game.restoreGame()
  local lm_start = saa.computeGraphSAA(2, game.graphs.general, "tau_1", nil, 1, 8)
  local nb = 0
  for _, j1_a1 in ipairs({-1, 0, 1}) do
    for _, j1_a2 in ipairs({-1, 0, 1}) do
      for _, j1_a3 in ipairs({-1, 0, 1}) do
        for _, j2_a1 in ipairs({-1, 0, 1}) do
          for _, j2_a2 in ipairs({-1, 0, 1}) do
            for _, j2_a3 in ipairs({-1, 0, 1}) do
              game.restoreGame()
              if j1_a1 == -1 then
                --game.addDislike(nil, "a1")
                game.addDislike("joueur 1", "a1")
              elseif j1_a1 == 1 then
                --game.addLike(nil, "a1")
                game.addLike("joueur 1", "a1")
              end


              if j1_a2 == -1 then
                --game.addDislike(nil, "a2")
                game.addDislike("joueur 1", "a2")
              elseif j1_a2 == 1 then
                --game.addLike(nil, "a2")
                game.addLike("joueur 1", "a2")
              end


              if j1_a3 == -1 then
                --game.addDislike(nil, "a3")
                game.addDislike("joueur 1", "a3")
              elseif j1_a3 == 1 then
                --game.addLike(nil, "a3")
                game.addLike("joueur 1", "a3")
              end


              if j2_a1 == -1 then
                --game.addDislike(nil, "a1")
                game.addDislike("joueur 2", "a1")
              elseif j2_a1 == 1 then
                --game.addLike(nil, "a1")
                game.addLike("joueur 2", "a1")
              end


              if j2_a2 == -1 then
                --game.addDislike(nil, "a2")
                game.addDislike("joueur 2", "a2")
              elseif j2_a2 == 1 then
                --game.addLike(nil, "a2")
                game.addLike("joueur 2", "a2")
              end


              if j2_a3 == -1 then
                --game.addDislike(nil, "a3")
                game.addDislike("joueur 2", "a3")
              elseif j2_a3 == 1 then
                --game.addLike(nil, "a3")
                game.addLike("joueur 2", "a3")
              end

              nb = nb + 1

              local lm1 = saa.computeGraphSAA(1, game.graphs["joueur 1"], "tau_1", nil, 1, 8)
              local lm2 = saa.computeGraphSAA(1, game.graphs["joueur 2"], "tau_1", nil, 1, 8)
              local play = false
              if (lm1 <= lm_start  and lm_start <= lm2) or
                 (lm2 <= lm_start and lm_start <= lm1) then
                saa.computeSAA   (game, "tau_1", nil, 1, 8)
                rules.mindChanged(game, parameters)
                play = true
              end

              print("a1\t\t|a2\t\t|a3")
              print("(".. (game.graphs.general.vertices.a1.likes or 0) .. ", " .. (game.graphs.general.vertices.a1.dislikes or 0) .. ")" ..
              "\t\t|("..(game.graphs.general.vertices.a2.likes or 0) .. ", " .. (game.graphs.general.vertices.a2.dislikes or 0) .. ")" ..
              "\t\t|("..(game.graphs.general.vertices.a3.likes or 0) .. ", " .. (game.graphs.general.vertices.a3.dislikes or 0) .. ")")
              print(lm1 .. "\t|" .. lm2 .. "\t|" .. lm_start .. "\t|" .. tostring(play))
              print("-----------------------------")

              if j2_a3 == -1 then
                game.removeDislike(nil, "a3")
                game.removeDislike("joueur 2", "a3")
              elseif j2_a3 == 1 then
                game.removeLike(nil, "a3")
                game.removeLike("joueur 2", "a3")
              end

              if j2_a2 == -1 then
                game.removeDislike(nil, "a2")
                game.removeDislike("joueur 2", "a2")
              elseif j2_a2 == 1 then
                game.removeLike(nil, "a2")
                game.removeLike("joueur 2", "a2")
              end

              if j2_a1 == -1 then
                game.removeDislike(nil, "a1")
                game.removeDislike("joueur 2", "a1")
              elseif j2_a1 == 1 then
                game.removeLike(nil, "a1")
                game.removeLike("joueur 2", "a1")
              end

              if j1_a3 == -1 then
                game.removeDislike(nil, "a3")
                game.removeDislike("joueur 1", "a3")
              elseif j1_a3 == 1 then
                game.removeLike(nil, "a3")
                game.removeLike("joueur 1", "a3")
              end

              if j1_a2 == -1 then
                game.removeDislike(nil, "a2")
                game.removeDislike("joueur 1", "a2")
              elseif j1_a2 == 1 then
                game.removeLike(nil, "a2")
                game.removeLike("joueur 1", "a2")
              end

              if j1_a1 == -1 then
                game.removeDislike(nil, "a1")
                game.removeDislike("joueur 1", "a1")
              elseif j1_a1 == 1 then
                game.removeLike(nil, "a1")
                game.removeLike("joueur 1", "a1")
              end
            end
          end
        end
      end
    end
  end
  print (nb, nb / 27)
end

local import_game     = require "import_xml"
local game = import_game("/home/talkie/Documents/Stage/DebateGames/src/game_1.xml")
local parameters = {type_vote = "better"}
normal_game.NormalForm(game, parameters)
