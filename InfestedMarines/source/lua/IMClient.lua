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

local function SwitchToObjectives(type)
    
    local player = Client.GetLocalPlayer()
    
    if type == "marine" then
        if not player.marineObjDisplayed then
            player.marineObjDisplayed = true
            GetMarineObjectivePanel():AnimateIn()
            GetMarineObjectivePanel():SetVisibility(true)
        end
        
        if player.alienObjDisplayed then
            player.alienObjDisplayed = false
            GetAlienObjectivePanel():AnimateOut()
        end
    elseif type == "alien" then
        if not player.alienObjDisplayed then
            player.alienObjDisplayed = true
            GetAlienObjectivePanel():AnimateIn()
            GetAlienObjectivePanel():SetVisibility(true)
        end
        
        if player.marineObjDisplayed then
            player.marineObjDisplayed = false
            GetMarineObjectivePanel():AnimateOut()
        end
    end
    
end

local function SetObjectives(text, type)
    
    local player = Client.GetLocalPlayer()
    local display = nil
    
    if type == "marine" or type == "alien" then
        SwitchToObjectives(type)
    end
    
    if not player.marineObjDisplayed and not player.alienObjDisplayed then
        SwitchToObjectives("marine")
    end
    
    display = player.marineObjDisplayed and GetMarineObjectivePanel() or GetAlienObjectivePanel()
    
    if not display then
        Log("couldn't set objectives for player %s", player)
        return
    end
    
    display:SetText(text)
    
end

local function OnInfectedStatusMessage(msg)
    
    if msg.infected then
        SetObjectives("You are infested!\nRight-click marines when close enough (outline turns red) to infest them.  Pretend you're uninfested to avoid suspicion, but you will starve to death soon if you do not infest more humans!", "alien")
    else
        SetObjectives("You are not infested!  One or more of your \"friends\" however, are.  Watch each other closely.  Infestation is spreading throughout the facility and poisoning the air!  Clear the infestation and repair the Air Purifiers before the air becomes lethal!", "marine")
    end
end
Client.HookNetworkMessage("InfectedStatusMessage", OnInfectedStatusMessage)

local function OnInfectedProcessMessage(msg)
    SetObjectives("You have been infested!\nRight-click marines when close enough (outline turns red) to infest them.  Pretend you're uninfested to avoid suspicion, but you will starve to death soon if you do not infest more humans!", "alien")
end
Client.HookNetworkMessage("InfectedProcessMessage", OnInfectedProcessMessage)

local function OnRoundStartMessage(msg)
    SetObjectives("Infestation is taking over the facility; the air is becoming toxic!  Repair the Air Purifiers before the air becomes lethal.  We cannot lose this facility!\n\n(Infested has not yet been chosen.)", "marine")
end
Client.HookNetworkMessage("RoundStartMessage", OnRoundStartMessage)
