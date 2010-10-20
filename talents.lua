local _, Broker_DS = ...

if IsAddOnLoaded("DataStore_Talents") then
	Broker_DS.talents = {}
	
	local activeColor, inactiveColor = "|cffFFFFFF", "|cffAAAAAA"
	local talents = {
		primary = {},
		secondary = {}
	}
	
	function Broker_DS.talents:CheckTalents(character)
		local class, level, current
		if not character or character == DataStore:GetCharacter() then
			character = DataStore:GetCharacter()
			_, class = UnitClass("player")
			level = UnitLevel("player")
			current = GetActiveTalentGroup("player")
		else
			_, class = DataStore:GetCharacterClass(character)
			level = DataStore:GetCharacterLevel(character) or 1
			current = DataStore:GetActiveTalents(character) and DataStore:GetActiveTalents(character) or nil
		end
		if not class then return end
		
		local availablePoints
		if level < 10 then
			return nil, nil, 0, nil
		elseif level <= 80 then
			availablePoints = math.floor((level-9)/2 + 1)
		else
			availablePoints = 36 + level - 80
		end
		
		-- scan talents and save raw numbers
		local i, points = 1, nil
		talents.primary.total, talents.secondary.total = 0, 0	-- reset data
		local treeData = DataStore:GetClassTrees(class)
		if treeData then
			for trees in treeData do
				points = tonumber(DataStore:GetNumPointsSpent(character, trees, 1) or 0)
				talents.primary[i] = points
				talents.primary.total = talents.primary.total + points
			
				points = tonumber(DataStore:GetNumPointsSpent(character, trees, 2) or 0)
				talents.secondary[i] = points
				talents.secondary.total = talents.secondary.total + points
			
				i = i+1
			end
		end
		
		-- calculate which one our main tree is
		local mainTree = math.max(talents.primary[1] or 0, talents.primary[2] or 0, talents.primary[3] or 0)
		local primary = (mainTree == 0 and -1) 
			or (mainTree == talents.primary[1] and 1) or (mainTree == talents.primary[2] and 2) or (mainTree == talents.primary[3] and 3)
		
		mainTree = math.max(talents.secondary[1] or 0, talents.secondary[2] or 0, talents.secondary[3] or 0)
		local secondary = (mainTree == 0 and -1) 
			or (mainTree == talents.secondary[1] and 1) or (mainTree == talents.secondary[2] and 2) or (mainTree == talents.secondary[3] and 3)
		
		-- if class is known, use proper tree name
		local primaryName, secondaryName
		if class ~= "" and type(class) == "string" then
			if primary > 0 then
				primaryName = DataStore:GetTreeNameByID(class, primary)
			end
			primary = primaryName or "-"
			
			if secondary > 0 then
				secondaryName = DataStore:GetTreeNameByID(class, secondary)
			end
			secondary = secondaryName or "-"
		else
			primary_result = talents.primary[1] .. "/" .. talents.primary[2] .. "/" .. talents.primary[3]
			secondary_result = talents.secondary[1] .. "/" .. talents.secondary[2] .. "/" .. talents.secondary[3]
		end
		
		-- return a pretty icon of the currently active talent spec
		local icon = "Interface\\Icons\\Inv_misc_questionmark"
		if current == 1 and primaryName then
			icon = DataStore:GetTreeInfo(class, primaryName)
		elseif current == 2 and secondaryName then
			icon = DataStore:GetTreeInfo(class, secondaryName)
		end
		
		-- notify of unspent talent points
		if talents.primary.total < availablePoints then
			primary = primary .. "*"
		end
		if talents.secondary.total ~= 0 and talents.secondary.total < availablePoints then
			secondary = secondary .. "*"
		end
		
		return primary, secondary, current, icon
	end
	
	-- Managing the module --------------------------------------------------
	-- initialize LDB plugin
	local LDB = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("DataStore_Talents", {
		type	= "data source",
		label	= "Talents",
		text 	= Broker_DS.locale.talents,
		
		-- OnClick defined below
		OnTooltipShow = function(self)
			self:AddDoubleLine("Broker_DataStore", Broker_DS.locale.talents)
			
			local character, primary, secondary
			local unspent = false
			local numChars = #Broker_DS.characters
			for i=1, numChars do
				character = Broker_DS.characters[i].key
				primary, secondary, current, icon = Broker_DS.talents:CheckTalents(character)
				
				if primary then
					if string.find(primary, "*") or string.find(secondary, "*") then
						unspent = true
					end
					if current == 1 then
						primary = activeColor .. primary .. "|r"
						secondary = inactiveColor .. secondary .. "|r"
					else
						primary = inactiveColor .. primary .. "|r"
						secondary = activeColor .. secondary .. "|r"
					end
					
					self:AddDoubleLine("|T"..icon..":0|t " .. Broker_DS:GetColoredCharacterName(character), primary.."/"..secondary)
				else
					-- ignore: this character can't use talents yet
				end
			end
			if numChars == 0 then
				self:AddLine(Broker_DS.locale.talentsNone)
			elseif unspent then
				self:AddLine("* " .. Broker_DS.locale.talentsUnspent)
			end
		end
	})
	
	function Broker_DS.talents:UpdateLDB()
		local primary, secondary, current, icon = Broker_DS.talents:CheckTalents()
		
		if current == 0 then
			-- character has no talents (yet)
			LDB.icon = "Interface\\Minimap\\Tracking\\None"
			LDB.text = Broker_DS.locale.talents
			return
		end
		
		if (current == 1 and string.find(primary, "*")) or (current == 2 and string.find(secondary, "*")) then
			LDB.text = Broker_DS.locale.talentsUnspent
		elseif current == 1 then
			LDB.text = activeColor .. primary .. "|r/" .. inactiveColor .. secondary .. "|r"
		else
			LDB.text = inactiveColor .. primary .. "|r/" .. activeColor .. secondary .. "|r"
		end
		LDB.icon = icon
	end
	
	LDB.OnClick = function(self, button)
        if button == "RightButton" then
            InterfaceOptionsFrame_OpenToCategory(Broker_DS.talents.options)
        else
			Broker_DS.talents:UpdateLDB()
            ToggleTalentFrame()
        end
	end
	
	local init = function()
		Broker_DS.talents:UpdateLDB()
	end
	
	-- event frame
	local frame = CreateFrame("frame")
	frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	frame:RegisterEvent("PLAYER_TALENT_UPDATE")
	frame:RegisterEvent("CHARACTER_POINTS_CHANGED")
	frame:SetScript("OnEvent", Broker_DS.talents.UpdateLDB)
	
	-- register module
	if not Broker_DS.modules then
		Broker_DS.modules = { {LDB, init} }
	else
		tinsert(Broker_DS.modules, {LDB, init})
	end
end