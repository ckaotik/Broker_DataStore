local _, Broker_DS = ...

local options = CreateFrame("Frame", "Broker_DataStoreOptions", InterfaceOptionsFramePanelContainer)
options.name = "Broker_DataStore"

local notAvailable = "|cFFff0000not loaded|r"
local available = "|cFF00ff00loaded|r"
local textWidth = "150"

options:SetScript("OnShow", function(frame)
	local title, subtitle = LibStub("tekKonfig-Heading").new(frame,
		"Broker_DataStore",	-- title
		"For more options see the submenus to the left.\nThe following DataStore modules were found:")	-- subtitle
	
	local auctions = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	auctions:SetWidth(textWidth)
	auctions:SetJustifyH("RIGHT")
	auctions:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -10)
	auctions:SetText(Broker_DS.locale.auctions)
	local auctionsVal = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	auctionsVal:SetWidth(textWidth)
	auctionsVal:SetJustifyH("LEFT")
	auctionsVal:SetPoint("LEFT", auctions, "RIGHT", 4, 0)
	auctionsVal:SetText(IsAddOnLoaded("DataStore_Auctions") and available or notAvailable)
	
	local achievements = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	achievements:SetWidth(textWidth)
	achievements:SetJustifyH("RIGHT")
	achievements:SetPoint("TOPLEFT", auctions, "BOTTOMLEFT", 0, -4)
	achievements:SetText(Broker_DS.locale.achievements)
	local achievementsVal = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	achievementsVal:SetWidth(textWidth)
	achievementsVal:SetJustifyH("LEFT")
	achievementsVal:SetPoint("LEFT", achievements, "RIGHT", 4, 0)
	achievementsVal:SetText(IsAddOnLoaded("DataStore_Achievements") and available or notAvailable)
	
	local currencies = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	currencies:SetWidth(textWidth)
	currencies:SetJustifyH("RIGHT")
	currencies:SetPoint("TOPLEFT", achievements, "BOTTOMLEFT", 0, -4)
	currencies:SetText(Broker_DS.locale.currencies)
	local currenciesVal = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	currenciesVal:SetWidth(textWidth)
	currenciesVal:SetJustifyH("LEFT")
	currenciesVal:SetPoint("LEFT", currencies, "RIGHT", 4, 0)
	currenciesVal:SetText(IsAddOnLoaded("DataStore_Currencies") and available or notAvailable)
	
	local talents = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	talents:SetWidth(textWidth)
	talents:SetJustifyH("RIGHT")
	talents:SetPoint("TOPLEFT", currencies, "BOTTOMLEFT", 0, -4)
	talents:SetText(Broker_DS.locale.talents)
	local talentsVal = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	talentsVal:SetWidth(textWidth)
	talentsVal:SetJustifyH("LEFT")
	talentsVal:SetPoint("LEFT", talents, "RIGHT", 4, 0)
	talentsVal:SetText(IsAddOnLoaded("DataStore_Currencies") and available or notAvailable)
	
	frame:SetScript("OnShow", nil)
end)

Broker_DS.options = options
InterfaceOptions_AddCategory(options)