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

--map of achievements that are available in this gamemode
local allowedAchievements =
{
    "Season_0_1",
    "Season_0_2",
    "Season_0_3"
}

local oldSetAchievement = Client.SetAchievement
function Client.SetAchievement( name )
    if allowedAchievements[name] then
        oldSetAchievement( name )

        if name == "Season_0_1" then
            Client.GrantPromoItems()
            InventoryNewItemNotifyPush( kHalloween16ShoulderPatchItemId )
        end
    end
end