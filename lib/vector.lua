local mt = {}

local methods = {}

function methods:size()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

local function new(x, y)
    local vec = { x = x, y = y }
    setmetatable(vec, mt)
    return vec
end

local function add(self, vec)
    return new(self.x + vec.x, self.y + vec.y)
end

local function sub(self, vec)
    return new(self.x + vec.x, self.y + vec.y)
end

local function mult(self, t)
    return new(self.x * t, self.y * t)
end

local function div(self, t)
    return new(self.x / t, self.y / t)
end

mt.__add = add
mt.__sub = sub
mt.__mult = mult
mt.__div = div
mt.__index = methods

print(new(1, 2) + new(3, 4))

return {
    new = new
}
