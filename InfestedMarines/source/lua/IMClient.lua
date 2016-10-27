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
}

local oldSetAchievement = Client.SetAchievement
function Client.SetAchievement( name )
    if allowedAchievements[name] then
        oldSetAchievement( name )
    end
end