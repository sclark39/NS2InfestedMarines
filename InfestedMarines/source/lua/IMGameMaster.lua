-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMGameMaster.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Controls the events that occur during a round of Infested Marines (eg when/which air
--    purifiers are attacked).  So named because this role was more or less filled by a human
--    during initial game design/testing.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/IMGameMasterUtilities.lua")

local gameMaster = nil

function GetGameMaster()
    
    if not gameMaster then
        gameMaster = CreateGameMaster()
    end
    
    return gameMaster
    
end

function CreateGameMaster()
    
    local newGM = IMGameMaster()
    newGM:OnCreate()
    return newGM
    
end

function DestroyGameMaster()
    
    gameMaster = nil
    DestroyCystManager()
    
end

function ResetGameMaster()
    
    DestroyGameMaster()
    GetGameMaster()
    
end

class 'IMGameMaster'

IMGameMaster.kDefaultMaxLives = 5
IMGameMaster.kUpdatePeriod = 0.25
IMGameMaster.kMarineSquadRange = 25 -- any marines within 25m of another marine are grouped into
                                    -- the same "squad"
IMGameMaster.kMarineSquadRangeSq = IMGameMaster.kMarineSquadRange * IMGameMaster.kMarineSquadRange
IMGameMaster.kMarineWeldTime = 4    -- approximately the amount of seconds required once at a node to weld it fully.
IMGameMaster.kTimeBeforeInfectedChosen = 30
IMGameMaster.kPhase = enum({ "Scatter", "Regroup" })

-- cysts propagate on their own slowly, but will RAPIDLY deploy near new nodes.
IMGameMaster.kScatterCystBoost = 10 -- number of additional cysts to spawn quickly, per node
                                    -- in addition to the few that are spawned directly on the node.
IMGameMaster.kRegroupCystBoost = 30 -- cysts per node for regroup phase.
IMGameMaster.kRegularCystPropagationPeriod = 5 -- one cyst every 5 seconds.
IMGameMaster.kFasterCystPropagationPeriod = 3 -- one cyst every 3 second.

IMGameMaster.kDefaultDillyDallyTime = 5 -- time added for organization, etc.
IMGameMaster.kScatterInfestationClearTime = 10 -- time added to allow for clearing cysts during scatter.
IMGameMaster.kRegroupInfestationClearTime = 30 -- more time here b/c there's a lot more infestation.
IMGameMaster.kCystToPurifierRatio = 1.5 -- 1.5 seems to be a good balance.
IMGameMaster.kAirQualityChangePerSecondMax = 1/90 -- 90 seconds minimum to drain the bar from full
IMGameMaster.kRatioChangeMax = 10 -- what the ratio has to be to have a positive max change
IMGameMaster.kRatioChangeMin = 0.1 -- if the ratio is lower than this, air quality change is maximized.
IMGameMaster.kRatioPositiveBoost = 3.0 -- rate of change is multiplied by this when positive.

function IMGameMaster:OnCreate()
    
    self.airQFraction = 1.0
    GetAirStatusBlip():SetFraction(self.airQFraction)
    
    self.damagedPurifiers = {}
    
    self.cooldownPeriod = 0.0 -- used to delay the next round of purifiers being damaged.
    self.timeBuffer = 5.0 -- extra five seconds by default.  This can be adjusted based on team performance to adjust difficulty
    self.fastCysts = {} -- table to be filled with { vector location, number } pairs.
    self.firstWave = true
    
end

function IMGameMaster:GetInfestationClearTime()
    if self:GetPhase() == IMGameMaster.kPhase.Scatter then
        return IMGameMaster.kScatterInfestationClearTime
    elseif self:GetPhase() == IMGameMaster.kPhase.Regroup then
        return IMGameMaster.kRegroupInfestationClearTime
    else
        assert(false)
    end
end

function IMGameMaster:GetDillyDallyTime()
    return self.timeBuffer
end

function IMGameMaster:FastCystLocation(location, numCysts)
    
    table.insert(self.fastCysts, {location, numCysts})
    
end

function IMGameMaster:GetAirQualityChangeRatio()
    local numCysts = IMGetCystCount()
    local numExtractors = IMGetExtractorCountFraction() -- half damaged extractor = half the benefit
    
    -- +1 to avoid /0
    local ratio = (numExtractors * IMGameMaster.kCystToPurifierRatio) / (numCysts + 1)
    
    return ratio
end

