local inspect = require("inspect")

local function struct(...)
    local fields = {}
    for _, name in ipairs({ n = select('#', ...); ... }) do
        fields[name] = true
    end
    print(inspect(fields))

    local mt = {
        fields = fields,
        __index = mt
    }
    function mt.new(instance_fields)
        for name, _ in pairs(instance_fields) do
            -- check that this field exists on the struct
            if not mt.fields[name] then
                error(string.format("struct new: field %s does not exist on struct", name))
            end
        end
        local instance = {table.unpack(instance_fields)} -- shallow copy
        setmetatable(instance, mt)
        return instance
    end
    return mt
end

return struct
