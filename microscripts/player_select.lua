local client
local players = dm.global_vars.GLOB.alive_player_list

if(players == nil) then
    notifyPlayer(user, "No living players found")
    return
end
-- Select our victim
local client = SS13.await(SS13.global_proc, "tgui_input_list", user, "Select The Person To Become The Generator", "Fatty Selector", players)

if(client == nil) then
    notifyPlayer(user, "No player selected!")
    return
end