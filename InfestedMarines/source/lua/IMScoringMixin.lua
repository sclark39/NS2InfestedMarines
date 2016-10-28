-- ======= Copyright (c) 2003-2016, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMScoringMixin.lua
--
--    Created by:   Sebastian Schuck (sebastian@naturalselection2.com)
--
--    Adjust the base score system so the player score is collected over multiple rounds.
--    And the scoreboard stats are only updated at rounds end.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

--Only show last rounds final score
function ScoringMixin:GetScore()
	return self.lastroundscore or 0
end

function ScoringMixin:GetDeaths()
	return self.lastrounddeaths or 0
end

function ScoringMixin:GetKills()
	return self.lastroundkills or 0
end

function ScoringMixin:GetAssistKills()
	return self.lastroundassistkills or 0
end

--Stop reseting score at game end etc.
function ScoringMixin:ResetScores()

	self.lastroundscore = self.score
	self.lastroundkills = self.kills
	self.lastroundassistkills = self.assistkills
	self.lastrounddeaths = self.deaths

	self.commanderTime = 0
	self.playTime = 0
	self.marineTime = 0
	self.alienTime = 0

	self.weightedEntranceTimes = {}
	self.weightedEntranceTimes[kTeam1Index] = {}
	self.weightedEntranceTimes[kTeam2Index] = {}

	local teamNum = self:GetTeamNumber()
	if teamNum ~= nil and teamNum == kTeam1Index or teamNum == kTeam2Index then
		table.insert( self.weightedEntranceTimes[teamNum], self:GetRelativeRoundTime() )
	end

	self.weightedExitTimes = {}
	self.weightedExitTimes[kTeam1Index] = {}
	self.weightedExitTimes[kTeam2Index] = {}

end

if Server then
	local oldCopyPlayerDataFrom = ScoringMixin.CopyPlayerDataFrom

	function ScoringMixin:CopyPlayerDataFrom(player)
		self.lastroundscore = player.lastroundscore
		self.lastroundkills = player.lastroundkills
		self.lastroundassistkills = player.lastroundassistkills
		self.lastrounddeaths = player.lastrounddeaths

		oldCopyPlayerDataFrom(self, player)
	end

	local achScore = 500
	local oldAddScore = ScoringMixin.AddScore
	function ScoringMixin:AddScore(...)
		local lastscore = self.score

		oldAddScore(self, ...)

		local client = self:GetClient()
		if client and lastscore < achScore and self.score >= achScore then
			Server.SetAchievement(client, "Season_0_1")
		end
	end
end