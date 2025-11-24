local Eval = wesnoth.require "~add-ons/wesnoth-chess/core/eval.lua"

local Search = {}

function Search.best_move(side, logic)
    local units = wesnoth.get_units {side=side}
    local best_score = -999999
    local best_action = nil

    for _,u in ipairs(units) do
        local moves = logic.get_moves(u)
        for _,m in ipairs(moves) do
            local result = wesnoth.simulate_move(u, m.x, m.y)
            local score = Eval.evaluate(side)

            if score > best_score then
                best_score = score
                best_action = {unit=u, x=m.x, y=m.y}
            end
        end
    end

    return best_action
end

return Search
