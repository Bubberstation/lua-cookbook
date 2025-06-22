local SS13 = require("SS13")
-- Change this to your ckey so that this works. Don't run it with my ckey please :)
local admin = "arturlang"
-- Admins that can also take administrative action, though they can't freely upload videos that bypass the time limit.
local trustedAdmins = {
	arturlang = true,
}
-- play this https://www.youtube.com/watch?v=dQw4w9WgXcQ ;)
-- The auth token. You'll need to update this every time you run the script because the python script generates a new one each time it runs for security purposes.
authToken = "pqteDnSkPJtOKIFRNUGGC" -- warning, run webserver.py on the same dir as your console is at
-- Whether users can submit requests or not.
local acceptingRequests = true
-- Whether it's one request per user until their video is played
local onePerUser = false
-- The size of the TV. Current available options are 1, 2, 4, 8, 16
local scale = 8
-- Channel to play on. Don't modify if you don't know what you're doing
local channel = 1023
-- Whether to auto accept requests or not
local autoAccept = true
-- Number of people required to vote skip
local voteSkipRequired = 5
-- Whether the 'admin' should be able to bypass video length limit
local bypassVidLength = true
-- Whether the TV range is infinite or not. Keep it off if you don't want people nowhere near the TV to lag when videos load.
-- Useful if you plan on curating or limiting the videos that will be played so that no matter
local infiniteRange = false
-- Set to a value if you'd like to force the FPS of the video. Useful if the video itself is not important
local forcedFps = nil
local voteSkipData = {
	voteSkip = 0,
	voteSkipVoters = {}
}
local AUDIO_DIRECTIONAL = "Directional"
local AUDIO_MONO = "Mono"

blockPlayerRequest = {}
local me = SS13.get_runner_client()
local spawnLocation = me.mob.loc
-- hehe
trustedAdmins["artur_lang"] = true
local function wget(url, body, headers, outfile)
	dm.global_procs.to_chat(me, "<span class='linkify'>Fetching: <a href='"..url.."'>"..url.."</a></span>")
	local request = SS13.new("/datum/http_request")
	request:prepare("get", url, body or "", headers, outfile)
	request:begin_async()
	while request:is_complete() == 0 do
		sleep()
	end
	local response = request:into_response()
	if response.errored == 1 then
		error("HTTP request for "..url.." failed to parse the returned json object")
	end
	local status = response.status_code
	if status ~= 200 then
		error("HTTP request for "..tostring(url).." returned response code "..tostring(status))
	end
	local body = response.body
	return body
end
if not json then
	json = assert(loadstring(wget("https://raw.githubusercontent.com/rxi/json.lua/refs/heads/master/json.lua")))()
end
local function fetchVideo(url, ckey)
	return
end
channelCache = {}
channels = {}
local currentChannel = nil
local behindSign = SS13.new("/obj")
behindSign.icon_state = "standby"
behindSign.vis_flags = 16
behindSign.name = "TV Sign"
do
	local request = SS13.new("/datum/http_request")
	local file_name = "tmp/custom_map_icon.dmi"
	local url = "http://raw.githubusercontent.com/tgstation/auxlua-cookbook/main/waltermeldron/assets/tv/inprogress.dmi"
	request:prepare("get", url, "", "", file_name)
	request:begin_async()
	while request:is_complete() == 0 do
		sleep()
	end
	behindSign.icon = SS13.new("/icon", file_name)
end

local tv = SS13.new("/obj/structure/showcase/machinery/tv", spawnLocation)
list.add(tv.vis_contents, behindSign)

local sign = SS13.new("/obj", nil, tv)
sign.layer = behindSign.layer + 1
sign.icon_state = "off"
sign.name = "Video Sign"
list.add(tv.vis_contents, sign)

