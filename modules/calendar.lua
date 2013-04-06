local _, ns = ...

local function initialize(frame, event, arg1)
	-- DataStore_Agenda
	--[[
		local function _GetNumCalendarEvents(character)
			return #character.Calendar
		end

		local function _GetCalendarEventInfo(character, index)
			local event = character.Calendar[index]
			if event then
				return strsplit("|", event)		-- eventDate, eventTime, title, eventType, inviteStatus
			end
		end
	--]]

	-- ns.UnregisterEvent('ADDON_LOADED', 'init')
end
-- ns.RegisterEvent('ADDON_LOADED', initialize, 'init')
