local PLAYER = FindMetaTable( "Player" )

local function heuristic_cost_estimate( start, goal )
	// Perhaps play with some calculations on which corner is closest/farthest or whatever
	return start:GetCenter():Distance( goal:GetCenter() )
end

local function convert_path(total_path)
	local new_path = {}
	for i = 1,#total_path do
		local point = total_path[i]
		if point then
			new_path[i] = point:GetCenter()
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
	return convert_path(total_path)
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

	while ( !start:IsOpenListEmpty() ) do
		local current = start:PopOpenList() // Remove the area with lowest cost in the open list and return it
		if ( current == goal ) then
			return reconstruct_path( cameFrom, current )
		end
		current:AddToClosedList()

		for k, neighbor in pairs( current:GetAdjacentAreas() ) do
			local newCostSoFar = current:GetCostSoFar() + heuristic_cost_estimate( current, neighbor )

			if ( neighbor:IsUnderwater() or neighbor:IsBlocked(nil,false))
			or ( ( neighbor:IsOpen() || neighbor:IsClosed() ) && neighbor:GetCostSoFar() <= newCostSoFar ) then // Add your own area filters or whatever here
				continue
			end

			if(GetConVar("gmbots_pf_skip_avoid"):GetInt() > 0 and neighbor:HasAttributes(NAV_MESH_AVOID)) then
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

			cameFrom[ neighbor:GetID() ] = current:GetID()
		end
	end

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
		if(cantTeleport or ply == bot or !ply or !ply:IsValid() or !ply:IsPlayer() or ply:IsGMBot()) then continue end
		for j = 1,2 do
			local startPos = bot:EyePos()
			if j == 2 then
				if teleportCheck == 1 then
					startPos = pos + (bot:EyePos() - bot:GetPos())
				else
					continue
				end
			end

			if ply:VisibleVec(startPos) or ply:VisibleVec(bot:EyePos()) or ply:VisibleVec(bot:GetPos()) then
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
				if not trace.Hit then
					cantTeleport = true
				end
			end
		end
	end
	return not cantTeleport
end

local rePathDelay = 0.5
function PLAYER:Pathfind(pos,cheap)
	local ply = self
    local cmd = ply.GMBotsCMD or ply.cmd


	// Only run this code on bots
	if not ( cmd and ply and ply:IsValid() and ply:IsGMBot() ) then return end

    if NUBZIGATE && self.Nubzigate then
        return self:Nubzigate(pos,cheap)
    end

	cmd:ClearButtons()
	cmd:ClearMovement()

	local currentArea = navmesh.GetNearestNavArea( ply:GetPos() )

	// internal variable to regenerate the path every X seconds to keep the pace with the target player
	ply.lastRePath = ply.lastRePath or 0

	// internal variable to limit how often the path can be (re)generated
	ply.lastRePath2 = ply.lastRePath2 or 0
	if ( ply.path && ply.lastRePath + rePathDelay < CurTime() && currentArea != ply.targetArea ) then
		ply.path = nil
		ply.lastRePath = CurTime()
	end

	local targetPos = pos
	local targetArea = navmesh.GetNearestNavArea( targetPos )
	if targetArea == currentArea and targetPos:Distance(self:GetPos()) > 16 then
		cmd:SetViewAngles( ( pos - ply:GetPos() ):GetNormalized():Angle() )
		cmd:SetForwardMove( 1000 )
		return
	end

	if ( !ply.path && ply.lastRePath2 + rePathDelay < CurTime() ) then
		ply.targetArea = nil
		ply.path = Astar( currentArea, targetArea, self)
		if ( !istable( ply.path ) ) then // We are in the same area as the target, or we can't navigate to the target
			ply.path = nil // Clear the path, bail and try again next time
			ply.lastRePath2 = CurTime()
			return
		end
		//PrintTable( ply.path )

		// TODO: Add inbetween points on area intersections
		// TODO: On last area, move towards the target position, not center of the last area
		table.remove( ply.path ) // Just for this example, remove the starting area, we are already in it!
	end

	// We have no path, or its empty (we arrived at the goal), try to get a new path.
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

	// The area we selected is invalid or we are already there, remove it, bail and wait for next cycle
	if ( !ply.targetArea || ( ply.targetArea:Distance( ply:GetPos() ) < 16) ) then
		table.remove( ply.path ) // Removes last element
		ply.targetArea = nil
		return
	end


	self.lastStuckCheck = self.lastStuckCheck or CurTime()
	if CurTime()-self.lastStuckCheck > 0.5 then
		self.botStuckChecksPassed = self.botStuckChecksPassed or 0
		self.lastUnstuckPos = self.lastUnstuckPos or Vector(0,0,0)

		if self.botStuckChecksPassed > 10 then
			self:BotDebug("I'm stuck!")
			self:BotJump()
			if(GetConVar("gmbots_pf_teleportation"):GetInt() > 0) then
				self:BotDebug("Attempting to unstick...")
				local locationType = math.ceil( GetConVar("gmbots_pf_teleportation_location"):GetInt() )
				local endLocation = nil
				if locationType == 0 and ply.targetArea then
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

		if self:GetPos():Distance(self.lastUnstuckPos) < 32 then
			self.botStuckChecksPassed = self.botStuckChecksPassed + 1
		else
			self.lastUnstuckPos = self:GetPos()
			self.botStuckChecksPassed = 0
		end

		self.lastStuckCheck = CurTime()
	end

	local targetPosArea = navmesh.GetNearestNavArea( ply.targetArea )

	local heightDifference = ply.targetArea.Z - self:GetPos().Z
	if (currentArea:HasAttributes(NAV_MESH_JUMP) or targetPosArea:HasAttributes(NAV_MESH_JUMP)) or (heightDifference > self:GetStepSize()) and (not currentArea:HasAttributes(NAV_MESH_NO_JUMP) and not currentArea:HasAttributes(NAV_MESH_STAIRS)) then
		self:BotJump()
	end

	if currentArea:HasAttributes(NAV_MESH_CROUCH) or targetPosArea:HasAttributes(NAV_MESH_CROUCH) then
		cmd:AddButtons(IN_DUCK)
	end

	if currentArea:HasAttributes(NAV_MESH_RUN) then
		cmd:AddButtons(IN_RUN)
	end

	// We got the target to go to, aim there and MOVE
	local targetang = ( ply.targetArea - ply:GetPos() ):GetNormalized():Angle()
	cmd:SetViewAngles( targetang )
	cmd:SetForwardMove( 1000 )

	if GMBots:IsDebugMode() then debugoverlay.Line(self:EyePos(),self:EyePos() + cmd:GetViewAngles():Forward()*100,0.1,Color(255,255,0)) end
end