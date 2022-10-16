--[[
--print("This is a default module.")

local PLAYER = FindMetaTable( "Player" )

local defaultrePathDelay = 1

CreateConVar("gmbots_pf_avoid_props",0,bit.bor(FCVAR_ARCHIVE,FCVAR_NEVER_AS_STRING),"Should GMBots pathfinding try to go around props? This may be inaccurate.",0,1)
CreateConVar("gmbots_pf_to_closest_area",1,bit.bor(FCVAR_ARCHIVE,FCVAR_NEVER_AS_STRING),"Should GMBots pathfinding try to pathfind to the closest NavArea if it fails to find a path?",0,1)

local function heuristic_cost_estimate( start, goal )
	// Perhaps play with some calculations on which corner is closest/farthest or whatever
	local dist = start:GetCenter():Distance( goal:GetCenter() )
	return dist
end

// using CNavAreas as table keys doesn't work, we use IDs
local function reconstruct_path( cameFrom, current )
	local total_path = { current }

	current = current:GetID()
	while ( cameFrom[ current ] ) do
		current = cameFrom[ current ]
		table.insert( total_path, navmesh.GetNavAreaByID( current ) )
	end
	return total_path
end

local function Astar( start, goal, ply, dontretryagain )
	if ( !IsValid( start ) || !IsValid( goal ) ) then return false end
	if ( start == goal ) then return true end

	start:ClearSearchLists()

	start:AddToOpenList()

	local cameFrom = {}

	start:SetCostSoFar( 0 )

	start:SetTotalCost( heuristic_cost_estimate( start, goal ) )
	start:UpdateOnOpenList()
	
	local waterisok = false

	if goal:IsUnderwater() then
		waterisok = true
	end
	
	if IsValid(ply) and ply:WaterLevel() > 0 then
		waterisok = true
	end

	local closestarea = goal
	local closestdist = 999999999
	
	local should_retry = (GetConVar("gmbots_pf_to_closest_area"):GetInt() > 0)
	
	if dontretryagain then
		should_retry = false
	end

	while ( !start:IsOpenListEmpty() ) do
		local current = start:PopOpenList() // Remove the area with lowest cost in the open list and return it
		if ( current == goal ) then
			return reconstruct_path( cameFrom, current )
		end

		current:AddToClosedList()

		for k, neighbor in pairs( current:GetAdjacentAreas() ) do
			local newCostSoFar = current:GetCostSoFar() + heuristic_cost_estimate( current, neighbor )

			if ( neighbor:IsUnderwater() ) then // Add your own area filters or whatever here
				if not PLAYER.BotLikesWater and not waterisok then
					continue
				end
			end
			
			if neighbor:HasAttributes(NAV_MESH_AVOID) and neighbor ~= start then
				continue
			end
			
			if should_retry then
				local currentdist = current:GetCenter():Distance(goal:GetCenter())
				if currentdist < closestdist then
					closestarea = current
					closestdist = currentdist
				end
			end
			
			if ( ( neighbor:IsOpen() || neighbor:IsClosed() ) && neighbor:GetCostSoFar() <= newCostSoFar ) then
				continue
			else
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
	end

	if should_retry then
		if ply and ply:IsValid() then
			ply:BotDebug("Can't reach goal! Trying to reach closest accessible area...")
		else
			GMBots:Msg("Can't reach goal! Trying to reach closest accessible area...")
		end
		return Astar(start,closestarea or goal,ply,true),true
	end
	
	if dontretryagain then
		GMBots:Msg("Can't reach closest area!")
	end
	
	return false
end
  
local function AstarVector( start, goal, ply )
	local startArea = navmesh.GetNearestNavArea( start )
	local goalArea = navmesh.GetNearestNavArea( goal )
	return Astar( startArea, goalArea, ply )
end

local function drawThePath( path, time )
	if (GetConVar("gmbots_debug_mode"):GetInt() <= 0) then return end
	
	time = time or (1 / 33)
	
	local prevArea
	for _, area in pairs( path ) do
		debugoverlay.Sphere( area:GetCenter(), 8, time or 9, color_white, true  )
		if ( prevArea ) then
			debugoverlay.Line( area:GetCenter(), prevArea:GetCenter(), time or 9, color_white, true )
		end

		area:Draw()
		prevArea = area
	end
end

function PLAYER:HandleNavAttributes(area)
	if not ( SERVER and ply and ply:IsValid() and ply:IsBot() and ply:Alive() and ply.GMBotsCMD ) then return end
	
	area = area or navmesh.GetNearestNavArea( self:GetPos() )
	if area then
		local cmd = ply.GMBotsCMD
		attributes = area:GetAttributes()
		
		if area:HasAttributes(NAV_MESH_STAIRS) or area:HasAttributes(NAV_MESH_NO_JUMP) or area:HasAttributes(NAV_MESH_CROUCH) then
			self.BotDontJump = true
			self.GMBot_JumpTimer = CurTime() + 0.5
		end
		
		if area:HasAttributes(NAV_MESH_JUMP) then
			self:BotJump()
		end
		
		if area:HasAttributes(NAV_MESH_CROUCH) then
			cmd:SetButtons(bit.bor(cmd:GetButtons(),IN_DUCK))
		end
	end
end

local function pfSetViewAngles( ply, angle )
	if ply and ply:IsValid() then
		ply:SetEyeAngles(angle)
		if ply.GMBotsCMD then
			ply.GMBotsCMD:SetViewAngles( angle )
		end
	end
end

local function calculateRealPath(path,corners)
	if path then
		local newpath = {}
		for i = 1,#path do
			if path[i] then
				newpath[i] = path[i]:GetCenter()
			end
		end
		return newpath
	else
		GMBots:Err("calculateRealPath missing argument 1, path. This shouldn't ever happen, if it does, contact me!")
	end
	return false
end

local function traceCheck(start,stop,ply)
	local trace_table = {
		start = start,
		endpos = stop,
		filter = ply,
		mins = Vector( -8, -8, 0 ),
		maxs = Vector( 8, 8, 72 ),
		mask = MASK_SHOT_HULL
	}
	local tr = util.TraceHull( trace_table )
	
	debugoverlay.Box( tr.HitPos, trace_table.mins, trace_table.maxs, 0.01, Color( 0, 255, 0 ) )
	
	return tr.Hit,tr.Entity
end

local function calculateRealPath(path,corners)
	if path then
		local new_path = {}
		for i = 1,#path do
			new_path[#new_path + 1] = path[i]:GetCenter()
		end
		return table.Reverse( new_path )
	else
		return GMBots:Err("calculateRealPath missing argument 1, path")
	end
end

local function botResetPath(ply)
	ply.path = nil
	ply.lastRePath = CurTime()
end

local function tableEqualValues(t1,t2,ignore_mt) // Blue Mustache is credit 2 team
	ignore_mt = ignore_mt or true
	local ty1 = type(t1)
	local ty2 = type(t2)
	if ty1 ~= ty2 then return false end
	-- non-table types can be directly compared
	if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
	-- as well as tables which have the metamethod __eq
	local mt = getmetatable(t1)
	if not ignore_mt and mt and mt.__eq then return t1 == t2 end
	for k1,v1 in pairs(t1) do
		local v2 = t2[k1]
		if v2 == nil or not tableEqualValues(v1,v2) then return false end
	end
	for k2,v2 in pairs(t2) do
		local v1 = t1[k2]
		if v1 == nil or not tableEqualValues(v1,v2) then return false end
	end
	return true
end

function PLAYER:Pathfind(pos,efficient,rePathDelay)
	local ply = self
	if not ( SERVER and ply and ply:IsValid() and ply.GMBot and ply:Alive() and ply.GMBotsCMD ) then return end
	
	local cmd = ply.GMBotsCMD
	
	if not pos then
		ErrorNoHalt("Pathfind missing argument 1 for position.")
		return
	end
	
	local theTargetArea = navmesh.GetNearestNavArea( pos, nil, 30000, false, true )
	local ourCurrentArea = navmesh.GetNearestNavArea( self:GetPos() )
	if ( theTargetArea == ourCurrentArea ) or (pos:Distance(self:GetPos()) < 200 and self:VisibleVec(pos)) then
		local targetang = ( pos - ply:GetPos() ):GetNormalized():Angle()
		pfSetViewAngles( ply, targetang )
		cmd:SetForwardMove( 1000 )
		
		return
	end
	
	pos = pos or Vector(0,0,0)
	corners = corners or false
	rePathDelay = rePathDelay or defaultrePathDelay
	
	local currentArea = navmesh.GetNearestNavArea( ply:GetPos() )

	ply.lastRePath = ply.lastRePath or 0

	ply.lastRePath2 = ply.lastRePath2 or 0 

	if ( ply.path && ply.lastRePath + rePathDelay < CurTime() ) then
		ply.path = nil
		ply.lastRePath = CurTime()
	end
	
	if ( !ply.path && ply.lastRePath2 + rePathDelay < CurTime() ) then
		local targetPos = pos // target position to go to, the first player on the server
		local targetArea = navmesh.GetNearestNavArea( targetPos )

		ply.targetArea = nil
		local newpath,hadtoretry = Astar( currentArea, targetArea, ply )
		ply.path = newpath
		
		if ( !istable( ply.path ) ) then // We are in the same area as the target, or we can't navigate to the target
			ply.path = nil // Clear the path, bail and try again next time
			ply.lastRePath2 = CurTime()
			
			if hadtoretry then
				ply.lastRePath2 = ply.lastRePath2 + rePathDelay
			end
			
			return
		end
		//PrintTable( ply.path )

		// TODO: Add inbetween points on area intersections
		// TODO: On last area, move towards the target position, not center of the last area
		self.GMBot_JumpTimer = CurTime() + math.Clamp(rePathDelay/4, 0.1, 0.8)
		table.remove( ply.path ) // Just for this example, remove the starting area, we are already in it!
		ply.botLastPath = ply.botRealPath
		ply.botRealPath = calculateRealPath(ply.path,corners)
	end

	// We have no path, or its empty (we arrived at the goal), try to get a new path.
	if ( !ply.path || #ply.path < 1 ) then
		ply.path = nil
		ply.targetArea = nil
		
		local targetang = ( pos - ply:GetPos() ):GetNormalized():Angle()
		pfSetViewAngles( ply, targetang )
		cmd:SetForwardMove( 1000 )
		
		return
	end
	if efficient then
		// We got a path to follow to our target!
		drawThePath( ply.path, 1/33 ) // Draw the path for debugging

		// Select the next area we want to go into
		if ( !IsValid( ply.targetArea ) ) then
			ply.targetArea = ply.path[ #ply.path ]
		end
		
		if ply.targetArea == ourCurrentArea then
			local nextpath = ply.path[ #ply.path - 1 ]
			if ply.path[ #ply.path - 1 ] then
				if nextpath ~= ply.targetArea and self:VisibleVec(nextpath:GetCenter()) and traceCheck(ply:GetPos(),nextpath:GetCenter()) then
					--ply.targetArea = nextpath
				end
			end
		end
		
		--print((ply.targetArea:GetCenter().Z-ply:GetPos().Z))
		if (ply.targetArea:GetCenter().Z-ply:GetPos().Z) > 40 then
			self:BotJump()
		end

		// The area we selected is invalid or we are already there, remove it, bail and wait for next cycle
		if ( !IsValid( ply.targetArea ) || ( ply.targetArea == currentArea && ply.targetArea:GetCenter():Distance( ply:GetPos() ) < 64 ) ) then
			table.remove( ply.path ) // Removes last element
			ply.targetArea = nil
			return
		end

		// We got the target to go to, aim there and MOVE
		
		self:HandleNavAttributes(ourCurrentArea)
		self:HandleNavAttributes(ply.targetArea)
		
		local targetang = ( ply.targetArea:GetCenter() - ply:GetPos() ):GetNormalized():Angle()
		pfSetViewAngles( ply, targetang )
		cmd:SetForwardMove( 1000 )
	else
		if ply.botRealPath and #ply.botRealPath <= 1 then
			local targetang = ( pos - ply:GetPos() ):GetNormalized():Angle()
			pfSetViewAngles( ply, targetang )
			cmd:SetForwardMove( 1000 )
		end
	
		ply.botCurSegment = ply.botCurSegment or 2
		
		ply.botRealPath = ply.botRealPath or calculateRealPath(ply.path,corners)
		ply.botLastPath = ply.botLastPath or ply.botRealPath
		
		if ply.botCurSegment ~= 1 and not tableEqualValues( ply.botLastPath, ply.botRealPath ) then
			ply.botCurSegment = 1
			ply.botLastPath = ply.botRealPath
		end
		
		if !ply.botRealPath then return botResetPath(ply) end
		
		local curgoal = ply.botRealPath[ply.botCurSegment]
		local nextgoal = ply.botRealPath[ply.botCurSegment + 1]
		if !curgoal then return botResetPath(ply) end
		
		if ply:GetPos():Distance(curgoal) < 20 then
			ply.botCurSegment = ply.botCurSegment+1
		end
		
		if (curgoal.Z-ply:GetPos().Z) > 40 then
			self:BotJump()
		end
		
		debugoverlay.Sphere( curgoal, 16, 1 / 33, Color(255,0,0), true  )
		
		local targetang = ( curgoal - ply:GetPos() ):GetNormalized():Angle()
		pfSetViewAngles( ply, targetang )
		cmd:SetForwardMove( 1000 )
	end
end
PLAYER.BotLikesWater = PLAYER.BotLikesWater or false
]]