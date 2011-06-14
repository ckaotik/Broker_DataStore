local _, Broker_DS = ...

if IsAddOnLoaded("DataStore_Achievements") then
	Broker_DS.achievements = {}
	
	-- Managing the module --------------------------------------------------
	-- initialize LDB plugin
	local LDB = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("DataStore_Achievements", {
		type	= "data source",
		label	= "Achievements",
		text 	= Broker_DS.locale.achievements,
		
		-- OnClick is further below
		OnTooltipShow = function(self)
			self:AddDoubleLine("Broker_DataStore", Broker_DS.locale.achievements)
			
			for i=1, #Broker_DS.characters do
				-- TODO
				-- self:AddDoubleLine(Broker_DS:GetColoredCharacterName(char), currencyString)
			end
			if GameTooltip:NumLines() == 1 then
				self:AddLine(Broker_DS.locale.achievementsNone)
			end
		end
	})
	
	function Broker_DS.achievements:UpdateLDB(displayText)
		if displayText and displayText ~= "" then
			LDB.text = displayText
		else
			local currenciesString = Broker_DS.currencies:GetCurrencyString()
			if currenciesString == "" then
				-- LDB.text = "|TInterface\\Minimap\\Tracking\\None:0|t " .. Broker_DS.locale.currencies
			else
				-- LDB.text = currenciesString
			end
		end
	end
	LDB.OnClick = function(self, button)
		if button == "RightButton" then
			-- InterfaceOptionsFrame_OpenToCategory(Broker_DS.achievements.options)
		else
			ToggleCharacter("AchievementFrame")
			Broker_DS.achievements:UpdateLDB()
		end
	end
	
	local init = function()
		-- check saved variables
		if not BDS_GlobalDB.achievements then
			BDS_GlobalDB.achievements = {}
		end
		Broker_DS.achievements:UpdateLDB()
	end
	
	-- event frame
	local frame = CreateFrame("frame")
	-- frame:RegisterEvent("CHAT_MSG_SYSTEM")
	frame:SetScript("OnEvent", function(self, event, ...)
		-- Broker_DS.currencies:UpdateLDB()
	end)
	
	-- register module
	if not Broker_DS.modules then
		Broker_DS.modules = { {LDB, init} }
	else
		tinsert(Broker_DS.modules, {LDB, init})
	end
end