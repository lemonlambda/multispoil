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
--- Example: `{"iron-plate", "copper-plate", "iron-ore"}`
--- @param item_names string[]|string
--- @return Trigger
function multispoil.create_spoil_trigger(item_names)
    if type(item_names) ~= "table" and type(item_names) ~= "string" then
        error("Wrong type used for multispoil.create_spoil_trigger")
    end

    local item_names_string = ""

    if type(item_names) ~= "string" then
        for _,name in pairs(item_names) do
            if item_names_string == "" then
                item_names_string = name
            else
                item_names_string = item_names_string .. "," .. name
            end
        end
    else
        return spoil_trigger(item_names)
    end

    return spoil_trigger(item_names_string)
end

--- Creates a trigger for `spoil_to_trigger_result` with weighted
--- 
--- Example: `{["iron-plate"] = 3, ["copper-plate"] = 2, ["iron-ore"] = 1}`
--- @param item_names string[]
--- @return Trigger
function multispoil.create_spoil_weighted_trigger(item_names)
    if type(item_names) ~= "table" then
        error("Wrong type used for multispoil.create_spoil_trigger")
    end

    local item_names_string = ""

    for name,weight in pairs(item_names) do
        local weight = weight or 1

        if item_names_string == "" then
            item_names_string = name .. "|" .. weight
        else
            item_names_string = item_names_string .. "," .. name .. "|" .. weight
        end
    end

    return spoil_trigger(item_names_string)
end

return multispoil