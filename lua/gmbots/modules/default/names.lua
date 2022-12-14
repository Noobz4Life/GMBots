//GMBots.StolenNames = {}

local function nameTaken(name)
    for _,ply in pairs(player.GetAll()) do
        if string.Trim(string.lower(ply:BotName() or ply:Nick())) == string.Trim(string.lower(name)) then
            return true
        end
    end
	return false
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
    //table.Merge(names,GMBots.StolenNames)

    local attempts = 0
    local name = nil
    while (not name or nameTaken(name)) and attempts < 1024 do
        name = names[math.random(1,#names)]
        attempts = attempts + 1
    end
	return name or names[math.random(1,#names)] or "???"
end