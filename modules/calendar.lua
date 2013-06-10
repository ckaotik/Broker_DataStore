local addonName, ns, _ = ...
-- GLOBALS: _G, DataStore, GameTooltip, NORMAL_FONT_COLOR, HIGHLIGHT_FONT_COLOR, GREEN_FONT_COLOR, RED_FONT_COLOR, ORANGE_FONT_COLOR, CALENDAR_FIRST_WEEKDAY, CALENDAR_WEEKDAY_NAMES, CALENDAR_FULLDATE_MONTH_NAMES, FULLDATE, CALENDAR_INVITESTATUS_CONFIRMED, CALENDAR_INVITESTATUS_ACCEPTED, CALENDAR_INVITESTATUS_SIGNEDUP, CALENDAR_INVITESTATUS_STANDBY, CALENDAR_INVITESTATUS_TENTATIVE, CALENDAR_INVITESTATUS_DECLINED, CALENDAR_INVITESTATUS_OUT
-- GLOBALS: hooksecurefunc, IsAddOnLoaded, CalendarGetMonth, CalendarGetNumDayEvents, CalendarGetDayEvent, GameTime_GetFormattedTime, CalendarFrame_SetSelectedEvent
-- GLOBALS: print, wipe, pairs, ipairs, tonumber, string, table

-- DayButton constants
local CALENDAR_DAYBUTTON_MAX_VISIBLE_EVENTS   = 4
local CALENDAR_DAYBUTTON_MAX_VISIBLE_BIGEVENTS  = 2
-- DayEventButton constants
local CALENDAR_DAYEVENTBUTTON_HEIGHT  = 12
local CALENDAR_DAYEVENTBUTTON_BIGHEIGHT = 24
local CALENDAR_DAYEVENTBUTTON_XOFFSET = 4
local CALENDAR_DAYEVENTBUTTON_YOFFSET = -3
-- date constants
local CALENDAR_FULLDATE_MONTH_NAMES = {
	FULLDATE_MONTH_JANUARY,
	FULLDATE_MONTH_FEBRUARY,
	FULLDATE_MONTH_MARCH,
	FULLDATE_MONTH_APRIL,
	FULLDATE_MONTH_MAY,
	FULLDATE_MONTH_JUNE,
	FULLDATE_MONTH_JULY,
	FULLDATE_MONTH_AUGUST,
	FULLDATE_MONTH_SEPTEMBER,
	FULLDATE_MONTH_OCTOBER,
	FULLDATE_MONTH_NOVEMBER,
	FULLDATE_MONTH_DECEMBER,
}

local thisCharacter = DataStore:GetCharacter()
local additionalEvents = {}

local function GetEventColor(status)
	if status == CALENDAR_INVITESTATUS_CONFIRMED
		or status == CALENDAR_INVITESTATUS_ACCEPTED
		or status ==CALENDAR_INVITESTATUS_SIGNEDUP then
		return GREEN_FONT_COLOR
	elseif status == CALENDAR_INVITESTATUS_STANDBY
		or status == CALENDAR_INVITESTATUS_TENTATIVE then
		return ORANGE_FONT_COLOR
	elseif status == CALENDAR_INVITESTATUS_DECLINED
		or status == CALENDAR_INVITESTATUS_OUT then
		return RED_FONT_COLOR
	else
		return NORMAL_FONT_COLOR
	end
end

