// TODO: Add this stuff for "voice chat" later
// https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=en&q=hello+world

print("12")

AddCSLuaFile() // this needs to run clientside as well

print('loaded')

local PLAYER = FindMetaTable("Player")

if SERVER then util.AddNetworkString( "__GMBots_Voice" ) end

local api = "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=en&q="

// taken from https://gist.github.com/liukun/f9ce7d6d14fa45fe9b924a3eed5c3d99
local char_to_hex = function(c)
    return string.format("%%%02X", string.byte(c))
end

local function urlencode(url)
    if url == nil then
      return
    end
    url = url:gsub("\n", "\r\n")
    url = url:gsub("([^%w ])", char_to_hex)
    url = url:gsub(" ", "+")
    return url
end

local function updateVoice(self)
    if self and self:IsValid() and IsValid(self.__GMBotsVoiceSound) then
        if self:IsGMBot() then
            if self:IsVoiceAudible() then
                self.__GMBotsVoiceSound:SetVolume(self:GetVoiceVolumeScale())
            else
                self.__GMBotsVoiceSound:SetVolume(0)
            end

            local state = self.__GMBotsVoiceSound:GetState()
            if state == GMOD_CHANNEL_STOPPED then
                GAMEMODE:PlayerEndVoice(self)

                self.__GMBotsVoiceSound:Stop()
                self.__GMBotsVoiceSound = nil
            end
        else
            GAMEMODE:PlayerEndVoice(self)

            self.__GMBotsVoiceSound:Stop()
            self.__GMBotsVoiceSound = nil
        end
    end
end

PLAYER.RealVoiceVolume = PLAYER.RealVoiceVolume or PLAYER.VoiceVolume
function PLAYER:VoiceVolume()
    if IsValid(self.__GMBotsVoiceSound) and self:IsGMBot() then
        local leftLevel, rightLevel = self.__GMBotsVoiceSound:GetLevel()
        local level = (leftLevel + rightLevel) / 2

        return level
    end
    return self:RealVoiceVolume()
end

local function GMBotsVoiceSoundPlayCallback(self,soundChannel)
    print(soundChannel)
    if IsValid(soundChannel) then
        soundChannel:Play()

        if self and self:IsValid() then
            GAMEMODE:PlayerStartVoice(self)
            if IsValid(self.__GMBotsVoiceSound) then
                self.__GMBotsVoiceSound:Stop()
            end
            self.__GMBotsVoiceSound = soundChannel
            local voiceTimerIdentifier = "____GMBotsVoiceTimer_"..self:UserID()
            timer.Create( voiceTimerIdentifier, 1/10, 0, function()
                if self and self:IsValid() and self.__GMBotsVoiceSound then
                    updateVoice(self)
                else
                    timer.Remove( voiceTimerIdentifier )
                end
            end)
        else
            soundChannel:Stop()
        end
    end
end

function PLAYER:BotVoice(text)
    if not (self and self:IsValid() and self:IsGMBot()) then return end
    if CLIENT then
        print("test" )
        if file.Exists(text,"GAME") then
            return self:BotVoiceFile(text)
        else
            return self:BotVoiceTTS(text)
        end
    else
        net.Start("__GMBots_Voice")
        net.WriteString(text or "")
        net.WriteInt(-1,3)
        net.WriteEntity(self)
        net.Broadcast()
    end
end

function PLAYER:BotVoiceFile(text)
    if not (self and self:IsValid() and self:IsGMBot()) then return end
    if CLIENT then
        if not self:IsVoiceAudible() then return end
        sound.PlayFile("sound/"..text,"mono",function(soundChannel) GMBotsVoiceSoundPlayCallback(self,soundChannel) end)
    else
        net.Start("__GMBots_Voice")
        net.WriteString(text or "")
        net.WriteInt(1,3)
        net.WriteEntity(self)
        net.Broadcast()
    end
end

function PLAYER:BotVoiceURL(text)
    if not (self and self:IsValid() and self:IsGMBot()) then return end
    if CLIENT then
        if not self:IsVoiceAudible() then return end
        sound.PlayURL(text,"mono",function(soundChannel) GMBotsVoiceSoundPlayCallback(self,soundChannel) end)
    else
        net.Start("__GMBots_Voice")
        net.WriteString(text or "")
        net.WriteInt(2,3)
        net.WriteEntity(self)
        net.Broadcast()
    end
end
PLAYER.BotVoiceUrl = PLAYER.BotVoiceURL

function PLAYER:BotVoiceTTS(text)
    if not (self and self:IsValid() and self:IsGMBot()) then return end
    if CLIENT then
        print(self:IsVoiceAudible())
        if not self:IsVoiceAudible() then return end
        local apiText = urlencode(text)
        sound.PlayURL(api..apiText,"mono",function(soundChannel) GMBotsVoiceSoundPlayCallback(self,soundChannel) end)
    else
        net.Start("__GMBots_Voice")
        net.WriteString(text or "")
        net.WriteInt(0,3)
        net.WriteEntity(self)
        net.Broadcast()
    end
end

if CLIENT then
    net.Receive( "__GMBots_Voice", function( len )
        local msg = net.ReadString()
        local voiceType = net.ReadInt(3)
        local ply = net.ReadEntity()
        if ply and ply:IsValid() and ply:IsPlayer() then
            if voiceType == 0 then
                ply:BotVoiceTTS(msg)
            elseif voiceType == 1 then
                ply:BotVoiceFile(msg)
            elseif voiceType == 2 then
                ply:BotVoiceURL(msg)
            else
                ply:BotVoice(msg)
            end
        end
    end )
end