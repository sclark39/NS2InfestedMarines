-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMClient.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Handles all the client-only functionality of the infested marines mod.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/IMGUIAirStatus.lua")
Script.Load("lua/IMGUIAirPurifierStatus.lua")
Script.Load("lua/IMGUIAirPurifierManager.lua")
Script.Load("lua/IMGUIObjectivesMarine.lua")
Script.Load("lua/IMGUIObjectivesAlien.lua")
Script.Load("lua/IMGUIInfestedFeedTimer.lua")
Script.Load("lua/IMGUIInfestedOverlay.lua")
Script.Load("lua/KeybindDisplayManager.lua") -- activate the built-in keybind display functionality.

--map of achievements that are available in this gamemode
local allowedAchievements =
{
    ["Season_0_1"] = true,
    ["Season_0_2"] = true,
    ["Season_0_3"] = true,
    ["Short_2_5"] = true, -- Quality Assurance
    ["Long_0_2"] = true, -- Arcade Champion
}

local oldSetAchievement = Client.SetAchievement
function Client.SetAchievement( name )
    if allowedAchievements[name] then
		local alreadyHas = Client.GetAchievement(name)
        oldSetAchievement( name )

        if not alreadyHas and name == "Season_0_1" then
            Client.GrantPromoItems()
            InventoryNewItemNotifyPush( kHalloween16ShoulderPatchItemId )
        end
    end
end