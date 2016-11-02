-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMMarine.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Allows a marine to be marked as "infected".
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/IMStrings.lua")

Marine.kInfectionRange = 3.0
Marine.kInfectionRangeSq = Marine.kInfectionRange * Marine.kInfectionRange

Marine.kInvalidInfestationTargetSound = PrecacheAsset("sound/NS2.fev/common/invalid")
Marine.kInfectionFreezeTime = 1.5 -- freeze player for this long when they are infested, to prevent
-- team killing.

Marine.kPointsForInfest = 80

Marine.kInfestedEnergyMax = 1.0
Marine.kInfestedDurationMax = 120.0 -- two minutes without feeding before infested starves.
Marine.kInfestedFeedLossRate = Marine.kInfestedEnergyMax / Marine.kInfestedDurationMax

Marine.kInfestedRecentTimeThreshold = 3.0

Marine.kInfestationCinematicOffset = Vector(0, 1.32, 0)

Marine.kObjective = enum({"NoObjective", "NobodyInfected", "NotInfected", "Infected", "GameOver"})

-- "hmm... I wonder how needlessly complicated I can make this?" <3 -Beige
Marine.kObjectiveStatusEvaluationTable = 
{
    alien = 
    {
        [Marine.kObjective.NoObjective] = 
        {
            vis = false,
            textFunc = IMStringGetBlankMessage,
        },
        [Marine.kObjective.NobodyInfected] = 
        {
            vis = false,
            textFunc = IMStringGetBlankMessage,
        },
        [Marine.kObjective.NotInfected] = 
        {
            vis = false,
            textFunc = IMStringGetBlankMessage,
        },
        [Marine.kObjective.Infected] = 
        {
            vis = true,
            textFunc = IMStringGetInfestedMessage,
        },
        [Marine.kObjective.GameOver] = 
        {
            vis = false,
            textFunc = IMStringGetBlankMessage,
        },
    },
    
    marine = 
    {
        [Marine.kObjective.NoObjective] = 
        {
            vis = false,
            textFunc = IMStringGetBlankMessage,
        },
        [Marine.kObjective.NobodyInfected] = 
        {
            vis = true,
            textFunc = IMStringGetNobodyInfestedMessage,
        },
        [Marine.kObjective.NotInfected] = 
        {
            vis = true,
            textFunc = IMStringGetNotInfestedMessage,
        },
        [Marine.kObjective.Infected] = 
        {
            vis = false,
            textFunc = IMStringGetBlankMessage,
        },
        [Marine.kObjective.GameOver] = 
        {
            vis = false,
            textFunc = IMStringGetBlankMessage,
        },
    }
}

Marine.kCoughingUpdateIntervalSevere = 3.0
Marine.kCoughingUpdateIntervalMild = 6.0

local function DoCoughing(self)
    
    self:TriggerEffects("bad_air")
    
end

local function UpdateCoughing(self, timePassed)
    
    -- Make marine cough a lot if the air quality is really low.
    -- Cough less often if air quality is bad but not terrible.
    -- Keep checking without coughing if air quality is good.
    
    if self:GetIsInfected() then
        return false -- infested shouldn't cough, and there is no way to become un-infested
    end
    
    local airQuality = GetGameMaster():GetAirQuality()
    if airQuality <= 0.25 then
        DoCoughing(self)
        return Marine.kCoughingUpdateIntervalSevere
    elseif airQuality <= 0.5 then
        DoCoughing(self)
        return Marine.kCoughingUpdateIntervalMild
    end
    
    return Marine.kCoughingUpdateIntervalMild
    
end

local old_Marine_OnCreate = Marine.OnCreate
function Marine:OnCreate()
    
    old_Marine_OnCreate(self)
    
    self.infestedEnergy = 1.0
    self.infected = false
    self.infestationFreeze = false
    self.objective = Marine.kObjective.NoObjective
    
    if Server then
        self:AddTimedCallback(UpdateCoughing, Marine.kCoughingUpdateIntervalMild)
    end
    
end
if Server then
    function Marine:SetObjective(objective)
        self.objective = objective
    end
end

function Marine:GetObjective()
    return self.objective or Marine.kObjective.NoObjective
end

function Marine:AddInfestedEnergy(amount)
    
    self.infestedEnergy = math.min(self.infestedEnergy + amount, Marine.kInfestedEnergyMax)
    
end

function Marine:DeductInfestedEnergy(amount)
    
    self.infestedEnergy = self.infestedEnergy - amount
    
    if self.infestedEnergy <= 0 then
        self:Kill()
    end
    
end

function Marine:GetCrosshairTargetForInfection()
    local viewAngles = self:GetViewAngles()
    local viewCoords = viewAngles:GetCoords()
    local startPoint = self:GetEyePos()
    local endPoint = startPoint + viewCoords.zAxis * Marine.kInfectionRange
    local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOneAndIsa(self, "Weapon"))
    return trace.entity
end

