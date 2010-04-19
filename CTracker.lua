local iconSize = 15

-- event frame
local f = CreateFrame("Frame", "CTracker", UIParent)
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
f:RegisterEvent("HONOR_CURRENCY_UPDATE")
f:RegisterEvent("KNOWN_CURRENCY_TYPES_UPDATE")
f:RegisterEvent("CHAT_MSG_LOOT")	-- test

-- options frame
local frame = CreateFrame("Frame", "CTracker_OptionsPanel", InterfaceOptionsFramePanelContainer)
frame.name = "Broker_CTracker"
f.option = frame
InterfaceOptions_AddCategory(frame)

-- ---------------------------------------------------
local loaded = false	-- do not change!
local character = DataStore:GetCharacter()

-- Helper functions
-- ===================================================
-- reformats long numbers to shorter ones: 12403 => 12.4k
local function numberize(v)
	if v <= 9999 then return v end
	if v >= 1000000 then
		local value = string.format("%.1fm", v/1000000)
		return value
	elseif v >= 10000 then
		local value = string.format("%.1fk", v/1000)
		return value
	end
end

local function abbreviate(text, limit)
	text = (string.len(text) > (limit or 10)) and string.gsub(text, "%s?([\128-\196].)%S+%s", "%1. ")
	return (string.len(text) > (limit or 10)) and string.gsub(text, "(%s?)([^\128-\196])%S+%s", "%1%2. ") or text
end


-- addon related utility functions
-- ===================================================
local function GetMarkIcon(itemID)
	if itemID == 43308 then
		-- honor points
		return "Interface\\AddOns\\Broker_CTracker\\"..UnitFactionGroup("player")
	elseif itemID == 43307 then
		-- arena points
		return "Interface\\PVPFrame\\PVP-ArenaPoints-Icon"
	else
		return GetItemIcon(itemID)
	end
end

local function GetMarkCount(character,itemID)
	for i = 1, DataStore:GetNumCurrencies(character), 1 do
		if select(4,DataStore:GetCurrencyInfo(character, i)) == itemID then
			return select(3,DataStore:GetCurrencyInfo(character, i))
		end
	end
	return 0
end

-- returns currencies (string) for a given character
local function GetCurrencyString(character)
	local text = ""
	for i = 1, DataStore:GetNumCurrencies(character) do
		local isHeader, name, count, itemID = DataStore:GetCurrencyInfo(character, i)
		if not isHeader and (hideCurrency == nil or not hideCurrency[character] or not hideCurrency[character][itemID]) then
			local icon = GetMarkIcon(itemID)
			if count ~= 0 then text = text .. numberize(count).." |T"..icon..":"..iconSize..":"..iconSize..":0.2:0.5|t " end
			
			-- check if our saved variables exist
			if not hideCurrency then
				hideCurrency = {
					[character] = {}
				}
			end
			if not hideCurrency[character] then
				hideCurrency[character] = {}
			end
			
			-- default to "do not hide this currency" (being "false")
			if not hideCurrency[character][itemID] then
				hideCurrency[character][itemID] = false
			end
		end
	end
	return text
end

local function UpdateDisplay()
	if CTracker then 
		if GetCurrencyString(character) == "" then
			CTracker.text = "|TInterface\\Minimap\\Tracking\\None:"..iconSize..":"..iconSize..":0:0|tCTracker"
		else
			CTracker.text = GetCurrencyString(character)
		end
	end
end

