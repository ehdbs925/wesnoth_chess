local game = {}

-- 게임 상태 변수 초기화
game.highlighted_hexes = {} -- 하이라이트된 좌표 저장용 리스트
game.selected_unit = nil    -- 현재 선택된 유닛

function game.init()
    wesnoth.message("DEBUG", "game.init() 실행됨")
    -- game.init() 함수 내부에 추가
    game.has_moved = {} -- 유닛 ID별 이동 여부 저장 (캐슬링 판별용)
    -- 기존 유닛 제거 (테스트 시 중복 방지)
    -- wesnoth.wml_actions.kill { fire_event = false, animate = false } 

    local w, h = wesnoth.get_map_size()
    wesnoth.message("CHESS", "Board Size: " .. w .. " x " .. h)

    -- [편의성 함수] 유닛 배치
    local function spawn(side, type, x, y)
        wesnoth.put_unit({ x=x, y=y, type=type, side=side })
    end

    -- White pieces (Side 1)
    spawn(1, "Chess_Rook_White",   1, 10)
    spawn(1, "Chess_Knight_White", 2, 10)
    spawn(1, "Chess_Bishop_White", 3, 10)
    spawn(1, "Chess_Queen_White",  4, 10)
    spawn(1, "Chess_King_White",   5, 10)
    spawn(1, "Chess_Bishop_White", 6, 10)
    spawn(1, "Chess_Knight_White", 7, 10)
    spawn(1, "Chess_Rook_White",   8, 10)
    for x = 1, 8 do spawn(1, "Chess_Pawn_White", x, 9) end

    -- Black pieces (Side 2)
    spawn(2, "Chess_Rook_Black",   1, 1)
    spawn(2, "Chess_Knight_Black", 2, 1)
    spawn(2, "Chess_Bishop_Black", 3, 1)
    spawn(2, "Chess_Queen_Black",  4, 1)
    spawn(2, "Chess_King_Black",   5, 1)
    spawn(2, "Chess_Bishop_Black", 6, 1)
    spawn(2, "Chess_Knight_Black", 7, 1)
    spawn(2, "Chess_Rook_Black",   8, 1)
    for x = 1, 8 do spawn(2, "Chess_Pawn_Black", x, 2) end
    function game.init()

    -- [추가] 모든 유닛의 마나를 0으로 만들어서 '드래그 이동' 막기
    local all_units = wesnoth.get_units({ side = "1,2" })
    for _, u in ipairs(all_units) do
        u.moves = 0 -- 마나통은 5지만, 현재 마나는 0 (이동 불가 상태)
        
        -- [중요] 상태이상(slowed 등)이 있으면 텔레포트도 꼬일 수 있으니 제거
        u.status.slowed = false 
        u.status.petrified = false
    end
end
end

-- [[ 통합 클릭 핸들러: 선택과 이동을 동시에 처리 ]] --
function game.on_hex_click()
    local x = tonumber(wml.variables.x1)
    local y = tonumber(wml.variables.y1)
    
    -- 1. 현재 선택된 유닛이 있는가?
    if game.selected_unit then
        
        -- 1-1. 클릭한 곳이 '이동 가능한(하이라이트된) 칸'인가? -> 이동 실행!
        local move_info = nil
        for _, hex in ipairs(game.highlighted_hexes) do
            if hex.x == x and hex.y == y then
                move_info = hex
                break
            end
        end

        if move_info then
            game.execute_move(x, y, move_info) -- 이동 함수 호출
            return -- 종료
        end

        -- 1-2. 이동하려는 게 아니라 '다른 아군 유닛'을 클릭했나? -> 선택 변경
        local clicked_unit = wesnoth.get_unit(x, y)
        if clicked_unit and clicked_unit.side == wesnoth.current.side then
            -- 기존 하이라이트 지우고 새로 선택
            game.select_unit(clicked_unit) 
            return
        end

        -- 1-3. 그 외 (빈 땅이나 엉뚱한 곳 클릭) -> 선택 해제
        game.clear_highlights()
        game.selected_unit = nil
        wesnoth.message("CHESS", "선택 해제됨")
        
    else
        -- 2. 선택된 유닛이 없을 때 -> 유닛 선택 시도
        local u = wesnoth.get_unit(x, y)
        if u and u.side == wesnoth.current.side then
            game.select_unit(u)
        end
    end
end


-- [[ 내부 로직: 유닛 선택 ]] --
function game.select_unit(u)
    game.clear_highlights() -- 기존 것 지우기
    
    game.selected_unit = u
    wesnoth.message("CHESS", "선택됨: " .. u.type)
    
    -- 이동 가능 범위 계산 및 표시
    game.highlight_moves(u)
end



