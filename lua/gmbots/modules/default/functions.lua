local PLAYER = FindMetaTable( "Player" )
local CUSERCMD = FindMetaTable( "CUserCmd" )

function CUSERCMD:AddButtons(...)
	return self:SetButtons(bit.bor(self:GetButtons(),...))
end

function PLAYER:BotJump()
	if not ( SERVER and self and self:IsValid() and self.GMBot and self:Alive() and self.GMBotsCMD ) then return end
	local cmd = self.GMBotsCMD

	self.GMBot_JumpTimer = self.GMBot_JumpTimer or 0

	if CurTime() > self.GMBot_JumpTimer and not self.BotDontJump then
		cmd:SetButtons(bit.bor(cmd:GetButtons(),IN_JUMP))
		self.GMBot_JumpTimer = CurTime() + math.random(0.5,0.8)
	end
end

function PLAYER:IsGMBot()
	return self.GMBot
end

function PLAYER:BotChat(text,teamOnly)
	if(self and self:IsValid() and self.GMBot) then
		self.__GMBots_NextChat = self.__GMBots_NextChat or 1
		if(CurTime() > self.__GMBots_NextChat) then
			self:Say( tostring( text ), teamOnly )
		end
	end
end

function PLAYER:BotLookAt(pos)
	if self and self:IsValid() and pos and self.GMBotsCMD then
		assert(not (pos and IsValid(pos)),"Missing/invalid argument 1, argument 1 should be a entity or vector value.")

		if IsEntity(pos) and pos:IsValid() then
			pos = pos:GetPos()
		end
		local ang = ( pos - self:GetPos() ):GetNormalized():Angle()
		self:SetEyeAngles(ang)
		self.GMBotsCMD:SetViewAngles( ang )
	end
end

function PLAYER:BotRetreatFrom(pos)
	assert(not (pos and IsValid(pos)),"Missing/invalid argument 1, argument 1 should be a entity or vector value.")

	local currentArea = navmesh.GetNearestNavArea( self:GetPos() )
	if currentArea and pos and self.GMBotsCMD then
		local cmd = self.GMBotsCMD
		if IsEntity(pos) and pos:IsValid() then
			pos = pos:GetPos()
		end
		local lastDist = 0
		local gotoArea = currentArea
		for k,neighbor in pairs(currentArea:GetAdjacentAreas()) do
			if not neighbor then continue end
			local dist = neighbor:GetCenter():Distance(pos)
			if dist > lastDist then
				lastDist = dist
				gotoArea = neighbor
			end
		end

		local posDist = pos:Distance(self:GetPos())
		local gotoDist = pos:Distance(gotoArea:GetCenter())
		if posDist < gotoDist then
			self:BotLookAt(pos)
			if posDist < 250 then
				cmd:SetForwardMove(-1000)
				if posDist < 150 then
					cmd:SetButtons(bit.bor(cmd:GetButtons(),IN_SPEED))
				end
			elseif posDist < 350 then
				cmd:SetForwardMove(-100)
			end
			return
		end

		if gotoArea and gotoArea:IsValid() then
			debugoverlay.Sphere( gotoArea:GetCenter(), 8, 0.01, color_white, true  )
			return self:Pathfind(gotoArea:GetCenter(),false)
		end

	end
end

PLAYER.BotRetreat = PLAYER.BotRetreatFrom

function PLAYER:BotAttackPlayer(enemy,mindist,maxdist,holdattack)
	if not ( SERVER and self and self:IsValid() and self.GMBot and self:Alive() and self.GMBotsCMD ) then return end
	if enemy and enemy:IsValid() and enemy:Alive() then

	end
end