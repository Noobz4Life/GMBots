local PLAYER = FindMetaTable( "Player" )

function PLAYER:BotJump()
	if not ( SERVER and self and self:IsValid() and self.GMBot and self:Alive() and self.GMBotsCMD ) then return end
	local cmd = self.GMBotsCMD
	
	self.GMBot_JumpTimer = self.GMBot_JumpTimer or 0
	
	if CurTime() > self.GMBot_JumpTimer and not self.BotDontJump then
		print("test")
		cmd:SetButtons(bit.bor(cmd:GetButtons(),IN_JUMP))
		self.GMBot_JumpTimer = CurTime() + math.random(0.5,0.8)
	end
end

function PLAYER:IsGMBot()
	return self.GMBot
end

function PLAYER:AttackPlayer(enemy,mindist,maxdist,holdattack)
	if not ( SERVER and self and self:IsValid() and self.GMBot and self:Alive() and self.GMBotsCMD ) then return end
	if enemy and enemy:IsValid() and enemy:Alive() then
		
	end
end