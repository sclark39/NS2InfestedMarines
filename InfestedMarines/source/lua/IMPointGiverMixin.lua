-- ======= Copyright (c) 2003-2016, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMPointGiverMixin.lua
--
--    Created by:   Sebastian Schuck (sebastian@naturalselection2.com)
--
--    Grant score points for certain actions.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kPointsForTeamKill = -5
local kPointsForInfestedKill = 10

local oldPreOnKill = PointGiverMixin.PreOnKill
function PointGiverMixin:PreOnKill(attacker, doer, point, direction)

	--save attacker for giving the right amount of points
	if self.GetIsInfected and attacker.GetIsInfected then
		self.attacker = attacker
	end

	return oldPreOnKill(self, attacker, doer, point, direction)
end

local oldGetPointValue = PointGiverMixin.GetPointValue
function PointGiverMixin:GetPointValue()
	if not self.attacker then
		return oldGetPointValue(self)
	end

	local attackerIsInfested = self.attacker:GetIsInfected()
	self.attacker = nil

	return self:GetIsInfected() == attackerIsInfested and kPointsForTeamKill or kPointsForInfestedKill
end