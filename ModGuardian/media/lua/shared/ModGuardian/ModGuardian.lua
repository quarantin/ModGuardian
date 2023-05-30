local ModGuardian = {}

local function ModGuardianShowPopup(config, textID)

	local width = 650
	local height = 400
	local popup = ModGuardianPopup:new(
		(getCore():getScreenWidth() - width) / 2,
		(getCore():getScreenHeight() - height) / 2,
		width, height,
		config, textID)
	popup:initialise()
	popup:addToUIManager()
	popup:setAlwaysOnTop(true)
	local joypadData = JoypadState.getMainMenuJoypad()
	if joypadData then
		joypadData.focus = popup
		updateJoypadFocus(joypadData)
	end
end

local function isModpack(config)

	local modInfo = getModInfoByID(config.modID)
	if modInfo and modInfo:getWorkshopID() ~= config.workshopID then
		return true
	end

	--[[
	local coroutine = getCurrentCoroutine()
	if coroutine then
		local count = getCallframeTop(coroutine)
		for i = count - 1, 0, -1 do
			local callFrame = getCoroutineCallframeStack(coroutine, i)
			if callFrame then
				local fileDir = getFilenameOfCallframe(callFrame)
				if fileDir then
					modInfo = getModInfo(fileDir:match("(.-)media/"))
					if modInfo and modInfo:getWorkshopID() ~= config.workshopID then
						return true
					end
				end
			end
		end
	end

	--]]
end

local function ModGuardianInit()

	print("DEBUG: ModGuardianInit")
	if not ModGuardian or not ModGuardian.config then
		print("ModGuardian: Configuration not set")
		return
	end

	for k, v in pairs(ModGuardian.config) do
		print('DEBUG: ' .. tostring(k) .. ' = ' .. tostring(v))
	end

	local textID = nil
	local config = ModGuardian.config

	if not config.disablePlayerBlacklist and config.playerBlacklist[getCurrentUserSteamID()] then
		textID = "UI_ModGuardian_Text_PlayerBlacklist"

	elseif not config.disableServerBlacklist and config.serverBlacklist[getServerIP()] then
		textID = "UI_ModGuardian_Text_ServerBlacklist"

	elseif not config.disableExclusiveServers and config.exclusiveServers[1] and not config.exclusiveServers[getServerIP()] then
		textID = "UI_ModGuardian_Text_ExclusiveServer"

	elseif not config.disableModpackCheck and isModpack(config) then
		textID = "UI_ModGuardian_Text_Modpack"
	end

	if textID then
		ModGuardianShowPopup(config, textID)
	end
end

Events.OnGameStart.Add(ModGuardianInit)

local function populateList(list)
	local newlist = {}
	for key, val in pairs(list) do
		newlist[val] = true
	end
	return newlist
end

local function ModGuardianConfig(config)

	config = config or {}
	config.playerBlacklist = config.playerBlacklist or {}
	config.serverBlacklist = config.serverBlacklist or {}
	config.exclusiveServers = config.exclusiveServers or {}

	if not config.modID then
		error("You must set your modID in ModGuardian configuration")
	end

	if not config.workshopID then
		error("You must set the workshopID of your mod in ModGuardian configuration")
	end

	config.playerBlacklist = populateList(config.playerBlacklist)
	config.serverBlacklist = populateList(config.serverBlacklist)
	config.exclusiveServers = populateList(config.exclusiveServers)

	ModGuardian.config = config

	print('DEBUG: ModGuardianConfig')
	for k, v in pairs(config) do
		print('DEBUG: ' .. tostring(k) .. ' = ' .. tostring(v))
	end
end

return ModGuardianConfig
