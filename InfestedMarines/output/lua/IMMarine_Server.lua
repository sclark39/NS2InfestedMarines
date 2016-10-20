-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMMarine_Server.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Changes the default loadout of marines to be flamethrower and welder.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- override weapons to give them flamethrowers and a welder
function Marine:InitWeapons()

    Player.InitWeapons(self)
    
    self:GiveItem(Flamethrower.kMapName)
    self:GiveItem(Axe.kMapName) -- required to buy welder... not worth working around.
    self:GiveItem(Welder.kMapName)
    
    self:SetQuickSwitchTarget(Welder.kMapName)
    self:SetActiveWeapon(Flamethrower.kMapName)

end

-- returns true if the target will reflect damage back onto the marine
function Marine:GetWillHaveDamageReflected(target, doer)
    -- infected cannot kill with flamethrower... they can LOOK like they're doing damage, however.
    if self:GetIsInfected() and doer and doer:isa("Flamethrower") then
        return true
    end
    
    return false
end

-- infect marine if attacker is infected, otherwise kill like normal.
local old_Marine_OnKill = Marine.OnKill
function Marine:OnKill(attacker, doer, point, direction)
    
    -- infected can infect the uninfected, but can also kill fellow infected for good.
    if attacker.GetIsInfected and attacker:GetIsInfected() and self.GetIsInfected and not self:GetIsInfected() then
        self:AddTimedCallback(Marine.Infect, 0.5)
    end
    
    old_Marine_OnKill(self, attacker, doer, point, direction)
    
end
