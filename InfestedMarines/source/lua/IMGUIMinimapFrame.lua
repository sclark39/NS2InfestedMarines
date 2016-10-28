local originalHUDUpdate = GUIMinimapFrame.Update
function GUIMinimapFrame:Update(deltatime)
	originalHUDUpdate(self, deltatime)
	self.chooseSpawnText:SetIsVisible(false)
	self.background:SetIsVisible(false)
end