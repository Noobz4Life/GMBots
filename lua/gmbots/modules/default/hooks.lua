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
		elseif target.GMBot then
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

hook.Add("StartCommand","GMBots_SCDefault_DoNotOverwrite", function(ply,cmd)
	if !ply.GMBot then return end
	
	if not (player.GetCount() > 1) then
		return
	end
	
	if not ply:Alive() then
		cmd:SetButtons(IN_ATTACK)
	end
	
	if !ply:Alive() then return end
	
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