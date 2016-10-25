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
    if self:GetIsInfected() and target:isa("Marine") then
        if doer and doer:isa("Flamethrower") then
            return true
        end
        
        return false
    end
    
    if not target.GetIsInfected then
        -- target doesn't take reflection into account at all (eg non-player entity)
        return false
    end
    
    if target:GetIsInfected() then
        return false
    end
    
    return true
end