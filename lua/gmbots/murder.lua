--[[
	This file can act as a base for custom gamemode support.
	You can read the wiki at:
	https://github.com/Noobz4Life/GMBots/wiki

	Note that this wiki may not be up to date, as the code had been completely rewritten.
]]

hook.Add("GMBotsConnected","GMBots_BotConnected",function(ply) -- Runs when a bot has been added.
	ply:SetGMBotVar("Target",nil)
	ply:SetGMBotVar("TargetSeenKnife",false)

	ply:SetGMBotVar("Murderer",nil)

	ply:SetGMBotVar("MurderCooldown",nil)

	ply:SetGMBotVar("LootTarget",foundLoot)
	ply:SetGMBotVar("DroppedMagnum",nil)
	ply:SetGMBotVar("LootTarget",nil)
end)

local function isVisibleToOthers(ply)
	for _,b in pairs(player.GetAll()) do
		if b and b:IsValid() and b ~= ply and b:Alive() and not b.Murderer and ply:Visible(b) then
			return true
		end
	end
	return false
end

local function onlyBotsAliveCheck()
	for _,b in pairs(player.GetAll()) do
		if b and b:IsValid() and b:Alive() and !b:IsGMBot() then
			return false
		end
	end
	return true
end

local function lookForLoot(ply,cmd)
	local foundLoot = ply:GetGMBotVar("LootTarget") or ply:LookForEntities("mu_loot")
	if foundLoot and foundLoot:IsValid() then
		ply:SetGMBotVar("LootTarget",foundLoot)
		ply:BotLookAt(foundLoot)
		ply:Pathfind(foundLoot:GetPos())
		cmd:AddKey(IN_USE)
		if foundLoot:GetPos():Distance(ply:GetPos()) < 90 then
			foundLoot:Use(ply)
			ply:ConCommand("mu_taunt morose")
			ply:SetGMBotVar("LootTarget",nil)
		end
		return true
	else
		ply:SetGMBotVar("LootTarget",nil)
	end
	return false
end

local onlyBotsAlive = false

local function bystanderWander(ply,cmd)
	local foundMurderer = ply:LookForPlayers(nil,function(otherPly)
		local weapon = otherPly:GetActiveWeapon()
		return otherPly.Murderer and ((weapon and weapon:IsValid() and weapon:GetClass() == "weapon_mu_knife") or otherPly:IsSprinting() or otherPly.MurdererRevealed)
	end)

	if foundMurderer and foundMurderer:IsValid() then
		ply:SetReaction("Murderer",foundMurderer)
		if ply:HasReacted("Murderer") or onlyBotsAlive then
			ply:SetGMBotVar("Murderer",foundMurderer)
			ply:ConCommand("mu_taunt scream")
		else
			onlyBotsAlive = onlyBotsAliveCheck()
		end
	else
		ply:ResetReaction("Murderer")
	end

	if not ply:HasWeapon("weapon_mu_magnum") then
		local foundMagnum = ply:GetGMBotVar("DroppedMagnum") or ply:LookForEntities("weapon_mu_magnum",function(ent)
			return IsValid(ent:GetOwner())
		end)

		if foundMagnum and foundMagnum:IsValid() and !IsValid(foundMagnum:GetOwner()) then
			ply:SetGMBotVar("DroppedMagnum",foundMagnum)
			ply:Pathfind(foundMagnum:GetPos())
		else
			ply:SetGMBotVar("DroppedMagnum",nil)
			if not lookForLoot(ply,cmd) then ply:BotWander() end
		end
	else
		ply:BotWander()
	end
end

