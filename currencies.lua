local _, Broker_DS = ...

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
		local colNum = 1 + 1 -- ns.numKnown
		ns.tt = QTip:Acquire("Broker_DataStore_Currencies", colNum, "LEFT", "RIGHT")
		ns.tt:Clear()

		-- font settings
		local tooltipHFont = CreateFont("TooltipHeaderFont")
		tooltipHFont:SetFont(GameTooltipText:GetFont(), 14)
		tooltipHFont:SetTextColor(1,1,1)

		local tooltipFont = CreateFont("TooltipFont")
		tooltipFont:SetFont(GameTooltipText:GetFont(), 11)
		tooltipFont:SetTextColor(255/255,176/255,25/255)

		local lineNum = ns.tt:AddLine("")
		ns.tt:SetCell(lineNum, 1, ns.name, tooltipHFont) --, 2) -- colspan!

		local character, name, count, icon, currency
		for i = 1, #Broker_DS.characters do
			character = Broker_DS.characters[i].key
			lineNum = ns.tt:AddLine(Broker_DS:GetColoredCharacterName(character),
				Broker_DS.currencies:GetCurrencyString(character)
			)

			--[[ for j = 1, ns.numKnown do
				currency = BDS_GlobalDB.currencies.order[j]
				_, name, count, icon = DataStore:GetCurrencyInfoByName(character, currency)
				icon = icon and "|T"..icon..":0|t" or ""
				ns.tt:SetCell(lineNum, j+1, (count or "-") .." ".. icon, "RIGHT") -- , 1, 5, 0, 50, 10)
			end--]]
		end
		if lineNum == 1 then
			ns.tt:AddLine("Nothing to display here. Right-Click for options!")
		end

		-- Use smart anchoring code to anchor the tooltip to our frame
		ns.tt:SmartAnchorTo(self)
		ns.tt:SetAutoHideDelay(0.25, self)
		ns.tt:Show()
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
	frame:SetScript("OnEvent", function(self, event, ...)
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
