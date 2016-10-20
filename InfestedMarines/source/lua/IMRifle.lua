-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMRifle.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Increase range of rifle butt.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

function Rifle:PerformMeleeAttack(player)

    player:TriggerEffects("rifle_alt_attack")
    
    AttackMeleeCapsule(self, player, 500, 3, nil, true)
    
end