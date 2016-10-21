-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMGameMasterUtilities.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Useful functions, intended for use by the infested marines IMGameMaster class.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local function GetTravelDistance(to, from)
    local points = PointArray()
    Pathing.GetPathPoints(to, from, points)
    
    if #points <= 1 then
        return nil
    end
    
    local sumDist = 0.0
    for i=1, #points-1 do
        sumDist = sumDist + (points[i]-points[i+1]):GetLength()
    end
    
    return sumDist
end

-- computes the travel time it would take for a unit to travel to a destination, given a certain speed.
function IMComputeTravelTime(to, from, speed)
    
    speed = speed or Marine.kWalkMaxSpeed
    assert(speed)
    assert(speed > 0)
    assert(to)
    assert(from)
    
    local dist = GetTravelDistance(to, from)
    if not dist then
        return nil
    end
    
    return dist/speed
    
end

-- computes the time required for one of the marine squads to walk to and weld the damaged node.
function IMComputeMinimumTimeRequired(marineConfiguration, to, includeInfected, speed)
    
    includeInfected = includeInfected or false
    speed = speed or Marine.kWalkMaxSpeed
    assert(speed)
    assert(speed > 0    )
    assert(to)
    assert(marineConfiguration)
    assert(#marineConfiguration > 0)
    
    local minTime = IMComputeTravelTime(IMGetSquadCenter(marineConfiguration[1]), to) or 999999
    for i=2, #marineConfiguration do
        minTime = math.min(minTime, IMComputeTravelTime(IMGetSquadCenter(marineConfiguration[i]), to) or 999999)
    end
    
    return minTime + IMGameMaster.kMarineWeldTime + GetGameMaster():GetDillyDallyTime() + 2
    
end

-- get table of living, undamaged extractors
function IMGetUndamagedExtractors()
    
    local x = EntityListToTable(Shared.GetEntitiesWithClassname("Extractor"))
    local x2 = {}
    for i=1, #x do
        if x[i] then
            if x[i].GetIsAlive and x[i]:GetIsAlive() then
                if GetGameMaster():GetIsPurifierSaved(x[i]) then
                    table.insert(x2, x[i])
                end
            end
        end
    end
    
    return x2
    
end

function IWGetRandomWeightedIndex(weights)
    
    assert(#weights > 0)
    
    local tw = weights[1]
    local pick = 1
    for i=2, #weights do
        tw = tw + weights[i]
        if math.random() * tw <= weights[i] then
            pick = i
        end
    end
    
    Log("IWGetRandomWeightedIndex returning %s", pick)
    return pick
    
end

local function GetDistanceBetweenEntitiesSq(e1, e2)
    return (e1:GetOrigin() - e2:GetOrigin()):GetLengthSquared()
end

function IMGetSquadCenter(squad)
    
    local pos = Vector(0,0,0)
    for i=1, #squad do
        pos = pos + squad[i]:GetOrigin()
    end
    
    local centroid = pos/#squad
    
    local closest = 1
    local closestDistSq = (centroid - squad[1]:GetOrigin()):GetLengthSquared()
    
    for i=2, #squad do
        local distSq = (centroid - squad[i]:GetOrigin()):GetLengthSquared()
        if distSq < closestDistSq then
            closestDistSq = distSq
            closest = i
        end
    end
    
    return squad[closest]:GetOrigin()
    
end

-- build marineConfiguration table
function IMBuildMarineConfigurationTable()
    
    local m = EntityListToTable(Shared.GetEntitiesWithClassname("Marine"))
    local s = {}
    
    for i=1, #m do
        if m[i] then
            local squadIndices = {}
            for j=1, #s do
                -- find appropriate squad(s!!!!  PLURAL) to insert into (combine all squads this marine
                -- "bridges")
                for k=1, #s[j] do
                    if GetDistanceBetweenEntitiesSq(s[j][k], m[i]) <= IMGameMaster.kMarineSquadRangeSq then
                        -- will be merged with this squad
                        table.insert(squadIndices, j)
                        break
                    end
                end
            end
            
            if #squadIndices == 0 then
                -- if no squad was suitable for this marine, make a new squad
                local newSquad = {}
                table.insert(newSquad, m[i])
                table.insert(s, newSquad)
            else
                -- found squads, merge them together if multiple.
                table.insert(s[squadIndices[1]], m[i]) -- add the marine to the first squad it matched
                for n=2, #squadIndices do
                    -- merge the remaining squads into the first
                    for p=1, #s[squadIndices[n]] do
                        table.insert(s[squadIndices[1]], s[squadIndices[n]][p])
                    end
                end
                -- remove the old squads from before the merge process
                for n=#squadIndices, 2, -1 do
                    table.remove(s, n)
                end
            end
        end
    end
    
    return s
    
end

-- Problem: if we make the number of extractors scale with the number of CLEAN players, people will catch on to the
-- fact that there are way more marines than there should be for the number of extractor they're getting, and they might
-- just start blasting everyone they see.  At the same time, it's a bit too brutal to make every marine count the same --
-- if all the infested just stopped helping and hid instead, they could win by default.  So from this we need two things:
-- 1) fewer extractors when there are fewer "clean" players, but not enough to be THAT noticeable, and 2) a way of giving
-- players more time when they are being assigned quite a few more extractors than they should.  This function computes the
-- "middle ground" of the number of extractors that should be damaged in a wave, and also provides a time multiplier value
-- to be used to adjust the duration of each extractor.
function IMGetPlausibleMarineCount()
    
    local m = EntityListToTable(Shared.GetEntitiesWithClassname("Marine"))
    local infectedCount = 0
    local cleanCount = 0
    for i=1, #m do
        if m[i] then
            if m[i].GetIsAlive and m[i]:GetIsAlive() and m[i].GetIsInfected and not m[i]:GetIsInfected() then
                cleanCount = cleanCount + 1
            end
            
            if m[i].GetIsAlive and m[i]:GetIsAlive() and m[i].GetIsInfected and m[i]:GetIsInfected() then
                infectedCount = infectedCount + 1
            end
        end
    end
    
    -- make each infected count for half, so even if EVERYONE except you is infected, you'll probably still be seeing more than
    -- one purifier being damaged, and might still hesitate to go full IronHorse on the enemy.
    local count = cleanCount + (infectedCount * 0.5)
    local fullCount = cleanCount + infectedCount
    local factor = fullCount / count -- essentially would give double time if everyone was infected.
    
    return count, factor
    
