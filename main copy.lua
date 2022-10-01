local inspect = require("inspect")
local vec = require("vector")

--
-- Assorted utility
--

local function lerp(a, b, t)
    return vec.add(a, vec.mult(vec.normalize(vec.sub(b, a)), t))
end

local function pointInRect(point, rect_pos, rect_size)
    return point.x >= rect_pos.x and point.x <= rect_pos.x + rect_size.x
       and point.y >= rect_pos.y and point.y <= rect_pos.y + rect_size.y
end

--
-- Game state
--

local map_size = { x = 32, y = 18 }
local tile_colors = {
    [1] = { r = 1, g = 1, b = 1 }, -- empty ground
    [2] = { r = 0, g = 0, b = 0 }, -- walls
    [3] = { r = 1, g = 0, b = 0 }, -- stone
    [4] = { r = 0, g = 1, b = 0 }, -- trees
    [5] = { r = 0, g = 0, b = 1 }, -- water
}
local solid = {
    [1] = false,
    [2] = true,
    [3] = true,
    [4] = true,
    [5] = true,
}
local interactable = {
    [3] = "stone",
    [4] = "wood",
    [5] = "water"
}
local map = {
    4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    4, 4, 4, 4, 4, 4, 4, 4, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 4, 4 ,4, 4, 4, 1, 1, 1, 1, 1, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
}
local player_move_time = 0.33
local player_interact_time = 
local player = { 
    pos = { x = 6, y = 10 },
    state = "static",
    -- state = "moving"
    move_points = {},
    move_timer = 0.0,
    -- state = "interacting"
    interaction = {}
    interact_timer = 0.0
}
local resources = {
    ["stone"] = 0,
    ["wood"]  = 0,
    ["water"] = 0
}

local function mapIndex(vec)
    return 1 + (vec.y * map_size.x + vec.x)
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
    do
        local remaining_dt = 0
        if player.state == "static" then
            player.move_timer = player.move_timer - dt
            if player.move_timer <= 0.0 then
                remaining_dt = -player.move_timer
                player.state = "moving"
                player.pos = player.move_points._end
            end
        end
        if player.state == "moving" then
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
            if move_vector.x ~= 0 and move_vector.y ~= 0 then
                -- hacky
                move_vector.y = 0
            end
            if  vec.size(move_vector) > 0
            and not solid[map[mapIndex(vec.add(player.pos, move_vector))]]
            then
                player.state = "moving"
                player.move_points = {
                    start = player.pos,
                    _end = vec.add(player.pos, move_vector)
                }
                player.move_timer = player_move_time - remaining_dt
            end
        end
    end
end

function love.mousepressed(x, y, button, istouch)
    if button ~= 1 then
        return
    end
    if player.state ~= "static" then
        return
    end
    -- what blocks are we facing?
    local facing = {
        vec.add(player.pos, { x =  1, y =  0 }),
        vec.add(player.pos, { x = -1, y =  0 }),
        vec.add(player.pos, { x =  0, y =  1 }),
        vec.add(player.pos, { x =  0, y = -1 })
    }
    -- where is the mouse?
    local mpos = { x = x / tile_size.x, y = y / tile_size.y }
    -- is the mouse over one of the blocks we're facing?
    local hovered_block
    for _, block in ipairs(facing) do
        if pointInRect(mpos, block, { x = 1, y = 1 }) then
            hovered_block = block
            break
        end
    end
    if hovered_block == nil then
        return
    end
    -- is the block interactable?
    local block_type = map[mapIndex(hovered_block)]
    local resource = interactable[block_type]
    if resources[resource] == nil then
        return
    end
    -- update the player to be acquiring the resource
    player.state = "interacting"

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
    do
        local realpos
        if player.moving then
            realpos = lerp(player.move_points.start, player.move_points._end, 1.0 - (player.move_timer / player_move_time))
        else
            realpos = player.pos
        end
        realpos = vec.hadProduct(realpos, { x = tile_size.x, y = tile_size.y })
        realpos = vec.add(realpos, { x = player_radius, y = player_radius })
        
        love.graphics.circle("fill", realpos.x, realpos.y, player_radius)
    end

    -- Draw resources UI
    do
        local resources_text = ""
        for resource, amount in pairs(resources) do
            resources_text = resources_text..resource..": "..amount.." / "
        end
        love.graphics.print(resources_text, 0, 0)
    end
end