local function DayOnEnter(self)
	local events = additionalEvents[ self:GetID() ]
	if GameTooltip:IsVisible() or #events > 0 then
		if not GameTooltip:IsVisible() then
			-- add date if we hit our first viewable event
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        	GameTooltip:ClearLines()

			local weekday = (self:GetID() - 2 + CALENDAR_FIRST_WEEKDAY)%7 + 1
			local month, year = CalendarGetMonth(self.monthOffset)
			local day = self.day
			local monthName = CALENDAR_FULLDATE_MONTH_NAMES[month]
			weekday = CALENDAR_WEEKDAY_NAMES[weekday]

			local fullDate = string.format(FULLDATE, weekday, monthName, day, year, month)
			GameTooltip:AddLine(fullDate, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
			GameTooltip:AddLine(" ")
		end

		for _, event in ipairs(events) do
			local eventColor = GetEventColor(tonumber(event[6]))
			GameTooltip:AddDoubleLine(
				string.format('%s %s', ns.GetColoredCharacterName(event[1]), event[4]),
				GameTime_GetFormattedTime(tonumber(event[2]), tonumber(event[3]), true),
				eventColor.r, eventColor.g, eventColor.b,
				HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b,
				1
			)
		end
		GameTooltip:Show()
	end
end

local function UpdateDayEvents(index, day, monthOffset, selectedEventIndex, contextEventIndex)
	if not IsAddOnLoaded('DataStore_Agenda') then return end
	local month, year = CalendarGetMonth(monthOffset)
	local thisDate = string.format("%04d-%02d-%02d", year, month, day)

	if not additionalEvents[index] then
		additionalEvents[index] = {}
	else
		wipe(additionalEvents[index])
	end

	local eventDate, eventTime, eventType, eventStatus, hours, minutes, title
	for _, character in pairs(ns.characters) do
		if character.key ~= thisCharacter then
			local numEvents = DataStore:GetNumCalendarEvents(character.key)
			for i = 1, numEvents do
				eventDate, eventTime, title, eventType, eventStatus = DataStore:GetCalendarEventInfo(character.key, i)
				if eventDate == thisDate then
					hours, minutes = string.split(':', eventTime)
					table.insert(additionalEvents[index],
						{character.key, tonumber(hours), tonumber(minutes), title, tonumber(eventType), tonumber(eventStatus)})
				end
			end
		end
	end
	local numAdditionalEvents = #additionalEvents[index]
	if numAdditionalEvents == 0 then return end

	local dayButtonName = 'CalendarDayButton'..index
	local dayButton = _G[dayButtonName]
	local numEvents = dayButton.numViewableEvents -- CalendarGetNumDayEvents(monthOffset, day)
	local numViewableEvents = numEvents + numAdditionalEvents

	local showingBigEvents = numViewableEvents <= CALENDAR_DAYBUTTON_MAX_VISIBLE_BIGEVENTS
	local buttonHeight = CALENDAR_DAYEVENTBUTTON_BIGHEIGHT
	local text2Point = 'BOTTOMLEFT'
	local text2JustifyH = 'LEFT'
	local text1RelPoint = nil
	if numViewableEvents > 0 and not showingBigEvents then
		if numViewableEvents > CALENDAR_DAYBUTTON_MAX_VISIBLE_EVENTS then
			_G[dayButtonName..'MoreEventsButton']:Show()
		end
		buttonHeight = CALENDAR_DAYEVENTBUTTON_HEIGHT
		text1RelPoint, text2Point, text2JustifyH = 'BOTTOMLEFT', 'RIGHT', 'RIGHT'
	end

	local eventIndex, eventButtonIndex = 1, 1
	local eventButton, eventButtonName, event, prevEventButton, firstEventButton
	local eventButtonText1, eventButtonText2
	while eventButtonIndex <= CALENDAR_DAYBUTTON_MAX_VISIBLE_EVENTS and eventIndex <= numEvents + numAdditionalEvents do
		eventButtonName = dayButtonName..'EventButton'..eventButtonIndex
		eventButton = _G[eventButtonName]
		eventButtonText1 = _G[eventButtonName..'Text1']
		eventButtonText2 = _G[eventButtonName..'Text2']

		local title, hour, minute, calendarType, sequenceType, eventType, texture, modStatus, inviteStatus, invitedBy
		if eventButtonIndex <= numEvents then
			title, hour, minute = CalendarGetDayEvent(monthOffset, day, eventIndex)
		else
			event = additionalEvents[index][ eventIndex - numEvents ]
			title, hour, minute, calendarType, sequenceType, eventType, texture, modStatus, inviteStatus, invitedBy = event[4], event[2], event[3], nil, nil, event[5], 'notex', nil, event[6], ns.GetColoredCharacterName(event[1])
		end

		-- adjust sizing if needed
		eventButton:SetHeight(buttonHeight)
		eventButtonText2:SetText(GameTime_GetFormattedTime(hour, minute, showingBigEvents))
		eventButtonText2:ClearAllPoints()
		eventButtonText2:SetPoint(text2Point, eventButton, text2Point) --
		eventButtonText2:SetJustifyH(text2JustifyH) --
		eventButtonText2:Show()
		eventButtonText1:ClearAllPoints()
		eventButtonText1:SetPoint("TOPLEFT", eventButton, "TOPLEFT")
		if text1RelPoint then --
		  eventButtonText1:SetPoint("BOTTOMRIGHT", eventButtonText2, text1RelPoint)
		end

		-- anchor the event button
		eventButton:SetPoint("BOTTOMLEFT", dayButton, "BOTTOMLEFT", CALENDAR_DAYEVENTBUTTON_XOFFSET, -CALENDAR_DAYEVENTBUTTON_YOFFSET)
		if prevEventButton then
			-- anchor the prev event button to this one...this makes the latest event stay at the bottom
			prevEventButton:SetPoint("BOTTOMLEFT", eventButton, "TOPLEFT", 0, -CALENDAR_DAYEVENTBUTTON_YOFFSET)
		else
			firstEventButton = eventButton
		end
		prevEventButton = eventButton

		if eventButtonIndex > numEvents then
			-- our custom events
			eventButton.eventIndex = nil
			eventButtonText1:SetFormattedText('%s (%s)', title, invitedBy)
			local eventColor = GetEventColor(tonumber(event[6]))
			eventButtonText1:SetTextColor(eventColor.r, eventColor.g, eventColor.b)
			eventButtonText1:Show()

			if not eventButton.touched then
				local orig_OnClick = eventButton:GetScript('OnClick')
				eventButton:SetScript('OnClick', function(self, btn)
					if not self.eventIndex then
						CalendarFrame_CloseEvent()
						CalendarDayButton_OnClick(self, button)
					else
						orig_OnClick(self, btn)
					end
				end)
				eventButton.touched = true
			end

			-- highlight the selected event
			-- CalendarFrame_SetSelectedEvent(eventButton)
			eventButton:UnlockHighlight()
			eventButton:Show()
		end

		eventIndex = eventIndex + 1
		eventButtonIndex = eventButtonIndex + 1
	end

	-- hide unused event buttons
	while eventButtonIndex <= CALENDAR_DAYBUTTON_MAX_VISIBLE_EVENTS do
		eventButton = _G[dayButtonName.."EventButton"..eventButtonIndex]
		eventButton.eventIndex = nil
		eventButton:Hide()
		eventButtonIndex = eventButtonIndex + 1
	end

	if numEvents == 0 then
		-- black shadow so it's easier to read
		local eventBackground = _G[dayButtonName.."EventBackgroundTexture"]
			  eventBackground:SetPoint("TOP", firstEventButton, "TOP", 0, 40);
			  eventBackground:SetPoint("BOTTOM", dayButton, "BOTTOM")
			  eventBackground:Show()

		--[[local eventTex = _G[dayButtonName.."EventTexture"]
		eventTex:SetTexture("Interface\\Calendar\\UI-Calendar-Event-Other")
		eventTex:SetTexCoord(0,1,0,1)
		eventTex:Show()--]]
	end
end


-- TODO: add our events to more-button
local function initialize(frame, event, arg1)
	if arg1 == 'Blizzard_Calendar' then
		hooksecurefunc('CalendarFrame_UpdateDayEvents', UpdateDayEvents)
		hooksecurefunc('CalendarDayButton_OnEnter', DayOnEnter)

		ns.UnregisterEvent('ADDON_LOADED', 'calendar')
	end
end
ns.RegisterEvent('ADDON_LOADED', initialize, 'calendar')
