-- This is a user-made module! This will run after any default modules. This file will not be ran as this is file is for example purposes.

local PLAYER = FindMetaTable( "Player" ) -- Get the player meta table.

function PLAYER:PathfindToEntity(ent) -- Make a new function in the player meta table named PathfindToEntity, and take a entity as a parameter
	if ent and ent:IsValid() then -- Check if the ent parameter is valid.
		self:Pathfind(ent:GetPos(),false) -- Make the player(self) pathfind to the entity(ent).
	end
end

print("My own module!")