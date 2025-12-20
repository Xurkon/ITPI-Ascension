--[[
    ItemTooltipProfessionIcons (Ascension Edition)
    Original Author: Bytespire
    Backported & Modified by: Xurkon
    
    This addon displays profession and quest requirement icons on item tooltips.
    Backported specifically for the Project Ascension environment.
]]--

local frame = CreateFrame( "Frame" )

-- Cache for performance and avoids redundant tooltip processing
local previousItemID = -1
local itemIcons = ""
local iconSize

-- Reference constants from the global table
local ITEM_DMF_FLAG = ItemProfConstants.DMF_ITEM_FLAG
local ITEM_PROF_FLAGS = ItemProfConstants.ITEM_PROF_FLAGS
local QUEST_FLAG = ItemProfConstants.QUEST_FLAG
local NUM_PROFS_TRACKED = ItemProfConstants.NUM_PROF_FLAGS
local PROF_TEXTURES = ItemProfConstants.PROF_TEXTURES

-- Local state variables (synced via ConfigChanged)
local showProfs
local showQuests
local profFilter
local questFilter
local showDMF

-- Initialize realm/char tracking for character-specific settings
ItemProfConstants.configTooltipIconsRealm = nil
ItemProfConstants.configTooltipIconsChar = nil
ItemProfConstants.DebugEnabled = false

