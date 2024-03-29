--- [[ WELCOME TO GMBOTS REWRITTEN ]] ---

GMBots.UseCollisionRules = true

CreateConVar("gmbots_collision", 1, bit.bor(FCVAR_ARCHIVE,FCVAR_NEVER_AS_STRING),"Enables custom collisions compared to normal players (This may be disabled by the current gamemode script)")
CreateConVar("gmbots_collision_doors",0,bit.bor(FCVAR_ARCHIVE,FCVAR_NEVER_AS_STRING),"Should bots collide with doors? (This may be disabled by the current gamemode script)")
//CreateConVar("gmbots_collision_bots",0,bit.bor(FCVAR_ARCHIVE,FCVAR_NEVER_AS_STRING),"Should bots collide with other bots? (This may be disabled by the current gamemode script)")
CreateConVar("gmbots_collision_ignore","",FCVAR_ARCHIVE,"What entities should bots not collide with? (This may be disabled by the current gamemode script)\nSeperated by a comma")

hook.Add( "ShouldCollide", "GMBots_SCDefault_CustomCollisions", function( ent1, ent2 )
	if GMBots.GamemodeSupported and GetConVar("gmbots_collision"):GetBool() and (ent1 and  ent2 and ent1:IsValid() and ent2:IsValid() ) then
		local ply = nil
		local ent = nil
		if ent1:IsPlayer() and ent1:IsGMBot() then ply = ent1; ent = ent2
		elseif ent2:IsPlayer() and ent2:IsGMBot() then ply = ent2; ent = ent1 end
		if ply and ply:IsValid() and ply:IsPlayer() and ply:IsGMBot() and ent and ent:IsValid() then
			local colRules = hook.Run("GMBotsCollide",ply,ent)
			if colRules ~= nil then return colRules end
			if not GetConVar("gmbots_collision_doors"):GetBool() and GMBots:IsDoorOpen(ent) then
				return false
			end

			--[[
			local botConvar = GetConVar("gmbots_collision_bots")
			if (botConvar and botConvar:GetBool()) and (ent:IsPlayer() and ent:IsGMBot()) then
				return false
			end
			]]

			local ignoreEntitiesStr = string.Trim(GetConVar("gmbots_collision_ignore"):GetString())
			if string.len( ignoreEntitiesStr ) > 0 then
				local ignoreEntities = string.Split( ignoreEntitiesStr, ",")
				for i = 1, #ignoreEntities do
					if ent:GetClass() == ignoreEntities[i] then
						return false
					end
				end
			end
		end
	end
end )