local SS13 = require("SS13")

SS13.wait(1)
local user = SS13.get_runner_client()

function getArea()
    local areas = dm.global_vars.GLOB.areas

    local area_to_remove = SS13.await(SS13.global_procs, "tgui_input_list", user, "Select the area to empty", "Area Deleter", areas)
    return area_to_remove
end

function canDelete(to_check)
    -- This is ugly, but I dont know dreamluau enough
    -- Basically, we avoid deleting walls, plating, piping/wiring, and windows/grilles, and airlocks
    if(SS13.istype(to_check, "/mob")) then
        return false
    elseif(SS13.istype(to_check, "/turf/open/floor/plating") or SS13.istype(to_check, "/turf/closed")) then
        return false
    elseif(SS13.istype(to_check, "/obj/machinery/airalarm") or SS13.istype(to_check, "/obj/machinery/power/apc") or SS13.istype(to_check, "/obj/machinery/power/terminal")) then
        return false
    elseif(SS13.istype(to_check, "/obj/machinery/atmospherics") or SS13.istype(to_check, "/obj/structure/cable")) then
        return false
    elseif(SS13.istype(to_check, "/obj/structure/grille") or SS13.istype(to_check, "/obj/structure/window")) then
        return false
    elseif(SS13.istype(to_check, "/obj/machinery/door") or SS13.istype(to_check, "/obj/effect")) then
        return false
    else
        return true
    end

end

function tryDelete(deleted)
    if(SS13.istype(deleted, "/turf/open")) then
        deleted:ChangeTurf("/turf/open/floor/plating")
        return
    end
    dm.global_procs.qdel(deleted)
end

function deleteOneArea()
    local area = getArea()
    if(area == nil) then
        dm.global_procs.to_chat(user, "<span class='notice'> Unable to get player </span>")
        return
    end
    local contents = area.contents

    -- Actual things to delete
    local contents_to_delete = {}
    for i=1,#contents do
        content = contents[i]
        if(canDelete(content)) then
            contents_to_delete[#contents_to_delete + 1] = content
        end
    end

    local lag_counter = 0 -- To prevent killing the server we only delete 64 items a tick
    for i=1,#contents_to_delete do
        to_delete = contents_to_delete[i]
        dm.global_procs.to_chat(user, "<span class='notice'>" .. to_delete.name .. "</span>")
        tryDelete(to_delete)

        lag_counter = lag_counter + 1
        if(lag_counter >= 64) then
            lag_counter = 0
            SS13.wait(1)
        end
    end
    return
end


deleteOneArea()