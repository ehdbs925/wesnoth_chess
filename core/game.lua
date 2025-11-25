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

    game.selected_unit = u
    game.highlight_moves(u)
end


function game.highlight_moves(u)
    local moves = game.get_legal_moves(u)
    
    for _, hex in ipairs(moves) do
        wesnoth.wml_actions.item({
            x=hex.x,
            y=hex.y,
            image="misc/highlight.png"
        })
        table.insert(game.highlighted_hexes, hex)
    end
end

--이동 함수 
function game.on_move_unit(to_x, to_y)
    wesnoth.message("DEBUG", "on_move_unit() 실행됨")

    local u = game.selected_unit
    if not u then
        wesnoth.message("ERROR", "이동하려는 선택된 유닛이 없습니다")
        return
    end

    if u.type == "Chess_Pawn_White" or u.type == "Chess_Pawn_Black" then
        if not game.can_move_pawn(u, to_x, to_y) then
            wesnoth.message("CHESS", "잘못된 폰 이동")
            return
        end
    end
    wesnoth.wml_actions.move_unit({
        id = u.id,
        x  = to_x,
        y  = to_y,
    })

    local after_pos = tostring(u.x)..","..tostring(u.y)
    wesnoth.message("Lua>", "REAL UNIT POS(after)="..after_pos)

    game.selected = nil
end

function game.can_move_pawn(u, to_x, to_y)
    local ux, uy = u.x, u.y

    -- side=1 은 백, 위에서 아래로 이동
    -- side=2 은 흑, 아래에서 위로 이동
    local dir = (u.side == 1) and -1 or 1

    -- 타겟 위치 유닛 확인
    local target = wesnoth.get_unit(to_x, to_y)

    -----------------------------------------------------------
    -- 1) 기본 1칸 전진 (유닛 없어야 함)
    -----------------------------------------------------------
    if to_x == ux and to_y == uy + dir then
        if not target then
            return true
        end
    end

    -----------------------------------------------------------
    -- 2) 처음 위치에서 2칸 전진 가능
    -- 백 폰 초기 y = 7
    -- 흑 폰 초기 y = 2
    -----------------------------------------------------------
    if to_x == ux and to_y == uy + 2*dir then
        if not u.has_moved then
            -- 중간 칸 확인
            local mid_y = uy + dir
            if not wesnoth.get_unit(ux, mid_y) and not target then
                return true
            end
        end
    end

    -----------------------------------------------------------
    -- 3) 대각선 공격 (그 칸에 적 유닛 있어야 가능)
    -----------------------------------------------------------
    if math.abs(to_x - ux) == 1 and to_y == uy + dir then
        if target and target.side ~= u.side then
            return true
        end
    end

    return false
end

function game.get_legal_moves(u)
    if u.type == "Chess_Pawn_White" or u.type == "Chess_Pawn_Black" then
        return game.get_pawn_moves(u)
    elseif u.type == "Chess_Rook_White" or u.type == "Chess_Rook_Black" then
        return game.get_rook_moves(u)
    elseif u.type == "Chess_Knight_White" or u.type == "Chess_Knight_Black" then
        return game.get_knight_moves(u)
    end
end

return game