local scales = {
	[1] = {
		pixel_x = 8,
		pixel_y = 10,
		behind_pixel_x = 3,
		behind_pixel_y = 5,
		behindSignScale = 0.5,
		volume = 1,
		sampling = "nearest",
		fps = 30,
		maxVidLength = 240,
	},
	[2] = {
		pixel_x = 0,
		pixel_y = 4,
		behind_pixel_x = 0,
		behind_pixel_y = 4,
		behindSignScale = 1,
		volume = 1,
		sampling = "nearest",
		fps = 30,
		maxVidLength = 60,
	},
	[4] = {
		pixel_x = -16,
		pixel_y = -8,
		behind_pixel_x = -5,
		behind_pixel_y = 2,
		behindSignScale = 2,
		volume = 1,
		extraWaitTime = 3,
		sampling = "bicubic",
		realScaleX = 3,
		realScaleY = 3,
		realPosX = -1,
		realPosY = -1,
		fps = 30,
		maxVidLength = 60,
	},
	[8] = {
		pixel_x = -48,
		pixel_y = -32,
		behind_pixel_x = -15,
		behind_pixel_y = -2,
		behindSignScale = 4,
		volume = 1,
		extraWaitTime = 5,
		sampling = "bicubic",
		realScaleX = 5,
		realScaleY = 6,
		realPosX = -2,
		realPosY = -2,
		fps = 20,
		maxVidLength = 60,
	},
	[16] = {
		pixel_x = -112,
		pixel_y = -80,
		behind_pixel_x = -35,
		behind_pixel_y = -10,
		behindSignScale = 8,
		volume = 1,
		extraWaitTime = 5,
		sampling = "bicubic",
		realScaleX = 11,
		realScaleY = 11,
		realPosX = -5,
		realPosY = -4,
		fps = 10,
		maxVidLength = 30,
	},
}
local scaleConfig = scales[scale]
sign.pixel_x = scaleConfig.pixel_x
sign.pixel_y = scaleConfig.pixel_y
behindSign.pixel_x = scaleConfig.behind_pixel_x
behindSign.pixel_y = scaleConfig.behind_pixel_y
behindSign.transform = dm.global_procs._matrix(scaleConfig.behindSignScale, 0, 0, 0, scaleConfig.behindSignScale, 0)
tv.transform = dm.global_procs._matrix(scale, 0, 0, 0, scale, 0)
tv:set_light_power(100)
tv:set_light_range(math.floor(scale / 2))
tv:set_light_on(true)
tv:update_light()
if scaleConfig.realScaleX then
	tv.bound_width = 32 * scaleConfig.realScaleX
	tv.bound_height = 32 * scaleConfig.realScaleY
	tv.bound_x = 32 * scaleConfig.realPosX
	tv.bound_y = 32 * scaleConfig.realPosY
end
sign.appearance_flags = 520
behindSign.mouse_opacity = 0
behindSign.appearance_flags = 520
globalPlayerSettings = globalPlayerSettings or nil

local function getPlayerSettings(ckey)
	globalPlayerSettings = globalPlayerSettings or {}
	local playerSettings = globalPlayerSettings[ckey]
	if not playerSettings then
		playerSettings = {
			disableTv = false,
			audioMode = AUDIO_DIRECTIONAL,
			volume = 100
		}
		globalPlayerSettings[ckey] = playerSettings
	end
	return playerSettings
end

local function escape(str)
	str = string.gsub(str, "([^0-9a-zA-Z !'()*._~-])", -- locale independent
		function (c) return string.format ("%%%02X", string.byte(c)) end)
	str = string.gsub(str, " ", "+")
	return str
end

local playClip = function() end

local startTimeOfDay = dm.world.timeofday

local playingChannel
local animationEnd = 0
local listeners = {}
local function startTvLoop(players)
	local playerClientImageMap = {}
	while animationEnd > dm.world.timeofday and dm.is_valid_ref(tv) and tv.gc_destroyed == nil do
		if dm.world.timeofday < startTimeOfDay then
			startTimeOfDay = dm.world.timeofday
			animationEnd = 0
			break
		end
		if playingChannel == nil then break end
		if not dm.is_valid_ref(tv) or tv.gc_destroyed ~= nil then break end
		local location = tv.loc
		for _, playerData in players do
			local playerClient = playerData.client
			local playerConfig = playerData.data
			if animationEnd <= dm.world.timeofday then
				break
			end
			if playingChannel == nil then
				break
			end
			if not dm.is_valid_ref(playerClient) then
				continue
			end
			local player = playerClient.mob
			if playerClientImageMap[playerClient] == nil then
				playerClientImageMap[playerClient] = player
			end
			local playerPos = player:drop_location()
			local dist = dm.global_procs._get_dist(playerPos, location)
			local volume = playerConfig.volume * scaleConfig.volume
			local playLocation = location
			if playerConfig.audioMode == AUDIO_MONO then
				playLocation = playerPos
			end
			if not SS13.istype(location, "/turf") or dist > 12 or location.z ~= playerPos.z then
				playLocation = nil
				volume = 0
			end
			if playerClientImageMap[playerClient] ~= player then
				list.add(playerClient.images, sign)
				playerClientImageMap[playerClient] = currentPlayerMob
			end
			player:playsound_local(playLocation, playingChannel.sound_file, volume, false, nil, 6, channel, true, playingChannel.sound_file, 17, 1, 1, true)
		end
		sleep()
	end
	playingChannel = nil
	for _, playerClient in dm.global_vars.GLOB.clients do
		if not playerClient or not playerClient.images then
			continue
		end
		local player = playerClient.mob
		player:stop_sound_channel(channel)
		list.remove(playerClient.images, sign)
	end
	animationEnd = 0
	sleep()
	sign.icon_state = "off"
	if #channels > 0 then
		sleep()
		table.remove(channels, 1)
		if #channels > 0 then
			behindSign.icon_state = "loading"
			currentChannel = channels[1].channel
			blockPlayerRequest[channels[1].submitter] = nil
			sign.icon = currentChannel.icon_file
			currentChannel.sound_file.status = 0
			local tvZLoc = tv:drop_location().z
			for _, player in dm.global_vars.GLOB.player_list do
				if (_exec.time / _exec.limit) > 0.7 then
					sleep()
				end
				local dist = dm.global_procs._get_dist(player, tv)
				if (dist > 12 and not infiniteRange) then
					continue
				end
				local playerLocation = player:drop_location()
				local playerClient = player.client
				if not dm.is_valid_ref(player) or not playerClient or not playerLocation or not dm.is_valid_ref(playerLocation) then
					continue
				end
				local playerSettings = getPlayerSettings(player.ckey)
				if playerSettings.disableTv then
					continue
				end
				if (player:drop_location().z == tvZLoc or infiniteRange) then
					player:playsound_local(nil, currentChannel.sound_file, 0, false, nil, 6, channel, true, currentChannel.sound_file, 17, 1, 1, true)
					local client = player.client
					list.add(client.images, sign)
				end
			end
			SS13.set_timeout(3 + (scaleConfig.extraWaitTime or 0), function()
				playClip()
			end)
		else
			if #queuedRequests > 0 then
				behindSign.icon_state = "loading"
			else
				behindSign.icon_state = "standby"
			end
		end
	end
