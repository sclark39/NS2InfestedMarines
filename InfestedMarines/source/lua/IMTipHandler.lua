-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMTipHandler.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Contains all the functionality needed to display a tip message on a client's screen.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

kIMTipMessageType = enum({"Blank", "DoNotWeldPurifiers", "DoNotKillCysts", "KillCysts", "WeldPurifiers", "FriendlyFireVictim", "FriendlyFireAttacker", "InfestedSuicideByFlamethrower", "InfestedFriendlyFire", "InfestedStarvation", "InfestedNearStarvation"})

local kTipDisplayCooldown = 8 -- seconds before another tip can be displayed.

local playerTipQueues = {} -- each tip queue is a table, and each one is mapped to a player id.
-- eg:
-- playerTipQueues = 
-- {
--     [1234] = 
--     {
--         cooldown = 5.5,
--         queue = 
--         {
--             1,2,3,4,5...... etc  (tip type enum values)
--         }
--     }
-- }

if Server then
    Script.Load("lua/IMTipHandlerActions.lua") -- script that looks for opportunities to present tips.
end

Shared.RegisterNetworkMessage("DoTipTypeForPlayer",
{
    tipType = "enum kIMTipMessageType",
})

local function GetPlayers()
    local players = GetGamerules():GetTeam1():GetPlayers()
    local returnPlayers = {}
    for i=1, #players do
        if players[i] then
            table.insert(returnPlayers, players[i])
        end
    end
    
    return returnPlayers
end

if Server then
    
    function TipHandler_ResetQueuedTips()
        playerTipQueues = {}
    end
    
    -- update the tip display on the next update.
    function DoTipASAP(player)
        local playerId = player:GetId()
        if playerTipQueues[playerId] then
            playerTipQueues[playerId].cooldown = 0
        end
    end
    
    -- Should never display tips directly, instead use this function.  This queues up tips, and prevents
    -- any particular tip from being spammed.
    function EnqueueTipForPlayer(player, tipType, atFront)
        local playerId = player:GetId()
        
        -- ensure table values are initialized
        playerTipQueues[playerId] = playerTipQueues[playerId] or {}
        playerTipQueues[playerId].cooldown = playerTipQueues[playerId].cooldown or 0
        playerTipQueues[playerId].queue = playerTipQueues[playerId].queue or {}
        
        -- see if tip type is already in the queue
        local foundAtIndex = nil
        for i=1, #playerTipQueues[playerId].queue do
            if playerTipQueues[playerId].queue[i] == tipType then
                foundAtIndex = 1
                break
            end
        end
        
        if atFront then
            if not foundAtIndex or foundAtIndex > 1 then
                if foundAtIndex then
                    table.remove(playerTipQueues[playerId].queue, foundAtIndex)
                end
                table.insert(playerTipQueues[playerId].queue, 1, tipType)
            end
        else
            if not foundAtIndex then -- only add if it's not already in the queue.
                table.insert(playerTipQueues[playerId].queue, tipType)
            end
        end
    end
    
    -- Do the actual tip displaying.
    function TipHandler_DisplayTipForPlayer(player, tipType)
        Server.SendNetworkMessage(player, "DoTipTypeForPlayer", {tipType = tipType}, true)
    end
    
    function TipHandler_Update(deltaTime)
        
        local players = GetPlayers()
        
        for i=1, #players do
            
            -- check for new tips (call goes to IMTipHandlerActions.lua)
            TipHandler_UpdatePlayerActions(players[i], deltaTime)
            
            -- check for tips that can finally be displayed.
            local playerId = players[i]:GetId()
            -- if player actually has a queue... they might have tips waiting to be presented.
            if playerTipQueues[playerId] then
                -- adjust the cooldown based on this update's delta time.
                playerTipQueues[playerId].cooldown = math.max(playerTipQueues[playerId].cooldown - deltaTime, 0)
                -- if the cooldown has expired, check to see if we have any tips to display.
                if playerTipQueues[playerId].cooldown <= 0.0001 then
                    local foundValidTip = false
                    if #playerTipQueues[playerId].queue > 0 then
                        -- we potentially have tips to display.  Starting at the oldest, find a tip
                        -- that is still relevant.  After sitting in the queue for some time, there
                        -- may be tips waiting that no longer apply, so we'll ignore them.
                        while #playerTipQueues[playerId].queue > 0 do
                            if TipHandler_GetIsTipTypeValid(players[i], playerTipQueues[playerId].queue[1]) then
                                -- display a new tip, reset the countdown.
                                TipHandler_DisplayTipForPlayer(players[i], playerTipQueues[playerId].queue[1])
                                foundValidTip = true
                            end
                            
                            table.remove(playerTipQueues[playerId].queue, 1)
                            
                            if foundValidTip then
                                playerTipQueues[playerId].cooldown = kTipDisplayCooldown
                                break
                            end
                        end
                    end
                    
                    if not foundValidTip then
                        -- no valid tips were found.  Since this can only occur after the cooldown
                        -- of the last message, we can now remove ourselves from the master list
                        -- of tip queues.
                        playerTipQueues[playerId] = nil
                    end
                end
            end
            
        end
        
    end
    
    -- ensure we cleanup the table whenever a player id is changed.
    function TipHandler_OnEntityChange(oldId, newId)
        if oldId then
            if newId then
                playerTipQueues[newId] = playerTipQueues[oldId]
            end
            playerTipQueues[oldId] = nil
        end
    end
end

if Client then
    local function OnClientDoTipType(msg)
        GetPlayerTipScript():DoPlayerTip(msg.tipType)
    end
    Client.HookNetworkMessage("DoTipTypeForPlayer", OnClientDoTipType)
end