local SS13 = require("SS13")

SS13.wait(1)
local user = SS13.get_runner_client()

function getGravGen()
    local SSmachines = dm.global_vars.SSmachines
    local gravgen_list = SSmachines:get_machines_by_type_and_subtypes(dm.global_procs._text2path("/obj/machinery/gravity_generator/main"))
    local gravgen = nil
    for i=1,#gravgen_list do
        gravgen = gravgen_list[i]
        if dm.global_procs.is_station_level(gravgen) then 
            break 
        end
    end
    return gravgen
end

function deleteGravGen()
    local generator = getGravGen()
    dm.global_procs.qdel(generator)
end

function getVictim()
    local players = dm.global_vars.GLOB.alive_player_list

    -- Select our victim
    local victim = SS13.await(SS13.global_procs, "tgui_input_list", user, "Select The Person To Become The Generator", "Fatty Selector", players)
    return victim
end

function gravityToggle(state)
    local SSmapping = dm.global_vars.SSmapping
    local station_levels = SSmapping:levels_by_trait("Station")
    local z_number = nil
    -- Turning on
    for i=1,#station_levels do
        z_number = station_levels[i]
        SSmapping.gravity_by_z_level[z_number] = state
    end

    
    local all_mobs = dm.global_vars.GLOB.mob_list
    local mob_to_update
    for j=1,#all_mobs do
        mob_to_update = all_mobs[j]
        if(SS13.istype(mob_to_update, "/mob/living")) then
            mob_to_update:refresh_gravity()
            if(mob_to_update.client) then
                dm.global_procs.shake_camera(mob_to_update, 32, 0.5)
            end
        end
    end
end

function turnVictimIntoGravgen()
    local client = getVictim()
    if(client == nil) then
        dm.global_procs.to_chat(user, "<span class='notice'> Unable to get player </span>")
        return
    end

    SS13.wait(1)
    deleteGravGen()
    SS13.wait(1)
    gravityToggle(client.stat == 0)

    SS13.register_signal(client, "mob_statchange", function(_, new_stat)
        gravityToggle(new_stat == 0)
    end)

    -- Announcement here
    local announcement_text = "Due to an unexpected anomaly, the gravity generator onboard seems to have disappeared. The replacement generator will be " .. client.name .. " until further notice."
    dm.global_procs.priority_announce(announcement_text, "Nanotrasen Gravity Anomalies Division")
end


turnVictimIntoGravgen()