end

playClip = function()
	if not currentChannel then
		return
	end
	sign.icon_state = "on"
	SS13.set_timeout(0, function()
		if animationEnd > dm.world.timeofday then
			return
		end
		playingChannel = currentChannel
		voteSkipData = {
			voteSkip = 0,
			voteSkipVoters = {}
		}
		queuedUrls[playingChannel.url] = false
		animationEnd = dm.world.timeofday + playingChannel.duration
		playingChannel.sound_file.status = 0
		local playerList = {}
		local tvZLoc = tv:drop_location().z
		behindSign.icon_state = "playing"
		for _, player in dm.global_vars.GLOB.player_list do
			if (_exec.time / _exec.limit) > 0.7 then
				sleep()
			end
			local dist = dm.global_procs._get_dist(player, tv)
			if (dist > 12 and not infiniteRange) then
				continue
			end
			if (player:drop_location().z == tvZLoc or infiniteRange) then
				local playerSettings = getPlayerSettings(player.ckey)
				if playerSettings.disableTv then continue end
				player:playsound_local(nil, playingChannel.sound_file, 0, false, nil, 6, channel, true, playingChannel.sound_file, 17, 1, 1, true)
				local client = player.client
				list.add(client.images, sign)
				table.insert(playerList, { client = client, data = playerSettings })
			end
		end
		dm.global_procs._flick("on", sign)
		playingChannel.sound_file.status = 16
		startTvLoop(playerList)
	end)
end

local createHref = function(args, content, brackets)
	brackets = brackets == nil and true or false
	local data = "<a href='?src="..dm.global_procs.REF(tv)..";"..args.."'>"..content.."</a>"
	if brackets then return "("..data..")" else return data end
end

queuedRequests = {}
queuedUrls = {}

local saveData = function() end
local saveRequired = false

