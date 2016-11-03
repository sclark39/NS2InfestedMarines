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

-- if a player is within "kConsiderCystsRange" of any cysts, we count off of a "cooldown".  When the
-- cooldown expires, we give the player a tip that they should be killing cysts.  If at any time the
-- player kills a cyst, the cooldown is reset to kCystNotificationCooldown seconds.
local kConsiderCystsRange = 5
local kCystNotificationCooldown = 10
local kConsiderPurifiersRange = 15
local kPurifierNotificationCooldown = 10

-- function references that should be used to verify if a tip is still valid
local tipTypeVerificationFunctions = {}

-- number of seconds out from doing the thing that causes the tip to be enqueued before the tip is
-- considered no longer valid.  Eg if a player kills some cysts, but then stops, and more than
-- kMaxVerifyLagTime seconds pass before the tip can be shown (and the player doesn't kill any more
-- cysts in that window of time), then the tip is considered not valid, and will be discarded.
local kMaxVerifyLagTime = 3.0

local function RegisterVerificationFunction(tipType, funcRef)
    if tipTypeVerificationFunctions[tipType] then
        Log("WARNING!  Reassignment for tip verification function detected!\n(tipType = %s, funcRef = %s)", EnumToString(kIMTipMessageType, tipType), funcRef)
    end
    tipTypeVerificationFunctions[tipType] = funcRef
end

local function GetAreUninfestedNearby(pos)
    
    local marines = GetEntitiesWithinRange("Marine", pos, kInfestedPlayAlongRange)
    for i=1, #marines do
        if marines[i] and marines[i]:GetIsAlive() and not marines[i]:GetIsInfected() then
            return true
        end
    end
    
    return false
    
end

local function GetIsPlayerInfested(player)
    return ((player.GetIsInfected and player:GetIsInfected()) == true)
end

local function GetIsPlayerAlive(player)
    return ((player.GetIsAlive and player:GetIsAlive()) == true)
end

local function GetNearbyCystCount(position)
    local cysts = GetEntitiesWithinRange("Cyst", position, kConsiderCystsRange)
    local count = 0
    for i=1, #cysts do
        if cysts[i] then
            count = count + 1
        end
    end
    
    return count
end

local function GetNearbyDamagedPurifiersCount(position)
    local purifiers = GetEntitiesWithinRange("Extractor", position, kConsiderPurifiersRange)
    local count = 0
    for i=1, #purifiers do
        if purifiers[i] and purifiers[i]:GetIsAlive() and purifiers[i]:GetHealthFraction() < 0.999 then
            count = count + 1
        end
    end
    
    return count
end

function TipHandler_Verify_DoNotWeldPurifiers(player)
    
    if Shared.GetTime() - (player.timeOfLastPurifierWeld or 0) > kMaxVerifyLagTime then
        return false
    end
    
    return true
    
end
RegisterVerificationFunction(kIMTipMessageType.DoNotWeldPurifiers, TipHandler_Verify_DoNotWeldPurifiers)

function TipHandler_Verify_DoNotKillCysts(player)
    
    if Shared.GetTime() - (player.timeOfLastCystKill or 0) > kMaxVerifyLagTime then
        return false
    end
    
    return true
    
end
RegisterVerificationFunction(kIMTipMessageType.DoNotKillCysts, TipHandler_Verify_DoNotKillCysts)

function TipHandler_Verify_KillCysts(player)
    
    if not player then
        return false
    end
    
    if not GetIsPlayerAlive(player) then
        return false
    end
    
    if GetIsPlayerInfested(player) then
        return false
    end
    
    if GetNearbyCystCount(player:GetOrigin()) == 0 then
        return false
    end
    
    return true
    
end
RegisterVerificationFunction(kIMTipMessageType.KillCysts, TipHandler_Verify_KillCysts)

function TipHandler_Verify_WeldPurifiers(player)
    
    if not player then
        return false
    end
    
    if not GetIsPlayerAlive(player) then
        return false
    end
    
    if GetIsPlayerInfested(player) then
        return false
    end
    
    if GetNearbyDamagedPurifiersCount(player:GetOrigin()) == 0 then
        return false
    end
    
    return true
    
end
RegisterVerificationFunction(kIMTipMessageType.WeldPurifiers, TipHandler_Verify_WeldPurifiers)

function TipHandler_Verify_AlwaysTrue(player)
    return true
end
RegisterVerificationFunction(kIMTipMessageType.FriendlyFireVictim, TipHandler_Verify_AlwaysTrue)
RegisterVerificationFunction(kIMTipMessageType.FriendlyFireAttacker, TipHandler_Verify_AlwaysTrue)
RegisterVerificationFunction(kIMTipMessageType.InfestedSuicideByFlamethrower, TipHandler_Verify_AlwaysTrue)
RegisterVerificationFunction(kIMTipMessageType.InfestedFriendlyFire, TipHandler_Verify_AlwaysTrue)

