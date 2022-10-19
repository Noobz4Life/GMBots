local PLAYER = FindMetaTable( "Player" )
local CUSERCMD = FindMetaTable( "CUserCmd" )

function GMBots:IsDoor(door)
	if(door and IsValid(door)) then
		local doorClass = door:GetClass()
		if doorClass == "func_door" or doorClass == "func_door_rotating" or doorClass == "prop_door_rotating" then
			return true
		end
	end
	return false
end

function GMBots:IsDoorLocked( door )
	return false
end

function GMBots:IsDoorOpened( door ) -- https://wiki.facepunch.com/gmod/Entity:GetInternalVariable yes i copied this from the gmod wiki because im lazy, leave me alone :(
	if not (door and door:IsValid()) then return false end
	local doorClass = door:GetClass()

	if ( doorClass == "func_door" or doorClass == "func_door_rotating" ) then
		return door:GetInternalVariable( "m_toggle_state" ) == 0
	elseif ( doorClass == "prop_door_rotating" ) then
		return door:GetInternalVariable( "m_eDoorState" ) == 2
	end
	return false
end

function GMBots:IsDoorOpening( door )
	if not (door and door:IsValid()) then return false end
	local doorClass = door:GetClass()

	if ( doorClass == "func_door" or doorClass == "func_door_rotating" ) then
		return door:GetInternalVariable( "m_toggle_state" ) == 0
	elseif ( doorClass == "prop_door_rotating" ) then
		return door:GetInternalVariable( "m_eDoorState" ) ~= 0 and door:GetInternalVariable( "m_eDoorState" ) ~= 1
	end
	return false
end

function GMBots:IsDoorOpen( door )
	return self:IsDoorOpened(door) or self:IsDoorOpening(door)
end

function GMBots:GetHidingSpot()
	if not self.NavHidingSpots then
		local navareas = navmesh.GetAllNavAreas()
		local navhiding = {}
		if #navareas > 0 then
			for i = 1,#navareas do
				local areahiding = navareas[i]:GetHidingSpots()
				if #areahiding > 0 then
					for o = 1,#areahiding do
						if not areahiding[o] then continue end
						table.insert(navhiding,areahiding[o])
					end
				end
			end
		end
		if #navhiding > 0 then
			self.NavHidingSpots = navhiding
		end
	end
	return self.NavHidingSpots[math.random(1,#self.NavHidingSpots)]
end

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

function PLAYER:BotWander()
	self.WanderSpot = self.WanderSpot or GMBots:GetHidingSpot() or self:GetPos()
	self.WanderTime = self.WanderTime or CurTime()+math.random(10,60)
	local dist = self.WanderSpot:Distance(self:GetPos())
	if dist > 20 then
		self:Pathfind(self.WanderSpot,true)
	else
		self.WanderTime = self.WanderTime/1.01
		if not self.WanderReached then
			self:BotDebug("Reached wander spot.")
			self.WanderReached = true
		end
	end
	if CurTime() > self.WanderTime then
		self.WanderTime = nil
		self.WanderSpot = nil
		self.WanderReached = false
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

function PLAYER:BotVisible(target)
	if self and target and IsValid(self) and IsValid(target) and self:Visible(target) then
		local target_pos = Vector(0,0,0)
		if target and target:IsValid() and isvector( target ) then
			target_pos = target
		else
			target_pos = target:GetPos()
		end
		local eye_pos = self:EyePos()

		local eyeToTarget = (target_pos - eye_pos):GetNormalized()
		local degreeLimit = self:GetFOV() -- We use this incase this is a Player-Bot instead of a Real Bot.
		local dotProduct = eyeToTarget:Dot(self:EyeAngles():Forward())
		local aimDegree = math.deg(math.acos(dotProduct))
		if (aimDegree >= degreeLimit) then
			-- They're not on the player's screen, return false.
			return false
		else
			-- They're on the player's screen, return true.
			return true
		end
	end

	return false
end