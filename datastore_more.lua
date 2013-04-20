local _, ns = ...

-- GLOBALS: LibStub, DataStore
-- GLOBALS: UnitLevel, GetRFDungeonInfo, GetNumRFDungeons, GetLFGDungeonRewardCapInfo, GetLFGDungeonNumEncounters, GetCurrencyListSize, GetCurrencyListInfo, GetCVar, GetQuestResetTime, GetCurrencyInfo, GetCurrencyListLink
-- GLOBALS: wipe, pairs, time, date, string, tonumber, math

if not DataStore then return end

local addonName  = "DataStore_More"
   _G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

local addon = _G[addonName]

-- these subtables need unique identifier
local AddonDB_Defaults = {
	global = {
		Characters = {
			['*'] = {				-- ["Account.Realm.Name"]
				lastUpdate = nil,
				LFRs = {},
				WeeklyCurrency = {},
			}
		}
	}
}

local lastMaintenance, nextMaintenance
local function GetLastMaintenance()
	if not lastMaintenance then
		local region = GetCVar('portal')
		local maintenanceWeekDay = (region == 'us' and 2) -- tuesday
								or (region == 'eu' and 3) -- wednesday
								or (region == 'kr' and 4) -- ?
								or (region == 'tw' and 4) -- ?
								or (region == 'cn' and 4) -- ?
								or 2
		-- this gives us the time a reset happens, GetQuestResetTime might not be available at launch
		local dailyReset = time() + GetQuestResetTime()
		if dailyReset == 0 then return end

		local dailyResetWeekday = tonumber(date('%w', dailyReset))
		lastMaintenance = dailyReset - ((dailyResetWeekday - maintenanceWeekDay)%7) * 24*60*60
		if lastMaintenance == dailyReset then lastMaintenance = lastMaintenance - 7*24*60*60 end
	end
	return lastMaintenance
end
local function GetNextMaintenance()
	if not nextMaintenance then
		nextMaintenance = GetLastMaintenance() + 7*24*60*60
	end
	return nextMaintenance
end

-- *** Scanning functions ***
local function UpdateLFRProgress()
	local lfrs = addon.ThisCharacter.LFRs
	wipe(lfrs)

	local playerLevel = UnitLevel("player")
	local dungeonID, minLevel, maxLevel, cleared, available, numDefeated, dungeonReset
	for i=1, GetNumRFDungeons() do
		dungeonID, _, _, _, minLevel, maxLevel = GetRFDungeonInfo(i)

		_, numDefeated = GetLFGDungeonNumEncounters(dungeonID)
		_, _, cleared, available = GetLFGDungeonRewardCapInfo(dungeonID)
		if playerLevel < minLevel or playerLevel > maxLevel then
			available = -1
		end

		dungeonReset = (numDefeated > 0) and GetNextMaintenance() - time() or 0
		lfrs[dungeonID] = string.format("%d|%d|%d|%d|%d", dungeonReset, time(), available, numDefeated, cleared)
	end
	-- addon.ThisCharacter.lastUpdate = time()
end

local function UpdateWeeklyCap(frame, event, ...)
	if GetCurrencyListSize() < 1 then return end
	local currencies = addon.ThisCharacter.WeeklyCurrency
	wipe(currencies)

	local currencyID, currencyLink, weeklyAmount, currentAmount, totalMax, weeklyMax
	for i = 1, GetCurrencyListSize() do
		currencyLink = GetCurrencyListLink(i)
		if currencyLink then
			currencyID = tonumber(string.match(currencyLink, "currency:(%d+)"))
			_, currentAmount, _, weeklyAmount, weeklyMax, totalMax = GetCurrencyInfo(currencyID)
			if weeklyMax and weeklyMax > 0 then
				currencies[currencyID] = weeklyAmount
			end
		end
	end
	addon.ThisCharacter.lastUpdate = time()
end

-- Mixins
local function _GetLFRs(character)
	return character.LFRs
end

local function _GetLFRInfo(character, dungeonID)
	local instanceInfo = character.LFRs[dungeonID]
	if not instanceInfo then return end

	local reset, lastCheck, available, numDefeated, cleared = string.split("|", instanceInfo)

	return tonumber(reset), tonumber(lastCheck), tonumber(available), tonumber(numDefeated), (cleared == "1") and true or nil
end

local function _GetCurrencyCaps(character)
	return character.WeeklyCurrency
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

local function _GetCurrencyWeeklyAmount(character, currencyID)
	local lastMaintenance = GetLastMaintenance()
	if lastMaintenance and character.lastUpdate and character.lastUpdate >= lastMaintenance then
		return character.WeeklyCurrency[currencyID]
	else
		return 0
	end
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

-- setup
local PublicMethods = {
	GetCurrencyCaps = _GetCurrencyCaps,
	GetCurrencyCapInfo = _GetCurrencyCapInfo,
	GetLFRs = _GetLFRs,
	GetLFRInfo = _GetLFRInfo,
	GetCurrencyWeeklyAmount = _GetCurrencyWeeklyAmount,
	IsWeeklyQuestCompletedBy = _IsWeeklyQuestCompletedBy,
}

function addon:OnInitialize()
	addon.db = LibStub("AceDB-3.0"):New(addonName .. "DB", AddonDB_Defaults)

	DataStore:RegisterModule(addonName, addon, PublicMethods)
	for funcName, funcImpl in pairs(PublicMethods) do
		DataStore:SetCharacterBasedMethod(funcName)
	end

	GetLastMaintenance()
	GetNextMaintenance()
end

function addon:OnEnable()
	addon:RegisterEvent("CURRENCY_DISPLAY_UPDATE", UpdateWeeklyCap)
	addon:RegisterEvent("PLAYER_LOGIN", UpdateWeeklyCap)
	addon:RegisterEvent("LFG_LOCK_INFO_RECEIVED", UpdateLFRProgress)
end

function addon:OnDisable()
	addon:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
	addon:UnregisterEvent("PLAYER_LOGIN", UpdateWeeklyCap)
	addon:UnregisterEvent("LFG_LOCK_INFO_RECEIVED")
end
