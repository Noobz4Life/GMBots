local lastpfDebugTarget = 0
local lastpfDebugValue = 0

GMBots.AutoCrouchJump = true

function GMBots:AddInternalHook(eventName,func)
	return hook.Add(eventName,"GMBots_"..eventName.."Default_DoNotOverwritePleaseTY",func)
end

local function pathfindDebug(ply,cmd)
	local newvalue = GetConVar("gmbots_debug_pathfind"):GetInt()
	local userid = math.ceil( newvalue )
	local target = Player(userid)

	cmd:ClearButtons()
	cmd:ClearMovement()

	if newvalue ~= lastpfDebugValue then
		if not IsValid( target ) then
			GMBots:Msg("gmbots_debug_pathfind target is invalid!")
			RunConsoleCommand("gmbots_debug_pathfind", "0")
			lastpfDebugValue = newvalue
			return
		elseif target:IsGMBot() then
			GMBots:Msg("gmbots_debug_pathfind target cannot be a bot!")
			RunConsoleCommand("gmbots_debug_pathfind", "0")
			lastpfDebugValue = newvalue
			return
		elseif lastpfDebugTarget ~= userid and target.Nick then
			GMBots:Msg("Valid gmbots_debug_pathfind target: "..target:Nick())
			lastpfDebugTarget = userid
		end
		lastpfDebugValue = newvalue
	end

	if target and target:IsValid() then
		ply:Pathfind(target:GetPos(),nil,1)
	end

	if GMBots.AutoCrouchJump and not ply:OnGround() then
		cmd:SetButtons(bit.bor(cmd:GetButtons(),IN_DUCK))
	end
end

GMBots:AddInternalHook("EntityTakeDamage", function(target, dmg)
	if(target and target:IsValid() and target:IsPlayer() and target:IsGMBot() ) then
		hook.Run("GMBotsTakeDamage",target,dmg)
	end
end)

GMBots:AddInternalHook("PlayerDeath", function(victim,inflictor,attacker)
	if(victim and victim:IsValid() and victim:IsPlayer() and victim:IsGMBot()) then
		hook.Run("GMBotsDeath",victim,inflictor,attacker)
	end

	if(attacker and attacker:IsValid() and attacker:IsPlayer() and attacker:IsGMBot()) then
		hook.Run("GMBotsKill",attacker,inflictor,victim)
	end
end)

GMBots:AddInternalHook("PlayerSpawn",function(ply,transition)
	if(ply and ply:IsValid() and ply:IsPlayer() and ply:IsGMBot()) then
		hook.Run("GMBotsSpawn",ply,transition)
		if GMBots.UseCollisionRules then
			ply:SetCustomCollisionCheck( true )
		end
	end
end)

GMBots:AddInternalHook("StartCommand", function(ply,cmd)
	if not (ply and ply:IsValid() and ply:IsGMBot()) then return end

	if (player.GetCount() < 1) then
		return
	end

	if not ply:Alive() then
		cmd:SetButtons(IN_ATTACK)
	end

	if not ply:Alive() then return end

	ply.GMBotsCMD = cmd
	ply.BotDontJump = false

	if ( GetConVar("gmbots_debug_pathfind"):GetInt() > 0 ) then return pathfindDebug(ply,cmd) end
	lastpfDebugTarget = 0

	local success,err = pcall(function()
		hook.Run("GMBotsStart",ply,cmd)
	end)

	if GMBots.AutoCrouchJump and not ply:OnGround() then
		cmd:SetButtons(bit.bor(cmd:GetButtons(),IN_DUCK))
	end

	if not success then
		ply:BotError(err or success or "Couldn't determine error...")
	end
end)