function TipHandler_GetIsTipTypeValid(player, tipType)
    
    if not player then
        return false
    end
    
    if tipType == kIMTipMessageType.Blank then
        return true
    end
    
    -- tip type didn't register a verification function
    if not tipTypeVerificationFunctions[tipType] then
        Log("ERROR: tipType %s does not have a registered verification function!  Discarding...", EnumToString(kIMTipMessageType, tipType))
        return false
    end
    
    return tipTypeVerificationFunctions[tipType](player)
    
end

function TipHandler_ReportCystKilled(attacker)
    
    -- don't care if they died on their own.
    if not attacker then
        return
    end
    
    -- don't care if attacker is an un-infected.  But, for a different tip, we will keep track of
    -- a "cooldown" for when the player last killed a cyst.  This is so we can detect if they're
    -- near cysts and not killing them.
    if not GetIsPlayerInfested(attacker) then
        attacker.cystKillCooldown = kCystNotificationCooldown
        return
    end
    
    -- don't bother telling them this tip if there are uninfected nearby.  We'll just assume
    -- they are playing along.
    if GetAreUninfestedNearby(attacker:GetOrigin()) then
        return
    end
    
    -- for the verification step
    attacker.timeOfLastCystKill = Shared.GetTime()
    
    EnqueueTipForPlayer(attacker, kIMTipMessageType.DoNotKillCysts)
    
end

function TipHandler_ReportWelding(weldingPlayer)
    
    if not weldingPlayer then
        return
    end
    
    if GetIsPlayerInfested(weldingPlayer) then
        -- if they're infested, they shouldn't be welding
        -- don't bother telling them this tip if there are uninfected nearby.  We'll just assume
        -- they are playing along.
        if GetAreUninfestedNearby(weldingPlayer:GetOrigin()) then
            return
        end
        
        weldingPlayer.timeOfLastPurifierWeld = Shared.GetTime()
        
        EnqueueTipForPlayer(weldingPlayer, kIMTipMessageType.DoNotWeldPurifiers)
    else
        -- but if they're not infested, they SHOULD be welding.
        weldingPlayer.purifierWeldCooldown = kPurifierNotificationCooldown
    end
end

function TipHandler_ReportFriendlyFireDeathVictim(victim)
    
    EnqueueTipForPlayer(victim, kIMTipMessageType.FriendlyFireVictim, true)
    DoTipASAP(victim)
    
end

function TipHandler_ReportFriendlyFireDeathAttacker(attacker)
    
    EnqueueTipForPlayer(attacker, kIMTipMessageType.FriendlyFireAttacker, true)
    DoTipASAP(attacker)
    
end

function TipHandler_ReportInfestedSuicideByUsingFlamethrower(infested)
    
    EnqueueTipForPlayer(infested, kIMTipMessageType.InfestedSuicideByFlamethrower, true)
    DoTipASAP(infested)
    
end

function TipHandler_ReportInfestedFriendlyFire(attacker)
    
    EnqueueTipForPlayer(attacker, kIMTipMessageType.InfestedFriendlyFire, true)
    DoTipASAP(attacker)
    
end

-- uninfested players should be killing cysts.  If they're near cysts and not killing them,
-- we should encourage them to.
function TipHandler_KillCystUpdateCheck(player, deltaTime)
    
    -- does not apply to infested players.
    if GetIsPlayerInfested(player) then
        return
    end
    
    -- if player isn't near cysts, don't count off cooldown.
    if GetNearbyCystCount(player:GetOrigin()) == 0 then
        return
    end
    
    player.cystKillCooldown = player.cystKillCooldown or kCystNotificationCooldown
    player.cystKillCooldown = player.cystKillCooldown - deltaTime
    if player.cystKillCooldown <= 0 then
        player.cystKillCooldown = kCystNotificationCooldown
        EnqueueTipForPlayer(player, kIMTipMessageType.KillCysts)
    end
    
end

function TipHandler_WeldPurifiersUpdateCheck(player, deltaTime)
    
    -- does not apply to infested players.
    if GetIsPlayerInfested(player) then
        return
    end
    
    -- if player isn't near purifiers, don't count off the cooldown.
    if GetNearbyDamagedPurifiersCount(player:GetOrigin()) == 0 then
        return
    end
    
    player.purifierWeldCooldown = player.purifierWeldCooldown or kPurifierNotificationCooldown
    player.purifierWeldCooldown = player.purifierWeldCooldown - deltaTime
    if player.purifierWeldCooldown <= 0 then
        player.purifierWeldCooldown = kPurifierNotificationCooldown
        EnqueueTipForPlayer(player, kIMTipMessageType.WeldPurifiers)
    end
    
end

function TipHandler_UpdatePlayerActions(player, deltaTime)
    
    TipHandler_KillCystUpdateCheck(player, deltaTime)
    TipHandler_WeldPurifiersUpdateCheck(player, deltaTime)
    
end

