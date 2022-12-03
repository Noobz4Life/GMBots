local PLAYER = FindMetaTable("Player")

function PLAYER:Pathfind()
	GMBots:Msg("Pathfind Module isn't loaded!")
	return
end

function PLAYER:BotError(msg)
	if self and self.Nick and self.GMBot then
		ErrorNoHalt()
		return MsgC(Color(255,0,0),"[ERROR, BOT "..self:Nick().."] "..msg.."\n")
	end
end

function PLAYER:BotDebug(msg)
	local convar = GetConVar("gmbots_debug_mode")
	if convar and convar:GetInt() <= 0 then
		return false
	end

	if self and self.Nick and self.GMBot then
		return MsgC(Color(0,255,255),"[BOT "..self:Nick().."] "..msg.."\n")
	end
end

function GMBots:GetDefaultName()
	local names = {
		// Team Fortress 2s Bot Names
		"A Professional With Standards",
		"AimBot",
		"AmNot",
		"Aperture Science Prototype XR7",
		"Archimedes!",
		"BeepBeepBoop",
		"Big Mean Muther Hubbard",
		"Black Mesa",
		"BoomerBile",
		"Cannon Fodder",
		"CEDA",
		"Chell",
		"Chucklenuts",
		"Companion Cube",
		"Crazed Gunman",
		"CreditToTeam",
		"CRITRAWKETS",
		"Crowbar",
		"CryBaby",
		"CrySomeMore",
		"C++",
		"DeadHead",
		"Delicious Cake",
		"Divide by Zero",
		"Dog",
		"Force of Nature",
		"Freakin' Unbelievable",
		"Gentlemanne of Leisure",
		"GENTLE MANNE of LEISURE",
		"GLaDOS",
		"Glorified Toaster with Legs",
		"Grim Bloody Fable",
		"GutsAndGlory!",
		"Hat-Wearing MAN",
		"Headful of Eyeballs",
		"Herr Doktor",
		"HI THERE",
		"Hostage",
		"Humans Are Weak",
		"H@XX0RZ",
		"I LIVE!",
		"It's Filthy in There!",
		"IvanTheSpaceBiker",
		"Kaboom!",
		"Kill Me",
		"LOS LOS LOS",
		"Maggot",
		"Mann Co.",
		"Me",
		"Mega Baboon",
		"Mentlegen",
		"MindlessElectrons",
		"MoreGun",
		"Nobody",
		"Nom Nom Nom",
		"NotMe",
		"Numnutz",
		"One-Man Cheeseburger Apocalypse",
		"Poopy Joe",
		"Pow!",
		"RageQuit",
		"Ribs Grow Back",
		"Saxton Hale",
		"Screamin' Eagles",
		"SMELLY UNFORTUNATE",
		"SomeDude",
		"Someone Else",
		"Soulless",
		"Still Alive",
		"TAAAAANK!",
		"Target Practice",
		"ThatGuy",
		"The Administrator",
		"The Combine",
		"The Freeman",
		"The G-Man",
		"THEM",
		"Tiny Baby Man",
		"Totally Not A Bot",
		"trigger_hurt",
		"WITCH",
		"ZAWMBEEZ",
		"Ze Ubermensch",
		"Zepheniah Mann",
		"0xDEADBEEF",
		"1000",

		// Half-Life based usernames
		"Alyx",
		"Vorty",
		"Eli",
		"Laszlo", //the finest mind of this generation!

		// Mario-based usernames
		"Yoshi",
		"Mario",
		"Luigi",
		"Wario",
		"Waluigi",
		"Bowser",
		"Bowser Jr.",
		"Koopa",
		"Dry Bones",

		// Undertale/Deltarune based usernames
		"Ralsei",
		"Asriel",
		"Kris",
		"Toriel",
		"Asgore",

		// Pokemon names
		"Gengar",
		"Pikachu",
		"Lugia",
		"Charmander",
		"Charizard",
		"Bulbasaur",
		"Eevee",
		"Lucario",
		"Tyranitar",

		// Haha funny names
		"Peter",
		"Homer",
		"AMOGUS",
		"Sus"
	}
	return names[math.random(1,#names)]
end

hook.Add( "PhysgunPickup", "AllowPlayerPickup", function( ply, ent )
	if ( ply:IsSuperAdmin() and ent:IsPlayer() and ent.GMBot) then
		return true
	end
end )

local function isAllowedToRun(ply)
	if SERVER and not ply then
		return true
	end

	if SERVER and not IsValid(ply) then
		return true
	end

	if SERVER and ply and ply:IsValid() and ply:IsPlayer() and ply:IsSuperAdmin() then
		return true
	end

	return false
end

concommand.Add("gmbots_bot_add", function( ply, cmd, args )
	if isAllowedToRun(ply) then
		GMBots:AddBot()
	end
end,nil,"Spawns a bot.",FCVAR_LUA_SERVER)

concommand.Add("gmbots_kick_all", function( ply, cmd, args )
	if isAllowedToRun(ply) then
		for a,b in pairs(player.GetAll()) do
			if b and b:IsValid() and b.GMBot then
				b:Kick("Kicking all bots...")
			end
		end
	end
end,nil,"Kick all bots.",FCVAR_LUA_SERVER)

hook.Add("PlayerDisconnected", "ulxSlotsDisconnect", function(ply)
	--If player is bot.
	if ply:SteamID() == "BOT" then
		--Do nothing.
		return
	end
end)