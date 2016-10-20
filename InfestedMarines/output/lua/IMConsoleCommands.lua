-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMConsoleCommands.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Handles all the commands associated with the infested marines gamemode.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Shared.RegisterNetworkMessage("IMSetAutomationState", { state = "boolean", })
Shared.RegisterNetworkMessage("IMSetLives", { lives = "integer", })
Shared.RegisterNetworkMessage("IMDamageExtractor", { pur = "entityid", duration = "float" })
Shared.RegisterNetworkMessage("IMInfectPlayer", {})

if Client then
    
    local function OnConsoleAutomate(state)
        if not (Shared.GetCheatsEnabled() or Shared.GetTestsEnabled()) then
            Log("Cheats or debug testing must be enabled to use this command")
            return
        end
        
        state = state and tonumber(state) or 1
        
        if state == 1 then
            Client.SendNetworkMessage("IMSetAutomationState", { state = true }, true)
            Log("Enabling automated extractor damaging")
        elseif state == 0 then
            Client.SendNetworkMessage("IMSetAutomationState", { state = false }, true)
            Log("Disabling automated extractor damaging")
        else
            Log("Unknown parameter.  Use iautomate 1 to enable automatic gamemaster, or iautomate 0 to enable human gamemaster.")
        end
    end
    
    local function OnConsoleSetLives(lives)
        if not (Shared.GetCheatsEnabled() or Shared.GetTestsEnabled()) then
            Log("Cheats or debug testing must be enabled to use this command")
            return
        end
        
        lives = lives and tonumber(lives) or 5
        
        if lives > 0 then
            Client.SendNetworkMessage("IMSetLives", { lives = lives, }, true)
            Log("Setting max lives and lives to %s", lives)
        else
            Log("max lives must be > 0")
        end
    end
    
    local function GetPlayerPosition(player)
        if HasMixin(player, "OverheadMove") then
            return player:GetOrigin() + player:GetViewCoords().zAxis * 11.706
        end
        
        return player:GetOrigin()
    end
    
    local function OnConsoleAddPurifier(duration)
        if not (Shared.GetCheatsEnabled() or Shared.GetTestsEnabled()) then
            Log("Cheats or debug testing must be enabled to use this command")
            return
        end
        
        local player = Client.GetLocalPlayer()
        if not player then
            return
        end
        
        duration = duration and tonumber(duration) or 60
        
        local nearbyExtractors = GetEntitiesWithinRange("Extractor", GetPlayerPosition(player), 30)
        Shared.SortEntitiesByDistance(GetPlayerPosition(player), nearbyExtractors)
        
        for i=1, #nearbyExtractors do
            local extractor = nearbyExtractors[i]
            if extractor then
                Log("Damaging extractor %s", extractor)
                Client.SendNetworkMessage("IMDamageExtractor", {pur = extractor:GetId(), duration = duration}, true)
                return
            end
        end
    end
    
    local function OnConsoleInfect()
        if not (Shared.GetCheatsEnabled() or Shared.GetTestsEnabled()) then
            Log("Cheats or debug testing must be enabled to use this command")
            return
        end
        
        local player = Client.GetLocalPlayer()
        if player and player:isa("Marine") then
            Client.SendNetworkMessage("IMInfectPlayer", {}, true)
            Log("You are now infected!")
        else
            Log("You must be a marine to infect yourself!")
        end
    end
    
    Event.Hook("Console_idmg", OnConsoleAddPurifier)
    Event.Hook("Console_isetlives", OnConsoleSetLives)
    Event.Hook("Console_iautomate", OnConsoleAutomate)
    Event.Hook("Console_iinfect", OnConsoleInfect)
    
end

if Server then
    
    local function OnSetAutomationState(client, message)
        GetGameMaster():SetAutomationState(message.state)
    end
    
    local function OnSetLives(client, message)
        GetGameMaster():SetLives(message.lives)
    end
    
    local function OnDamageExtractor(client, message)
        GetGameMaster():AddDamagedPurifier(Shared.GetEntity(message.pur), message.duration)
    end
    
    local function OnInfectPlayer(client, message)
        local player = client:GetPlayer()
        if player and player.SetIsInfected then
            player:SetIsInfected(true)
        end
    end
    
    Server.HookNetworkMessage("IMInfectPlayer", OnInfectPlayer)
    Server.HookNetworkMessage("IMDamageExtractor", OnDamageExtractor)
    Server.HookNetworkMessage("IMSetAutomationState", OnSetAutomationState)
    Server.HookNetworkMessage("IMSetLives", OnSetLives)
    
end