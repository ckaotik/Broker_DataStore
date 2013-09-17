local _, ns = ...

-- !!!!!!!!!!!!!!!!!!!!!!!!! --
if true then return end
-- !!!!!!!!!!!!!!!!!!!!!!!!! --

-- GLOBALS: LibStub, DataStore
-- GLOBALS: IsAddOnLoaded, UnitLevel, GetRFDungeonInfo, GetNumRFDungeons, GetLFGDungeonRewardCapInfo, GetLFGDungeonNumEncounters, GetCurrencyListSize, GetCurrencyListInfo, GetCVar, GetQuestResetTime, GetCurrencyInfo, GetCurrencyListLink
-- GLOBALS: wipe, pairs, time, date, string, tonumber, math

if not DataStore then return end

local addonName  = "DataStore_More"
   _G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

local addon = _G[addonName]
local thisCharacter = DataStore:GetCharacter()

-- these subtables need unique identifier
local AddonDB_Defaults = {
	global = {
		Characters = {
			['*'] = {				-- ["Account.Realm.Name"]
				lastUpdate = nil,
				LFGs = {},
				WeeklyCurrency = {},
			}
		}
	}
}

local lastMaintenance, nextMaintenance
local function GetLastMaintenance()
	if not lastMaintenance then
		local region = string.lower( GetCVar('portal') or '' )
		local maintenanceWeekDay = (region == 'us' and 2) -- tuesday
			or (region == 'eu' and 3) -- wednesday
			or (region == 'kr' and 4) -- ?
			or (region == 'tw' and 4) -- ?
			or (region == 'cn' and 4) -- ?
			or 2
		-- this gives us the time a reset happens, though GetQuestResetTime might not be available at launch
		local dailyReset = time() + GetQuestResetTime()
		if dailyReset == 0 then return end

		local dailyResetWeekday = tonumber(date('%w', dailyReset))
		lastMaintenance = dailyReset - ((dailyResetWeekday - maintenanceWeekDay)%7) * 24*60*60
		if lastMaintenance == dailyReset then lastMaintenance = lastMaintenance - 7*24*60*60 end
	end
	return lastMaintenance
end
local function GetNextMaintenance()
	if not nextMaintenance and lastMaintenance then
		nextMaintenance = lastMaintenance + 7*24*60*60
	end
	return nextMaintenance
end

-- *** Scanning functions ***
local LFGInfos = {
	-- GetNumX(), GetXInfo(index) returning same data as GetLFGDungeonInfo(dungeonID)
	GetNumRandomDungeons, GetLFGRandomDungeonInfo,
	GetNumRFDungeons, GetRFDungeonInfo,
	GetNumRandomScenarios, GetRandomScenarioInfo,
	-- GetNumFlexRaidDungeons, GetFlexRaidDungeonInfo
}
-- TYPEID_DUNGEON, TYPEID_RANDOM_DUNGEON
-- LFG_SUBTYPEID_DUNGEON, LFG_SUBTYPEID_HEROIC, LFG_SUBTYPEID_RAID, LFG_SUBTYPEID_SCENARIO

local function UpdateLFGStatus()
	local playerLevel = UnitLevel("player")

	local lfgs = addon.ThisCharacter.LFGs
	wipe(lfgs)
	for i = 1, #LFGInfos, 2 do
		local getNum, getInfo = LFGInfos[i], LFGInfos[i+1]
		for index = 1, getNum() do
			local dungeonID, _, _, _, minLevel, maxLevel, _, _, _, expansionLevel = getInfo(index)
			local _, _, completed, available, _, _, _, _, _, _, isWeekly = GetLFGDungeonRewardCapInfo(dungeonID)
			local _, numDefeated = GetLFGDungeonNumEncounters(dungeonID)
			local doneToday = GetLFGDungeonRewards(dungeonID)

			local status = completed
			if available ~= 1 or EXPANSION_LEVEL < expansionLevel or playerLevel < minLevel or playerLevel > maxLevel then
				-- not available
				local _, reason, info1, info2 = GetLFDLockInfo(dungeonID, 1)
				status = string.format("%s:%s:%s", reason or '', info1 or '', info2 or '')
			end

			local dungeonReset = 0
			if numDefeated > 0 or doneToday then
				dungeonReset = isWeekly and GetNextMaintenance() or (time() + GetQuestResetTime())
			end

			lfgs[dungeonID] = string.format("%s|%d|%d", status, dungeonReset, numDefeated)
		end
	end

	addon.ThisCharacter.lastUpdate = time()
end

local function UpdateWeeklyCap()
	if GetCurrencyListSize() < 1 then return end
	local currencies = addon.ThisCharacter.WeeklyCurrency
	wipe(currencies)

	for i = 1, GetCurrencyListSize() do
		local currencyLink = GetCurrencyListLink(i)
		if currencyLink then
			local currencyID = tonumber(string.match(currencyLink, "currency:(%d+)"))
			local _, currentAmount, _, weeklyAmount, weeklyMax, totalMax = GetCurrencyInfo(currencyID)
			if weeklyMax and weeklyMax > 0 then
				currencies[currencyID] = weeklyAmount
			end
		end
	end
	addon.ThisCharacter.lastUpdate = time()
end

