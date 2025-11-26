-- [[ 1. 전역 변수 안전 선언 ]] --
local game = {}

game.selected_unit = nil
game.highlighted_hexes = {}

-- [[ 2. 게임 초기화 ]] --
function game.init()
    wesnoth.message("DEBUG", "Chess Game Init (Menu Action Mode)")

    -- (1) 유닛 배치
    local function spawn(side, type, x, y)
        wesnoth.put_unit({ x=x, y=y, type=type, side=side })
        local u = wesnoth.get_unit(x, y)
        if u then
            u.max_moves = 5; u.moves = 0; u.variables.chess_moved = false
        end
    end

    -- 백색 & 흑색 배치
    spawn(1, "Chess_Rook_White",   1, 8); spawn(1, "Chess_Knight_White", 2, 8)
    spawn(1, "Chess_Bishop_White", 3, 8); spawn(1, "Chess_Queen_White",  4, 8)
    spawn(1, "Chess_King_White",   5, 8); spawn(1, "Chess_Bishop_White", 6, 8)
    spawn(1, "Chess_Knight_White", 7, 8); spawn(1, "Chess_Rook_White",   8, 8)
    for x=1,8 do spawn(1, "Chess_Pawn_White", x, 7) end
    
    spawn(2, "Chess_Rook_Black",   1, 1);  spawn(2, "Chess_Knight_Black", 2, 1)
    spawn(2, "Chess_Bishop_Black", 3, 1);  spawn(2, "Chess_Queen_Black",  4, 1)
    spawn(2, "Chess_King_Black",   5, 1);  spawn(2, "Chess_Bishop_Black", 6, 1)
    spawn(2, "Chess_Knight_Black", 7, 1);  spawn(2, "Chess_Rook_Black",   8, 1)
    for x=1,8 do spawn(2, "Chess_Pawn_Black", x, 2) end

    -- (2) 유닛 개조 (무기/동맹 설정 불필요)
    local all_units = wesnoth.get_units({ side = "1,2" })
    for _, u in ipairs(all_units) do
        wesnoth.wml_actions.modify_unit({
            [1] = { "filter", { id = u.id } }, 
            max_moves = 5, moves = 0,
            ["movement_costs"] = { flat=1, castle=1, village=1, grassland=1, impassable=99 }
        })
    end

    -- (3) 좌클릭 이벤트: 유닛 선택
    wesnoth.wml_actions.event({
        name = "select",
        first_time_only = false,
        [1] = { "lua", { code = "if game then game.on_select() end" } }
    })

    -- (4) 우클릭 메뉴 등록 (핵심!)
    -- 땅을 우클릭했을 때 이동 가능한 곳이면 메뉴가 뜹니다.
    wesnoth.wml_actions.set_menu_item({
        id = "chess_move",
        description = "체스 이동/공격",
        image = "misc/hover-hex.png",
        allow_in_debug = false,
        show_if = "",
        needs_select = false,
        -- 메뉴가 뜨는 조건: 하이라이트 된 땅이어야 함
        [1] = { "show_if", {
            [1] = { "lua", { code = "return game.check_menu_condition()" } }
        }},
        
        -- 메뉴 클릭 시 실행할 행동
        [2] = { "command", {
            [1] = { "lua", { code = "game.execute_menu_action()" } }
        }}
    })

    -- (5) 턴 리프레시
    wesnoth.wml_actions.event({
        name = "turn refresh", first_time_only = false,
        [1] = { "lua", { code = [[
            local units = wesnoth.get_units({ side = wesnoth.current.side })
            for _, u in ipairs(units) do u.moves = 0 end
            game.check_king_warning()
        ]] } }
    })
        -- (X) AI 턴 이벤트 등록: side 2의 턴이 시작되면 game.ai_turn() 호출
    wesnoth.wml_actions.event({
        name = "side turn",
        first_time_only = false,
        [1] = { "filter_side", { side = 2 } },
        [2] = { "lua", { code = "if game and game.ai_turn then game.ai_turn() end" } }
    })

end

-- [[ 3. 유닛 선택 로직 (좌클릭) ]] --
function game.on_select()
    game.clear_highlights()
    game.clear_selected_unit_highlight()
    local x, y = wesnoth.interface.get_hovered_hex()
    local u = wesnoth.get_unit(x, y)
    -- 내 턴이고 내 유닛이면 선택
    if u and u.side == wesnoth.current.side then
        game.selected_unit = u
        game.selected_unit_hex = {x=u.x, y=u.y}
        wesnoth.wml_actions.item({ x=u.x, y=u.y, image="misc/hover-hex-yours-bottom.png" })
        game.highlight_moves(u) -- 이동 범위 표시
    else
        -- 빈 땅이나 적을 좌클릭하면 선택 해제
        game.selected_unit = nil
    end
