local PLAYER = FindMetaTable( "Player" )

CreateConVar("gmbots_pf_avoid_props",0,bit.bor(FCVAR_ARCHIVE,FCVAR_NEVER_AS_STRING),"Should GMBots pathfinding try to go around props? This may be inaccurate.",0,1)
CreateConVar("gmbots_pf_to_closest_area",1,bit.bor(FCVAR_ARCHIVE,FCVAR_NEVER_AS_STRING),"Should GMBots pathfinding try to pathfind to the closest node if it fails to find a path?",0,1)

local navMeshLocation = "gmbots/nav/"

local pfNodes = pfNodes or {}
local nodeMeta = {}

local function getNodeDivideAmount()
	return 64
end

function GMBots:SaveNavMesh()
	
end

function GMBots:LoadNavMesh()

end

function GMBots:GenerateNavMesh()
	local allNavAreas = navmesh.GetAllNavAreas()
	if #allNavAreas <= 0 then
		return GMBots:Msg("No navmesh has been generated! Please type nav_generate into console!")
	end
	
	pfNodes = {}
	for i = 1,#allNavAreas do
		local navArea = allNavAreas[i]
		if navArea then
			local navAreaWidth = navArea:GetSizeX()
			local navAreaHeight = navArea:GetSizeY()
			local navAreaCenter = navArea:GetCenter()
			local navAreaCorner = navArea:GetCenter() - Vector(navAreaWidth/2,navAreaHeight/2,0)
			
			local divideAmount = getNodeDivideAmount()
			
			for ix = 1,(navAreaWidth/divideAmount) do
				for iy = 1,(navAreaHeight/divideAmount) do
					local node = nodeMeta.new(navAreaCorner + Vector((ix*divideAmount),(iy*divideAmount),0))
					table.insert(pfNodes,node)
				end
			end
		end
	end
	GMBots:Msg("Generated "..#pfNodes.." nodes!")
end

concommand.Add("gmbots_nav_draw", function( ply, cmd, args )
	if SERVER and (ply and ply:IsSuperAdmin()) then
		for a,b in pairs(pfNodes) do
			if(a < 500) then
				ply:SetPos(b:GetPos())
				debugoverlay.Sphere( b:GetPos(), 8, 10, color_white, true  )
			end
		end
	end
end)

concommand.Add("gmbots_nav_generate", function( ply, cmd, args )
    if SERVER and (not ply or (ply and ply:IsSuperAdmin())) then
		return GMBots:GenerateNavMesh()
	end
end)

function nodeMeta.new( position )
	local node = {}
	node.Position = position or Vector(0,0,0)
	
	setmetatable(node,nodeMeta)
	return node
end

function nodeMeta:GetPos()
	return self.Position
end

function nodeMeta:AddNeighbor(neighbor)
	self.nodeNeighbors = self.nodeNeighbors or {}
	return table.insert(self.nodeNeighbors,1,neighbor)
end

function nodeMeta:GetNeighbors()
	return self.nodeNeighbors or {}
end

function nodeMeta:IsClear()
	return true
end

setmetatable(nodeMeta, { __call = nodeMeta.new })
nodeMeta.__index = nodeMeta