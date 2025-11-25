local game = {}

function game.init()
    wesnoth.message("DEBUG", "game.init() 실행됨")

    local w, h = wesnoth.get_map_size()
    wesnoth.message("DEBUG", "맵 크기 확인: " .. w .. " x " .. h)
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

function game.on_select_unit()
    local x = tonumber(wml.variables.x1)
    local y = tonumber(wml.variables.y1)
    
    if not x or not y then
        wesnoth.message("ERROR", "x1,y1좌표가 존재하지 않습니다")
        return
    end

    local u = wesnoth.get_unit(x, y)

    if not u then
        wesnoth.message("ERROR", "Unit not found at"..wml.variables.x1..","..wml.variables.y1)
        return
    end

    wesnoth.message("CHESS", "선택됨: "..u.type)

    game.selected = u
    game.highlight_moves(u)
end


function game.highlight_moves(u)
    wesnoth.message("DEBUG", "Highlight moves for "..u.type)
    wesnoth.wml_actions.scroll_to({x=u.x, y=u.y})
    
    -- 기존 표시 제거
    wesnoth.wml_actions.remove_item({})

    for dx = -1,1 do
        for dy = -1,1 do
            if not (dx==0 and dy==0) then
                local nx = u.x + dx
                local ny = u.y + dy
                
                if nx >= 1 and nx <= 8 and ny >= 1 and ny <= 8 then
                    -- 목적 hex가 비어 있는지 확인
                    local target = wesnoth.get_unit(nx, ny)
                    if not target then
                        wesnoth.wml_actions.item({
                            x=nx,
                            y=ny,
                            image="misc/capture.png"
                        })
                    end
                end
            end
        end
    end
end

--이동 함수 
function game.on_move_unit(to_x, to_y)
    wesnoth.message("DEBUG", "on_move_unit() 실행됨")

    if not game.selected then
        wesnoth.message("ERROR", "이동하려는 선택된 유닛이 없습니다")  
        return
    end

    local u = game.selected

    wesnoth.wml_actions.move_unit({
        id = u.id,
        x  = to_x,
        y  = to_y,
    })

    local after_pos = tostring(u.x)..","..tostring(u.y)
    wesnoth.message("Lua>", "REAL UNIT POS(after)="..after_pos)

    game.selected = nil
end


return game