hook.Add("GMBotsStart","GMBots_StartCommand",function(ply,cmd) -- Initialize the hook.
	if not ply:Alive() then return end -- No need to hog resources on players that aren't alive

	cmd:ClearButtons() -- Clear any buttons the bot is pressing, this is usually crouch.
	cmd:ClearMovement() -- Clear any movement the bot is doing, this usually doesn't do anything but it's here just in case.
	local roundState = hook.Run( "GetRound" ) or 1
	if roundState ~= 1 then return ply:BotWander() end

	if ply.Murderer then -- Check if we have a enemy, and that the enemy is a player and is still alive..
		if GAMEMODE and GAMEMODE.RoundTime and GAMEMODE.RoundTime+1200 < CurTime() then -- Stop round as it's taking too long, and actual players probably want to play too
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

				if !isVisibleToOthers(ply) then
					cmd:AddKey(IN_SPEED)
				end

				if distance < 100 and ply:Visible(target) then
					ply:SelectWeapon("weapon_mu_knife")
					ply:BotLookAt(target)

					ply:SetGMBotVar("TargetSeenKnife",true)
					ply:SetGMBotVar("MurderCooldown",nil)

					cmd:AddKey(IN_ATTACK)

					if target:GetPos().Z < ply:GetPos().Z then
						cmd:AddKey(IN_DUCK)
					end
				else
					ply:SelectWeapon("weapon_mu_hands")
				end
			else
				local targets = {}
				for _,possibleTarget in pairs(player.GetAll()) do
					if possibleTarget and possibleTarget:IsValid() and possibleTarget ~= ply and possibleTarget:Alive() and !possibleTarget.Murderer and (possibleTarget:GetGMBotVar("Murderer") == ply or !isVisibleToOthers(possibleTarget) or needToKill) then
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
			lookForLoot(ply,cmd)
			ply:BotWander()
			onlyBotsAlive = onlyBotsAliveCheck()
			if(ply:GetGMBotVar("MurderCooldown") == nil) then
				ply:SetGMBotVar("MurderCooldown",CurTime() + math.random(15,60))
				if(onlyBotsAlive) then
					ply:BotDebug("Skipping murder cooldown because no real player is alive")
					ply:SetGMBotVar("MurderCooldown",0)
					ply:SetGMBotVar("Target",ply:LookForPlayers())
				end
			end
		end
	else
		local murderer = ply:GetGMBotVar("Murderer")
		if murderer and murderer:IsValid() and murderer:IsPlayer() and murderer:Alive() then
			local magnum = ply:GetWeapon("weapon_mu_magnum")
			local reacted = ply:HasReacted("Murderer") or onlyBotsAlive
			ply:SetReaction("Murderer",ply:Visible(murderer))
			if magnum and magnum:IsValid() then
				if (ply:BotVisible(murderer) and reacted) then
					cmd:SelectWeapon(magnum)
					ply:BotLookAt(murderer)
					cmd:SetForwardMove( -1000 )
					//if magnum:CanPrimaryAttack() then
						//magnum:PrimaryAttack()
					//end

					if magnum:CanPrimaryAttack() and not (ply:GetGMBotVar("AttackCooldown") and ply:GetGMBotVar("AttackCooldown") > CurTime()) then
						ply:SetGMBotVar("AttackCooldown",CurTime() + 0.5)
						cmd:AddKey(IN_ATTACK)
						if magnum:CanPrimaryAttack() then
							magnum:PrimaryAttack()
						end
					end
				else
					ply:Pathfind(murderer:GetPos())
				end
			else
				bystanderWander(ply,cmd)
			end
		else
			bystanderWander(ply,cmd)
		end
	end
end)

hook.Add("GMBotsSpawn","GMBots_BotDeath",function(ply,inflictor,attacker)
	ply:SetGMBotVar("Target",nil)
	ply:SetGMBotVar("TargetSeenKnife",false)

	ply:SetGMBotVar("Murderer",nil)

	ply:SetGMBotVar("MurderCooldown",nil)

	ply:SetGMBotVar("LootTarget",foundLoot)
	ply:SetGMBotVar("DroppedMagnum",nil)
	ply:SetGMBotVar("LootTarget",nil)

	ply:SetGMBotVar("AttackCooldown",nil)

	ply:ResetReactions()

	onlyBotsAlive = false
end)