if authToken ~= "" then
	local address = me.address or "localhost"
	saveData = function()
		local request = SS13.new("/datum/http_request")
		request:prepare("get", "http://"..address..":30020/set-settings-data", json.encode(globalPlayerSettings), { Authorization = authToken })
		request:begin_async()
		while request:is_complete() == 0 do
			sleep()
		end
		local response = request:into_response()
		if response.errored == 1 then
			print("Failed to save settings. Please check API server")
		end
	end
	if not globalPlayerSettings then
		local request = SS13.new("/datum/http_request")
		request:prepare("get", "http://"..address..":30020/get-settings-data", "", { Authorization = authToken })
		request:begin_async()
		while request:is_complete() == 0 do
			sleep()
		end
		local response = request:into_response()
		if response == nil or response.errored == 1 then
			print("Failed to fetch settings. Please check API server")
		else
			local jsonData = response.body
			if jsonData and jsonData ~= "" then
				globalPlayerSettings = json.decode(jsonData)
			else
				globalPlayerSettings = {}
			end
		end
	end
	local function saveDataLoop()
		if not SS13.is_valid(tv) then
			return
		end
		if saveRequired then
			saveData()
			saveRequired = false
		end
		SS13.set_timeout(30, saveDataLoop)
	end
	saveDataLoop()

	queryInProgress = false
	fetchVideo = function()
		if #queuedRequests == 0 then
			return
		end
		local requestData = queuedRequests[1]
		local url = requestData.url
		local ckey = requestData.ckey
		local startPos = requestData.startPos
		local duration = requestData.duration
		if url == nil then
			table.remove(queuedRequests, 1)
			return
		end
		queuedUrls[url] = true
		if queryInProgress then
			return
		end
		if channelCache[url] then
			table.remove(queuedRequests, 1)
			local channel = channelCache[url]
			table.insert(channels, { channel = channel, submitter = ckey, startPos = startPos })
			if #channels == 1 then
				currentChannel = channels[1].channel
				blockPlayerRequest[channels[1].submitter] = nil
				sign.icon = currentChannel.icon_file
				playClip()
			end
			return
		end
		if behindSign.icon_state == "standby" then
			behindSign.icon_state = "loading"
		end
		local frames = forcedFps or scaleConfig.fps or 30
		local channel = {}
		channel.url = url
		queryInProgress = true
		local vidLength = scaleConfig.maxVidLength
		if ckey == admin and bypassVidLength then
			-- Load in however long you want it to be, but this is just here so that you don't crash people's clients with 1 hr long videos
			vidLength = 1200
		end
		if startPos < 0 then
			startPos = 0
		end
		if not duration or duration <= 0 then
			duration = vidLength
		end
		duration = math.min(duration, vidLength)
		local performFetch = SS13.new("/datum/http_request")
		performFetch:prepare("get", "http://"..address..":30020/perform-fetch?youtube-url="..escape(url).."&size="..scale.."&sampling="..scaleConfig.sampling.."&frames="..frames.."&max-video-length="..vidLength.."&start-time="..startPos.."&duration="..duration, "", { Authorization = authToken })
		performFetch:begin_async()
		while performFetch:is_complete() == 0 do
			sleep()
		end
		PERFORM_FETCH_RESULT = performFetch:into_response()

		local fetchCompleted = false
		local errored = false
		local errors = ""
		local responseData = ""
		while fetchCompleted == false do
			local checkFetch = SS13.new("/datum/http_request")
			checkFetch:prepare("get", "http://"..address..":30020/check-fetch", "", { Authorization = authToken })
			checkFetch:begin_async()
			while checkFetch:is_complete() == 0 do
				sleep()
			end
			local response = checkFetch:into_response()
			if response.errored == 1 then
				fetchCompleted = true
				errored = true
				errors = response.error
				break
			end
			responseData = response.body
			if responseData ~= "Not ready" then
				fetchCompleted = true
				break
			end
			SS13.wait(3)
		end

		if responseData ~= "1" then
			local playerClient = dm.global_vars.GLOB.directory[ckey]
			if behindSign.icon_state == "loading" and #channels == 0 then
				behindSign.icon_state = "standby"
			end
			table.remove(queuedRequests, 1)
			if playerClient == nil then
				return
			end
			local player = playerClient.mob
			player:playsound_local(nil, "sound/effects/adminhelp.ogg", 75)
			dm.global_procs.to_chat(player, "<font color='red'><b>Your video request was rejected.</b> This is because an error occured with the request. Please input appropriate video details to avoid this from happening again.</font>")
			dm.global_procs.message_admins("TV: "..dm.global_procs.key_name_admin(player).." has been warned about their request due to bad input data.")
			queryInProgress = false
			queuedUrls[url] = false
			blockPlayerRequest[ckey] = nil
			return
		end

		if errored then
			dm.global_procs.message_admins("TV: Unable to fetch video for TV due to API errors!")
			queryInProgress = false
			table.remove(queuedRequests, 1)
			return
		end

		local request = SS13.new("/datum/http_request")
		local file_name = "tmp/custom_map_icon.dmi"
		request:prepare("get", "http://"..address..":30020/get-dmi?size="..scale, "", { Authorization = authToken }, file_name)
		request:begin_async()
		while request:is_complete() == 0 do
			sleep()
		end
		local response = request:into_response()
		channel.icon_file = SS13.await(SS13.global_proc, "_new", "/icon", { file_name })
		channel.title = response.headers["video-title"]
		sleep()
		local request = SS13.new("/datum/http_request")
		local file_name = "tmp/custom_map_sound.ogg"
		request:prepare("get", "http://"..address..":30020/get-audio", "", { Authorization = authToken }, file_name)
		request:begin_async()
		while request:is_complete() == 0 do
			sleep()
		end
		local response = request:into_response()
		if response.errored == 1 or tonumber(response.headers["audio-length"]) == nil then
			queryInProgress = false
			if behindSign.icon_state == "loading" and #channels == 0 then
				behindSign.icon_state = "standby"
			end
			queuedUrls[url] = false
			table.remove(queuedRequests, 1)
			return
		end
		channel.sound_file = SS13.new("/sound", file_name)
		channel.duration = tonumber(response.headers["audio-length"]) * 10
		table.insert(channels, { channel = channel, submitter = ckey, startPos = startPos })
		table.remove(queuedRequests, 1)
		channelCache[url] = channel
		request = nil
		queryInProgress = false
		dm.global_procs.message_admins("TV: Loaded youtube video "..dm.global_procs.sanitize(channel.title).." - "..dm.global_procs.sanitize(url).." for use in the TV. "..createHref("skip="..escape(url), "SKIP"))
		sleep()
		if not dm.is_valid_ref(tv) then
			return
		end
		if #channels == 1 then
			currentChannel = channels[1].channel
			blockPlayerRequest[channels[1].submitter] = nil
			sign.icon = currentChannel.icon_file
			currentChannel.sound_file.status = 0
			local tvZLoc = tv:drop_location().z
			sleep()
			for _, player in dm.global_vars.GLOB.player_list do
				if (_exec.time / _exec.limit) > 0.7 then
					sleep()
				end
				local dist = dm.global_procs._get_dist(player, tv)
				if dist > 12 and not infiniteRange then
					continue
				end
				if (player:drop_location().z == tvZLoc or infiniteRange) then
					local playerSettings = getPlayerSettings(player.ckey)
					if playerSettings.disableTv then continue end
					player:playsound_local(nil, currentChannel.sound_file, 0, false, nil, 6, channel, true, currentChannel.sound_file, 17, 1, 1, true)
					local client = player.client
					list.add(client.images, sign)
				end
			end
			SS13.set_timeout(3 + (scaleConfig.extraWaitTime or 0), function()
				playClip()
			end)
		end
		SS13.set_timeout(0, function()
			fetchVideo()
		end)
	end
