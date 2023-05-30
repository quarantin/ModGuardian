local ModGuardian = {}

local function createLookupTable(list)
	local newlist = {}
	for key, val in pairs(list) do
		newlist[val] = true
	end
	return newlist
end

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

	-- TODO
	-- Fix this so that we can retrieve the workshop ID of the mod using
	-- ModGuardian, instead of retrieving the one of ModGuardian itself
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

local function ModGuardianCheck()

	if not ModGuardian or not ModGuardian.config then
		return
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

		local modInfo = getModInfoByID(config.modID)
		if modInfo and not config.modpackWhitelist[modInfo:getWorkshopID()] then
			textID = "UI_ModGuardian_Text_Modpack"
		end
	end

	if textID then
		ModGuardianShowPopup(config, textID)
	end
end

Events.OnGameStart.Add(ModGuardianCheck)

local function mergeConfig(oldConfig, newConfig)

	for key, val in pairs(newConfig) do

		if type(val) ~= 'table' then
			oldConfig[key] = val
		else
			if newConfig.reset then
				oldConfig[key] = {}
			end

			for k, v in pairs(val) do
				table.insert(oldConfig[key], v)
			end
		end
	end

	return oldConfig
end

local function downloadConfig(config)

	if not config or not config.url then
		return
	end

	local output = ''
	local dataInputStream = getUrlInputStream(config.url)
	local line = dataInputStream:readLine()
	while line do
		output = output .. line
		line = dataInputStream:readLine()
	end
	dataInputStream:close()
	local newConfig = loadstring(output)()
	print(newConfig)
	return mergeConfig(config, newConfig)

end

local configKeys = {
	"playerBlacklist",
	"serverBlacklist",
	"exclusiveServers",
	"modpackWhitelist",
}

local function ModGuardianConfig(config)

	config = config or {}

	for _, key in pairs(configKeys) do
		config[key] = config[key] or {}

	downloadConfig(config)

	if not config.modID then
		error("You must set your modID in ModGuardian configuration")
	end

	if not config.workshopID then
		error("You must set the workshopID of your mod in ModGuardian configuration")
	end

	for _, key in pairs(configKeys) do
		config[key] = createLookupTable(config[key])

	ModGuardian.config = config

	print('DEBUG: ModGuardianConfig')
	for k, v in pairs(config) do
		print('DEBUG: ' .. tostring(k) .. ' = ' .. tostring(v))
	end
end

return ModGuardianConfig
