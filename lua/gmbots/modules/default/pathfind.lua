local PLAYER = FindMetaTable( "Player" )
local CNAVAREA = FindMetaTable( "CNavArea" )
GMBots.CustomBlockedNavAreas = GMBots.CustomBlockedNavAreas or {}
CNAVAREA.InternalIsBlocked = CNAVAREA.InternalIsBlocked or CNAVAREA.IsBlocked

function CNAVAREA:IsBlocked(...)
	return GMBots.CustomBlockedNavAreas[self:GetID()] or self:InternalIsBlocked(...)
end

local blockWhitelist = {
	"prop_physics",
	"prop_physics_multiplayer",
	"func_button",
	"player"
}

function CNAVAREA:CheckBlocked()
	--[[
	-- Taken from https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/nav_area.cpp line 4843-4847
	const float sizeX = MAX( 1, MIN( GetSizeX()/2 - 5, HalfHumanWidth ) );
	const float sizeY = MAX( 1, MIN( GetSizeY()/2 - 5, HalfHumanWidth ) );
	Extent bounds;
	bounds.lo.Init( -sizeX, -sizeY, 0 );
	bounds.hi.Init( sizeX, sizeY, VEC_DUCK_HULL_MAX.z - HalfHumanHeight );
	]]

	// -16.000000 -16.000000 0.000000
	// 16.000000 16.000000 72.000000

	local origin = self:GetCenter()
	local mins = Vector(-16,-16,0)
	local maxs = Vector(16,16,72/2)

	local trace = {
		start = origin,
		endpos = origin,
		mins = mins,
		maxs = maxs,
		filter = function(ent)
			if table.HasValue(blockWhitelist,ent:GetClass()) then return false end
			if GMBots:IsDoor(ent) and !GMBots:IsDoorLocked(ent) then return false end
			return true
		end,
		mask = MASK_PLAYERSOLID,
		//collisiongroup = COLLISION_GROUP_WORLD,
		ignoreworld = true
	}
	local traceResult = util.TraceHull(trace)
	if traceResult.StartSolid then
		GMBots.CustomBlockedNavAreas[self:GetID()] = true
		if GMBots:IsDebugMode() then debugoverlay.Box(origin,mins,maxs,1,Color(255,0,0)) end
	else
		GMBots.CustomBlockedNavAreas[self:GetID()] = nil
		//debugoverlay.Box(origin,mins,maxs,2,Color(0,255,0))
	end
	return GMBots.CustomBlockedNavAreas[self:GetID()]
end

function GMBots:UpdateNavBlocked()
	for a,b in pairs(navmesh.GetAllNavAreas()) do
		b:CheckBlocked()
	end
end
GMBots:UpdateNavBlocked()

local function updateEntNavArea(ent)
	if ent and IsValid(ent) then
		local navarea = navmesh.GetNavArea( ent:GetPos(), 100 ) or navmesh.GetNearestNavArea( ent:GetPos() )
		print("test")
		if navarea then navarea:CheckBlocked() end
	end
end

GMBots:AddInternalHook("EntityKeyValue",updateEntNavArea)
GMBots:AddInternalHook("KeyPress",function(ply,key)
	print(key,IN_USE)
	if ply and ply:IsValid() and key == IN_USE then
		local navarea = navmesh.GetNavArea( ply:GetPos(), 100 ) or navmesh.GetNearestNavArea( ply:GetPos() )
		if navarea then
			navarea:CheckBlocked()

			local neighbors = navarea:GetAdjacentAreas()
			for i = 1,#neighbors do
				local neighbor = neighbors[i]
				if neighbor then neighbor:CheckBlocked() end
			end
		end
	end
end)
GMBots:AddInternalHook("PostCleanupMap",function() GMBots:UpdateNavBlocked() end)

local function heuristic_cost_estimate( start, goal )
	// Perhaps play with some calculations on which corner is closest/farthest || whatever
	return start:GetCenter():Distance( goal:GetCenter() )
end

