local inspect = require("inspect")
local vec = require("lib/vector")

function love.load()
    print(inspect(vec.new(1, 1):size()))
end