-- [[ 이동 실행: 유닛 변수에 기록 저장 ]] --
function game.execute_move(to_x, to_y, move_info)
    local u = game.selected_unit
    
    if not u or not u.valid then 
        game.clear_highlights()
        return 
    end
  
    local unit_id = u.id
    local unit_side = u.side
    local unit_y = u.y

    -- 1. 적군 잡기
    local target = wesnoth.get_unit(to_x, to_y)
    if target then
        if target.id == unit_id then -- 자폭 방지
            game.clear_highlights()
            game.selected_unit = nil
            return
        end
        if target.side == unit_side then -- 팀킬 방지
            wesnoth.message("ERROR", "아군은 공격 불가!")
            game.clear_highlights()
            game.selected_unit = nil
            return
        end
        -- 적 제거
        wesnoth.wml_actions.kill({ id = target.id, animate = true, fire_event = true })
    end

    -- 2. 텔레포트 (무조건 이동)
    wesnoth.wml_actions.teleport({
        id = unit_id,
        x = to_x,
        y = to_y,
        animate = false 
    })
    
    -- [핵심 수정] 유닛 자체 변수에 '움직임' 기록 (저장해도 남음!)
    local u_after = wesnoth.get_unit(to_x, to_y) -- 텔레포트 후 유닛 정보 갱신
    if u_after then
        u_after.variables.chess_moved = true
        u_after.moves = 0 -- (중요) 겉보기 마력을 0으로 만듦
    end

    -- 3. 캐슬링 처리
    if move_info.is_castle then
        if move_info.is_castle == "kingside" then
            local rook = wesnoth.get_unit(8, unit_y)
            if rook then 
                wesnoth.wml_actions.teleport({id=rook.id, x=6, y=unit_y}) 
                rook.variables.chess_moved = true -- 룩도 움직인 것으로 처리
            end
        elseif move_info.is_castle == "queenside" then
            local rook = wesnoth.get_unit(1, unit_y)
            if rook then 
                wesnoth.wml_actions.teleport({id=rook.id, x=4, y=unit_y}) 
                rook.variables.chess_moved = true
            end
        end
    end
    local moved_unit = wesnoth.get_unit(to_x, to_y)
    
    game.clear_highlights()
    game.selected_unit = nil
    wesnoth.fire("end_turn")
end


-- 하이라이트 표시 로직
function game.highlight_moves(u)
    local moves = game.get_legal_moves(u)
    
    if not moves then return end -- 이동 가능 칸이 없으면 종료

    for _, hex in ipairs(moves) do
        -- [수정] image 대신 halo 사용 (유닛 위에 표시됨)
        -- [수정] 테스트를 위해 기본 이미지 사용. 잘 되면 본인 경로로 수정하세요.
        local img_path = "misc/hover-hex.png" 
        
        wesnoth.wml_actions.item({
            x = hex.x,
            y = hex.y,
            halo = img_path 
        })
        
        -- 나중에 지우기 위해 기록
        table.insert(game.highlighted_hexes, {x=hex.x, y=hex.y, img=img_path})
    end
end

-- 하이라이트 제거 로직
function game.clear_highlights()
    for _, item in ipairs(game.highlighted_hexes) do
        wesnoth.wml_actions.remove_item({
            x = item.x,
            y = item.y,
            halo = item.img -- 추가할 때 썼던 경로와 똑같아야 지워짐
        })
    end
    game.highlighted_hexes = {} -- 리스트 초기화
end

-- 유닛 이동 실행


-- 각 기물별 이동 로직 분기
-- [[ 메인 이동 판별 함수 ]] --
function game.get_legal_moves(u)
    -- u.type은 WML의 [unit_type] id와 일치합니다.
    
    -- 1. 폰 (Pawn)
    if u.type == "Chess_Pawn_White" or u.type == "Chess_Pawn_Black" then
        return game.get_pawn_moves(u)
    
    -- 2. 룩 (Rook)
    elseif u.type == "Chess_Rook_White" or u.type == "Chess_Rook_Black" then
        return game.get_rook_moves(u)
    
    -- 3. 나이트 (Knight)
    elseif u.type == "Chess_Knight_White" or u.type == "Chess_Knight_Black" then
        return game.get_knight_moves(u)
    
    -- 4. 비숍 (Bishop)
    elseif u.type == "Chess_Bishop_White" or u.type == "Chess_Bishop_Black" then
        return game.get_Bishop_moves(u)
    
    -- 5. 퀸 (Queen)
    elseif u.type == "Chess_Queen_White" or u.type == "Chess_Queen_Black" then
        return game.get_Queen_moves(u)
    
    -- 6. 킹 (King)
    elseif u.type == "Chess_King_White" or u.type == "Chess_King_Black" then
        return game.get_King_moves(u)
    end

    -- 그 외 유닛 (혹시 모를 오류 방지)
    return {}
end

-- 아래 함수들은 나중에 로직을 채워넣으세요
-- [[ 헬퍼 함수들 (이동 계산용) ]] --

-- 좌표가 보드 내부에 있는지 확인 (작성하신 배치에 맞춰 y 1~10으로 설정)
local function is_on_board(x, y)
    return x >= 1 and x <= 8 and y >= 1 and y <= 10
end

