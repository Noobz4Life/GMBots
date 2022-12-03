local PLAYER = FindMetaTable( "Player" )

PLAYER.RealIsTyping = PLAYER.RealIsTyping or PLAYER.IsTyping
function PLAYER:IsTyping()
	if self.GMBotIsTyping or self:GetNWBool("__GMBots__GMBotIsTyping") then
		return true
	end

	return self:RealIsTyping()
end