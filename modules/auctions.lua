local _, Broker_DS = ...
local QTip = LibStub("LibQTip-1.0")

-- GLOBALS: DataStore
-- GLOBALS: GetTime, GetInboxNumItems, InterfaceOptionsFrame_OpenToCategory

if not IsAddOnLoaded("DataStore_Auctions") or not IsAddOnLoaded("DataStore_Mails") then
	return
end

Broker_DS.auctions = {}
Broker_DS.auctions.mailKnown = false

local goblinColor = "|cffeeee22"
local auctionPrefix, bidPrefix = "(A) ", "(B) "

function Broker_DS.auctions:GetAuctionStatus(character)
	if not character then
		character = DataStore:GetCharacter()
	end

	local lastVisit = DataStore:GetAuctionHouseLastVisit(character) or 0
	local auctions = DataStore:GetNumAuctions(character) or 0
	local bids = DataStore:GetNumBids(character) or 0

	local auctionsGoblin, bidsGoblin = 0, 0
	for i=1, auctions do
		if DataStore:GetAuctionHouseItemInfo(character, "Auctions", i) then
			auctionsGoblin = auctionsGoblin + 1
		end
	end
	for i=1, bids do
		if DataStore:GetAuctionHouseItemInfo(character, "Bids", i) then
			bidsGoblin = bidsGoblin + 1
		end
	end

	-- #faction auctions, #goblin auctions, #faction bids, #goblin bids, outdated
	return (auctions-auctionsGoblin), auctionsGoblin,
        (bids-bidsGoblin), bidsGoblin,
        GetTime() - lastVisit > 7*24*60*60
end

-- returns information strings to be displayed in tooltip / LDB
function Broker_DS.auctions:CreateDisplayString(character)
    local mailbox
    if not character or character == DataStore:GetCharacter() then
        character = DataStore:GetCharacter()
        mailbox = Broker_DS.auctions.mailKnown and GetInboxNumItems() or DataStore:GetNumMails(character) or 0
    else
        mailbox = DataStore:GetNumMails(character) or 0
    end
    local auctionsFaction, auctionsGoblin, bidsFaction, bidsGoblin, outdated = Broker_DS.auctions:GetAuctionStatus(character)

    local icon
	if (DataStore:GetNumExpiredMails(character, 7) or 0) > 0 then	-- mails that last <7 days count as expired
		icon = "Interface\\RAIDFRAME\\ReadyCheck-NotReady"
	elseif outdated then
		icon = "Interface\\RAIDFRAME\\ReadyCheck-Waiting"
	elseif mailbox > 0 then
		icon = "Interface\\Minimap\\TRACKING\\Mailbox"
	else
		icon = "Interface\\RAIDFRAME\\ReadyCheck-Ready"
	end

    local auctionsString, bidsString
	if auctionsFaction ~= 0 and auctionsGoblin ~= 0 then
		auctionsString = auctionsFaction .. "/" .. goblinColor .. auctionsGoblin .. "|r"
	elseif auctionsFaction ~= 0 then
		auctionsString = auctionsFaction
	elseif auctionsGoblin ~= 0 then
		auctionsString = goblinColor .. auctionsGoblin .. "|r"
	end
	if bidsFaction ~= 0 and auctionsGoblin ~= 0 then
		bidsString = bidsFaction .. "/" .. goblinColor .. bidsGoblin .. "|r"
	elseif bidsFaction ~= 0 then
		bidsString = bidsFaction
	elseif bidsGoblin ~= 0 then
		bidsString = goblinColor .. bidsGoblin .. "|r"
	end

	return auctionsString, bidsString, icon
end

-- Managing the module --------------------------------------------------
-- initialize LDB plugin
local LDB = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("DataStore_Auctions", {
	type	= "data source",
	label	= "Auctions",
	text 	= Broker_DS.locale.auctions,

	-- OnClick defined below
	OnTooltipShow = function(self)
		-- <self> is a GameTooltip!
		local tooltip = QTip:Acquire("DataStore_Auctions", 2, "LEFT", "RIGHT")
			  tooltip:Clear()

		-- self:AddDoubleLine("Broker_DataStore", Broker_DS.locale.auctions)
		tooltip:AddHeader("Broker_DataStore", Broker_DS.locale.auctions)

		local numLines = 0
		for i=1, #Broker_DS.characters do
			local character = Broker_DS.characters[i].key
			local auctionsString, bidsString, icon = Broker_DS.auctions:CreateDisplayString(character)

            if icon ~= "Interface\\RAIDFRAME\\ReadyCheck-Ready" or auctionsString or bidsString then
                local dataString
                if auctionsString and bidsString then
                    dataString = auctionPrefix .. auctionsString .. ", " .. bidPrefix .. bidsString
                elseif not auctionsString and not bidsString then
                    dataString = "-"
                else
                    dataString = (auctionsString and auctionPrefix .. auctionsString or "") ..
                        (bidsString and bidPrefix .. bidsString or "")   -- only one exists, anyway
                end

                -- self:AddDoubleLine("|T"..icon..":0|t " .. Broker_DS.GetColoredCharacterName(character), dataString)
                tooltip:AddLine("|T"..icon..":0|t " .. Broker_DS.GetColoredCharacterName(character), dataString)
				numLines = numLines + 1
            end
		end
		if numLines == 0 then
			-- self:AddLine(Broker_DS.locale.auctionsClear)
			tooltip:AddLine(Broker_DS.locale.auctionsClear)
		end

		-- Use smart anchoring code to anchor the tooltip to our frame
		local anchor = self:GetOwner()
		tooltip:SmartAnchorTo(anchor)
		tooltip:SetAutoHideDelay(0.25, anchor)
		tooltip:Show()
	end
})

function Broker_DS.auctions:UpdateLDB()
	local auctionsString, bidsString, icon = Broker_DS.auctions:CreateDisplayString()

    if auctionsString and bidsString then
        LDB.text = auctionPrefix .. auctionsString .. ", " .. bidPrefix .. bidsString
    elseif auctionsString or bidsString then
        LDB.text = (auctionsString and auctionPrefix .. auctionsString or "")..(bidsString and bidPrefix .. bidsString or "")
    else
        LDB.text = Broker_DS.locale.auctions
    end
    LDB.icon = icon
end

LDB.OnClick = function(self, button)
	if button == "RightButton" then
		InterfaceOptionsFrame_OpenToCategory(Broker_DS.auctions.options)
	else
		Broker_DS.auctions:UpdateLDB()
	end
end

local init = function()
	Broker_DS.auctions:UpdateLDB()
end

-- event frame
local frame = CreateFrame("Frame")
frame:RegisterEvent("AUCTION_HOUSE_CLOSED")
frame:RegisterEvent("AUCTION_HOUSE_SHOW")
frame:RegisterEvent("MAIL_CLOSED")
frame:RegisterEvent("MAIL_SHOW")
frame:SetScript("OnEvent", function(arg1, ...)
	if arg1 == "MAIL_SHOW" then
		Broker_DS.auctions.mailKnown = true
	end
	Broker_DS.auctions:UpdateLDB()
end)

-- register module
if not Broker_DS.modules then
	Broker_DS.modules = { {LDB, init} }
else
	tinsert(Broker_DS.modules, {LDB, init})
end
