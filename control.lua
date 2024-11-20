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

local function pick_weighted(items) 
    local total_weight = 0
    for _,weight in pairs(items) do
        total_weight = total_weight + weight
    end

    local random_weight = math.random(1, total_weight)

    local last_weight = 0
    local current_weight = 0

    local item = ""

    for name,weight in pairs(items) do
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

    if weighted == true then
        local weighted_items = {}
        for _,item_name in pairs(item_names) do
            local weighted_item_name = string.split(item_name, "|")

            weighted_items[weighted_item_name[1]] = tonumber(weighted_item_name[2])
        end 
        item_name = pick_weighted(weighted_items)
    else
        item_name = item_names[math.random(1, #item_names)]
    end

    -- Either insert into a container or drop on the ground
    -- Since we only get an entity if it's in a container we can check that
    local position = table.deepcopy(properties.source_position or properties.target_position or {x = 0, y = 0})
    local entity = properties.target_entity or properties.source_entity

    if entity ~= nil then
        local inventory = nil
        if entity.held_stack.can_set_stack({name = item_name, count = 1}) then
            entity.held_stack.set_stack({name = item_name, count = 1})
            return
        elseif entity.get_inventory(defines.inventory.robot_cargo) ~= nil then
            inventory = entity.get_inventory(defines.inventory.robot_cargo)
        elseif entity.get_inventory(defines.inventory.assembling_machine_dump) ~= nil then
            inventory = entity.get_inventory(defines.inventory.assembling_machine_dump)
        else
            inventory = entity
        end
        if inventory == nil then
            error("Inventory is nil: " .. entity.name)
        end
        inventory.insert{name = item_name, count = 1}
    else
        game.get_surface(properties.surface_index).spill_item_stack{position = position, stack = {name = item_name, count = 1}}
    end
end)