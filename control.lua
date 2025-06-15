require("util")

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

-- Only for special case inventories relevant to items spoiling
local function get_spoil_inventory(entity)
    local bot_cargo = entity.get_inventory(defines.inventory.robot_cargo)
    if bot_cargo then
        return bot_cargo
    end
    local machine_dump = entity.get_inventory(defines.inventory.assembling_machine_dump)
    if machine_dump then
        return machine_dump
    end
    return entity
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
    local item_names = util.split(items, ",")
    local item_name = ""
    local item_count = 1

    if weighted == true then
        local name,count = pick_weighted_items(item_names)
        item_name = name
        item_count = count
    else
        local random_item = item_names[math.random(1, #item_names)]
        local splitted = util.split(random_item, ".")
        -- game.print(splitted[1] .. ", " .. splitted[2])
        item_name = splitted[1]
        item_count = tonumber(splitted[2]) or 1
    end

    -- Either insert into a container or drop on the ground
    -- Since we only get an entity if it's in a container we can check that
    local position = table.deepcopy(properties.source_position or properties.target_position or {x = 0, y = 0})
    local entity = properties.target_entity or properties.source_entity
    local safe_spill = false

    if entity ~= nil then
        -- game.print(entity.type)
        if entity.type == "inserter" then
            local stack_item_count = item_count
            if entity.held_stack.valid_for_read and entity.held_stack.name == item_name and entity.held_stack.quality == properties.quality then
                stack_item_count = stack_item_count + entity.held_stack.count
            end
            -- 
            if entity.held_stack.set_stack({name = item_name, count = stack_item_count, quality = properties.quality}) then
                item_count = 0
            end
        elseif entity.type == "transport-belt" or entity.type == "belt" then
            safe_spill = true
        end
        if item_count > 0 then
            local inventory = get_spoil_inventory(entity)
            local spoil_count = inventory.insert{name = item_name, count = item_count, quality = properties.quality}
            item_count = item_count - spoil_count
        end
    end
    if item_count > 0 then
        local surface = game.get_surface(properties.surface_index)
        if surface then
          surface.spill_item_stack{position = position, stack = {name = item_name, count = item_count, quality = properties.quality}, drop_full_stack = safe_spill, use_start_position_on_failure = not safe_spill}
        end
    end
end)

