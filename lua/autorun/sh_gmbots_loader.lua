local PLAYER = FindMetaTable( "Player" )

PLAYER.RealIsTyping = PLAYER.RealIsTyping or PLAYER.IsTyping
function PLAYER:IsTyping()
	if self.GMBotIsTyping or self:GetNWBool("__GMBots__GMBotIsTyping") then
		return true
	end

	return self:RealIsTyping()
end

if CLIENT then
	CreateConVar( "gmbots_become_bot", 0, FCVAR_USERINFO, "Whether you should be a bot or not. Mostly used for debugging purposes", 0, 1)

	hook.Add("StartCommand","__GMBots_JumpLagFix",function(ply, cmd)
		if ply and ply:IsValid() and (ply:GetNWBool("IsGMBot") or GetConVar("gmbots_become_bot"):GetBool()) then
			cmd:ClearButtons()
			cmd:ClearMovement()
			cmd:SetImpulse(0)
			if not ply:OnGround() and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
				cmd:AddKey(IN_DUCK)
			end

			// silly flashlight thingy so the player can actually see what the bot is doing
			local lightColor = render.GetLightColor(ply:GetPos())
			if lightColor:IsZero() or lightColor:IsEqualTol( Vector(), 0.02 ) then
				if not ply:FlashlightIsOn() then
					cmd:SetImpulse(100)
				end
			elseif ply:FlashlightIsOn() then
				cmd:SetImpulse(100)
			end
		end
	end)
end