end

-- [[ 4. 메뉴 조건 확인 (우클릭 시 발동) ]] --
function game.check_menu_condition()
    if not game.selected_unit then return false end
    
    local x, y = wesnoth.interface.get_hovered_hex()


    -- 지금 우클릭한 곳이 하이라이트 목록에 있는가?
    if game.highlighted_hexes then
        for _, hex in ipairs(game.highlighted_hexes) do
            if hex.x == x and hex.y == y then
                return true
            end
        end
    end
    return false
end

-- [[ 5. 메뉴 실행 로직 ]] --
function game.execute_menu_action()
    local x, y = wesnoth.interface.get_hovered_hex()

    
    -- 이동 정보 찾기
    local move_info = nil
    for _, hex in ipairs(game.highlighted_hexes) do
        if hex.x == x and hex.y == y then
            move_info = hex
            break
        end
    end

    if move_info then
        game.perform_move(x, y, move_info)
    end
end

-- [[ 6. 실제 이동 및 공격 (강제 집행) ]] --
function game.perform_move(to_x, to_y, move_info)
    local u = game.selected_unit
    if not u or not u.valid then return end
    
    local u_id = u.id
    local u_side = u.side
    local u_type = u.type
    local u_y = u.y
    local me = wesnoth.get_unit(u_id)

    game.clear_highlights()
    game.clear_selected_unit_highlight()

    
     -- 적군이 있으면 공격
    local target = wesnoth.get_unit(to_x, to_y)
    if target and target.side ~= u_side then
        
        local tx, ty = target.x, target.y
        

        wesnoth.delay(200)
        
        if game.is_king(target) then
            wesnoth.message("GAME", "킹이 죽었습니다 — 게임 종료!")
            wesnoth.extract_unit(target)
            wesnoth.extract_unit(me)
            wesnoth.put_unit({ id=u_id, type=u_type, side=u_side, x=to_x, y=to_y, moves=0 })
            wesnoth.delay(400)
            game.end_game(target.side)
            return
        else
            wesnoth.extract_unit(target)
        end
    end

    if me then wesnoth.extract_unit(me) end
    
    wesnoth.put_unit({ id=u_id, type=u_type, side=u_side, x=to_x, y=to_y, moves=0 })

    local moved_u = wesnoth.get_unit(to_x, to_y)
    if moved_u then moved_u.variables.chess_moved = true end

    if move_info and move_info.is_castle then
        if move_info.is_castle == "kingside" then
            local rook = wesnoth.get_unit(8, u_y)
            if rook then wesnoth.extract_unit(rook); wesnoth.put_unit({id=rook.id, type=rook.type, side=rook.side, x=6, y=u_y, moves=0}) end
        elseif move_info.is_castle == "queenside" then
            local rook = wesnoth.get_unit(1, u_y)
            if rook then wesnoth.extract_unit(rook); wesnoth.put_unit({id=rook.id, type=rook.type, side=rook.side, x=4, y=u_y, moves=0}) end
        end
    end

    game.selected_unit = nil
    wesnoth.wml_actions.redraw({})
    wesnoth.fire("end_turn")
end

function game.highlight_moves(u)
    local moves = game.get_legal_moves(u)
    for _, hex in ipairs(moves) do
        local target = wesnoth.get_unit(hex.x, hex.y)
        if hex.x >= 1 and hex.x <= 8 and hex.y >= 1 and hex.y <= 8 then
            local img = "misc/hover-hex.png"
            wesnoth.wml_actions.item({ x=hex.x, y=hex.y, halo=img })
            table.insert(game.highlighted_hexes, hex)
        end
    end
    wesnoth.wml_actions.redraw({})
    
end

function game.clear_highlights()
    if not game.highlighted_hexes then return end
    for _, item in ipairs(game.highlighted_hexes) do
        wesnoth.wml_actions.remove_item({ x=item.x, y=item.y })
    end
    game.highlighted_hexes = {}
    wesnoth.wml_actions.redraw({})
end

function game.clear_selected_unit_highlight()
    if game.selected_unit_hex then
        wesnoth.wml_actions.remove_item({ x=game.selected_unit_hex.x, y=game.selected_unit_hex.y })
        game.selected_unit_hex = nil
    end
end
-- [[ 8. 이동 규칙 (Logic) ]] --
local function check_spot(u, x, y)
    if x < 1 or x > 8 or y < 1 or y > 8 then return "blocked" end
    local target = wesnoth.get_unit(x, y)
    if not target then return "empty"
    elseif target.side ~= u.side then return "enemy"
    else return "friend" end
end