end

function IMGetInfestedMarineCount()
    
    local m = EntityListToTable(Shared.GetEntitiesWithClassname("Marine"))
    local count = 0
    for i=1, #m do
        if m[i] then
            if m[i].GetIsAlive and m[i]:GetIsAlive() and m[i].GetIsInfected and m[i]:GetIsInfected() then
                count = count + 1
            end
        end
    end
    
    return count
    
end

function IMGetCleanMarineCount()
    
    local m = EntityListToTable(Shared.GetEntitiesWithClassname("Marine"))
    local count = 0
    for i=1, #m do
        if m[i] then
            if m[i].GetIsAlive and m[i]:GetIsAlive() and m[i].GetIsInfected and not m[i]:GetIsInfected() then
                count = count + 1
            end
        end
    end
    
    return count
    
end

local function DistBetweenEntAndPointSq(ent, pt)
    return (ent:GetOrigin()-pt):GetLengthSquared()
end

local function GetPurifierFurthestFromPoint(purifiers, pt)
    
    local furthestDistSq = DistBetweenEntAndPointSq(purifiers[1], pt)
    local furthest = 1
    for i=2, #purifiers do
        local distSq = DistBetweenEntAndPointSq(purifiers[i], pt)
        if distSq > furthestDistSq then
            furthestDistSq = distSq
            furthest = i
        end
    end
    
    return purifiers[furthest], furthestDistSq
    