function IMGameMaster:GetCystUpdatePeriod()
    local ratio = self:GetAirQualityChangeRatio()
    if ratio > 1 then
        return IMGameMaster.kFasterCystPropagationPeriod
    end
    
    return IMGameMaster.kRegularCystPropagationPeriod
end

function IMGameMaster:GetIsPurifierSaved(purifier)
    
    -- for now, just look at the health and armor.  Later, we'll need to require they clear the room
    -- of infestation.
    if purifier:GetHealth() >= purifier:GetMaxHealth() * 0.995 and purifier:GetArmor() >= purifier:GetMaxArmor() * 0.995 then
        return true
    end
    
    return false
    
end

function IMGameMaster:AllowLateJoin()
    
    return self.infectedChooseDelay and (self.infectedChooseDelay >= 5.0) or false
    
end

function IMGameMaster:GetHasInfectedBeenChosenYet()
    
    return self.pickedInfected
    
end

function IMGameMaster:GetPhase()
    self.phase = self.phase or IMGameMaster.kPhase.Scatter
    return self.phase
end

function IMGameMaster:SetPhase(p)
    self.phase = p
end

function IMGameMaster:DoGameStart()
    
    self.pickedInfected = false
    self.infectedChooseDelay = IMGameMaster.kTimeBeforeInfectedChosen
    self:SetPhase(IMGameMaster.kPhase.Scatter)
    
end

function IMGameMaster:SetIsFirstWave(state)
    self.firstWave = state
end

function IMGameMaster:GetIsFirstWave()
    return self.firstWave
end

local function UpdateQueuedDamages(self)
    
    self.queuedDamages = self.queuedDamages or {}
    if #self.queuedDamages > 0 then
        self.damageCooldown = self.damageCooldown or 0
        if self.damageCooldown <= 0 then
            local purifier = Shared.GetEntity(self.queuedDamages[1])
            if purifier then
                IMInfestNode(purifier)
            end
            table.remove(self.queuedDamages, 1)
            self.damageCooldown = 0.75
        else
            self.damageCooldown = self.damageCooldown - IMGameMaster.kUpdatePeriod
        end
    end
    
end

local function InfestNodes(nodes)
    
    for i=1, #nodes do
        GetGameMaster():QueuePurifierDamage(nodes[i])
    end
    
end

local function CalculateRegroupNodeCount()
    
    return math.ceil(IMGetCleanMarineCount() / 6)
    
end

local function CalculateScatterNodeCount()
    
    return math.ceil(IMGetCleanMarineCount() / 2)
    
end

local function PerformRegroupNodeDamage(self)
    
    local weights, sorted = IMGetDistanceRankedNodeList(self:GetIsFirstWave())
    local numNodes = CalculateRegroupNodeCount()
    
    -- pick nodes randomly based on weight
    local pickedNodes = IMPickRandomWithWeights(weights, sorted, numNodes)
    for i=1, #pickedNodes do
        self:FastCystLocation(pickedNodes[i]:GetOrigin(), IMGameMaster.kRegroupCystBoost)
    end
    
    InfestNodes(pickedNodes)
    
    self.cooldownPeriod = 5
    
end

local function PerformScatterNodeDamage(self)
    
    local weights, sorted = IMInvertWeights(IMGetDistanceRankedNodeList(self:GetIsFirstWave()))
    local numNodes = CalculateScatterNodeCount()
    
    -- pick nodes randomly based on weight
    local pickedNodes = IMPickRandomWithWeights(weights, sorted, numNodes)
    for i=1, #pickedNodes do
        self:FastCystLocation(pickedNodes[i]:GetOrigin(), IMGameMaster.kScatterCystBoost)
    end
    
    InfestNodes(pickedNodes)
    
    self.cooldownPeriod = 5
    
end

local function PerformNodeDamage(self)
    
    if self.phase == IMGameMaster.kPhase.Scatter then
        PerformScatterNodeDamage(self)
    elseif self.phase == IMGameMaster.kPhase.Regroup then
        PerformRegroupNodeDamage(self)
    else
        assert(false)
    end
    
end

