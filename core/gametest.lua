local game = {}
game = game or {}
game.selected = nil
game.valid_moves = {}  -- [ "x,y" ] = true 형태

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

function game.clear_highlighted_moves()
    wesnoth.message("CHESS", "하이라이트 초기화: ")
    if game.highlighted_hexes then
        for _, hex in ipairs(game.highlighted_hexes) do
            wesnoth.wml_actions.remove_item({ x = hex.x, y = hex.y})
        end
    end
    game.highlighted_hexes = {}
end

function game.highlight_moves(u)
    game.clear_highlighted_moves()
    wesnoth.message("CHESS", "하이라이트 실행됨: ")
    local x = u.x
    local y = u.y
    game.highlighted_hexes = {}

    -- 예시: 모든 방향 1칸 이동 가능
    for dx=-1,1 do
        for dy=-1,1 do
            if not (dx==0 and dy==0) then
                local nx = x + dx
                local ny = y + dy

                table.insert(game.highlighted_hexes, {x=nx, y=ny})

                wesnoth.wml_actions.item({x=nx, y=ny, image="buttons/radiobox@2x.png"})
            end
        end
    end
end




--이동 함수 
function game.on_move_unit(x, y)
    wesnoth.message("DEBUG", "on_move_unit() 실행됨")

    if not game.selected then return end

    local u = game.selected

    wesnoth.message("CHESS", u.type .. " 이동 → " .. x .. "," .. y)
    wesnoth.wml_actions.move_unit({ id=u.id, x=x, y=y })

    game.selected = nil
    game.clear_highlighted_moves()
end




function game.get_pawn_moves(u)
    local moves = {}
    local dir = 0
    if u.type == "Chess_Pawn_White" then
        dir = -1
    elseif u.type == "Chess_Pawn_Black" then
        dir = 1
    else
        return moves
    end
    
    local w,h = wesnoth.get_map_size()

    -- 1칸 앞으로
    local nx = u.x
    local ny = u.y + dir
    
    if ny >= 1 and ny <= h then
        if not wesnoth.get_unit(nx, ny) then
            table.insert(moves, {x=nx,y=ny})
        end
    end
    
    -- 첫 이동 → 2칸 가능
    if (u.type == "Chess_Pawn_White" and u.y == 9) or
       (u.type == "Chess_Pawn_Black" and u.y == 2) then
        
        local ny2 = u.y + dir * 2
        if ny2 >= 1 and ny2 <= h then
            if not wesnoth.get_unit(nx, ny2) and not wesnoth.get_unit(nx, ny) then
                table.insert(moves, {x=nx,y=ny2})
            end
        end
    end
    
    -- 대각선 공격 가능(화이트→위, 블랙→아래)
    for dx = -1,1,2 do
        local cx = u.x + dx
        local cy = u.y + dir

        if cx >= 1 and cx <= w and cy >= 1 and cy <= h then
            local target = wesnoth.get_unit(cx,cy)
            if target and target.side ~= u.side then
                table.insert(moves, {x=cx,y=cy})
            end
        end
    end
    
    return moves
end

return game