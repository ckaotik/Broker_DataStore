local addonName, ns, _ = ...

-- GLOBALS: AUTOCOMPLETE_MAX_BUTTONS, AUTOCOMPLETE_SIMPLE_REGEX, AUTOCOMPLETE_SIMPLE_FORMAT_REGEX, AutoCompleteBox
-- GLOBALS: SendMailNameEditBox, GetAutoCompleteResults, AutoComplete_UpdateResults
-- GLOBALS: pairs, string, table, tContains, hooksecurefunc, strlen, unpack

-- ================================================
-- Autocomplete character names
-- ================================================
local function GetCleanName(text)
	if not text then return '' end
	text = text:match("\124c%x%x%x%x%x%x%x%x(.-)\124r") or text
	return text
end
local function SortNames(a, b)
	local nameA = GetCleanName(a)
	local nameB = GetCleanName(b)
	return nameA < nameB
end
local thisCharacter, lastQuery = DataStore:GetCharacter(), nil
local function AddAltsToAutoComplete(parent, text, cursorPosition)
	if parent == SendMailNameEditBox and cursorPosition <= strlen(text) then
		-- possible flags can be found here: http://wow.go-hero.net/framexml/16650/AutoComplete.lua
		local include, exclude = parent.autoCompleteParams.include, parent.autoCompleteParams.exclude
		local newResults = { GetAutoCompleteResults(text, include, exclude, AUTOCOMPLETE_MAX_BUTTONS+1, cursorPosition) }
		local character
		for _, charData in pairs(ns.characters) do
			if charData.key ~= thisCharacter then
				character = charData.name
				if string.find(string.lower(character), '^'..string.lower(text)) then
					local index
					for i, entry in pairs(newResults) do
						if entry == character then
							index = i
							break
						end
					end

					character = ns.GetColoredCharacterName(charData.key)
					if index then
						-- sometimes alts are on our flist/guild, color them nicely, too!
						newResults[index] = character
					else
						table.insert(newResults, character)
					end
				end
			end
		end
		table.sort(newResults, SortNames)
		AutoComplete_UpdateResults(AutoCompleteBox, unpack(newResults))

		-- also write out the first match
		local currentText = parent:GetText()
		if newResults[1] and currentText ~= lastQuery then
			lastQuery = currentText
			local newText = string.gsub(currentText, parent.autoCompleteRegex or AUTOCOMPLETE_SIMPLE_REGEX,
				string.format(parent.autoCompleteFormatRegex or AUTOCOMPLETE_SIMPLE_FORMAT_REGEX, newResults[1],
				string.match(currentText, parent.autoCompleteRegex or AUTOCOMPLETE_SIMPLE_REGEX)),
				1)

			parent:SetText( GetCleanName(newText) )
			parent:HighlightText(strlen(currentText), strlen(newText))
			parent:SetCursorPosition(strlen(currentText))
		end
	end
end

local function CleanAutoCompleteOutput(self)
	local editBox = self:GetParent().parent
	if not editBox.addSpaceToAutoComplete then
		local newText = GetCleanName( editBox:GetText() )
		editBox:SetText(newText)
		editBox:SetCursorPosition(strlen(newText))
	end
end

ns.RegisterEvent('ADDON_LOADED', function(self, event, arg1)
	if arg1 == addonName then
		hooksecurefunc('AutoComplete_Update', AddAltsToAutoComplete)
		hooksecurefunc('AutoCompleteButton_OnClick', CleanAutoCompleteOutput)

		ns.UnregisterEvent('ADDON_LOADED', 'characters')
	end
end, 'characters')