end

SS13.register_signal(tv, "parent_qdeleting", function()
	dm.global_procs.qdel(behindSign)
	for _, player in dm.global_vars.GLOB.player_list do
		player:stop_sound_channel(channel)
	end
	saveData()
end)

local playerOpen = {}
local blocked = {}
local requestCounter = 0
local canMakeRequest = function(user, isAdmin)
	if onePerUser and not isAdmin then
		if blockPlayerRequest[user.ckey] then
			user:balloon_alert(user, "only 1 request at a time!")
			return false
		end
	end
	return true
end

local makeRequest = function(user, isAdmin)
	local ckey = user.ckey
	if blocked[ckey] then
		user:balloon_alert(user, "blocked from making requests!")
		return
	end
	if not acceptingRequests and not isAdmin then
		return
	end
	if not canMakeRequest(user, isAdmin) then
		return
	end
	SS13.set_timeout(0, function()
		if not ckey then
			return
		end
		local vidLength = scaleConfig.maxVidLength
		if isAdmin and bypassVidLength then
			-- Load in however long you want it to be, but this is just here so that you don't crash people's clients with 1 hr long videos
			vidLength = 1200
		end
		playerOpen[ckey] = true
		local input = SS13.await(
			SS13.global_proc,
			"tgui_input_text",
			user,
			"Input Youtube URL. Optionally include timestamp to start at a specific video location. Videos longer than "..vidLength.." seconds will be cut down in length.",
			"Request Youtube Video"
		)
		playerOpen[ckey] = false
		if not canMakeRequest(user, isAdmin) then
			user:balloon_alert(user, "unable to make a request!")
			return
		end
		if input == nil or input == "" then
			user:balloon_alert(user, "invalid input!")
			return
		end
		if queuedUrls[input] then
			user:balloon_alert(user, "That request is already queued!")
			return
		end
		local duration = -1
		local startTime = tonumber(string.match(input, "t=(%d+)"))
		if startTime then
			playerOpen[ckey] = true
			duration = SS13.await(SS13.global_proc, "tgui_input_number", user, "Detected starting location, please specify video length to showcase in seconds", "Specify video length", vidLength, vidLength, 1)
			playerOpen[ckey] = false
		else
			startTime = -1
		end
		-- This does not make it safe, but there are further protections in the API script anyways
		local scrubbed = dm.global_procs.shell_url_scrub(input)
		if not isAdmin then
			blockPlayerRequest[ckey] = true
			if autoAccept then
				dm.global_procs.message_admins("TV: "..dm.global_procs.key_name_admin(user).." queued the youtube video <span class='linkify'>"..scrubbed.."</span> to be played on the TV. "..createHref("skip="..escape(scrubbed)..";", "SKIP").." "..createHref("block=1;ckey="..ckey, "BLOCK"))
				table.insert(queuedRequests, { url = scrubbed, ckey = ckey, startPos = startTime, duration = duration })
				fetchVideo()
				user:playsound_local(nil, "sound/misc/asay_ping.ogg", 15)
				dm.global_procs.to_chat(user, "<font color='blue'><b>Your video request was queued.</b></font>")
			else
				dm.global_procs.message_admins("TV: "..dm.global_procs.key_name_admin(user).." requested the youtube video <span class='linkify'>"..scrubbed.."</span> to be played on the TV. "..createHref("link="..escape(scrubbed)..";ckey="..ckey..";startTime="..startTime..";duration="..duration..";play_id="..requestCounter, "PLAY").." "..createHref("reject=1;reject_id="..requestCounter..";ckey="..ckey, "REJECT").." "..createHref("block=1;ckey="..ckey, "BLOCK"))
			end
			requestCounter = requestCounter + 1
		else
			table.insert(queuedRequests, { url = scrubbed, ckey = ckey, startPos = startTime, duration = duration })
			fetchVideo()
		end
	end)
end

