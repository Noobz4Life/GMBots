local cheat_flag = bit.bor(FCVAR_CHEAT,FCVAR_UNREGISTERED)
local pf_flag = bit.bor(FCVAR_ARCHIVE,FCVAR_NEVER_AS_STRING)

CreateConVar("gmbots_use_playermodels",1,bit.bor(FCVAR_ARCHIVE,FCVAR_NEVER_AS_STRING),"Should GMBots use cl_playermodel or should they use the gamemodes default model?\n(Only works in Sandbox or with Extended Playermodel Selector")

CreateConVar("gmbots_pf_avoid_props",0,pf_flag,"Should GMBots pathfinding try to go around props?\nThis may be inaccurate, and will cause a performance hit.",0,1)
CreateConVar("gmbots_pf_to_closest_area",1,pf_flag,"Should GMBots pathfinding try to pathfind to the closest NavArea if it fails to find a path?",0,1)
CreateConVar("gmbots_pf_skip_avoid",0,pf_flag,"Should GMBots pathfinding skip areas marked as 'avoid'?")
//CreateConVar("gmbots_pf_smooth",1,pf_flag,"Should GMBots try to smooth the pathfinding out at the cost of performance?",0,1)

CreateConVar("gmbots_pf_teleportation",1,pf_flag,"Should bots teleport if stuck? (players marked as bots are always ignored)\n"
	.."\n 0 = Don't teleport"
	.."\n 1 = Teleport if both the bot and the end location isn't visible to players"
	.."\n 2 = Teleport if the bot isn't visible to other players"
	.."\n 3 = Teleport no matter what.")
CreateConVar("gmbots_pf_teleportation_location",0,pf_flag,"Where should the bots teleport if stuck? (assuming gmbots_pf_teleportation is also set to 1\n"
	.."\n 0 = Teleport to next pathfinding node"
	.."\n 1 = Attempt to teleport to the center of the nearest navmesh")

CreateConVar("gmbots_pause_while_typing",1,FCVAR_NEVER_AS_STRING,"Should bots disable their AI while typing?",0,1)

CreateConVar("gmbots_collision", 1, bit.bor(FCVAR_ARCHIVE,FCVAR_NEVER_AS_STRING),"Enables custom collisions compared to normal players (This may be disabled by the current gamemode script)")
//CreateConVar("gmbots_collision_bots",0,bit.bor(FCVAR_ARCHIVE,FCVAR_NEVER_AS_STRING),"Should bots collide with other bots? (This may be disabled by the current gamemode script)")
CreateConVar("gmbots_collision_doors",0,pf_flag,"Should bots collide with doors? (This may be disabled by the current gamemode script)")
CreateConVar("gmbots_collision_ignore","",FCVAR_ARCHIVE,"What entities should bots not collide with? (This may be disabled by the current gamemode script)")

CreateConVar("gmbots_debug_mode",0,FCVAR_NEVER_AS_STRING,"Should GMBots show debug information?",0,1)
CreateConVar("gmbots_debug_notarget",0,cheat_flag,"Should GMBots not target players? Only affects the LookForPlayers function.",0,1)
CreateConVar("gmbots_debug_pathfind",0,cheat_flag,"Should GMBots pathfind to this player in the server? Number corresponds to the player's userid, which you can find by typing 'status' in console!",0,128)

CreateConVar("gmbots_spawnmenu",1,bit.bor(FCVAR_NEVER_AS_STRING,FCVAR_REPLICATED),"Should GMBots settings show in the spawn menu?",0,1)

CreateConVar("gmbots_bot_quota",0,bit.bor(FCVAR_ARCHIVE,FCVAR_NEVER_AS_STRING),"How many bots should automatically spawn to fill in player slots?",0,math.max(128,game.MaxPlayers()))