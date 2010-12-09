local _, Broker_DS = ...

local function Initialize()
	-- initialize saved variables
	if not BDS_GlobalDB then BDS_GlobalDB = {} end
	if not BDS_LocalDB then BDS_LocalDB = {} end
	
	-- initialize modules
	local initFunc
	for _, tab in pairs(Broker_DS.modules or {}) do
		-- run module's init function
		initFunc = tab[2]
		if initFunc then
			initFunc()
		end
	end
	Broker_DS.frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

Broker_DS.frame = CreateFrame("Frame", "Broker_DataStore", UIParent)
Broker_DS.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
Broker_DS.frame:SetScript("OnEvent", Initialize)

-- -------------------------------------------------------------------------------------------
-- characters database, sorted, for nice display
Broker_DS.characters = {}
for characterName, characterKey in pairs(DataStore:GetCharacters()) do
   tinsert(Broker_DS.characters, { name = characterName, key = characterKey })
end
table.sort(Broker_DS.characters, function(a,b)
	return a.name < b.name
end)

if IsAddOnLoaded("DataStore_Characters") then
	Broker_DS.GetColoredCharacterName = DataStore.GetColoredCharacterName
	Broker_DS.GetFaction = DataStore.GetCharacterFaction
else
	Broker_DS.GetColoredCharacterName = function(characterKey)
		local _, _, characterName = strsplit(".", characterKey)
		return characterName
	end
	Broker_DS.GetFaction = function()
		return UnitFactionGroup("player")
	end
end

-- helper functions
function Broker_DS:Print(text)
	DEFAULT_CHAT_FRAME:AddMessage("|cffee6622Broker_DataStore|r "..text)
end

-- reformats long numbers to shorter ones: 12403 => 12.4k
function Broker_DS:ShortenNumber(value, minAccuracy)
	if not value or (value and not type(value) == "number" and not tonumber(value)) then
		Broker_DS:Print("Error: Invalid argument to ShortenNumber. "..(value or "nil").." supplied.")
		return nil
	end
	
	if value >= 1000000 then
		return string.format("%.1fm", value/1000000)
	elseif value >= math.pow(10, minAccuracy or 3) then
		return string.format("%.1fk", value/1000)
	else
		return value
	end
end