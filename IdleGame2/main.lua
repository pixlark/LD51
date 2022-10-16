local Object  = require "lib/classic"
local Input   = require "lib/Input"
local inspect = require "lib/inspect"
local Vector  = require "lib/vector"

--
-- Entity
--

local Entity = Object:extend()

function Entity:new()
end

function Entity:update(dt)
end

function Entity:draw()
end

--
-- Player
--

local Player = Entity:extend()

function Player:new()
    Player.super.new(self)
    self.pos = Vector.new(0, 0)
end

function Player:update(dt)
end

function Player:draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", self.pos.x, self.pos.y, 100, 100)
end

--
-- GameState
--

local GameState = Object:extend()

function GameState:new()
    self.entities = {
        Player()
    }
end

function GameState:update(dt)
    for _, entity in ipairs(self.entities) do
        entity:update(dt)
    end
end

function GameState:draw()
    for _, entity in ipairs(self.entities) do
        entity:draw()
    end
end

local game_state

--
-- LOVE hooks
--

function love.load()
    game_state = GameState()
end

function love.update(dt)
    game_state:update(dt)
end

function love.draw()
    love.graphics.setColor(0, 0, 0)
    love.graphics.clear()
    game_state:draw()
end
