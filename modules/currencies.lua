local addonName, ns, _ = ...
local QTip = LibStub("LibQTip-1.0")

-- GLOBALS: _G, DataStore, BDS_GlobalDB, RAID_FINDER, BOSS, CALENDAR_REPEAT_WEEKLY, CURRENCY, GREEN_FONT_COLOR_CODE, GRAY_FONT_COLOR_CODE, RED_FONT_COLOR_CODE, FONT_COLOR_CODE_CLOSE, ITEM_REFUND_MSG, BATTLE_PET_SOURCE_7
-- GLOBALS: IsAddOnLoaded, IsAltKeyDown, GetItemInfo, GetCurrencyInfo, IsQuestFlaggedCompleted, GetLFGDungeonNumEncounters, GetLFGDungeonRewardCapInfo, InterfaceOptionsFrame_OpenToCategory, ToggleCharacter
-- GLOBALS: tonumber, type, select, wipe, unpack, ipairs, table, string, math, date, time, bit

-- --------------------------------------------------------
-- character progress
-- --------------------------------------------------------
local fontDummy = ns.events:CreateFontString()
local thisCharacter = DataStore:GetCharacter()

local worldBosses 	= { 32099, 32098, 32518, 32519 }
local LFRDungeons 	= { {527, 528}, {529, 530}, {526}, {610, 611, 612, 613} }
local weeklyQuests 	= { 32610, 32626, 32609, 32505, '32640|32641', '32719|32718', '32872|32862' }
local currencies 	= { 396, 395, 738, 697, 752 } -- valor, justice, lesser/elder/mogu charm
--[[
CONQUEST_CURRENCY = 390;
HONOR_CURRENCY = 392;
JUSTICE_CURRENCY = 395;
VALOR_CURRENCY = 396;
SHOW_CONQUEST_LEVEL = 70;
--]]

local function tex(item, text)
	local icon = select(10, GetItemInfo(item))
	return icon and '|T'..icon..':0|t' or text or '?'
end
local function currencyHeader(currency)
	local name, _, icon, _, weeklyMax = GetCurrencyInfo(currency)
	return icon and '|T'..icon..':0|t' or name, weeklyMax > 0 and '|TInterface\\FriendsFrame\\StatusIcon-Away:0|t' or nil
end
local returnTable = {}
local function getColumnHeaders(dataType)
	if dataType == 'lfr' then
		return RAID_FINDER,
			'MV', 'HoF', 'ToES', 'ToT'
	elseif dataType == 'boss' then
		return BATTLE_PET_SOURCE_7, --BOSS,
			tex(89317, 'Sha'), tex(89783, 'Galleon'), tex(85513, 'Nalak'), tex(95424, 'Oondasta')
	elseif dataType == 'weekly' then
		return CALENDAR_REPEAT_WEEKLY,
			tex(94221, 'Stone'), tex(94222, 'Key'), tex(87391, 'Chest'), tex(93792, 'Chamberlain'), tex(90538, 'Champions'), tex(90815, 'Charms'), tex(97849, 'Barrens')
	elseif dataType == 'currency' then
		local val1, val2
		wipe(returnTable)
		for _, currency in ipairs(currencies) do
			val1, val2 = currencyHeader(currency)
			table.insert(returnTable, val1)
			if val2 then
				table.insert(returnTable, val2)
			end
		end
		return CURRENCY, unpack(returnTable)
	end
	return ''
end
local function colorize(value, goodValue, badValue, padding)
	local returnString = value or ''
	if goodValue and badValue and goodValue == badValue then
		returnString = GRAY_FONT_COLOR_CODE .. value .. FONT_COLOR_CODE_CLOSE
	elseif goodValue and value == goodValue then
		returnString = GREEN_FONT_COLOR_CODE .. value .. FONT_COLOR_CODE_CLOSE
	elseif badValue and value == badValue then
		returnString = RED_FONT_COLOR_CODE .. value .. FONT_COLOR_CODE_CLOSE
	elseif type(value) == "number" and type(goodValue) == "number" and type(badValue) == "number"
		and goodValue ~= badValue then
		-- color continuously
		local percentage = (value - badValue) / (goodValue - badValue)
		local r, g, b = 255, percentage*510, 0
		if percentage > 0.5 then
			r, g, b = 510 - percentage*510, 255, 0
		end
		returnString = string.format("|cff%02x%02x%02x%s|r", r, g, b, value)
	end

	if padding ~= nil and (type(padding) == 'boolean' or type(padding) == 'number') then
		-- true/-int = front, false/+int = back
		if type(padding) == 'boolean' then
			-- calculate padding
			local returnWidth, maxWidth
			fontDummy:SetText(returnString)
			returnWidth = fontDummy:GetStringWidth()

			fontDummy:SetText(goodValue or '')
			maxWidth = math.max(returnWidth, fontDummy:GetStringWidth())
			fontDummy:SetText(badValue or '')
			maxWidth = math.max(maxWidth, fontDummy:GetStringWidth())
			padding = ((padding == true) and -1 or 1) * (maxWidth - returnWidth)
			padding = math.floor(padding + 0.5)
		end

		if padding < 0 then
			returnString = string.format(    '|T:1:%1$s|t%2$s', -1*padding, returnString)
		elseif padding > 0 then
			returnString = string.format('%2$s|T:1:%1$s|t'    ,    padding, returnString)
		end
	end

	return returnString
