local debugoverlay = debugoverlay
local PLAYER = FindMetaTable("Player")
local ENTITY = FindMetaTable("Entity")

GMBots.Debug = {}

for key, func in pairs(debugoverlay) do
    GMBots.Debug[key] = function(...)
        if not GMBots:IsDebugMode() then return end
        return func(...)
    end
end

function math.average(...)
	local varargs = ...
	if varargs and istable(varargs) then varargs = unpack(varargs) end

	local amount = select('#', varargs)
	local sum = 0
	for i = 1, amount do
		local arg = select(i, varargs)

		sum = sum + tonumber(arg)
	end
	return sum / amount
end

function PLAYER:BotError(msg)
	if self and self.Nick and self:IsGMBot() then
		ErrorNoHalt()
		return MsgC(Color(255,0,0),"[ERROR, BOT "..self:Nick().."] "..msg.."\n")
	end
end

function PLAYER:BotDebug(msg)
	if not GMBots:IsDebugMode() then return false end

	if self and self.Nick and self.GMBot then
		return MsgC(Color(0,255,255),"[BOT "..self:Nick().."] "..msg.."\n")
	end
end


function ENTITY:BenchmarkFunction(func,...)
	if(isstring(func)) then func = self[func] end
	--[[
	local varargs = ...
	if func then
		return GMBots:BenchmarkFunction(function() return func(self,varargs) end)
	else
		print("function doesn't exist")
	end]]
	return GMBots:BenchmarkFunction(func,self,...)
end

function GMBots:BenchmarkFunction(func,...)
	if not GMBots:IsDebugMode() then return end
	print("test")
	local times = {}
	for i = 1,5000 do
		local startTime = SysTime()
		func(...)
		local endTime = SysTime()
		local totalTime = endTime - startTime
		times[i] = totalTime * 1000
		//print("benchmark function took "..(totalTime * 1000).."ms")
	end
	local average = math.average(times)
	print("average time is "..average.."ms")
	return average
end
GMBots.Debug.BenchmarkFunction = GMBots.BenchmarkFunction