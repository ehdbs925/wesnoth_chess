local Board = {}

Board.grid = {}

function Board.init()
    for y=1,8 do
        Board.grid[y] = {}
        for x=1,8 do
            Board.grid[y][x] = nil
        end
    end
end

function Board.update()
    Board.init()
    local units = wesnoth.get_units{}
    for _,u in ipairs(units) do
        Board.grid[u.y][u.x] = u
    end
end

function Board.get(x,y)
    if x < 1 or x > 8 or y < 1 or y > 8 then return nil end
    return Board.grid[y][x]
end

return Board
