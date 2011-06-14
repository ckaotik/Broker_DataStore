local _, Broker_DS = ...

if IsAddOnLoaded("DataStore_Auctions") then
	local options = CreateFrame("Frame", "BrokerDS_AuctionsOptions", InterfaceOptionsFramePanelContainer)
	options.parent = "Broker_DataStore"
	options.name = Broker_DS.locale.auctions
	
	options:SetScript("OnShow", function(self)
		
		
		self:SetScript("OnShow", nil)
	end)
	
	Broker_DS.auctions.options = options
	InterfaceOptions_AddCategory(options)
end