function game.get_legal_moves(u)
    if u.type:find("Pawn") then return game.get_pawn_moves(u) end
    if u.type:find("Rook") then return game.get_rook_moves(u) end
    if u.type:find("Knight") then return game.get_knight_moves(u) end
    if u.type:find("Bishop") then return game.get_bishop_moves(u) end
    if u.type:find("Queen") then return game.get_queen_moves(u) end
    if u.type:find("King") then return game.get_king_moves(u) end
    return {}
end

function game.get_pawn_moves(u)
    local moves = {}
    local dy = (u.side == 1) and -1 or 1
    if check_spot(u, u.x, u.y+dy) == "empty" then
        table.insert(moves, {x=u.x, y=u.y+dy})
        if not u.variables.chess_moved then
            if check_spot(u, u.x, u.y+(dy*2)) == "empty" then
                table.insert(moves, {x=u.x, y=u.y+(dy*2)})
            end
        end
    end
    for _, dx in ipairs({-1, 1}) do
        if check_spot(u, u.x+dx, u.y+dy) == "enemy" then
            table.insert(moves, {x=u.x+dx, y=u.y+dy})
        end
    end
    return moves
end

local function get_sliding_moves(u, dirs)
    local moves = {}
    for _, dir in ipairs(dirs) do
        for i = 1, 8 do
            local nx, ny = u.x + (dir[1]*i), u.y + (dir[2]*i)
            local status = check_spot(u, nx, ny)
            if status == "empty" then table.insert(moves, {x=nx, y=ny})
            elseif status == "enemy" then table.insert(moves, {x=nx, y=ny}); break
            else break end
        end
    end
    return moves
end

local function get_step_moves(u, offsets)
    local moves = {}
    for _, off in ipairs(offsets) do
        local nx, ny = u.x + off[1], u.y + off[2]
        local status = check_spot(u, nx, ny)
        if status == "empty" or status == "enemy" then
            table.insert(moves, {x=nx, y=ny})
        end
    end
    return moves
end

function game.get_rook_moves(u) return get_sliding_moves(u, {{0,-1},{0,1},{-1,0},{1,0}}) end
function game.get_bishop_moves(u) return get_sliding_moves(u, {{-1,-1},{1,-1},{-1,1},{1,1}}) end
function game.get_queen_moves(u) return get_sliding_moves(u, {{0,-1},{0,1},{-1,0},{1,0},{-1,-1},{1,-1},{-1,1},{1,1}}) end
function game.get_knight_moves(u) return get_step_moves(u, {{1,-2},{2,-1},{2,1},{1,2},{-1,2},{-2,1},{-2,-1},{-1,-2}}) end
function game.get_king_moves(u)
    local moves = get_step_moves(u, {{0,-1},{0,1},{-1,0},{1,0},{-1,-1},{1,-1},{-1,1},{1,1}})
    if not u.variables.chess_moved then
        local y = u.y
        local rk = wesnoth.get_unit(8, y)
        if rk and not rk.variables.chess_moved and check_spot(u,6,y)=="empty" and check_spot(u,7,y)=="empty" then
            table.insert(moves, {x=7, y=y, is_castle="kingside"})
        end
        local rq = wesnoth.get_unit(1, y)
        if rq and not rq.variables.chess_moved and check_spot(u,2,y)=="empty" and check_spot(u,3,y)=="empty" and check_spot(u,4,y)=="empty" then
            table.insert(moves, {x=3, y=y, is_castle="queenside"})
        end
    end
    return moves
end

function game.do_attack(attacker, defender)

    wesnoth.audio.play("attacks/sword-human.wav")


    wesnoth.wml_actions.animate_unit({
        flag="attack",
        hit=true,
        [1]={ "filter", { id= "Cavalryman"} },
        primary=true,
        with_bars=true
    })

    wesnoth.wml_actions.animate_unit({
        flag="defend",
        [1]={ "filter", { id=defender.id } }
    })

    -- 애니메이션 대기 시간
    wesnoth.delay(350)

    -- 이제 죽임
    wesnoth.extract_unit(defender)
    wesnoth.wml_actions.redraw({})
end

function game.ai_turn()

    local ai_side = wesnoth.current.side     -- 여기서는 2
    local ai_units = wesnoth.get_units({ side = ai_side })

    local final_unit = nil
    local final_move = nil
    local best_score = -99999

    for _, unit in ipairs(ai_units) do
        local moves = game.get_legal_moves(unit)

        for _, hex in ipairs(moves) do
            local score = game.ai_score_move(unit, hex)

            if score > best_score then
                best_score = score
                final_unit = unit
                final_move = hex
            end
        end
    end

    if final_unit and final_move then
        game.selected_unit = final_unit
        game.perform_move(final_move.x, final_move.y, final_move)
    end

    wesnoth.fire("end_turn")
