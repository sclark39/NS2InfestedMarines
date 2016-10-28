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
-- repair it, also clear infestation.  Assume the node is at full health.  Punishes marines for
-- not repairing nodes.
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
    return table.median(times) * 1.5 + GetGameMaster():GetDillyDallyTime() + GetGameMaster():GetInfestationClearTime()
    
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

function IMGetExtractorEHPFraction(extractor)
    
    if not extractor.GetIsAlive or not extractor:GetIsAlive() then
        return 0
    end
    
    local ehp = extractor:GetHealth() + extractor:GetArmor() * 2
    local maxEhp = extractor:GetMaxHealth() + extractor:GetMaxArmor() * 2
    
    return ehp / maxEhp
    
end

local function GetWillExtractorBeCorroded(extractor)
    
    local cysts = GetEntitiesWithinRange("Cyst", extractor:GetOrigin(), Cyst.kInfestationRadius)
    for i=1, #cysts do
        if cysts[i] and cysts[i].GetIsAlive and cysts[i]:GetIsAlive() then
            return true
        end
    end
    
end

-- test not just extractors that are being corroded, but extractors that are within infestation
-- range of a cyst, so they are ABOUT to be corroded.
function IMGetCorrodingExtractorsExist()
    
    local extractors = EntityListToTable(Shared.GetEntitiesWithClassname("Extractor"))
    for i=1, #extractors do
        if extractors[i] and GetWillExtractorBeCorroded(extractors[i]) then
            return true
        end
    end
    
    return false
    
end

function IMGetExtractorCountFraction()
    
    -- returns a sum from all extractors, where 1 = an undamaged extractor, 0 = a dead extractor,
    -- and damaged is somewhere in between.
    
    local extractors = EntityListToTable(Shared.GetEntitiesWithClassname("Extractor"))
    
    local sum = 0
    for i=1, #extractors do
        if extractors[i] and extractors[i].GetIsAlive and extractors[i]:GetIsAlive() then
            sum = sum + IMGetExtractorEHPFraction(extractors[i])
        end
    end
    
    return sum
    
end

function IMGetCleanMarineCount()
    
    local m = self:GetTeam1():GetPlayers()
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

function IMGetInfestedMarines()
    
    local marines = self:GetTeam1():GetPlayers()
    local vettedMarines = {}
    
    for i=1, #marines do
        if marines[i] and marines[i].GetIsAlive and marines[i]:GetIsAlive() and marines[i].GetIsInfected and marines[i]:GetIsInfected() then
            table.insert(vettedMarines, marines[i])
        end
    end
    
    return vettedMarines
    
end

function IMGetCleanMarines()
    
    local marines = self:GetTeam1():GetPlayers()
    local vettedMarines = {}
    
    for i=1, #marines do
        if marines[i] and marines[i].GetIsAlive and marines[i]:GetIsAlive() and marines[i].GetIsInfected and not marines[i]:GetIsInfected() then
            table.insert(vettedMarines, marines[i])
        end
    end
    
    return vettedMarines
    
end

function IMGetRandomMarine()
    
    local marines = self:GetTeam1():GetPlayers()
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

function IMPickRandomWithWeights(weights, items, numPicks)
    
    assert(#weights == #items)
    
    numPicks = numPicks or 1
    local picked = {}
    
    while(numPicks > 0 and #items > 0) do
        
        local index = PickRandomWithWeight(weights)
        table.insert(picked, items[index])
        table.remove(weights, index)
        table.remove(items, index)
        numPicks = numPicks - 1
        
    end
    
    return picked
    
end

function IMGetCystCount()
    
    local cysts = EntityListToTable(Shared.GetEntitiesWithClassname("Cyst"))
    local count = #cysts
    for i=1, #cysts do
        if not cysts[i] or not cysts[i].GetIsAlive or not cysts[i]:GetIsAlive() then
            count = count - 1
        end
    end
    
    return count
    
end

function IMInvertWeights(weights, sorted)
    for i=1, #weights do
        weights[i] = 1.0 - weights[i]
    end
    return weights, sorted
end

-- return a sorted list of eligible extractors, sorted according to sum of square distances between
-- each extractor and every marine.  Then, we can either pick from the bottom or top to choose
-- closest or furthest.
function IMGetDistanceRankedNodeList(isFirstWave)
    
    local extractors = IMGetUndamagedExtractors()
    local cleanMarines = IMGetCleanMarines()
    local weights = {}
    
    -- exclude the starting rez node if it's the first wave
    if isFirstWave then
        local marine = IMGetRandomMarine()
        local closest = 1
        local closestDistSq = (extractors[1]:GetOrigin() - marine:GetOrigin()):GetLengthSquared()
        for i=2, #extractors do
            local distSq = (extractors[i]:GetOrigin() - marine:GetOrigin()):GetLengthSquared()
            if distSq < closestDistSq then
                closest = i
                closestDistSq = distSq
            end
        end
        
        table.remove(extractors, closest)
    end
    
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
    local splitWeights = {}
    local sum = 0.0
    for i=1, #weights do
        sum = sum + weights[i][2]
        table.insert(sorted, weights[i][1])
        table.insert(splitWeights, weights[i][2])
    end
    
    -- normalize data so it can be inverted easily
    for i=1, #splitWeights do
        splitWeights[i] = splitWeights[i] / sum
    end
    
    return splitWeights, sorted
    
end


