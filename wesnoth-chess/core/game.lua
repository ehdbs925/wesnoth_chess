local game = {}

function game.init()
    wesnoth.message("DEBUG", "game.init() 실행됨")

    wesnoth.message("CHESS", "Spawning initial board pieces")

    -- White pieces
    wesnoth.put_unit({ x=1, y=10, type="Chess_Rook_White", side=1 })
    wesnoth.put_unit({ x=2, y=10, type="Chess_Knight_White", side=1 })
    wesnoth.put_unit({ x=3, y=10, type="Chess_Bishop_White", side=1 })
    wesnoth.put_unit({ x=4, y=10, type="Chess_Queen_White", side=1 })
    wesnoth.put_unit({ x=5, y=10, type="Chess_King_White", side=1 })
    wesnoth.put_unit({ x=6, y=10, type="Chess_Bishop_White", side=1 })
    wesnoth.put_unit({ x=7, y=10, type="Chess_Knight_White", side=1 })
    wesnoth.put_unit({ x=8, y=10, type="Chess_Rook_White", side=1 })

    for x = 1,8 do
        wesnoth.put_unit({ x=x, y=9, type="Chess_Pawn_White", side=1 })
    end

    -- Black pieces
    wesnoth.put_unit({ x=1, y=1, type="Chess_Rook_Black", side=2 })
    wesnoth.put_unit({ x=2, y=1, type="Chess_Knight_Black", side=2 })
    wesnoth.put_unit({ x=3, y=1, type="Chess_Bishop_Black", side=2 })
    wesnoth.put_unit({ x=4, y=1, type="Chess_Queen_Black", side=2 })
    wesnoth.put_unit({ x=5, y=1, type="Chess_King_Black", side=2 })
    wesnoth.put_unit({ x=6, y=1, type="Chess_Bishop_Black", side=2 })
    wesnoth.put_unit({ x=7, y=1, type="Chess_Knight_Black", side=2 })
    wesnoth.put_unit({ x=8, y=1, type="Chess_Rook_Black", side=2 })

    for x = 1,8 do
        wesnoth.put_unit({ x=x, y=2, type="Chess_Pawn_Black", side=2 })
    end
end

return game