end
local function prepare(dataTable)
	for index, value in ipairs(dataTable) do
		if not value then
			dataTable[index] = '–'
		elseif value == true then
			dataTable[index] = '|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0|t'
		else
			-- no changes
		end
	end
	return unpack(dataTable)
end

-- -----------------------------------------
local function GetCharacterQuestState(character, questID)
	if character == thisCharacter then
		return IsQuestFlaggedCompleted(questID) and true or false
	elseif IsAddOnLoaded('DataStore_Quests') then
		return DataStore:IsWeeklyQuestCompletedBy(character, questID, character) or false
	else
		-- no info
		return false
	end
end
local function GetCharacterLockoutState(character, dungeonID)
	local numEncounters, numDefeated = GetLFGDungeonNumEncounters(dungeonID)

	if character == thisCharacter then
		local _, _, cleared, available = GetLFGDungeonRewardCapInfo(dungeonID)

		numEncounters = cleared == 1 and numDefeated or (available * numEncounters)
		return numDefeated, numEncounters
	else
		local resetIn, lastCheck, available, numDefeated, cleared = DataStore:GetLFRInfo(character, dungeonID)

		available = available and available == 1 and 1 or 0
		numEncounters = cleared and numDefeated or (available * numEncounters)
		if resetIn and resetIn - (time() - lastCheck) < 0 then
			-- we're saved for this dungeon and it's expired
			numDefeated = 0
		end
		return numDefeated or 0, numEncounters
	end

	return 0, 0
end
local function GetCharacterCurrencyInfo(character, currency)
	local name, currentAmount, _, weeklyAmount, weeklyMax, totalMax = GetCurrencyInfo(currency)
	if character ~= thisCharacter then
		currentAmount = 0
		weeklyAmount = DataStore:GetCurrencyWeeklyAmount(character, currency)
		if IsAddOnLoaded('DataStore_Currencies') then
			_, _, currentAmount = DataStore:GetCurrencyInfoByName(character, name)
		end
	end
	currentAmount = currentAmount or 0
	weeklyAmount  = weeklyAmount or 0

	if totalMax%100 == 99 then -- valor and justice caps are weird
		totalMax  = math.floor(totalMax/100)
		weeklyMax = math.floor(weeklyMax/100)
	end

	return currentAmount, totalMax, weeklyAmount, weeklyMax
end

-- Gather data --------------------------------------------------
local lockoutReturns = { lfr = {}, worldboss = {}, weekly = {} }
local function GetCharacterLFRLockouts(character, hideEmpty)
	wipe(lockoutReturns.lfr)
	local showLine = (character == thisCharacter)
	local numDefeated, numEncounters, categoryData
	for index, LFRCategory in ipairs(LFRDungeons) do
		categoryData = ''
		for _, dungeonID in ipairs(LFRCategory) do
			numDefeated, numEncounters = GetCharacterLockoutState(character, dungeonID)
			categoryData = (categoryData ~= '' and categoryData..' ' or '') .. colorize(numDefeated, 0, numEncounters)
			-- show line if any bosses are down or we may visit this LFR wing
			showLine = showLine or numDefeated > 0 or numEncounters > 0 or nil
		end
		lockoutReturns.lfr[index] = categoryData
	end
	return (showLine or not hideEmpty) and lockoutReturns.lfr or nil
end
local function GetCharacterBossLockouts(character, hideEmpty)
	wipe(lockoutReturns.worldboss)
	local showLine, questState = character == thisCharacter, nil
	for index, questID in ipairs(worldBosses) do
		questState = GetCharacterQuestState(character, questID)
		lockoutReturns.worldboss[index] = questState
		showLine = showLine or questState or nil
	end
	return (showLine or not hideEmpty) and lockoutReturns.worldboss or nil
end
local function GetCharacterWeeklyLockouts(character, hideEmpty)
	wipe(lockoutReturns.weekly)
	local showLine = character == thisCharacter
	local questState, alliance, horde
	for index, questID in ipairs(weeklyQuests) do
		if type(questID) == 'string' then
			alliance, horde = string.split('|', questID)
			questID = ns.GetFaction(character) == 'Alliance' and tonumber(alliance) or tonumber(horde)
		end
		questState = GetCharacterQuestState(character, questID)
		lockoutReturns.weekly[index] = questState
		showLine = showLine or questState or nil
	end
	return (showLine or not hideEmpty) and lockoutReturns.weekly or nil
