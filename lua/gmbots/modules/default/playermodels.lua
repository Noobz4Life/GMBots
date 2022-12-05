// I made it use this really hacky way so that it works across gamemodes properly
// It also makes it as accurate to real players as you can get
// If this affects anything unintended, it's most likely the gamemodes/addons fault for trusting the client

local PLAYER = FindMetaTable( "Player" )

PLAYER.RealGetInfo = PLAYER.RealGetInfo or PLAYER.GetInfo
PLAYER.RealGetInfoNum = PLAYER.RealGetInfoNum or PLAYER.GetInfoNum

function PLAYER:GetInfo(cvarName)
    if (self and self:IsValid() and self:IsBot()) and #self:RealGetInfo(cvarName) <= 0 then
        if (string.Trim(string.lower(cvarName)) == "cl_playermodel") then
            if self.GMBotsPlayerModel == nil then
                local playermodels = table.GetKeys( player_manager.AllValidModels() ) or {""}

                local nameMatchingPlayermodels = {}
                for i = 1,#playermodels do
                    local playermodel = playermodels[i]
                    //print(playermodel)
                    local splitPlayermodel = string.Split(playermodel," ")
                    local username = self:Nick()
                    if #username <= 0 then // fix a bug where the players username is empty on first spawn
                        username = GMBots.LastBotUsername
                    end
                    for j = 1,#splitPlayermodel do
                        local findStart = string.find(string.Trim(string.lower(username)),string.Trim(string.lower(splitPlayermodel[j])),nil,true)
                        if not (#playermodel > 5 and findStart) then continue end
                        nameMatchingPlayermodels[#nameMatchingPlayermodels + 1] = playermodel
                        break
                    end
                end

                if #nameMatchingPlayermodels > 0 then
                    self:BotDebug("Overriding playermodels to a list of models containing my username!")
                    playermodels = nameMatchingPlayermodels
                end

                self.GMBotsPlayerModel = playermodels[math.random(1,#playermodels)] or ""
            end
            local playermodel = self.GMBotsPlayerModel or ""

            return playermodel
        end

        if string.Trim(string.lower(cvarName)) == "cl_playercolor" then
            self.GMBotsPlayerColor = self.GMBotsPlayerColor or tostring(Vector(math.random(0,255)/255,math.random(0,255)/255,math.random(0,255)/255))
            return self.GMBotsPlayerColor
        end

        if string.Trim(string.lower(cvarName)) == "gmod_toolmode" then
            return self:GetGMBotVar("ToolMode") or "weld"
        end
    end
    return self:RealGetInfo(cvarName)
end

function PLAYER:GetInfoNum(cvarName,default)
    return self:RealGetInfoNum(cvarName,default)
end