-- options
-- ===================================================
local function CurrenciesCheckBoxes(checkCharacter, parent)
	-- show checkboxes for currencies to include
	local last
	local i = 0
	
	-- hide previously created check boxes + labels + ids (phew ...)
	if _G["CTrackerOptionCheck1"] then
		local i = 1
		while _G["CTrackerOptionCheck"..i] do
			_G["CTrackerOptionCheck"..i]:Hide()
			_G["CTrackerOptionCheck"..i].label:SetText("")
			_G["CTrackerOptionCheck"..i].count:SetText("")
			_G["CTrackerOptionCheck"..i].icon:Hide()
			_G["CTrackerOptionCheck"..i].itemID = nil
			i = i+1
		end
	end
	
	f.checkboxes = {}
	for itemID,_ in pairs(hideCurrency[checkCharacter]) do
		local check = _G['CTrackerOptionCheck'..i] or CreateFrame('CheckButton', 'CTrackerOptionCheck'..i, parent, 'OptionsCheckButtonTemplate')
		i = i+1
		if last ~= nil then
			check:SetPoint('TOPLEFT', last, 'BOTTOMLEFT', 0, -10)
		else
			check:SetPoint('TOPLEFT', parent, 40, -10)
		end
		check:Show()
	
		local label
		if not _G['CTrackerOptionCheck'..i] or not _G['CTrackerOptionCheck'..i].label then
			label = check:CreateFontString(nil, 'BACKGROUND', 'GameFontNormal')
			label:SetPoint('LEFT', check, 'RIGHT', iconSize+5, 2)
			label:SetText(GetItemInfo(itemID))			-- token name
			check.label = label
		else
			check.label:Show()
			check.label:SetText(select(1,GetItemInfo(itemID)))	-- token name
		end
		
		local icon
		if not _G['CTrackerOptionCheck'..i] or not _G['CTrackerOptionCheck'..i].icon then
			icon = check:CreateTexture()
			icon:SetTexture(GetMarkIcon(itemID))
			icon:SetWidth(iconSize)
			icon:SetHeight(iconSize)
			icon:SetPoint('LEFT', check, 'RIGHT', 3, 0)
			
			check.icon = icon
		else
			check.icon:Show()
			check.icon:SetTexture(GetMarkIcon(itemID))
		end
		
		local count
		if not _G['CTrackerOptionCheck'..i] or not _G['CTrackerOptionCheck'..i].count then
			count = check:CreateFontString(nil, 'BACKGROUND', 'GameFontNormal')
			count:SetText(numberize(GetMarkCount(checkCharacter,itemID)))
			count:SetPoint('RIGHT', check, 'LEFT', -3, 2)
			
			check.count = count
		else
			check.count:Show()
			check.count:SetText(numberize(GetMarkCount(checkCharacter,itemID)))
		end
		
		check:SetChecked(not hideCurrency[checkCharacter][itemID] or false)
		check.itemID = itemID
		
		check:SetScript('OnClick', function(self)
			for ID, check in pairs(f.checkboxes) do
				if (check == self) then itemID = ID end
			end
			
			-- read settings from Saved Variables
			if self:GetChecked() then
				hideCurrency[checkCharacter][itemID] = false
			else
				hideCurrency[checkCharacter][itemID] = true
			end
			
			UpdateDisplay()
		end)
		
		last = check
		f.checkboxes[itemID] = check
	end
end

