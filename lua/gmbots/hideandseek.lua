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

	if ply.Enemy and ply.Enemy:IsValid() and ply.Enemy:IsPlayer() and ply.Enemy:Alive() then -- Check if we have a enemy, and that the enemy is a player and is still alive..
		-- PLAYER:AttackPlayer(enemy, closest_distance, maximum_distance, hold_down_attack)
		ply:AttackPlayer(ply.Enemy,200,800,true) -- Attack the enemy, this will also pathfind for you if the enemy is out of sight.
	else
		ply.Enemy = ply:LookForPlayers() or nil -- Look for a new enemy.
		ply:Wander() -- Wander around while waiting for a new enemy.
	end
end)

hook.Add("GMBotsDeath","GMBots_BotDeath",function(ply,inflictor,attacker)
	ply.Enemy = nil
end)