end

function IMGetMarineSquadPositions(mc)
    
    local positions = {}
    for i=1, #mc do
        table.insert(positions, IMGetSquadCenter(mc[i]))
    end
    
    return positions
    
end

function IMGetFurthestByMarineGroup(extractors, marineConfiguration)
    
    local furthest = {}
    for i=1, #marineConfiguration do
        local result, distSq = GetPurifierFurthestFromPoint(extractors, IMGetSquadCenter(marineConfiguration[i]))
        local entry = { pur = result, distSq = distSq }
        table.insert(furthest, entry)
    end
    
    local function sortFunc(t1, t2)
        return t1.distSq > t2.distSq
    end
    
    table.sort(furthest, sortFunc)
    
    -- return table of extractors.
    local sorted = {}
    for i=1, #furthest do
        table.insert(sorted, furthest[i].pur)
    end
    
    return sorted
    
end

local function ComputeSumSquaredDistance(picked, pos)
    
    local sum = 0.0
    for i=1, #picked do
        sum = sum + (picked[i]:GetOrigin() - pos):GetLengthSquared()
    end
    
    return sum
    
end

local function ComputeDistanceBias(picked, pool)
    
    local poolBias = {}
    for i=1, #pool do
        table.insert(poolBias, math.sqrt(ComputeSumSquaredDistance(picked, pool[i]:GetOrigin())))
    end
    
    return poolBias
    
end

-- picks a random index from the table, based on the weights.
local function PickRandomWithWeight(poolBias)
    
    if #poolBias == 0 then
        return 0
    end
    
    local totalWeight = 0.0
    local pickedIndex = 0
    
    for i=1, #poolBias do
        local thisWeight = poolBias[i]
        totalWeight = totalWeight + thisWeight
        local result = math.random() * totalWeight
        if result <= thisWeight then
            pickedIndex = i
        end
    end
    
    return pickedIndex
    
end

