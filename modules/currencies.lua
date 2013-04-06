local addonName, Broker_DS, _ = ...

if IsAddOnLoaded("DataStore_Currencies") then
	Broker_DS.currencies = {}
	local ns = Broker_DS.currencies
		  ns.name = "Currencies"
		  ns.numKnown = 1

	local QTip = LibStub("LibQTip-1.0")

	-- initialize LDB plugin
	local LDB = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("DataStore_Currencies", {
		type	= "data source",
		label	= ns.name,
		text 	= Broker_DS.locale.currencies,

		OnClick = function(...) ns:OnClick(...) end,
		OnEnter = function(...) ns:Tooltip(...) end,
		OnLeave = function() end,	-- needed for e.g. NinjaPanel
	})
	ns.LDB = LDB

	function ns:OnClick(self, button)
		if button == "RightButton" then
			InterfaceOptionsFrame_OpenToCategory(ns.options)
		else
			ToggleCharacter("TokenFrame")
			ns:UpdateLDB()
		end
	end

	function ns:UpdateLDB(displayText)
		if displayText and displayText ~= "" then
			LDB.text = displayText
		else
			local currenciesString = ns:GetCurrencyString()
			if currenciesString == "" then
				LDB.text = "|TInterface\\Minimap\\Tracking\\None:0|t " .. Broker_DS.locale.currencies
			else
				LDB.text = currenciesString
			end
		end
	end

	function ns:Tooltip(self)
		local tooltip = QTip:Acquire("Broker_DataStore_Currencies", 2, "LEFT", "RIGHT")
		tooltip:Clear()

		tooltip:AddHeader(ns.name)

		local character, name, count, icon, currency
		for i = 1, #Broker_DS.characters do
			character = Broker_DS.characters[i].key
			tooltip:AddLine(
				Broker_DS.GetColoredCharacterName(character),
				Broker_DS.currencies:GetCurrencyString(character)
			)
		end

		-- Use smart anchoring code to anchor the tooltip to our frame
		tooltip:SmartAnchorTo(self)
		tooltip:SetAutoHideDelay(0.25, self)
		tooltip:Show()
	end

	function ns:GetCurrency(character, index)
		if not character then character = DataStore:GetCharacter() end
		local isSelf, maxEntries, current = nil, nil, 0
		if character == DataStore:GetCharacter() then
			isSelf = true
			maxEntries = GetCurrencyListSize()
		else
			maxEntries = DataStore:GetNumCurrencies(character)
		end

		for i = 1, maxEntries do
			local isHeader, name, count, icon
			if isSelf then
				name, isHeader, _, _, _, count, icon = GetCurrencyListInfo(i)
			else
				isHeader, name, count, icon = DataStore:GetCurrencyInfo(character, i)
			end

			if isHeader then
				-- ignore
			else
				current = current + 1
				if current == index then
					return name, count, (icon and "|T"..icon..":0|t" or nil)
				end
			end
		end
		return "", 0
	end

	-- returns currencies (string) for a given character
	function ns:GetCurrencyString(character)
		if not character then character = DataStore:GetCharacter() end
        local isSelf, maxEntries
        if character == DataStore:GetCharacter() then
			isSelf = true
			maxEntries = GetCurrencyListSize()
		else
			maxEntries = DataStore:GetNumCurrencies(character)
		end

		local text = ""
		for i = 1, maxEntries do
			local isHeader, name, count, icon
			if isSelf then
				name, isHeader, _, _, _, count, icon = GetCurrencyListInfo(i)
			else
				isHeader, name, count, icon = DataStore:GetCurrencyInfo(character, i)
			end

			if not isHeader and count and count > 0
				and BDS_GlobalDB.currencies[character] and BDS_GlobalDB.currencies[character][name] then
				text = text .. "|T" .. (icon or "") .. ":0|t" .. (count or 0) .. " "	-- trailing space for concat
			end
		end
		return text
	end

	-- Managing the module --------------------------------------------------
	local function UpdateNumCurrenciesKnown()
		for i = 1, #Broker_DS.characters do
			local character, count, isSelf, name, header = Broker_DS.characters[i].key, nil, nil
			if character == DataStore:GetCharacter() then
				count = GetCurrencyListSize()
				isSelf = true
			else
				count = DataStore:GetNumCurrencies(character)
			end
			count = count or 0

			if count > ns.numKnown then
				ns.numKnown = count

				if BDS_GlobalDB.currencies.order then wipe(BDS_GlobalDB.currencies.order)
				else BDS_GlobalDB.currencies.order = {}
				end
				for i=1, count do
					if isSelf then name, header = GetCurrencyListInfo(i)
					else header, name = DataStore:GetCurrencyInfo(character, i)
					end
					if not header then table.insert(BDS_GlobalDB.currencies.order, name) end
				end
				ns.numKnown = #(BDS_GlobalDB.currencies.order)
			end
		end
	end

	local init = function()
		-- check saved variables
		if not BDS_GlobalDB.currencies then
			BDS_GlobalDB.currencies = {}
		end

		-- UpdateNumCurrenciesKnown()
		ns:UpdateLDB()
	end

	-- event frame
	local frame = CreateFrame("frame")
		  frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
		  frame:RegisterEvent("CHAT_MSG_SYSTEM")
	frame:SetScript("OnEvent", function(self, event, arg1, ...)
		if event == "CURRENCY_DISPLAY_UPDATE" then UpdateNumCurrenciesKnown()
		elseif event == "CHAT_MSG_SYSTEM" and arg1 ~= ITEM_REFUND_MSG then return
		end
		Broker_DS.currencies:UpdateLDB(ns:GetCurrencyString())
	end)

	-- register module
	if not Broker_DS.modules then
		Broker_DS.modules = { {LDB, init} }
	else
		tinsert(Broker_DS.modules, {LDB, init})
	end
