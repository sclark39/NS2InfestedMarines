-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMFlamethrower.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Limit the amount of ammo you have.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================
Log("IMFlamethrower.lua")
function Flamethrower:GetMaxClips()
    return 1
end

-- infinite ammo for now
local old_Flamethrower_OnPrimaryAttack = Flamethrower.OnPrimaryAttack
function Flamethrower:OnPrimaryAttack(player)
    
    old_Flamethrower_OnPrimaryAttack(self, player)
    
    self.ammo = self:GetMaxAmmo()
    
end