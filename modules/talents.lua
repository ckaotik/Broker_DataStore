local _, Broker_DS = ...
local QTip = LibStub("LibQTip-1.0")

-- GLOBALS: DataStore, HIGHLIGHT_FONT_COLOR_CODE, GRAY_FONT_COLOR_CODE, string
-- GLOBALS: UnitClass, UnitLevel, GetActiveSpecGroup, ToggleTalentFrame, InterfaceOptionsFrame_OpenToCategory

if not IsAddOnLoaded("DataStore_Talents") then return end

-- initialize LDB plugin
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local plugin = LDB:NewDataObject("DataStore_Talents", {
	type	= "data source",
	label	= "Talents",
	text 	= Broker_DS.locale.talents,

	-- dummies as some displays require these
	OnTooltipShow = function() end,
	OnClick = function() end,
})
Broker_DS.talents = plugin

local function CheckTalents(character)
	character = character or DataStore:GetCharacter()

	local _, class = DataStore:GetCharacterClass(character)
	local currentSpec = DataStore:GetActiveTalents(character)
	if not class or not currentSpec then return end

	local primary = DataStore:GetSpecialization(character, 1)
	local secondary = DataStore:GetSpecialization(character, 2)

	local currentSpecIcon = DataStore:GetTreeInfo(class, currentSpec == 1 and primary or secondary)
		or "Interface\\Icons\\INV_MISC_QUESTIONMARK"

	local primaryTree = DataStore:GetTreeNameByID(class, primary)
	local secondaryTree = DataStore:GetTreeNameByID(class, secondary)

	local hasUnspentPrimary = DataStore:GetNumUnspentTalents(character, 1) > 0
	local hasUnspentSecondary = DataStore:GetNumUnspentTalents(character, 2) > 0

	return primaryTree, secondaryTree, currentSpec, currentSpecIcon, hasUnspentPrimary, hasUnspentSecondary
end

function plugin.UpdateLDB()
	local primary, secondary, currentSpec, icon, unspentPrimary, unspentSecondary = CheckTalents()

	local displayIcon = currentSpec and icon or "Interface\\Minimap\\Tracking\\None"
	local displayText = Broker_DS.locale.talents

	if (currentSpec == 1 and unspentPrimary) or (currentSpec == 2 and unspentSecondary) then
		displayText = Broker_DS.locale.talentsUnspent
	elseif primary or secondary then
		displayText = string.format("%s%s%s|r/%s%s%s|r", -- HIGHLIGHT_FONT_COLOR_CODE
			currentSpec == 1 and '' or GRAY_FONT_COLOR_CODE,
			primary or '?',
			unspentPrimary and '*' or '',
			currentSpec == 2 and '' or GRAY_FONT_COLOR_CODE,
			secondary or '?',
			unspentSecondary and '*' or ''
		)
	end

	-- local plugin = LDB:GetDataObjectByName("DataStore_Talents")
	plugin.text = displayText
	plugin.icon = displayIcon
end

-- Managing the module --------------------------------------------------
function plugin:OnTooltipShow()
	-- <self> is a GameTooltip!
	local tooltip = QTip:Acquire("DataStore_Talents", 2, "LEFT", "RIGHT")
		  tooltip:Clear()

	-- self:AddDoubleLine("Broker_DataStore", Broker_DS.locale.talents)
	tooltip:AddHeader("Broker_DataStore", Broker_DS.locale.talents)

	local numChars = #Broker_DS.characters
	if numChars == 0 then
		self:AddLine(Broker_DS.locale.talentsNone)
		return
	end

	local unspent
	for i=1, numChars do
		local character = Broker_DS.characters[i].key
		local primary, secondary, currentSpec, icon, unspentPrimary, unspentSecondary = CheckTalents(character)

		unspent = unspent or unspentPrimary or unspentSecondary

		local textLeft = string.format("|T%s:0|t %s", icon, Broker_DS.GetColoredCharacterName(character))
		local textRight = string.format("%s%s%s|r/%s%s%s|r",
			currentSpec == 1 and NORMAL_FONT_COLOR_CODE or GRAY_FONT_COLOR_CODE,
			primary or '?',
			unspentPrimary and '*' or '',
			currentSpec == 2 and NORMAL_FONT_COLOR_CODE or GRAY_FONT_COLOR_CODE,
			secondary or '?',
			unspentSecondary and '*' or ''
		)

		-- self:AddDoubleLine(textLeft, textRight)
		tooltip:AddLine(textLeft, textRight)
	end

	if unspent then
		-- self:AddLine("* " .. Broker_DS.locale.talentsUnspent)
		tooltip:AddSeparator(2)
		tooltip:AddLine("* "..Broker_DS.locale.talentsUnspent)
	end

	-- Use smart anchoring code to anchor the tooltip to our frame
	local anchor = self:GetOwner()
	tooltip:SmartAnchorTo(anchor)
	tooltip:SetAutoHideDelay(0.25, anchor)
	tooltip:Show()
end

function plugin:OnClick(self, button)
	if button == "RightButton" then
		InterfaceOptionsFrame_OpenToCategory(plugin.options)
	else
		plugin.UpdateLDB()
		ToggleTalentFrame()
	end
end

local init = function()
	plugin:UpdateLDB()
end

-- event frame
local frame = CreateFrame("frame")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("CHARACTER_POINTS_CHANGED")
frame:SetScript("OnEvent", plugin.UpdateLDB)

-- register module
if not Broker_DS.modules then
	Broker_DS.modules = { {plugin, init} }
else
	tinsert(Broker_DS.modules, {plugin, init})
end
