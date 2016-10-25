-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMTechData.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Change name of "Extractor" to "Air Purifier"
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local old_BuildTechData = BuildTechData
function BuildTechData()
    
    kTechData = old_BuildTechData()
    
    -- Perform modifications
    for index, record in ipairs(kTechData) do
        local currentid = record[kTechDataId]
        
        -- Make structures unplaceable except for where we explicitly allow them to be placed.
        if currentid == kTechId.Extractor then
            record[kTechDataDisplayName] = "AIR_PURIFIER"
        end
    end
    
    return kTechData
    
end