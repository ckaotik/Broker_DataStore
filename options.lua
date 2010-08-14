local _, Broker_DS = ...

--[[
-- options frame
local frame = CreateFrame('Frame', 'CTrackerOptionsFrame', InterfaceOptionsFramePanelContainer)
frame.name = 'Broker_CTracker'
f.option = frame
InterfaceOptions_AddCategory(frame)



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
		local CheckBoxBox = CreateFrame("ScrollFrame", "CheckBoxBox", frame, "UIPanelScrollFrameTemplate")
		local CBB_Scroll = CreateFrame("Frame", "CBB_Scroll", CheckBoxBox)
		CheckBoxBox:SetScrollChild(CBB_Scroll)
		CheckBoxBox:SetPoint("TOPLEFT", checkboxabout, 0,-20)
		CheckBoxBox:SetPoint("BOTTOMRIGHT", frame, -27,4)
		CheckBoxBox:SetFrameStrata("DIALOG")
		CBB_Scroll:SetAllPoints(CheckBoxBox)
		CBB_Scroll:SetHeight(300)
		CBB_Scroll:SetWidth(300)

		CheckBoxBox:Show()
		CBB_Scroll:Show()
		
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
				info.arg2 = CBB_Scroll
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
		CurrenciesCheckBoxes(character, CheckBoxBox)
	end
]]