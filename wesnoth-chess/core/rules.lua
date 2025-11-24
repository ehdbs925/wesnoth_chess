local Board = wesnoth.require "~add-ons/wesnoth-chess/core/board.lua"
local Utils = wesnoth.require "~add-ons/wesnoth-chess/core/utils.lua"

local Rules = {}

function Rules.init()
end

-- King 찾기
local function get_king(side)
    local u = wesnoth.get_units{ id="Chess_King", side=side }
    return u[1]
end

-- 공격받는 칸인지
local function under_attack(x,y, attacker_side, logic)
    local enemies = wesnoth.get_units{side = attacker_side}
    for _,u in ipairs(enemies) do
        local moves = logic.get_moves(u)
        for _,m in ipairs(moves) do
            if m.x==x and m.y==y then return true end
        end
    end
    return false
end

-- 체크 판정
function Rules.is_in_check(side, logic)
    local king = get_king(side)
    if not king then return false end
    local enemy = (side==1 and 2 or 1)
    return under_attack(king.x, king.y, enemy, logic)
end

-- 체크메이트 판정
function Rules.is_checkmate(side, logic)
    if not Rules.is_in_check(side, logic) then return false end

    local king = get_king(side)
    local enemy = (side==1 and 2 or 1)

    local moves = logic.get_moves(king)
    for _,m in ipairs(moves) do
        if not under_attack(m.x, m.y, enemy, logic) then
            return false
        end
    end

    return true
end

return Rules
