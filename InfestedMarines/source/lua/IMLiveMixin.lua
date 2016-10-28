-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMLiveMixin.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Modified to implement a special kind of reflective damage that doesn't tip it's hand until
--    a death will occur.  For example, we don't want an uninfected marine to be able to detect
--    infected marines just by seeing who takes damage and who reflects damage back on him.  So
--    what we'll do is make everybody appear to take damage like normal, but when they are "killed",
--    if the death should be reflected, the attacker is killed, and the victim is "refunded" all
--    the damage that was dealt to them by that ONE attacker.
--    
--    We do this for particular entity types by storing the damage they absorbed, and by whom, in
--    a table.
--
--    Update: Currently the only situation that reflects damage is infected vs infected.  Yes, this
--    means people could just blow away everybody indiscriminately, but that just means they'll
--    lose as they won't be able to keep up with the infestation spawning.  Also, griefing means
--    they'd be removed from any well-administered server anyways.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local function SetLastDamage(self, time, attacker)

    if attacker and attacker.GetId then
    
        self.timeOfLastDamage = time
        self.lastDamageAttackerId = attacker:GetId()
        
    end
    
    -- Track "combat" (for now only take damage, since we don't make a difference between harmful and passive abilities):
    self.timeLastCombatAction = Shared.GetTime()
    
end

function LiveMixin:Kill(attacker, doer, point, direction)

    -- Do this first to make sure death message is sent
    if self:GetIsAlive() and self:GetCanDie() then
        
        -- refund any reflected damage this player caused to other players.
        if self.reflectedDamageTable then
            for victimId, data in pairs(self.reflectedDamageTable) do
                local victim = Shared.GetEntity(victimId)
                if victim then
                    victim:SetHealth(victim:GetHealth() + data.healthLost)
                    victim:SetArmor(victim:GetArmor() + data.armorLost)
                    
                    -- remove self from the victim's table of players that damaged them
                    if victim.playersThatDamagedUs then
                        victim.playersThatDamagedUs[self:GetId()] = nil
                    end
                end
            end
        end
        
        if self.PreOnKill then
            self:PreOnKill(attacker, doer, point, direction)
        end
    
        self.health = 0
        self.armor = 0
        self.alive = false
        
        if Server then
            GetGamerules():OnEntityKilled(self, attacker, doer, point, direction)
        end
        
        if self.OnKill then
            self:OnKill(attacker, doer, point, direction)
        end
        
    end
    
end

local old_LiveMixin_OnEntityChange = LiveMixin.OnEntityChange
function LiveMixin:OnEntityChange(oldId, newId)
    
    old_LiveMixin_OnEntityChange(self, oldId, newId)
    
    -- give health back if attacker is removed and doesn't do it themselves.
    local ptdu = self.playersThatDamagedUs
    if ptdu and ptdu[oldId] then
        -- the only reason we made it here is because the attacker didn't fulfill their responsibility
        -- of informing past damage victims of when they can have their health returned.
        self:SetHealth(self:GetHealth() + ptdu[oldId].healthLost)
        self:SetArmor(self:GetArmor() + ptdu[oldId].armorLost)
        ptdu[oldId] = nil
        
        -- just in case, ensure the attacker doesn't still have their damage table registered for us.
        local attacker = Shared.GetEntity(oldId)
        if attacker then
            local rdt = attacker.reflectedDamageTable
            if rdt then
                rdt[self:GetId()] = nil
            end
        end
    end

end

function LiveMixin:RecordReflectionDamage(attacker, healthLost, armorLost)
    attacker.reflectedDamageTable = attacker.reflectedDamageTable or {}
    local rdt = attacker.reflectedDamageTable
    local victimId = self:GetId()
    rdt[victimId] = rdt[victimId] or {}
    rdt[victimId].healthLost = rdt[victimId].healthLost and rdt[victimId].healthLost + healthLost or healthLost
    rdt[victimId].armorLost = rdt[victimId].armorLost and rdt[victimId].armorLost + armorLost or armorLost
    
    self.playersThatDamagedUs = self.playersThatDamagedUs or {}
    local ptdu = self.playersThatDamagedUs
    local attackerId = attacker:GetId()
    ptdu[attackerId] = ptdu[attackerId] or {}
    ptdu[attackerId].healthLost = ptdu[attackerId].healthLost and ptdu[attackerId].healthLost + healthLost or healthLost
    ptdu[attackerId].armorLost = ptdu[attackerId].armorLost and ptdu[attackerId].armorLost + armorLost or armorLost
end

function LiveMixin:TakeDamage(damage, attacker, doer, point, direction, armorUsed, healthUsed, damageType, preventAlert)
        
    -- Use AddHealth to give health.
    assert(damage >= 0)
    
    local killedFromDamage = false
    local oldHealth = self:GetHealth()
    local oldArmor = self:GetArmor()
    
    if self.OnTakeDamage then
        self:OnTakeDamage(damage, attacker, doer, point, direction, damageType, preventAlert)
    end
    
    -- Remember time we were last hurt to track combat
    SetLastDamage(self, Shared.GetTime(), attacker)
  
    -- Do the actual damage only on the server
    if Server then
      
        self.armor = math.max(0, self:GetArmor() - armorUsed)
        self.health = math.max(0, self:GetHealth() - healthUsed)
      
        local killedFromHealth = oldHealth > 0 and self:GetHealth() == 0 and not self.healthIgnored
        local killedFromArmor = oldArmor > 0 and self:GetArmor() == 0 and self.healthIgnored
        local damageReflected = GetGamerules():GetUsesBlindReflectedDamage() and attacker and attacker.GetWillHaveDamageReflected and attacker:GetWillHaveDamageReflected(self, doer)
        if damageReflected then
            self:RecordReflectionDamage(attacker, oldHealth - self.health, oldArmor - self.armor)
        end
        
        if killedFromHealth or killedFromArmor then
            
            if damageReflected then
                -- player friendly-fired a friendly player to death.  They die, player they attacked
                -- gets their health/armor back.
                attacker:Kill(nil, nil, point, direction)
            end
            
            if (not damageReflected) or (not attacker.GetWillReflectedDamageHitVictim) or attacker:GetWillReflectedDamageHitVictim(self, doer) then
                self:Kill(attacker, doer, point, direction)
            end
            
        end
        
        return killedFromDamage, (oldHealth - self.health + (oldArmor - self.armor) * 2)    
    
    end
    
    -- things only die on the server
    return false, false

    
end