local function UpdateGameMasterDuties(self, deltaTime)
    
    if not GetGamerules():GetGameStarted() then
        return
    end
    
    -- don't advance until all extractors have been destroyed or saved.  Don't consider
    -- extractors that have been saved but still have yet to be repaired.
    if IMGetCorrodingExtractorsExist() then
        return
    end
    
    -- NOTE: the cooldown period will only decrease once there are no more corroding/about-to-be
    -- corroding extractors.
    if self.cooldownPeriod > 0 then
        self.cooldownPeriod = self.cooldownPeriod - deltaTime
        return
    end
    
    PerformNodeDamage(self)
    self:SetIsFirstWave(false) -- so we don't exclude the starting location node again
    
    assert(self.cooldownPeriod > 0) -- cooldown period MUST be set after this
    
end

local function GetInfestedPickCount()
    
    local numMarines = IMGetCleanMarineCount()
    return math.ceil(numMarines / 9)
    
end

local function PickInfected(self)
    
    local players = GetGamerules().team1:GetPlayers()
    local numPicks = GetInfestedPickCount()
    local infectedPlayers = {}
    
    while numPicks > 0 and #players > 0 do
        local index = math.random(#players)
        if players[index] and players[index].SetIsInfected then
            numPicks = numPicks - 1
            table.insert(infectedPlayers, players[index])
        else
            table.remove(players, index)
        end
    end
    
    assert(#infectedPlayers > 0)
    self.initialInfected = {}

    for i=1, #infectedPlayers do
        infectedPlayers[i]:SetIsInfected(true)
        infectedPlayers[i]:TriggerEffects( "initial_infestation_pick_sound" )

        self.initialInfected[infectedPlayers[i]:GetSteamId()] = true
    end
    
    local numPlayers = GetGamerules().team1:GetNumPlayers()
    for i=1, numPlayers do
        local player = GetGamerules().team1:GetPlayer(i)
        if player and not player:GetIsInfected() then
            player:TriggerEffects("initial_infestation_sound")
        end
    end
    
end

local function UpdateInfectionPick(self)
    
    if not GetGamerules():GetGameStarted() then
        return
    end
    
    if not self.infectedChooseDelay then
        return
    end
    
    self.infectedChooseDelay = self.infectedChooseDelay - IMGameMaster.kUpdatePeriod
    if self.infectedChooseDelay <= 0 then
        self.infectedChooseDelay = nil
        self.pickedInfected = true
        
        PickInfected(self)
    end
    
end

local function UpdateCysts(self)
    
    -- regular cyst propagation
    self.nextCyst = self.nextCyst or 0
    if self.nextCyst <= 0 then
        if GetCystManager():AddNewCyst() then -- keep trying until successful.
            self.nextCyst = self:GetCystUpdatePeriod() -- changes based on how well marines are doing.
        end
    end
    
    self.nextCyst = self.nextCyst - IMGameMaster.kUpdatePeriod
    
    -- rapid cyst propagation
    for i=#self.fastCysts, 1, -1 do
        GetCystManager():AddNewCyst(self.fastCysts[i][1])
        self.fastCysts[i][2] = self.fastCysts[i][2] - 1
        if self.fastCysts[i][2] <= 0 then
            -- finished spawning that many cysts, can return now.
            table.remove(self.fastCysts, i)
        end
    end
    
end

local function UpdateAirChangeIndicatorByRatio(self, ratio)
    
    local rate = 0
    local fracStepped = 0.0
    
    if ratio >= 1 then
        ratio = ratio * IMGameMaster.kRatioPositiveBoost
        local frac = (ratio-1) / (IMGameMaster.kRatioChangeMax-1)
        frac = math.min(1, frac)
        fracStepped = math.ceil(4*frac) - 1
    else
        local frac = ((ratio-1) / (IMGameMaster.kRatioChangeMin-1))
        fracStepped = math.ceil(-4*frac)
    end
    
    fracStepped = math.min(math.max(fracStepped, -3), 3)
    
    GetAirStatusBlip():SetChangeRate(fracStepped)
    
end

local function UpdateAirQuality(self)
    
    local deltaTime = IMGameMaster.kUpdatePeriod
    local rateOfChange = 0.0
    local ratio = self:GetAirQualityChangeRatio()
    ratio = math.max(math.min(ratio, IMGameMaster.kRatioChangeMax), IMGameMaster.kRatioChangeMin)
    if ratio >= 1 then
        -- increasing, good for marines
        local interp = (ratio - 1) / (IMGameMaster.kRatioChangeMax - 1)
        rateOfChange = IMGameMaster.kAirQualityChangePerSecondMax * interp * IMGameMaster.kRatioPositiveBoost
    else
        -- decreasing, bad for marines
        local interp = 1.0 - ((ratio - IMGameMaster.kRatioChangeMin) / (1.0 - IMGameMaster.kRatioChangeMin))
        rateOfChange = -IMGameMaster.kAirQualityChangePerSecondMax * interp
    end
    
    UpdateAirChangeIndicatorByRatio(self, ratio)
    
    rateOfChange = rateOfChange * deltaTime
    self.airQFraction = self.airQFraction + rateOfChange
    GetAirStatusBlip():SetFraction(self.airQFraction)
    
end

local function UpdateInfestedFeed(self)
    
    local deltaTime = IMGameMaster.kUpdatePeriod
    local iMarines = IMGetInfestedMarines()
    
    local loss = Marine.kInfestedFeedLossRate * deltaTime
    
    for i=1, #iMarines do
        iMarines[i]:DeductInfestedEnergy(loss)
    end
    
end

function IMGameMaster:OnRoundEnd(winner)
    local marines = {}
    local infested = {}
    local function sortPlayer(player)
        if player and player.GetIsAlive and player:GetIsAlive() then
            if player:GetIsInfected() then
                infested[#infested+1] = player
            else
                marines[#marines+1] = player
            end
        end
    end
    GetGamerules():GetTeam1():ForEachPlayer(sortPlayer)

    local winningTeamType = winner and winner.GetTeamType and winner:GetTeamType() or kNeutralTeamType
    if winningTeamType == kMarineTeamType then
        if #marines == 1 then
            local client = marines[1]:GetClient()
            if client then
                Server.SetAchievement(client, "Season_0_3")
            end
        end
    else
        if #marines == 0 then
            for i = 1, #infested do
                if self.initialInfected[infested[i]:GetSteamId()] then
                    local client = infested[i]:GetClient()
                    Server.SetAchievement(client, "Season_0_2")
                end
            end
        end
    end
end

function IMGameMaster:GetAirQuality()
    return self.airQFraction
end

function IMGameMaster:ReportRepairedExtractor(extractor)
    
    self:EnsureExtractorHasBlip(extractor)
    
    local index = self:GetDamagedPurifierIndexByEntity(extractor)
    if index then
        local blip = Shared.GetEntity(self.damagedPurifiers[index].blipId)
        blip:SetState(IMAirPurifierBlip.kPurifierState.Fixed)
        blip:DestroyAfterRepairWait()
    end
    
end

function IMGameMaster:ReportDestroyedExtractor(extractor)
    
    local blipId = extractor.purifierBlipId
    if not blipId then
        return
    end
    
    local blip = Shared.GetEntity(blipId)
    if blip then
        blip:SetState(IMAirPurifierBlip.kPurifierState.Destroyed)
        local index = self:GetDamagedPurifierIndexByEntity(blip)
        table.remove(self.damagedPurifiers, index)
    end
    
end

-- saved, but not repaired.  Ie no longer taking damage, but still damaged.
function IMGameMaster:ReportSavedExtractor(extractor)
    
    self:EnsureExtractorHasBlip(extractor)
    
    local index = self:GetDamagedPurifierIndexByEntity(extractor)
    if index then
        local blip = Shared.GetEntity(self.damagedPurifiers[index].blipId)
        blip:SetState(IMAirPurifierBlip.kPurifierState.Damaged)
    end
    
end

-- taking damage!
function IMGameMaster:ReportExtractorBeingDamaged(extractor)
    
    self:EnsureExtractorHasBlip(extractor)
    
    -- setup how much time the extractor has before it dies.
    local duration = IMComputeTimeRequiredToSave(extractor)
    if duration then
        extractor:SetCorrosionDamageFactorByTTK(duration)
    end
    
    local index = self:GetDamagedPurifierIndexByEntity(extractor)
    if index then
        local blip = Shared.GetEntity(self.damagedPurifiers[index].blipId)
        blip:SetState(IMAirPurifierBlip.kPurifierState.BeingDamaged)
    end
    
end


function IMGameMaster:EnsureExtractorHasBlip(extractor)
    
    local index = self:GetDamagedPurifierIndexByEntity(extractor)
    if not index then
        self:AddDamagedPurifier(extractor)
    end
    
end

local function GetObjectiveForMarine(self, marine)
    
    if GetGamerules():GetGameStarted() then
        if self:GetHasInfectedBeenChosenYet() then
            if marine.GetIsInfected and marine:GetIsInfected() then
                return Marine.kObjective.Infected
            else
                return Marine.kObjective.NotInfected
            end
        else
            return Marine.kObjective.NobodyInfected
        end
    end
    
    return Marine.kObjective.GameOver
    
end

local function UpdatePlayerObjectives(self)
    
    -- set all players objectives
    local marines = GetGamerules():GetTeam1():GetPlayers()
    for i=1, #marines do
        if marines[i] and marines[i].SetObjective then
            marines[i]:SetObjective(GetObjectiveForMarine(self, marines[i]))
        end
    end
    
end

function IMGameMaster:OnUpdate(deltaTime)
    
    UpdatePlayerObjectives(self)
    
    if not GetGamerules():GetGameStarted() then
        return
    end
    
    self.throttle = self.throttle or 0
    self.throttle = self.throttle + deltaTime
    if self.throttle >= IMGameMaster.kUpdatePeriod then
        self.throttle = 0
    else
        return
    end
    
    UpdateQueuedDamages(self)
    UpdateInfectionPick(self)
    UpdateCysts(self)
    UpdateAirQuality(self)
    UpdateInfestedFeed(self)
    UpdateGameMasterDuties(self, IMGameMaster.kUpdatePeriod)
    
end

function IMGameMaster:QueuePurifierDamage(purifier)
    
    local duration = IMComputeTimeRequiredToSave(purifier)
    self.queuedDamages = self.queuedDamages or {}
    table.insert(self.queuedDamages, purifier:GetId())
    
end

function IMGameMaster:GetDamagedPurifierIndexByEntity(ent)
    
    local id = ent:GetId()
    for i=1, #self.damagedPurifiers do
        if id == self.damagedPurifiers[i].purId or id == self.damagedPurifiers[i].blipId then
            return i
        end
    end
    
    return nil
    
end

local function GetIsDamaged(self)
    return (self:GetHealth() < self:GetMaxHealth() - 0.01) and (self:GetArmor() < self:GetMaxArmor() - 0.01)
end

function IMGameMaster:UpdateExtractor(purifier)
    
    -- figure out what needs doing
    if not purifier then
        return
    end
    
    if not(purifier.GetIsAlive and purifier:GetIsAlive()) then
        -- it's dead.  Ensure the blip is set to dead.
        self:ReportDestroyedExtractor(purifier)
    else
        -- it's alive
        if purifier.isCorroded then
            -- it's just become corroded
            self:ReportExtractorBeingDamaged(purifier)
        else
            -- see if it needs repairing
            if GetIsDamaged(purifier) then
                -- it's just become un-corroded
                self:ReportSavedExtractor(purifier)
            else
                -- it's just been fully repaired and an elapsed time for keeping it around has ended.
                self:ReportRepairedExtractor(purifier)
            end
        end
    end
    
end

function IMGameMaster:AddDamagedPurifier(purifier)
    
    local newBlip = CreateEntity(IMAirPurifierBlip.kMapName, purifier:GetOrigin(), kMarineTeamType)
    newBlip:SetEntityId(purifier:GetId())
    
    local purId = purifier:GetId()
    local blipId = newBlip:GetId()
    
    self.damagedPurifiers = self.damagedPurifiers or {}
    for i=#self.damagedPurifiers,1,-1 do
        if self.damagedPurifiers[i].purId == purId then
            local oldBlip = Shared.GetEntity(self.damagedPurifiers[i].blipId)
            if oldBlip then
                DestroyEntity(oldBlip)
            end
            self.damagedPurifiers[i].blipId = blipId
            return
        end
    end
    
    table.insert(self.damagedPurifiers,
    {
        purId = purId,
        blipId = blipId,
    })
    
end

function IMGameMaster:RemoveDamagedPurifier(purifier)
    
    local purId = purifier:GetId()
    
    self.damagedPurifiers = self.damagedPurifiers or {}
    for i=1, #self.damagedPurifiers do
        local iterPurId = self.damagedPurifiers[i].purId
        if iterPurId == purId then
            local blip = Shared.GetEntity(self.damagedPurifiers[i].blipId)
            assert(blip)
            DestroyEntity(blip)
            table.remove(self.damagedPurifiers, i)
            return
        end
    end
    
    Log("Attempted to remove purifier from damaged purifiers table that didn't exist! (%s)", purifier)
    
end

local function OnUpdateGameMaster(deltaTime)
    GetGameMaster():OnUpdate(deltaTime)
end
Event.Hook("UpdateServer", OnUpdateGameMaster)
