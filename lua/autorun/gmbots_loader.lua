--- [[ WELCOME TO GMBOTS REWRITTEN ]] ---
GMBots = {}
GMBots.GamemodeSupported = false

local cheat_flag = bit.bor(FCVAR_CHEAT,FCVAR_UNREGISTERED)

CreateConVar("gmbots_pf_avoid_props",0,bit.bor(FCVAR_ARCHIVE,FCVAR_NEVER_AS_STRING),"Should GMBots pathfinding try to go around props?\nThis may be inaccurate, and will cause a performance hit.",0,1)
CreateConVar("gmbots_pf_to_closest_area",1,bit.bor(FCVAR_ARCHIVE,FCVAR_NEVER_AS_STRING),"Should GMBots pathfinding try to pathfind to the closest NavArea if it fails to find a path?",0,1)
CreateConVar("gmbots_pf_skip_avoid",0,bit.bor(FCVAR_ARCHIVE,FCVAR_NEVER_AS_STRING),"Should GMBots pathfinding skip areas marked as 'avoid'?")

CreateConVar("gmbots_debug_mode",0,FCVAR_NEVER_AS_STRING,"Should GMBots show debug information?",0,1)
CreateConVar("gmbots_debug_notarget",0,cheat_flag,"Should GMBots not target players? Only affects the LookForPlayers function.",0,1)
CreateConVar("gmbots_debug_pathfind",0,cheat_flag,"Should GMBots pathfind to this player in the server? Number corresponds to the player's userid, which you can find by typing 'status' in console!",0,128)

CreateConVar("gmbots_spawnmenu",1,bit.bor(FCVAR_NEVER_AS_STRING,FCVAR_REPLICATED),"Should GMBots settings show in the spawn menu?",0,1)

function GMBots:Msg(msg,col)
	return MsgC( col or Color(0,255,0), "[GMBots] "..msg.."\n")
end

function GMBots:Err(msg,prefix)
	prefix = prefix or "GMBots Error"
	ErrorNoHalt()
	return MsgC( col or Color(255,0,0), "["..prefix.."] "..msg.."\n")
end

function GMBots:LoadModules()
	self:Msg("Loading modules...")
	local f_path = "gmbots/modules"
	
	for i = 1,2 do
		local folder_path = f_path
		if i > 1 then
			folder_path = f_path.."/default"
		end
		local files, directories = file.Find(folder_path.."/*.lua","LUA")
		for a,b in pairs(files) do
			if b and b ~= "example.lua" then
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
end

function GMBots:GenerateNavMesh()
	GMBots:Msg("Generating a nav mesh...")
end

function GMBots:AddBot(name)
	local bot = NULL
	if ( !game.SinglePlayer() and player.GetCount() < game.MaxPlayers() and GMBots.GamemodeSupported ) then 
		bot = player.CreateNextBot( name or self:GetDefaultName() or "???" )
		bot.GMBot = true
	else
		if not GMBots.GamemodeSupported then
			GMBots:Msg("Can't create bot because this gamemode isn't supported, or GMBots hasn't loaded yet!")
		else
			GMBots:Msg("Can't create bot!")
		end
	end
	return bot
end

function GMBots:Load()
	GMBots.RanBefore = true
	if self and SERVER then
		local gm_name = string.lower(GAMEMODE_NAME)
		if gm_name then
			if file.Exists("gmbots/"..gm_name..".lua","LUA") then
				include("gmbots/gmbots/sv_gmbots.lua")
				self:Msg("Loading...")
				
				self:LoadModules()
				
				include("gmbots/"..gm_name..".lua")
				GMBots.GamemodeSupported = true
				
				return true
			else
				MsgC(Color(0,255,0),"-------------------------------------------------\n")
				self:Msg("Couldn't find gmbots/"..gm_name..".lua, stopping...")
				self:Msg("If you believe this is a error, try restarting your game/server, if that doesn't work, contact me!")
				MsgC(Color(0,255,0),"-------------------------------------------------\n")
				RunConsoleCommand("gmbots_spawnmenu",0)
				return false
			end
		else
			self:Msg("Unexpected error: Couldn't find gamemode name...")
			RunConsoleCommand("gmbots_spawnmenu",0)
		end
		return false
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
				
				local sv_cheats_enabled = (GetConVar("sv_cheats"):GetInt() > 0)
				
				if sv_cheats_enabled then
					panel:CheckBox( "Debug Mode","gmbots_debug_mode")
					panel:ControlHelp( GetConVar("gmbots_debug_mode"):GetHelpText() )
				
					panel:CheckBox( "No Target","gmbots_debug_notarget")
					panel:ControlHelp( GetConVar("gmbots_debug_notarget"):GetHelpText() )
				
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
					
					for i = 1,3 do
						panel:Help( "" )
					end
				end
				
				panel:CheckBox( "Pathfind: Go to closest area on failure?","gmbots_pf_to_closest_area" )
				panel:ControlHelp( GetConVar("gmbots_pf_to_closest_area"):GetHelpText() )
				
				panel:CheckBox( "Pathfind: Avoid props?","gmbots_pf_avoid_props" )
				panel:ControlHelp( GetConVar("gmbots_pf_avoid_props"):GetHelpText() )
				
				panel:CheckBox( "Pathfind: Skip areas marked as Avoid?","gmbots_pf_avoid_props" )
				panel:ControlHelp( GetConVar("gmbots_pf_skip_avoid"):GetHelpText() )
				
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

if SERVER and game.IsDedicated() then
	RunConsoleCommand("gmbots_spawnmenu",0)
end

timer.Create("GMBots_Loader_Startup_DoNotOverwrite",2,1,function()
	if SERVER and not GMBots.RanBefore then
		if game.SinglePlayer() then
			GMBots:Msg("Can't run in singleplayer!")
			return
		end
		local navareas = navmesh.GetAllNavAreas()
		if (navareas and #navareas < 0) or not navareas then
			GMBots:Msg("There isn't a navmesh!")
			if GetConVar("gmbots_gen_navmesh"):GetInt() > 0 then
				return GMBots:GenerateNavMesh()
			end
		end
		GMBots:Load()
	end
end)