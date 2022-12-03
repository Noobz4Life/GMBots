--[[
	You can read the wiki at:
	https://github.com/Noobz4Life/GMBots/wiki

	Note that this wiki may not be up to date.
]]

hook.Add("GMBotsConnected","GMBots_BotConnected",function(ply) -- Runs when a bot has been added.
	ply.Enemy = nil
end)

hook.Add("GMBotsStart","GMBots_RunStart",function(ply,cmd) -- Initialize the hook.
	cmd:ClearButtons() -- Clear any buttons the bot is pressing (for nextbots, this is by default crouch for some reason)
	cmd:ClearMovement() -- Clear any movement the bot is doing, this usually doesn't do anything but it's here just in case.

	if ply.Enemy then
		ply:Pathfind(ply.Enemy:GetPos(),false)
		//ply:SelectBestWeapon()
	end
end)

hook.Add("GMBotsTakeDamage","GMBots_TakeDamage",function(ply,dmg)
	local attacker = dmg:GetAttacker()
	if(attacker and attacker:IsPlayer() and attacker ~= ply) then
		ply.Enemy = attacker
	end
end)

hook.Add("GMBotsDeath","GMBots_BotDeath",function(ply,inflictor,attacker)
	ply.Enemy = nil
end)

hook.Add("Think","GMBots_Sandbox_DeathThink",function()
	for a,ply in pairs(player.GetAll()) do
		if ply and ply:IsValid() and ply:IsPlayer() and !ply:Alive() and hook.Run("PlayerDeathThink",ply) then
			ply:Spawn()
		end
	end
end)