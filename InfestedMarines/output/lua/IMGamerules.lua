-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMGamerules.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Prevents kill message from appearing in console.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

function Gamerules:GetDamageMultiplier()
    return ConditionalValue(Shared.GetCheatsEnabled(), self.damageMultiplier, 1)
end