end


-- --------------------------------------------------------
-- character progress
-- --------------------------------------------------------

do
	local _, ns = ...
	local QTip = LibStub("LibQTip-1.0")

	local lastMaintenance
	local fontDummy = ns.events:CreateFontString()
	local thisCharacter = DataStore:GetCharacter()

	local function tex(item, text)
		local icon = select(10, GetItemInfo(item))
		return icon and '|T'..icon..':0|t' or text or ''
	end
	local function currencyHeader(currency)
		local index = 3 -- 3 = icon, 1 = name
		local icon = select(index, GetCurrencyInfo(currency))
		return (index == 3 and icon and '|T'..icon..':0|t' or nil) or name
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
		-- dataTable = tableValues(dataTable)
		for index, value in ipairs(dataTable) do
			if not value then
				dataTable[index] = '|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:0|t'
			elseif value == true then
				dataTable[index] = '|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0|t'
			else
				-- no changes
			end
		end
		return unpack(dataTable)
	end

	local worldBosses 	    = { 32099, 32098, 32518, 32519 }
	local worldBossesNames  = { 'Sha', 'Galleon', 'Nalak', 'Oondasta' }
	local LFRDungeons       = { {527, 528}, {529, 530}, {526}, {610, 611, 612, 613} }
	local LFRDungeonsNames  = { 'MV', 'HoF', 'ToES', 'ToT' }
	local weeklyQuests      = { 32610, 32626, 32609, 32505, '32640|32641' }
	local weeklyQuestsNames = { tex(94221, 'Stone'), tex(94222, 'Key'), tex(87391, 'Chest'), tex(93792, 'Statue'), tex(90538, 'Group') }
	local currencies = { 396, 395, 752, 697, 738 } -- valor, justice, elder/lesser/mogu charm
	local currenciesNames = { currencyHeader(396), currencyHeader(395), currencyHeader(752), currencyHeader(697), currencyHeader(738) }

	local function GetCharacterQuestState(character, questID)
		if character ~= thisCharacter and IsAddOnLoaded('DataStore_Quests') then
			local _, lastUpdate = DataStore:GetQuestHistoryInfo(character)
			if not (lastUpdate and lastMaintenance) or lastUpdate < lastMaintenance then
				return false
			else
				return DataStore:IsQuestCompletedBy(character, questID) and true or false
			end
		elseif character == thisCharacter then
			return IsQuestFlaggedCompleted(questID) and true or false
		else
			-- no info
			return false
		end
	end
	local function GetCharacterLockoutState(character, dungeonID)
		if character ~= thisCharacter and IsAddOnLoaded('DataStore_Agenda') then
			-- TODO: figure out a way to save if a dungeon is available
			local instanceKey = GetLFGDungeonInfo(dungeonID)
				  instanceKey = instanceKey .. " (LFR)|" .. dungeonID
			local _, _, numDefeated, cleared = DataStore:GetSavedInstanceInfo(character, instanceKey)
			if numDefeated and not DataStore:HasSavedInstanceExpired(character, instanceKey) then
				-- we have data and it's not outdated
				return numDefeated, nil -- cleared and numDefeated or nil
			end

		elseif character == thisCharacter then -- /spew GetLFGDungeonEncounterInfo(dungeonID, 4)
			local _, _, cleared, available = GetLFGDungeonRewardCapInfo(dungeonID)
			local numEncounters, numDefeated = GetLFGDungeonNumEncounters(dungeonID)
				  numEncounters = cleared == 1 and numDefeated or (available * numEncounters)
			return numDefeated, numEncounters
		end

		return 0, 0
	end
	local function GetCharacterCurrencyInfo(character, currency)
		local name, currentAmount, _, weeklyAmount, weeklyMax, totalMax = GetCurrencyInfo(currency)
		if character ~= thisCharacter then
			currentAmount = 0
			weeklyAmount = 0
			if IsAddOnLoaded('DataStore_Currencies') then
				-- TODO: get cap info
				-- /spew DataStore_Currencies.db.global.Reference
				_, _, currentAmount = DataStore:GetCurrencyInfoByName(character, name)
			end
		end
		currentAmount = currentAmount or 0
		weeklyAmount = weeklyAmount or 0

		if totalMax%100 == 99 then -- valor and justice caps are weird
			totalMax = math.floor(totalMax/100)
			weeklyMax = math.floor(weeklyMax/100)
		end

		return currentAmount, totalMax, weeklyAmount, weeklyMax
	end

	-- Gather data --------------------------------------------------
	local lockoutReturns = { lfr = {}, worldboss = {}, weekly = {} }
	local function GetCharacterLFRLockouts(character, hideEmpty)
		wipe(lockoutReturns.lfr)
		local showLine = character == thisCharacter
		local numDefeated, numEncounters, categoryData
		for index, LFRCategory in ipairs(LFRDungeons) do
			categoryData = ''
			for _, dungeonID in ipairs(LFRCategory) do
				numDefeated, numEncounters = GetCharacterLockoutState(character, dungeonID)
				categoryData = (categoryData ~= '' and categoryData..' ' or '') .. colorize(numDefeated, 0, numEncounters)
				showLine = showLine or numDefeated > 0 or nil
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
				alliance, horde = strsplit('|', questID)
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

		for index, currency in ipairs(currencies) do
			currentAmount, totalMax, weeklyAmount, weeklyMax = GetCharacterCurrencyInfo(character, currency)
			currencyReturns[index] = colorize(currentAmount, 0, totalMax, true) .. ' '

			if weeklyMax and weeklyMax > 0 and weeklyAmount and weeklyAmount > 0 then
				-- add current weekly cap info
				currencyReturns[index] = currencyReturns[index]..colorize(weeklyAmount, 0, weeklyMax, true)
			end
			-- show non-valor characters only on ALT
			showLine = showLine or ((IsAltKeyDown() or index == 1) and currentAmount > 0) or nil
		end
		return (showLine or not hideEmpty) and currencyReturns or nil
	end

	-- Output ------------------------------------------------------
	local function ShowTooltip(self)
		-- name column + data columns + ilvl on LFRs
		local numColumns = 1 + math.max(0, #worldBosses, #weeklyQuests, #LFRDungeons, #currencies+1)
		local tooltip = QTip:Acquire("DataStore_Grinder", numColumns, "LEFT")
			  tooltip:Clear()

		fontDummy:SetFontObject(tooltip:GetFont())
		local data, lineNum
		table.sort(ns.characters, function(a,b) return a.itemLevel > b.itemLevel end)

		tooltip:AddHeader(RAID_FINDER, unpack(LFRDungeonsNames))
		for _, charData in ipairs(ns.characters) do
			data = GetCharacterLFRLockouts(charData.key, true)
			if data then
				tooltip:AddLine(charData.coloredName, prepare(data))
			end
		end

		tooltip:AddLine(' ')
		tooltip:AddHeader(BOSS, unpack(worldBossesNames))
		for _, charData in ipairs(ns.characters) do
			data = GetCharacterBossLockouts(charData.key, true)
			if data then
				tooltip:AddLine(charData.coloredName, prepare(data))
			end
		end

		tooltip:AddLine(' ')
		tooltip:AddHeader(CALENDAR_REPEAT_WEEKLY, unpack(weeklyQuestsNames))
		for _, charData in ipairs(ns.characters) do
			data = GetCharacterWeeklyLockouts(charData.key, true)
			if data then
				tooltip:AddLine(charData.coloredName, prepare(data))
			end
		end

		tooltip:AddLine(' ')
		tooltip:AddHeader(CURRENCY, LEVEL, unpack(currenciesNames))
		for _, charData in ipairs(ns.characters) do
			data = GetCharacterCurrencies(charData.key, true)
			if data then
				tooltip:AddLine(charData.coloredName, math.floor(charData.itemLevel), unpack(data))
			end
		end

		-- Use smart anchoring code to anchor the tooltip to our frame
		tooltip:SmartAnchorTo(self)
		tooltip:SetAutoHideDelay(0.25, self)
		tooltip:Show()
	end

	local LDB = LibStub:GetLibrary('LibDataBroker-1.1'):NewDataObject('DataStore_CharProgress', {
		type	= 'data source',
		label	= '',
		text 	= 'Character Progress',

		OnEnter = ShowTooltip,
		OnClick = function() end,
		OnLeave = function() end,	-- needed for e.g. NinjaPanel
	})

	-- --------------------------------------------------------

	local function UpdateWeeklyCap(frame, event, ...)
		if IsAddOnLoaded('DataStore_Currencies') then
			local ref = _G['DataStore_Currencies'].db.global.Reference -- not working :(
			if not ref.CurrencyCaps then ref.CurrencyCaps = {} end
			wipe(ref.CurrencyCaps)

			-- TODO: scan and save valor cap info
			local current, max, weekly, weeklyMax
			for _, currency in ipairs(currencies) do
				current, max, weekly, weeklyMax = GetCharacterCurrencyInfo(thisCharacter, currency)
				ref.CurrencyCaps[currency] = string.format('%d|%d|%d|%d', current, max, weekly, weeklyMax)
			end
		end
	end
	ns.RegisterEvent('CURRENCY_DISPLAY_UPDATE', UpdateWeeklyCap, 'updateweeklycap')
	-- ns.RegisterEvent('CHAT_MSG_CURRENCY', UpdateWeeklyCap, 'updateweekly_update')
	--[[ ns.RegisterEvent('CHAT_MSG_SYSTEM', function(frame, event, arg1, ...)
		if arg1 == ITEM_REFUND_MSG then
			UpdateWeeklyCap(frame, event, arg1, ...)
		end
	end, 'updateweekly_refund') --]]

	local function UpdateWeeklyQuests(frame, event)
		if IsAddOnLoaded('DataStore_Quests') then
			local history = _G['DataStore_Quests'].db.global.Characters[thisCharacter].History
			local alliance, horde

			for _, questID in ipairs(worldBosses) do
				history[ ceil(questID / 32) ] = bit.bor(IsQuestFlaggedCompleted(questID) and 1 or 0, 2^(questID % 32))
			end
			for _, questID in ipairs(weeklyQuests) do
				if type(questID) == 'string' then
					alliance, horde = strsplit('|', questID)
					questID = ns.GetFaction(thisCharacter) == 'Alliance' and tonumber(alliance) or tonumber(horde)
				end
				history[ ceil(questID / 32) ] = bit.bor(IsQuestFlaggedCompleted(questID) and 1 or 0, 2^(questID % 32))
			end
			_G['DataStore_Quests'].db.global.Characters[thisCharacter].lastUpdate = time()
		end
	end
	ns.RegisterEvent('QUEST_FINISHED', UpdateWeeklyCap, 'updateweeklyquests')
	-- ZONE_CHANGED, PLAYER_REGEN_ENABLED, QUEST_FINISHED

	local function UpdateLFRProgress(frame, event)
		--[[ if IsAddOnLoaded('DataStore_Agenda') then
			local playerLevel = UnitLevel('player')
			local dungeonID, name, minLevel, maxLevel, cleared, available, numDefeated, dungeonReset
			for i=1, GetNumRFDungeons() do
				dungeonID, dungeonName, _, _, minLevel, maxLevel = GetRFDungeonInfo(i)
				if minLevel >= playerLevel and maxLevel <= playerLevel then
					_, _, cleared, available = GetLFGDungeonRewardCapInfo(dungeonID)
					_, numDefeated = GetLFGDungeonNumEncounters(dungeonID)
					numDefeated = cleared == 1 and -1 or numDefeated

					if numDefeated ~= 0 then
						dungeonReset = GetNextMaintenance() - time()
						dungeons[dungeonName.." (LFR)|"..dungeonID] = format("%s|%s|%s|%s", dungeonReset, time(), available, numDefeated)
					end
				end
			end
		end --]]
	end
	ns.RegisterEvent('LFG_LOCK_INFO_RECEIVED', UpdateLFRProgress, 'updatelfr')

	ns.RegisterEvent('ADDON_LOADED', function(frame, event, arg1)
		if arg1 == addonName then
			local region = GetCVar('portal')
			local maintenanceWeekDay = (region == 'us' and 3)
				or (region == 'eu' and 4)
				or (region == 'kr' and 5) -- ?
				or (region == 'tw' and 6) -- ?
				or 7 -- ?
			local dailyReset = time() + GetQuestResetTime()
			local resetWeekday = tonumber(date('%w', dailyReset)) + 1
			lastMaintenance = dailyReset - ((resetWeekday - maintenanceWeekDay)%7)*24*60*60

			UpdateWeeklyCap()
			UpdateWeeklyQuests()
			UpdateLFRProgress()
		end
	end, 'currencies')
end
