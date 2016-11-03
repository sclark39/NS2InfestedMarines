-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMWelder.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Only the uninfected should get points for welding, and only when they weld extractors.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Welder.kHealScoreAdded = 1
Welder.kAmountHealedForPoints = 2000

local function PrioritizeDamagedFriends(weapon, player, newTarget, oldTarget)
    return not oldTarget or (HasMixin(newTarget, "Team") and newTarget:GetTeamNumber() == player:GetTeamNumber() and (HasMixin(newTarget, "Weldable") and newTarget:GetCanBeWelded(weapon)))
end

function Welder:PerformWeld(player)

    local attackDirection = player:GetViewCoords().zAxis
    local success = false
    -- prioritize friendlies
    local didHit, target, endPoint, direction, surface = CheckMeleeCapsule(self, player, 0, self:GetRange(), nil, true, 1, PrioritizeDamagedFriends, nil, PhysicsMask.Flame)
    
    if didHit and target and HasMixin(target, "Live") then
        
        if GetAreEnemies(player, target) then
            self:DoDamage(kWelderDamagePerSecond * kWelderFireDelay, target, endPoint, attackDirection)
            success = true     
        elseif player:GetTeamNumber() == target:GetTeamNumber() and HasMixin(target, "Weldable") then
        
            if target:GetHealthScalar() < 1 then
                
                local prevHealthScalar = target:GetHealthScalar()
                local prevHealth = target:GetHealth()
                local prevArmor = target:GetArmor()
                target:OnWeld(self, kWelderFireDelay, player)
                success = prevHealthScalar ~= target:GetHealthScalar()
                
                if success then
                    
                    if player.GetsPointsForWelding and player:GetsPointsForWelding(target) then
                        
                        local addAmount = (target:GetHealth() - prevHealth) + (target:GetArmor() - prevArmor)
                        player:AddContinuousScore("WeldHealth", addAmount, Welder.kAmountHealedForPoints, Welder.kHealScoreAdded)
                        
                    end
                    
                    -- weld owner as well
                    player:SetArmor(player:GetArmor() + kWelderFireDelay * kSelfWeldAmount)
                    
                    if Server then
                        TipHandler_ReportWelding(player)
                    end
                    
                end
                
            end
            
            if HasMixin(target, "Construct") and target:GetCanConstruct(player) then
                target:Construct(kWelderFireDelay, player)
            end
            
        end
        
    end
    
    if success then    
        return endPoint
    end
    
end