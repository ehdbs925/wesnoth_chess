local Eval = {}

Eval.value = {
    Pawn=100, Knight=320, Bishop=330, Rook=500, Queen=900, King=20000
}

function Eval.get_piece_value(id)
    if id:find("Pawn") then return Eval.value.Pawn end
    if id:find("Knight") then return Eval.value.Knight end
    if id:find("Bishop") then return Eval.value.Bishop end
    if id:find("Rook") then return Eval.value.Rook end
    if id:find("Queen") then return Eval.value.Queen end
    if id:find("King") then return Eval.value.King end
    return 0
end

function Eval.evaluate(side)
    local score = 0
    local units = wesnoth.get_units{}
    for _,u in ipairs(units) do
        local v = Eval.get_piece_value(u.id)
        if u.side == side then score = score + v
        else score = score - v end
    end
    return score
end

return Eval
