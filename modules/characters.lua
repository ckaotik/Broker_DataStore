local addonName, ns, _ = ...

-- GLOBALS: AUTOCOMPLETE_MAX_BUTTONS, AUTOCOMPLETE_SIMPLE_REGEX, AUTOCOMPLETE_SIMPLE_FORMAT_REGEX, AutoCompleteBox
-- GLOBALS: SendMailNameEditBox, GetAutoCompleteResults, AutoComplete_UpdateResults
-- GLOBALS: pairs, string, table, tContains, hooksecurefunc, strlen, unpack

-- ================================================
-- Autocomplete character names
-- ================================================
local thisCharacter, lastQuery = DataStore:GetCharacter(), nil
local function AddAltsToAutoComplete(parent, text, cursorPosition)
	if parent == SendMailNameEditBox and cursorPosition <= strlen(text) then
		-- possible flags can be found here: http://wow.go-hero.net/framexml/16650/AutoComplete.lua
		-- /spew GetAutoCompleteResults('t', AUTOCOMPLETE_FLAG_ALL, AUTOCOMPLETE_FLAG_NONE, AUTOCOMPLETE_MAX_BUTTONS+1, 0)
		local include, exclude = parent.autoCompleteParams.include, parent.autoCompleteParams.exclude
		local newResults = { GetAutoCompleteResults(text, include, exclude, AUTOCOMPLETE_MAX_BUTTONS+1, cursorPosition) }
		local character
		for _, charData in pairs(ns.characters) do
			if charData.key ~= thisCharacter then
				character = charData.name
				if string.find(string.lower(character), '^'..string.lower(text)) and not tContains(newResults, character) then
					character = ns.GetColoredCharacterName(charData.key)
					table.insert(newResults, character)
				end
			end
		end
		table.sort(newResults)
		AutoComplete_UpdateResults(AutoCompleteBox, unpack(newResults))

		-- also write out the first match
		local currentText = parent:GetText()
		if newResults[1] and currentText ~= lastQuery then
			lastQuery = currentText
			local newText = string.gsub(currentText, parent.autoCompleteRegex or AUTOCOMPLETE_SIMPLE_REGEX,
				string.format(parent.autoCompleteFormatRegex or AUTOCOMPLETE_SIMPLE_FORMAT_REGEX, newResults[1],
				string.match(currentText, parent.autoCompleteRegex or AUTOCOMPLETE_SIMPLE_REGEX)),
				1)

			parent:SetText( string.match(newText, '|c........(.+)|r') or newText or '' )
			parent:HighlightText(strlen(currentText), strlen(newText))
			parent:SetCursorPosition(strlen(currentText))
		end
	end
end

local function CleanAutoCompleteOutput(self)
	local editBox = self:GetParent().parent
	if not editBox.addSpaceToAutoComplete then
		local newText = string.match(editBox:GetText(), '|c........(.+)|r') or editBox:GetText() or ''
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
