local SS13 = require("SS13")

SS13.wait(1)
local user = SS13.get_runner_client()

local teleCloset
local closet_target

local PLACE_FIRST = SS13.await(SS13.global_proc, "tgui_alert", user, "Confirm to select closet placement location", "TeleCloset Industries", { "No", "Yes" }) == "Yes"

function sendToTarget()
    for i=1,#teleCloset.contents do
        content = teleCloset.contents[i]
        content:forceMove(closet_target)
    end
end

-- Fugly doubleif but this is such a lazy small script, why not
if PLACE_FIRST then
    local closet_initial = dm.global_procs._get_step(user.mob, 0)
    local PLACE_SECOND = SS13.await(SS13.global_proc, "tgui_alert", user, "Confirm to select closet target destination", "TeleCloset Industries", { "No", "Yes" }) == "Yes"
    if PLACE_SECOND then
        closet_target = dm.global_procs._get_step(user.mob, 0)
        teleCloset = SS13.new("/obj/structure/closet", closet_initial)
        teleCloset.resistance_flags = 64

        SS13.register_signal(teleCloset, "closet_post_close", sendToTarget)
    end

end
