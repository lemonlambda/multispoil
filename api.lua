local multispoil = {}

local function spoil_trigger(item_names)
    return {
        trigger = {
            type = "direct",
            action_delivery = {
                type = "instant",
                target_effects = {
                    type = "script",
                    effect_id = "spoiled-item-" .. item_names,
                }
            },
        },
        items_per_trigger = 1
    }
end

--- Creates a trigger for `spoil_to_trigger_result`
--- 
--- If count > 1 then it will not create a single item stack if the game doesn't have item stack bonus
--- 
--- Example: `{["iron-plate"] = 1, ["copper-plate"] = 1, ["iron-ore"] = 1}`
--- Example 2: `{["iron-plate"], ["copper-plate"], ["iron-ore"]}`
--- Example 3: `"iron-plate"``
--- @param item_names table<string, integer>|table<string>|string
--- @return data.SpoilToTriggerResult
function multispoil.create_spoil_trigger(item_names)
    if type(item_names) ~= "table" and type(item_names) ~= "string" then
        error("Wrong type used for multispoil.create_spoil_trigger")
    end

    local item_names_string = ""

    if type(item_names) == "table" and item_names[0] ~= nil then
        for count,name in pairs(item_names) do
            local count = count or 1
            
            if item_names_string == "" then
                item_names_string = name .. "." .. count
            else
                item_names_string = item_names_string .. "," .. name .. "." .. count
            end
        end
    elseif type(item_names) == "table" and item_names[0] == nil then
        for name,count in pairs(item_names) do
            local count = count or 1
            
            if item_names_string == "" then
                item_names_string = name .. "." .. count
            else
                item_names_string = item_names_string .. "," .. name .. "." .. count
            end
        end
    else
        item_names_string = item_names .. "." .. 1
    end

    return spoil_trigger(item_names_string)
end

--- Creates a trigger for `spoil_to_trigger_result` with weighted
---
--- If count > 1 then it will not create a single item stack if the game doesn't have item stack bonus
--- 
--- Example: `{["iron-plate"] = {weight = 3, count = 1}, ["copper-plate"] = {weight = 2, count = 1}, ["iron-ore"] = {weight = 1, count = 1}}`
--- Example 2: `{["iron-plate"], ["copper-plate"], ["iron-ore"]}`
--- Example 3: `{["iron-plate"] = 3, ["copper-plate"] = 2, ["iron-ore"] = 1}`
--- @param item_names table<string, { weight: integer, count: integer }>|table<string>|table<string, integer>
--- @return Trigger
function multispoil.create_spoil_weighted_trigger(item_names)
    if type(item_names) ~= "table" then
        error("Wrong type used for multispoil.create_spoil_trigger")
    end

    local item_names_string = ""

    for name,properties in pairs(item_names) do
        local weight = properties["weight"] or properties[0] or 1
        local count = properties["count"] or 1

        if item_names_string == "" then
            item_names_string = name .. "|" .. weight .. "|" .. count
        else
            item_names_string = item_names_string .. "," .. name .. "|" .. weight .. "|" .. count
        end
    end

    return spoil_trigger(item_names_string)
end

return multispoil
