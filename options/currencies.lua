local _, Broker_DS = ...

if IsAddOnLoaded("DataStore_Currencies") then
	local options = CreateFrame("Frame", "BrokerDS_CurrenciesOptions", InterfaceOptionsFramePanelContainer)
	options.parent = "Broker_DataStore"
	options.name = Broker_DS.locale.currencies
	
	options:SetScript("OnShow", function(frame)
		-- options
		local title, subtitle = LibStub("tekKonfig-Heading").new(frame,
			Broker_DS.locale.currencies,	-- title
			"Settings for Broker_DataStore's currencies module")	-- subtitle
		
		-- character dropdown
		local characterSelect, characterSelectText, _ = LibStub("tekKonfig-Dropdown").new(frame, 
			"Select a character", 
			"TOPLEFT", subtitle, "BOTTOMLEFT")
		characterSelectText:SetText("This character")
		
		-- displays some informational text on how to use these options
		local explanation = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			explanation:SetPoint("TOPLEFT", characterSelect, "TOPRIGHT", 0, 0)
			explanation:SetPoint("BOTTOMLEFT", characterSelect, "BOTTOMRIGHT", 0, 0)
			explanation:SetPoint("RIGHT", frame, -32, 0)
			explanation:SetNonSpaceWrap(true)
			explanation:SetJustifyH("LEFT"); explanation:SetJustifyV("TOP")
			explanation:SetText("Choose a character to show and include/exclude tokens for.")
		
		-- create the scroll box, full width and all the fun
		local scrollFrame = CreateFrame("ScrollFrame", frame:GetName().."Scroll", frame, "UIPanelScrollFrameTemplate")
		scrollFrame:SetPoint("TOPLEFT", characterSelect, "BOTTOMLEFT", 0, -4)
		scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -26, 3)
		local scrollContent = CreateFrame("Frame", scrollFrame:GetName().."Content", scrollFrame)
		scrollFrame:SetScrollChild(scrollContent)
		scrollContent:SetHeight(300); scrollContent:SetWidth(400)	-- will be replaced when used
		scrollContent:SetAllPoints()
		
		-- helper functions
		local function FetchEntry(i, isHeader)
			-- retrieves or creates entry number #i
			scrollContent:SetWidth(scrollFrame:GetWidth())
			scrollContent:SetHeight(scrollFrame:GetHeight())
			
			if _G["BDSCurrenciesEntry"..i] then
				return _G["BDSCurrenciesEntry"..i]
			else
				local entry = CreateFrame("Frame", "BDSCurrenciesEntry"..i, scrollContent)
				if i == 1 then
					entry:SetPoint("TOPLEFT", scrollContent, "TOPLEFT")
					entry:SetPoint("TOPRIGHT", scrollContent, "TOPRIGHT")
				else
					entry:SetPoint("TOPLEFT", _G["BDSCurrenciesEntry"..(i-1)], "BOTTOMLEFT", 0, -2)
					entry:SetPoint("TOPRIGHT", _G["BDSCurrenciesEntry"..(i-1)], "BOTTOMRIGHT", 0, -2)
				end
				entry:SetHeight(24)
				
				entry.count = entry:CreateFontString(nil, "ARTWORK", "GameFontNormal")
					entry.count:SetWidth(80)
					entry.count:SetJustifyH("RIGHT")
					entry.count:SetPoint("TOPLEFT", entry, "TOPLEFT")
				
				entry.check = CreateFrame("CheckButton", entry:GetName().."CheckBox", entry, "UICheckButtonTemplate")
					entry.check:SetWidth(20); entry.check:SetHeight(20)
					entry.check:SetPoint("LEFT", entry.count, "RIGHT", 4, 0)
					entry.check:SetChecked(false)
				
				entry.icon = entry:CreateTexture()
					entry.icon:SetWidth(16); entry.icon:SetHeight(16)
					entry.icon:SetPoint("LEFT", entry.check, "RIGHT", 4, 0)
				
				entry.label = entry:CreateFontString(nil, "ARTWORK", "GameFontNormal")
				
				return entry
			end
		end
		
		local function DisplayCurrencyData(character)
			if not character then character = DataStore:GetCharacter() end
			if not BDS_GlobalDB.currencies[character] then BDS_GlobalDB.currencies[character] = {} end
			local entry
			
			local i = 1
			-- hide previous data
			while _G["BDSCurrenciesEntry"..i] do
				entry = _G["BDSCurrenciesEntry"..i]
				entry:Hide()
				i = i + 1
			end
			
			-- display current data
			local numCurrencies = DataStore:GetNumCurrencies(character)
			for k = 1, numCurrencies do