end



function game.ai_move_unit(u)
    local moves = game.get_legal_moves(u)
    if #moves == 0 then return end

    -- 1) 가치 높은 캡처
    local best_capture = game.ai_find_best_capture(u, moves)
    if best_capture and game.ai_is_safe_move(u, best_capture) then
        game.perform_move(best_capture.x, best_capture.y, best_capture)
        return
    end

    -- 2) 거점 점령 (예: 중앙)
    local zone_move = game.ai_move_to_zone(u, moves)
    if zone_move then
        game.perform_move(zone_move.x, zone_move.y, zone_move)
        return
    end

    -- 3) 랜덤 이동
    game.perform_move(moves[math.random(#moves)].x, moves[math.random(#moves)].y)
end


function game.get_piece_value(u)
    if u.type:find("Queen") then return 9 end
    if u.type:find("Rook") then return 5 end
    if u.type:find("Bishop") or u.type:find("Knight") then return 3 end
    if u.type:find("Pawn") then return 1 end
    if u.type:find("King") then return 10 end
    return 0
end

function game.ai_is_safe_move(u, move)
    local temp_x, temp_y = move.x, move.y
    local enemies = wesnoth.get_units({ side = 1 })

    for _, enemy in ipairs(enemies) do
        local moves = game.get_legal_moves(enemy)
        for _, m in ipairs(moves) do
            if m.x == temp_x and m.y == temp_y then
                return false
            end
        end
    end
    return true
end

function game.ai_find_best_capture(u, moves)
    local best = nil
    local best_value = -1

    for _, hex in ipairs(moves) do
        local t = wesnoth.get_unit(hex.x, hex.y)
        if t and t.side ~= u.side then
            if game.is_king(t) then
                return hex   -- 킹 발견 → 바로 먹음
            end
            local v = game.get_piece_value(t)
            if v > best_value then
                best_value = v
                best = hex
            end
        end
    end
    return best
end

function game.ai_is_safe_move(u, move)
    local temp_x, temp_y = move.x, move.y
    local enemies = wesnoth.get_units({ side = 1 })

    for _, enemy in ipairs(enemies) do
        local moves = game.get_legal_moves(enemy)
        for _, m in ipairs(moves) do
            if m.x == temp_x and m.y == temp_y then
                return false
            end
        end
    end
    return true
end

function game.ai_move_to_zone(u, moves)
    for _, hex in ipairs(moves) do
        if hex.x >= 3 and hex.x <= 6 and hex.y >= 4 and hex.y <= 7 then
            return hex
        end
    end
    return nil
end

function game.is_king(u)
    return u.type == "Chess_King_White" or u.type == "Chess_King_Black"
end
function game.ai_score_move(u, hex)

    -- 1) 캡처 가능하면 점수
    local target = wesnoth.get_unit(hex.x, hex.y)
    if target then
        if game.is_king(target) then
            return 10000   -- 왕 먹기 최우선
        end
        return game.get_piece_value(target) * 20
    end

    -- 2) 중앙 점수 (3~6, 4~7)
    if hex.x >= 3 and hex.x <= 6 and hex.y >= 4 and hex.y <= 7 then
        return 15
    end

    -- 3) 안전성 체크
    if game.ai_is_safe_move(u, hex) then
        return 3
    else
        return -50
    end
end

function game.end_game(dead_side)
    if dead_side == 1 then
        wesnoth.message("GAME", "백색 킹이 죽었습니다 — 흑의 승리!")
        wesnoth.wml_actions.endlevel({ result="defeat" })
    else
        wesnoth.message("GAME", "흑색 킹이 죽었습니다 — 백의 승리!")
        wesnoth.wml_actions.endlevel({ result="victory" })
    end
    wesnoth.delay(2000)
end

function game.is_king_in_check(side)
    local units = wesnoth.get_units({side = side})
    local king = nil
    
    for _, u in ipairs(units) do
        if game.is_king(u) then
            king = u
            break
        end
    end
    
    if not king then return false end
    
    local enemies = wesnoth.get_units({ side = (side == 1) and 2 or 1 })

    for _, enemy in ipairs(enemies) do
        local moves = game.get_legal_moves(enemy)
        for _, hex in ipairs(moves) do
            if hex.x == king.x and hex.y == king.y then
                return true
            end
        end
    end

    return false
end

function game.check_king_warning()
    local current = wesnoth.current.side
    if game.is_king_in_check(current) then
        if current == 1 then
            wesnoth.message("CHECK", "백색 왕이 위험합니다!")
        else
            wesnoth.message("CHECK", "흑색 왕이 위험합니다!")
        end
    end
end

return game