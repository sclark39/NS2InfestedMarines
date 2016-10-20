-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMGameMasterData.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Contains the "brain" of the automated game master, how it chooses which nodes to damage.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

gIMScenarioType = enum({"test", "Scatter", "Random", "Regroup"})

gIMScenarioTypeList = 
{
    --gIMScenarioType.test,
    gIMScenarioType.Scatter,
    gIMScenarioType.Random,
    gIMScenarioType.Regroup,
}

-- we use "marineConfiguration" tables, which just group together nearby-marines.  This is
-- so we don't have to do pathfinding for every single marine on the map -- we can just do
-- it from the marine closest to the centroid, and it'll be close enough.
gIMScenarios = 
{
    --------------------------------------------------------------------------------------
    -- Test Scenario 1 -------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    -- simply picks a random extractor, and damages it.  Computes the time it would take
    -- to walk there, and sets that amount of time, plus 10 seconds.
    [gIMScenarioType.test] = function(marineConfiguration)
        local extractors = IMGetUndamagedExtractors()
        local purifier = extractors[math.random(#extractors)]
        local duration = 10 + IMComputeTravelTime(IMGetSquadCenter(marineConfiguration[1]), purifier:GetOrigin())
        
        GetGameMaster():QueuePurifierDamage(purifier, duration)
        GetGameMaster().cooldownPeriod = 5.0
    end,
    
    --------------------------------------------------------------------------------------
    -- Scatter ---------------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    -- spawn damaged nodes as far away from marines as possible.  Break N/2 round-up nodes, where N is
    -- the number of non-infected players.
    [gIMScenarioType.Scatter] = function(marineConfiguration)
        local extractors = IMGetUndamagedExtractors()
        local marineCount, timeFactor = IMGetPlausibleMarineCount()
        
        local numNodes = math.ceil(marineCount*0.5)
        
        -- sort extractors by closest marine squad.  We'll iterate backwards to find the extractors furthest from the
        -- marines.
        extractors = IMSortPurifiersByClosestMarineSquad(extractors, marineConfiguration)
        numNodes = math.min(numNodes, #extractors)
        
        local index = #extractors
        for _=1, numNodes do
            local pur = extractors[index]
            index = index - 1
            local duration = IMComputeMinimumTimeRequired(marineConfiguration, pur:GetOrigin()) * timeFactor
            GetGameMaster():QueuePurifierDamage(pur, duration)
        end
        
        GetGameMaster().cooldownPeriod = 5.0
    end,
    
    --------------------------------------------------------------------------------------
    -- Random ----------------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    -- spawn the nodes randomly.
    [gIMScenarioType.Random] = function(marineConfiguration)
        local extractors = IMGetUndamagedExtractors()
        local marineCount, timeFactor = IMGetPlausibleMarineCount()
        
        local numNodes = math.ceil(marineCount*0.5)
        numNodes = math.min(numNodes, #extractors)
        
        while(numNodes > 0) do
            numNodes = numNodes - 1
            local index = math.random(#extractors)
            local pur = extractors[index]
            local duration = IMComputeMinimumTimeRequired(marineConfiguration, pur:GetOrigin()) * timeFactor
            GetGameMaster():QueuePurifierDamage(pur, duration)
            table.remove(extractors, index)
        end
        
        GetGameMaster().cooldownPeriod = 5.0
    end,
    
    --------------------------------------------------------------------------------------
    -- Regroup ---------------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    -- Spawns a single node, the one closest to all the marines.  Maybe make the infestation extra bad in this room to
    -- give people a reason to stick around or come in the first place.
    [gIMScenarioType.Regroup] = function(marineConfiguration)
        local extractors = IMGetUndamagedExtractors()
        local marineCenters = {}
        for i=1, #marineConfiguration do
            table.insert(marineCenters, IMGetSquadCenter(marineConfiguration[i]))
        end
        
        local leastSquareSum = Math.infinity
        local leastSquareIndex = 0
        for i=1, #extractors do
            local purPos = extractors[i]:GetOrigin()
            local squareSum = 0
            for j=1, #marineCenters do
                squareSum = squareSum + (marineCenters[j]-purPos):GetLengthSquared()
            end
            
            if squareSum < leastSquareSum then
                leastSquareSum = squareSum
                leastSquareIndex = i
            end
        end
        
        assert(leastSquareIndex > 0)
        local pur = extractors[leastSquareIndex]
        local duration = IMComputeMinimumTimeRequired(marineConfiguration, pur:GetOrigin())
        GetGameMaster():QueuePurifierDamage(pur, duration)
        
        GetGameMaster().cooldownPeriod = 15.0 -- extra time for cabin fever... :)
    end,
}

function IMGetRandomScenario()
    
    return gIMScenarios[gIMScenarioTypeList[math.random(#gIMScenarioTypeList)]]
    
end