-- 해당 좌표의 상태 확인 (빈칸, 적, 아군)
local function check_spot(u, x, y)
    if not is_on_board(x, y) then return "blocked" end
    
    local target = wesnoth.get_unit(x, y)
    if not target then
        return "empty"
    elseif target.side ~= u.side then
        return "enemy" -- 잡을 수 있음
    else
        return "friend" -- 막힘
    end
end

-- 슬라이딩 이동 (룩, 비숍, 퀸) 공통 로직
local function get_sliding_moves(u, directions)
    local moves = {}
    for _, dir in ipairs(directions) do
        local dx, dy = dir[1], dir[2]
        for i = 1, 8 do -- 최대 8칸까지 뻗어나감
            local nx, ny = u.x + (dx * i), u.y + (dy * i)
            local status = check_spot(u, nx, ny)
            
            if status == "empty" then
                table.insert(moves, {x = nx, y = ny})
            elseif status == "enemy" then
                table.insert(moves, {x = nx, y = ny})
                break -- 적을 만나면 잡고 멈춤
            else -- blocked or friend
                break -- 막히면 멈춤
            end
        end
    end
    return moves
end

-- 스텝/점프 이동 (나이트, 킹) 공통 로직
local function get_step_moves(u, offsets)
    local moves = {}
    for _, off in ipairs(offsets) do
        local nx, ny = u.x + off[1], u.y + off[2]
        local status = check_spot(u, nx, ny)
        if status == "empty" or status == "enemy" then
            table.insert(moves, {x = nx, y = ny})
        end
    end
    return moves
end


-- [[ 각 기물별 이동 로직 ]] --

-- [[ 폰 (Pawn) 이동 로직 수정판 (좌표 무시) ]] --
-- [[ 폰 (Pawn) 이동 로직: 유닛 변수 사용 버전 ]] --
function game.get_pawn_moves(u)
    local moves = {}
    
    local dy = (u.side == 1) and -1 or 1
    
    -- 1. 앞으로 1칸
    local one_step_y = u.y + dy
    if check_spot(u, u.x, one_step_y) == "empty" then
        table.insert(moves, {x = u.x, y = one_step_y})
        
        -- 2. 앞으로 2칸 (조건: 유닛 몸에 'chess_moved'라는 기록이 없어야 함)
        if not u.variables.chess_moved then
            local two_step_y = u.y + (dy * 2)
            if check_spot(u, u.x, two_step_y) == "empty" then
                table.insert(moves, {x = u.x, y = two_step_y})
            end
        end
    end

    -- 3. 대각선 공격
    local attack_dirs = {-1, 1}
    for _, dx in ipairs(attack_dirs) do
        local target_x = u.x + dx
        local target_y = u.y + dy
        if check_spot(u, target_x, target_y) == "enemy" then
            table.insert(moves, {x = target_x, y = target_y})
        end
    end
    
    return moves
end

function game.get_rook_moves(u)
    -- 상하좌우
    local dirs = {{0, -1}, {0, 1}, {-1, 0}, {1, 0}}
    return get_sliding_moves(u, dirs)
end

function game.get_Bishop_moves(u)
    -- 대각선 4방향
    local dirs = {{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}
    return get_sliding_moves(u, dirs)
end

function game.get_Queen_moves(u)
    -- 룩 + 비숍 (8방향)
    local dirs = {
        {0, -1}, {0, 1}, {-1, 0}, {1, 0},   -- 직선
        {-1, -1}, {1, -1}, {-1, 1}, {1, 1}  -- 대각선
    }
    return get_sliding_moves(u, dirs)
end

function game.get_knight_moves(u)
    -- L자 점프 (8지점)
    local offsets = {
        {1, -2}, {2, -1}, {2, 1}, {1, 2},
        {-1, 2}, {-2, 1}, {-2, -1}, {-1, -2}
    }
    return get_step_moves(u, offsets)
end

-- [[ 킹 이동 로직 수정 부분 ]] --
function game.get_King_moves(u)
    -- ... (기본 1칸 이동 로직은 그대로) ...
    local moves = get_step_moves(u, offsets) -- 기존 코드 활용

    -- 캐슬링: 유닛 변수 확인
    if not u.variables.chess_moved then
        local y = u.y
        
        -- 킹사이드
        local rook_k = wesnoth.get_unit(8, y)
        -- 룩이 존재하고 + 룩도 움직인 적이 없어야 함
        if rook_k and not rook_k.variables.chess_moved then
            if check_spot(u, 6, y) == "empty" and check_spot(u, 7, y) == "empty" then
                table.insert(moves, {x = 7, y = y, is_castle = "kingside"})
            end
        end

        -- 퀸사이드
        local rook_q = wesnoth.get_unit(1, y)
        if rook_q and not rook_q.variables.chess_moved then
            if check_spot(u, 2, y) == "empty" and 
               check_spot(u, 3, y) == "empty" and 
               check_spot(u, 4, y) == "empty" then
                table.insert(moves, {x = 3, y = y, is_castle = "queenside"})
            end
        end
    end

    return moves
end
return game