local function openClientSettings(user)
	local userCkey = user.ckey
	local browser = SS13.new("/datum/browser", user, "Client TV Settings", "Client TV Settings", 300, 200)
	local data = ""
	local playerSettings = getPlayerSettings(userCkey)
	local tvDisableToggle = createHref("client_disable=1", "YES", false)
	if playerSettings.disableTv then
		tvDisableToggle = createHref("client_disable=0", "NO", false)
	end
	data = data.."<h1>TV Settings</h1></hr>"
	data = data.."<div style='display: flex; margin-top: 4px;'><div style='flex-grow: 1; color: #98B0C3;'>TV enabled for self:</div><div>"..tvDisableToggle.."</div></div>"
	data = data.."<div style='display: flex; margin-top: 4px;'><div style='flex-grow: 1; color: #98B0C3;'>Change TV audio mode:</div><div>"..createHref("client_audio_mode=1", tostring(playerSettings.audioMode), false).."</div></div>"
	data = data.."<div style='display: flex; margin-top: 4px;'><div style='flex-grow: 1; color: #98B0C3;'>Change TV volume:</div><div>"..createHref("client_audio_volume=1", tostring(playerSettings.volume), false).."</div></div>"
	browser:set_content(data)
	browser:open()
end

getLink = getLink or dm.global_procs._regex("(v=|v/|vi=|vi/|youtu.be/)([a-zA-Z0-9_-]+)")
local function openAdminSettings(user)
	local browser = SS13.new("/datum/browser", user, "Admin TV Settings", "Admin TV Settings", 500, 600)
	local data = ""
	local tvRequestsToggle = createHref("ui=1;disable_requests=1", "YES", false)
	if not acceptingRequests then
		tvRequestsToggle = createHref("ui=1;disable_requests=0", "NO", false)
	end
	local onePerUserToggle = createHref("ui=1;disable_one_per_user=1", "YES", false)
	if not onePerUser then
		onePerUserToggle = createHref("ui=1;disable_one_per_user=0", "NO", false)
	end
	data = data.."<div style='font-size: 14px'><h1>TV Settings</h1></hr></div>"
	data = data..createHref("adminsettings=1", "REFRESH", false)
	data = data.."<div style='display: flex; margin-top: 4px;'><div style='flex-grow: 1; color: #98B0C3;'>Requests allowed:</div><div>"..tvRequestsToggle.."</div></div>"
	data = data.."<div style='display: flex; margin-top: 4px;'><div style='flex-grow: 1; color: #98B0C3;'>Restrict to one request per user:</div><div>"..onePerUserToggle.."</div></div>"
	data = data.."<div style='display: flex; margin-top: 4px;'><div style='flex-grow: 1; color: #98B0C3;'>Required votes to voteskip:</div><div>"..createHref("ui=1;admin_set_voteskip=1", tostring(voteSkipRequired), false).."</div></div>"
	data = data.."<h2>Queued Channels</h2>"
	for position, nextChannel in channels do
		local sanitizedLink = dm.global_procs.sanitize(nextChannel.channel.url)
		getLink:Find(nextChannel.channel.url)
		local catchGroup = getLink.group
		local ytLink = ""
		if #catchGroup <= 2 then
			ytLink = "https://www.youtube.com/watch?v="..catchGroup[2].."&t="..tostring(nextChannel.startPos ~= -1 and nextChannel.startPos or 0)
		else
			ytLink = "INVALID YOUTUBE LINK!"
		end
		data = data.."<div style='display: flex; margin-top: 4px;'><div style='flex-grow: 1'>Position #"..tostring(position)..": "..sanitizedLink.." - "..tostring(nextChannel.channel.title).."</div><div>"..createHref("ui=1;skip="..escape(nextChannel.channel.url), "SKIP", false).."</div></div>"
		local blockedInfo = createHref("ui=1;block=1;ckey="..nextChannel.submitter, "BLOCK", false)
		if blocked[ckey] then
			blockedInfo = "<span style='color: #ffcccb'>Blocked from making requests</span>"
		end
		data = data.."<div style='display: flex; margin-top: 4px; margin-bottom: 4px;'><div style='flex-grow: 1'>Submitted by "..nextChannel.submitter.."</div><div>"..blockedInfo.."</div></div>"
		if ytLink ~= "INVALID YOUTUBE LINK!" then
			data = data.."<a href='"..ytLink.."'>Open Youtube Link</a>"
		end
	end
	local positionOffset = #channels
	data = data.."<h2>Processing Requests</h2>"
	for position, request in queuedRequests do
		local sanitizedLink = dm.global_procs.sanitize(request.url)
		getLink:Find(request.url)
		local catchGroup = getLink.group
		local ytLink = ""
		if #catchGroup <= 2 then
			ytLink = "https://www.youtube.com/watch?v="..catchGroup[2].."&t="..tostring(request.startPos ~= -1 and request.startPos or 0)
		else
			ytLink = "INVALID YOUTUBE LINK!"
		end
		data = data.."<div style='display: flex; margin-top: 4px;'><div style='flex-grow: 1'>Position #"..tostring(positionOffset + position)..": "..sanitizedLink.."</div><div>"..createHref("ui=1;skip="..escape(request.url), "SKIP", false).."</div></div>"
		local blockedInfo = createHref("ui=1;block=1;ckey="..request.ckey, "BLOCK", false)
		if blocked[ckey] then
			blockedInfo = "<span style='color: #ffcccb'>Blocked from making requests</span>"
		end
		data = data.."<div style='display: flex; margin-top: 4px; margin-bottom: 4px;'><div style='flex-grow: 1'>Submitted by "..request.ckey.."</div><div>"..blockedInfo.."</div></div>"
		if ytLink ~= "INVALID YOUTUBE LINK!" then
			data = data.."<a href='"..ytLink.."'>Open Youtube Link</a>"
		end
	end
	browser:set_content(data)
	browser:open()