end

local currencyReturns = {}
local function GetCharacterCurrencies(character, hideEmpty)
	wipe(currencyReturns)
	local showLine = (character == thisCharacter)
	local currentAmount, totalMax, weeklyAmount, weeklyMax

	for index, currency in ipairs(currencies) do
		currentAmount, totalMax, weeklyAmount, weeklyMax = GetCharacterCurrencyInfo(character, currency)
		table.insert(currencyReturns, colorize(currentAmount, 0, totalMax, true))

		if weeklyMax and weeklyMax > 0 and weeklyAmount then
			-- add current weekly cap info
			table.insert(currencyReturns, colorize(weeklyAmount, 0, weeklyMax, true))
			-- currencyReturns[#currencyReturns] = currencyReturns[#currencyReturns] ..': '
			--	.. colorize(weeklyAmount, 0, weeklyMax, true)
		end
		-- show non-valor characters only on ALT
		showLine = showLine or ((IsAltKeyDown() or index == 1) and currentAmount > 0) or nil
	end
	return (showLine or not hideEmpty) and currencyReturns or nil
end

-- Output ------------------------------------------------------
local function ShowTooltip(self)
	-- name column + data columns
	local numColumns = 1 + math.max(0, #worldBosses, #weeklyQuests, #LFRDungeons, select('#', getColumnHeaders('currency')))
	local tooltip = QTip:Acquire("DataStore_Grinder", numColumns, "LEFT")
		  tooltip:Clear()

	fontDummy:SetFontObject(tooltip:GetFont())
	local data, lineNum

	tooltip:AddHeader(getColumnHeaders('lfr'))
	-- tooltip:SetCellScript(headLine, col, "OnEnter", ShowToonTooltip, {toon})
	-- tooltip:SetCellScript(headLine, col, "OnLeave", function() GameTooltip:Hide() end)
	for _, charData in ipairs(ns.characters) do
		data = GetCharacterLFRLockouts(charData.key, true)
		if data then
			tooltip:AddLine(charData.coloredName, prepare(data))
		end
	end

	tooltip:AddLine(' ')
	tooltip:AddHeader(getColumnHeaders('boss'))
	for _, charData in ipairs(ns.characters) do
		data = GetCharacterBossLockouts(charData.key, true)
		if data then
			tooltip:AddLine(charData.coloredName, prepare(data))
		end
	end

	tooltip:AddLine(' ')
	tooltip:AddHeader(getColumnHeaders('weekly'))
	for _, charData in ipairs(ns.characters) do
		data = GetCharacterWeeklyLockouts(charData.key, true)
		if data then
			tooltip:AddLine(charData.coloredName, prepare(data))
		end
	end

	tooltip:AddLine(' ')
	tooltip:AddHeader(getColumnHeaders('currency'))
	for _, charData in ipairs(ns.characters) do
		data = GetCharacterCurrencies(charData.key, true)
		if data then
			tooltip:AddLine(charData.coloredName, unpack(data))
		end
	end

	-- Use smart anchoring code to anchor the tooltip to our frame
	tooltip:SmartAnchorTo(self)
	tooltip:SetAutoHideDelay(0.25, self)
	tooltip:Show()
end

local progressLDB = LibStub:GetLibrary('LibDataBroker-1.1'):NewDataObject('DataStore_CharProgress', {
	type	= 'data source',
	label	= string.format('%s: %s', addonName, 'Progress'),
	text 	= 'Character Progress',

	OnEnter = ShowTooltip,
	OnClick = function() end,
	OnLeave = function() end,	-- needed for e.g. NinjaPanel
})

local displayCurrency, displayAmount = 396, nil
ns.RegisterEvent('CURRENCY_DISPLAY_UPDATE', function()
	if GetCurrencyListSize() < 1 then return end
	local displayData
	local currencyName, _, currencyIcon = GetCurrencyInfo(displayCurrency)
	if displayAmount and IsAddOnLoaded('DataStore_Currencies') then
		_, _, displayData = DataStore:GetCurrencyInfoByName(thisCharacter, currencyName)
	else
		displayData = DataStore:GetCurrencyWeeklyAmount(thisCharacter, displayCurrency)
	end

	if displayData and displayData > 0 then
		progressLDB.text = '|T'..currencyIcon..':0|t' .. displayData
	else
		progressLDB.text = 'Character Progress'
	end
end, 'currencyweekly')

-- --------------------------------------------------------

--[[local function UpdateWeeklyQuests(frame, event)
	if IsAddOnLoaded('DataStore_Quests') then
		-- local history = _G['DataStore_Quests'].db.global.Characters[thisCharacter].History
		local history = _G['DataStore_Quests'].ThisCharacter.History
		local alliance, horde

		for _, questID in ipairs(worldBosses) do
			history[ math.ceil(questID / 32) ] = bit.bor(IsQuestFlaggedCompleted(questID) and 1 or 0, 2^(questID % 32))
		end
		for _, questID in ipairs(weeklyQuests) do
			if type(questID) == 'string' then
				alliance, horde = string.split('|', questID)
				questID = ns.GetFaction(thisCharacter) == 'Alliance' and tonumber(alliance) or tonumber(horde)
			end
			history[ math.ceil(questID / 32) ] = bit.bor(IsQuestFlaggedCompleted(questID) and 1 or 0, 2^(questID % 32))
		end
		_G['DataStore_Quests'].ThisCharacter.lastUpdate = time()
	end
end
ns.RegisterEvent('CRITERIA_UPDATE', UpdateWeeklyQuests, 'updatequestsongoing') --]]
ns.RegisterEvent('PLAYER_LOGOUT', DataStore.QueryQuestHistory, 'updatequests')
-- ns.RegisterEvent('PLAYER_LOGIN', DataStore.QueryQuestHistory, 'updatequesthistory')
-- ZONE_CHANGED, PLAYER_REGEN_ENABLED, QUEST_FINISHED
--]]

