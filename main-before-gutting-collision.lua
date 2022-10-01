local inspect = require("inspect")
local vec = require("vector")

--
-- Intersection testing
--

local function circleBoxIntersect(circle, radius, topleft, bottomright)
    local top    = topleft.y
    local bottom = bottomright.y
    local left   = topleft.x
    local right  = bottomright.x

    local within_x = circle.x >= left and circle.x <= right
    local within_y = circle.y >= top  and circle.y <= bottom

    -- Inside
    if within_x and within_y then
        return true
    end
    -- Above/Below
    if within_x and (not within_y) then
        return math.min(math.abs(circle.y - top), math.abs(circle.y - bottom)) < radius
    end
    -- Left/Right
    if (not within_x) and within_y then
        return math.min(math.abs(circle.x - left), math.abs(circle.x - right)) < radius
    end
    -- Corners
    return (vec.size(vec.sub(circle, topleft)) < radius)
        or (vec.size(vec.sub(circle, { x = right, y = top })) < radius)
        or (vec.size(vec.sub(circle, { x = left, y = bottom})) < radius)
        or (vec.size(vec.sub(circle, bottomright)) < radius)
end

--
-- Game state
--

local map_size = { x = 12, y = 8 }
local tile_colors = {
    [1] = { r = 1, g = 1, b = 1 },
    [2] = { r = 0, g = 0, b = 0 }
}
local solid = {
    [1] = false,
    [2] = true
}
local map = {
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 2,
    2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 2,
    2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
}
local player = { pos = { x = 4.0, y = 4.0 } }

local function mapIndex(x, y)
    return 1 + (y * map_size.x + x)
end

--
-- Love hooks
--

local tile_size
local player_radius

function love.load()
    assert(#map == map_size.x * map_size.y)
    tile_size = {
        x = love.graphics.getWidth() / map_size.x,
        y = love.graphics.getHeight() / map_size.y
    }
    player_radius = math.min(tile_size.x, tile_size.y) / 2.0
end

function love.update(dt)
    -- Move player
    local move_vector = { x = 0.0, y = 0.0 }
    if love.keyboard.isDown("w") then
        move_vector.y = move_vector.y - 1.0
    end
    if love.keyboard.isDown("s") then
        move_vector.y = move_vector.y + 1.0
    end
    if love.keyboard.isDown("a") then
        move_vector.x = move_vector.x - 1.0
    end
    if love.keyboard.isDown("d") then
        move_vector.x = move_vector.x + 1.0
    end
    local player_next_pos = vec.add(player.pos, vec.mult(move_vector, 3 * dt))

    -- Collide player
    local gridpos = { x = math.floor(player_next_pos.x), y = math.floor(player_next_pos.y) }

    local dir = vec.normalize(move_vector)
    local horiz = {
        x = gridpos.x + (dir.x > 0 and 1 or -1),
        y = gridpos.y
    }
    local vert = {
        x = gridpos.x,
        y = gridpos.y + (dir.y > 0 and 1 or -1)
    }

    local fudge_factor = 0.001
    local limit = 500
    local ok = false
    
    repeat
        ok = true

        -- Check the block next to us on the X axis. Slide horizontally.
        if  solid[map[mapIndex(horiz.x, horiz.y)]]
        and circleBoxIntersect(player_next_pos, 0.5, horiz,
                               vec.add(horiz, { x = 1.0, y = 1.0 }))
        then
            ok = false
            player_next_pos.x = player_next_pos.x - dir.x * fudge_factor
        end

        -- Check the block next to us on the Y axis. Slide vertically.
        if  solid[map[mapIndex(vert.x, vert.y)]]
        and circleBoxIntersect(player_next_pos, 0.5, vert,
                               vec.add(vert, { x = 1.0, y = 1.0 }))
        then
            ok = false
            player_next_pos.y = player_next_pos.y - dir.y * fudge_factor
        end

        -- Check the block diagonal from us. Slide vertically.
        if  ok
        and solid[map[mapIndex(horiz.x, vert.y)]]
        and circleBoxIntersect(player_next_pos, 0.5, { x = horiz.x, y = vert.y },
                               { x = horiz.x + 1, y = vert.y + 1 } )
        then
            ok = false;
            player_next_pos.y = player_next_pos.y - dir.y * fudge_factor
        end

        limit = limit - 1
    until ok or limit <= 0

    player.pos = player_next_pos
end

local debug_info = {}
function love.keypressed(key, scancode, isrepeat)
    if key == "space" then
        print(inspect(debug_info))
    end
end

function love.draw()
    love.graphics.setColor(0, 0, 0)
    love.graphics.clear()

    -- Draw map
    for x = 1, map_size.x do
        for y = 1, map_size.y do
            local color = tile_colors[map[(y - 1) * map_size.x + x]]
            love.graphics.setColor(color.r, color.g, color.b, 1)
            love.graphics.rectangle("fill", (x - 1) * tile_size.x, (y - 1) * tile_size.y, tile_size.x, tile_size.y)
        end
    end

    -- Draw player
    local realpos = vec.hadProduct(player.pos, { x = tile_size.x, y = tile_size.y })
    love.graphics.circle("fill", realpos.x, realpos.y, player_radius)
end
