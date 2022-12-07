--[[
	This file can act as a base for custom gamemode support.
	You can read the wiki at:
	https://github.com/Noobz4Life/GMBots/wiki

	Note that this wiki may not be up to date, as the code had been completely rewritten.
]]

hook.Add("GMBotsConnected","GMBots_BotConnected",function(ply) -- Runs when a bot has been added.
	ply:SetGMBotVar("Murderer",nil)
	ply:SetGMBotVar("Target",nil)
	ply:SetGMBotVar("TargetSeenKnife",false)

	ply:SetGMBotVar("MurderCooldown",nil)
end)

local function isVisibleToOthers(ply)
	for _,b in pairs(player.GetAll()) do
		if b and b:IsValid() and b ~= ply and b:Alive() and not b.Murderer and ply:Visible(b) then
			return true
		end
	end
	return false
end

local function onlyBotsAlive()
	for _,b in pairs(player.GetAll()) do
		if b and b:IsValid() and b:Alive() and !b:IsGMBot() then
			return false
		end
	end
	return true
end

local function botAttack(bot)
	local attackCooldown = ply:GetGMBotVar("AttackCooldown")
end

hook.Add("GMBotsStart","GMBots_StartCommand",function(ply,cmd) -- Initialize the hook.
	cmd:ClearButtons() -- Clear any buttons the bot is pressing, this is usually crouch.
	cmd:ClearMovement() -- Clear any movement the bot is doing, this usually doesn't do anything but it's here just in case.

	local roundState = hook.Run( "GetRound" ) or 1
	if roundState ~= 1 then return end

	if ply.Murderer then -- Check if we have a enemy, and that the enemy is a player and is still alive..
		if GAMEMODE and GAMEMODE.RoundTime and GAMEMODE.RoundTime+1200 < CurTime() and onlyBotsAlive() then -- Stop round as it's taking too long, and actual players probably want to play too
			return ply:Kill()
		end
		local target = ply:GetGMBotVar("Target")
		local needToKill = (ply:GetGMBotVar("MurderCooldown") and ply:GetGMBotVar("MurderCooldown")+30 < CurTime()) or ply.MurdererRevealed or ply:GetGMBotVar("TargetSeenKnife")
		-- PLAYER:AttackPlayer(enemy, closest_distance, maximum_distance, hold_down_attack)
		if (ply:GetGMBotVar("MurderCooldown") and ply:GetGMBotVar("MurderCooldown") < CurTime()) or needToKill or (target and target:IsValid() and target:Alive()) then
			if target and target:IsValid() and (!target:Alive() or target == ply) then ply:BotWander(); return ply:SetGMBotVar("Target",nil) end
			if target and target:IsValid() and target:Alive() and (!isVisibleToOthers(target) or needToKill) then
				ply:Pathfind(target:GetPos())
				local distance = target:GetPos():Distance(ply:GetPos())

				if distance < 300 or !isVisibleToOthers(ply) then
					cmd:AddKey(IN_SPEED)
				end

				if distance < 100 and ply:Visible(target) then
					ply:SelectWeapon("weapon_mu_knife")
					ply:BotLookAt(target)

					ply:SetGMBotVar("TargetSeenKnife",true)
					ply:SetGMBotVar("MurderCooldown",nil)

					cmd:AddKey(IN_ATTACK)
				else
					ply:SelectWeapon("weapon_mu_hands")
				end
			else
				local targets = {}
				for _,possibleTarget in pairs(player.GetAll()) do
					if possibleTarget and possibleTarget:IsValid() and possibleTarget ~= ply and possibleTarget:Alive() and !possibleTarget.Murderer and (!isVisibleToOthers(possibleTarget) or needToKill) then
						targets[#targets + 1] = possibleTarget
					end
				end
				ply:SetGMBotVar("TargetSeenKnife",false)
				ply:SetGMBotVar("Target",targets[math.random(1,#targets)])
				ply:BotWander()
				ply:SelectWeapon("weapon_mu_hands")
			end
		else
			ply:SetGMBotVar("TargetSeenKnife",false)
			ply:SetGMBotVar("Target",nil)
			ply:SelectWeapon("weapon_mu_hands")
			ply:BotWander()
			if(ply:GetGMBotVar("MurderCooldown") == nil) then
				ply:SetGMBotVar("MurderCooldown",CurTime() + math.random(15,60))
				if(onlyBotsAlive()) then
					ply:BotDebug("Skipping murder cooldown because no real player is alive")
					ply:SetGMBotVar("MurderCooldown",0)
					ply:SetGMBotVar("Target",ply:LookForPlayers())
				end
			end
		end
	else
		ply:SetGMBotVar("Enemy",ply:LookForPlayers() or nil) -- Look for a new enemy.
		ply:BotWander() -- Wander around while waiting for a new enemy.
	end
end)

hook.Add("GMBotsTakeDamage","GMBots_TakeDamage",function(ply,dmg)
	local attacker = dmg:GetAttacker()
	if(attacker and attacker:IsPlayer() and attacker ~= ply) then
		ply:SetGMBotVar("Enemy",ply:LookForPlayers() or nil)
	end
end)

hook.Add("GMBotsSpawn","GMBots_BotDeath",function(ply,inflictor,attacker)
	ply:SetGMBotVar("Target",nil)
	ply:SetGMBotVar("TargetSeenKnife",false)

	ply:SetGMBotVar("Murderer",nil)

	ply:SetGMBotVar("MurderCooldown",nil)
end)