--[[ ns.RegisterEvent('ADDON_LOADED', function(frame, event, arg1)
	if arg1 == addonName then
		-- init
		ns.UnregisterEvent('ADDON_LOADED', 'charprogress')
	end
end, 'charprogress') --]]

-- --------------------------------------------------------
-- simple currency ldb
-- --------------------------------------------------------
ns.currencies = {}
local plugin = ns.currencies
local currencyLDB

local function GetCurrencyString(character)
	character = character or thisCharacter

	local text = ''
	local isHeader, name, count, icon
	-- if character == thisCharacter then
	--	print('LDBUpdate', DataStore:GetNumCurrencies(character), DataStore:GetCurrencyInfo(character, 2))
	-- end
	for i = 1, DataStore:GetNumCurrencies(character) do
		isHeader, name, count, icon = DataStore:GetCurrencyInfo(character, i)

		if not isHeader and count and count > 0
			and BDS_GlobalDB.currencies[character] and BDS_GlobalDB.currencies[character][name] then
			text = string.format('%s|T%s:0|t%d', (text == '' and '' or text..' '), icon or '', count or 0)
		end
	end
	return text
end

local function GetDisplayString()
	local currencyString = GetCurrencyString()
	if currencyString == '' then
		currencyString = "|TInterface\\Minimap\\Tracking\\None:0|t " .. ns.locale.currencies
	end
	return currencyString
end

local function LDBUpdate(...)
	currencyLDB.text = GetDisplayString()
end

local function OnLDBClick(self, button)
	if button == "RightButton" then
		InterfaceOptionsFrame_OpenToCategory(ns.options)
	else
		ToggleCharacter("TokenFrame")
		LDBUpdate()
	end
end

local function OnLDBEnter(self)
	local tooltip = QTip:Acquire("DataStore_Currencies", 2, "LEFT", "RIGHT")
	local character, name, count, icon, currency, currencyString
	tooltip:Clear()

	tooltip:AddHeader(CURRENCY)
	for i = 1, #ns.characters do
		character = ns.characters[i].key
		currencyString = GetCurrencyString(character)
		if currencyString ~= '' then
			tooltip:AddLine(ns.GetColoredCharacterName(character), currencyString)
		end
	end

	-- Use smart anchoring code to anchor the tooltip to our frame
	tooltip:SmartAnchorTo(self)
	tooltip:SetAutoHideDelay(0.25, self)
	tooltip:Show()
end

-- initialize LDB plugin
currencyLDB = LibStub:GetLibrary('LibDataBroker-1.1'):NewDataObject('DataStore_Currencies', {
	type	= 'data source',
	label	= string.format('%s: %s', addonName, CURRENCY),
	text 	= CURRENCY,

	OnClick = OnLDBClick,
	OnEnter = OnLDBEnter,
	OnLeave = function() end,	-- needed for e.g. NinjaPanel
})

ns.RegisterEvent('ADDON_LOADED', function(frame, event, arg1)
	if arg1 == addonName or arg1 == 'DataStore_Currencies' then
		if IsAddOnLoaded('DataStore_Currencies') then
			-- register module
			table.insert(ns.modules, { currencyLDB, function()
				-- check saved variables
				if not BDS_GlobalDB.currencies then
					BDS_GlobalDB.currencies = {}
				end
				LDBUpdate()
			end })
			ns.UnregisterEvent('ADDON_LOADED', 'currencies')
		end
	end
end, 'currencies')

ns.RegisterEvent('CURRENCY_DISPLAY_UPDATE', LDBUpdate, 'currencies_update')
