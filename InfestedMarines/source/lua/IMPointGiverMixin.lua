-- ======= Copyright (c) 2003-2016, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMPointGiverMixin.lua
--
--    Created by:   Sebastian Schuck (sebastian@naturalselection2.com)
--
--    Grant score points for certain actions.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kPointsForTeamKill = -40
local kPointsForInfestedKill = 40
local kPointsForCystKill = 1

function PointGiverMixin:PreOnKill(attacker, doer, point, direction)

	if not attacker or self.isHallucination then
		return
	end

	local points = self:GetPointValue(attacker)

	attacker:AddScore(points, 0, true)

	if self:isa("Player") and attacker and attacker:isa("Player") then
		if self:GetIsInfected() and not attacker:IsInfected() then
			attacker:AddKill()
		end
	end
end

local oldGetPointValue = PointGiverMixin.GetPointValue
function PointGiverMixin:GetPointValue(attacker)
	if not attacker then
		return oldGetPointValue(self)
	end

    local attackerIsInfested = attacker.GetIsInfected and attacker:GetIsInfected()
    
    if self:isa("Marine") then
        return self:GetIsInfected() == attackerIsInfested and kPointsForTeamKill or kPointsForInfestedKill
    elseif self:isa("Cyst") and not attackerIsInfested then
        return kPointsForCystKill
    end
    
    return 0
end