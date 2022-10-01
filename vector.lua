-- TODO: Figure out metatables to make this syntax implicit

local module = {}

function module.add(a, b)
    return { x = a.x + b.x, y = a.y + b.y }
end

function module.sub(a, b)
    return { x = a.x - b.x, y = a.y - b.y }
end

function module.mult(vec, t)
    return { x = vec.x * t, y = vec.y * t }
end

function module.div(vec, t)
    return { x = vec.x / t, y = vec.y / t }
end

function module.size(vec)
    return math.sqrt(vec.x * vec.x + vec.y * vec.y)
end

function module.normalize(vec)
    return module.div(vec, module.size(vec))
end

-- Hadamard product (element-wise product)
function module.hadProduct(a, b)
    return { x = a.x * b.x, y = a.y * b.y }
end

-- Dot product (scalar product, inner product)
function module.dotProduct(a, b)
    return a.x * b.x + a.y * b.y
end

return module