-- Mixins
local function _GetLFGInfo(character, dungeonID)
	local instanceInfo = character.LFGs[dungeonID]
	if not instanceInfo then return end

	local status, reset, numDefeated = string.split("|", instanceInfo)
	status = tonumber(status) or status
	if type(status) == "string" then
		local playerName, lockedReason, subReason1, subReason2 = strsplit(":", status)
		status = string.format(_G["INSTANCE_UNAVAILABLE_SELF_"..(LFG_INSTANCE_INVALID_CODES[lockedReason] or "OTHER")], playerName, subReason1, subReason2)
	else
		status = status == 1 and true or false
	end

	return status, tonumber(reset), tonumber(numDefeated)
end

local function _GetLFGs(character)
	local lastKey = nil
	return function()
		local dungeonID, info = next(character.LFGs, lastKey)
		lastKey = dungeonID

		return dungeonID, _GetLFGInfo(character, dungeonID)
	end
end

local function _GetCurrencyCaps(character)
	return character.WeeklyCurrency
end

local function _GetCurrencyWeeklyAmount(character, currencyID)
	local lastMaintenance = GetLastMaintenance()
	if character == thisCharacter then
		-- always hand out live data as we might react to CURRENCY_DISPLAY_UPDATE later than our requestee
		UpdateWeeklyCap()
	end
	if lastMaintenance and character.lastUpdate and character.lastUpdate >= lastMaintenance then
		return character.WeeklyCurrency[currencyID]
	else
		return 0
	end
end

local function _GetCurrencyCapInfo(character, currencyID, characterKey)
	local weeklyAmount = _GetCurrencyWeeklyAmount(character, currencyID)
	local name, _, _, _, weeklyMax, totalMax = GetCurrencyInfo(currencyID)

	local currentAmount
	if IsAddOnLoaded('DataStore_Currencies') then
		_, _, currentAmount = DataStore:GetCurrencyInfoByName(characterKey, name)
	end

	if totalMax%100 == 99 then -- valor and justice caps are weird
		totalMax  = math.floor(totalMax/100)
		weeklyMax = math.floor(weeklyMax/100)
	end

	return currentAmount, totalMax, weeklyAmount, weeklyMax
end

local function _IsWeeklyQuestCompletedBy(character, questID, characterKey)
	if not IsAddOnLoaded('DataStore_Quests') then return end
	local _, lastUpdate = DataStore:GetQuestHistoryInfo(characterKey)
	local lastMaintenance = GetLastMaintenance()
	if not (lastUpdate and lastMaintenance) or lastUpdate < lastMaintenance then
		return false
	else
		return DataStore:IsQuestCompletedBy(characterKey, questID) or false
	end
end

--[[
local scanTooltip = CreateFrame("GameTooltip", "DataStoreScanTooltip", nil, "GameTooltipTemplate")
local glyphNameByID = setmetatable({}, {
	__index = function(self, id)
		scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
		scanTooltip:SetHyperlink("glyph:"..id)
		local name = _G[scanTooltip:GetName().."TextLeft1"]:GetText()
		scanTooltip:Hide()
		if name then
			self[id] = name
			return name
		end
	end
})
local function _IsGlyphKnown(character, itemID)
	-- returns true/nil: isKnown, canLearn
	local glyphName = GetItemInfo(itemID)
	for index, glyph in ipairs(character.GlyphList) do
		local id = RightShift(glyph, 4)

		if glyphNameByID[id] == glyphName then
			local isKnown = bAnd(RightShift(glyph, 3), 1)
			return (isKnown == 1) and true or nil, true
		end
	end
end
--]]

-- setup
local PublicMethods = {
	GetCurrencyCaps = _GetCurrencyCaps,
	GetCurrencyCapInfo = _GetCurrencyCapInfo,
	GetLFGs = _GetLFGs,
	GetLFGInfo = _GetLFGInfo,
	GetCurrencyWeeklyAmount = _GetCurrencyWeeklyAmount,
	IsWeeklyQuestCompletedBy = _IsWeeklyQuestCompletedBy,
}

function addon:OnInitialize()
	addon.db = LibStub("AceDB-3.0"):New(addonName .. "DB", AddonDB_Defaults)

	DataStore:RegisterModule(addonName, addon, PublicMethods)
	for funcName, funcImpl in pairs(PublicMethods) do
		DataStore:SetCharacterBasedMethod(funcName)
	end
end

function addon:OnEnable()
	addon:RegisterEvent("CURRENCY_DISPLAY_UPDATE", UpdateWeeklyCap)
	addon:RegisterEvent("LFG_LOCK_INFO_RECEIVED", UpdateLFGStatus)
	addon:RegisterEvent("QUEST_LOG_UPDATE", function()
		if GetNextMaintenance() then
			UpdateWeeklyCap()
			addon:UnregisterEvent("QUEST_LOG_UPDATE")
		end
	end)

	-- clear expired
	local now = time()
	for characterKey, character in pairs(addon.Characters) do
		for dungeonID, data in pairs(character.LFGs) do
			local status, reset, numDefeated = strsplit("|", data)
			reset = tonumber(reset)
			if reset ~= 0 and reset < now and tonumber(status) then
				-- had lockout, lockout expired, LFG is available
				character.LFGs[dungeonID] = string.format("%s|%d|%d", 0, 0, 0)
			end
		end
	end
end

function addon:OnDisable()
	addon:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
	addon:UnregisterEvent("LFG_LOCK_INFO_RECEIVED")
	addon:UnregisterEvent("QUEST_LOG_UPDATE")
end
