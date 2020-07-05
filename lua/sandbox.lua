--[[
	This file can act as a base for custom gamemode support.
	You can read the wiki at:
	https://github.com/Noobz4Life/GMBots/wiki
	
	Note that this wiki may not be up to date, as the code had been completely rewritten.
]]

hook.Add("GMBotsConnected","GMBots_BotConnected",function(ply) -- Runs when a bot has been added.
	ply.Enemy = nil
end)

hook.Add("GMBotsStart","GMBots_RunStart",function(ply,cmd) -- Initialize the hook.
	cmd:ClearButtons() -- Clear any buttons the bot is pressing, this is usually crouch.
	cmd:ClearMovement() -- Clear any movement the bot is doing, this usually doesn't do anything but it's here just in case.
end)

hook.Add("Think","GMBots_Sandbox_DeathThink",function()
	for a,ply in pairs(player.GetAll()) do
		if ply and ply:IsValid() and ply:IsPlayer() and !ply:Alive() then
			local should_respawn = hook.Run("PlayerDeathThink",ply)
			if should_respawn then
				ply:Spawn()
			end
		end
	end
end)