-- randomly choose X starting infested nodes with a bias towards nodes
-- that are further from the starting area, and with each subsequent
-- choice -- further from the other starting infested nodes.
function IMComputeStartingInfestedNodes(infestCount, pool, homeNode)
    
    local picked = {}
    table.insert(picked, homeNode) -- so we avoid this node.  Remember to remove later
    
    while (#picked < infestCount + 1) do
        
        local poolBias = ComputeDistanceBias(picked, pool)
        local index = PickRandomWithWeight(poolBias)
        assert(index > 0)
        table.insert(picked, pool[index])
        table.remove(pool, index)
        
    end
    
    table.remove(picked, 1) -- remove home node from picked list.
    return picked
    
end

function IMGetClosestIndexToPoint(pool, pt)
    
    local closest = 1
    local closestDistSq = (pool[1]:GetOrigin()-pt):GetLengthSquared()
    for i=2, #pool do
        local distSq = (pool[i]:GetOrigin()-pt):GetLengthSquared()
        if distSq < closestDistSq then
            closest = i
            closestDistSq = distSq
        end
    end
    
    return closest
    
end

local function GetPointOnNavMesh(pos)
    
    local pt = Pathing.GetClosestPoint(pos)
    
    -- it doesn't fail, it returns the parameter if it cannot find a point on the nav mesh
    local diff = pt - pos
    if math.abs(diff.x) <= 0.001 and math.abs(diff.y) <= 0.001 and math.abs(diff.z) <= 0.001 then
        return nil 
    end
    
    return pt
     
end

local function GetPointVariants(offset, pos)
    
    -- get the same points rotated 90 degrees around the middle, turning 1 point into 4.
    local points = {}
    table.insert(points, pos + offset)
    
    -- rotate and add
    offset.y = offset.z
    offset.z = -offset.x
    offset.x = offset.y
    offset.y = 0
    table.insert(points, pos + offset)
    
    -- rotate and add
    offset.y = offset.z
    offset.z = -offset.x
    offset.x = offset.y
    offset.y = 0
    table.insert(points, pos + offset)
    
    -- rotate and add
    offset.y = offset.z
    offset.z = -offset.x
    offset.x = offset.y
    offset.y = 0
    table.insert(points, pos + offset)
    
    return points
    
end

function IMGetRandomPointsAroundPosition(pos)
    
    local tentativeOffsets = {}
    
    local numSamples = 4
    local rOffs = math.random() * math.pi * 0.5
    local rPer = (math.pi * 0.5) / numSamples
    local maxDist = IMCystManager.kCystConnectionRadius
    local minDist = maxDist * 0.25
    local distSamples = 3
    
    for d=0, distSamples do
        local dist = (maxDist - minDist) * (d/distSamples) + minDist
        for i=1, numSamples do
            local rads = rOffs + rPer * i
            local c = math.cos(rads)
            local s = math.sin(rads)
            
            table.insert(tentativeOffsets, Vector(c*dist, 0, -s*dist))
        end
    end
    
    local pathingPoints = {}
    for i=1, #tentativeOffsets do
        local points = GetPointVariants(tentativeOffsets[i], pos)
        for j=1, #points do
            local ppt = GetPointOnNavMesh(points[j])
            if ppt then
                table.insert(pathingPoints, ppt)
            end
        end
    end
    
    return pathingPoints
    
end

function IMInfestNode(node)
    
    -- create infestation and cysts around node.
    local pts = IMGetRandomPointsAroundPosition(node:GetOrigin())
    if not pts or #pts == 0 then
        Log("Error: could not create infestation for resource node at location %s", node:GetLocationName())
        return false
    end
    
    -- todo make this pick better cysts.  I'm outta time right now, so pick a few randoms.
    local numPick = 5
    local numSpawned = 0
    while numPick > 0 and #pts > 0 do
        local index = math.random(#pts)
        GetCystManager():CreateCyst(pts[index])
        table.remove(pts, index)
        numPick = numPick - 1
        numSpawned = numSpawned + 1
    end
    
    if numSpawned == 0 then
        Log("didn't spawn any cysts... for some reason...")
        return false
    end
    return true
    
end

function IMGetRandomMarine()
    
    local marines = EntityListToTable(Shared.GetEntitiesWithClassname("Marine"))
    local vettedMarines = {}
    
    for i=1, #marines do
        if marines[i] and marines[i].GetIsAlive and marines[i]:GetIsAlive() then
            table.insert(vettedMarines, marines[i])
        end
    end
    
    if #vettedMarines == 0 then
        return nil
    end
    
    return vettedMarines[math.random(#vettedMarines)]
    
end

function IMSortPurifiersByClosestMarineSquad(purifiers, marineConfiguration)
    
    local marinePositions = IMGetMarineSquadPositions(marineConfiguration)
    local pScored = {}
    
    for i=1, #purifiers do
        
        local closestSquad = 1
        local closestSquadDistSq = (marinePositions[1] - purifiers[i]:GetOrigin()):GetLengthSquared()
        
        for j=2, #marinePositions do
            local distSq = (marinePositions[j] - purifiers[i]:GetOrigin()):GetLengthSquared()
            if distSq < closestSquadDistSq then
                closestSquad = j
                closestSquadDistSq = distSq
            end
        end
        
        local newEntry = {}
        newEntry.pur = purifiers[i]
        newEntry.score = closestSquadDistSq
        table.insert(pScored, newEntry)
        
    end
    
    local function sortFunc(t1, t2)
        return t1.score < t2.score
    end
    table.sort(pScored, sortFunc)
    
    local pSorted = {}
    for i=1, #pScored do
        table.insert(pSorted, pScored[i].pur)
    end
    
    return pSorted
    
end

function IMDebugPrintMarineConfiguration(marineConfiguration)
    
    for i=1, #marineConfiguration do
        Log("  Squad %s:", i)
        for j=1, #marineConfiguration[i] do
            Log("    %s", marineConfiguration[i][j])
        end
    end
end


