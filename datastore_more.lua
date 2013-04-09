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

local nextMaintenance
local function GetNextMaintenance()
	if not nextMaintenance then
		local region = GetCVar('portal')
		local maintenanceWeekDay = (region == 'us' and 3)
			or (region == 'eu' and 4)
			or (region == 'kr' and 5)
			or (region == 'tw' and 6)
			or 7
		local dailyReset = time() + GetQuestResetTime()
		local resetWeekday = tonumber(date('%w', dailyReset)) + 1
		nextMaintenance = dailyReset + ((maintenanceWeekDay - resetWeekday)%7)*24*60*60
		-- print('next weekly reset', date('%d.%m.%Y', nextMaintenance))
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

local function _GetCurrencyCapInfo(character, currencyID)
	local weeklyAmount = character.WeeklyCurrency[currencyID]
	local currentAmount = nil -- TODO get data from datastore_currencies
	local name, _, _, _, weeklyMax, totalMax = GetCurrencyInfo(currencyID)

	if totalMax%100 == 99 then -- valor and justice caps are weird
		totalMax  = math.floor(totalMax/100)
		weeklyMax = math.floor(weeklyMax/100)
	end

	return currentAmount, totalMax, weeklyAmount, weeklyMax
end

local function _GetCurrencyWeeklyAmount(character, currencyID)
	return character.WeeklyCurrency[currencyID]
end

-- setup
local PublicMethods = {
	GetCurrencyCaps = _GetCurrencyCaps,
	GetCurrencyCapInfo = _GetCurrencyCapInfo,
	GetLFRs = _GetLFRs,
	GetLFRInfo = _GetLFRInfo,
	GetCurrencyWeeklyAmount = _GetCurrencyWeeklyAmount,
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
	addon:RegisterEvent("PLAYER_LOGIN", UpdateWeeklyCap)
	addon:RegisterEvent("LFG_LOCK_INFO_RECEIVED", UpdateLFRProgress)
end

function addon:OnDisable()
	addon:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
	addon:UnregisterEvent("PLAYER_LOGIN", UpdateWeeklyCap)
	addon:UnregisterEvent("LFG_LOCK_INFO_RECEIVED")
end
