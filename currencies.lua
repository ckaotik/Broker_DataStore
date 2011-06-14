local _, Broker_DS = ...

if IsAddOnLoaded("DataStore_Currencies") then
	Broker_DS.currencies = {}
	
	-- returns currencies (string) for a given character
	function Broker_DS.currencies:GetCurrencyString(character)
		if not character then character = DataStore:GetCharacter() end
        local isSelf = character == DataStore:GetCharacter()
        
		local text = ""
		local numCurrencies = isSelf and GetCurrencyListSize() or DataStore:GetNumCurrencies(character) or 0
		for i = 1, numCurrencies do
			local isHeader, name, count, icon
			if isSelf then
				name, isHeader, _, _, _, count, icon = GetCurrencyListInfo(i)
			else
				isHeader, name, count, icon = DataStore:GetCurrencyInfo(character, i)
			end
			
			if not isHeader and count > 0
				and BDS_GlobalDB.currencies
				and BDS_GlobalDB.currencies[character]
				and BDS_GlobalDB.currencies[character][name] then
				text = text .. "|T" .. icon .. ":0|t" .. count .. " "	-- trailing space for concat
			end
		end
		return text
	end
	
	-- Managing the module --------------------------------------------------
	-- initialize LDB plugin
	local LDB = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("DataStore_Currencies", {
		type	= "data source",
		label	= "Currencies",
		text 	= Broker_DS.locale.currencies,
		
		-- OnClick is further below
		OnTooltipShow = function(self)
			self:AddDoubleLine("Broker_DataStore", Broker_DS.locale.currencies)
			
			local char, currencyString
			for i=1, #Broker_DS.characters do
				char = Broker_DS.characters[i].key
				currencyString = Broker_DS.currencies:GetCurrencyString(char)
				if currencyString and currencyString ~= "" then
					self:AddDoubleLine(Broker_DS:GetColoredCharacterName(char), currencyString)
				end
			end
			if GameTooltip:NumLines() == 1 then
				self:AddLine("Nothing to display here. Right-Click for options!")
			end
		end
	})
	
	function Broker_DS.currencies:UpdateLDB(displayText)
		if displayText and displayText ~= "" then
			LDB.text = displayText
		else
			local currenciesString = Broker_DS.currencies:GetCurrencyString()
			if currenciesString == "" then
				LDB.text = "|TInterface\\Minimap\\Tracking\\None:0|t " .. Broker_DS.locale.currencies
			else
				LDB.text = currenciesString
			end
		end
	end
	LDB.OnClick = function(self, button)
		if button == "RightButton" then
			InterfaceOptionsFrame_OpenToCategory(Broker_DS.currencies.options)
		else
			ToggleCharacter("TokenFrame")
			Broker_DS.currencies:UpdateLDB()
		end
	end
	
	local init = function()
		-- check saved variables
		if not BDS_GlobalDB.currencies then
			BDS_GlobalDB.currencies = {}
		end
		Broker_DS.currencies:UpdateLDB()
	end
	
	-- event frame
	local frame = CreateFrame("frame")
	frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
	frame:RegisterEvent("CHAT_MSG_SYSTEM")
	frame:SetScript("OnEvent", function(self, event, ...)
		if event == "CHAT_MSG_SYSTEM" and arg1 ~= ITEM_REFUND_MSG then
			return
		end
		Broker_DS.currencies:UpdateLDB(Broker_DS.currencies:GetCurrencyString())
	end)
	
	-- register module
	if not Broker_DS.modules then
		Broker_DS.modules = { {LDB, init} }
	else
		tinsert(Broker_DS.modules, {LDB, init})
	end
end