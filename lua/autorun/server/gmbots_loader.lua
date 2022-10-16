--- [[ WELCOME TO GMBOTS REWRITTEN ]] ---
GMBots = {}
GMBots.GamemodeSupported = false
GMBots.BotPrefix = "BOT "

include("gmbots/gmbots/sv_convars.lua")

function GMBots:GetBots()
	local players = player.GetAll()
	local bots = {}
	for i = 1,#players do
		local ply = players[i]
		if ply and ply:IsValid() and ply:IsPlayer() and ply:IsGMBot() then
			bots[#bots + 1] = ply
		end
	end
	return bots
end

function GMBots:Msg(msg,col)
	return MsgC( col or Color(0,255,0), "[GMBots] "..tostring(msg).."\n")
end

function GMBots:Err(msg,prefix)
	prefix = prefix or "GMBots Error"
	ErrorNoHalt()
	return MsgC( Color(255,0,0), "["..prefix.."] "..msg.."\n")
end

function GMBots:MsgLine(col,col2) -- having 2 colors is a way to make sure people don't accidentally forget this function only has 1 argument, very lazy but i dont care
	return MsgC(col or col2 or Color(0,255,0),"-------------------------------------------------\n")
end

function GMBots:IsDebugMode()
	return GetConVar("gmbots_debug_mode"):GetInt() > 0
end

function GMBots:LoadCFG()
	local cfg = file.Read("cfg/gmbots.cfg","GAME")
	if cfg then
		GMBots:Msg("Attempting to run gmbots.cfg")
		local commands = string.Split(cfg,"\n")
		//PrintTable(commands[1])
		for i = 1,#commands do
			local commandArgs = string.Split(commands[i]," ")
			//print("!"..commandArgs[1].."!")
			pcall(function() RunConsoleCommand(string.Trim(commandArgs[1]), unpack(commandArgs,2)) end)
		end
	end
end

function GMBots:MultiMsg(tbl,col)
	self:MsgLine(col)
	for i = 1,#tbl do
		local msg = tbl[i]
		if msg then MsgC( col or Color(255,0,0), "["..prefix.."] "..msg.."\n") end
	end
	self:MsgLine(col)
end

function GMBots:GenerateNavMesh()
	--GMBots:Msg("Generating a nav mesh...")
end

function GMBots:GetDefaultName(nameList)
	local defaultNames = nameList or {"Bob","Billy","Xander","Isaiah","Alex","Alyx","Vorty","Eli","Carl"}

	return defaultNames[math.random(1,#defaultNames)]
end

function GMBots:AddBot(name)
	local bot = NULL

	if not ( not game.SinglePlayer() and player.GetCount() < game.MaxPlayers() and GMBots.GamemodeSupported ) then
		if not GMBots.GamemodeSupported then
			GMBots:Msg("Can't create bot because this gamemode isn't supported, or GMBots hasn't loaded yet!")
		else
			GMBots:Msg("Can't create bot!")
		end
	end
	local botName = tostring(self.BotPrefix)..tostring( name or self:GetDefaultName() or "???" )

	bot = player.CreateNextBot( botName )
	bot.GMBot = true
	bot.IsGMBot = function() return true end
	return bot
end

if SERVER then
	function GMBots:LoadModules()
		self:Msg("Loading modules...")
		local f_path = "gmbots/modules"

		for i = 1,2 do
			local folder_path = f_path
			if i == 1 then
				folder_path = f_path.."/default"
			end
			local files = file.Find(folder_path.."/*.lua","LUA")
			for a,b in pairs(files) do
				if not (b and b ~= "example.lua") then continue end

				local success,err = pcall(function()
					include(folder_path.."/"..b)
				end)
				if not success then
					self:Err(err or success or "Couldn't determine reason...","Module Error")
				end
				if i <= 1 then
					self:Msg("Loaded module "..b..".")
				else
					self:Msg("Loaded default module "..b..".")
				end
			end
		end
	end

	function GMBots:Load()
		GMBots.RanBefore = true
		if self and SERVER then
			local gm_name = string.lower(GAMEMODE_NAME)
			if not gm_name then
				self:Msg("Unexpected error: Couldn't find gamemode name...")
				RunConsoleCommand("gmbots_spawnmenu",0)
				return
			end
			if file.Exists("gmbots/"..gm_name..".lua","LUA") then
				include("gmbots/gmbots/sv_gmbots.lua")
				self:Msg("Loading...")

				self:LoadModules()

				GMBots.GamemodeSupported = true
				include("gmbots/"..gm_name..".lua")

				return true
			else
				--[[
				MsgC(Color(0,255,0),"-------------------------------------------------\n")
				self:Msg("Couldn't find gmbots/"..gm_name..".lua, stopping...")
				self:Msg("If you believe this is a error, try restarting your game/server, if that doesn't work, contact me!")
				MsgC(Color(0,255,0),"-------------------------------------------------\n")
				]]
				self:MultiMsg({
					"Couldn't find gmbots/"..gm_name..".lua, stopping...",
					"If you believe this is an error, try restarting your game/server! If that doesn't work, contact the developer!"
				},Color(255,255,0))
				RunConsoleCommand("gmbots_spawnmenu",0)
				return false
			end
			return false
		end
	end
end

if CLIENT then
	language.Add( "GMBots_Menu", "GMBots" )
	language.Add( "GMBots_Settings", "Settings" )
	language.Add( "GMBots_Pathfinding", "Pathfinding" )
	hook.Add( "AddToolMenuCategories", "GMBots_CustomCategory", function()
		if GetConVar("gmbots_spawnmenu"):GetInt() > 0 then
			spawnmenu.AddToolCategory( "Utilities", "GMBots", "#GMBots_Menu" )
		end
	end )

	hook.Add( "PopulateToolMenu", "GMBots_CustomMenuSettings", function()
		if GetConVar("gmbots_spawnmenu"):GetInt() > 0 then
			spawnmenu.AddToolMenuOption( "Utilities", "GMBots", "GMBots_Settings", "#GMBots_Settings", "", "", function( panel )
				panel:ClearControls()

				panel:CheckBox( "Pathfind: Go to closest area on failure?","gmbots_pf_to_closest_area" )
				panel:ControlHelp( GetConVar("gmbots_pf_to_closest_area"):GetHelpText() )

				panel:CheckBox( "Pathfind: Avoid props?","gmbots_pf_avoid_props" )
				panel:ControlHelp( GetConVar("gmbots_pf_avoid_props"):GetHelpText() )

				panel:CheckBox( "Pathfind: Skip areas marked as Avoid?","gmbots_pf_avoid_props" )
				panel:ControlHelp( GetConVar("gmbots_pf_skip_avoid"):GetHelpText() )


				if (GetConVar("sv_cheats"):GetInt() <= 0) then return end
				panel:CheckBox( "Debug Mode","gmbots_debug_mode")
				panel:ControlHelp( GetConVar("gmbots_debug_mode"):GetHelpText() )

				panel:CheckBox( "No Target","gmbots_debug_notarget")
				panel:ControlHelp( GetConVar("gmbots_debug_notarget"):GetHelpText() )

				local pfdebug = panel:ComboBox( "Pathfind: Debugging", "gmbots_debug_pathfind" )
				panel:ControlHelp( "GMBots will pathfind to the player with this UserID in the server." )

				local players = player.GetAll()

				local function updateValues()
					pfdebug:Clear()

					pfdebug:AddChoice("Disabled",0)

					for i = 1,#players do
						print(players[i]:SteamID())
						if not players[i]:IsBot() then continue end
						pfdebug:AddChoice(players[i]:Nick(),players[i]:UserID())
					end

					local curvalue = GetConVar("gmbots_debug_pathfind"):GetInt()
					for a,b in pairs(players) do
						if not b:UserID() == curvalue then continue end
						pfdebug:SetValue(b:Nick())
					end
				end

				updateValues()

				pfdebug.DefaultOpenMenu = pfdebug.OpenMenu
				pfdebug.OpenMenu = function()
					updateValues()
					pfdebug:DefaultOpenMenu()
				end
				--pfdebug.OpenMenu = function() end

				for i = 1,3 do
					panel:Help( "" )
				end



				--[[
				if sv_cheats_enabled then

					local pfdebug = panel:ComboBox( "Pathfind: Debugging", "gmbots_debug_pathfind" )
					panel:ControlHelp( "GMBots will pathfind to this player in the server." )

					local players = player.GetAll()

					local function updateValues()
						pfdebug:Clear()

						pfdebug:AddChoice("Disabled",0)

						for i = 1,#players do
							print(players[i]:SteamID())
							if not players[i]:IsBot() then
								pfdebug:AddChoice(players[i]:Nick(),players[i]:UserID())
							end
						end

						local curvalue = GetConVar("gmbots_debug_pathfind"):GetInt()
						for a,b in pairs(players) do
							if b:UserID() == curvalue then
								pfdebug:SetValue(b:Nick())
							end
						end
					end

					updateValues()

					pfdebug.DefaultOpenMenu = pfdebug.OpenMenu
					pfdebug.OpenMenu = function()
						updateValues()
						pfdebug:DefaultOpenMenu()
					end
					--pfdebug.OpenMenu = function() end
				end
				]]
			end )
		end
	end )
end

if SERVER then
	if game.IsDedicated() then RunConsoleCommand("gmbots_spawnmenu",0) end
	timer.Create("GMBots_Loader_Startup_DoNotOverwrite",2,1,function()
		if SERVER and not GMBots.RanBefore then
			if game.SinglePlayer() then
				GMBots:Msg("Game is set to singleplayer! Please change to have a player count of 2 or more for GMBots to run.")
				return
			end
			--[[
			local navareas = navmesh.GetAllNavAreas()
			if (navareas and #navareas < 0) or not navareas then
				GMBots:Msg("There isn't a navmesh!")
				if GetConVar("gmbots_gen_navmesh"):GetInt() > 0 then
					return GMBots:GenerateNavMesh()
				end
			end
			]]
			GMBots:Load()
		end
	end)
end