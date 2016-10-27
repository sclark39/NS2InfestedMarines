-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMInfestationEffects.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Contains the effects Infested Marines uses.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

kInfestedMarinesEffects = 
{
    marine_infestation_attacker = 
    {
        {
            {cinematic = "cinematics/infested_marines/infested_marine.cinematic"},
            {cinematic = "cinematics/alien/gorge/bilebomb_impact.cinematic"},
            {sound = "sound/NS2.fev/alien/common/swarm"},
        },
    },
    
    marine_infestation_victim = 
    {
        {
            {cinematic = "cinematics/infested_marines/infested_marine.cinematic", world_space = true},
            {cinematic = "cinematics/alien/gorge/bilebomb_impact.cinematic", world_space = true},
            {sound = "sound/NS2.fev/alien/common/res_received", world_space = true},
            {sound = "sound/NS2.fev/alien/common/regeneration", world_space = true},
        },
    },
    
    initial_infestation_sound = 
    {
        {
            { private_sound = "sound/NS2.fev/alien/common/swarm" },
        },
    },
    
    cyst_toxins = 
    {
        {
            { cinematic = "cinematics/infested_marines/cyst_toxins.cinematic", world_space = true },
        },
    },
    
    air_purifier_working = 
    {
        {
            { cinematic = "cinematics/alien/nutrientmist_structure.cinematic", world_space = true },
        },
    },
}

GetEffectManager():AddEffectData("IMInfestationEffects", kInfestedMarinesEffects)
GetEffectManager():PrecacheEffects()