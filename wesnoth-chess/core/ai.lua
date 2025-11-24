local Search = wesnoth.require "~add-ons/wesnoth-chess/core/search.lua"
local Logic = wesnoth.require "~add-ons/wesnoth-chess/core/logic.lua"

local AI = {}

function AI.play_turn(side)
    local action = Search.best_move(side, Logic)
    if action then
        wesnoth.ai.move(action.unit, action.x, action.y)
    end
end

return AI
