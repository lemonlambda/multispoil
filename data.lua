if feature_flags["spoiling"] == false then
    error("This mod requires Space Age to work")
end

-- Test case
local multispoil = require("__multispoil__.api")

data.raw["item"]["iron-plate"].spoil_ticks = 5 * 60 -- 5 sec spoil time
data.raw["item"]["iron-plate"].spoil_to_trigger_result = multispoil.create_spoil_trigger({["iron-ore"] = 1, ["copper-ore"] = 5, ["copper-plate"] = 5}) -- spoils into iron ore or copper or or copper plates

data.raw["item"]["copper-plate"].spoil_ticks = 5 * 60 -- 5 sec spoil time
data.raw["item"]["copper-plate"].spoil_to_trigger_result = multispoil.create_spoil_weighted_trigger({["iron-plate"] = {weight = 3, count = 1}, ["copper-plate"] = {weight = 2, count = 1}, ["iron-ore"] = {weight = 1, count = 1}}) -- spoils into iron ore or copper or or copper plates
