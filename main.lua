local inspect = require("inspect")
local vec = require("vector")

--
-- Assorted utility
--

local function lerp(a, b, t)
    local dir = vec.normalize(vec.sub(b, a))
    local distance = vec.size(vec.sub(b, a))
    return vec.add(a, vec.mult(dir, t * distance))
end

local function pointInRect(point, rect_pos, rect_size)
    return point.x >= rect_pos.x and point.x < rect_pos.x + rect_size.x
       and point.y >= rect_pos.y and point.y < rect_pos.y + rect_size.y
end

local function round(x, multiple)
    local rem = x % multiple
    return x - rem
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
    [6] = true,
}
local interactable = {
    [3] = "stone",
    [4] = "wood",
    [5] = "water"
}
local map = {
    4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    4, 4, 4, 4, 4, 4, 4, 4, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2,
    4, 4, 4 ,4, 4, 4, 1, 1, 1, 1, 1, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 6, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    5, 5, 1, 1, 1, 1, 1, 1, 1, 5, 5, 5, 5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
    5, 5, 5, 5, 1, 1, 1, 1, 5, 5, 5, 5, 5, 5, 1, 1, 1, 1, 1, 1, 5, 5, 5, 5, 5, 1, 1, 1, 1, 1, 1, 2,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 1, 1, 1, 1, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
}
local player_move_time = 0.4
local player_interact_time = 0.15
local player = { 
    pos = { x = 6, y = 10 },
    state = "static",
    -- state = "moving"
    move_points = {},
    move_timer = 0.0,
    -- state = "interacting"
    interaction = {},
    interact_dir = { x = 0, y = 0 },
    interact_timer = 0.0
}
local resources = {
    ["stone"] = 0,
    ["wood"]  = 0,
    ["water"] = 0,
    ["gold"]  = 0,
}
local buttons_state = {}
local upgrades = {
    gold_per_turn = 1.0
}
local ten_second_timer = 10.0

local function mapIndex(vec)
    return 1 + (vec.y * map_size.x + vec.x)
end

--
-- Graphics helpers
--

-- Interpolates via a piecewise parabola, so that the
-- increasing side of the parabola can go up faster
-- than the decreasing side or vice-versa
local function smoothPeakInterpolation(t, peak)
    if t < peak then
        return -(((1.0 / peak) * t - 1.0) ^ 2) + 1.0
    else
        return -(((1.0 / (1.0 - peak)) ^ 2) * t - (peak / (1.0 - peak))) + 1.0
    end
end

--
-- Love hooks
--

local tile_size
local player_radius

local font_files = {
    default = { "Eczar-VariableFont_wght.ttf", 26 }
}
local fonts
local sprite_files = {
    player = "betterplayer.png",
    backgrounds = {
        home = "homearea.png"
    },
    gobutton = {
        base = "gobutton.png",
        highlight = "gobutton_highlight.png",
        pressed = "gobutton_pressed.png"
    },
    arrowbutton = {
        base = "arrow.png",
        highlight = "arrow_highlight.png",
        pressed = "arrow_pressed.png"
    },
    crafting_ui_bg = "craftingui.png"
}
local sprites

