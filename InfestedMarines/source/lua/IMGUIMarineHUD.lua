

    


local originalHUDUpdate
originalHUDUpdate = Class_ReplaceMethod( "GUIMarineHUD", "Update", function(self)
	originalHUDUpdate(self)
    
	self.commanderName:SetIsVisible(false)
	self.resourceDisplay.teamText:SetIsVisible(false)
	self.resourceDisplay.background:SetIsVisible(false)
	if self.minimapBackground then
		self.minimapBackground:SetIsVisible(false)
    end
    
	--if self.gameTime then
		--self.gameTime:SetIsVisible(false)
	--end
end)
