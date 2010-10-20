local _, Broker_DS = ...

if IsAddOnLoaded("DataStore_Talents") then
	local options = CreateFrame("Frame", "BrokerDS_TalentsOptions", InterfaceOptionsFramePanelContainer)
	options.parent = "Broker_DataStore"
	options.name = Broker_DS.locale.talents
	
	options:SetScript("OnShow", function(self)
		
		
		self:SetScript("OnShow", nil)
	end)
	
	Broker_DS.talents.options = options
	InterfaceOptions_AddCategory(options)
end