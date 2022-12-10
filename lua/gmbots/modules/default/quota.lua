local function countBots()
    local botCount = 0
    for _,bot in pairs(GMBots:GetBots() or player.GetAll()) do
        if bot and bot:IsValid() and bot:IsGMBot() and bot:IsBot() then
            botCount = botCount + 1
        end
    end
    return botCount
end

local function countPlayers()
    local plrCount = 0
    for _,plr in pairs(player.GetAll()) do
        if plr and plr:IsValid() and not (plr:IsGMBot() and plr:IsBot()) then
            plrCount = plrCount + 1
        end
    end
    return plrCount
end

local function findDuplicateName(bots)
    for _,ply in pairs(player.GetAll()) do
        if not (ply and ply:IsValid() and not (ply:IsBot() and ply:IsGMBot())) then continue end
        for _,bot in pairs(bots or player.GetAll()) do
            if not (bot and bot:IsValid() and (bot:IsBot() and bot:IsGMBot())) then continue end
            if ply and ply:Nick() == ply:BotName() then
                return bot
            end
        end
    end
end

local updatingQuota = false

function GMBots:UpdateQuota(newQuota,oldValue)
    if updatingQuota then return end

    local botCount = countBots() or 0
    local realQuota = math.min(game.MaxPlayers(),tonumber(newQuota) or GetConVar("gmbots_bot_quota"):GetInt() or 0)

    if realQuota <= 0 and not (oldValue and tonumber(oldValue) > 0) then return end
    local quota = realQuota - countPlayers()
    local bots = GMBots:GetBots()

    updatingQuota = true

    for i = 1,game.MaxPlayers() do
        if botCount < quota then
            local bot = GMBots:AddBot()
            if bot and bot:IsValid() then
                botCount = botCount + 1
            end
        elseif botCount > quota then
            local botToKick = findDuplicateName(bots) or bots[math.random(1,#bots)]
            if botToKick and botToKick:IsValid() then
                botCount = botCount - 1
                print("kicking "..tostring(botToKick))
                botToKick:Kick()
                table.RemoveByValue(bots, botToKick)
            end
        end
    end
    updatingQuota = false
end

cvars.AddChangeCallback( "gmbots_bot_quota", function(name,oldValue,newValue)
    GMBots:UpdateQuota(newValue,oldValue)
end, "__GMBots_UpdateQuotaCallback" )

local function updateQuotaOnSlotChange(data)
    if data and not data.Bot and data.networkid ~= "BOT" then
        GMBots:UpdateQuota()
    end
end

gameevent.Listen( "player_connect" )
gameevent.Listen( "player_disconnect" )
GMBots:AddInternalHook("player_connect",updateQuotaOnSlotChange,"QuotaConnect")
GMBots:AddInternalHook("player_disconnect",updateQuotaOnSlotChange,"QuotaDisconnect")

GMBots:UpdateQuota()