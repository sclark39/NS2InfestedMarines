-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMConsoleCommands.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Handles all the commands associated with the infested marines gamemode.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Shared.RegisterNetworkMessage("IMInfectPlayer", {})
Shared.RegisterNetworkMessage("IMCystRatio", { ratio = "float"})
Shared.RegisterNetworkMessage("IMPickInfested", {})

if Client then
    
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
    Event.Hook("Console_iinfect", OnConsoleInfect)
    
    local function OnConsoleCystRatio(ratio)
        if not (Shared.GetCheatsEnabled() or Shared.GetTestsEnabled()) then
            Log("Cheats or debug testing must be enabled to use this command")
            return
        end
        
        Client.SendNetworkMessage("IMCystRatio", { ratio = tonumber(ratio) }, true)
    end
    Event.Hook("Console_icystratio", OnConsoleCystRatio)
    
    local function OnConsolePickInfested()
        if not (Shared.GetCheatsEnabled() or Shared.GetTestsEnabled()) then
            Log("Cheats or debug testing must be enabled to use this command")
            return
        end
        
        Client.SendNetworkMessage("IMPickInfested", {}, true)
    end
    Event.Hook("Console_ipickinfested", OnConsolePickInfested)
    
end

if Server then
    
    local function OnInfectPlayer(client, message)
        local player = client:GetPlayer()
        if player and player.SetIsInfected then
            player:SetIsInfected(true)
        end
    end
    Server.HookNetworkMessage("IMInfectPlayer", OnInfectPlayer)
    
    local function OnCystRatio(client, message)
        IMGameMaster.kCystToPurifierRatio = message.ratio
    end
    Server.HookNetworkMessage("IMCystRatio", OnCystRatio)
    
    local function OnPickInfested(client, message)
        GetGameMaster().infectedChooseDelay = 0
    end
    Server.HookNetworkMessage("IMPickInfested", OnPickInfested)
end