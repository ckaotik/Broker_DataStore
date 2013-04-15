local addonName, ns, _ = ...
Broker_DataStore = ns

ns.modules = {}

local initialize -- forward declaration
local frame, eventHooks = CreateFrame("Frame"), {}
local function eventHandler(frame, event, arg1, ...)
	if event == 'ADDON_LOADED' and arg1 == addonName then
		-- make sure core initializes before anyone else
		initialize()
	end

	if eventHooks[event] then
		for id, listener in pairs(eventHooks[event]) do
			listener(frame, event, arg1, ...)
		end
	end
end
frame:SetScript("OnEvent", eventHandler)
ns.events = frame

function ns.RegisterEvent(event, callback, id, silentFail)
	assert(callback and event and id, format("Usage: RegisterEvent(event, callback, id[, silentFail])"))
	if not eventHooks[event] then
		eventHooks[event] = {}
		frame:RegisterEvent(event)
	end
	assert(silentFail or not eventHooks[event][id], format("Event %s already registered by id %s.", event, id))

	eventHooks[event][id] = callback
end
function ns.UnregisterEvent(event, id)
	if not eventHooks[event] or not eventHooks[event][id] then return end
	eventHooks[event][id] = nil
	if ns.Count(eventHooks[event]) < 1 then
		eventHooks[event] = nil
		frame:UnregisterEvent(event)
	end
end

-- Util ---------------------------------------------------
function ns.Count(dataTable)
	local count = 0
	if dataTable then
		for _ in pairs(dataTable) do
			count = count + 1
		end
	end
	return count
end

function ns.Print(text)
	DEFAULT_CHAT_FRAME:AddMessage("|cffee6622Broker_DataStore|r "..text)
end

-- /spew DataStore_Currencies.db.global.Reference
function ns.GetColoredCharacterName(characterKey)
	local _, _, characterName = strsplit('.', characterKey)
	return characterName
end
function ns.GetFaction()
	return UnitFactionGroup('player')
end
function ns.GetAverageItemLevel()
	return GetAverageItemLevel()
end

-- Events -------------------------------------------------
local thisCharacter = DataStore:GetCharacter()

-- local function initialize(frame, event, addon)
initialize = function()
	-- initialize saved variables
	if not BDS_GlobalDB then BDS_GlobalDB = {} end
	if not BDS_LocalDB then BDS_LocalDB = {} end

	-- supply some fallbacks
	if IsAddOnLoaded('DataStore_Characters') then
		ns.GetColoredCharacterName = function(characterKey)
			return (DataStore:GetColoredCharacterName(characterKey) or '') .. '|r'
		end
		ns.GetFaction = function(characterKey)
			return DataStore:GetCharacterFaction(characterKey)
		end

		--
	end
	if IsAddOnLoaded('DataStore_Inventory') then
		ns.GetAverageItemLevel = function(characterKey)
			if characterKey == thisCharacter then
				return GetAverageItemLevel()
			else
				return DataStore:GetAverageItemLevel(characterKey)
			end
		end
	end

	-- initialize addon variables
	ns.characters = {}
	for characterName, characterKey in pairs(DataStore:GetCharacters()) do
		table.insert(ns.characters, {
			name = characterName,
			key = characterKey,
			coloredName = ns.GetColoredCharacterName(characterKey),
			-- itemLevel = ns.GetAverageItemLevel(characterKey),
		})
	end
	table.sort(ns.characters, function(a,b) return a.name < b.name end)

	-- initialize modules
	local initFunc
	for _, tab in pairs(ns.modules or {}) do
		-- run module's init function
		initFunc = tab[2]
		if initFunc then
			initFunc()
		end
	end
end
frame:RegisterEvent('ADDON_LOADED')

--[[ local function UpdateItemLevel()
	for _, charData in ipairs(ns.characters) do
		if charData.key == thisCharacter then
			charData.itemLevel = ns.GetAverageItemLevel(thisCharacter)
			break
		end
	end
end
ns.RegisterEvent('PLAYER_AVG_ITEM_LEVEL_READY', UpdateItemLevel, 'updateilvl_initial')
ns.RegisterEvent('PLAYER_EQUIPMENT_CHANGED', 	UpdateItemLevel, 'updateilvl_equipped')
ns.RegisterEvent('BAG_UPDATE_DELAYED', 			UpdateItemLevel, 'updateilvl_bags')
--]]