-- Function to generate the texture string for a given item's flags
local function CreateItemIcons( itemFlags )
	
	local t = {}
	
	-- Profession Icons
	if showProfs then
		local enabledFlags = bit.band( itemFlags, profFilter )
		for i=0, NUM_PROFS_TRACKED-1 do
			local bitMask = bit.lshift( 1, i )
			local isSet = bit.band( enabledFlags, bitMask )
			if isSet ~= 0 then
				local tex = ItemProfConstants:GetTexture( bitMask )
				if tex then
					t[ #t+1 ] = "|T"
					t[ #t+1 ] = tex
					t[ #t+1 ] = ":"
					t[ #t+1 ] = iconSize
					t[ #t+1 ] = "|t "
				end
			end
		end
	end
	
	-- Darkmoon Faire Icons
	if showDMF then
		local isTicketItem = bit.band( itemFlags, ITEM_DMF_FLAG )
		if isTicketItem ~= 0 then
			local tex = ItemProfConstants:GetTexture( ITEM_DMF_FLAG )
			if tex then
				t[ #t+1 ] = "|T"
				t[ #t+1 ] = tex
				t[ #t+1 ] = ":"
				t[ #t+1 ] = iconSize
				t[ #t+1 ] = "|t "
			end
		end
	end
	
	-- Quest Icons
	if showQuests then
		-- Quest filter flags start at 0x400 (bit 10). Shift to align for simplified bitwise checks.
		local questFlags = bit.rshift( itemFlags, 10 )
		local isSet = bit.band( questFlags, questFilter )
		
		-- Faction-specific filtering logic
		local isFactionQuest = bit.band( questFlags, 0x06 )
		if isFactionQuest ~= 0 then
			local isFactionEnabled = bit.band( isFactionQuest, questFilter )
			local showFaction = bit.band( isFactionQuest, isFactionEnabled )
			if showFaction == 0 then
				isSet = 0
			end
			
			-- Multi-requirement checks (Faction + Class/Prof)
			if isSet < 0x08 and questFlags >= 0x08 then
				isSet = 0
			end
		end
		
		if isSet ~= 0 then
			local tex = ItemProfConstants:GetTexture( QUEST_FLAG )
			if tex then
				t[ #t+1 ] = "|T"
				t[ #t+1 ] = tex
				t[ #t+1 ] = ":"
				t[ #t+1 ] = iconSize
				t[ #t+1 ] = "|t "
			end
		end
	end

	return table.concat( t )
end


-- Main tooltip modification function
local function ModifyItemTooltip( tt ) 
		
	local itemName, itemLink = tt:GetItem() 
	if not itemName or not itemLink then return end

    -- Technical Note: Extraction from link is more reliable in 3.3.5a than GetItemInfo(name)
    -- especially for uncached auction house items.
    local itemID = tonumber( string.match( itemLink, "item:(%d+)" ) )
	
	if not itemID then
		return
	end

    -- Ensure we have the current realm/char for settings lookup
    if not ItemProfConstants.configTooltipIconsRealm or ItemProfConstants.configTooltipIconsRealm == "" then
        local realm = GetRealmName()
        local char = UnitName("player")
        if realm and realm ~= "" and char and char ~= "" then
            ItemProfConstants.configTooltipIconsRealm = realm
            ItemProfConstants.configTooltipIconsChar = char
        end
    end

    -- Lazy load config if it hasn't been accessed yet
    if showProfs == nil then
        if ItemTooltipIconsConfig and ItemProfConstants.configTooltipIconsRealm and ItemTooltipIconsConfig[ ItemProfConstants.configTooltipIconsRealm ] then
            ItemProfConstants:ConfigChanged()
        else
            -- Robust Fallbacks: ensure icons show even if config frames fail to initialize
            showProfs = true
            showQuests = true
            profFilter = 0x3FF
            questFilter = 0x3FFFFF
            iconSize = 16
            showDMF = true
        end
    end
	
    if ItemProfConstants.DebugEnabled then
        DEFAULT_CHAT_FRAME:AddMessage("ITPI DEBUG: Hovering " .. itemName .. " (ID: " .. itemID .. ")")
    end

	-- Efficient caching: skip regeneration if we're looking at the same item
	if previousItemID == itemID then
		if itemIcons ~= "" then
			tt:AddLine( itemIcons )
		end
		return
	end
	
	-- Verify if the current item exists in the profession database
	local itemFlags = ITEM_PROF_FLAGS[ itemID ]
	if itemFlags == nil then
        if ItemProfConstants.DebugEnabled then
            DEFAULT_CHAT_FRAME:AddMessage("ITPI DEBUG: No flags for item " .. itemID)
        end
		return
	end
	
    if ItemProfConstants.DebugEnabled then
        DEFAULT_CHAT_FRAME:AddMessage("ITPI DEBUG: Found flags for item " .. itemID)
    end

	-- Generate and apply icons
	previousItemID = itemID
	itemIcons = CreateItemIcons( itemFlags )
	
	if itemIcons and itemIcons ~= "" then
		tt:AddLine( itemIcons )
	end
end


-- Centralized configuration sync
-- Updates local state from SavedVariables
function ItemProfConstants:ConfigChanged()
    local realm = self.configTooltipIconsRealm
    local char = self.configTooltipIconsChar
    
    if not realm or not char or realm == "" or char == "" then return end

    -- Initialize the table structure if missing (New User Protection)
    if not ItemTooltipIconsConfig then ItemTooltipIconsConfig = {} end
    if not ItemTooltipIconsConfig[realm] then ItemTooltipIconsConfig[realm] = {} end
    if not ItemTooltipIconsConfig[realm][char] then 
        ItemTooltipIconsConfig[realm][char] = {
            showProfs = true,
            showQuests = true,
            profFlags = 0x3FF,
            questFlags = 0x3FFFFF,
            iconSize = 16,
            showDMF = true
        }
    end

    local cfg = ItemTooltipIconsConfig[realm][char]
	showProfs = cfg.showProfs
	showQuests = cfg.showQuests
	profFilter = cfg.profFlags
	questFilter = cfg.questFlags
	iconSize = cfg.iconSize
	showDMF = cfg.showDMF
	
	previousItemID = -1		-- Reset cache to force refresh with new settings
end


-- Register hooks for all relevant tooltips
-- Note: HookScript is safer than direct prototype overrides in 3.3.5a
local function InitFrame()
	GameTooltip:HookScript( "OnTooltipSetItem", ModifyItemTooltip )
	ItemRefTooltip:HookScript( "OnTooltipSetItem", ModifyItemTooltip )
    
    if ShoppingTooltip1 then ShoppingTooltip1:HookScript("OnTooltipSetItem", ModifyItemTooltip) end
    if ShoppingTooltip2 then ShoppingTooltip2:HookScript("OnTooltipSetItem", ModifyItemTooltip) end
    if WorldMapTooltip then WorldMapTooltip:HookScript("OnTooltipSetItem", ModifyItemTooltip) end
end


-- Execute core initialization
InitFrame()

-- Trigger config population once player is in world
local function PopulateConfig()
    if not ItemProfConstants.configTooltipIconsRealm then
        ItemProfConstants.configTooltipIconsRealm = GetRealmName()
        ItemProfConstants.configTooltipIconsChar = UnitName("player")
    end
    ItemProfConstants:ConfigChanged()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:SetScript("OnEvent", function()
    PopulateConfig()
    loader:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)

-- Slash Command Handler
SLASH_ITEMTOOLTIPPROFICON1 = "/itpi"
SlashCmdList["ITEMTOOLTIPPROFICON"] = function(msg)
    if msg == "test" then
        local dbCount = 0
        for _ in pairs(ItemProfConstants.ITEM_PROF_FLAGS or {}) do dbCount = dbCount + 1 end
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00ITPI Test:|r")
        DEFAULT_CHAT_FRAME:AddMessage("- Realm: " .. (ItemProfConstants.configTooltipIconsRealm or "nil"))
        DEFAULT_CHAT_FRAME:AddMessage("- Char: " .. (ItemProfConstants.configTooltipIconsChar or "nil"))
        DEFAULT_CHAT_FRAME:AddMessage("- showProfs: " .. (showProfs and "true" or "false"))
        DEFAULT_CHAT_FRAME:AddMessage("- Database Items: " .. dbCount)
        DEFAULT_CHAT_FRAME:AddMessage("- Debug Mode: " .. (ItemProfConstants.DebugEnabled and "ON" or "OFF"))
    elseif msg == "debug" then
        ItemProfConstants.DebugEnabled = not ItemProfConstants.DebugEnabled
        DEFAULT_CHAT_FRAME:AddMessage("ITPI Debug: " .. (ItemProfConstants.DebugEnabled and "ON" or "OFF"))
    else
        -- 3.3.5a Best Practice: OpenToCategory using string name
        InterfaceOptionsFrame_OpenToCategory("ItemTooltipProfessionIcons")
        InterfaceOptionsFrame_OpenToCategory("ItemTooltipProfessionIcons")
    end
end
