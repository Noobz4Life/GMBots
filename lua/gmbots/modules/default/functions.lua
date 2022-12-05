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

function GMBots:IsDoorOpened( door ) // https://wiki.facepunch.com/gmod/Entity:GetInternalVariable yes i copied this from the gmod wiki because im lazy, leave me alone :(
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

local function getNavHidingSpot()
	local navAreas = navmesh.GetAllNavAreas()
	if #navAreas > 0 then
		local i = 0
		local area = nil
		while not area or #area:GetHidingSpots() <= 0 and i < 1000 do
			i = i + 1
			area = navAreas[math.random(1,#navAreas)]
		end
		if area and #area:GetHidingSpots() > 0 then
			local spot = area:GetHidingSpots()[math.random(1,#area:GetHidingSpots())]
			return spot or Vector()
		end
	end
	return Vector()
end
GMBots.GetHidingSpot = getNavHidingSpot

function GMBots:AddSpotType(name,addCommands)
	GMBots.Spots = GMBots.Spots or {}
	if not GMBots.Spots[name] then
		GMBots.Spots[name] = {}

		GMBots["Get"..name.."Spot"] = function(key)
			if GMBots.Spots[name][key] then return GMBots.Spots[name][key] end
			print(GMBots.Spots[name])
			if #GMBots.Spots[name] <= 0 then
				local navAreas = navmesh.GetAllNavAreas()
				if #navAreas > 0 then
					local i = 0
					local backupArea = nil
					while (not backupArea or #backupArea:GetHidingSpots() <= 0) and i < 1000 do
						i = i + 1
						backupArea = navAreas[math.random(1,#navAreas)]
					end
					local backupSpot = backupArea:GetHidingSpots()[math.random(1,#backupArea:GetHidingSpots())]
					return backupSpot
				end
			end

			return GMBots.Spots[name][key] or GMBots.Spots[name][math.random(1,#GMBots.Spots[name])] or table.Random(GMBots.Spots[name]) or Vector()
		end

		GMBots["Add"..name.."Spot"] = function(vector)
			local spot = vector or Vector()
			GMBots.Spots[name][#GMBots.Spots[name] + 1] = spot

			GMBots["Save"..name.."Spots"]()

			GMBots:Msg("Added "..name.." spot at "..tostring(vector))

			return spot
		end

		local fileDir = "gmbots/spots/"..name.."/"..game.GetMap()..".json"
		GMBots["Load"..name.."Spots"] = function()
			local json = file.Read( fileDir, "DATA" )
			if json then
				local jsonSpots = util.JSONToTable(json)
				local spots = {}

				// Make sure the loaded json is sequential, otherwise stuff will break
				for _,v in pairs(jsonSpots) do
					if v then
						spots[#spots + 1] = v
					end
				end

				GMBots.Spots[name] = spots
			end
		end

		GMBots["Save"..name.."Spots"] = function(prettyPrint)
			file.Write( fileDir, util.TableToJSON( GMBots.Spots[name], prettyPrint ) )
		end
		GMBots["Load"..name.."Spots"]()

		if addCommands or addCommands == nil then
			self:AddCommand("gmbots_add_"..string.lower(name).."_spot",function(ply,cmd,args)
				if not SERVER then return end
				print(ply:IsSuperAdmin())
				if not (ply and ply:IsValid()) or not (ply and ply:IsValid() and ply:IsSuperAdmin()) then return self:Msg("You're not an admin!") end

				local pos = nil
				if (ply and ply:IsValid()) and #args < 3 then
					pos = ply:GetPos()
				else
					if #args > 3 then
						pos = Vector(tonumber(args[1]) or 0,tonumber(args[2]) or 0,tonumber(args[3]) or 0)
					else
						return self:Msg("Can't add "..string.lower(name).." spot due to no position being inputted!")
					end
				end

				//GMBots:Msg("Adding "..string.lower(name).." spot at: "..(pos.x..pos.y..pos.z))
				return GMBots["Add"..name.."Spot"](pos)
			end)
		end
	end
end
GMBots:AddSpotType("Wander",true)
--[[
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
]]

function CUSERCMD:AddButtons(...)
	return self:SetButtons(bit.bor(self:GetButtons(),...))
end

PLAYER.RealConCommand = PLAYER.RealConCommand or PLAYER.ConCommand
function PLAYER:ConCommand(str)
	if self:IsGMBot() then // concommand doesn't work on bots, workaround by using the internal function concommand.Run
		local split = string.Split( str," " )
		local args = table.Copy(split)

		table.remove(args,1)
		local argsStr = table.concat(args," ")
		concommand.Run(self,split[1],args,argsStr)
	end

	return self:RealConCommand(str)
end

function PLAYER:ClearGMBotVars()
	self.__GMBots = self.__GMBots or {}
	self.__GMBots.Vars = {}
end

function PLAYER:SetGMBotVar(key,value)
	self.__GMBots = self.__GMBots or {}
	self.__GMBots.Vars = self.__GMBots.Vars or {}

	self.__GMBots.Vars[key] = value
end

function PLAYER:GetGMBotVar(key)
	self.__GMBots.Vars = self.__GMBots.Vars or {}
	return self.__GMBots.Vars[key]
end

PLAYER.ClearGMBotsVar = PLAYER.ClearGMBotVar
PLAYER.SetGMBotsVar = PLAYER.SetGMBotVar
PLAYER.GetGMBotsVar = PLAYER.GetGMBotVar

function PLAYER:BotJump()
	if not ( SERVER and self and self:IsValid() and self:IsGMBot() and self:Alive() and self.GMBotsCMD ) then return end
	local cmd = self.GMBotsCMD

	self.__GMBot_JumpTimer = self.GMBot_JumpTimer or 0

	if CurTime() > self.__GMBot_JumpTimer and not self.GMBotDontJump then
		cmd:SetButtons(bit.bor(cmd:GetButtons(),IN_JUMP))
		self.__GMBot_JumpTimer = CurTime() + math.random(0.5,0.8)
	end
end

function PLAYER:IsGMBot()
	return self.GMBot or (self:GetInfoNum( "gmbots_become_bot", 0 ) > 0)
end

local function botChat(self,text,teamOnly)
	if(self and self:IsValid()) then
		self:SetNWBool("__GMBots__GMBotIsTyping",false)
		self.GMBotIsTyping = false

		if !self.GMBot then return end
		self:Say( tostring( text ), teamOnly )
	end
end

function PLAYER:BotChat(text,teamOnly,typingTime)
	if(self and self:IsValid() and self.GMBot) then
		self.__GMBots_NextChat = self.__GMBots_NextChat or 1
		if (CurTime() <= self.__GMBots_NextChat) then return end

		self.GMBotIsTyping = true
		self:SetNWBool("__GMBots__GMBotIsTyping",true)

		if typingTime ~= nil and (typingTime == true or typingTime <= 0) then
			botChat(self,text,teamOnly)
		else
			typingTime = typingTime or (string.len(text) * (math.random(8,10)/100))

			self:BotDebug("Typing text in "..typingTime..": "..text)
			timer.Create( "__GMBotsChatTimer____"..tostring(text), typingTime, 1, function()
				if (CurTime() <= self.__GMBots_NextChat) then return end
				botChat(self,text,teamOnly)
			end)
		end
	end
end

function PLAYER:BotLookAt(pos)
	if self and self:IsValid() and pos and self.GMBotsCMD then
		assert(not (pos and IsValid(pos)),"Missing/invalid argument 1, argument 1 should be a entity or vector value.")

		if IsEntity(pos) and pos:IsValid() then
			pos = pos:GetPos()
		end
		local ang = ( pos - self:EyePos() ):GetNormalized():Angle()
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
	if not ( SERVER and self and self:IsValid() and self:IsGMBot() and self:Alive() and self.GMBotsCMD ) then return end
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