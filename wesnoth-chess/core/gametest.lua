local game = {}

function game.init()
    wesnoth.message("DEBUG", "game.init() 실행됨")

    wesnoth.message("CHESS", "맵 크기 = " ..
        wesnoth.current.map_bounds.max_x .. " x " ..
        wesnoth.current.map_bounds.max_y
    )

    wesnoth.message("CHESS", "테스트: 일반 병사 생성")
    wesnoth.put_unit{ x=5, y=5, type="Spearman", side=1 }

    wesnoth.scroll_to_hex(5,5)
end

return game