local function finalize_path(total_path)
	local new_path = {}
	for i = 1,#total_path do
		local point = total_path[i]
		if point then
			new_path[#new_path + 1] = point:GetCenter()
		end
	end
	return new_path
end

// using CNavAreas as table keys doesn't work, we use IDs
local function reconstruct_path( cameFrom, current )
	local total_path = { current }

	current = current:GetID()
	while ( cameFrom[ current ] ) do
		current = cameFrom[ current ]
		table.insert( total_path, navmesh.GetNavAreaByID( current ) )
	end
	return finalize_path(total_path)
end

local function drawThePath( path, time )
	if not GMBots:IsDebugMode() then return end
	local prevArea
	for _, area in pairs( path ) do
		//debugoverlay.Sphere( area, 8, time or 9, color_white, true  )
		if ( prevArea ) then
			debugoverlay.Line( area, prevArea, time or 9, Color(1-(_ / #path) * 255,0,0), true )
		end
		prevArea = area

		local navarea = navmesh.GetNearestNavArea(area)
	end
end

local function isPathBlocked(area,neighbor)
	area = area or neighbor
	neighbor = neighbor or area
	return false
end

local function Astar( start, goal, ply )
	if ( !IsValid( start ) || !IsValid( goal ) ) then return false end
	if ( start == goal ) then return true end

	start:ClearSearchLists()

	start:AddToOpenList()

	local cameFrom = {}

	start:SetCostSoFar( 0 )

	start:SetTotalCost( heuristic_cost_estimate( start, goal ) )
	start:UpdateOnOpenList()

	local closest_accessible = nil
	local closest_accessible_distance = 0

	while ( !start:IsOpenListEmpty() ) do
		local current = start:PopOpenList() // Remove the area with lowest cost in the open list && return it
		if ( current == goal ) then
			return reconstruct_path( cameFrom, current )
		end
		current:AddToClosedList()

		for k, neighbor in pairs( current:GetAdjacentAreas() ) do
			local newCostSoFar = current:GetCostSoFar() + heuristic_cost_estimate( current, neighbor )

			if ( neighbor:IsUnderwater() || neighbor:IsBlocked(nil,false))
			|| ( ( neighbor:IsOpen() || neighbor:IsClosed() ) && neighbor:GetCostSoFar() <= newCostSoFar )
			|| ( isPathBlocked(current,neighbor)) then // Add your own area filters || whatever here
				continue
			end

			if(GetConVar("gmbots_pf_skip_avoid"):GetInt() > 0 && neighbor:HasAttributes(NAV_MESH_AVOID)) then
				print("avoiding")
				continue
			end

			neighbor:SetCostSoFar( newCostSoFar );
			neighbor:SetTotalCost( newCostSoFar + heuristic_cost_estimate( neighbor, goal ) )

			if ( neighbor:IsClosed() ) then
				neighbor:RemoveFromClosedList()
			end

			if ( neighbor:IsOpen() ) then
				// This area is already on the open list, update its position in the list to keep costs sorted
				neighbor:UpdateOnOpenList()
			else
				neighbor:AddToOpenList()
			end

			local distance = neighbor:GetCenter():Distance(goal:GetCenter())
			if(!closest_accessible || distance < closest_accessible_distance) then
				closest_accessible = neighbor
				closest_accessible_distance = distance
			end

			cameFrom[ neighbor:GetID() ] = current:GetID()
		end
	end
	if(closest_accessible) then return Astar(start,closest_accessible,ply) end
	return false
end

function AstarVector( start, goal )
	local startArea = navmesh.GetNearestNavArea( start )
	local goalArea = navmesh.GetNearestNavArea( goal )
	return Astar( startArea, goalArea )
end

local function canTeleport(bot,pos)
	local cantTeleport = false
	local teleportCheck = GetConVar("gmbots_pf_teleportation"):GetInt()
	if teleportCheck > 2 then return true end

	local players = player.GetAll()
	for i = 1,#players do
		local ply = players[i]
		if(cantTeleport || ply == bot || !ply || !ply:IsValid() || !ply:IsPlayer() || ply:IsGMBot()) then continue end
		for j = 1,2 do
			local startPos = bot:EyePos()
			if j == 2 then
				if teleportCheck == 1 then
					startPos = pos + (bot:EyePos() - bot:GetPos())
				else
					continue
				end
			end

			if ply:VisibleVec(startPos) || ply:VisibleVec(bot:EyePos()) || ply:VisibleVec(bot:GetPos()) then
				cantTeleport = true
			end

			for k = 1,8 do
				if cantTeleport then continue end

				local traceData = {}
				traceData.start = startPos
				traceData.endpos = ply:EyePos()
				traceData.mask = MASK_VISIBLE
				traceData.collisiongroup = COLLISION_GROUP_WORLD

				local trace = util.TraceLine(traceData,bot)
				if !trace.Hit then
					cantTeleport = true
				end
			end
		end
	end
	return !cantTeleport
end

local rePathDelay = 0.5
function PLAYER:Pathfind(pos,cheap)
	local ply = self
    local cmd = ply.GMBotsCMD || ply.cmd

	// Only run this code on bots
	if !( cmd && ply && ply:IsValid() && ply:IsGMBot() ) then return end

    if NUBZIGATE && self.Nubzigate then
        return self:Nubzigate(pos,cheap)
    end

	cmd:ClearButtons()
	cmd:ClearMovement()
	if GMBots:IsDebugMode() then debugoverlay.Sphere(pos,10,0.1,Color(255,255,0),true) end

	local currentArea = navmesh.GetNavArea( ply:GetPos(), 100 ) || navmesh.GetNearestNavArea( ply:GetPos() )

	// internal variable to regenerate the path every X seconds to keep the pace with the target player
	ply.lastRePath = ply.lastRePath || 0

	// internal variable to limit how often the path can be (re)generated
	ply.lastRePath2 = ply.lastRePath2 || 0
	if ( ply.path && ply.lastRePath + rePathDelay < CurTime() && currentArea != ply.targetArea ) then
		ply.path = nil
		ply.lastRePath = CurTime()
	end

	local targetPos = pos or self:GetPos()
	local targetArea = navmesh.GetNavArea( targetPos, 100 ) or navmesh.GetNearestNavArea( targetPos )
	if ((targetArea == currentArea) or (targetPos:Distance(self:GetPos()) < 64 && (!targetArea or targetArea:IsConnected(currentArea or targetArea)))) and targetPos:Distance(self:GetPos()) > 16 then
		cmd:SetViewAngles( ( pos - ply:GetPos() ):GetNormalized():Angle() )
		cmd:SetForwardMove( 1000 )
		return
	end

	if ( !ply.path && ply.lastRePath2 + rePathDelay < CurTime() ) then
		ply.targetArea = nil
		ply.path = Astar( currentArea, targetArea, self)
		if ( !istable( ply.path ) ) then // We are in the same area as the target, || we can't navigate to the target
			ply.path = nil // Clear the path, bail && try again next time
			ply.lastRePath2 = CurTime()
			return
		end
		//PrintTable( ply.path )

		// TODO: Add inbetween points on area intersections
		// TODO: On last area, move towards the target position, not center of the last area
		table.remove( ply.path ) // Just for this example, remove the starting area, we are already in it!
		drawThePath( ply.path, rePathDelay+0.05 )
	end

	// We have no path, || its empty (we arrived at the goal), try to get a new path.
	if ( !ply.path || #ply.path < 1 ) then
		ply.path = nil
		ply.targetArea = nil
		return
	end

	// We got a path to follow to our target!
	//drawThePath( ply.path, .1 ) // Draw the path for debugging
	// Select the next area we want to go into
	if ( !IsValid( ply.targetArea ) ) then
		ply.targetArea = ply.path[ #ply.path ]
	end

	// The area we selected is invalid || we are already there, remove it, bail && wait for next cycle
	if ( !ply.targetArea || (ply.targetArea:Distance( ply:GetPos() ) < 16) ) then
		table.remove( ply.path ) // Removes last element
		ply.targetArea = nil
		return
	end


	self.lastStuckCheck = self.lastStuckCheck || CurTime()
	if CurTime()-self.lastStuckCheck > 0.5 then
		self.botStuckChecksPassed = self.botStuckChecksPassed || 0
		self.lastUnstuckPos = self.lastUnstuckPos || Vector(0,0,0)

		if self.botStuckChecksPassed > 10 then
			self:BotDebug("I'm stuck!")
			if(GetConVar("gmbots_pf_teleportation"):GetInt() > 0) then
				self:BotDebug("Attempting to unstick...")
				local locationType = math.ceil( GetConVar("gmbots_pf_teleportation_location"):GetInt() )
				local endLocation = nil
				if locationType == 0 && ply.targetArea then
					self:BotDebug("Teleporting to target area of the current path")
					endLocation = ply.targetArea
				elseif currentArea then
					self:BotDebug("Teleporting to the center of the current navarea")
					endLocation = currentArea:GetCenter()
				end
				if canTeleport(ply,endLocation) then
					ply:SetPos(endLocation)
					self.botStuckChecksPassed = 0
				else
					self.botStuckChecksPassed = self.botStuckChecksPassed - 2
				end
			end
		end
		local selfPosNoZ = self:GetPos()
		local lastPosNoZ = self.lastUnstuckPos
		selfPosNoZ = Vector(selfPosNoZ.X,selfPosNoZ.Y,0)
		lastPosNoZ = Vector(lastPosNoZ.X,lastPosNoZ.Y,0)
		if selfPosNoZ:Distance(lastPosNoZ) < 32 then
			if self.botStuckChecksPassed > 2 then
				self:BotJump()
			end
			self.botStuckChecksPassed = self.botStuckChecksPassed + 1
		else
			self.lastUnstuckPos = self:GetPos()
			self.botStuckChecksPassed = math.max(self.botStuckChecksPassed - 2,0)
		end

		self.lastStuckCheck = CurTime()
	end

	local checkArea = currentArea
	local currentTargetArea = navmesh.GetNearestNavArea( ply.targetArea ) or currentArea
	local targetPosArea = currentTargetArea:GetCenter()
	local targetAreaClose = (targetPosArea && targetPosArea:Distance(self:GetPos()) < 24)
	if targetAreaClose then
		checkArea = currentTargetArea
	end
	local checkAreaPos = checkArea:GetCenter()

	local heightDifference = targetPosArea.Z - self:GetPos().Z
	if self:OnGround() && (checkArea:HasAttributes(NAV_MESH_JUMP) || (heightDifference > self:GetStepSize())) && (!checkArea:HasAttributes(NAV_MESH_NO_JUMP) && !checkArea:HasAttributes(NAV_MESH_STAIRS)) then
		self:BotJump()
	end

	if checkArea:HasAttributes(NAV_MESH_CROUCH) then
		cmd:AddButtons(IN_DUCK)
	end

	if checkArea:HasAttributes(NAV_MESH_RUN) then
		cmd:AddButtons(IN_RUN)
	end

	if self:GetMoveType() == MOVETYPE_LADDER then
		self:BotJump()
	end

	// We got the target to go to, aim there && MOVE

	local targetang = ( ply.targetArea - ply:GetPos() ):GetNormalized():Angle()
	cmd:SetViewAngles( targetang )
	cmd:SetForwardMove( 1000 )
	self:SetEyeAngles(targetang)

	local eyetrace = self:GetEyeTrace()
	if (eyetrace && IsValid(eyetrace.Entity) && !GMBots:IsDoorOpen(eyetrace.Entity) && !GMBots:IsDoorLocked(eyetrace.Entity) && !IsValid(eyetrace.Entity:GetInternalVariable("m_hActivator"))) then
		cmd:SetButtons(IN_USE)
		if eyetrace.Entity:GetPos():Distance(self:GetPos()) < 128 then
			eyetrace.Entity:Use(self)
			eyetrace.Entity:SetSaveValue("m_hActivator",self)
		end
	end

	if GMBots:IsDebugMode() then debugoverlay.Line(self:EyePos(),self:EyePos() + cmd:GetViewAngles():Forward()*100,0.1,Color(255,255,0)) end
end