-- for the options frame in the interface menu
local function CreateOptions()
	local frame = _G["CTracker_OptionsPanel"]
	local title = frame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
		title:SetPoint('TOPLEFT', 16, -16)
		title:SetText('Broker_CTracker')

	local about = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
		about:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -10)
		about:SetPoint('RIGHT', frame, -20, 0)
		about:SetHeight(40)
		about:SetJustifyH('LEFT')
		about:SetJustifyV('TOP')
		about:SetText("This happens when you try to make CurrencyTracker (<3) to use DataStore data.")

	local checkboxabout = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
		checkboxabout:SetPoint('TOPLEFT', about, 'BOTTOMLEFT', 0, -10)
		checkboxabout:SetText("Check to include tokens for character")
	
	-- show select box for character choice
	local checkCharacter = character
    if not CharSelect then
		CreateFrame("Frame", "CharSelect", frame, "UIDropDownMenuTemplate")
	end
	CharSelect:ClearAllPoints()
	CharSelect:SetPoint("LEFT", checkboxabout, "RIGHT", 5, 0)
	CharSelect:Show()
	CharSelect:SetFrameStrata("DIALOG")
	
	-- create character list as select options
	local charList = {}
	for characterName, charKey in pairs(DataStore:GetCharacters()) do
		charList[characterName] = charKey
	end
	
	-- make the box-frame scrollable
	local CheckBoxBox = CreateFrame("ScrollFrame", "CTracker_OptionsPanelScrollFrame", frame, "UIPanelScrollFrameTemplate")
	CheckBoxBox:SetPoint("TOPLEFT", checkboxabout, 0,-20)
	CheckBoxBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -27, 3)
	local contentFrame = CreateFrame("Frame", nil, CheckBoxBox)
	CheckBoxBox:SetScrollChild(contentFrame)
	contentFrame:SetHeight(300)
	contentFrame:SetWidth(300)
	contentFrame:SetAllPoints()
	
	-- this belongs to the dropdown box
	local function OnClick(self, charKey, parent)
		UIDropDownMenu_SetSelectedID(CharSelect, self:GetID())
		CurrenciesCheckBoxes(charKey, parent)
	end

	local function initialize(self, level)
		level = level or 1
		local info = UIDropDownMenu_CreateInfo()
		for charName,charKey in pairs(charList) do
			info = UIDropDownMenu_CreateInfo()
			info.text = charName
			info.value = charKey
			info.func = OnClick
			info.arg1 = charKey
			info.arg2 = contentFrame
			UIDropDownMenu_AddButton(info, level)
		end
	end
	UIDropDownMenu_Initialize(CharSelect, initialize)
	UIDropDownMenu_SetWidth(CharSelect, 100);
	UIDropDownMenu_SetButtonWidth(CharSelect, 124)
	UIDropDownMenu_JustifyText(CharSelect, "LEFT")
	
	-- select the current character for more intuitive usage
	UIDropDownMenu_SetSelectedValue(CharSelect, character)
	ToggleDropDownMenu(1, nil, CharSelect, self, -20, 0);
	
	-- load all relevant checkboxes for this character's currency list
	CurrenciesCheckBoxes(character, contentFrame)
end

-- initialisation. kind of important
-- ===================================================
local function Init()
	-- saved vars
	if not hideCurrency then
		hideCurrency = {
			[character] = {}
		}
	end
	if not hideCurrency[character] then
		hideCurrency[character] = {}
	end
	
	-- create options frame
	if not loaded then CreateOptions() end
	loaded = true

	-- tooltip
	local function Tooltip(wut)
		GameTooltip:SetOwner(wut, "ANCHOR_NONE")
		GameTooltip:SetPoint("TOPLEFT", wut, "BOTTOMLEFT")
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Click for options")
		
		-- show current character first
		if GetCurrencyString(character) ~= "" then
			GameTooltip:AddDoubleLine(DataStore:GetClassColor(character)..GetUnitName("player"),GetCurrencyString(character))
		end
		for characterName, char in pairs(DataStore:GetCharacters()) do
			local data = GetCurrencyString(char)
			local color = DataStore:GetClassColor(char)
			if data ~= "" and char ~= character then
				GameTooltip:AddDoubleLine(color..characterName,data)
			end
		end
		
		GameTooltip:Show()
	end

	-- LDB
	CTracker = LibStub("LibDataBroker-1.1"):NewDataObject("CTracker", { 
		type = "data source",
		text = "CTracker",
		OnClick = function() InterfaceOptionsFrame_OpenToCategory(frame) end,
		OnEnter = function(self) Tooltip(self) end,
		OnLeave = function() GameTooltip:Hide()	end,
	})

	UpdateDisplay()
	f:UnregisterEvent("PLAYER_ENTERING_WORLD")
	f:SetScript("OnEvent", UpdateDisplay)
end

f:SetScript("OnEvent", Init)