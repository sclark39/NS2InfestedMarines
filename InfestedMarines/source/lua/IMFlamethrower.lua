-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMFlamethrower.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Limit the amount of ammo you have.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

function Flamethrower:GetMaxClips()
    return 1
end

-- infinite ammo for now
function ClipWeapon:CanReload()

    self.ammo = self:GetMaxAmmo()
    return self.ammo > 0 and
           self.clip < self:GetClipSize() and
           not self.reloading and 
           self.deployed
    
end