function Marine:GetCanInfectTarget(target)
    -- must be a marine
    if not target:isa("Marine") then
        return false
    end
    
    -- must not already be infected
    if target:GetIsInfected() then
        return false
    end
    
    -- only living targets
    if not target.GetIsAlive or not target:GetIsAlive() then
        return false
    end
    
    -- check range, because LOSMixin uses a much longer range than the infection range.
    local distSq = (self:GetOrigin() - target:GetOrigin()):GetLengthSquared()
    if distSq > Marine.kInfectionRangeSq then
        return false
    end
    
    -- we don't perform an expensive obstacle-check here, because this is already done by
    -- Marine:GetCrosshairTargetForInfection(), so there is no need.
    return true
end

function Marine:GetPlayerStatusDesc()
    
    if (self:GetIsAlive() == false) then
        return kPlayerStatus.Dead
    end
    
    if self:GetIsInfected() then
        return kPlayerStatus.Infested
    end
    
    return kPlayerStatus.Void
    
end

function Marine:GetIsInfected()
    
    return (self.infected == true)
    
end

function Marine:GetWasRecentlyInfested()
    
    if self.timeInfested and Shared.GetTime() < self.timeInfested + Marine.kInfestedRecentTimeThreshold then
        return true
    end
    
    return false
    
end

function Marine:SetIsInfected(state)
    
    self.infected = (state == true)
    self:MarkBlipDirty()
    
    self:AddInfestedEnergy(Marine.kInfestedEnergyMax)
    
    self.timeInfested = Shared.GetTime()
    
end

local function TriggerThingoutEffects(self, timePassed, attacker)
    
    local coords = self:GetCoords()
    if attacker then
        coords.origin = coords.origin + Marine.kInfestationCinematicOffset
        self:TriggerEffects("marine_infestation_attacker", {effecthostcoords = coords})
    else
        coords.origin = coords.origin + Marine.kInfestationCinematicOffset
        self:TriggerEffects("marine_infestation_victim", {effecthostcoords = coords})
    end
    
    return false -- don't repeat
    
end

local function UnfreezeInfestation(self, timePassed)
    self.infestationFreeze = false
    return false
end

function Marine:Infect()
    
    self:SetIsInfected(true)
    
    self:AddTimedCallback(TriggerThingoutEffects, 0.5)
    
    self.infestationFreeze = true --prevent player from moving while they are infesting another.
    -- unfreeze player once infestation process has ended.
    self:AddTimedCallback(UnfreezeInfestation, Marine.kInfectionFreezeTime)
    
end

local function AttemptInfection(self)
    
    -- make it a single event upon the button press, not a continuous thing.
    if self.isSecondaryAttacking then
        return
    end
    
    self.isSecondaryAttacking = true
    
    if not self:GetIsInfected() then
        return
    end
    
    -- find the target under the player's crosshair
    local target = self:GetCrosshairTargetForInfection()
    if not target then
        if Client then
            StartSoundEffect(Marine.kInvalidInfestationTargetSound)
        end
        return
    end
    
    -- found a target, check if it's valid
    if not self:GetCanInfectTarget(target) then
        if Client then
            StartSoundEffect(Marine.kInvalidInfestationTargetSound)
        end
        return
    end
    
    self.infestationFreeze = true --prevent player from moving while they are infesting another.
    
    if Server then
        self:AddScore(self.kPointsForInfest)
        target:Infect()
        self:AddInfestedEnergy(Marine.kInfestedEnergyMax)
        
        local team = self:GetTeam()
        local deathMessageTable = team:GetDeathMessage(self, kDeathMessageIcon.Consumed, target)
        team:ForEachPlayer(function(player) if player:GetClient() then Server.SendNetworkMessage(player:GetClient(), "DeathMessage", deathMessageTable, true) end end)
            
            
        TriggerThingoutEffects(self, 0.0, true)
        
        -- unfreeze player once infestation process has ended.
        self:AddTimedCallback(UnfreezeInfestation, Marine.kInfectionFreezeTime)
    end
    
    if Client then
        
        -- hide the keybind telling them how to infest a human
        self.secondaryKeybindHidden = true
        
    end
    
end

function Marine:GetCanDropWeapon(weapon, ignoreDropTimeLimit)

    if not weapon then
        weapon = self:GetActiveWeapon()
    end
    
    if weapon ~= nil and weapon.GetIsDroppable and weapon:GetIsDroppable() then
    
        -- Don't drop weapons too fast.
        if ignoreDropTimeLimit then
            return true
        end
        
    end
    
    return false
    
end

function Marine:GetsPointsForWelding(entity)
    
    if self:GetIsInfected() then
        return false
    end
    
    if not (entity and entity:isa("Extractor")) then
        return false
    end
    
    return true
    
end

function Marine:SecondaryAttackEnd()
    
    self.isSecondaryAttacking = false
    
    Player.SecondaryAttackEnd(self)
    
end

function Marine:SecondaryAttack()
    
    AttemptInfection(self)
    
    Player.SecondaryAttack(self)
    
end

local old_Marine_OnProcessMove = Marine.OnProcessMove
function Marine:OnProcessMove(input)
    
    if self.infestationFreeze then
        input.move:Scale(0)
        input.commands = 0
    end
    
    old_Marine_OnProcessMove(self, input)
    
end

local kNewMarineNetvars = 
{
    infected = "boolean",
    infestedEnergy = "float",
    infestationFreeze = "boolean",
    timeInfested = "time",
    objective = "enum Marine.kObjective",
}

Class_Reload("Marine", kNewMarineNetvars)