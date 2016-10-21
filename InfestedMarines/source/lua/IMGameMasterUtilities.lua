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

-- computes the median time needed for CLEAN marines on the map to walk over to the node and
-- repair it, also clear infestation.
function IMComputeTimeRequiredToSave(purifier)
    
    assert(purifier)
    
    local times = {}
    local cleans = IMGetCleanMarines()
    for i=1, #cleans do
        local t = IMComputeTravelTime(purifier:GetOrigin(), cleans[i]:GetOrigin())
        if t then
            table.insert(times, t)
        end
    end
    
    if #times == 0 then
        return nil
    end
    
    -- double the travel time, to account for the fact that you move about half as fast when you're
    -- constantly personal-space-checking people around you.
    return table.median(times) * 2 + GetGameMaster():GetDillyDallyTime() + GetGameMaster():GetInfestationClearTime()
    
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
    
    local diff = pt-pos
    diff.y = 0
    local distSq = diff:GetLengthSquared()
    if distSq <= 0.00001 then
        return nil
    end
    
    if distSq > 25 then
        -- if snapping to the nav mesh results in a difference of > 5 meters, discard it.
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

function IMGetCleanMarines()
    
    local marines = EntityListToTable(Shared.GetEntitiesWithClassname("Marine"))
    local vettedMarines = {}
    
    for i=1, #marines do
        if marines[i] and marines[i].GetIsAlive and marines[i]:GetIsAlive() and marines[i].GetIsInfected and not marines[i]:GetIsInfected() then
            table.insert(vettedMarines, marines[i])
        end
    end
    
    return vettedMarines
    
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

-- return a sorted list of eligible extractors, sorted according to sum of square distances between
-- each extractor and every marine.  Then, we can either pick from the bottom or top to choose
-- closest or furthest.
function IMGetDistanceRankedNodeList()
    
    local extractors = IMGetUndamagedExtractors()
    local cleanMarines = IMGetCleanMarines()
    local weights = {}
    
    for e=1, #extractors do
        local sum = 0.0
        for m=1, #cleanMarines do
            sum = sum + (extractors[e]:GetOrigin() - cleanMarines[m]:GetOrigin()):GetLengthSquared()
        end
        table.insert(weights, {extractors[e], sum})
    end
    
    local function sortByWeight(a, b)
        return a[2] < b[2]
    end
    
    table.sort(weights, sortByWeight)
    
    local sorted = {}
    for i=1, #weights do
        table.insert(sorted, weights[i][1])
    end
    
    return sorted
    
end