end
SS13.register_signal(tv, "atom_attack_hand", function(_, user)
	makeRequest(user)
end)

local adminOpen = {}
local handledRequests = {}
SS13.register_signal(tv, "handle_topic", function(_, user, href_list)
	local userCkey = user.ckey
	if adminOpen[userCkey] then
		return
	end
	SS13.set_timeout(0, function()
		if href_list["voteskip"] then
			if not playingChannel then
				return
			end
			if voteSkipData.voteSkipVoters[userCkey] then
				user:balloon_alert(user, "already voted to skip")
				return
			end
			voteSkipData.voteSkip += 1
			voteSkipData.voteSkipVoters[userCkey] = true
			if voteSkipData.voteSkip >= voteSkipRequired then
				tv:say("Voteskipped current channel.")
				dm.global_procs.message_admins("TV: Skipped "..dm.global_procs.sanitize(playingChannel.title or ""))
				playingChannel = nil
			end
			user:balloon_alert(user, "voted to skip current channel")
		elseif href_list["settings"] then
			openClientSettings(user)
		elseif href_list["client_disable"] then
			local playerSettings = getPlayerSettings(userCkey)
			if href_list["client_disable"] == "1" then
				playerSettings.disableTv = true
			else
				playerSettings.disableTv = false
			end
			saveRequired = true
			openClientSettings(user)
		elseif href_list["client_audio_mode"] then
			adminOpen[userCkey] = true
			local input = SS13.await(SS13.global_proc, "tgui_alert", user, "Set audio mode for how you will hear the TV", "Set audio mode", { AUDIO_DIRECTIONAL, AUDIO_MONO })
			adminOpen[userCkey] = false
			if input == nil then
				return
			end
			local playerSettings = getPlayerSettings(userCkey)
			playerSettings.audioMode = input
			saveRequired = true
			openClientSettings(user)
		elseif href_list["client_audio_volume"] then
			local playerSettings = getPlayerSettings(userCkey)
			adminOpen[userCkey] = true
			local newVolume = SS13.await(SS13.global_proc, "tgui_input_number", user, "Please input new audio volume", "TV audio volume", playerSettings.volume, 100, 1)
			adminOpen[userCkey] = false
			if newVolume == nil then
				return
			end
			playerSettings.volume = newVolume
			saveRequired = true
			openClientSettings(user)
		end
		if userCkey == admin or trustedAdmins[userCkey] then
			if href_list["link"] ~= nil then
				local youtubeLink = href_list["link"]
				local playerCkey = href_list["ckey"]
				local startTime = tonumber(href_list["startTime"]) or 0
				local duration = tonumber(href_list["duration"]) or 1200
				local playId = href_list["play_id"]
				if handledRequests[playId] then
					return
				end
				local startTextDuration = ""
				if startTime ~= -1 and duration ~= -1 then
					startTextDuration = " | Start at "..startTime.."s | Duration: "..duration.."s"
				end
				adminOpen[userCkey] = true
				local input = SS13.await(SS13.global_proc, "tgui_alert", user, "Do you really want to play "..youtubeLink..startTextDuration, "Play Youtube link", { "Yes", "No" })
				adminOpen[userCkey] = false
				if input ~= "Yes" then
					return
				end
				handledRequests[playId] = true
				dm.global_procs.message_admins("TV: "..dm.global_procs.key_name_admin(user).." played "..youtubeLink)
				table.insert(queuedRequests, { url = youtubeLink, ckey = playerCkey, startPos = startTime, duration = duration })
				fetchVideo()
				local playerClient = dm.global_vars.GLOB.directory[playerCkey]
				if playerClient then
					local player = playerClient.mob
					player:playsound_local(nil, "sound/misc/asay_ping.ogg", 15)
					dm.global_procs.to_chat(player, "<font color='blue'><b>Your video request was queued.</b></font>")
				end
			elseif href_list["reject"] ~= nil then
				local rejectId = href_list["reject_id"]
				if handledRequests[rejectId] then
					return
				end
				local ckey = href_list["ckey"]
				local playerClient = dm.global_vars.GLOB.directory[ckey]
				if playerClient == nil then
					return
				end
				adminOpen[userCkey] = true
				local input = SS13.await(SS13.global_proc, "tgui_input_text", user, "Input reason as to why you want to reject this request.", "Reject Reason")
				adminOpen[userCkey] = false
				local player = playerClient.mob
				player:playsound_local(nil, "sound/effects/adminhelp.ogg", 75)
				dm.global_procs.to_chat(player, "<font color='red'><b>Your video request was rejected.</b> This is for the following reason: "..input.."</font>")
				dm.global_procs.message_admins("TV: "..dm.global_procs.key_name_admin(player).." has been warned about their request by "..dm.global_procs.key_name_admin(user)..".")
				handledRequests[rejectId] = true
			elseif href_list["block"] ~= nil then
				if blocked[ckey] then
					return
				end
				local ckey = href_list["ckey"]
				blocked[ckey] = true
				player:playsound_local(nil, "sound/effects/adminhelp.ogg", 75)
				dm.global_procs.to_chat(player, "<font color='red'><b>You have been blocked from making any further video requests.</b></font>")
				dm.global_procs.message_admins("TV: "..ckey.." has been blocked from making any more requests by "..dm.global_procs.key_name_admin(user)..".")
			elseif href_list["skip"] ~= nil then
				local toSkip = href_list["skip"]
				local foundOne = false
				local i = 2
				local playersToNotify = {}
				while i <= #channels do
					if channels[i].channel.url == toSkip then
						foundOne = true
						blockPlayerRequest[channels[i].submitter] = nil
						table.remove(channels, i)
					else
						i += 1
					end
				end
				i = 1
				while i <= #queuedRequests do
					if queuedRequests[i].url == toSkip then
						blockPlayerRequest[queuedRequests[i].ckey] = nil
						foundOne = true
						table.remove(queuedRequests, i)
					else
						i += 1
					end
				end
				if playingChannel and playingChannel.url == toSkip then
					playingChannel = nil
					foundOne = true
				end
				queuedUrls[toSkip] = false
				if foundOne then
					dm.global_procs.message_admins("TV "..dm.global_procs.key_name_admin(user).." skipped "..dm.global_procs.sanitize(toSkip))
				end
			elseif href_list["adminsettings"] then
				openAdminSettings(user)
			elseif href_list["disable_requests"] then
				if href_list["disable_requests"] == "1" then
					acceptingRequests = false
				else
					acceptingRequests = true
				end
			elseif href_list["disable_one_per_user"] then
				if href_list["disable_one_per_user"] == "1" then
					onePerUser = false
				else
					onePerUser = true
				end
			elseif href_list["admin_set_voteskip"] then
				adminOpen[userCkey] = true
				local newVoteSkipAmount = SS13.await(SS13.global_proc, "tgui_input_number", user, "Please input new vote skip boundary", "TV vote skip boundary", voteSkipRequired, 100, 1)
				adminOpen[userCkey] = false
				if newVoteSkipAmount == nil then
					return
				end
				voteSkipRequired = newVoteSkipAmount
			end
			if href_list["ui"] then
				openAdminSettings(user)
			end
		end
	end)
end)
SS13.register_signal(tv, "atom_examine", function(_, examiner, examine_list)
	local ckey = examiner.ckey
	local settingsData = createHref("settings=1", "OPEN CLIENT TV SETTINGS")
	if trustedAdmins[ckey] then
		settingsData = settingsData.." "..createHref("adminsettings=1", "OPEN ADMIN TV SETTINGS")
	end
	list.add(examine_list, "<span class='notice'>"..settingsData.."</span>")
	if acceptingRequests then
		list.add(examine_list, "<span class='notice'>Use ctrl + click to request a video.</span>")
	else
		list.add(examine_list, "<span class='danger'>This television is not accepting requests right now.</span>")
	end

	if playingChannel ~= nil then
		list.add(examine_list, "<span class='notice'>Currently playing "..(dm.global_procs.sanitize(playingChannel.title) or "").."<br/><span class='linkify'>"..(dm.global_procs.sanitize(playingChannel.url) or "").."</span></span>")
		list.add(examine_list, "<span class='danger'>There are currently "..tostring(voteSkipData.voteSkip or 0).."/"..tostring(voteSkipRequired).." votes to skip "..createHref("voteskip=1", "VOTE SKIP").."</span>")
	end

end)
SS13.register_signal(tv, "ctrl_shift_click", function(_, clicker)
	local clickerCkey = clicker.ckey
	if clickerCkey == admin or trustedAdmins[clickerCkey] then
		if playingChannel then
			dm.global_procs.message_admins("TV: Skipped "..dm.global_procs.sanitize(playingChannel.url))
			playingChannel = nil
		else
			if clickerCkey == admin then
				playClip()
			end
		end
	end
end)
SS13.register_signal(tv, "ctrl_click", function(_, clicker)
	if trustedAdmins[clicker.ckey] then
		makeRequest(clicker, true)
	else
		makeRequest(clicker)
	end
end)
function doNothing() return 1 end
SS13.register_signal(tv, "tool_act_screwdriver", doNothing)
SS13.register_signal(tv, "tool_secondary_act_screwdriver", doNothing)
SS13.register_signal(tv, "tool_act_crowbar", doNothing)
SS13.register_signal(tv, "tool_secondary_act_crowbar", doNothing)
SS13.register_signal(tv, "tool_act_wrench", doNothing)
SS13.register_signal(tv, "tool_secondary_act_crowbar", doNothing)
