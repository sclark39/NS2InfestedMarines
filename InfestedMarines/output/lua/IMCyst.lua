-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMCyst.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

if Client then
    
    function Cyst:OnTimedUpdate()
    end
    
end

function Cyst:GetMapBlipInfo()
    --return    success,    blipType,                       blipTeam,       isAttacked, isParasited
    return      true,       kMinimapBlipType.Infestation,   kTeam1Index,    false,      false
end

local old_Cyst_OnCreate = Cyst.OnCreate
function Cyst:OnCreate()
    
    old_Cyst_OnCreate(self)
    
    self.nearCysts = {}
    self.nearCysts.num = 0
    
end