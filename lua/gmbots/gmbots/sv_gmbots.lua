hook.Add( "PhysgunPickup", "AllowPlayerPickup", function( ply, ent )
	if ( ply:IsSuperAdmin() and ent:IsPlayer() and ent.GMBot) then
		return true
	end
end )

local function isAllowedToRun(ply)
	if SERVER and not ply then
		return true
	end

	if SERVER and not IsValid(ply) then
		return true
	end

	if SERVER and ply and ply:IsValid() and ply:IsPlayer() and ply:IsSuperAdmin() then
		return true
	end

	return false
end

concommand.Add("gmbots_bot_add", function( ply, cmd, args )
	if isAllowedToRun(ply) then
		GMBots:AddBot()
	end
end,nil,"Spawns a bot.",FCVAR_LUA_SERVER)

concommand.Add("gmbots_kick_all", function( ply, cmd, args )
	if isAllowedToRun(ply) then
		for a,b in pairs(player.GetAll()) do
			if b and b:IsValid() and b:IsGMBot() and b:IsBot() then
				b:Kick("Kicking all bots...")
			end
		end
	end
end,nil,"Kick all bots.",FCVAR_LUA_SERVER)

// ULX fix for "unauthed player"
hook.Add("PlayerDisconnected", "ulxSlotsDisconnect", function(ply)
	--If player is bot.
	if ply:IsBot() or ply:SteamID() == "BOT" then
		--Do nothing.
		return
	end
end)