--[[
	This file can act as a base for custom gamemode support.
	You can read the wiki at:
	https://github.com/Noobz4Life/GMBots/wiki

	Note that this wiki may not be up to date, as the code had been completely rewritten.
]]
GMBots:AddSpotType("Hide",true)
hook.Add("GMBotsConnected","GMBots_BotConnected",function(ply) -- Runs when a bot has been added.
	ply:SetGMBotVar("Enemy",nil)
	ply:SetGMBotVar("HidingSpot",nil)
end)

local function isThreat(ply,threat)
	return (threat and threat:IsValid() and threat:IsPlayer() and threat:Alive() and threat:Team() ~= ply:Team())
end

hook.Add("GMBotsStart","GMBots_RunStart",function(ply,cmd) -- Initialize the hook.
	if SeekerBlinded and ply:Team() == 2 then return end

	cmd:ClearButtons() -- Clear any buttons the bot is pressing, this is usually crouch.
	cmd:ClearMovement() -- Clear any movement the bot is doing, this usually doesn't do anything but it's here just in case.

	if ply:Team() == 1 then // Hiding
		local hideSpot = ply:GetGMBotVar("HidingSpot")
		if hideSpot then
			local distance = hideSpot:Distance(ply:GetPos())
			if distance > 2 then
				ply:Pathfind(hideSpot)
				if distance < 150 then
					cmd:AddKey(IN_DUCK)
				end
			else
				cmd:SetButtons(IN_DUCK)
			end
		else
			ply:SetGMBotVar("HidingSpot",GMBots:GetHideSpot())
			ply:BotWander()
		end
	elseif ply:Team() == 2 then // Seeking
		if isThreat(ply,ply:GetGMBotVar("Enemy")) then -- Check if we have a enemy, and that the enemy is a player and is still alive..
			-- PLAYER:AttackPlayer(enemy, closest_distance, maximum_distance, hold_down_attack)
			ply:SetGMBotVar("Enemy",ply:GetGMBotVar("Enemy") or ply:LookForPlayers(1) or nil)

			local isChasing = ply:BotChase(ply:GetGMBotVar("Enemy") )
			if isChasing == false then
				ply:BotDebug("I lost "..ply:GetGMBotVar("Enemy"):Nick())
				ply:SetGMBotVar("Enemy",nil) // we lost em
			end
			cmd:AddKey(IN_SPEED)
		else
			ply:SetGMBotVar("Enemy",ply:LookForPlayers(1) or nil) -- Look for a new enemy.
			ply:BotWander() -- Wander around while waiting for a new enemy.

			local newEnemy = ply:LookForPlayers(1)
			if isThreat(newEnemy) then
				cmd:AddKey(IN_RELOAD)
				ply:SetGMBotVar("Enemy",newEnemy)
			end
		end
	end
end)

hook.Add("GMBotsSpawn","GMBots_BotSpawn",function(ply)
	ply:SetGMBotVar("Enemy",nil)
	ply:SetGMBotVar("HidingSpot",nil)
end)

hook.Add("GMBotsDeath","GMBots_BotDeath",function(ply,inflictor,attacker)
	ply:SetGMBotVar("Enemy",nil)
	ply:SetGMBotVar("HidingSpot",nil)
end)