local Board = wesnoth.require "~add-ons/wesnoth-chess/core/board.lua"
local Rules = wesnoth.require "~add-ons/wesnoth-chess/core/rules.lua"
local AI = wesnoth.require "~add-ons/wesnoth-chess/core/ai.lua"
local State = wesnoth.require "~add-ons/wesnoth-chess/core/state.lua"

local Logic = {}

function Logic.init()
    Board.init()
    Rules.init()
    State.reset()
end

function Logic.on_turn(side)
    Board.update()

    if Rules.is_checkmate(1) then
        State.result = "black_win"
        return "checkmate"
    end
    if Rules.is_checkmate(2) then
        State.result = "white_win"
        return "checkmate"
    end

    if side == 2 then
        AI.play_turn(side)
    end

    return "continue"
end

return Logic
