-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMNS2Utility.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Overrides how friendly fire damage is handled.  FF should only apply to players, not structures.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local old_CanEntityDoDamageTo = CanEntityDoDamageTo
function CanEntityDoDamageTo(attacker, target, cheats, devMode, friendlyFire, damageType)
    
    if attacker and attacker:isa("Marine") and target and target:isa("Marine") then
        return true
    end
    
    -- extra protection for extractors
    if attacker and attacker:isa("Marine") and target and target:isa("Extractor") then
        return false
    end
    
    return old_CanEntityDoDamageTo(attacker, target, cheats, devMode, friendlyFire, damageType)
    
end