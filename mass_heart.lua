-- WARNING - THIS SPAMS ADMIN CHAT

local SS13 = require("SS13")

SS13.wait(1)

local user = SS13.get_runner_client()

local players = dm.global_vars.GLOB.mob_list
for i = 1, #players do
    local victim = players[i]
    if victim.client then
        victim:receive_heart(user, 24 * 36000, true)
    end
end