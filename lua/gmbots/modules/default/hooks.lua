local PLAYER = FindMetaTable( "Player" )

local lastpfDebugTarget = 0
local lastpfDebugValue = 0

GMBots.AutoCrouchJump = true

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
		cmd:AddKey(IN_DUCK)
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
	if(ply and ply:IsValid() and ply:IsPlayer()) then
		if ply.GMBot == nil then ply.GMBot = false end

		if ply:IsGMBot() then
			ply.WanderSpot = nil
			if GMBots.UseCollisionRules then
				ply:SetCustomCollisionCheck( true )
			end

			hook.Run("GMBotsSpawn",ply,transition)
		else
			ply.__GMBots = nil // clear this so it doesn't take up memory
		end
	end
end)

CreateConVar("gmbots_pause_while_typing",1,FCVAR_NEVER_AS_STRING,"Should bots disable their while typing?",0,1)

GMBots:AddInternalHook("StartCommand", function(ply,cmd)
	--[[if ply and ply:IsValid() then
		ply:SetNWBool("IsGMBot",ply:IsGMBot())
	end]]
	if not (ply and ply:IsValid() and ply:IsGMBot()) then return end

	if ply:IsGMBot() and !ply:IsBot() then
		ply:PrintMessage(4,"You are currently a bot. You can type 'gmbots_become_bot 0' in console to disable being a bot!")
		ply:SetNWBool("GMBot",true)
	end

	ply.__GMBots = ply.__GMBots or {}

	if (player.GetCount() < 1) then
		return
	end

	if not ply:Alive() then
		cmd:SetButtons(IN_ATTACK)
		return
	end

	cmd:ClearButtons()
	cmd:ClearMovement()

	if cmd:GetImpulse() ~= 100 then cmd:SetImpulse(0) end

	cmd:SetMouseX(0)
	cmd:SetMouseY(0)

	if ply:IsTyping() and GetConVar("gmbots_pause_while_typing"):GetInt() > 0 then return end

	ply.GMBotsCMD = cmd
	ply.GMBotDontJump = false

	if ( GetConVar("gmbots_debug_pathfind"):GetInt() > 0 ) then return pathfindDebug(ply,cmd) end
	lastpfDebugTarget = 0

	local success,err = pcall(function()
		hook.Run("GMBotsStart",ply,cmd)
	end)

	if GMBots.AutoCrouchJump and not ply:OnGround() and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
		cmd:AddKey(IN_DUCK)
	end

	if not success then
		ply:BotError(err or success or "Couldn't determine error...")
	end
end)