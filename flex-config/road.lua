-- Change SRID if desired
local srid = 3857

local tables = {}

tables.road_line = osm2pgsql.define_table({
    name = 'road_line',
    schema = 'osm',
    ids = { type = 'way', id_column = 'osm_id' },
    columns = {
        { column = 'osm_type',     type = 'text', not_null = true },
        { column = 'name',     type = 'text' },
        { column = 'ref',     type = 'text' },
        { column = 'maxspeed', type = 'int' },
        { column = 'oneway',     type = 'direction' },
        { column = 'geom',     type = 'linestring', projection = srid }
    }
})


-- Parse a maxspeed value like "30" or "55 mph" and return a number in km/h
-- from osm2pgsql/flex-config/data-types.lua
function parse_speed(input)
    if not input then
        return nil
    end

    local maxspeed = tonumber(input)

    -- If maxspeed is just a number, it is in km/h, so just return it
    if maxspeed then
        return maxspeed
    end

    -- If there is an 'mph' at the end, convert to km/h and return
    if input:sub(-3) == 'mph' then
        local num = tonumber(input:sub(1, -4))
        if num then
            return math.floor(num * 1.60934)
        end
    end

    return nil
end


function road_process_way(object)
    -- We are only interested in highways
    if not object.tags.highway then
        return
    end

    -- Using grab_tag() removes from remaining key/value saved to Pg
    local name = object:grab_tag('name')
    local osm_type = object:grab_tag('highway')
    local ref = object:grab_tag('ref')
    -- in km/hr
    maxspeed = parse_speed(object.tags.maxspeed)

    oneway = object:grab_tag('oneway') or 0

    tables.road_line:add_row({
        name = name,
        osm_type = osm_type,
        ref = ref,
        maxspeed = maxspeed,
        oneway = oneway,
        geom = { create = 'line' }
    })

end


-- deep_copy based on copy2: https://gist.github.com/tylerneylon/81333721109155b2d244
function deep_copy(obj)
    if type(obj) ~= 'table' then return obj end
    local res = setmetatable({}, getmetatable(obj))
    for k, v in pairs(obj) do res[deep_copy(k)] = deep_copy(v) end
    return res
end


if osm2pgsql.process_way == nil then
    -- Change function name here
    osm2pgsql.process_way = road_process_way
else
    local nested = osm2pgsql.process_way
    osm2pgsql.process_way = function(object)
        local object_copy = deep_copy(object)
        nested(object)
        -- Change function name here
        road_process_way(object_copy)
    end
end