<<<<<<< HEAD
				local isHeader, name, count, icon = DataStore:GetCurrencyInfo(character, k)
=======
				local isHeader, name, count, itemID = DataStore:GetCurrencyInfo(character, k)
>>>>>>> origin/master
				
				entry = FetchEntry(k)
				if isHeader then
					entry:SetBackdrop({
						bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
						insets = {left = 4, right = 4, top = 4, bottom = 4},
						edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
						edgeSize = 16
					})
					entry:SetBackdropColor(1, 1, 1, 0.2)
					entry.count:Hide()
					entry.icon:Hide()
					entry.check:Hide()
					entry.label:SetAllPoints()
					entry.label:SetJustifyH("CENTER")
				else
					entry:SetBackdrop(nil)
					entry.count:Show()
					entry.icon:Show()
					entry.check:Show()
					entry.label:SetJustifyH("LEFT")
					entry.label:ClearAllPoints()
					entry.label:SetPoint("LEFT", entry.icon, "RIGHT", 4, 0)
					
					entry.count:SetText(Broker_DS:ShortenNumber(count))
					
<<<<<<< HEAD
					entry.check:SetChecked(BDS_GlobalDB.currencies[character][name] or false)
=======
					entry.check:SetChecked(BDS_GlobalDB.currencies[character][itemID] or false)
>>>>>>> origin/master
					entry.check:SetScript("OnClick", function(self, button)
						if not BDS_GlobalDB.currencies[character] then
							BDS_GlobalDB.currencies[character] = {}
						end
<<<<<<< HEAD
						BDS_GlobalDB.currencies[character][name] = self:GetChecked()
						Broker_DS.currencies:UpdateLDB()
					end)
					
=======
						BDS_GlobalDB.currencies[character][itemID] = self:GetChecked()
						Broker_DS.currencies:UpdateLDB()
					end)
					
					local icon = Broker_DS.currencies:GetMarkIcon(itemID, character)
>>>>>>> origin/master
					entry.icon:SetTexture(icon)
				end
				entry.label:SetText(name)
				entry:Show()
			end
		end
		
		DisplayCurrencyData()
		
		-- stupid lua order
<<<<<<< HEAD
		local function OnClick(self)
			UIDropDownMenu_SetSelectedValue(characterSelect, self.value)
			characterSelectText:SetText(Broker_DS:GetColoredCharacterName(self.value))
			DisplayCurrencyData(self.value)
=======
		local function OnClick()
			UIDropDownMenu_SetSelectedValue(characterSelect, this.value)
			characterSelectText:SetText(Broker_DS:GetColoredCharacterName(this.value))
			DisplayCurrencyData(this.value)
>>>>>>> origin/master
		end
		UIDropDownMenu_Initialize(characterSelect, function()
			local selected, info = UIDropDownMenu_GetSelectedValue(characterSelect), UIDropDownMenu_CreateInfo()
			
			local char
			for i=1, #Broker_DS.characters do
				char = Broker_DS.characters[i].key
				info.text = Broker_DS:GetColoredCharacterName(char)
				info.value = char
				info.func = OnClick
				info.checked = char == selected
				UIDropDownMenu_AddButton(info)
			end
		end)
		-- select the current character for more intuitive usage
		UIDropDownMenu_SetSelectedValue(characterSelect, DataStore:GetCharacter())
		ToggleDropDownMenu(1, nil, characterSelect, frame, -20, 0)
		
		frame:SetScript("OnShow", nil)
	end)
	
	Broker_DS.currencies.options = options
	InterfaceOptions_AddCategory(options)
end