function love.load()
    assert(#map == map_size.x * map_size.y)
    tile_size = {
        x = love.graphics.getWidth() / map_size.x,
        y = love.graphics.getHeight() / map_size.y
    }
    print("tile_size: ", inspect(tile_size))
    player_radius = math.min(tile_size.x, tile_size.y) / 2.0

    local function loadFonts(filetree)
        local tree = {}
        for key, value in pairs(filetree) do
            if value[1] ~= nil then
                tree[key] = love.graphics.newFont(value[1], value[2])
            else
                tree[key] = loadFonts(value)
            end
        end
        return tree
    end

    fonts = loadFonts(font_files)
    assert(fonts.default ~= nil)
    love.graphics.setFont(fonts.default)

    local function loadSprites(filetree)
        local tree = {}
        for key, value in pairs(filetree) do
            if type(value) == "string" then
                tree[key] = love.graphics.newImage(value)
            elseif type(value) == "table" then
                tree[key] = loadSprites(value)
            else
                assert(false, "Sprite file tree had bad value")
            end
        end
        return tree
    end
    
    sprites = loadSprites(sprite_files)
end

function love.update(dt)
    -- Ten second timer
    ten_second_timer = ten_second_timer - dt
    if ten_second_timer <= 0.0 then
        ten_second_timer =  ten_second_timer + 10.0
        resources["gold"] = resources["gold"] + upgrades.gold_per_turn
    end

    -- Move player
    do
        -- The moving state is calculated first, and then the other states
        -- are calculated in an if-else chain. This is because, if the moving
        -- state *ends*, we want it to be able to immediately start up again
        -- so long as the move button is being held down. Otherwise, there's one
        -- frame in-between where the player is just standing still. This is
        -- where remaining_dt comes into play, so that the moving interpolation
        -- is as smooth as it can possibly be
        local remaining_dt = 0
        if player.state == "moving" then
            player.move_timer = player.move_timer - dt
            if player.move_timer <= 0.0 then
                remaining_dt = -player.move_timer
                player.state = "static"
                player.pos = player.move_points._end
            end
        end
        if player.state == "static" then
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
        elseif player.state == "interacting" then
            player.interact_timer = player.interact_timer - dt
            if player.interact_timer <= 0.0 then
                remaining_dt = -player.interact_timer
                player.state = "static"
                if player.interaction.type == "acquire resource" then
                    resources[player.interaction.resource] = resources[player.interaction.resource] + 1
                end
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
        vec.add(player.pos, { x =  0, y = -1 }),
        vec.add(player.pos, { x =  1, y =  1 }),
        vec.add(player.pos, { x =  1, y = -1 }),
        vec.add(player.pos, { x = -1, y =  1 }),
        vec.add(player.pos, { x = -1, y = -1 }),
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
    player.interact_dir = vec.normalize(vec.sub(hovered_block, player.pos))
    player.interact_timer = player_interact_time
    player.interaction = {
        type = "acquire resource",
        resource = resource
    }
end

local debug_info = {}
function love.keypressed(key, scancode, isrepeat)
    if key == "space" then
        print(inspect(debug_info))
    end
end

local function drawCenteredText(string, x, y)
    local w = fonts.default:getWidth(string)
    love.graphics.printf(string, x - w/2, y, w, "left")
end

local function drawButton(name, pos, sprites, flags)
    if buttons_state[name] == nil then
        buttons_state[name] = false
    end

    local mpos = { x = love.mouse.getX(), y = love.mouse.getY() }
    local down = love.mouse.isDown(1)
    local w, h = sprites.base:getDimensions()
    
    local in_box = pointInRect(mpos, pos, { x = w, y = h })

    local sprite
    local pressed
    if in_box and not down and buttons_state[name] then
        -- released!
        buttons_state[name] = false
        sprite = sprites.highlight
        pressed = true
    elseif in_box and not down and not buttons_state[name] then
        -- hovered
        sprite = sprites.highlight
        pressed = false
    elseif in_box and down then
        -- pressed down
        buttons_state[name] = true
        sprite = sprites.pressed
        pressed = false
    else
        -- not interacted with
        sprite = sprites.base
        pressed = false
    end

    local y_scale
    if flags.upside_down ~= nil then
        y_scale = -1
        pos.y = pos.y - h
    end
    love.graphics.draw(sprite, pos.x, pos.y, nil, nil, y_scale)
    return pressed
end

function love.draw()
    love.graphics.setColor(0, 0, 0)
    love.graphics.clear()

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(sprites.backgrounds.home, 0, 0)

    -- Draw player
    do
        local realpos
        if player.state == "moving" then
            realpos = lerp(player.move_points.start, player.move_points._end, 1.0 - (player.move_timer / player_move_time))
        elseif player.state == "static" then
            realpos = player.pos
        elseif player.state == "interacting" then
            realpos = lerp(
                player.pos,
                vec.add(player.pos, vec.mult(player.interact_dir, 0.2)),
                smoothPeakInterpolation(1.0 - (player.interact_timer / player_interact_time), 0.2)
            )
        end
        realpos = vec.hadProduct(realpos, { x = tile_size.x, y = tile_size.y })
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(sprites.player, realpos.x, realpos.y - tile_size.y)
    end

    -- Draw resources UI
    do
        local resources_text = ""
        for resource, amount in pairs(resources) do
            if amount ~= 0 then
                resources_text = resources_text..resource..": "..amount.."   " 
            end
        end
        if resources_text == "" then
            resources_text = "You have zero resources."
        end

        local w = fonts.default:getWidth(resources_text)
        local h = fonts.default:getHeight()
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", 0, 0, round(w + 45, 40), h)

        love.graphics.setColor(1, 1, 1)
        love.graphics.print(resources_text, 10, 0)
    end

    -- Draw crafting table UI
    do
        local craft_square = {
            pos  = { x = 17, y = 9 },
            size = { x =  2, y = 1 }
        }
        if pointInRect(player.pos, craft_square.pos, craft_square.size) then
            local dialog_pos = { x = 0, y = 0 }
            
            love.graphics.draw(sprites.crafting_ui_bg, 600, 200)
            -- arrow buttons
            local up_pressed   = drawButton("craftingdialog_uparrow",   { x = 620, y = 220 }, sprites.arrowbutton, {})
            local down_pressed = drawButton("craftingdialog_downarrow", { x = 620, y = 380 }, sprites.arrowbutton, { upside_down = true })
        end
    end

    -- Draw gold timer
    do
        love.graphics.setColor(61 / 255, 51 / 255, 32 / 255)
        love.graphics.rectangle("fill", 0, 45, 100, 20)

        local progress = (1.0 - (ten_second_timer / 10.0))
        local t = progress ^ 1.7
        love.graphics.setColor(245 / 255, 1, 133 / 255)
        love.graphics.rectangle("fill", 5, 50, t * 90, 10)
    end

    -- Draw bridge-building UI
    do
        local build_square = {
            pos  = { x = 16, y = 15 },
            size = { x =  2, y =  1 }
        }
        if pointInRect(player.pos, build_square.pos, build_square.size) then
            local dialog_pos = vec.hadProduct({ x = 17, y = 16 }, tile_size)
            dialog_pos.y = dialog_pos.y + 10
            
            drawCenteredText("Build bridge", dialog_pos.x, dialog_pos.y)
            drawCenteredText("50 stone + 50 wood", dialog_pos.x, dialog_pos.y + 40)
            local pressed = drawButton("gobutton", vec.add(dialog_pos, { x = 75, y = -5 }), sprites.gobutton, {})
            if pressed then
                print("EAT MY BUTT")
            end
        end
    end
end
