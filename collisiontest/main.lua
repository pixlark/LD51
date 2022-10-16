local vec = require("vector")
local inspect = require("inspect")
local struct = require("struct")

local player = { x = 10, y = 10, w = 50, h = 50 }

local obstacles = {
    { x = 500, y = 500, w = 300, h = 100 },
    { x = 700, y = 300, w = 100, h = 200 },
    { x = 700, y = 200, w = 300, h = 100 },
    { x = 900, y = 400, w = 100, h = 100 },
    { x = 500, y = 200, w = 100, h = 100 }
}

local function overlap(a, b)
    return (a.x < b.x + b.w and b.x < a.x + a.w) and
           (a.y < b.y + b.h and b.y < a.y + a.h)
end

local function getOverlapVector(dynamic, static)
    local top    = function (box) return box.y end
    local bottom = function (box) return box.y + box.h end
    local left   = function (box) return box.x end
    local right  = function (box) return box.x + box.w end
    local displacement_vectors = {
        { x = left(static) - right(dynamic), y = 0 },
        { x = right(static) - left(dynamic), y = 0 },
        { x = 0, y = top(static) - bottom(dynamic) },
        { x = 0, y = bottom(static) - top(dynamic) }
    }
    -- find smallest displacement vector
    local s
    for _, v in ipairs(displacement_vectors) do
        if s == nil or vec.size(v) < vec.size(s) then
            s = v
        end
    end
    return s
end

function love.load()
    Vector2 = struct("x", "y")
    local v = Vector2.new { x = 1, y = 2 }
    print(inspect(v))
end

local overlapping = false

function love.update(dt)
    local dir = { x = 0, y = 0 }
    if love.keyboard.isDown("w") then
        dir.y = dir.y - 1
    end
    if love.keyboard.isDown("s") then
        dir.y = dir.y + 1
    end
    if love.keyboard.isDown("a") then
        dir.x = dir.x - 1
    end
    if love.keyboard.isDown("d") then
        dir.x = dir.x + 1
    end
    dir = vec.normalize(dir)

    player.x = player.x + dir.x * dt * 300
    player.y = player.y + dir.y * dt * 300

    overlapping = false
    for index, value in ipairs(obstacles) do
        if overlap(value, player) then
            overlapping = true
        end
    end

    -- iterative collision fixing
    while true do
        -- find a collision
        local overlap_obstacle
        for _, obstacle in ipairs(obstacles) do
            if overlap(player, obstacle) then
                overlap_obstacle = obstacle
                break
            end
        end
        -- no collisions, break
        if overlap_obstacle == nil then
            break
        end
        -- nudge us out of the collision
        local overlap_vector = getOverlapVector(player, overlap_obstacle)
        player.x = player.x + overlap_vector.x
        player.y = player.y + overlap_vector.y
    end
end

function love.draw()
    love.graphics.setColor(0, 0, 0)
    love.graphics.clear()
    if overlapping then
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(1, 0, 0)
    end
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)
    
    local colors = {
        { r = 0, g = 1, b = 0 },
        { r = 0, g = 0, b = 1 },
        { r = 1, g = 0, b = 1 },
        { r = 1, g = 1, b = 0 },
        { r = 0, g = 1, b = 1 }
    }
    for i = 1, #obstacles do
        local idx = ((i - 1) % #obstacles) + 1
        love.graphics.setColor(colors[idx].r, colors[idx].g, colors[idx].b)
        love.graphics.rectangle("fill", obstacles[i].x, obstacles[i].y, obstacles[i].w, obstacles[i].h)
    end
end
