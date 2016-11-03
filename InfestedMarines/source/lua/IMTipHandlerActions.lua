-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMTipHandlerActions.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Contains all the functions that are called by various events in the game to potentially trigger
--    a tip message.  For example, Cyst:OnKill calls a function below to report a cyst was killed, and
--    by whom, so we can see if we should warn them about not killing cysts as infested.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- if there are any un-infected within this range, we will assume the infested is attempting to blend
-- in, otherwise, we will assume they do not understand their actions are helping the enemy.
local kInfestedPlayAlongRange = 20

local function GetAreUninfestedNearby(pos)
    
    local marines = GetEntitiesWithinRange("Marine", pos, kInfestedPlayAlongRange)
    for i=1, #marines do
        if marines[i] and marines[i]:GetIsAlive() and not marines[i]:GetIsInfected() then
            return true
        end
    end
    
    return false
    
end

function TipHandler_ReportCystKilled(attacker)
    
    -- don't care if they died on their own.
    if not attacker then
        return
    end
    
    -- don't care if attacker is an un-infected.
    if not (attacker.GetIsInfected and attacker:GetIsInfected()) then
        return
    end
    
    -- don't bother telling them this tip if there are uninfected nearby.  We'll just assume
    -- they are playing along.
    if GetAreUninfestedNearby(attacker:GetOrigin()) then
        return
    end
    
    DisplayTipForPlayer(attacker, kIMTipMessageType.DoNotKillCysts)
    
end

function TipHandler_ReportWelding(weldingPlayer)
    
    -- don't care if they're not infested.
    if not weldingPlayer or not (weldingPlayer.GetIsInfected and weldingPlayer:GetIsInfected()) then
        return
    end
    
    -- don't bother telling them this tip if there are uninfected nearby.  We'll just assume
    -- they are playing along.
    if GetAreUninfestedNearby(weldingPlayer:GetOrigin()) then
        return
    end
    
    DisplayTipForPlayer(weldingPlayer, kIMTipMessageType.DoNotWeldPurifiers)
    
end



