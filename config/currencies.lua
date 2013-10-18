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
		local characterSelect, characterSelectText, _ = LibStub("tekKonfig-Dropdown").new(frame, "Select a character", "TOPLEFT", subtitle, "BOTTOMLEFT")

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
		local function ToggleSetting(self, button)
			if not BDS_GlobalDB.currencies[self.character] then BDS_GlobalDB.currencies[self.character] = {} end
			BDS_GlobalDB.currencies[self.character][self.name] = self:GetChecked()
			-- Broker_DS.currencies:UpdateLDB()
		end
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
					entry.check:SetScript("OnClick", ToggleSetting)

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
			local entry, i = nil, 1

			-- hide previous data
			while _G["BDSCurrenciesEntry"..i] do
				entry = _G["BDSCurrenciesEntry"..i]
				entry:Hide()
				i = i + 1
			end

			-- display current data
			local numCurrencies = DataStore:GetNumCurrencies(character)
			for k = 1, numCurrencies do
				local isHeader, name, count, markIcon = DataStore:GetCurrencyInfo(character, k)

				entry = FetchEntry(k, isHeader)
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

					entry.count:SetText(count)
					entry.icon:SetTexture(markIcon)
					entry.check:SetChecked(BDS_GlobalDB.currencies[character][name] or false)
					entry.check.character = character
					entry.check.name = name
				end
				entry.label:SetText(name)
				entry:Show()
			end
		end

		-- stupid lua order
		local function OnClick(self)
			UIDropDownMenu_SetSelectedValue(characterSelect, self.value)
			DisplayCurrencyData(self.value)
		end
		characterSelect.initialize = function()
			local selected = UIDropDownMenu_GetSelectedValue(characterSelect)
			local info = UIDropDownMenu_CreateInfo()

			local char
			for i = 1, #Broker_DS.characters do
				info.value = Broker_DS.characters[i].key
				info.text  = Broker_DS.GetColoredCharacterName(info.value)
				info.func  = OnClick
				info.checked = char == selected

				UIDropDownMenu_AddButton(info)
			end
		end

		-- select the current character for more intuitive usage
		local character = DataStore:GetCharacter()
		UIDropDownMenu_SetSelectedValue(characterSelect, character)
		-- UIDropDownMenu_SetText(characterSelect, "This character")

		DisplayCurrencyData(character)

		frame:SetScript("OnShow", nil)
	end)

	Broker_DS.currencies.options = options
	InterfaceOptions_AddCategory(options)
end
