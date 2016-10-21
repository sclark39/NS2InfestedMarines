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

local function OnInfectedStatusMessage(msg)
    if msg.infected then
        ChatUI_AddSystemMessage("YOU ARE INFECTED!!!  Right click marines when close enough (outline = red) to infect them!")
    else
        ChatUI_AddSystemMessage("You are NOT infected!  Repair the air purifiers, and watch the person you're with closely!")
    end
end
Client.HookNetworkMessage("InfectedStatusMessage", OnInfectedStatusMessage)

local function OnInfectedProcessMessage(msg)
    ChatUI_AddSystemMessage("YOU ARE INFECTED!!!  Right click marines when close enough (outline = red) to infect them!")
end
Client.HookNetworkMessage("InfectedProcessMessage", OnInfectedProcessMessage)

