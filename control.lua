require("util")

--- Splits by delimiter
--- @param to_split string
--- @param delimiter string
--- @return string[]
function string.split(to_split, delimiter)
    if string.find(to_split, delimiter) ~= 0 then
        local splitted = {}
        for split in string.gmatch(to_split, "([^" .. delimiter .. "]+)") do
            table.insert(splitted, split)
        end
        return splitted
    end
    return {to_split}
end

-- Picks a weight item
local function pick_weighted(items) 
    local total_weight = 0
    for _,properties in pairs(items) do
        total_weight = total_weight + properties.weight
    end

    local random_weight = math.random(1, total_weight)

    local last_weight = 0
    local current_weight = 0

    local item = ""

    for name,properties in pairs(items) do
        local weight = properties.weight
        
        if last_weight == 0 then
            current_weight = weight
        else
            current_weight = current_weight + weight
        end

        if last_weight <= random_weight and random_weight <= current_weight then
            item = name
            break
        end

        last_weight = last_weight + weight
    end

    return item
end

-- Takes weighted items list and returns an item name
local function pick_weighted_items(item_names)
    local weighted_items = {}
    for _,item_name in pairs(item_names) do
        local weighted_item_name = string.split(item_name, "|")
        local splitted = string.split(weighted_item_name[2], ".")
        local weight = tonumber(splitted[1])
        local count = tonumber(splitted[2])

        weighted_items[weighted_item_name[1]] = {weight = weight, count = count}
    end 
    item_name = pick_weighted(weighted_items)

    return item_name, count
end

script.on_event(defines.events.on_script_trigger_effect, function(properties)
    -- game.print(tostring(properties.effect_id))

    if string.sub(properties.effect_id, 1, 13) ~= "spoiled-item-" then
        return
    end

    local items = string.sub(properties.effect_id, 14, #properties.effect_id)
    -- Check if it's weighted if it's weighted we must do more bs!!!
    local weighted = false
    if string.find(items, "|") ~= nil then
        weighted = string.find(items,"|") > 0
    end
    
    -- Split by every item
    local item_names = string.split(items, ",")
    local item_name = ""
    local item_count = 1

    if weighted == true then
        local name,count = pick_weighted_items(item_names)
        item_name = name
        item_count = count
    else
        local random_item = item_names[math.random(1, #item_names)]
        local splitted = string.split(random_item, ".")
        -- game.print(splitted[1] .. ", " .. splitted[2])
        item_name = splitted[1]
        item_count = splitted[2]
    end

    -- Either insert into a container or drop on the ground
    -- Since we only get an entity if it's in a container we can check that
    local position = table.deepcopy(properties.source_position or properties.target_position or {x = 0, y = 0})
    local entity = properties.target_entity or properties.source_entity

    if entity ~= nil then
        local inventory = nil
        -- game.print(entity.type)
        if entity.type == "inserter" then
            local success, _ = pcall(entity.held_stack.set_stack, {name = item_name, count = item_count, quality = properties.quality})
            if success == false then
                error("Failed to spoil in inserter")
            end
        elseif entity.type == "transport-belt" or entity.type == "belt" then
            local success, _ = pcall(game.get_surface(properties.surface_index).spill_item_stack, {position = position, stack = {name = item_name, count = item_count, quality = properties.quality}, drop_full_stack=true, use_start_position_on_failure = false})
            if success == false then
                error("Failed to spoil on belt")
            end
        end
        if entity.get_inventory(defines.inventory.robot_cargo) ~= nil then
            inventory = entity.get_inventory(defines.inventory.robot_cargo)
        elseif entity.get_inventory(defines.inventory.assembling_machine_dump) ~= nil then
            inventory = entity.get_inventory(defines.inventory.assembling_machine_dump)
        else
            inventory = entity
        end
        if inventory == nil then
            error("Inventory is nil: " .. entity.name)
        end
        inventory.insert{name = item_name, count = item_count, quality = properties.quality}
    else
        game.get_surface(properties.surface_index).spill_item_stack{position = position, stack = {name = item_name, count = item_count, quality = properties.quality}}
    end
end)

