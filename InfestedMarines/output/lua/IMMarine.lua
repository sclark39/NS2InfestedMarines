-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMMarine.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Allows a marine to be marked as "infected".
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Marine.kInfectionRange = 3.0
Marine.kInfectionRangeSq = Marine.kInfectionRange * Marine.kInfectionRange

Marine.kInvalidInfestationTargetSound = PrecacheAsset("sound/NS2.fev/common/invalid")
Marine.kInfectionFreezeTime = 0.5 -- freeze player for this long when they are infested, to prevent
-- team killing.

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

function Marine:GetIsInfected()
    
    return (self.infected == true)
    
end

function Marine:SetIsInfected(state)
    
    self.infected = (state == true)
    self:MarkBlipDirty()
    
end

function Marine:Infect()
    
    self:SetIsInfected(true)
    self:SetStun(Marine.kInfectionFreezeTime)
    
    Log("marine '%s' has been infected!", self)
    if Server then
        Server.SendNetworkMessage(self, "InfectedProcessMessage", {}, true)
    end
    
    self:TriggerEffects("bilebomb_hit")
    --TODO better effects
    
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
    
    if Server then
        target:Infect()
    end
    
end

function Marine:SecondaryAttackEnd()
    
    self.isSecondaryAttacking = false
    
    Player.SecondaryAttackEnd(self)
    
end

function Marine:SecondaryAttack()
    
    AttemptInfection(self)
    
    Player.SecondaryAttack(self)
    
end

local kNewMarineNetvars = 
{
    infected = "boolean",
}

Class_Reload("Marine", kNewMarineNetvars)