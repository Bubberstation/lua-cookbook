local SS13 = require("SS13")

SS13.wait(1)

local players = dm.global_vars.GLOB.alive_player_list
for i=1,#players do
    local victim = players[i]
    victim:say("*mggaow")
end