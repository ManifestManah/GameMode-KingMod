///////////////////////
// Actual Code Below //
///////////////////////

// List of Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
// #include <clientprefs>
#include <multicolors>

// The code formatting rules we wish to follow
#pragma semicolon 1;
#pragma newdecls required;


// The retrievable information about the plugin itself 
public Plugin myinfo =
{
	name		= "[CS:GO] King Mod - Core",
	author		= "Manifest @Road To Glory",
	description	= "Handles the core part of the King Mod game mode.",
	version		= "V. 1.0.0 [Beta]",
	url			= ""
};


/////////////////////////
// - Planned Convars - //
/////////////////////////

bool cvar_HideMoneyHud = true;
bool cvar_EffectTesla = true;
bool cvar_EffectRing = true;
bool cvar_KingPowerChooser = true;

bool cvar_PowerImpregnableArmor = false;
bool cvar_PowerMovementSpeed = false;
bool cvar_PowerStickyGrenades = false;
bool cvar_PowerScoutNoScope = false;
bool cvar_PowerCarpetBombingFlashbangs = false;
bool cvar_PowerNapalm = false;
bool cvar_PowerRiot = false;
bool cvar_PowerVampire = false;
bool cvar_PowerBreachCharges = false;
bool cvar_PowerLegCrushingBumpmines = false;
bool cvar_PowerHatchetMassacre = false;
bool cvar_PowerChuckNorrisFists = false;
bool cvar_PowerLaserGun = false;
bool cvar_PowerLuckyNumberSeven = false;
bool cvar_PowerWesternShootout = false;
bool cvar_PowerBabonicPlague = false;
bool cvar_PowerZombieApocalypse = false;
bool cvar_PowerBlastCannon = false;
bool cvar_PowerDeagleHeadshot = false;
bool cvar_PowerLaserPointer = false;
bool cvar_PowerHammerTime = false;
bool cvar_PowerDoomChickens = true;

int cvar_PointsNormalKill = 1;
int cvar_PointsKingKill = 3;
int cvar_DropChance = 33;
int cvar_KingHealth = 200;
int cvar_SentryGunHealth = 999; // Please note setting this to 999 or above will turn the sentry guns invulnerable
int cvar_SentryGunVolumePercentage = 12;

float cvar_RespawnTime = 1.50;
float cvar_ImmobilityTime = 3.00;
float cvar_SpawnProtectionDuration = 3.0;
float cvar_RecoveryCooldownDuration = 10.00;
float cvar_HealthshotExpirationTime = 10.0;


////////////////////////////////
// - Global Power Variables - //
////////////////////////////////

bool powerStickyGrenades = false;
bool powerScoutNoScope = false;
bool powerNapalm = false;
bool powerRiot = false;
bool powerHatchetMassacre = false;
bool powerChuckNorris = false;
bool powerLuckyNumberSeven = false;
bool powerWesternShootout = false;
bool powerZombieApocalypse = false;
bool powerBlastCannon = false;
bool powerDeagleHeadshot = false;
bool powerLaserPointer = false;
bool powerHammerTime = false;
bool powerDoomChickens = false;

int powerImpregnableArmor = 0;
int powerMovementSpeed = 0;
int powerCarpetBombingFlashbangs = 0;
int powerVampire = 0;
int powerBreachCharges = 0;
int powerLegCrushingBumpmines = 0;
int powerLaserGun = 0;
int powerBabonicPlague = 0;


//////////////////////////
// - Global Variables - //
//////////////////////////


// Global Booleans
bool gameInProgress = true;
bool mapHasPlatformSupport = false;
bool isPlayerKing[MAXPLAYERS + 1] = {false,...};
bool isPlayerProtected[MAXPLAYERS + 1] = {false,...};
bool isPlayerControllingBot[MAXPLAYERS + 1] = {false,...};
bool displayRestrictionHud[MAXPLAYERS + 1] = {false,...};
bool isRecoveryOnCooldown[MAXPLAYERS + 1] = {false,...};
bool injectingHealthshot[MAXPLAYERS + 1] = {false,...};
bool cooldownHealthshot[MAXPLAYERS + 1] = {false,...};
bool cooldownWeaponSwapMessage[MAXPLAYERS + 1] = {false,...};
bool powerHatchetMassacreCooldown[MAXPLAYERS + 1] = {false,...};
bool playerSwappedWeapons[MAXPLAYERS + 1] = {false,...};
bool powerBabonicPlagueInfected[MAXPLAYERS + 1] = {false,...};
bool powerHammerTimeBuried[MAXPLAYERS + 1] = {false,...};
bool LaserPointerTickCoolDown[MAXPLAYERS + 1] = {false,...};


// Global Integers
int kingIndex = 0;
int kingIsOnTeam = 0;
int pointCounterT = 0;
int pointCounterCT = 0;
int mapHasMinimapHidden = 0;
int kingRecoveryCounter = 0;
int kingIsAcquiringPower = 0;
int powerZombieAffectedTeam = 0;
int colorRGB[3];
int effectRing = 0;
int effectLaser = 0;
int effectSmoke = 0;
int effectExplosion = 0;
int PlayerSpawnCount[MAXPLAYERS+1] = {0, ...};
int playerHealthPreInjection[MAXPLAYERS+1] = {0, ...};
int powerNapalmDamageTaken[MAXPLAYERS+1] = {0, ...};
int EntityOwner[2049] = {-1, ...};


// Global Floats
float platformLocation[3];


// Global Characters
char kingName[64];
char kingWeapon[64];
char colorCombination[32];
char nameOfPower[64];
char nameOfTier[16];
char dottedLine[128];
char powerSoundName[128];
char skyboxName[128];
char PlayerClanTag[MAXPLAYERS + 1][14];



//////////////////////////
// - Forwards & Hooks - //
//////////////////////////


// This happens when the plugin is loaded
public void OnPluginStart()
{
	// Finds the sv_cheats convar and store it within our conVarCheats value
	ConVar conVarCheats = FindConVar("sv_cheats");

	// Obtains the flags related to the sv_cheats convar
	int notifyFlag = GetConVarFlags(conVarCheats);

	// Changes the notify status for the sv_cheats to not notify about value changes
	notifyFlag &= ~FCVAR_NOTIFY;

	// Sets the convar flag to the new rule that we applied for our convar
	SetConVarFlags(conVarCheats, notifyFlag);

	// Adds a command only available to administrators with the Root flag
	RegAdminCmd("sm_platform", Command_DeveloperMenu, ADMFLAG_ROOT);

	// Hooks the events that we intend to use in our plugin
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_falldamage", Event_PlayerFalldamage, EventHookMode_Post);
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);

	// Calls upon our CommandListenerJoinTeam function whenever a player changes team
	AddCommandListener(CommandListenerJoinTeam, "jointeam");

	// Creates a sound hook to reduce the sound produced when sentry guns shoot
	AddNormalSoundHook(SoundHookSentryGuns);

	// Creates a timer that will check if people are on fire and at low health every 0.5 seconds
	PowerNapalmStartTimer();

	// Creates a timer that will apply babonic plague's effects every 1.5 second if the babonic plague king power is currently active
	CreateTimer(1.5, Timer_PowerBabonicPlagueLoop, _, TIMER_REPEAT);

	// Creates a timer that will update the team score hud every 1.0 second
	CreateTimer(1.0, Timer_UpdateTeamScoreHud, _, TIMER_REPEAT);

	// Creates a timer that will modify the env_gunfire used by the sentry guns once every 1.0 second  
	CreateTimer(1.0, SentryGunModifyGunFire, _, TIMER_REPEAT || TIMER_FLAG_NO_MAPCHANGE);

	// Creates a timer that will remove dropped items and weapons from the map every 2.5 seconds
	CreateTimer(2.5, Timer_CleanFloor, _, TIMER_REPEAT);

	// Adds a hook for mp_restartgame to prevent the usage of it
	PreventRestartGameUsage();

	// Adds all of the game mode's required files to the download list and precaches content that needs precaching
	DownloadAndPrecacheFiles();

	// Allows the modification to be loaded while the server is running, without causing gameplay issues
	LateLoadSupport();

	// Loads the translaltion file which we intend to use
// TO DO	LoadTranslations("manifest_kingmod.phrases");
}


// This happens when the plugin is unloaded
public void OnPluginEnd()
{
	PrintToChatAll("King Mod has been unloaded.");
	PrintToChatAll("A new round will soon commence.");

	// Changes the skybox back to the skybox that was saved prior to altering it to the zombie apocalypse skybox
	PowerZombieApocalypseResetSkybox();

	// Removes all overlays that may currently be applied to players' screens
	RemoveAllScreenOverlays();

	// Forcefully ends the round and considers it a round draw
	CS_TerminateRound(3.0, CSRoundEnd_Draw);
}


// This happens when a new map is loaded
public void OnMapStart()
{
	// Adds all of the game mode's required files to the download list and precaches content that needs precaching
	DownloadAndPrecacheFiles();

	// Checks if the current map has been configured to have platform support included 
	CheckForPlatformSupport();

	// Disables CS:GO's built-in money hud element and money related messages if the cvar is enabled
	HudElementMoney();

	// Executes the configuration file containing the modification specific configurations
	ServerCommand("exec sourcemod/KingMod/kingmod.cfg");
}


// This happens once all post authorizations have been performed and the client is fully in-game
public void OnClientPostAdminCheck(int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return;
	}

	// Adds a hook to the client which will let us track when the player is eligible to pick up a weapon
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);

	// Adds a hook to the client which will let us track when the player picks up a weapon
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);

	// Adds a hook to the client which will let us track when the player changes weapon
	SDKHook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanSwitchTo);

	// Adds a hook to the client which will let us track when the player takes damage
	SDKHook(client, SDKHook_OnTakeDamage, OnDamageTaken);

	// Adds a hook to the client which will let us track when the client uses their weapon's scope
	SDKHook(client, SDKHook_PreThink, OnPreThink);

	// Adds a hook to the client which will let us track when the client takes damage and remains alive
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive); 

	// Attempts to auto-assign the player to the team at a disadvantage after the mp_force_pick_time duration
	AutoJoinTeam(client);
}


// This happens when a player disconnects
public void OnClientDisconnect(int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return;
	}

	// If the client is not a controlled bot then execute this section
	if(isPlayerControllingBot[client])
	{
		// Attempts to respawn all bots that are currently dead
		RespawnOvertakenBots();
	}

	// Removes the hook that we had added to the client to track when he was eligible to pick up weapons
	SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);

	// Removes the hook that we had added to the client to track when he had picked up a weapon
	SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponEquip);

	// Removes the hook that we had added to the client to track when he changes weapon
	SDKUnhook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanSwitchTo);

	// Removes the hook that we added to track when the player takes damage
	SDKUnhook(client, SDKHook_OnTakeDamage, OnDamageTaken);

	// Removes the hook that we added to track when the client is using their weapon's scope
	SDKUnhook(client, SDKHook_PreThink, OnPreThink);

	// Removes the hook that we added to track when the player takes damage and remains alive
	SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive); 

	// If the client is not the current king then execute this section
	if(!isPlayerKing[client])
	{
		return;
	}

	// Changes the killed player's king status to false
	isPlayerKing[client] = false;

	// Removes any currently present king crowns from the game
	RemoveCrownEntity();

	// Changes the indicator of which team the King is currently on be none
	kingIsOnTeam = 0;

	// Changes the kingName variable's value to just be None
	kingName = "None";

	PrintToChatAll("Debug: The king has disconnected from the game");

	return;
}


// This happens when a player joins or changes team 
public Action CommandListenerJoinTeam(int client, const char[] command, int numArgs)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Calls upon the Timer_RespawnPlayer function after (1.5 default) seconds
	CreateTimer(cvar_RespawnTime, Timer_RespawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}


// This happens when a player presses a key
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float unused_velocity[3]) 
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If thg king power chooser is enabled and the chuck norris fists or the hatchet massacre powers are enabled then execute this section
	if(cvar_KingPowerChooser && cvar_PowerChuckNorrisFists | cvar_PowerHatchetMassacre | cvar_PowerHammerTime | cvar_PowerLaserPointer)
	{
		// If the currently active power is either hatchet massacre or chuck norris fists then execute this section
		if(powerChuckNorris | powerHatchetMassacre | powerHammerTime | powerLaserPointer)
		{
			// If the client is not alive then execute this section
			if(!IsPlayerAlive(client))
			{
				return Plugin_Continue;
			}

			// If the player is pressing their secondary attack button then execute this section
			if(buttons & IN_ATTACK2)
			{
				// Obtains the name of the player's weapon and store it within our variable entity
				int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

				// If the entity does not meet our criteria validation then execute this section
				if(!IsValidEntity(entity))
				{
					return Plugin_Continue;
				}

				// Creates a variable to store our data within
				char classname[32];

				// Obtains the classname of the entity and store it within our classname variable
				GetEdictClassname(entity, classname, sizeof(classname));

				// If the entity is not a pair of fists or an axe then execute this section
				if(!StrEqual(classname, "weapon_fists") && !StrEqual(classname, "weapon_melee"))
				{
					return Plugin_Continue;
				}

				// Blocks the usage of the second attack button
				buttons &= ~IN_ATTACK2;

				return Plugin_Changed;
			}
		}

		// If the cvar for the Laser Pointer power is enabled then execute this section
		if(powerLaserPointer)
		{
			// If the client is not the current king then execute this section
			if(!isPlayerKing[client])
			{
				return Plugin_Continue;
			}

			// If the client is not alive then execute this section
			if(!IsPlayerAlive(client))
			{
				return Plugin_Continue;
			}

			// If the player is pressing their USE button then execute this section
			if(buttons & IN_USE)
			{
				// If the player is has not recently received a message regarding weapon swapping being blockd then execute this section 
				if(LaserPointerTickCoolDown[client])
				{
					return Plugin_Continue;
				}

				// Changes the player's LaserPointerTickCoolDown state to true
				LaserPointerTickCoolDown[client] = true;

				// Removes the cooldown for announcing messages regarding the blocking of weapons
				CreateTimer(0.083, Timer_RemoveLaserPointerTickCoolDown, client, TIMER_FLAG_NO_MAPCHANGE);

				// Creates a variable which we will store data within
				float eyeAngles[3];

				// Creates a variable which we will store data within
				float eyeLocation[3];
				
				// Obtains the client's eye angles and store them within our eyeAngles variable
				GetClientEyeAngles(client, eyeAngles);

				// Obtains the client's eye location and store it within our eyeLocation variable
				GetClientEyePosition(client, eyeLocation);
				
				// Modifies the eyeLocation position on the z-axis by -8.0
				eyeLocation[2] -= 8.0;
				
				// Checks for whether the client is aiming at a player and store it within our rayTraceHandle variable 
				Handle rayTraceHandle = TR_TraceRayFilterEx(eyeLocation, eyeAngles, (CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_GRATE), RayType_Infinite, TraceRayHitPlayers, client);
				
				// If the rayTraceHandle is not invalid then execute this section
				if(TR_DidHit(rayTraceHandle))
				{
					// Creates a variable which we will store data within
					float endLocation[3];

					// Gets the end location point of our raytrace and store it within the endLocation variable
					TR_GetEndPosition(endLocation, rayTraceHandle);

					// Obtains the entity index of the player that was hit and store it within the victimPlayer variable
					int victimPlayer = TR_GetEntityIndex(rayTraceHandle);

					// Creates a laser beam using temp entities that spand from the client to he location he aims at  
					TE_SetupBeamPoints(eyeLocation, endLocation, effectLaser, effectLaser, 0, 0, 0.25, 0.3, 0.3, 1, 0.0, {255, 0, 220, 205}, 0);

					// Sends the visual effect temp entity to the relevant players
					ShowVisualEffectToPlayers();

					// If the victimPlayer does not meet our validation criteria then execute this section
					if(!IsValidClient(victimPlayer))
					{
						return Plugin_Continue;
					}
					
					// Inflicts 4.0 damage to the enemy upon the victim as if it was damage dealt from the king
					DealDamageToClient(victimPlayer, client, 4, "weapon_tagrenade");
				}

				// Deletes our rayTraceHandle as we are done using it
				delete rayTraceHandle;
			}
		}
	}

	// If the player is spawn protected then execute this section
	if(isPlayerProtected[client])
	{
		// If the client is not alive then execute this section
		if(!IsPlayerAlive(client))
		{
			return Plugin_Continue;
		}

		// Obtains the client's active weapon and store it within the variable: weapon
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

		// If the weapon that was picked up our entity criteria of validation then execute this section
		if(!IsValidEntity(weapon))
		{
			return Plugin_Continue;
		}

		// Obtains the player's weapon based on weapon slot
		int knife_weapon = GetPlayerWeaponSlot(client, 2);

		// If the knife_weapon entity does not meet our criteria of validation then execute this section
		if(!IsValidEntity(knife_weapon))
		{
			return Plugin_Continue;
		}

		// If the entity stored within our weapon variable and the entity stored within our knife_weapon differs then execute this section
		if(weapon != knife_weapon)
		{
			return Plugin_Continue;
		}

		// if the player presses their right click button then execute this
		if(buttons & IN_ATTACK2)
		{
			// Removes the spawn protection from the client
			RemoveSpawnProtection(client);
		}
	}

	// If the client is alive then execute this section
	if(IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	// Obtains the target that the client is observing and store its' index within the observerTarget variable
	int observerTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");

	// If the observerTarget does not meet our validation criteria then execute this section
	if(!IsValidClient(observerTarget))
	{
		return Plugin_Continue;
	}

	// If the observerTarget is on a different team than the client then execute this section
	if(GetClientTeam(observerTarget) != GetClientTeam(client))
	{
		return Plugin_Continue;
	}

	// If the observerTarget is not a bot then execute this section
	if(!IsFakeClient(observerTarget))
	{
		return Plugin_Continue;
	}

	// If the player presses their USE button then execute this section
	if(buttons & IN_USE)
	{
		// If the observerTarget is not the current king then execute this section
		if(!isPlayerKing[observerTarget])
		{
			// Changes the isPlayerControllingBot to true
			isPlayerControllingBot[client] = true;

			PrintToChat(client, "You took over a bot");

			return Plugin_Continue;
		}

		PrintToChat(client, "You cannot take over the bot if it is the current king");

		return Plugin_Handled;
	}

	return Plugin_Continue;
}


// This happens when a player can pick up a weapon
public Action OnWeaponCanUse(int client, int weapon)
{
	// If the weapon that was picked up our entity criteria of validation then execute this section
	if(!IsValidEntity(weapon))
	{
		return Plugin_Continue;
	}

	// Creates a variable called ClassName which we will store the weapon entity's name within
	char ClassName[64];

	// Obtains the classname of the weapon entity and store it within our ClassName variable
	GetEntityClassname(weapon, ClassName, sizeof(ClassName));

	// If the client is the current king then execute this section
	if(isPlayerKing[client])
	{
		// If the currently active power is Laser Pointer then execute this section
		if(powerLaserPointer)
		{
			// If the weapon's entity name is not weapon_healthshot then execute this section
			if(!StrEqual(ClassName, "weapon_healthshot", false))
			{
				return Plugin_Handled;
			}
		}

		// If the weapon's entity name is weapon_knifegg then execute this section
		if(StrEqual(ClassName, "weapon_knifegg", false))
		{
			return Plugin_Continue;
		}
		
		// If the king's current power is the sticky grenades power then execute this section
		if(powerStickyGrenades)
		{
			// If the weapon is a high explosive grenad then excute this section
			if(StrEqual(ClassName, "weapon_hegrenade", false))
			{
				return Plugin_Continue;
			}
		}

		// If the king's current power is the scout no scope power then execute this section
		if(powerScoutNoScope)
		{
			// If the weapon is a ssg08 then excute this section
			if(StrEqual(ClassName, "weapon_ssg08", false))
			{
				return Plugin_Continue;
			}
		}

		// If the king's current power is the carpet bombing flashbangs power then execute this section
		if(powerCarpetBombingFlashbangs)
		{
			// If the weapon is a flashbang then excute this section
			if(StrEqual(ClassName, "weapon_flashbang", false))
			{
				return Plugin_Continue;
			}
		}

		// If the king's current power is the napalm power then execute this section
		if(powerNapalm)
		{
			// If the weapon is a molotov then excute this section
			if(StrEqual(ClassName, "weapon_molotov", false))
			{
				return Plugin_Continue;
			}
		}

		// If the currently active power is riot then execute this section
		if(powerRiot)
		{
			// If the weapon is a shield then excute this section
			if(StrEqual(ClassName, "weapon_shield", false))
			{
				return Plugin_Continue;
			}
		}

		// If the currently active power is breachcharges then execute this section
		if(powerBreachCharges)
		{
			// If the weapon is a breachcharge then excute this section
			if(StrEqual(ClassName, "weapon_breachcharge", false))
			{
				return Plugin_Continue;
			}
		}

		// If the currently active power is leg crushing bumpmines then execute this section
		if(powerLegCrushingBumpmines)
		{
			// If the weapon is a bumpmine then excute this section
			if(StrEqual(ClassName, "weapon_bumpmine", false))
			{
				return Plugin_Continue;
			}
		}

		// If the currently active power is hatchet massacre then execute this section
		if(powerHatchetMassacre)
		{
			// If the weapon is an hatchet massacre then excute this section
			if(StrEqual(ClassName, "weapon_melee", false))
			{
				EquipPlayerWeapon(client, weapon);

				return Plugin_Continue;
			}
		}

		// If the currently active power is chuck norris fists then execute this section
		if(powerChuckNorris)
		{
			// If the weapon is a pair of fists then excute this section
			if(StrEqual(ClassName, "weapon_fists", false))
			{
				EquipPlayerWeapon(client, weapon);

				return Plugin_Continue;
			}
		}

		// If the currently active power is laser gun then execute this section
		if(powerLaserGun)
		{
			// If the weapon is a cz75a (p250 shares item slot with it) then excute this section
			if(StrEqual(ClassName, "weapon_p250", false))
			{
				return Plugin_Continue;
			}
		}

		// If the currently active power is western shootout then execute this section
		if(powerWesternShootout)
		{
			// If the weapon is a revolver (deagle shares item slot with it) then excute this section
			if(StrEqual(ClassName, "weapon_deagle", false))
			{
				return Plugin_Continue;
			}
		}

		// If the currently active power is Blast Cannon then execute this section
		if(powerBlastCannon)
		{
			// If the entity is a sawedoff shotgun then excute this section
			if(StrEqual(ClassName, "weapon_sawedoff", false))
			{
				return Plugin_Continue;
			}
		}

		// If the currently active power is Deagle Headshot then execute this section
		if(powerDeagleHeadshot)
		{
			// If the entity is a deagle then excute this section
			if(StrEqual(ClassName, "weapon_deagle", false))
			{
				return Plugin_Continue;
			}
		}

		// If the currently active power is Hammer Time then execute this section
		if(powerHammerTime)
		{
			// If the entity is a hammer then excute this section
			if(StrEqual(ClassName, "weapon_melee", false))
			{
				EquipPlayerWeapon(client, weapon);

				return Plugin_Continue;
			}
		}
	}

	// If the weapon's entity name is the same as weapon_knife or weapon_healthshot then execute this section
	if(StrEqual(ClassName, "weapon_knife", false) || StrEqual(ClassName, "weapon_healthshot", false))
	{
		return Plugin_Continue;
	}

	// If the sound is not already precached then execute this section
	if(!IsSoundPrecached("kingmod/sfx_restrictedweapon.mp3"))
	{	
		// Precaches the sound file
		PrecacheSound("kingmod/sfx_restrictedweapon.mp3", true);
	}

	// Performs a clientcommand to play a sound only the clint can hear
	ClientCommand(client, "play */kingmod/sfx_restrictedweapon.mp3");

	// Changes the state of displayRestrictionHud[client] to true
	displayRestrictionHud[client] = true;

	// Calls upon the Timer_UpdateTeamScoreHud function to display the restriction message
	CreateTimer(0.0, Timer_UpdateTeamScoreHud, _, TIMER_FLAG_NO_MAPCHANGE);

	// After 3.0 seconds changes the restriction hud back to the score hud
	CreateTimer(3.0, Timer_DisableRestrictionHud , client, TIMER_FLAG_NO_MAPCHANGE);

	// Kills the weapon entity, removing it from the game
	AcceptEntityInput(weapon, "Kill");

	return Plugin_Handled;
}


// This happens when a player has picked up a weapon
public Action OnWeaponEquip(int client, int weapon)
{
	// If the weapon that was picked up our entity criteria of validation then execute this section
	if(!IsValidEntity(weapon))
	{
		return Plugin_Continue;
	}

	// Creates a variable called ClassName which we will store the weapon entity's name within
	char ClassName[64];

	// Obtains the classname of the weapon entity and store it within our ClassName variable
	GetEntityClassname(weapon, ClassName, sizeof(ClassName));

	// If the weapon's entity name is the weapon_healthshot then execute this section
	if(StrEqual(ClassName, "weapon_healthshot", false))
	{
		// Obtains the entity's model scale and store it within our modelScale variable
		float modelScale = GetEntPropFloat(weapon, Prop_Send, "m_flModelScale");

		// If the entity's model scale is anything other than 1.0 then execute this section
		if(modelScale != 1.0)
		{
			// Kills the weapon entity, removing it from the game
			AcceptEntityInput(weapon, "Kill");

			// Gives the client the specified weapon
			GivePlayerItem(client, "weapon_healthshot");
		}
	}

	return Plugin_Continue;
}


// This happens when a player changes weapon
public Action OnWeaponCanSwitchTo(int client, int weapon)
{
	// If the weapon that was picked up our entity criteria of validation then execute this section
	if(!IsValidEntity(weapon))
	{
		return Plugin_Continue;
	}

	// If the player is currently injecting a healthshot then execute this section 
	if(!injectingHealthshot[client])
	{
		return Plugin_Continue;
	}

	// If the player is has not recently received a message regarding weapon swapping being blockd then execute this section 
	if(!cooldownWeaponSwapMessage[client])
	{
		// Changes the player's cooldownWeaponSwapMessage state to true
		cooldownWeaponSwapMessage[client] = true;

		PrintToChat(client, "KingMod You cannot change weapon once you have begun the injection procss");

		// Removes the cooldown for announcing messages regarding the blocking of weapons
		CreateTimer(1.0, Timer_RemoveCooldownWeaponSwapMessage, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	// Creates a variable called ClassName which we will store the weapon entity's name within
	char className[64];

	// Obtains the classname of the weapon entity and store it within our ClassName variable
	GetEntityClassname(weapon, className, sizeof(className));

	// If the weapon's entity name is weapon_healthshot then execute this section
	if(StrEqual(className, "weapon_healthshot", false))
	{
		return Plugin_Continue;
	}

	return Plugin_Handled;
}


// This happens when the player takes damage but still remains alive
public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	// If the victim does not meet our validation criteria then execute this section
	if(!IsValidClient(victim))
	{
		return Plugin_Continue;
	}

	// If the attacker does meet our validation criteria then execute this section
	if(IsValidClient(attacker))
	{
		return Plugin_Continue;
	}

	// Creates a variable which we will use to store data within
	char className[64];

	// Obtains the classname of the attacker entity and store it within our className variable
	GetEntityClassname(attacker, className, sizeof(className));

	// If the classname is env_gunfire then execute this section
	if(!StrEqual(className, "env_gunfire"))
	{
		return Plugin_Continue;
	}

	// Changes the damage dealt by the dronegun's attacks to 65% of the normal damage
	damage = (damage / 100) * 65;

	return Plugin_Changed;
}


// This happens when the plugin is loaded
public Action SoundHookSentryGuns(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	// If the entity meets our entity criteria of validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Creates a variable which we will use to store data within
	char className[64];

	// Obtains the classname of the entity and store it within our className variable
	GetEntityClassname(entity, className, sizeof(className));
	
	// If the entity's classname is anything else than dronegun then execute this section
	if(!StrEqual(className, "dronegun", false))
	{
		return Plugin_Continue;
	}

	// Changes the volume of the dronegun to (12% default) of the normal volume
	volume = (volume / 100) * cvar_SentryGunVolumePercentage;
	
	return Plugin_Changed;
}



////////////////
// - Events - //
////////////////


// This happens when a player spawns
public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	// Obtains the client's userid and converts it to an index and store it within our client variable
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Change's the client's model, increases their health, reduces their speed and applies a screen overlay
	PowerZombieApocalypseSpawn(client);

	// Changes the client's health to 1 if the riot power is active
	PowerRiotChangePlayerHealth(client);

	// Grants the player increased movement speed if the movement speed power is active
	PowerMovementSpeedSpawn(client);

	// Strips the client of all their weapons
	StripPlayerOfWeapons(client);

	// Gives the client the specified weapon
	GivePlayerItem(client, "weapon_knife");

	// Provides the player with invulnerability temporarily to protect the player
	GrantPlayerSpawnProtection(client);

	// Disables CS:GO's built-in minimap / radar hud element if it is specified in the keyvalue file
	CreateTimer(0.0, Timer_HudElementMinimap, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}


// This happens when a player dies
public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	// Obtains the client's userid and converts it to an index and store it within our client variable
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Removes the cooldown that is being set when the client is buried, if the Hammer Time power is active
	PowerHammerTimeDeath(client);

	// Removes the zombie screen overlay if the zombie apocalypse power is active
	ZombieApocalypseOnDeath(client);

	// Resets the babonic plague infection of the player back to 0 if the currently active power is babonic plague
	ResetBabonicPlagueOnDeath(client);

	// Resets the client's inferno stacks back to 0 if the currently active power is napalm 
	ResetNapalmStacks(client);

	// Creates a chicken where the player was killed if the currently active power is Doomm Chickens
	SpawnDoomChicken(client);

	// Gives the client a (33% default) chance to drop a healthshot where they stood upon dying
	DropHealthShot(client);

	// Calls upon the Timer_RespawnPlayer function after (1.5 default) seconds
	CreateTimer(cvar_RespawnTime, Timer_RespawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);

	// If the client is not a controlled bot then execute this section
	if(isPlayerControllingBot[client])
	{
		// Attempts to respawn all bots that are currently dead
		RespawnOvertakenBots();
	}

	// If the game is not currently in progress then execute this section	
	if(!gameInProgress)
	{
		return Plugin_Continue;
	}

	// Obtains the attacker's userid and converts it to an index and store it within our attacker variable
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	// If the attacker is the same as the victim (suicide) then execute this section or if the attacker is the world like for fall damage etc.
	if((attacker == client) | (attacker == 0))
	{
		// If the client is not the current king then execute this section
		if(!isPlayerKing[client])
		{
			return Plugin_Continue;
		}

		// Changes the index of the king back to 0
		kingIndex = 0;

		// Changes the killed player's king status to false
		isPlayerKing[client] = false;

		// Removes all of the bumpmine projectile entities from the map
		RemoveAllBumpMines();

		// Extinguishes the flames of all clients currently on fire if the current power is napalm 
		RemoveNapalmFromVictims();

		// Resets all power spcific variables back to their default values 
		ResetPreviousPower();

		// Removes the screen overlay if the client is the king and impregnable armor is currently active
		RemoveScreenOverlay(client);

		// Resets the movement speed of all the players if the current power is movement speed 
		RemovePowerMovementSpeed();

		// Removes any currently present king crowns from the game
		RemoveCrownEntity();

		// Strips the player of the clantag which indicates that the player is the current king 
		RemoveClanTag(client);

		PrintToChat(client, "Debug: You lost your kingship because you committed suicide");

		// Changes the indicator of which team the King is currently on be none
		kingIsOnTeam = 0;

		// Changes the kingName variable's value to just be None
		kingName = "None";

		return Plugin_Continue;
	}

	// If the attacker does not meet our validation criteria then execute this section
	if(!IsValidClient(attacker))
	{
		return Plugin_Continue;
	}

	// If there is the king currently then execute this section
	if(IsThereACurrentKing())
	{
		// If the client is the current king then execute this section
		if(isPlayerKing[client])
		{
			// Changes the index of the king to that of the value stored within the attacker variable
			kingIndex = attacker;

			// Changes the killed player's king status to false
			isPlayerKing[client] = false;
			PrintToChat(client, "Debug: You lost your kingship as you were killed");

			// Changes the attacking player's king status to true
			isPlayerKing[attacker] = true;
			PrintToChat(attacker, "Debug: You stole the king title from the enemy that died");

			// Removes any currently present king crowns from the game
			RemoveCrownEntity();

			// Strips the player of the clantag which indicates that the player is the current king 
			RemoveClanTag(client);

			// Attaches a crown model on top of the attacker's head
			GiveCrown(attacker);

			// Assigsn a clantag to the player which indicates that the player is the current king
			AssignClanTag(attacker);

			// Changes the health of the player to (200 default)
			SetEntProp(attacker, Prop_Send, "m_iHealth", cvar_KingHealth, 1);

			// Removes all of the bumpmine projectile entities from the map
			RemoveAllBumpMines();

			// Extinguishes the flames of all clients currently on fire if the current power is napalm 
			RemoveNapalmFromVictims();

			// Decides which powers can be chosen, and picks a power from the list for the new king
			ChooseKingPower(attacker);

			// Removes the screen overlay if the client is the king and impregnable armor is currently active
			RemoveScreenOverlay(client);

			// Resets the movement speed of all the players if the current power is movement speed 
			RemovePowerMovementSpeed();

			// Strips the client of all their weapons
			StripPlayerOfWeapons(attacker);

			// After 0.1 seconds gives the player a golden knife
			CreateTimer(0.1, Timer_GiveGoldenKnife, attacker, TIMER_FLAG_NO_MAPCHANGE);

			// If the map has been configured to have platform support then execute this section
			if(mapHasPlatformSupport)
			{
				// Teleports the client to the specified location of the map's platform
				TeleportEntity(attacker, platformLocation, NULL_VECTOR, NULL_VECTOR);

				// Changes the movement speed of the player to 0.0 essentially freezing all player movement aside from camera turning
				SetEntPropFloat(attacker, Prop_Data, "m_flLaggedMovementValue", 0.0);

				// After (3.0 default) seconds has passed the king will have normal movement once again
				CreateTimer(cvar_ImmobilityTime, Timer_UnfreezeKing, attacker, TIMER_FLAG_NO_MAPCHANGE);
			}

			// Creates visual effects at the location of the new king
			DisplayVisualEffects(attacker);

			// Obtains the name of the attacker and store it within the kingName variable
			GetClientName(attacker, kingName, sizeof(kingName));

			// If the attacker is on the Terrorist team then execute this section
			if(GetClientTeam(attacker) == 2)
			{
				// Changes the indicator of which team the King is currently on to the Terrorist team
				kingIsOnTeam = 2;

				// Adds the value of cvar_PointsKingKill to the pointCounterT variable's value
				pointCounterT += cvar_PointsKingKill;
			}

			// If the attacker is on the Coutner-Terrorist team then execute this section
			if(GetClientTeam(attacker) == 3)
			{
				// Changes the indicator of which team the King is currently on to the Counter-Terrorist team
				kingIsOnTeam = 3;

				// Adds the value of cvar_PointsKingKill to the pointCounterCT variable's value
				pointCounterCT += cvar_PointsKingKill;
			}

			return Plugin_Continue;
		}

		// If the client is not the current king then execute this section
		else
		{
			// If the attacker is on the Terrorist team then execute this section
			if(GetClientTeam(attacker) == 2)
			{
				if(kingIsOnTeam == 2)
				{
					// Adds the value of cvar_PointsNormalKill to the pointCounterT variable's value
					pointCounterT += cvar_PointsNormalKill;
				}
			}

			// If the attacker is on the Coutner-Terrorist team then execute this section
			if(GetClientTeam(attacker) == 3)
			{
				if(kingIsOnTeam == 3)
				{
					// Adds the value of cvar_PointsNormalKill to the pointCounterCT variable's value
					pointCounterCT += cvar_PointsNormalKill;
				}
			}

			return Plugin_Continue;
		}
	}

	// Changes the index of the king to that of the value stored within the attacker variable
	kingIndex = attacker;

	// Changes the attacking player's king status to true
	isPlayerKing[attacker] = true;
	PrintToChat(attacker, "Debug: You became the new king");

	// Removes any currently present king crowns from the game
	RemoveCrownEntity();

	// Strips the player of the clantag which indicates that the player is the current king 
	RemoveClanTag(client);

	// Attaches a crown model on top of the attacker's head
	GiveCrown(attacker);

	// Changes the health of the player to (200 default)
	SetEntProp(attacker, Prop_Send, "m_iHealth", cvar_KingHealth, 1);

	// Removes all of the bumpmine projectile entities from the map
	RemoveAllBumpMines();

	// Extinguishes the flames of all clients currently on fire if the current power is napalm 
	RemoveNapalmFromVictims();

	// Decides which powers can be chosen, and picks a power from the list for the new king
	ChooseKingPower(attacker);

	// Removes the screen overlay if the client is the king and impregnable armor is currently active
	RemoveScreenOverlay(client);

	// Resets the movement speed of all the players if the current power is movement speed 
	RemovePowerMovementSpeed();

	// Strips the client of all their weapons
	StripPlayerOfWeapons(attacker);

	// After 0.1 seconds gives the player a golden knife
	CreateTimer(0.1, Timer_GiveGoldenKnife, attacker, TIMER_FLAG_NO_MAPCHANGE);

	// If the map has been configured to have platform support then execute this section
	if(mapHasPlatformSupport)
	{
		// Teleports the client to the specified location of the map's platform
		TeleportEntity(attacker, platformLocation, NULL_VECTOR, NULL_VECTOR);

		// Changes the movement speed of the player to 0.0 essentially freezing all player movement aside from camera turning
		SetEntPropFloat(attacker, Prop_Data, "m_flLaggedMovementValue", 0.0);

		// After (3.0 default) seconds has passed the king will have normal movement once again
		CreateTimer(cvar_ImmobilityTime, Timer_UnfreezeKing, attacker, TIMER_FLAG_NO_MAPCHANGE);
	}

	// Assigsn a clantag to the player which indicates that the player is the current king
	AssignClanTag(attacker);

	// Creates visual effects at the location of the new king
	DisplayVisualEffects(attacker);

	// Obtains the name of the attacker and store it within the kingName variable
	GetClientName(attacker, kingName, sizeof(kingName));

	// If the attacker is on the Terrorist team then execute this section
	if(GetClientTeam(attacker) == 2)
	{
		// Changes the indicator of which team the King is currently on to the Terrorist team
		kingIsOnTeam = 2;
	}

	// If the attacker is on the Coutner-Terrorist team then execute this section
	if(GetClientTeam(attacker) == 3)
	{
		// Changes the indicator of which team the King is currently on to the Counter-Terrorist team
		kingIsOnTeam = 3;
	}

	return Plugin_Continue;
}


// This happens when the round starts 
public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	// Changes the gameInProgress state to true
	gameInProgress = true;

	// Creates a hostage rescue zone if the powerchooser and shield power is enabled, to let players use the shield
	createHostageZone();

	// Removes any power related effects that may elsewise be able to transfer over from the previous round
	RemoveKingPowerEffects();

	// Changes all power related variables from active to inactive
	ResetPreviousPower();

	// Changes the health of any sentry gun placed on the map
	ChangeSentryGunHealth();

	// Checks if the current map has been configured to have platform support included 
	CheckForPlatformSupport();

	// Changes the index of the king back to 0
	kingIndex = 0;

	// Changes the indicator of which team the King is currently on to be on no team
	kingIsOnTeam = 0;

	// Changes the kingName variable's value to just be None
	kingName = "None";
	
	// Resets the terrorists' team score back to 0 
	pointCounterT = 0;

	// Resets the counter-terrorists' team score back to 0
	pointCounterCT = 0;

	PrintToChatAll("Debug: A new round has started, kill an enemy to become the first King");

	// Creates a variable with the value of the terrorist and counter-terrorist teams' current score added together
	int initialRound = GetTeamScore(2) + GetTeamScore(3);

	// Creates a variable secondsToRoundEnd that stores the value of the round's duration + freeze time minus -0.25 seconds
	float secondsToRoundEnd = (GetConVarFloat(FindConVar("mp_roundtime")) * 60.0) + GetConVarFloat(FindConVar("mp_freezetime")) - 0.25;

	// After secondsToRoundEnd seconds has passed then call upon the Timer_EndCurrentRound function to end the current round
	CreateTimer(secondsToRoundEnd, Timer_EndCurrentRound, initialRound, TIMER_FLAG_NO_MAPCHANGE);

	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// If the client is not a bot then execute this section
		if(!IsFakeClient(client))
		{
			continue;
		}

		// Changes the isPlayerControllingBot to false
		isPlayerControllingBot[client] = false;
	}

	return Plugin_Continue;
}


// This happens when the round ends
public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// If the client is the king then execute this section
		if(isPlayerKing[client])
		{
			// Changes the killed player's king status to false
			isPlayerKing[client] = false;
		}

		// Strips the player of the clantag which indicates that the player is the current king 
		RemoveClanTag(client);

		// If the Terrorist team have more points than the Counter-Terrorist team then execute this section
		if(pointCounterT > pointCounterCT)
		{
			// Sends a colored multi-language message to everyone in the chat area
			// CPrintToChat(client, "%t", "Terrorists Won", pointCounterT, pointCounterCT);
			PrintToChat(client, "T Won - T: %i CT: %i", pointCounterT, pointCounterCT);

		}

		// If the Terrorist team have less points than the Counter-Terrorist team then execute this section
		else if(pointCounterT < pointCounterCT)
		{
			// Sends a colored multi-language message to everyone in the chat area
			// CPrintToChat(client, "%t", "Counter-Terrorists Won", pointCounterT, pointCounterCT);
			PrintToChat(client, "CT Won - T: %i CT: %i", pointCounterT, pointCounterCT);
		}

		// If the Terrorist team have the same amount of points as the Counter-Terrorist team then execute this section
		else
		{
			// Sends a colored multi-language message to everyone in the chat area
			// CPrintToChat(client, "%t", "Round Draw", pointCounterT, pointCounterCT);
			PrintToChat(client, "Round Draw - T: %i CT: %i", pointCounterT, pointCounterCT);
		}
	}

	return Plugin_Continue;
}


// This happens every time a player changes team (NOTE: This is required in order to make late-joining bots respawn)
public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	// Obtains the client's userid and converts it to an index and store it within our client variable
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the client is not a bot then execute this section
	if(!IsFakeClient(client))
	{
		return Plugin_Continue;
	}

	// If the client is alive then execute this section
	if(IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	// Obtains the team which the player changed to
	int team = GetEventInt(event, "team");

	// If the team is the observer or spectator team execute this section
	if(team <= 1)
	{
		return Plugin_Continue;
	}

	// Calls upon the Timer_RespawnPlayer function after (1.5 default) seconds
	CreateTimer(cvar_RespawnTime, Timer_RespawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}


// This happens when a player takes or would take damage from falling
public Action Event_PlayerFalldamage(Handle event, const char[] name, bool dontBroadcast)
{
	// If the cvar_KingPowerChooser is not enabled then execute this section
	if(!cvar_KingPowerChooser)
	{
		return Plugin_Continue;
	}

	// If the currently active power is not leg crushing bumpmines then execute this section
	if(!powerLegCrushingBumpmines)
	{
		return Plugin_Continue;
	}

	// Obtains the client's userid and converts it to an index and store it within our client variable
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the client is on the same team as the king then execute this section
 	if(GetClientTeam(client) == kingIsOnTeam)
	{
		return Plugin_Continue;
	}

	// Obtains the damage taken from falling and store it within the fallDamage variable 
	int fallDamage = RoundToCeil(GetEventFloat(event, "damage"));

	// Inflicts the value of fallDamage as damage to the client from the king
	DealDamageToClient(client, kingIndex, fallDamage, "weapon_bumpmine");

	return Plugin_Continue;
}


// This happens when a player takes damage
public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	// Obtains the client's userid and converts it to an index and store it within our client variable
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Makes the king recover óver a few seconds if the king is brought below 75 health
	KingRecovery(client);

	return Plugin_Continue;
}


// This happens when a player uses the left attack with their knife or weapon
public Action Event_WeaponFire(Handle event, const char[] name, bool dontBroadcast)
{
	// Obtains the client's userid and converts it to an index and store it within our client variable
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Grants a random amount of health when using the healthshot
	InjectHealthshot(client); 

	// Gives the player high explosive grenades after having thrown their previous one
	WeaponFireStickyGrenades(client);

	// Gives the player a flashbang after having thrown their previous one
	WeaponFireCarpetBombingFlashbang(client);

	// Gives the player a molotov after having thrown their previous one
	WeaponFireNapalm(client);

	// Replenishes the clip and creates a laser beam from the player to where the bullet hit the wall
	WeaponFireCz75a(client);

	// If the player is no longer spawnprotected then execute this section
	if(!isPlayerProtected[client])
	{
		return Plugin_Continue;
	}

	// Removes the spawn protection from the client
	RemoveSpawnProtection(client);

	return Plugin_Continue;
}



///////////////////////////
// - Regular Functions - //
///////////////////////////


// This happens when the plugin is unloaded
public void RemoveAllScreenOverlays()
{
	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// If the client is a bot then execute this section
		if(IsFakeClient(client))
		{
			continue;
		}

		// Removes any active screen overlays from the client
		RemoveScreenOverlay(client);
	}
}


// This happens when the plugin is loaded
public void LateLoadSupport()
{
	// Changes the kingName variable's value to just be None
	kingName = "None";

	PrintToChatAll("King Mod has been loaded. ");
	PrintToChatAll("A new round will soon commence.");

	// Calls upon the Timer_TerminateRound function after 3.0 seconds
	CreateTimer(3.0, Timer_TerminateRound, _, TIMER_FLAG_NO_MAPCHANGE);

	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// Renders the player unable to move or perform any movement related actions
		SetEntityFlags(client, GetEntityFlags(client) | FL_FROZEN);

		// Adds a hook to the client which will let us track when the player is eligible to pick up a weapon
		SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);

		// Adds a hook to the client which will let us track when the player picks up a weapon
		SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);

		// Adds a hook to the client which will let us track when the player changes weapon
		SDKHook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanSwitchTo);

		// Adds a hook to the client which will let us track when the player takes damage
		SDKHook(client, SDKHook_OnTakeDamage, OnDamageTaken);

		// Adds a hook to the client which will let us track when the client uses their weapon's scope
		SDKHook(client, SDKHook_PreThink, OnPreThink);

		// Adds a hook to the client which will let us track when the client takes damage and remains alive
		SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive); 

		// Adds a hook to the client which will let us track when the player switches weapon
		SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	}
}


// This happens when the plugin is loaded
public void PreventRestartGameUsage()
{
	// Obtains the value of the mp_restartgame convar and store it within the variable named restartGame
	Handle restartGame = FindConVar("mp_restartgame");

	// Adds a hook to our mp_restartgame convar to keep track of any possible changes 
	HookConVarChange(restartGame, RestartGameConvarChanged);
}


// This happens when changes to the mp_restartgame convar are attempted
public void RestartGameConvarChanged(Handle cvar, const char[] oldVal, const char[] newVal)
{
	// If the new convar value is anything else than 0 then execute this section
	if(!StrEqual(newVal, "0"))
	{
		// Creates a convar named restartGame with the value similar to that of mp_restartgame
		ConVar restartGame = FindConVar("mp_restartgame");

		// Changes the value of our mp_restartgame back to 0
		restartGame.IntValue = 0;

		PrintToChatAll("King Mod: Please try not to use mp_restartgame, change the map instead.");
	}
}


// This happens every time a new round starts
public void ChangeSentryGunHealth()
{
	// Loops through all entities that are currently in the game
	for (int entity = MaxClients + 1; entity <= GetMaxEntities(); entity++)
	{
		// If the entity does not meet our criteria of validation then execute this section
		if(!IsValidEntity(entity))
		{
			continue;
		}

		// Creates a variable which we will use to store data within
		char className[64];

		// Obtains the entity's class name and store it within our className variable
		GetEntityClassname(entity, className, sizeof(className));

		// If the entity is a dronegun then execute this section
		if(!StrEqual(className, "dronegun"))
		{	
			continue;
		}

		// Changes the sentry gun's health
		SetEntityHealth(entity, cvar_SentryGunHealth);
	}
}


// This function is called upon whenever a new round starts or a new map is loaded
void CheckForPlatformSupport()
{
	// Sets the mapHasMinimapHidden variable to 0
	mapHasMinimapHidden = 0;

	// Sets the coordinate location of the platform to an impossible value
	platformLocation[0] = -32769.0;
	platformLocation[1] = -32769.0;
	platformLocation[2] = -32769.0;

	// Creates a variable named CurerntMapName
	char CurrentMapName[64];

	// Obtains the name of the current map and st ore it within our CurrentMapName variable
	GetCurrentMap(CurrentMapName, sizeof(CurrentMapName));

	// Creates a KeyValue structure which we store within our handle named kv
	Handle kv = CreateKeyValues("platforms");

	// Defines the destination and used file of our located keyvalue tree 
	FileToKeyValues(kv, "addons/sourcemod/configs/KingMod/platforms.txt");

	// If there isn't a first sub key then execute this section
	if(!KvGotoFirstSubKey(kv))
	{
		return;
	}

	// Loops through all the sub keys
	do
	{
		// Creates a variable named KeyValueSection which we will use to store data within
		char KeyValueSection[32];

		// Creates a variable named KeyValueMapName which we will use to store data within
		char KeyValueMapName[PLATFORM_MAX_PATH];

		// Obtains the name of the KeyValue trees section and store it within the kv handle
		KvGetSectionName(kv, KeyValueSection, sizeof(KeyValueSection));

		// Obtains the string value that is stored within our sub key value "map" and store it within our variable named KeyValueMapName
		KvGetString(kv, "map", KeyValueMapName, sizeof(KeyValueMapName));

		// If the current map contains the same name as the data that was stored within our KeyValueMapName variable then execute this section
		if(StrContains(CurrentMapName, KeyValueMapName, false) != -1)
		{
			// Obtains the values stored within our keyvalues, x_coord, y_coord and z_coord and store them within our variables KeyValueX, KeyValueY, and KeyValueZ respectively
			platformLocation[0] = KvGetFloat(kv, "location_x");
			platformLocation[1] = KvGetFloat(kv, "location_y");
			platformLocation[2] = KvGetFloat(kv, "location_z");

			// Sets the mapHasMinimapHidden variable to whatever may be defined in the key value file
			mapHasMinimapHidden = KvGetNum(kv, "hide_minimap");

			// Adds + 2.0 game units to the Z-axis
			platformLocation[2] += 2.0;
		}
	}

	while (KvGotoNextKey(kv));

	// If the coordinates used are one of the three default out of bounds map coordinates then execute this section
	if(platformLocation[0] == -32769.0 || platformLocation[1] == -32769.0 || platformLocation[2] == -32769.0)
	{
		// Changes the mapHasPlatformSupport state to be false
		mapHasPlatformSupport = false;

		// Writes a message to the server's console informing about the possible issue at hand
		PrintToServer("=======================================================================================================");
		PrintToServer("[King Mod Warning]:");
		PrintToServer("   %s map is missing a proper platform coordinate specification", CurrentMapName);
		PrintToServer("   to fix this add a location by editing addons/sourcemod/configs/KingMod/platforms.txt");
		PrintToServer("   ");
		PrintToServer("=======================================================================================================");
	}

	// If the coordinates used are not one of the three default out of bounds map coordinates then execute this section
	else
	{
		// Changes the mapHasPlatformSupport state to be true
		mapHasPlatformSupport = true;
	}

	// Closes our kv handle once we are done using it
	CloseHandle(kv);
}


// This happens when a new map is loaded
public void HudElementMoney()
{
	// If the cvar_HideMoneyHud is set to true then execute this section
	if(cvar_HideMoneyHud)
	{
		// Changes the two server variables in order to remove the money hud element and money related messages
		SetConVar("mp_playercashawards", "0");
		SetConVar("mp_teamcashawards", "0");
	}
}


// This happens when we wish to change a server variable convar
public void SetConVar(const char[] ConvarName, const char[] ConvarValue)
{
	// Finds an existing convar with the specified name and store it within the ServerVariable name 
	ConVar ServerVariable = FindConVar(ConvarName);

	// If the convar exists then execute this section
	if(ServerVariable != null)
	{
		// Changes the value of the convar to the value specified in the ConvarValue variable
		ServerVariable.SetString(ConvarValue, true);
	}
}


// This happens once all post authorizations have been performed and the client is fully in-game
public void AutoJoinTeam(int client)
{
	// Creates a variable secondsToRoundEnd that stores the value of the round's duration + freeze time minus -0.25 seconds
	float forcedPickWaitTime = GetConVarFloat(FindConVar("mp_force_pick_time"));

	// If the value of forcedPickWaitTime is 0.00 then execute this section
	if(forcedPickWaitTime <= 1.0)
	{
		SetConVar("mp_force_pick_time", "1");

		// Sets the value of our forcedPickWaitTime variable to 0.5
		forcedPickWaitTime = 0.5;
	}

	// If the value of forcedPickWaitTime is above 1.0 then execute this section
	else
	{
		// Subtracts 0.5 seconds from the value of forcedPickWaitTime
		forcedPickWaitTime -= 0.5;
	}

	// Calls upon the Timer_AutoJoinTeam function after (1.5 default) seconds
	CreateTimer(forcedPickWaitTime, Timer_AutoJoinTeam, client, TIMER_FLAG_NO_MAPCHANGE);
}


// This happens when someone stops being the current king
public Action RemoveClanTag(int client)
{
	// If the client is not a bot then execute this section
	if(!IsFakeClient(client))
	{
		// Creates a variable which we will use to store data within
		char TempClanTag[14];

		// Obtains the player's current clantag and store it within the tempClanTag variable
		CS_GetClientClanTag(client, TempClanTag, sizeof(TempClanTag));
		
		// If the player's current clantag is [ - King - ] then execute this section
		if(StrEqual(TempClanTag, "[ - King - ] ", false))
		{
			// Changes the player's tag to the previously saved clan tag
			CS_SetClientClanTag(client, PlayerClanTag[client]);
		}
	}
	else
	{
		// Changes the player's clantag to [ - King - ]
		CS_SetClientClanTag(client, "");
	}

	return Plugin_Continue;
}


// This happens when someone becommes the king
public void AssignClanTag(int client)
{
	// If the client is not a bot then execute this section
	if(!IsFakeClient(client))
	{
		// Creates a variable which we will use to store data within
		char TempClanTag[14];

		// Obtains the player's current clantag and store it within the tempClanTag variable
		CS_GetClientClanTag(client, TempClanTag, sizeof(TempClanTag));
		
		// If the player's current clantag is not [ - King - ] then execute this section
		if(!StrEqual(TempClanTag, "[ - King - ] ", false))
		{
			// Sets playerClanTag[client] to store the player's current clantag for later
			CS_GetClientClanTag(client, PlayerClanTag[client], sizeof(PlayerClanTag));
		}
	}

	// Changes the player's clantag to [ - King - ]
	CS_SetClientClanTag(client, "[ - King - ] ");
}


// This happens when a king dies or disconnects from the game
public void RemoveCrownEntity()
{
	// Creates a variable to store our data within 
	int entity = INVALID_ENT_REFERENCE;

	// Loops through the entities and execute this section if the entity has the classname prop_dynamic_override
	while ((entity = FindEntityByClassname(entity, "prop_dynamic_override")) != INVALID_ENT_REFERENCE)
	{
		// If the entity does not meet our criteria validation then execute this section
		if(!IsValidEntity(entity))
		{
			continue;
		}

		// Creates a variable which we will use to store our data within
		char entityName[128];

		// Obtains the name of the entity and store it within the our entityName variable
		GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));

		// If the name of the entity is not KingName then execute this section
		if(!StrEqual(entityName, "KingCrown", false))
		{
			continue;
		}

		// Removes the entity from the game
		AcceptEntityInput(entity, "Kill");

		break;
	}
}


// This happens when a new king has been chosen
public void GiveCrown(int client)
{
	// If the model is not precached then execute this section
	if(!IsModelPrecached("models/props/crown.mdl"))
	{
		// Precaches the model
		PrecacheModel("models/props/crown.mdl");
	}

	// Creates a variable named PropEntity to store our prop_dynamic_override unique id within 
 	int PropEntity = CreateEntityByName("prop_dynamic_override");
 	
 	// Sets the targetname for our crown to be our formatted EntityName
	DispatchKeyValue(PropEntity, "targetname", "KingCrown");

	// Changes the model of the prop to a crown
	DispatchKeyValue(PropEntity, "model", "models/props/crown.mdl");

	// Turns off receiving shadows for the model
	DispatchKeyValue(PropEntity, "disablereceiveshadows", "1");

	// Turns off the model's own shadows 
	DispatchKeyValue(PropEntity, "disableshadows", "1");
	
	// Changes the solidity of the model to be unsolid
	DispatchKeyValue(PropEntity, "solid", "0");
	
	// Changes the spawn flags of the model
	DispatchKeyValue(PropEntity, "spawnflags", "256");

	// Changes the collisiongroup to that of the ones used by weapons in CS:GO as well
	SetEntProp(PropEntity, Prop_Send, "m_CollisionGroup", 11);
	
	// Spawns the crown model in to the world
	DispatchSpawn(PropEntity);

	// Creates a variable which we will use to store our data within
	float modelAngles[3];

	// Creates a variable which we will use to store our data within
	float modelPosition[3];

	// Modifies the placement of the crown model relative to the player's x-coordinate position
	modelPosition[0] = 5.50;

	// Modifies the placement of the crown model relative to the player's z-coordinate position
	modelPosition[2] = 53.25;

	// Changes the variantstring to !activator
	SetVariantString("!activator");
	
	// Changes the parent of the model to be that of the player who just became the new king
	AcceptEntityInput(PropEntity, "SetParent", client, PropEntity, 0);
	
	// Teleports the crown model to the previously specified coordinates relative to the player
	TeleportEntity(PropEntity, modelPosition, modelAngles, NULL_VECTOR);

	// Sets the EntityOwner variable to that of the client's index
	EntityOwner[PropEntity] = client;

	// Hooks on to the PropEntity and modifies how it is transmitted to clients in the game
	SDKHook(PropEntity, SDKHook_SetTransmit, Transmit_HideCrown);
}


// This happens once every game tick
public Action Transmit_HideCrown(int entity, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the client is not a bot then execute this section
	if(IsFakeClient(client))
	{
		return Plugin_Continue;
	}

	// If the client is the entity owner then execute this section
	if(client == EntityOwner[entity])
	{
		return Plugin_Handled;
	}

	// If the player is in observermode and seeing in first person then execute this section
	if(GetEntProp(client, Prop_Send, "m_iObserverMode") == 4)
	{
		// If the client observed is the owner of the crown entity thn execute this section
		if(GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") == EntityOwner[entity])
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}


// This happens when a player spawns and when a player becomes the new king
public void StripPlayerOfWeapons(int client)
{
	// Loops through the five weapon holding
	for(int weaponCarrySlot = 0; weaponCarrySlot < 4 ; weaponCarrySlot++)
	{
		// Loops through all of the weapon numbers
		for(int WeaponNumber = 0; WeaponNumber < 24; WeaponNumber++)
		{
			// Obtains the weapon in the weapon slot and store it within the WeaponSlotNumber variable
			int WeaponSlotNumber = GetPlayerWeaponSlot(client, WeaponNumber);

			// IF the WeaponSlotNumber is not a valid edict then execute this setting 
			if(!IsValidEdict(WeaponSlotNumber))
			{
				continue;
			}

			// If the entity does not meet our criteria validation then execute this section
			if(!IsValidEntity(WeaponSlotNumber))
			{
				continue;
			}

			// Removes the player's item from the client
			RemovePlayerItem(client, WeaponSlotNumber);

			// Deletes the entity from the game
			AcceptEntityInput(WeaponSlotNumber, "Kill");
		}
	}
}


// This happens when a player spawns
public Action GrantPlayerSpawnProtection(int client)
{
	// Changes the SpawnProtection to true
	isPlayerProtected[client] = true;

	// Makes the client unable to take damage by enabling God-Mode
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);

	// Changes the rendering mode of the player
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);

	// If the client is on the terrorist team then execute this section
	if(GetClientTeam(client) == 2)
	{
		// Changes the client's color to red
		SetEntityRenderColor(client, 200, 0, 0, 255);
	}

	// If the client is on the counter-terrorist team then execute this section
	else if(GetClientTeam(client) == 3)
	{
		// Changes the client's color to blue
		SetEntityRenderColor(client, 0, 0, 215, 255);
	}

	// Adds +1 to the PlayerSpawnCount[client] variable
	PlayerSpawnCount[client]++;
	
	// Creates a datapack called pack which we will store our data within 
	DataPack pack = new DataPack();

	// Stores the client's index within our datapack
	pack.WriteCell(client);

	// Stores the PlayerSpawnCount variable within our datapack
	pack.WriteCell(PlayerSpawnCount[client]);

	// After (3.5 default) seconds remove the spawn protection from the player
	CreateTimer(cvar_SpawnProtectionDuration, Timer_ExpireSpawnProtection, pack, TIMER_FLAG_NO_MAPCHANGE);
}


// This happens (3.5 default) seconds after a player spawns
public Action RemoveSpawnProtection(int client)
{
	// Changes the SpawnProtection status of the client to be turned off
	isPlayerProtected[client] = false;

	// Turns the player's God Mode off
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);

	// Changes the player's color to the default color 
	SetEntityRenderColor(client, 255, 255, 255, 255);
}


// This happens when a player fires his weapon
public Action InjectHealthshot(int client)
{
	// Obtains the name of the player's weapon and store it within our variable entity
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Creates a variable which we will use to store data within
	char className[64];

	// Obtains the entity's class name and store it within our className variable
	GetEntityClassname(entity, className, sizeof(className));

	// If the entity is not a healthshot then execute this section
	if(!StrEqual(className, "weapon_healthshot", false))
	{
		return Plugin_Continue;
	}

	// If the player is currently injecting a healthshot then execute this section 
	if(injectingHealthshot[client])
	{
		return Plugin_Continue;
	}

	// If the player's healthshot action is currently on cooldown then execute this section 
	if(cooldownHealthshot[client])
	{
		return Plugin_Continue;
	}

	// Changes the player's cooldownHealthshot state to true
	cooldownHealthshot[client] = true;

	// Changes the player's injectingHealthshot state to true
	injectingHealthshot[client] = true;

	// Calls our Timer_InjectionComplete function to alter the effect of health injections
	CreateTimer(0.55, Timer_InjectionComplete, client, TIMER_FLAG_NO_MAPCHANGE);

	// After 0.85 seconds calls our Timer_InjectHealthshot function to alter the effect of health injections
	CreateTimer(0.85, Timer_InjectHealthshot, client, TIMER_FLAG_NO_MAPCHANGE);

	// After 1.90 seconds lifts the healthshot action cooldown from the player allowing them to use another injection
	CreateTimer(1.90, Timer_CooldownHealthshotAction, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;	
}


// This function is called upon whenever a player is killed
public Action DropHealthShot(int client)
{
	// If the cvar_KingPowerChooser is enabled and either cvar_PowerRiot or cvar_PowerZombieApocalypse is enabled then execute this section
	if(cvar_KingPowerChooser && cvar_PowerRiot | cvar_PowerZombieApocalypse)
	{
		return Plugin_Continue;
	}

	// If the currently active power is riot or zombie apocalypse then execute this section
	if(powerRiot | powerZombieApocalypse)
	{
		return Plugin_Continue;
	}

	// If the randomly chosen number is larger than the value of the cvar_DropChance then execute this section
	if(cvar_DropChance <= GetRandomInt(1, 100))
	{
		return Plugin_Continue;
	}

	// Creates a variable to store our data within
	float playerLocation[3];

	// Creates a variable to store our data within
	float entityRotation[3];

	// Obtains the location of the client and store it within the playerLocation variable
	GetClientAbsOrigin(client, playerLocation);

	// Changes the obtained player location by +64 on the z-axis
	playerLocation[2] += 64;

	// Sets the entity's rotation to 90.0 around its' z-axis
	entityRotation[2] = 90.0;

	// Creates a healthshot and store it's index within our entity variable
	int entity = CreateEntityByName("weapon_healthshot");

	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Changes the size of the entity
	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 1.98);

	// Changes the color of the entity to a random predefined color
	SetRandomColor(entity);

	// Attaches a light_dynamic entity to the healthshot of a random predefined color
	SetRandomLightColor(entity);

	// Spawns the entity
	DispatchSpawn(entity);

	// Teleports the entity to the specified coordinates relative to the player and rotate it
	TeleportEntity(entity, playerLocation, entityRotation, NULL_VECTOR);

	// Calls our Timer_RemoveSpawnedHealthShotInjection function to remove any healthshots that hasn't been picked up within the last 5 seconds
	CreateTimer(cvar_HealthshotExpirationTime, Timer_RemoveHealthShot, entity, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}


// This happens when a player dies and drops a healthshot
public void SetRandomColor(int entity)
{
	// Picks a random number between 1 and 9 and store it within our randomColor variable
	int randomcolor = GetRandomInt(1, 9);

	// Creates a switch statement to manage outcomes depnding on the value of our randomVariable
	switch(randomcolor)
	{
		// If the randomcolor variable is 1 then execute this section
		case 1:
		{
			// Changes the color values of our colorRGB variable
			colorRGB[0] = 193;
			colorRGB[1] = 35;
			colorRGB[2] = 35;
		}

		// If the randomcolor variable is 2 then execute this section
		case 2:
		{
			// Changes the color values of our colorRGB variable
			colorRGB[0] = 19;
			colorRGB[1] = 226;
			colorRGB[2] = 14;
		}

		// If the randomcolor variable is 3 then execute this section
		case 3:
		{
			// Changes the color values of our colorRGB variable
			colorRGB[0] = 113;
			colorRGB[1] = 123;
			colorRGB[2] = 255;
		}

		// If the randomcolor variable is 4 then execute this section
		case 4:
		{
			// Changes the color values of our colorRGB variable
			colorRGB[0] = 254;
			colorRGB[1] = 234;
			colorRGB[2] = 122;
		}

		// If the randomcolor variable is 5 then execute this section
		case 5:
		{
			// Changes the color values of our colorRGB variable
			colorRGB[0] = 255;
			colorRGB[1] = 146;
			colorRGB[2] = 47;
		}

		// If the randomcolor variable is 6 then execute this section
		case 6:
		{
			// Changes the color values of our colorRGB variable
			colorRGB[0] = 133;
			colorRGB[1] = 255;
			colorRGB[2] = 213;
		}

		// If the randomcolor variable is 7 then execute this section
		case 7:
		{
			// Changes the color values of our colorRGB variable
			colorRGB[0] = 15;
			colorRGB[1] = 255;
			colorRGB[2] = 255;
		}

		// If the randomcolor variable is 8 then execute this section
		case 8:
		{
			// Changes the color values of our colorRGB variable
			colorRGB[0] = 255;
			colorRGB[1] = 0;
			colorRGB[2] = 255;
		}

		// If the randomcolor variable is 9 then execute this section
		case 9:
		{
			// Changes the color values of our colorRGB variable
			colorRGB[0] = 131;
			colorRGB[1] = 22;
			colorRGB[2] = 228;
		}
	}

	// Formats the colorCombination to create a variable containing red, green and blue color values
	Format(colorCombination, sizeof(colorCombination), "%i %i %i", colorRGB[0], colorRGB[1], colorRGB[2]);

	// Changes the color of the entity to the RGB color combination within our colorCombination variable
	DispatchKeyValue(entity, "rendercolor", colorCombination);
}


// This happens when a player dies and drops a healthshot
public Action SetRandomLightColor(int healthShotEntity)
{
	// Creates a dynamic light and store it's index within our entity variable
	int entity = CreateEntityByName("light_dynamic");

	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Formats the colorCombination to create a variable containing red, green and blue color values
	Format(colorCombination, sizeof(colorCombination), "%i %i %i 255", colorRGB[0], colorRGB[1], colorRGB[2]);

	// Changes the color of the light emitted from the light_dynamic entity
	DispatchKeyValue(entity, "_light", colorCombination);
	
	// Defines the brightness
	DispatchKeyValue(entity, "brightness", "6");

	// Defins the radius of the spotlight
	DispatchKeyValueFloat(entity, "spotlight_radius", 300.0);

	// Sets the distance of the light_dynamic entity
	DispatchKeyValueFloat(entity, "distance", float(65));

	// Chooses which lighting style that should be used by our light_dynamic
	DispatchKeyValue(entity, "style", "6");

	// Spawns the light_dynamic entity in to the world 
	DispatchSpawn(entity);

	// Turns on the entity's light
	AcceptEntityInput(entity, "TurnOn");
	
	// Creates a variable which we will use to store our data within
	float entityLocation[3];

	// Modifies the placement of the light_dynamic's z-coordinate position
	entityLocation[2] = 5.0;

	// Changes the variantstring to !activator
	SetVariantString("!activator");
	
	// Changes the parent of the light_dynamic to be the spawned healthshot
	AcceptEntityInput(entity, "SetParent", healthShotEntity, entity, 0);
	
	// Teleports the light_dynamic to the specified coordinate location
	TeleportEntity(entity, entityLocation, NULL_VECTOR, NULL_VECTOR);

	return Plugin_Continue;
}


// This happens when a player that controls a bot dies
public void RespawnOvertakenBots()
{
	// Loops through all of the clients
	for (int i = 1; i <= MaxClients; i++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(i))
		{
			continue;
		}

		// If the client is not a bot then execute this section
		if(!IsFakeClient(i))
		{
			continue;
		}

		// If the client is alive then execute this section
		if(IsPlayerAlive(i))
		{
			continue;
		}

		// Calls upon the Timer_RespawnPlayer function after (1.5 default) seconds
		CreateTimer(cvar_RespawnTime, Timer_RespawnPlayer, i, TIMER_FLAG_NO_MAPCHANGE);
	}
}


// This happens when a player is takes damage
public Action KingRecovery(int client)
{
	// If the client is not the current king then execute this section
	if(!isPlayerKing[client])
	{
		return Plugin_Continue;
	}

	// Obtains the health of client and store it within our variable playerHealth
	int playerHealth = GetEntProp(client, Prop_Send, "m_iHealth");

	// If the client's health is 0 or below then execute this section
	if(playerHealth <= 0)
	{
		return Plugin_Continue;
	}

	// If the client's health is 75 or above thhen execute this section
	if (playerHealth >= 75)
	{
		return Plugin_Continue;
	}

	// If recovery is currently on cooldown then execute this section
	if(isRecoveryOnCooldown[client])
	{
		return Plugin_Continue;
	}

	// Resets the recovry counter back to 0
	kingRecoveryCounter = 0;

	// Changes the cooldown state of the recovery to be on cooldown
	isRecoveryOnCooldown[client] = true;

	// Sends a colored multi-language message in the chat area
	// CPrintToChat(client, "%t", "Recovery Starts");
	PrintToChat(client, "King Recovery Started");

	// If the sound is not already precached then execute this section
	if(!IsSoundPrecached("kingmod/recovery_initiated.mp3"))
	{	
		// Precaches the sound file
		PrecacheSound("kingmod/recovery_initiated.mp3", true);
	}

	// Emits a sound to the specified client that only they can hear
	EmitSoundToClient(client, "kingmod/recovery_initiated.mp3", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.00, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

	// Changes the king's color to green while recovery is active
	SetEntityRenderColor(client, 35, 230, 5, 255);

	// After seconds, calls upon our Timer_RegenerationProtocolCooldown function to remove the cooldown on the Regeneration Protocol
	CreateTimer(0.0, Timer_RecoverHealth, client, TIMER_FLAG_NO_MAPCHANGE);

	// After a few seconds calls upon our 
	CreateTimer(cvar_RecoveryCooldownDuration, Timer_RemoveRecoveryCooldown, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}


// This happens when a new king is chosen
public Action DisplayVisualEffects(int attacker)
{
	// If neither ring or tesla effects are enabled then execute this section
	if(!cvar_EffectRing && !cvar_EffectTesla)
	{
		return Plugin_Continue;
	}

	// Creates a variable which we will store our effectColor within 
	int effectColor[4];

	// Creates a variable which we will store our data within
	float playerLocation[3];

	// Obtains the location of the attacker and store it within the playerLocation variable
	GetClientAbsOrigin(attacker, playerLocation);

	// Modifies the position by +20.0 on z-axis
	playerLocation[2] += 20.0;

	// If the player is on the Terrorist team then execute this section
	if(GetClientTeam(attacker) == 2)
	{
		// Changes the color values for the effects 
		effectColor[0] = 255;
		effectColor[1] = 45;
		effectColor[2] = 45;
		effectColor[3] = 220;
	}

	// If the player is on the Counter-Terrorist team then execute this section
	else if(GetClientTeam(attacker) == 3)
	{
		// Changes the color values for the effects
		effectColor[0] = 75;
		effectColor[1] = 75;
		effectColor[2] = 255;
		effectColor[3] = 220;
	}

	// If effect rings are enabled then execute this section
	if(cvar_EffectRing)
	{
		// Creates a temp entity visual efefct shaped like a ring
		TE_SetupBeamRingPoint(playerLocation, 40.0, 2000.0, effectRing, effectRing, 0, 20, 1.5, 90.0, 2.0, effectColor, 1, 1);

		// Sends the visual effect temp entity to the relevant players
		ShowVisualEffectToPlayers();
	}

	// If tesla effects are enabled then execute this section
	if(!cvar_EffectTesla)
	{
		return Plugin_Continue;
	}


	// Tesla Effect Stuff
	int point_tesla = CreateEntityByName("point_tesla");

	// If the edict does not meet our validation criteria then execute this section
	if(!IsValidEdict(point_tesla))
	{
		return Plugin_Continue;
	}

	// Modifies the position by -28 on z-axis
	playerLocation[2] -= 28.0;

	// Creates a variable which we will use to store data within
	char teslaName[16];

	// Creates a variable which we will use to store data within
	char teslaColor[16];

	// Formats the teslaName to create a unique name for the tesla effect
	Format(teslaName, sizeof(teslaName), "teslaeffect_%i", attacker);

	// Formats the teslaColor to create a color that corrosponds to a team
	Format(teslaColor, sizeof(teslaColor), "%i %i %i", effectColor[0], effectColor[1], effectColor[2]);
	
	// Sets the name of the tesla to the one stored within our teslaName variable
	DispatchKeyValue(point_tesla, "Name", teslaName);

	// Sets the color of the tesla to the one we have stored within our teslaColor variable
	DispatchKeyValue(point_tesla, "m_Color", teslaColor);

	// Specifies the texture we wish to use for our visual effect
	DispatchKeyValue(point_tesla, "texture", "kingmod/sprites/lgtning.vmt");

	// Sets the minimum of tesla beams that will be created by our tesla
	DispatchKeyValue(point_tesla, "beamcount_min", "1250");

	// Sets the maximum of tesla beams that will be created by our tesla
	DispatchKeyValue(point_tesla, "beamcount_max", "3750");

	// Defines how large the radius of our tesla will b
	DispatchKeyValueFloat(point_tesla, "m_flRadius", 1250.0);

	// Sets the width of the teslabeam at the center of the tesla
	DispatchKeyValueFloat(point_tesla, "thick_min", 3.4);

	// Sets the width of the tesla beams at the end point of the tesla
	DispatchKeyValueFloat(point_tesla, "thick_max", 0.6);

	// Specifies the minimum duration that the tesla beam will be displayed for
	DispatchKeyValueFloat(point_tesla, "lifetime_min", 0.1);

	// Specifies the maximum duration that the tesla beam will be displayed for
	DispatchKeyValueFloat(point_tesla, "lifetime_min", 0.3);

	// Specifies the minimum frequency of the emitting intervals of the tesla beams
	DispatchKeyValueFloat(point_tesla, "interval_min", 0.1);

	// Specifies the maximum frequency of the emitting intervals of the tesla beams
	DispatchKeyValueFloat(point_tesla, "interval_max", 0.2);
	
	// Defines the sound that is played when the tesla creates a spark
	DispatchKeyValue(point_tesla, "m_SoundName", "DoSpark");
	
	// Spawns the tesla entity in to the world 
	DispatchSpawn(point_tesla);
	
	// Activates the tesla entity
	ActivateEntity(point_tesla);
	
	// Teleports the tesla entity to the coordinate location stored within our variable playerLocation
	TeleportEntity(point_tesla, playerLocation, NULL_VECTOR, NULL_VECTOR);
	
	// Turns on the Tesla entity
	AcceptEntityInput(point_tesla, "TurnOn");

	// Makes the tesla create a spark
	AcceptEntityInput(point_tesla, "DoSpark");

	// Makes the tesla create a spark after the specified time
	CreateTimer(0.1, Timer_TeslaEffectDoSpark, point_tesla);
	CreateTimer(0.3, Timer_TeslaEffectDoSpark, point_tesla);
	CreateTimer(0.4, Timer_TeslaEffectDoSpark, point_tesla);
	CreateTimer(0.5, Timer_TeslaEffectDoSpark, point_tesla);
	CreateTimer(0.6, Timer_TeslaEffectDoSpark, point_tesla);
	CreateTimer(0.7, Timer_TeslaEffectDoSpark, point_tesla);

	// Removes the point_tesla entity after 1.0 seconds has passed
	CreateTimer(1.0, Timer_TeslaEffectKill, point_tesla);

	return Plugin_Continue;
}


// This happens when a ring effect is to be created which happens when a new king is chosen
public void ShowVisualEffectToPlayers()
{
	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// If the client is a bot then execute this section
		if(IsFakeClient(client))
		{
			continue;
		}

		// Sends the temp entity visual effects only to those with the headshot kill visual effects enabled
		TE_SendToClient(client, 0.0);
	}
}



///////////////////////////////
// - Timer Based Functions - //
///////////////////////////////


// This function happens once every 1 second and is used to update the custom team score hud element
public Action Timer_UpdateTeamScoreHud(Handle timer)
{
	// Creates a variable which we will use to store our data within
	char hudMessage[1024];

	// If there are currently no king then execute this section
	if(kingIsOnTeam == 0)
	{
		// Modifies the contents stored within the hudMessage variable
		Format(hudMessage, 1024, "%s\n<font color='#fbb227'>King:</font><font color='#5fd6f9'> %s</font>", hudMessage, kingName);
	}

	// If the king is currently on the terrorist team then execute this section
	else if(kingIsOnTeam == 2)
	{
		// Modifies the contents stored within the hudMessage variable
		Format(hudMessage, 1024, "%s\n<font color='#fbb227'>King:</font><font color='#d94545'> %s</font>", hudMessage, kingName);
	}

	// If the king is currently on the counter-terrorist team then execute this section
	else if(kingIsOnTeam == 3)
	{
		// Modifies the contents stored within the hudMessage variable
		Format(hudMessage, 1024, "%s\n<font color='#fbb227'>King:</font><font color='#5fa7f9'> %s</font>", hudMessage, kingName);
	}

	// Modifies the contents stored within the hudMessage variable
	Format(hudMessage, 1024, "%s\n<font color='#fbb227'>T:<font color='#d94545'> %i<font color='#fbb227'> - CT:</font><font color='#5fa7f9'> %i</font>", hudMessage, pointCounterT, pointCounterCT);

	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// If the client is a bot then execute this section
		if(IsFakeClient(client))
		{
			continue;
		}

		// If the client recently touched a restricted weapon then execute this section
		if(displayRestrictionHud[client])
		{
			// Resets the contents of the hudMessage variable
			hudMessage = "";

			// Formats the message that we wish to send to the player and store it within our message_string variable
			Format(hudMessage, 1024, "%s\n<font color='#e30000'>Weapon Restriction:</font>", hudMessage);
			Format(hudMessage, 1024, "%s\n<font color='#fbb227'>This weapon is restricted for you</font>", hudMessage);
		}

		// If the player is the king then execute this section
		if(isPlayerKing[client])
		{
			// If the king is in the process of acquiring his new power then execute this section
			if(kingIsAcquiringPower == 1)
			{
				// Resets the contents of the hudMessage variable
				hudMessage = "";

				// Formats the message that we wish to send to the player and store it within our message_string variable
				Format(hudMessage, 1024, "%s\n<font color='#fbb227'>---------------------</font>", hudMessage);
				Format(hudMessage, 1024, "%s\n<font color='#33E0FF'>Acquiring Power</font>", hudMessage);
				Format(hudMessage, 1024, "%s\n<font color='#fbb227'>---------------------</font>", hudMessage);
			}

			// If the king has acquired his new power then execute this section
			else if(kingIsAcquiringPower == 2)
			{
				// Resets the contents of the hudMessage variable
				hudMessage = "";

				// Formats the message that we wish to send to the player and store it within our message_string variable
				Format(hudMessage, 1024, "%s\n<font color='#fbb227'>%s</font>", hudMessage, dottedLine);
				Format(hudMessage, 1024, "%s\n<font color='#33E0FF'>%s - %s</font>", hudMessage, nameOfPower, nameOfTier);
				Format(hudMessage, 1024, "%s\n<font color='#fbb227'>%s</font>", hudMessage, dottedLine);
			}
		}

		// Displays the contents of our hudMessage variable for the client to see in the hint text area of their screen 
		PrintHintText(client, hudMessage);
	}

	return Plugin_Continue;
}


// This happens once every 1.0 seconds once the plugin has been loaded
public Action SentryGunModifyGunFire(Handle timer)
{
	if(!gameInProgress)
	{
		return Plugin_Continue;
	}

	// Creats a variable to store our information within and sets it to false
	bool isCheatsEnabled = false;

	// If the server already have sv_cheats enabled then execute this section
	if(GetConVarInt(FindConVar("sv_cheats")) != 0)
	{
		isCheatsEnabled = true;
	}

	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// If the client is not a bot then execute this section
		if(!IsFakeClient(client))
		{
			continue;
		}

		// If sv_cheats are not currently enabled then execute this section
		if(!isCheatsEnabled)
		{
			// Changes the sv_cheats convar to 1
			SetConVar("sv_cheats", "0");
		}

		// Performs a fake client command to target all env_gunfire entities and modify their weapon name  
		FakeClientCommand(client, "ent_fire env_gunfire addoutput \"weaponname weapon_shield\"");
		
		// If sv_cheats are not currently enabled then execute this section
		if(!isCheatsEnabled)
		{
			// Changes the sv_cheats convar back to 0
			SetConVar("sv_cheats", "1");
		}

		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}


// This happens every 2.5 seconds and is used to remove items and weapons lying around in the mapr
public Action Timer_CleanFloor(Handle timer)
{
	// Loops through all entities that are currently in the game
	for (int entity = MaxClients + 1; entity <= GetMaxEntities(); entity++)
	{
		// If the entity does not meet our criteria of validation then execute this section
		if(!IsValidEntity(entity))
		{
			continue;
		}

		// Creates a variable which we will use to store data within
		char className[64];

		// Obtains the entity's class name and store it within our className variable
		GetEntityClassname(entity, className, sizeof(className));

		// If the entity is a healthshot then execute this section
		if(StrEqual(className, "weapon_healthshot"))
		{	
			continue;
		}

		// If the className contains neither weapon_ nor item_ then execute this section
		if((StrContains(className, "weapon_") == -1 && StrContains(className, "item_") == -1))
		{
			continue;
		}

		// If the king's current power is the sticky grenades power then execute this section
		if(powerStickyGrenades)
		{
			// If the entity is a high explosive grenade then execute this section
			if(StrEqual(className, "weapon_hegrenade", false))
			{
				continue;
			}
		}

		// If the king's current power is the carpet bombing flashbangs power then execute this section
		if(powerCarpetBombingFlashbangs)
		{
			// If the entity is a flashbang then execute this section
			if(StrEqual(className, "weapon_flashbang", false))
			{
				continue;
			}
		}

		// If the king's current power is the napalm power then execute this section
		if(powerNapalm)
		{
			// If the entity is a molotov then execute this section
			if(StrEqual(className, "weapon_molotov", false))
			{
				continue;
			}
		}

		// If the king's current power is the scout no scope power then execute this section
		if(powerScoutNoScope)
		{
			// If the entity is a ssg08 then execute this section
			if(StrEqual(className, "weapon_ssg08", false))
			{
				continue;
			}
		}

		// If the currently active power is riot then execute this section
		if(powerRiot)
		{
			// If the entity is a shield then execute this section
			if(StrEqual(className, "weapon_shield", false))
			{
				continue;
			}
		}

		// If the currently active power is breachcharges then execute this section
		if(powerBreachCharges)
		{
			// If the entity is a breachcharge then execute this section
			if(StrEqual(className, "weapon_breachcharge", false))
			{
				continue;
			}
		}

		// If the currently active power is leg crushing bumpmines then execute this section
		if(powerLegCrushingBumpmines)
		{
			// If the entity is a bumpmine then execute this section
			if(StrEqual(className, "weapon_bumpmine", false))
			{
				continue;
			}
		}

		// If the currently active power is hatchet massacre then execute this section
		if(powerHatchetMassacre)
		{
			// If the entity is an axe then execute this section
			if(StrEqual(className, "weapon_melee", false))
			{
				continue;
			}
		}

		// If the currently active power is chuck norris fists then execute this section
		if(powerChuckNorris)
		{
			// If the entity is fists then execute this section
			if(StrEqual(className, "weapon_fists", false))
			{
				continue;
			}
		}

		// If the currently active power is laser gun then execute this section
		if(powerLaserGun)
		{
			// If the entity is cz75a then execute this section
			if(StrEqual(className, "weapon_cz75a", false))
			{
				continue;
			}
		}

		// If the currently active power is western shootout then execute this section
		if(powerWesternShootout)
		{
			// If the entity is a revolver (deagle shares item slot with it) then excute this section
			if(StrEqual(className, "weapon_deagle", false))
			{
				continue;
			}
		}

		// If the currently active power is Blast Cannon then execute this section
		if(powerBlastCannon)
		{
			// If the entity is a sawedoff shotgun then excute this section
			if(StrEqual(className, "weapon_sawedoff", false))
			{
				continue;
			}
		}

		// If the currently active power is Deagle Headshot then execute this section
		if(powerDeagleHeadshot)
		{
			// If the entity is a deagle then excute this section
			if(StrEqual(className, "weapon_deagle", false))
			{
				continue;
			}
		}

		// If the currently active power is Hammer Time then execute this section
		if(powerHammerTime)
		{
			// If the entity is a hammer then excute this section
			if(StrEqual(className, "weapon_hammer", false))
			{
				continue;
			}
		}

		// If the entity has an ownership relation then execute this section
		if(GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") != -1)
		{
			return Plugin_Continue;
		}

		PrintToChatAll("Debug removed weapon %s", className);

		// Removes the entity from the map 
		AcceptEntityInput(entity, "Kill");
	}

	return Plugin_Continue;
}


// This function is called upon 3.0 seconds after LateLoadSupport is initiated
public Action Timer_TerminateRound(Handle timer)
{
	// Forcefully ends the round and considers it a round draw
	CS_TerminateRound(0.0, CSRoundEnd_Draw);

	return Plugin_Continue;
}


// This happens when a player joins the server after the mp-force_pick_time has run out 
public Action Timer_AutoJoinTeam(Handle timer, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the client is on the terrorist or counter-terrorist team then execute this section
	if(GetClientTeam(client) >= 1)
	{
		return Plugin_Continue;
	}

	// Creates the teamChoice variable and set it to -1 to indicate the team is still undecided
	int teamChoice = -1;

	// If there are more players on the terrorist team then execute this
	if(GetTeamClientCount(2) > GetTeamClientCount(3))
	{
		// Sets the teamChoice variable to 3 to indicate the counter-terrorist team
		teamChoice = 3;
	}

	// If there are more players on the counter-terrorist team then execute this
	else if(GetTeamClientCount(2) < GetTeamClientCount(3))
	{
		// Sets the teamChoice variable to 2 to indicate the terrorist team
		teamChoice = 2;
	}

	// If there are the same amount of players on both teams then execute this section
	else
	{
		// Obtain the terrorist team's score and store it within the scoreT variable
		int scoreT = GetTeamScore(2);

		// Obtain the counter-terrorist team's score and store it within the scoreCT variable
		int scoreCT = GetTeamScore(3);

		// If the terrorists have more points than the counter-terrorists then execute this section
		if(scoreT > scoreCT)
		{
			// Sets the teamChoice variable to 3 to indicate the counter-terrorist team
			teamChoice = 3;
		}

		// If the terrorists have less points than the counter-terrorists then execute this section
		else if(scoreT < scoreCT)
		{
			// Sets the teamChoice variable to 2 to indicate the terrorist team
			teamChoice = 2;
		}

		// If both teams have the same score then execute this section
		else
		{
			// Picks a random number between 0 and 1 and store it within the randomTeam variable
			int randomTeam = GetRandomInt(0, 1);

			// If the value of the randomTeam variable is 0 then execute this section
			if(!randomTeam)
			{
				// Sets the teamChoice variable to 2 to indicate the terrorist team
				teamChoice = 2;
			}

			// If the value of the randomTeam variable is 1 then execute this section
			else
			{
				// Sets the teamChoice variable to 3 to indicate the counter-terrorist team
				teamChoice = 3;
			}
		}
	}

	// Changes the client's team to the team index stored within the teamChoice variable
	ChangeClientTeam(client, teamChoice);

	// Calls upon the Timer_RespawnPlayer function after (1.5 default) seconds
	CreateTimer(cvar_RespawnTime, Timer_RespawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}


// This happens 3.0 seconds after a player tries to pick up a restricted weapon
public Action Timer_DisableRestrictionHud(Handle Timer, int client)
{
	// If the player does not meet our validation criteria then execut this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Changes the state of displayRestrictionHud[client] to false
	displayRestrictionHud[client] = false;

	return Plugin_Continue;
}


// This happens when a player becomes the king
public Action Timer_GiveGoldenKnife(Handle Timer, int client)
{
	// If the player does not meet our validation criteria then execut this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the currently active power is hatchet massacre then execute this section
	if(powerHatchetMassacre)
	{
		return Plugin_Continue;
	}

	// If the currently active power is chuck norris fists then execute this section
	if(powerChuckNorris)
	{
		return Plugin_Continue;
	}

	// If the currently active power is hammer time then execute this section
	if(powerHammerTime)
	{
		return Plugin_Continue;
	}

	// If the currently active power is Laser Pointer then execute this section
	if(powerLaserPointer)
	{
		return Plugin_Continue;
	}

	// Gives the client the specified weapon
	GivePlayerItem(client, "weapon_knifegg");

	return Plugin_Continue;
}


// This function is called 0.55 seconds after a player uses a health injection
public Action Timer_InjectionComplete(Handle Timer, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Obtains the client's current health and store it within the variable playerHealthPreInjection[client]
	playerHealthPreInjection[client] = GetEntProp(client, Prop_Send, "m_iHealth");

	return Plugin_Continue;
}


// This happens 0.85 seconds after a player uses a halthshot
public Action Timer_InjectHealthshot(Handle Timer, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Execute this section if the injection is currently on cooldown
	if(injectingHealthshot[client])
	{
		// Changes the player's injectingHealthshot state back to false
		injectingHealthshot[client] = false;
	}

	// Obtains the name of the player's weapon and store it within our variable entity
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Creates a variable which we will use to store data within
	char className[64];

	// Obtains the entity's class name and store it within our className variable
	GetEntityClassname(entity, className, sizeof(className));

	// If the entity is not a healthshot then execute this section
	if(!StrEqual(className, "weapon_healthshot", false))
	{
		return Plugin_Continue;
	}

	// Picks a random number between 25 and 75 and store it within the recoveredHealth variable
	int recoveredHealth = GetRandomInt(25, 75);

	// Obtains the player's current health and store it within the playerHealth variable
	int playerHealth = playerHealthPreInjection[client];
	PrintToChat(client, "Debug playerHealth initial HP: %i", playerHealth);

	// Adds the value of recoveredHealth to the value stored within our playerHealth variable
	playerHealth += recoveredHealth;

	// If the player is not the king then execute this section
	if(!isPlayerKing[client])
	{
		// If the player's health will be 100 or above, then execute this section
		if(playerHealth >= 100)
		{
			// Changes the player's health to 100
			SetEntProp(client, Prop_Send, "m_iHealth", 100, 1);

			// Finds the actual health granted by the healthshot and store it within recoveredHealth
			recoveredHealth = (recoveredHealth - playerHealth) + 100;
		}

		// If the player's health is less than 1000 then execute this section
		else
		{
			// Changes the player's health to the value of playerHealth
			SetEntProp(client, Prop_Send, "m_iHealth", playerHealth, 1);
		}
	}

	// If the player is the current king then execute this section
	else
	{
		// If the player's health will be 200 or above, then execute this section
		if(playerHealth >= 200)
		{
			// Changes the player's health to 200
			SetEntProp(client, Prop_Send, "m_iHealth", 200, 1);

			// Finds the actual health granted by the healthshot and store it within recoveredHealth
			recoveredHealth = (recoveredHealth - playerHealth) + 200;
		}

		// If the player's health is less than 200 then execute this section
		else
		{
			// Changes the player's health to the value of playerHealth
			SetEntProp(client, Prop_Send, "m_iHealth", playerHealth, 1);

			PrintToChat(client, "playerHealth HP: %i", playerHealth);
		}
	}

	// Sends a multi-language message in the chat to the client
	PrintToChat(client, "The healthshot recovered %i of your health", recoveredHealth);

	// Changes the player's cooldownWeaponSwapMessage state to false
	cooldownWeaponSwapMessage[client] = false;

	return Plugin_Continue;
}


// This happens 1.90 seconds after a player uses a halthshot
public Action Timer_CooldownHealthshotAction(Handle Timer, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Changes the player's cooldownHealthshot state to false
	cooldownHealthshot[client] = false;

	return Plugin_Continue;
}


// This happens 1.0 second after a player with weapon swapping blocked has tried to swap weapons
public Action Timer_RemoveCooldownWeaponSwapMessage(Handle Timer, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Changes the player's cooldownWeaponSwapMessage state to false
	cooldownWeaponSwapMessage[client] = false;

	return Plugin_Continue;
}


// This happens (3.5 default) seconds after a player spawns
public Action Timer_ExpireSpawnProtection(Handle timer, DataPack dataPackage)
{
	dataPackage.Reset();

	// Obtains client index stored within our data pack and store it within the client variable
	int client = dataPackage.ReadCell();

	// Obtains PlayerSpawnCount stored within our data pack and store it within the SpawnCount variable
	int SpawnCount = dataPackage.ReadCell();
	
	// Deletes our data package after having acquired the information we needed
	delete dataPackage;
	
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Stop;
	}

	// If the spawncount and PlayerSpawnCount variable differs then execute this section
	if(SpawnCount != PlayerSpawnCount[client])
	{
		return Plugin_Stop;
	}

	// If the player is no longer spawnprotected then execute this section
	if(!isPlayerProtected[client])
	{
		return Plugin_Stop;
	}

	// Removes the spawn protection from the client
	RemoveSpawnProtection(client);

	return Plugin_Stop;
}


// This happens when a player spawns
public Action Timer_HudElementMinimap(Handle timer, int client) 
{
	// If the minimap / radar is not set to be hidden then execute this section
	if(!mapHasMinimapHidden)
	{
		return Plugin_Continue;
	}

	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the player is anything but a bot then execute this section
	if(IsFakeClient(client))
	{
		return Plugin_Continue;
	}

	//Disables CS:GO's built-in minimap / radar hud element
	SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | 4096);

	return Plugin_Continue;
}


// This happens 3.0 seconds after a player becomes the king if the map has platform support
public Action Timer_UnfreezeKing(Handle timer, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the value stored within the powerMovementSpeed is 0 execute this section
	if(powerMovementSpeed == 0)
	{
		// Changes the movement speed of the player to 1.0 essentially returning their movement to the normal speed
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}

	// If the value stored within the powerMovementSpeed is 1 execute this section
	else if(powerMovementSpeed == 1)
	{
		// Changes the movement speed of the player to 200% of the normal movement speed
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.80);
	}

	// If the value stored within the powerMovementSpeed is 2 execute this section
	else if(powerMovementSpeed == 2)
	{
		// Changes the movement speed of the player to 175% of the normal movement speed
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.60);
	}

	// If the value stored within the powerMovementSpeed is 3 execute this section
	else if(powerMovementSpeed == 3)
	{
		// Changes the movement speed of the player to 150% of the normal movement speed
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.40);
	}

	return Plugin_Continue;
}


// This happens (10.0 default) seconds after a player dies and drops a healthshot
public Action Timer_RemoveHealthShot(Handle Timer, int entity)
{
	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Creates a variable to store our data within
	char classname[32];

	// Obtains the classname of the entity and store it within our classname variable
	GetEdictClassname(entity, classname, sizeof(classname));

	// If the entity has an ownership relation then execute this section
	if(GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") != -1)
	{
		return Plugin_Continue;
	}

	// Removes the entity from the game
	AcceptEntityInput(entity, "Kill");

	return Plugin_Continue;
}


// This function is called upon briefly after a player changes team or dies
public Action Timer_RespawnPlayer(Handle timer, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the client is on the spectator or observer team then execute this section
	if(GetClientTeam(client) <= 1)
	{
		return Plugin_Continue;
	}

	// If the client is alive then execute this section
	if(IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	// Respawns the player
	CS_RespawnPlayer(client);

	return Plugin_Continue;
}


// This happens 0.25 seconds prior to when the round would normally end
public Action Timer_EndCurrentRound(Handle Timer, int initialRound)
{
	// Obtain the current round based on the counter-terrorist and terrorist teams' scores
	int currentRound = GetTeamScore(2) + GetTeamScore(3);

	// If the currentRound and initialRound differ from one another then execute this section
	if(initialRound != currentRound)
	{
		return Plugin_Stop;
	}

	// Changes the gameInProgress state to false
	gameInProgress = false;

	// Creates a variable named restartRoundDelay storing the value of the mp_round_restart_delay convar within
	float restartRoundDelay = GetConVarFloat(FindConVar("mp_round_restart_delay"));

	// If the value stored within restartRoundDelay is below 3.0 then execute this section
	if(restartRoundDelay < 3.0)
	{
		// Changes the value of restartRoundDelay to 3.0
		restartRoundDelay = 3.0;
	}

	// If the Terrorist team have more points than the Counter-Terrorist team then execute this section
	if(pointCounterT > pointCounterCT)
	{
		// Forcefully ends the round and considers it a win for the terrorist team
		CS_TerminateRound(restartRoundDelay, CSRoundEnd_TerroristWin);

		// Adds + 1 to the terrorist team's current team score
		SetTeamScore(2, GetTeamScore(2) + 1);
	}

	// If the Terrorist team have less points than the Counter-Terrorist team then execute this section
	else if(pointCounterT < pointCounterCT)
	{
		// Forcefully ends the round and considers it a win for the counter-terrorist team
		CS_TerminateRound(restartRoundDelay, CSRoundEnd_CTWin);

		// Adds + 1 to the counter-terrorist team's current team score
		SetTeamScore(3, GetTeamScore(3) + 1);
	}

	// If the Terrorist team have the same amount of points as the Counter-Terrorist team then execute this section
	else
	{
		// Forcefully ends the round and considers it a round draw
		CS_TerminateRound(restartRoundDelay, CSRoundEnd_Draw);
	}

	return Plugin_Continue;
}


// This happens when the king drops below 75 health from taking damage
public Action Timer_RecoverHealth(Handle Timer, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the client is not alive then execute this section
	if(!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	// If the client is not the current king then execute this section
	if(!isPlayerKing[client])
	{
		return Plugin_Continue;
	}

	// Adds 1 to our the tick counter
	kingRecoveryCounter++;

	// Obtains the health of client and store it within our variable playerHealth
	int playerHealth = GetEntProp(client, Prop_Send, "m_iHealth");

	// If the client's health is below or equals to 75 then execute this section
	if(playerHealth <= 75)
	{
		// If the client's health is 70 or above thhen execute this section
		if(playerHealth >= 70)
		{
			// Sets the value of playerHealth to 75
			playerHealth = 75;
		}

		// If the client have 69 or less health then execute this section
		else
		{
			// Adds +5 to the value of the playerHealth variable
			playerHealth += 5;
		}		
	}

	// Changes the client's health to the value of the playerHealth variable
	SetEntProp(client, Prop_Send, "m_iHealth", playerHealth, 1);

	// If the tick counter is below or equal to 15 then execute this section 
	if(kingRecoveryCounter <= 15)
	{
		// Calls upon this same function again after 0.3 seconds has passed
		CreateTimer(0.3, Timer_RecoverHealth, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	// If the tick counter is 15 or above then execute this section
	else
	{
		// Changes the king's color back to the default color
		SetEntityRenderColor(client, 255, 255, 255, 255);

		// Sends a colored multi-language message in the chat area
		// CPrintToChat(client, "%t", "Regeneration Protocol Completed");
		PrintToChat(client, "King Recovery Has Ended");

		// If the sound is not already precached then execute this section
		if(!IsSoundPrecached("kingmod/recovery_complete.mp3"))
		{	
			// Precaches the sound file
			PrecacheSound("kingmod/recovery_complete.mp3", true);
		}

		// Emits a sound to the specified client that only they can hear
		EmitSoundToClient(client, "kingmod/recovery_complete.mp3", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.00, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

	}

	return Plugin_Continue;
}


// This happens 10 seconds after the king drops below 75 health from taking damage
public Action Timer_RemoveRecoveryCooldown(Handle Timer, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Changes the recovry cooldown state to be off cooldown
	isRecoveryOnCooldown[client] = false;

	return Plugin_Continue;
}


// This happens a few times within 1 second after a new king is chosen
public Action Timer_TeslaEffectDoSpark(Handle timer, int edict)
{
	// If the edict does not meet our validation criteria then execute this section
	if(!IsValidEdict(edict))
	{
		return Plugin_Continue;
	}

	// Makes the edict emit a spark
	AcceptEntityInput(edict, "DoSpark");

	return Plugin_Continue;
}


// This happens 1 second after a new king has been chosen
public Action Timer_TeslaEffectKill(Handle timer, int edict)
{
	// If the edict does not meet our validation criteria then execute this section
	if(!IsValidEdict(edict))
	{
		return Plugin_Continue;
	}

	// Removes the entity from the game
	AcceptEntityInput(edict, "Kill");

	return Plugin_Continue;
}



/////////////////////////////////////////
// - Power Chooser Related Functions - //
/////////////////////////////////////////


// This happens when a new king has been chosen
public Action ChooseKingPower(int client)
{
	// If the cvar_KingPowerChooser is not enabled then execute this section
	if(!cvar_KingPowerChooser)
	{
		return Plugin_Continue;
	}

	// Resets all power spcific variables back to their default values 
	ResetPreviousPower();

	// Creates a variable called powersAvailable and set it to the same value as the amount of enabled powers
	int powersAvailable = countAvailablePowers();

	// If the value of powersAvailable is 0 then execute this section
	if(!powersAvailable)
	{
		// Writes a message to the server's console informing about the possible issue at hand
		PrintToServer("=======================================================================================================");
		PrintToServer("[King Mod Warning]:");
		PrintToServer("   None of the available powers are enabled. Please change the cvar 'kingmod_kingpowers' to 0,");
		PrintToServer("   inside of the addons/sourcemod/configs/KingMod/cvars.txt file to improve performance.");
		PrintToServer("   ");
		PrintToServer("=======================================================================================================");

		return Plugin_Continue;
	}

	// Changes the kingIsAcquiringPower to 1 to indicate that the king is about to acquire his power
	kingIsAcquiringPower = 1;

	// Calls upon the Timer_UpdateTeamScoreHud function to update the HUD
	CreateTimer(0.0, Timer_UpdateTeamScoreHud, _, TIMER_FLAG_NO_MAPCHANGE);

	// If the sound is not already precached then execute this section
	if(!IsSoundPrecached("kingmod/power_acquiringpower.mp3"))
	{	
		// Precaches the sound file
		PrecacheSound("kingmod/power_acquiringpower.mp3", true);
	}

	// Emits a sound to the specified client that only they can hear
	EmitSoundToClient(client, "kingmod/power_acquiringpower.mp3", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.00, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

	// Picks a value between 1 to the value stored within our powersAvailable variable
	int chosenPower = GetRandomInt(1, powersAvailable);

	// Resets the value of powersAvailable back to 0
	powersAvailable = 0;

	// If the cvar for the impregnable armor power is enabled then execute this section
	if(cvar_PowerImpregnableArmor)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the client a heavy assault suit, a random armor value and applies a screen overlay
			PowerImpregnableArmor(client);

			// 
			PrintToChatAll("Power impregnable Armor - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}

	// If the cvar for the movement speed power is enabled then execute this section
	if(cvar_PowerMovementSpeed)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// INcreases the movement speed of all the players
			PowerMovementSpeed();

			// 
			PrintToChatAll("Movement Speed - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}

	// If the cvar for the sticky grenades power is enabled then execute this section
	if(cvar_PowerStickyGrenades)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the client an infinite amount of grenades and let the grenades stick to walls, objects and players
			PowerStickyGrenades(client);

			// 
			PrintToChatAll("Power Sticky Grenades - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}

	// If the cvar for the scout no scope power is enabled then execute this section
	if(cvar_PowerScoutNoScope)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the client a ssg08 but the player is unable to use the weapon's scope 
			PowerScoutNoScope(client);

			// 
			PrintToChatAll("Power Scout No Scope - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}

	// If the cvar for the carpet bombing flashbangs power is enabled then execute this section
	if(cvar_PowerCarpetBombingFlashbangs)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the client an infinite amount of flashbangs that duplicates themselves when thrown and deal damage 1337 upon collision
			PowerCarpetBombingFlashbangs(client);

			// 
			PrintToChatAll("Power Carpet Bombing Flashbangs - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}

	// If the cvar for the napalm power is enabled then execute this section
	if(cvar_PowerNapalm)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the client an infinite amount of molotovs, the fire from the molotovs will cause players to catch on fire
			PowerNapalm(client);

			// 
			PrintToChatAll("Power Napalm - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}

	// If the cvar for the riot power is enabled then execute this section
	if(cvar_PowerRiot)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the client a riot shield, and changes everybody's health to 1
			PowerRiot(client);

			// 
			PrintToChatAll("Power Riot - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}

	// If the cvar for the vampire power is enabled then execute this section
	if(cvar_PowerVampire)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the client a the ability to leech a percentage of health from the enemy he attacks
			PowerVampire();

			// 
			PrintToChatAll("Power Vampire - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}

	// If the cvar for the breachcharges power is enabled then execute this section
	if(cvar_PowerBreachCharges)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the client a large stack of breachcharges to plant and detonate
			PowerBreachCharges(client);

			// 
			PrintToChatAll("Power Breachcharges - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}

	// If the cvar for the leg crushing bumpmines power is enabled then execute this section
	if(cvar_PowerLegCrushingBumpmines)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the client a large stack of bumpmines, and causes all fall damage taken by enemies to be dealt by the king 
			PowerLegCrushingBumpmines(client);

			// 
			PrintToChatAll("Power Leg Crushing Bumpmines - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}

	// If the cvar for the hatchet massacre power is enabled then execute this section
	if(cvar_PowerHatchetMassacre)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the client an axe that deals additional damage, and applies blood to the victim's screen 
			PowerHatchetMassacre(client);

			// 
			PrintToChatAll("Power Hatchet Massacre - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}


	// If the cvar for the chuck norris fists power is enabled then execute this section
	if(cvar_PowerChuckNorrisFists)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the client a pair of fists that deals high damage 
			PowerChuckNorrisFists(client);

			// 
			PrintToChatAll("Power Chuck Norris Fists - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}

	// If the cvar for the laser gun power is enabled then execute this section
	if(cvar_PowerLaserGun)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the client a cz-auto which deals 3, 4 or 5 damage with no recoil and unlimited ammo that shoots lasers 
			PowerLaserGun(client);

			// 
			PrintToChatAll("Power Laser Gun Fists - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}

	// If the cvar for the lucky number seven power is enabled then execute this section
	if(cvar_PowerLuckyNumberSeven)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// When attacking an enemy two dices will be rolled and if the number is 7 then the king deals bonus damage 
			PowerLuckyNumberSeven(client);

			// 
			PrintToChatAll("Power Laser Gun Fists - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}

	// If the cvar for the western shootout power is enabled then execute this section
	if(cvar_PowerWesternShootout)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the king a revolver that always deals 50 damage, only contains 2 bullets and cannot use secondary attacks
			PowerWesternShootout(client);

			// 
			PrintToChatAll("Power Western Shootout - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}


	// If the cvar for the Babonic Plague power is enabled then execute this section
	if(cvar_PowerBabonicPlague)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// When the king attacks an enemy they will take damage over time and have their vision distorted
			PowerBabonicPlague(client);

			// 
			PrintToChatAll("Power Babonic Plague - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}


	// If the cvar for the Zombie Apocalypse power is enabled then execute this section
	if(cvar_PowerZombieApocalypse)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Turns the king's team in to zombies, increasing their health but slows them down, changes the skies and ambience sounds
			PowerZombieApocalypse(client);

			// 
			PrintToChatAll("Power Zombie Apocalypse - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}


	// If the cvar for the Blast Cannon power is enabled then execute this section
	if(cvar_PowerBlastCannon)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the client a shotgun that deals reduced damage but pushed people back
			PowerBlastCannon(client);

			// 
			PrintToChatAll("Power Blast Cannon - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}


	// If the cvar for the Deagle Headshot power is enabled then execute this section
	if(cvar_PowerDeagleHeadshot)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the client a desert eagle that can only deal damage when hitting the enemy's head
			PowerDeagleHeadshot(client);

			// 
			PrintToChatAll("Power Deagle Headshot - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}


	// If the cvar for the Laser Pointer power is enabled then execute this section
	if(cvar_PowerLaserPointer)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the client the ability to press E and deal damage using a laser pointer when hovering over other players
			PowerLaserPointer(client);

			// 
			PrintToChatAll("Power Laser Pointer - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}


	// If the cvar for the Hammer Time power is enabled then execute this section
	if(cvar_PowerHammerTime)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// Gives the client a hammer, and attacking enemies will knock them in to the ground
			PowerHammerTime(client);

			// 
			PrintToChatAll("Power Hammer Time - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}


	// If the cvar for the doom Doom Chickens is enabled then execute this section
	if(cvar_PowerDoomChickens)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;

		PrintToChatAll("Debug Power - PA %i | C %i", powersAvailable, chosenPower);

		// If the value contained within chosenPower is the same as the value stored in powersAvailable then execute this section
		if(chosenPower == powersAvailable)
		{
			// When a player dies they will spawn a chicken that deals damage and explodes
			PowerDoomChickens(client);

			// 
			PrintToChatAll("Power Doom Chickens - [ %i | %i ]", chosenPower, powersAvailable);
		}
	}

	// Plays the sound file that is specific to that of the newly acquired power
	CreateTimer(2.0, Timer_PlayPowerSpecificSound, client);

	// Changes the power acquisition state to 2 to make the hud display the newly acquired power to the king
	CreateTimer(2.0, Timer_InitializePowerAcquisition, client);

	// Changes the power acquisition state back to 0 to make the hud show the normal information to the king again
	CreateTimer(6.0, Timer_FinalizePowerAcquisition, client);

	return Plugin_Continue;
}


// This happens when a new king has been chosen and he is about to receive a unique power
public int countAvailablePowers()
{
	// Creates a variable called powersAvailable and set it to 0
	int powersAvailable = 0;

	// If the cvar for the impregnable armor power is enabled then execute this section
	if(cvar_PowerImpregnableArmor)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the Movement Speed power is enabled then execute this section
	if(cvar_PowerMovementSpeed)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the sticky grenades power is enabled then execute this section
	if(cvar_PowerStickyGrenades)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the scout no scope power is enabled then execute this section
	if(cvar_PowerScoutNoScope)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the carpet bombing flashbangs power is enabled then execute this section
	if(cvar_PowerCarpetBombingFlashbangs)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the napalm power is enabled then execute this section
	if(cvar_PowerNapalm)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the riot power is enabled then execute this section
	if(cvar_PowerRiot)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the vampire power is enabled then execute this section
	if(cvar_PowerVampire)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the breachcharges power is enabled then execute this section
	if(cvar_PowerBreachCharges)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the leg crushing bumpmines power is enabled then execute this section
	if(cvar_PowerLegCrushingBumpmines)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the hatchet massacre power is enabled then execute this section
	if(cvar_PowerHatchetMassacre)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the chuck norris fists power is enabled then execute this section
	if(cvar_PowerChuckNorrisFists)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the laser gun power is enabled then execute this section
	if(cvar_PowerLaserGun)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the lucky number seven power is enabled then execute this section
	if(cvar_PowerLuckyNumberSeven)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the western shootout power is enabled then execute this section
	if(cvar_PowerWesternShootout)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the Babonic Plague power is enabled then execute this section
	if(cvar_PowerBabonicPlague)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the Zombie Apocalypse power is enabled then execute this section
	if(cvar_PowerZombieApocalypse)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}


	// If the cvar for the Blast Cannon power is enabled then execute this section
	if(cvar_PowerBlastCannon)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the Deagle Headshot power is enabled then execute this section
	if(cvar_PowerDeagleHeadshot)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the Laser Pointer power is enabled then execute this section
	if(cvar_PowerLaserPointer)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the Hammer Time power is enabled then execute this section
	if(cvar_PowerHammerTime)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// If the cvar for the doom Doom Chickens is enabled then execute this section
	if(cvar_PowerDoomChickens)
	{
		// Adds +1 to the current value of the powersAvailable variable
		powersAvailable++;
	}

	// Returns the value of our powersAvailable variable
	return powersAvailable;
}


// This happens when a king is about to receive a new power and when a round starts
public void ResetPreviousPower()
{
	// Changes the unique weapon the king will receive to be nothing
	kingWeapon = "";

	// If the currently active power is sticky grenades then execute this section
	if(powerStickyGrenades)
	{
		// Disables the sticky grenade power
		powerStickyGrenades = false;
	}

	// If the currently active power is impregnable armor then execute this section
	if(powerImpregnableArmor)
	{
		// Turns off the impregnable armor king power 
		powerImpregnableArmor = 0;
	}

	// If the currently active power is movement speed then execute this section
	if(powerMovementSpeed)
	{
		// Turns off the movement speed king power 
		powerMovementSpeed = 0;
	}

	// If the currently active power is scout no scope then execute this section
	if(powerScoutNoScope)
	{
		// Turns off the scout no scope king power 
		powerScoutNoScope = false;
	}

	// If the currently active power is carpet bombing flashbangs then execute this section
	if(powerCarpetBombingFlashbangs)
	{
		// Turns off the carpet bombing flashbangs king power 
		powerCarpetBombingFlashbangs = 0;
	}

	// If the currently active power is napalm then execute this section
	if(powerNapalm)
	{
		// Turns off the napalm king power 
		powerNapalm = false;
	}

	// If the currently active power is riot then execute this section
	if(powerRiot)
	{
		// Turns off the riot king power 
		powerRiot = false;
	}

	// If the currently active power is vampire then execute this section
	if(powerVampire)
	{
		// Turns off the Vampire power 
		powerVampire = 0;
	}

	// If the currently active power is breachcharges then execute this section
	if(powerBreachCharges)
	{
		// Turns off the breachcharge power 
		powerBreachCharges = 0;
	}

	// If the currently active power is leg crushing bumpmines then execute this section
	if(powerLegCrushingBumpmines)
	{
		// Turns off the leg crushing bumpmines power 
		powerLegCrushingBumpmines = 0;
	}

	// If the currently active power is hatchet massacre then execute this section
	if(powerHatchetMassacre)
	{
		// Turns off the hatchet massacre king power 
		powerHatchetMassacre = false;
	}

	// If the currently active power is chuck norris fists then execute this section
	if(powerChuckNorris)
	{
		// Turns off the chuck norris fists king power 
		powerChuckNorris = false;
	}
	
	// If the currently active power is laser gun then execute this section
	if(powerLaserGun)
	{
		// Removes the no-recoil and no-spread and restore the default accuracy settings
		PowerLaserGunEnableRecoil();

		// Turns off the laser gun power 
		powerLaserGun = 0;
	}

	// If the currently active power is Lucky Number Seven then execute this section
	if(powerLuckyNumberSeven)
	{
		// Turns off the lucky number seven king power 
		powerLuckyNumberSeven = false;
	}

	// If the currently active power is western shootout then execute this section
	if(powerWesternShootout)
	{
		// Turns off the western shootoutn king power 
		powerWesternShootout = false;
	}

	// If the currently active power is babonic plague then execute this section
	if(powerBabonicPlague)
	{
		// Removes the babonic plague infection from all currently infected players
		ResetBabonicPlague();

		// Turns off the babonic plague power 
		powerBabonicPlague = 0;
	}

	// If the currently active power is Zombie Apocalypse then execute this section
	if(powerZombieApocalypse)
	{
		// Removes the zombie apocalypse setting and effects from all players
		PowerZombieApocalypseRemove();

		// Turns off the zombie apocalypse power 
		powerZombieApocalypse = false;
	}

	// If the cvar for the Blast Cannon power is enabled then execute this section
	if(powerBlastCannon)
	{
		// Turns off the blast cannon king power 
		powerBlastCannon = false;
	}

	// If the cvar for the Deagle Headshot power is enabled then execute this section
	if(powerDeagleHeadshot)
	{
		// Turns off the deagle headshot king power 
		powerDeagleHeadshot = false;
	}

	// If the cvar for the Laser Pointer power is enabled then execute this section
	if(powerLaserPointer)
	{
		// Turns off the laser pointer king power 
		powerLaserPointer = false;
	}

	// If the cvar for the Hammer Time power is enabled then execute this section
	if(powerHammerTime)
	{
		// Lifts the buried cooldown from all the players
		RemoveAllBuryCooldowns();

		// Turns off the hammer time king power 
		powerHammerTime = false;
	}

	// If the cvar for the doom Doom Chickens is enabled then execute this section
	if(powerDoomChickens)
	{
		// Turns off the doom chickens king power 
		powerDoomChickens = false;

		// Removes all the chicken entitites from the map
		DestroyChickenEntities();
	}
}


// This happens 0.25 second after a player becomes the king
public Action Timer_GiveKingUniqueWeapon(Handle timer, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	if(StrEqual(kingWeapon, "", false))
	{
		return Plugin_Continue;
	}

	// Gives the client the specified weapon and store it within the kingWeaponIndex variable
	int kingWeaponIndex = GivePlayerItem(client, kingWeapon);

	// If the currently active power is sticky grenades then execute this section
	if(powerStickyGrenades)
	{
		// Changes the player's amount of high explosive grenades to 10
		SetEntProp(client, Prop_Send, "m_iAmmo", 10, _, 14);
	}

	// If the currently active power is carpet bombing flashbangs then execute this section
	if(powerCarpetBombingFlashbangs)
	{
		// Changes the player's amount of flashbangs to 25
		SetEntProp(client, Prop_Send, "m_iAmmo", 25, _, 15);
	}

	// If the currently active power is napalm then execute this section
	if(powerNapalm)
	{
		// Changes the player's amount of molotovs to 25
		SetEntProp(client, Prop_Send, "m_iAmmo", 10, _, 17);
	}

	// If the currently active power is breachcharges then execute this section
	if(powerBreachCharges)
	{
		// Creates a variable which we will store data within
		int breachChargesAmmo = 0;

		// If the powerBreachCharges is 1 then execute this section
		if(powerBreachCharges == 1)
		{
			// Changes the value of our breachChargesAmmo variable 
			breachChargesAmmo = 18;
		}

		// If the powerBreachCharges is 2 then execute this section
		if(powerBreachCharges == 2)
		{
			// Changes the value of our breachChargesAmmo variable 
			breachChargesAmmo = 15;
		}

		// If the powerBreachCharges is 3 then execute this section
		if(powerBreachCharges == 3)
		{
			// Changes the value of our breachChargesAmmo variable 
			breachChargesAmmo = 12;
		}

		// If the king's weapon does not match our validation criteria then execute this section
		if(!IsValidEntity(kingWeaponIndex))
		{
			return Plugin_Continue;
		}

		// Changes the "clip" of the breachcharge stack to value stored within our breachChargesAmmo
		SetEntData(kingWeaponIndex, 2420, breachChargesAmmo, 4, true);
	}

	// If the currently active power is breachcharges then execute this section
	if(powerLegCrushingBumpmines)
	{
		// Creates a variable which we will store data within
		int bumpMinesAmmo = 0;

		// If the powerLegCrushingBumpmines is 1 then execute this section
		if(powerLegCrushingBumpmines == 1)
		{
			// Changes the value of our bumpMinesAmmo variable 
			bumpMinesAmmo = 18;
		}

		// If the powerLegCrushingBumpmines is 2 then execute this section
		if(powerLegCrushingBumpmines == 2)
		{
			// Changes the value of our bumpMinesAmmo variable 
			bumpMinesAmmo = 15;
		}

		// If the powerLegCrushingBumpmines is 3 then execute this section
		if(powerLegCrushingBumpmines == 3)
		{
			// Changes the value of our bumpMinesAmmo variable 
			bumpMinesAmmo = 12;
		}

		// If the king's weapon does not match our validation criteria then execute this section
		if(!IsValidEntity(kingWeaponIndex))
		{
			return Plugin_Continue;
		}

		// Changes the "clip" of the bumpmine stack to value stored within our bumpMinesAmmo
		SetEntData(kingWeaponIndex, 2420, bumpMinesAmmo, 4, true);
	}

	return Plugin_Continue;
}


// This happens when the round starts
public void RemoveKingPowerEffects()
{
	// If the cvar_KingPowerChooser is not enabled then execute this section
	if(!cvar_KingPowerChooser)
	{
		return;
	}

	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// If the client is not a bot then execute this section
		if(IsFakeClient(client))
		{
			continue;
		}

		// If the currently active power is impregnable armor then execute this section
		if(powerImpregnableArmor)
		{
			// Removes the screen overlay from the player
			RemoveScreenOverlay(client);
		}

		// If the currently active power is babonic plague then execute this section
		if(powerBabonicPlague)
		{
			// Removes the screen overlay from the player
			RemoveScreenOverlay(client);
		}

		// Resets the client's inferno stacks back to 0 if the active powr is napalm 
		ResetNapalmStacks(client);
	}
}


// This happens 2.0 seconds after a player becomes the king and is about to acquire a new power
public Action Timer_PlayPowerSpecificSound(Handle timer, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the client is not the king then execute this section
	if(!isPlayerKing[client])
	{
		return Plugin_Continue;
	}

	// If the king is a bot then execute this section
	if(IsFakeClient(client))
	{
		return Plugin_Continue;
	}

	// If the sound is not already precached then execute this section
	if(!IsSoundPrecached(powerSoundName))
	{
		// Precaches the sound file
		PrecacheSound(powerSoundName, true);
	}

	// Emits a sound to the specified client that only they can hear
	EmitSoundToClient(client, powerSoundName, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.00, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	
	return Plugin_Continue;
}


// This happens 2.5 seconds after a player becomes the king and is about to acquire a new power
public Action Timer_InitializePowerAcquisition(Handle timer, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the client is not the king then execute this section
	if(!isPlayerKing[client])
	{
		return Plugin_Continue;
	}

	// If the king is a bot then execute this section
	if(IsFakeClient(client))
	{
		return Plugin_Continue;
	}

	// Changes the kingIsAcquiringPower to 2 to indicate that the king is has acquired his power
	kingIsAcquiringPower = 2;

	// Calls upon the Timer_UpdateTeamScoreHud function to update the HUD
	CreateTimer(0.0, Timer_UpdateTeamScoreHud, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}


// This happens 5.5 seconds after a player becomes the king and is about to acquire a new power
public Action Timer_FinalizePowerAcquisition(Handle timer, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the client is not the king then execute this section
	if(!isPlayerKing[client])
	{
		return Plugin_Continue;
	}

	// If the king is a bot then execute this section
	if(IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	
	// Changes the kingIsAcquiringPower to 0 to indicate that the king has finished the acquiring power part
	kingIsAcquiringPower = 0;

	// Calls upon the Timer_UpdateTeamScoreHud function to update the HUD
	CreateTimer(0.0, Timer_UpdateTeamScoreHud, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}



/////////////////////////////////
// - Power Impregnable Armor - //
/////////////////////////////////


// This happens when a king acquires the impregnable armor power
public void PowerImpregnableArmor(int client)
{
	// If the king is not a bot then execute this section
	if(!IsFakeClient(client))
	{
		// Applies a screen overlay to the player
		ClientCommand(client, "r_screenoverlay kingmod/overlays/power_impregnablearmor.vmt");

		// If the sound is not already precached then execute this section
		if(!IsSoundPrecached("items/nvg_on.wav"))
		{	
			// Precaches the sound file
			PrecacheSound("items/nvg_on.wav", true);
		}

		// Emits a sound to the specified client that only they can hear
		EmitSoundToClient(client, "items/nvg_on.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.00, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}

	// If the Phoenix heavy assault suit player model is not precached already then execute this section
	if(!IsModelPrecached("models/player/custom_player/legacy/tm_phoenix_heavy.mdl"))
	{
		// Precaches the phoenix heavy assault suit player model
		PrecacheModel("models/player/custom_player/legacy/tm_phoenix_heavy.mdl");
	}

	// If the phoenix heavy assault suit sleeve & glove model is not precached already then execute this section
	if(!IsModelPrecached("models/weapons/v_models/arms/phoenix_heavy/v_sleeve_phoenix_heavy.mdl"))
	{
		// Precaches the phoneix heavy assault suit sleeve & glove model
		PrecacheModel("models/weapons/v_models/arms/phoenix_heavy/v_sleeve_phoenix_heavy.mdl");
	}

	// Gives the king a heavy assault suit
	GivePlayerItem(client, "item_heavyassaultsuit");

	// Changes the player's player model to match the assault suit model
	SetEntityModel(client, "models/player/custom_player/legacy/tm_phoenix_heavy.mdl");

	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_impregnablearmor.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "----------------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Impregnable Armor";

	// Turns on the impregnable armor king power 
	powerImpregnableArmor = GetRandomInt(1, 3);

	// If the value stored within the powerImpregnableArmor is 1 execute this section
	if(powerImpregnableArmor == 1)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier A";

		// Changes the armor value of the client to 200
		SetEntProp(client, Prop_Data, "m_ArmorValue", 200);
	}

	// If the value stored within the powerImpregnableArmor is 2 execute this section
	if(powerImpregnableArmor == 2)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier B";

		// Changes the armor value of the client to 165
		SetEntProp(client, Prop_Data, "m_ArmorValue", 165);
	}

	// If the value stored within the powerImpregnableArmor is 3 execute this section
	if(powerImpregnableArmor == 3)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier C";

		// Changes the armor value of the client to 130
		SetEntProp(client, Prop_Data, "m_ArmorValue", 130);
	}
}


// This happens when a player spawns or when the king dies
public void RemoveScreenOverlay(int client)
{
	// Removes the screen overlay from the client
	ClientCommand(client, "r_screenoverlay 0");
}



//////////////////////////////
// - Movement Speed Power - //
//////////////////////////////


// This happens when a king acquires the movement speed power 
public void PowerMovementSpeed()
{
	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_movementspeed.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "-------------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Movement Speed";
	
	// Turns on the movement speed king power 
	powerMovementSpeed = GetRandomInt(1, 3);

	// If the value stored within the powerMovementSpeed is 1 execute this section
	if(powerMovementSpeed == 1)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier A";
	}

	// If the value stored within the powerMovementSpeed is 2 execute this section
	else if(powerMovementSpeed == 2)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier B";
	}

	// If the value stored within the powerMovementSpeed is 3 execute this section
	else if(powerMovementSpeed == 3)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier C";
	}

	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// If the value stored within the powerMovementSpeed is 1 execute this section
		if(powerMovementSpeed == 1)
		{
			// Changes the movement speed of the player to 200% of the normal movement speed
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.80);
		}

		// If the value stored within the powerMovementSpeed is 2 execute this section
		else if(powerMovementSpeed == 2)
		{
			// Changes the movement speed of the player to 175% of the normal movement speed
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.60);
		}

		// If the value stored within the powerMovementSpeed is 3 execute this section
		else if(powerMovementSpeed == 3)
		{
			// Changes the movement speed of the player to 150% of the normal movement speed
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.40);
		}
	}
}


// This happens when the movement speed power is no longer active
public void RemovePowerMovementSpeed()
{
	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// If the value stored within the powerMovementSpeed is 0 execute this section
		if(powerMovementSpeed == 0)
		{
			// Changes the movement speed of the player to 200% of the normal movement speed
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.00);
		}
	}
}


// Changes the player's movement speed upon spawning if the movement speed power is active
public void PowerMovementSpeedSpawn(int client)
{
	// If the value stored within the powerMovementSpeed is 1 execute this section
	if(powerMovementSpeed == 1)
	{
		// Changes the movement speed of the player to 200% of the normal movement speed
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.80);
	}

	// If the value stored within the powerMovementSpeed is 2 execute this section
	else if(powerMovementSpeed == 2)
	{
		// Changes the movement speed of the player to 175% of the normal movement speed
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.60);
	}

	// If the value stored within the powerMovementSpeed is 3 execute this section
	else if(powerMovementSpeed == 3)
	{
		// Changes the movement speed of the player to 150% of the normal movement speed
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.40);
	}
}



///////////////////////////
// - Power Sticky Nade - //
///////////////////////////


// This happens when a king acquires the sticky grenade power
public void PowerStickyGrenades(int client)
{
	// Turns on the sticky grenade king power 
	powerStickyGrenades = true;

	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_stickynades.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "------------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Sticky Grenades";
	
	// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
	nameOfTier = "Tier A";
	
	// Specifies which special weapon the king should be given
	kingWeapon = "weapon_hegrenade";

	// Gives the king a unique weapon if the current power requires one
	CreateTimer(0.25, Timer_GiveKingUniqueWeapon, client);
}


// This happens when a new entity is created
public void OnEntityCreated(int entity, const char[] classname)
{
	// If the king's current power is the sticky grenades power then execute this section
	if(powerStickyGrenades)
	{
		// If the entity that was created is not a high explosive grenade projectile then execute this section
		if(!StrEqual(classname, "hegrenade_projectile", false))
		{
			return;
		}

		// Adds a hook to the high explosive grenade after it has been spawned allowing us to alter the grenade's behavior
		SDKHook(entity, SDKHook_SpawnPost, entity_HEGrenadeSpawned);
	}

	// If the king's current power is the carpet bombing flashbang power then execute this section
	if(powerCarpetBombingFlashbangs)
	{
		// If the entity that was created is not a flashbang projectile then execute this section
		if(!StrEqual(classname, "flashbang_projectile", false))
		{
			return;
		}

		// Adds a hook to the flashbange after it has been spawned allowing us to alter the flashbang's behavior
		SDKHook(entity, SDKHook_SpawnPost, entity_FlashbangSpawned);
	}


	// If the currently active power is western shootout then execute this section
	if(powerWesternShootout)
	{
		// If the entity that was created is not a deagle then execute this section
		if(!StrEqual(classname, "weapon_deagle", false))
		{
			return;
		}

		// Adds a hook to the revolver after it has been spawned allowing us to alter the revolver's behavior
		SDKHook(entity, SDKHook_SpawnPost, entity_RevolverSpawned);
	}


	// If the currently active power is Deagle Headshot then execute this section
	if(powerDeagleHeadshot)
	{
		// If the entity that was created is not a deagle then execute this section
		if(!StrEqual(classname, "weapon_deagle", false))
		{
			return;
		}

		// Adds a hook to the deagle after it has been spawned allowing us to alter the deagle's behavior
		SDKHook(entity, SDKHook_SpawnPost, entity_DeagleSpawned);
	}
}


// This happens when a high explosive grenade projectile has been spawned
public Action entity_HEGrenadeSpawned(int entity)
{
	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Obtains and stores the entity owner offset within our client variable 
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the client is not the king then execute this section
	if(!isPlayerKing[client])
	{
		return Plugin_Continue;
	}

	// Changes the maximum damage dealt by the grenade to 120
	SetEntPropFloat(entity, Prop_Data, "m_flDamage", 120.0);

	// Adds a hook to our grenade entity to notify of us when the grenade will touch something
	SDKHook(entity, SDKHook_StartTouch, OnStartTouchHEGrenade);

	return Plugin_Continue;
}


// This happens when a high explosive grenade touches something while a king possesses the sticky grenade power
public Action OnStartTouchHEGrenade(int entity, int client)
{
	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// If the client meets our validation criteria then execute this section
	if(IsValidClient(client))
	{
		// Changes the collisiongroup of the high explosive grenade
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);

		// Changes the maximum damage dealt by the grenade to 500
		SetEntPropFloat(entity, Prop_Data, "m_flDamage", 500.0);

		// Changes the size of the entity
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 4.50);

		// Changes the entity's move type to be none making it immobile
		SetEntityMoveType(entity, MOVETYPE_NONE);

		// Changes the variantstring to !activator
		SetVariantString("!activator");
		
		// Changes the parent of entity to that of the player that was struck by the grenade
		AcceptEntityInput(entity, "SetParent", client);

		// Obtains and stores the entity owner's index within our entityOwner variable
		int entityOwner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

		// If the entityOwner does not meet our validation criteria then execute this section
		if(!IsValidClient(entityOwner))
		{
			return Plugin_Continue;
		}

		// If the sound is not already precached then execute this section
		if(!IsSoundPrecached("kingmod/oh_shit.mp3"))
		{	
			// Precaches the sound file
			PrecacheSound("kingmod/oh_shit.mp3", true);
		}

		// Emits a sound to the specified client that only they can hear
		EmitSoundToClient(client, "kingmod/oh_shit.mp3", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.00, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		
		// Emits a sound to the specified client that only they can hear
		EmitSoundToClient(entityOwner, "kingmod/oh_shit.mp3", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.00, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}

	else if(GetEntityMoveType(entity) != MOVETYPE_NONE)
	{
		// Changes the entity's move type to be none making it immobile
		SetEntityMoveType(entity, MOVETYPE_NONE);
	}

	// Removes the hook that we had attached to the grenade
	SDKUnhook(entity, SDKHook_StartTouch, OnStartTouchHEGrenade);

	return Plugin_Continue;
}


// This happens when a player uses the left attack with their knife or weapon
public Action WeaponFireStickyGrenades(int client)
{
	// If the king's current power is not the sticky grenades power then execute this section
	if(!powerStickyGrenades)
	{
		return Plugin_Continue;
	}

	// Obtains the name of the player's weapon and store it within our variable entity
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Creates a variable which we will use to store data within
	char className[64];

	// Obtains the entity's class name and store it within our className variable
	GetEntityClassname(entity, className, sizeof(className));

	// If the entity is not a high explosive grenade then execute this section
	if(!StrEqual(className, "weapon_hegrenade", false))
	{
		return Plugin_Continue;
	}

	// Gives the client the specified weapon
	GivePlayerItem(client, "weapon_hegrenade");

	// Changes the player's amount of high explosive grenades to 10
	SetEntProp(client, Prop_Send, "m_iAmmo", 10, _, 14);

	return Plugin_Continue;
}



//////////////////////////////
// - Power Scout No Scope - //
//////////////////////////////


// This happens when a king acquires the scout no scope power
public void PowerScoutNoScope(int client)
{
	// Turns on the scout no scope king power 
	powerScoutNoScope = true;

	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_scoutnoscope.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "------------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Scout No Scope";
	
	// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
	nameOfTier = "Tier A";
	
	// Specifies which special weapon the king should be given
	kingWeapon = "weapon_ssg08";

	// Gives the king a unique weapon if the current power requires one
	CreateTimer(0.25, Timer_GiveKingUniqueWeapon, client);
}


// This happens every game tick
public Action OnPreThink(int client)
{
	// If the cvar_KingPowerChooser is not enabled then execute this section
	if(!cvar_KingPowerChooser)
	{
		return Plugin_Continue;
	}

	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the client is not the king then execute this section
	if(!isPlayerKing[client])
	{
		return Plugin_Continue;
	}

	// If the king's current power is the scout no scope or western shootout power then execute this section
	if(powerScoutNoScope || powerWesternShootout)
	{
		// Prevents the player from using their secondary attack
		PreventSecondaryAttack(client);
	}

	return Plugin_Continue;
}


// This happens when the king tries to use the scope or secondary attack while no scope power or western shootout power is active
public Action PreventSecondaryAttack(int client)
{
	// Obtains the name of the player's weapon and store it within our variable entity
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Creates a variable to store our data within
	char classname[32];

	// Obtains the classname of the entity and store it within our classname variable
	GetEdictClassname(entity, classname, sizeof(classname));

	// If the entity is not a ssg08 or revolver then execute this section
	if(!StrEqual(classname, "weapon_ssg08") && !StrEqual(classname, "weapon_deagle"))
	{
		return Plugin_Continue;
	}

	// Adds 2.0 seconds cooldown to when the player would be able to use the secondary attack / zoom function 
	SetEntDataFloat(entity, FindSendPropOffs("CBaseCombatWeapon", "m_flNextSecondaryAttack"), GetGameTime() + 2.0);

	return Plugin_Continue;
}



/////////////////////////////////////////
// - Power Carpet Bombing Flashbangs - //
/////////////////////////////////////////


// This happens when a king acquires the carpet bombing flashbangs power 
public void PowerCarpetBombingFlashbangs(int client)
{
	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_carpetbombingflashbangs.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "---------------------------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Carpet Bombing Flashbangs";
	
	// Specifies which special weapon the king should be given
	kingWeapon = "weapon_flashbang";

	// Gives the king a unique weapon if the current power requires one
	CreateTimer(0.25, Timer_GiveKingUniqueWeapon, client);

	// Turns on the power Carpet Bombing Flashbangs king power 
	powerCarpetBombingFlashbangs = GetRandomInt(1, 3);

	// If the value stored within the powerCarpetBombingFlashbangs is 1 execute this section
	if(powerCarpetBombingFlashbangs == 1)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier A";
	}

	// If the value stored within the powerCarpetBombingFlashbangs is 2 execute this section
	else if(powerCarpetBombingFlashbangs == 2)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier B";
	}

	// If the value stored within the powerCarpetBombingFlashbangs is 3 execute this section
	else if(powerCarpetBombingFlashbangs == 3)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier C";
	}
}


// This happens when a player uses the left attack with their knife or weapon
public Action WeaponFireCarpetBombingFlashbang(int client)
{
	// If the king's current power is not the carpet bombing flashbang power then execute this section
	if(!powerCarpetBombingFlashbangs)
	{
		return Plugin_Continue;
	}

	// Obtains the name of the player's weapon and store it within our variable entity
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Creates a variable which we will use to store data within
	char className[64];

	// Obtains the entity's class name and store it within our className variable
	GetEntityClassname(entity, className, sizeof(className));

	// If the entity is not a flashbang then execute this section
	if(!StrEqual(className, "weapon_flashbang", false))
	{
		return Plugin_Continue;
	}

	// Gives the client the specified weapon
	GivePlayerItem(client, "weapon_flashbang");

	// Changes the player's amount of flashbangs to 25
	SetEntProp(client, Prop_Send, "m_iAmmo", 25, _, 15);

	// Throws another flashbang after 0.1 seconds has passed
	CreateTimer(0.1, Timer_DuplicateFlashbangEntity, client, TIMER_FLAG_NO_MAPCHANGE);

	// Throws another flashbang after 0.2 seconds has passed
	CreateTimer(0.2, Timer_DuplicateFlashbangEntity, client, TIMER_FLAG_NO_MAPCHANGE);

	// If the value stored within the powerCarpetBombingFlashbangs is 1 execute this section
	if(powerCarpetBombingFlashbangs == 1)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier A";

		// Throws another flashbang after 0.3 seconds has passed
		CreateTimer(0.3, Timer_DuplicateFlashbangEntity, client, TIMER_FLAG_NO_MAPCHANGE);

		// Throws another flashbang after 0.4 seconds has passed
		CreateTimer(0.4, Timer_DuplicateFlashbangEntity, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	// If the value stored within the powerCarpetBombingFlashbangs is 2 execute this section
	else if(powerCarpetBombingFlashbangs == 2)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier B";

		// Throws another flashbang after 0.3 seconds has passed
		CreateTimer(0.3, Timer_DuplicateFlashbangEntity, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	// If the value stored within the powerCarpetBombingFlashbangs is 3 execute this section
	else if(powerCarpetBombingFlashbangs == 3)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier C";
	}

	return Plugin_Continue;
}


// This happens anywhere between 0.1 to 0.4 seconds after a player throws a flashbang
public Action Timer_DuplicateFlashbangEntity(Handle timer, int client)
{
	// If the king's current power is not the carpet bombing flashbang power then execute this section
	if(!powerCarpetBombingFlashbangs)
	{
		return Plugin_Continue;
	}

	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Obtains the client's active weapon and store it within the variable: entity
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	// If the entity that was picked up our entity criteria of validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Changes the throw time of the grenade to 1.0 to reset the thrown grenade
	SetEntPropFloat(entity, Prop_Send, "m_fThrowTime", 1.0);

	return Plugin_Continue;
}


// This happens when a flashbang projectile has been spawned
public Action entity_FlashbangSpawned(int entity)
{
	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Throws another flashbang after 1.0 seconds has passed
	CreateTimer(1.0, Timer_RemoveFlashBangEntity, entity, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}


// This happens 1.0 seconds after a flashbang has been thrown
public Action Timer_RemoveFlashBangEntity(Handle timer, int entity)
{
	// If the entity that was picked up our entity criteria of validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Kills the entity, removing it from the game
	AcceptEntityInput(entity, "Kill");

	return Plugin_Continue;
}


// This happens when the player takes damage
public Action OnDamageTaken(int client, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	// If the cvar_KingPowerChooser is not enabled then execute this section
	if(!cvar_KingPowerChooser)
	{
		return Plugin_Continue;
	}

	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the currently active power is the leg crushing bumpmines then execute this section
	if(powerLegCrushingBumpmines)
	{
		// If the type of damage taken is fall damage then execute this section
		if(damagetype & DMG_FALL)
		{
			return Plugin_Handled;
		}
	}

	// If the attacker does not meet our validation criteria then execute this section
	if(!IsValidClient(attacker))
	{
		return Plugin_Continue;
	}

	// If the inflictor is not a valid entity then execute this section
	if(!IsValidEntity(inflictor))
	{
		return Plugin_Continue;
	}

	// If the victim and attacker is on the same team
	if(GetClientTeam(client) == GetClientTeam(attacker))
	{
		return Plugin_Continue;
	}

	// If the attacker is not the current king then execute this section
	if(!isPlayerKing[attacker])
	{
		return Plugin_Continue;
	}

	// If the king's current power is not the vampire power then execute this section
	if(powerVampire)
	{
		// Creates a variable which we will store data within
		float leechedHealth = 0.0;

		// If the value stored within the powerVampire is 1 execute this section
		if(powerVampire == 1)
		{
			// Obtains the damage dealt and multiply it by 0.50 and store the result within the leechedhealth variable
			leechedHealth = damage * 0.50;
		}

		// If the value stored within the powerVampire is 2 execute this section
		else if(powerVampire == 2)
		{
			// Obtains the damage dealt and multiply it by 0.425 and store the result within the leechedhealth variable
			leechedHealth = damage * 0.425;
		}

		// If the value stored within the powerVampire is 3 execute this section
		else if(powerVampire == 3)
		{
			// Obtains the damage dealt and multiply it by 0.35 and store the result within the leechedhealth variable
			leechedHealth = damage * 0.35;
		}

		// Obtains the attacker's current health and the leeched health and store the total value within the playerhealth variable
		int playerHealth = GetEntProp(attacker, Prop_Send, "m_iHealth") + RoundToFloor(leechedHealth);

		// If the attacker's health plus the leeched amount is larger than (200 default) then execute this section
		if(playerHealth > cvar_KingHealth)
		{
			// Changes the health of the attacker to (200 default)
			SetEntProp(attacker, Prop_Send, "m_iHealth", cvar_KingHealth, 1);
		}

		// If the attacker's health plus the lehced amount is not larger than (200 default) then execute this section
		else
		{
			// Changes the health of the attacker to the  value stored within the playerHealth variable
			SetEntProp(attacker, Prop_Send, "m_iHealth", playerHealth, 1);
		}

		PrintToChat(attacker, "Kingmod You leeched %i health from your enemy", RoundToFloor(leechedHealth));
	}

	// Creates a variable to store our data within
	char classname[64];

	// Obtains the classname of the inflictor entity and store it within our classname variable
	GetEdictClassname(inflictor, classname, sizeof(classname));

	// If the king's current power is not the carpet bombing flashbang power then execute this section
	if(powerCarpetBombingFlashbangs)
	{
		// If the inflictor entity is a flashbang projectile then execute this section
		if(StrEqual(classname, "flashbang_projectile", false))
		{
			// Changes the amount of damage to 1337
			damage = 1337.0;

			return Plugin_Changed;
		}
	}

	// If the king's current power is not the napalm power then execute this section
	if(powerNapalm)
	{
		// If the inflictor entity is the fire left behind a molotov or inccendiary grenade then execute this section
		if(StrEqual(classname, "inferno", false))
		{
			// If the molotov's fire have damaged the player 4 times or less then execute this section
			if(powerNapalmDamageTaken[client] <= 4)
			{
				// Adds +1 to the powerNapalmDamageTaken variable
				powerNapalmDamageTaken[client]++;

				return Plugin_Continue;
			}

			// if the molotov's fire have damaged the player 5 times then execute this section
			else if(powerNapalmDamageTaken[client] == 5)
			{
				// Sets the player on fire for 60 seconds
				IgniteEntity(client, 60.0);
			}
		}
	}

	// If the currently active power is hatchet massacre then execute this section
	if(powerHatchetMassacre)
	{
		// If the inflictor entity is an axe then execute this section
		if(StrEqual(classname, "player", false))
		{
			// If the damage is equals to 20 then execute this section
			if(damage == 20)
			{
				// Changes the damage value to 50.0
				damage = 50.0;
			}

			// If the damage is equals to 24 then execute this section
			else if(damage == 24)
			{
				// Changes the damage value to 55.0
				damage = 55.0;
			}

			// If the damage is equals to 40 then execute this section
			else if(damage == 40)
			{
				// Changes the damage value to 100.0
				damage = 100.0;
			}

			// If the client does not currently have a blood spattered screen then exceute this section
			if(!powerHatchetMassacreCooldown)
			{
				// Sets the powerHatchetMassacreCooldown variable to true
				powerHatchetMassacreCooldown[client] = true;

				// Applies a red fade overlay to the player that was hit with the axe
				ApplyFadeOverlay(client, 1, 1536, (0x0010), 173, 0, 0, 120, true);

				// Applies a blood screen overlay to the client
				ClientCommand(client, "r_screenoverlay kingmod/overlays/power_hatchetmassacre.vmt");

				// Removes the blood screen overlay from the player's screen after 3.0 seconds
				CreateTimer(3.0, Timer_HatchetMassacreRemoveBlood, client, TIMER_FLAG_NO_MAPCHANGE);
			}

			return Plugin_Changed;
		}
	}


	// If the currently active power is chuck norris fists then execute this section
	if(powerChuckNorris)
	{
		if(StrEqual(classname, "player", false))
		{
			// If the damage is equals to 15 then execute this section
			if(damage == 15)
			{
				// Picks a random number between 1 and 5 and store it within the random number variable
				int randomNumber = GetRandomInt(1, 5);

				// If the randomly chosen number is 4 or below then execute this section
				if(randomNumber <= 4)
				{
					// Changes the damage value to 5 times the randomly picked number + a base of 30 damage
					damage = 30.0 + (randomNumber * 5);
				}

				// If the randomly chosen number is 5 then execute this section
				else if(randomNumber == 5)
				{
					// Changes the damage value to 9000.0
					damage = 9000.0;

					PrintToChat(attacker, "Chuck Norris' punch completely obliterated you by dealing %i", RoundToFloor(damage));
				}
			}
		}

		PrintToChat(attacker, "damage %0.2f", damage);

		PrintToChat(attacker, "attacker weapon %s", classname);

		return Plugin_Changed;
	}


	// If the king's current power is not the laser gun power then execute this section
	if(powerLaserGun)
	{
		if(StrEqual(classname, "player", false))
		{
			if(powerLaserGun == 1)
			{
				// Changes the damage inflicted by the attack to 5.0
				damage = 5.0;
			}

			else if(powerLaserGun == 2)
			{
				// Changes the damage inflicted by the attack to 4.0
				damage = 4.0;
			}

			else if(powerLaserGun == 3)
			{
				// Changes the damage inflicted by the attack to 3.0
				damage = 3.0;
			}
		}

		return Plugin_Changed;
	}


	// If the currently active power is Lucky Number Seven then execute this section
	if(powerLuckyNumberSeven)
	{
		// Rolls a dice and stores the value of the outcome within the diceOne variable
		int diceOne = GetRandomInt(1, 6);

		// Rolls another dice and stores the value of the outcome within the diceTwo variable
		int diceTwo = GetRandomInt(1, 6);

		// If the rolled dices total number of eyes were equals to 7
		if(diceOne + diceTwo == 7)
		{
			// Picks a random number between 100 and 200 and store the chosen value within the bonusDamage variable
			int bonusDamage = GetRandomInt(100, 200);

			// Changes the damage inflicted by the attack to add an additional 100% to 200% bonus damage
			damage = damage + ((bonusDamage / 100) * damage);

			// Sends a message in the chat area only visible to the specified client
			PrintToChat(attacker, "KingMod: You rolled 7 (%i + %i) dealing %i%% bonus damage", diceOne, diceTwo, bonusDamage);

			return Plugin_Changed;
		}

		// If the rolled dices total number of eyes were not equals to 7
		else
		{
			// Sends a message in the chat area only visible to the specified client
			PrintToChat(attacker, "KingMod: You rolled %i (%i & %i) and dealt normal damage", diceOne + diceTwo, diceOne, diceTwo);
		}
	}


	// If the currently active power is western shootout then execute this section
	if(powerWesternShootout)
	{
		if(StrEqual(classname, "player", false))
		{
			// Changes the damage inflicted by the attack to 50.0
			damage = 50.0;

			return Plugin_Changed;
		}
	}


	// If the currently active power is babonic plague then execute this section
	if(powerBabonicPlague)
	{
		// Sets it so that the client is infected by the babonic plague
		powerBabonicPlagueInfected[client] = true;

		// Adds a scren overlay to the client's screen
		ClientCommand(client, "r_screenoverlay kingmod/overlays/power_babonicplague.vmt");
	}


	// If the currently active power is Blast Cannon then execute this section
	if(powerBlastCannon)
	{
		// If the entity is a sawedoff shotgun then excute this section
		if(StrEqual(classname, "player", false))
		{
			// Changes the damage inflicted upon the victim to 8% of the normal damage
			damage = (damage * 0.11) + 1.0;

			PrintToChatAll("Sawedoff dealt %0.0f damage", damage);

			// Creates a variable to store our data within
			float vectorLocation[3];

			// Creates a variable to store our data within
			float victimLocation[3];

			// Creates a variable to store our data within
			float attackerLocation[3];

			// Obtains the client's location and store it within the victimLocation variable
			GetEntPropVector(client, Prop_Data, "m_vecOrigin", victimLocation);

			// Obtains the attacker's location and store it within the attackerLocation variable
			GetEntPropVector(attacker, Prop_Data, "m_vecOrigin", attackerLocation);

			// Changes the player's ground state, making him airborne and easier to push
			SetEntPropEnt(client, Prop_Data, "m_hGroundEntity", -1);

			// Obtains th dsitance from the victim's location to the attacker's location and store it within our distance variable
			float distance = GetVectorDistance(victimLocation, attackerLocation);

			// If the distance is lower than 500 then execute this section
			if(distance < 500.0)
			{
				// Adds + 20 to the victim's location on the z-axis
				victimLocation[2] += 30.0;

				// Create an explosion effect at the victim location
				TE_SetupExplosion(victimLocation, effectExplosion, 5.0, 1, 0, 20, 40, victimLocation);
		
				// Sends the visual effect temp entity to the relevant players
				ShowVisualEffectToPlayers();

				// Creates a smoke effect at the victim's location
				TE_SetupSmoke(victimLocation, effectSmoke, 4.0, 3);

				// Sends the visual effect temp entity to the relevant players
				ShowVisualEffectToPlayers();

				// Calculates teh force multiplier of our knockback and store it within the pushPower variable
				float pushPower = ((500 - distance) * 0.01) + 1.0;

				// Modifies the attacker's location by -15.0
				attackerLocation[2] -= 15.0;

				// Creates a vector using th attacker and victim location
				MakeVectorFromPoints(attackerLocation, victimLocation, vectorLocation);

				// Scales our vctor by the pushpower value
				ScaleVector(vectorLocation, pushPower);

				// Modifies the victim's velocity to create a knockback effect
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vectorLocation);
			}
		
			return Plugin_Changed;
		}
	}


	// If the currently active power is Deagle Headshot then execute this section
	if(powerDeagleHeadshot)
	{
		// If the entity is a deagle then excute this section
		if(StrEqual(classname, "player", false))
		{
			// If the damage type is headshot damage then execute this section
			if(damagetype & CS_DMG_HEADSHOT)
			{
				// Creates a variable which we will use to store data within
				char soundName[64];

				// Picks a random number between 1 and 4
				int RandomSound = GetRandomInt(1, 4);

				// If the randomly picked number is 1 then execute this section
				if(RandomSound == 1)
				{
					// Changes the contents of our soundName variable
					soundName = "physics/flesh/flesh_squishy_impact_hard1.wav";
				}

				// If the randomly picked number is 2 then execute this section
				else if(RandomSound == 2)
				{
					// Changes the contents of our soundName variable
					soundName = "physics/flesh/flesh_squishy_impact_hard2.wav";
				}

				// If the randomly picked number is 3 then execute this section
				else if(RandomSound == 3)
				{
					// Changes the contents of our soundName variable
					soundName = "physics/flesh/flesh_squishy_impact_hard3.wav";
				}

				// If the randomly picked number is 4 then execute this section
				else if(RandomSound == 4)
				{
					// Changes the contents of our soundName variable
					soundName = "physics/flesh/flesh_squishy_impact_hard4.wav";
				}

				// If the sound is not already precached then execute this section
				if(!IsSoundPrecached(soundName))
				{	
					// Precaches the sound file
					PrecacheSound(soundName, true);
				}

				// Emits a sound to the specified client that only they can hear
				EmitSoundToClient(client, soundName, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.00, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

				return Plugin_Continue;
			}

			// Changes the damage inflicted upon the victim to 0
			damage = 0.0;

			return Plugin_Changed;
		}
	}


	// If the currently active power is Hammer Time then execute this section
	if(powerHammerTime)
	{
		// If the entity is a hammer then excute this section
		if(StrEqual(classname, "player", false))
		{
			// If the damage is equals to 32 then execute this section
			if(damage == 32)
			{
				// Changes the damage value to 65.0
				damage = 65.0;
			}

			// If the damage is equals to 16 or 19 then execute this section
			else
			{
				// Changes the damage value to 35.0
				damage = 35.0;
			}

			// If the powerHammerTimeBuried is not on cooldown then execute this section
			if(!powerHammerTimeBuried[client])
			{
				// Sets the powerHammerTimeBuried cooldown state to true
				powerHammerTimeBuried[client] = true;

				// Creates a variable called playerLocation which we will use to store data within
				float playerLocation[3];

				// Obtains the player's current location and store it within our playerLocation variable
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerLocation);

				// Subtracts 35.0 from the player's current position on the z-axis
				playerLocation[2] -= 42.5;

				// Teleports the prop to the location where the player died
				TeleportEntity(client, playerLocation, NULL_VECTOR, NULL_VECTOR);

				// Unburies the player from the ground if the player has not died in the meantime
				CreateTimer(2.25, Timer_HammerKnockDown, client, TIMER_FLAG_NO_MAPCHANGE);
			}

			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}



//////////////////////
// - Power Naplam - //
//////////////////////


// This happens when a king acquires the napalm power 
public void PowerNapalm(int client)
{
	// Turns on the Power napalm king power 
	powerNapalm = true;

	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_napalm.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "--------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Napalm";

	// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
	nameOfTier = "Tier A";

	// Specifies which special weapon the king should be given
	kingWeapon = "weapon_molotov";

	// Gives the king a unique weapon if the current power requires one
	CreateTimer(0.25, Timer_GiveKingUniqueWeapon, client);
}


// This happens when a player dies
public Action ResetNapalmStacks(int client)
{
	// If the king's current power is not the napalm power then execute this section
	if(!powerNapalm)
	{
		return Plugin_Continue;
	}

	// If the powerNapalmDamageTaken variable 0 then execute this section
	if(!powerNapalmDamageTaken[client])
	{
		return Plugin_Continue;
	}

	// Resets the powerNapalmDamageTaken variable back to 0
	powerNapalmDamageTaken[client] = 0;

	return Plugin_Continue;
}


// This happens when a player uses the left attack with their knife or weapon
public Action WeaponFireNapalm(int client)
{
	// If the king's current power is not the napalm power then execute this section
	if(!powerNapalm)
	{
		return Plugin_Continue;
	}

	// Obtains the name of the player's weapon and store it within our variable entity
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Creates a variable which we will use to store data within
	char className[64];

	// Obtains the entity's class name and store it within our className variable
	GetEntityClassname(entity, className, sizeof(className));

	// If the entity is not a molotov then execute this section
	if(!StrEqual(className, "weapon_molotov", false))
	{
		return Plugin_Continue;
	}

	// Gives the client the specified weapon
	GivePlayerItem(client, "weapon_molotov");

	// Changes the player's amount of molotovs to 10
	SetEntProp(client, Prop_Send, "m_iAmmo", 10, _, 17);

	return Plugin_Continue;
}


// This happens when a the plugin is being loaded
public void PowerNapalmStartTimer()
{
	// If the cvar_KingPowerChooser is not enabled then execute this section
	if(!cvar_KingPowerChooser)
	{
		return;
	}

	// Creates a timer that will check if a playr is below 6 health and is on fire every 0.5 seconds while the napalm power is active
	CreateTimer(0.5, Timer_PowerNapalmCheckHealth, _, TIMER_REPEAT);
}


// This happens every 0.5 seconds once the plugin has been loaded
public Action Timer_PowerNapalmCheckHealth(Handle timer)
{
	// If the king's current power is not the napalm power then execute this section
	if(!powerNapalm)
	{
		return Plugin_Continue;
	}

	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// If the king does not meet our validation criteria then execute this section
		if(!IsValidClient(kingIndex))
		{
			continue;
		}

		// If the client is not alive then execute this section
		if(!IsPlayerAlive(client))
		{
			continue;
		}

		// if the molotov's fire have not damaged the player 5 times then execute this section
		if(powerNapalmDamageTaken[client] != 5)
		{
			continue;
		}

		// If the client's health is above 6 then execute this section
		if(GetEntProp(client, Prop_Send, "m_iHealth") > 10)
		{
			continue;
		}

		PrintToChat(client, "KingMod: You died from the severe burns!");

		// Inflicts 50 damage to the client from the king
		DealDamageToClient(client, kingIndex, 50, "inferno");
	}

	return Plugin_Continue;
}


// We call upon this function whenever we want to inflict damage upon a player
public Action DealDamageToClient(int client, int attacker, int damage, const char[] weaponClassName)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	if(!IsValidClient(attacker))
	{
		return Plugin_Continue;
	}

	if(!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	// Creates a point_hurt entity and store it within the pointHurt variable
	int pointHurt = CreateEntityByName("point_hurt");

	// If the pointHurt  entity meets our criteria of validation then execute this section
	if(!IsValidEntity(pointHurt))
	{
		return Plugin_Continue;
	}

	// Creates a variable which we will use to store data within
	char damageString[16];

	// Converts the damage integer to a string value and store it within the damageString variable 
	IntToString(damage, damageString, 16);

	// Sets the client's targetname to damageVictim
	DispatchKeyValue(client, "targetname", "damageVictim");

	// Sets the target to receive the damage from the point_hurt to be the target with the name damageVictim
	DispatchKeyValue(pointHurt, "DamageTarget", "damageVictim");
	
	// Defines which type of damage will be inflicted upon the victim
	DispatchKeyValue(pointHurt, "DamageType", "DMG_GENERIC");

	// Sets the amount of damage that the target should receive
	DispatchKeyValue(pointHurt, "Damage", damageString);
	
	// Defines the weapon that was used to inflict the damage upon the victim
	DispatchKeyValue(pointHurt, "classname", weaponClassName);

	// Spawns the point-hurt entity in to the world 
	DispatchSpawn(pointHurt);
	
	// Inflicts the damage specified upon the targetname by the attacker
	AcceptEntityInput(pointHurt, "Hurt", attacker);

	// Sets the client's targetname back to "" 
	DispatchKeyValue(client, "targetname", "");

	// Kills the point_hurt entity, removing it from the game
	AcceptEntityInput(pointHurt, "Kill");	

	return Plugin_Continue;
}


// This happens when the king dies while the napalm power is currently active
public void RemoveNapalmFromVictims()
{
	// If the king's current power is not the napalm power then execute this section
	if(!powerNapalm)
	{
		return;
	}

	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// If the client is not alive then execute this section
		if(!IsPlayerAlive(client))
		{
			continue;
		}

		// if the molotov's fire have not damaged the player 5 times then execute this section
		if(powerNapalmDamageTaken[client] != 5)
		{
			continue;
		}

		// Finds the effect that is active on the player and store it within the burningFlames variable 
		int burningFlamees = GetEntPropEnt(client, Prop_Data, "m_hEffectEntity");

		// Changes the duration of the fire to 0.0 thereby extinguishing it
		SetEntPropFloat(burningFlamees, Prop_Data, "m_flLifetime", 0.0); 
	}
}



////////////////////
// - Power Riot - //
////////////////////


// This happens when a king acquires the riot power 
public void PowerRiot(int client)
{
	// Turns on the riot king power 
	powerRiot = true;

	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_riot.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "--------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Riot";

	// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
	nameOfTier = "Tier A";

	// Specifies which special weapon the king should be given
	kingWeapon = "weapon_shield";

	// Removes all the healthshots
	PowerGenericRemoveHealthshots();

	// Gives the king a unique weapon if the current power requires one
	CreateTimer(0.25, Timer_GiveKingUniqueWeapon, client);

	// Loops through all of the clients
	for (int i = 1; i <= MaxClients; i++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(i))
		{
			continue;
		}

		// If the client is not alive then execute this section
		if(!IsPlayerAlive(i))
		{
			continue;
		}

		// Changes the health of the client to 1
		SetEntProp(i, Prop_Send, "m_iHealth", 1, 1);
	}
}

// This happens when a player spawns
public void PowerRiotChangePlayerHealth(int client)
{
	// If the the riot power is not currently active  execute this section
	if(!powerRiot)
	{
		return;
	}

	// Changes the health of the client to 1
	SetEntProp(client, Prop_Send, "m_iHealth", 1, 1);
}


// This hapens when the round starts
public void createHostageZone()
{
	// If the cvar_KingPowerChooser is enabled and the riot power is enabled then execute this section
	if(cvar_KingPowerChooser && cvar_PowerRiot)
	{
		return;
	}

	// Creates a variable which we will store data within
	int entity = -1;

	// Loops through all of the entities and if no func_hostage_rescue zone exists then execute this section
	if((entity = FindEntityByClassname(entity, "func_hostage_rescue")) == -1)
	{
		// Creates a func_hostage_rescue entity and store it within the rescueArea variable
		int rescueArea = CreateEntityByName("func_hostage_rescue");

		// If the rescueArea does not meet our criteria of validation then execute this section
		if(!IsValidEntity(rescueArea))
		{
			return;
		}
		
		// Sets the origin of our hostage rescue zone
		DispatchKeyValue(rescueArea, "origin", "0.0, 0.0, 0.0");
		
		// Spawns our hostage rescue zone
		DispatchSpawn(rescueArea);

		// Changes the zone's state to disabled, as we don't need the functionality of it, we just require it to exist within the level
		AcceptEntityInput(rescueArea, "disable");
	}
}


// This happens when either the riot or the zombie apocalypse powers is active
public void PowerGenericRemoveHealthshots()
{
	// Loops through all entities that are currently in the game
	for (int entity = MaxClients + 1; entity <= GetMaxEntities(); entity++)
	{
		// If the entity does not meet our criteria of validation then execute this section
		if(!IsValidEntity(entity))
		{
			continue;
		}

		// Creates a variable which we will use to store data within
		char className[64];

		// Obtains the entity's class name and store it within our className variable
		GetEntityClassname(entity, className, sizeof(className));

		// If the entity is a healthshot then execute this section
		if(!StrEqual(className, "weapon_healthshot"))
		{	
			continue;
		}

		// Kills the weapon entity, removing it from the game
		AcceptEntityInput(entity, "Kill");
	}
}


///////////////////////
// - Power Vampire - //
///////////////////////


// This happens when a king acquires the vampire power 
public void PowerVampire()
{
	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_vampire.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "---------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Vampire";
	
	// Turns on the movement speed king power 
	powerVampire = GetRandomInt(1, 3);

	// If the value stored within the powerVampire is 1 execute this section
	if(powerVampire == 1)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier A";
	}

	// If the value stored within the powerVampire is 2 execute this section
	else if(powerVampire == 2)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier B";
	}

	// If the value stored within the powerVampire is 3 execute this section
	else if(powerVampire == 3)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier C";
	}
}



/////////////////////////////
// - Power Breachcharges - //
/////////////////////////////


// This happens when a king acquires the breachcharges power 
public void PowerBreachCharges(int client)
{
	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_breachcharges.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "-----------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Breachcharges";
	
	// Specifies which special weapon the king should be given
	kingWeapon = "weapon_breachcharge";

	// Gives the king a unique weapon if the current power requires one
	CreateTimer(0.25, Timer_GiveKingUniqueWeapon, client);

	// Turns on the breachcharges king power 
	powerBreachCharges = GetRandomInt(1, 3);

	// If the value stored within the powerBreachCharges is 1 execute this section
	if(powerBreachCharges == 1)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier A";
	}

	// If the value stored within the powerBreachCharges is 2 execute this section
	else if(powerBreachCharges == 2)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier B";
	}

	// If the value stored within the powerBreachCharges is 3 execute this section
	else if(powerBreachCharges == 3)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier C";
	}
}



//////////////////////////////////////
// - Power Leg Crushing Bumpmines - //
//////////////////////////////////////


// This happens when a king acquires the leg crushing bumpmines power 
public void PowerLegCrushingBumpmines(int client)
{
	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_legcrushingbumpmines.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "------------------------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Leg Crushing Bumpmines";
	
	// Specifies which special weapon the king should be given
	kingWeapon = "weapon_bumpmine";

	// Gives the king a unique weapon if the current power requires one
	CreateTimer(0.25, Timer_GiveKingUniqueWeapon, client);

	// Turns on the leg crushing bumpmines king power 
	powerLegCrushingBumpmines = GetRandomInt(1, 3);

	// If the value stored within the powerLegCrushingBumpmines is 1 execute this section
	if(powerLegCrushingBumpmines == 1)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier A";
	}

	// If the value stored within the powerLegCrushingBumpmines is 2 execute this section
	else if(powerLegCrushingBumpmines == 2)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier B";
	}

	// If the value stored within the powerLegCrushingBumpmines is 3 execute this section
	else if(powerLegCrushingBumpmines == 3)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier C";
	}
}


// This happens when the king dies while the leg crushing bumpmine power is active
public void RemoveAllBumpMines()
{
	// If the currently active power is not leg crushing bumpmines then execute this section
	if(!powerLegCrushingBumpmines)
	{
		return;
	}

	// Creates a variable to store our data within 
	int entity = INVALID_ENT_REFERENCE;

	// Loops through the entities and execute this section if the entity has the classname bumpmine_projectile
	while ((entity = FindEntityByClassname(entity, "bumpmine_projectile")) != -1)
	{
		// If the entity does not meet our criteria of validation then execute this section
		if(!IsValidEntity(entity))
		{
			return;
		}

		// Kills the weapon entity, removing it from the game
		AcceptEntityInput(entity, "Kill");
	}
}



////////////////////////////////
// - Power Hatchet Massacre - //
////////////////////////////////


// This happens when a king acquires the hatchet massacre power 
public void PowerHatchetMassacre(int client)
{
	// Turns on the hatchet massacre king power 
	powerHatchetMassacre = true;

	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_hatchetmassacre.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "---------------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Hatchet Massacre";
	
	// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
	nameOfTier = "Tier A";

	// Specifies which special weapon the king should be given
	kingWeapon = "weapon_axe";

	// Gives the king a unique weapon if the current power requires one
	CreateTimer(0.25, Timer_GiveKingUniqueWeapon, client);
}


// This happens 3.0 seconds after a player is hit by the king's axe
public Action Timer_HatchetMassacreRemoveBlood(Handle timer, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Removes the screen overlay from the client
	ClientCommand(client, "r_screenoverlay 0");

	// Sets the powerHatchetMassacreCooldown variable to true
	powerHatchetMassacreCooldown[client] = true;

	return Plugin_Continue;
}


// Thanks to Berni for his SM LIB screenfade stock
public void ApplyFadeOverlay(int client, int duration, int holdTime, int fadeflags, int colorRed, int colorGreen, int colorBlue, int colorAlpha, bool reliable)
{
	// 0x0001 - Fade In, i believe?
	// 0x0002 - Fade out
	// 0x0004 - Fade without transitional color blend and a bit darker tones
	// 0x0008 - Stays faded until a new fade takes over
	// 0x0010 - Replaces any existing fade overlays with this one
	
	// Creates a handle for our usermessage
	Handle userMessage = StartMessageOne("Fade", client, (reliable ? USERMSG_RELIABLE : 0));

	// If the usermessage is not invalid then execute this section 
	if(userMessage != INVALID_HANDLE)
	{
		// If the usermessage type is protobuf which is used in CS:GO then execute this section
		if(GetUserMessageType() == UM_Protobuf)
		{
			// Creates a variable called fadeColor which we will use to store our color code in
			int fadeColor[4];

			// Assigns the red color value to the fadeColor variable first index
			fadeColor[0] = colorRed;

			// Assigns the green color value to the fadeColor variable's second index
			fadeColor[1] = colorGreen;

			// Assigns the blue color value to the fadeColor variable's third index
			fadeColor[2] = colorBlue;

			// Assigns the alpha color value to the fadeColor variable's fourth index
			fadeColor[3] = colorAlpha;

			// Defines how long the duration should last (duration roughly translates 512 to ~1 second)
			PbSetInt(userMessage, "duration", duration);

			// Definses the hold time for the screen fade
			PbSetInt(userMessage, "hold_time", holdTime);

			// You can use multiple flags at once by enclosing them in parantheses different options
			PbSetInt(userMessage, "flags", fadeflags);

			// Sets the fade color to that of our value stored within our variable fadeColor
			PbSetColor(userMessage, "clr", fadeColor);

			EndMessage();
		}
	}
}



//////////////////////////////////
// - Power Chuck Norris Fists - //
//////////////////////////////////


// This happens when a king acquires the chuck norris fists power 
public void PowerChuckNorrisFists(int client)
{
	// Turns on the chuck norris king power 
	powerChuckNorris = true;

	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_chucknorris.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "-----------------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Chuck Norris Fists";
	
	// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
	nameOfTier = "Tier S+";

	// Specifies which special weapon the king should be given
	kingWeapon = "weapon_fists";

	// Picks one of many random chuck norris jokes and posts it in the chat presenting it as if it was a fact
	SelectChuckNorirsJoke();

	// Gives the king a unique weapon if the current power requires one
	CreateTimer(0.25, Timer_GiveKingUniqueWeapon, client);
}


// This happens when a king acquires the chuck norris fists power
public void SelectChuckNorirsJoke()
{
	// Picks a random number and store it within the randomJoke variable
	int randomJoke = GetRandomInt(1, 46);

	// Creates a variable which we will store our data within
	char chuckNorrisJoke[256];

	// Creates a switch statement to manage outcomes depnding on the value of our randomVariable
	switch(randomJoke)
	{
		// If the value of the randomJoke variable is 1 then execute this section
		case 1:
		{
			// Changes the contents of the chuckNorrisJoke variable
			chuckNorrisJoke = "Chuck Norris can strangle you with a cordless phone.";
		}

		case 2:
		{
			chuckNorrisJoke = "Death once had a near-Chuck-Norris experience.";
		}
		
		case 3:
		{
			chuckNorrisJoke = "When Chuck Norris writes, he makes paper bleed.";
		}

		case 4:
		{
			chuckNorrisJoke = "Chuck Norris makes onions cry.";
		}

		case 5:
		{
			chuckNorrisJoke = "Chuck Norris can kill two stones with one bird.";
		}

		case 6:
		{
			chuckNorrisJoke = "The dark is afraid of Chuck Norris.";
		}

		case 7:
		{
			chuckNorrisJoke = "Chuck Norris does not hunt because the word hunting implies the possibility of failure. Chuck Norris goes killing.";
		}

		case 8:
		{
			chuckNorrisJoke = "Chuck Norris once won a game of Connect Four in three moves.";
		}

		case 9:
		{
			chuckNorrisJoke = "A cobra once bit Chuck Norris' leg. After five days of excruciating pain, the cobra died.";
		}

		case 10:
		{
			chuckNorrisJoke = "Chuck Norris stands faster than anyone can run.";
		}

		case 11:
		{
			chuckNorrisJoke = "Chuck Norris counted to infinity... Twice.";
		}

		case 12:
		{
			chuckNorrisJoke = "If you want a list of Chuck Norris' enemies, just check the extinct species list.";
		}
		
		case 13:
		{
			chuckNorrisJoke = "On the 7th day, God rested ... Chuck Norris took over.";
		}

		case 14:
		{
			chuckNorrisJoke = "The chief export of Chuck Norris is pain.";
		}

		case 15:
		{
			chuckNorrisJoke = "Chuck Norris does not sleep. He waits.";
		}

		case 16:
		{
			chuckNorrisJoke = "Chuck Norris does not own a stove, oven, or microwave, because revenge is a dish best served cold.";
		}

		case 17:
		{
			chuckNorrisJoke = "Since 1940, the year Chuck Norris was born, roundhouse kick related deaths have increased 13,000 percent.";
		}

		case 18:
		{
			chuckNorrisJoke = "Chuck Norris' tears cure cancer. Too bad he has never cried.";
		}
		
		case 19:
		{
			chuckNorrisJoke = "The dinosaurs looked at Chuck Norris the wrong way once. You know what happened to them.";
		}

		case 20:
		{
			chuckNorrisJoke = "In the Beginning there was nothing ... then Chuck Norris roundhouse kicked nothing and told it to get a job.";
		}

		case 21:
		{
			chuckNorrisJoke = "Chuck Norris breathes air ... Three times a day.";
		}

		case 22:
		{
			chuckNorrisJoke = "Time waits for no man. Unless that man is Chuck Norris.";
		}
		
		case 23:
		{
			chuckNorrisJoke = "Chuck Norris doesn't read books. He stares them down until he gets the information he wants.";
		}

		case 24:
		{
			chuckNorrisJoke = "Chuck Norris once punched a man in the soul.";
		}

		case 25:
		{
			chuckNorrisJoke = "Chuck Norris once had a heart attack. His heart lost.";
		}

		case 26:
		{
			chuckNorrisJoke = "The only time Chuck Norris was ever wrong was when he thought he had made a mistake.";
		}

		case 27:
		{
			chuckNorrisJoke = "The quickest way to a man's heart is with Chuck Norris's fist.";
		}

		case 28:
		{
			chuckNorrisJoke = "Chuck Norris used to beat up his shadow because it was following to close. It now stands 15 feet behind him.";
		}
		
		case 29:
		{
			chuckNorrisJoke = "Outer space exists because it's too afraid to be on the same planet with Chuck Norris.";
		}

		case 30:
		{
			chuckNorrisJoke = "When Chuck Norris does a pushup, he's pushing the Earth down.";
		}

		case 31:
		{
			chuckNorrisJoke = "Chuck Norris is the reason why Waldo is hiding.";
		}

		case 32:
		{
			chuckNorrisJoke = "The Great Wall of China was originally created to keep Chuck Norris out. It didn’t work.";
		}
		
		case 33:
		{
			chuckNorrisJoke = "Chuck Norris is the only man to ever defeat a brick wall in a game of tennis.";
		}

		case 34:
		{
			chuckNorrisJoke = "Chuck Norris once ordered a steak in a restaurant. The steak did what it was told.";
		}

		case 35:
		{
			chuckNorrisJoke = "Chuck Norris can cook minute rice in 30 seconds.";
		}

		case 36:
		{
			chuckNorrisJoke = "Chuck Norris once beat the sun in a staring contest.";
		}

		case 37:
		{
			chuckNorrisJoke = "Chuck Norris doesn't breathe, he holds air hostage.";
		}

		case 38:
		{
			chuckNorrisJoke = "Before he forgot a gift for Chuck Norris, Santa Claus was real.";
		}
		
		case 39:
		{
			chuckNorrisJoke = "Chuck Norris can start a fire with an ice cube.";
		}

		case 40:
		{
			chuckNorrisJoke = "When Chuck Norris stares into the abyss, the abyss nervously looks away.";
		}

		case 41:
		{
			chuckNorrisJoke = "COVID-19 is desperate to develop a vaccine against Chuck Norris.";
		}
		
		case 43:
		{
			chuckNorrisJoke = "When Chuck Norris steps on a piece of lego, the lego cries.";
		}

		case 44:
		{
			chuckNorrisJoke = "The Dead Sea was alive before Chuck Norris swam there.";
		}

		case 45:
		{
			chuckNorrisJoke = "The Swiss Army uses Chuck Norris Knives.";
		}

		case 46:
		{
			chuckNorrisJoke = "Chuck Norris knows Victoria’s secret.";
		}
	}

	// Sends a message in the chat to all players online
	PrintToChatAll("Chuck Norris Fact #%i", randomJoke);
	PrintToChatAll("- %s", chuckNorrisJoke);
}



/////////////////////////
// - Power Laser Gun - //
/////////////////////////


// This happens when a king acquires the laser gun power 
public void PowerLaserGun(int client)
{
	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_lasergun.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "-----------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Laser Gun";
	
	// Specifies which special weapon the king should be given
	kingWeapon = "weapon_cz75a";

	// Disables recoil and spread
	PowerLaserGunDisableRecoil();

	// Turns on the laser gun king power 
	powerLaserGun = GetRandomInt(1, 3);

	// If the value stored within the powerLaserGun is 1 execute this section
	if(powerLaserGun == 1)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier A";
	}

	// If the value stored within the powerLaserGun is 2 execute this section
	else if(powerLaserGun == 2)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier B";
	}

	// If the value stored within the powerLaserGun is 3 execute this section
	else if(powerLaserGun == 3)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier C";
	}

	// Gives the king a unique weapon if the current power requires one
	CreateTimer(0.25, Timer_GiveKingUniqueWeapon, client);
}


// This happens when a king acquires the laser gun power 
public void PowerLaserGunDisableRecoil()
{
	SetConVar("weapon_recoil_scale", "0");
	SetConVar("weapon_recoil_cooldown", "0");
	SetConVar("weapon_accuracy_nospread", "1");
	SetConVar("weapon_recoil_decay1_exp", "99999");
	SetConVar("weapon_recoil_decay2_exp", "99999");
	SetConVar("weapon_recoil_decay2_lin", "99999");
	SetConVar("weapon_recoil_suppression_shots", "500");
}


// This happens when a new round starts or the king dies
public void PowerLaserGunEnableRecoil()
{
	SetConVar("weapon_recoil_scale", "2.0");
	SetConVar("weapon_recoil_cooldown", "0.55");
	SetConVar("weapon_accuracy_nospread", "0");
	SetConVar("weapon_recoil_decay1_exp", "3.5");
	SetConVar("weapon_recoil_decay2_exp", "8.0");
	SetConVar("weapon_recoil_decay2_lin", "18");
	SetConVar("weapon_recoil_suppression_shots", "4");
}


// This happens when a player uses the left attack with their knife or weapon
public Action WeaponFireCz75a(int client)
{
	// If the king's current power is not the laser gun power then execute this section
	if(!powerLaserGun)
	{
		return Plugin_Continue;
	}

	// Obtains the name of the player's weapon and store it within our variable entity
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Creates a variable to store our data within
	char classname[32];

	// Obtains the classname of the entity and store it within our classname variable
	GetEdictClassname(entity, classname, sizeof(classname));

	// If the weapon is not a cz75a (p250 shares item slot with it) then excute this section
	if(!StrEqual("weapon_p250", classname))
	{
		return Plugin_Continue;
	}

	// Changes the cz75a's clip to 13
	SetEntProp(entity, Prop_Data, "m_iClip1", 13);

	// Creates our two variables which we will store our data within
	float playerEyeLocation[3];

	// Creates our two variables which we will store our data within
	float playerViewLocation[3];

	// Obtains the player's eye coordinat location and store it within our variable playerEyeLocation
	GetClientEyePosition(client, playerEyeLocation);
	
	// Obtains the player's aim coordinate location and store it within our variable playerViewLocation
	GetClientSightEnd(client, playerViewLocation);

	int effectColor[4];

	// If the player is on the Terrorist team then execute this section
	if(GetClientTeam(client) == 2)
	{
		// Defines the Red, Green, Blue and Alpha color values and store them within effectColor
		effectColor = {230, 15, 30, 255};

		// Creates a temporary visual effect shaped as a line from where you stand to where the bullet was fired at
		TE_SetupBeamPoints(playerEyeLocation, playerViewLocation, effectLaser, effectLaser, 10, 10, 0.7, 1.5, 1.5, 0, 0.0, effectColor, 0);
	}

	// If the player is on the Counter-Terrorist team then execute this section
	else if(GetClientTeam(client) == 3)
	{
		// Defines the Red, Green, Blue and Alpha color values and store them within effectColor
		effectColor = {0, 210, 250, 255};

		// Creates a temporary visual effect shaped as a line from where you stand to where the bullet was fired at
		TE_SetupBeamPoints(playerEyeLocation, playerViewLocation, effectLaser, effectLaser, 10, 10, 0.7, 1.5, 1.5, 0, 0.0, effectColor, 0);
	}

	// Sends the visual effect temp entity to the relevant players
	ShowVisualEffectToPlayers();

	return Plugin_Continue;
}


// This happens when the king fires his cz75a while the laser gun power is currently active
public void GetClientSightEnd(int client, float endLocation[3])
{
	// Creates our two variables which we will store our data within
	float playerEyeLocation[3];

	// Creates our two variables which we will store our data within
	float playerEyeAngles[3];

	// Obtains the player's eye coordinat location and store it within our variable playerEyeLocation
	GetClientEyePosition(client, playerEyeLocation);

	// Obtains the player's eye angles and store it within our variable playerEyeLocation
	GetClientEyeAngles(client, playerEyeAngles);

	// Performs a trace ray 
	TR_TraceRayFilter(playerEyeLocation, playerEyeAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitPlayers);
	
	// If the traceray did hit then execute this section
	if(TR_DidHit())
	{
		// Obtains the colission point of the trace ray
		TR_GetEndPosition(endLocation);
	}
}


// This happens when the king fires his cz75a while the laser gun power is currently active
public bool TraceRayDontHitPlayers(int entity, int mask, int data)
{
	// If the entity is above 0 but below or equals to the value of maxClients then execute this section
	if (0 < entity <= MaxClients)
	{
		return false;
	}

	return true;
}



//////////////////////////////////
// - Power Lucky Number Seven - //
//////////////////////////////////


// This happens when a king acquires the lucky number seven power 
public void PowerLuckyNumberSeven(int client)
{
	// Turns on the lucky number seven king power 
	powerLuckyNumberSeven = true;

	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_luckynumberseven.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "------------------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Lucky number Seven";
	
	// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
	nameOfTier = "Tier A";
}



////////////////////////////////
// - Power Western Shootout - //
////////////////////////////////


// This happens when a king acquires the western shootout power 
public void PowerWesternShootout(int client)
{
	// Turns on the western shootout king power 
	powerWesternShootout = true;

	// Sets the playerSwappedWeapons state to false to indicate the player has not swapped weapons since initiating the weapon reloading
	playerSwappedWeapons[client] = false;

	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_westernshootout.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "---------------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Western Shootout";
	
	// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
	nameOfTier = "Tier A";

	// Specifies which special weapon the king should be given
	kingWeapon = "weapon_revolver";

	// Gives the king a unique weapon if the current power requires one
	CreateTimer(0.25, Timer_GiveKingUniqueWeapon, client);
}


// This happens when a revolver has been spawned
public Action entity_RevolverSpawned(int entity)
{
	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Changes the clip to 2 and the ammo to 2 after 0.1 second
	CreateTimer(0.1, Timer_PowerWesternShootoutDefaultAmmo, entity, TIMER_FLAG_NO_MAPCHANGE);

	// Adds a hook to the revolver entity which will let us track when the entity is reloaded
	SDKHook(entity, SDKHook_ReloadPost, OnWeaponReloadPostRevolver);

	return Plugin_Continue;
}


// This happens 0.1 second after a revolver has been spawned
public Action Timer_PowerWesternShootoutDefaultAmmo(Handle timer, int weapon)
{
	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(weapon))
	{
		return Plugin_Continue;
	}

	// Changes the amount of bullets there are inside of the revolveer's clip
	SetEntProp(weapon, Prop_Send, "m_iClip1", 2);

	// Changes the ammount of ammo that the player has for their weapon
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 2);

	return Plugin_Continue;
}


// This happens when the player starts to reload his revolver
public Action OnWeaponReloadPostRevolver(int weapon)
{
	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(weapon))
	{
		return Plugin_Continue;
	}

	// Obtains and stores the entity owner offset within our client variable 
	int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Sets the playerSwappedWeapons state to false to indicate the player has not swapped weapons since initiating the weapon reloading
	playerSwappedWeapons[client] = false;

	// Changes the clip to 2 and the ammo to 2 after 2.31 seconds
	CreateTimer(2.31, Timer_PowerWesternShootoutAmmo, weapon, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}


// This happens when a player switches
public Action OnWeaponSwitchPost(int client, int weapon)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Sets the playerSwappedWeapons state to true to indicate the player swapped weapons since initiating the weapon reloading
	playerSwappedWeapons[client] = true;

	return Plugin_Handled;
}


// This happens 2.31 seconds after it has been reloaded
public Action Timer_PowerWesternShootoutAmmo(Handle timer, int weapon)
{
	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(weapon))
	{
		return Plugin_Continue;
	}

	// Obtains and stores the entity owner offset within our client variable 
	int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the player has changed weapons since he initiated the reloading process then execute this section
	if(playerSwappedWeapons[client])
	{
		return Plugin_Continue;
	}

	// Changes the amount of bullets there are inside of the revolveer's clip
	SetEntProp(weapon, Prop_Send, "m_iClip1", 2);

	// Changes the ammount of ammo that the player has for their weapon
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 2);

	return Plugin_Continue;
}



//////////////////////////////
// - Power Babonic Plague - //
//////////////////////////////


// This happens when a king acquires the babonic plague power 
public void PowerBabonicPlague(int client)
{
	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_babonicplague.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "------------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Babonic Plague";
	
	// Turns on the babonic plague king power 
	powerBabonicPlague = GetRandomInt(1, 3);

	// If the value stored within the powerBabonicPlague is 1 execute this section
	if(powerBabonicPlague == 1)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier A";
	}

	// If the value stored within the powerBabonicPlague is 2 execute this section
	if(powerBabonicPlague == 2)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier B";
	}

	// If the value stored within the powerBabonicPlague is 3 execute this section
	if(powerBabonicPlague == 3)
	{
		// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
		nameOfTier = "Tier C";
	}
}


// This happens once every 1.5 second
public Action Timer_PowerBabonicPlagueLoop(Handle timer)
{
	// If thg king power chooser is enabled and the babonic plague power is enabled then execute this section
	if(!cvar_KingPowerChooser && !cvar_PowerBabonicPlague)
	{
		return Plugin_Continue;
	}

	// If the currently active power is babonic plague then execute this section
	if(!powerBabonicPlague)
	{
		return Plugin_Continue;
	}

	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// If the player is not infected by the babonic plague then execute this section
		if(!powerBabonicPlagueInfected[client])
		{
			continue;
		}

		// If the client is not alive then execute this section
		if(!IsPlayerAlive(client))
		{
			continue;
		}

		// Obtains the value of powerBabonicPlague multiplies it by 2 and adds 4 and store it within the damage variable
		int damage = 4 + (powerBabonicPlague * 2);

		// Obtains the player's health and store it within the playerHealth variable
		int playerHealth = GetEntProp(client, Prop_Send, "m_iHealth");

		// If the client's health is the same as the value contained within damage or below then execute this section
		if(playerHealth <= damage)
		{
			// Inflicts the value stored within the damage upon the client from the king
			DealDamageToClient(client, kingIndex, damage, "weapon_healthshot");

			continue;
		}

		// Subtracts the value stored within the damage variable from our player's health 
		playerHealth -= damage;

		// Changes the health of the client
		SetEntProp(client, Prop_Send, "m_iHealth", playerHealth, 1);

		// If the client is not a bot then execute this section
		if(!IsFakeClient(client))
		{
			continue;
		}

		// Obtains a random number between 0 and 255 and store it within the colorRed variable
		int colorRed = GetRandomInt(0, 255);
		
		// Obtains a random number between 0 and 255 and store it within the colorGreen variable
		int colorGreen = GetRandomInt(0, 255);
		
		// Obtains a random number between 0 and 255 and store it within the colorBlue variable
		int colorBlue = GetRandomInt(0, 255);

		// Applies a colored fade overlay to the player's screen
		ApplyFadeOverlay(client, 255, 255, (0x0008), colorRed, colorGreen, colorBlue, 128, true);

		// Picks a random value between 102 and 158 and store it within the randomFOV variable
		int randomFoV = GetRandomInt(102, 158);

		// Changes the client's FOV to the value stored in our randomFOV variable
		SetEntProp(client, Prop_Send, "m_iFOV", randomFoV);

		// Changes the client's default FOV to the value stored in our randomFOV variable
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", randomFoV);

		// float PlayerPosition[3];
		float playerViewAngle[3];

		// GetClientAbsOrigin(client, PlayerPosition);
		GetClientEyeAngles(client, playerViewAngle);

		// Picks a random value between -32.50 and 32.50 and store it within our playerViewAngle
		playerViewAngle[2] = GetRandomFloat(-32.50, 32.50);
		
		// TeleportEntity(client, PlayerPosition, playerViewAngle, NULL_VECTOR);
		TeleportEntity(client, NULL_VECTOR, playerViewAngle, NULL_VECTOR);
	}

	return Plugin_Continue;
}


// This happens when the king dies or when a new round starts
public void ResetBabonicPlague()
{
	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// If the player is not infected by the babonic plague then execute this section
		if(!powerBabonicPlagueInfected[client])
		{
			continue;
		}

		// Sets it so that the client is no longer inflicted by the babonic plague
		powerBabonicPlagueInfected[client] = false;

		// Removes the screen overlay from the player
		RemoveScreenOverlay(client);

		// Changes the client's FOV to the default valuee 90
		SetEntProp(client, Prop_Send, "m_iFOV", 90);

		// Changes the client's default FOV to the default valuee 90
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", 90);
	}
}


// This happens when the player dies while Babonic Plague is active
public void ResetBabonicPlagueOnDeath(int client)
{
	// If the currently active power is babonic plague then execute this section
	if(!powerBabonicPlague)
	{
		return;
	}

	// Sets it so that the client is no longer inflicted by the babonic plague
	powerBabonicPlagueInfected[client] = false;

	// Removes the screen overlay from the player
	RemoveScreenOverlay(client);

	// Changes the client's FOV to the default valuee 90
	SetEntProp(client, Prop_Send, "m_iFOV", 90);

	// Changes the client's default FOV to the default valuee 90
	SetEntProp(client, Prop_Send, "m_iDefaultFOV", 90);
}


/////////////////////////////////
// - Power Zombie Apocalypse - //
/////////////////////////////////


// This happens when a king acquires the Zombie Apocalypse power 
public void PowerZombieApocalypse(int client)
{
	// Turns on the zombie apocalypse king power 
	powerZombieApocalypse = true;

	// Obtains the client's team index and store it within the powerZombieAffectedTeam variable
	powerZombieAffectedTeam = GetClientTeam(client);

	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_zombieapocalypse.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "-----------------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Zombie Apocalypse";
	
	// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
	nameOfTier = "Tier A";

	// Plays the ambient sound that will be running while the zombie apocalypse power is active
	CreateTimer(0.0, Timer_PowerZombieApocalypseAmbience, _, TIMER_FLAG_NO_MAPCHANGE);

	// Changes the skybox, sound ambience, turns the king's team in to zombies, increasing their health and lowers their speed
	PowerZombieApocalypseInitiate(client);
}


// This happens when a king acquires the zombie apocalypse power
public void PowerZombieApocalypseInitiate(int client)
{
	// Removes all the healthshots
	PowerGenericRemoveHealthshots();

	// Saves the current skybox, and changes the skybox to zombie apocalypse skybox
	PowerZombieApocalypseChangeSkybox();

	// Turns the client in to a zombie with 325 health, and 80% of the normal movement speed
	PowerZombieApocalypseCreateZombie(client, 325, 0.80);

	// Loops through all of the clients
	for (int i = 1; i <= MaxClients; i++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(i))
		{
			continue;
		}

		// If the client is the king then execute this section
		if(isPlayerKing[i])
		{
			continue;
		}

		// Turns the client in to a zombie with 150 health, and 80% of the normal movement speed
		PowerZombieApocalypseCreateZombie(i, 150, 0.80);
	}
}


// This happens when a king acquires the zombie apocalypse power
public void PowerZombieApocalypseChangeSkybox()
{
	// Obtains the value of the sv_skyname server variable and store it within the skyName convar 
	ConVar skyName = FindConVar("sv_skyname");

	// Creates a variable to store our data within
	char validateSkyboxName[128];

	// Obtains the value of the sv_skyname server variable and store it within the validateSkyboxName variable
	GetConVarString(skyName, validateSkyboxName, sizeof(validateSkyboxName));

	// If the current skybox is not the zombienight skybox then execute this section
	if(!StrEqual(validateSkyboxName, "zombienight"))
	{
		// Obtains the value of the sv_skyname server variable and store it within the skyboxName variable
		GetConVarString(skyName, skyboxName, sizeof(skyboxName));

		// Changes the map's skybox 
		ServerCommand("sv_skyname zombienight");
	}

	// If the current skybox is the zombienight skybox then execut this section
	else
	{
		// Changes the map's skybox 
		ServerCommand("sv_skyname zombienight");
	}
}


// This happens when a king acquires the zombie apocalypse power and when a player spawns while the zombie apocalypse power is active
public void PowerZombieApocalypseCreateZombie(int client, int playerHealth, float movementSpeed)
{
	// If the client is not a bot then execute this section
	if(!IsFakeClient(client))
	{
		// If the client is on the zombie infected team then execute this section
		if(GetClientTeam(client) == powerZombieAffectedTeam)
		{
			// Applies a screen overlay to the player's screen
			ClientCommand(client, "r_screenoverlay kingmod/overlays/power_zombieapocalypsezombie.vmt");
		}

		// If the client is not on the zombie infected team then execute this section
		else
		{
			// Applies a screen overlay to the player's screen
			ClientCommand(client, "r_screenoverlay kingmod/overlays/power_zombieapocalypsehuman.vmt");
		}

		// If the sound is not already precached then execute this section
		if(!IsSoundPrecached("kingmod/sfx_zombiescream.mp3"))
		{	
			// Precaches the sound file
			PrecacheSound("kingmod/sfx_zombiescream.mp3", true);
		}

		// Emits a sound to the specified client that only they can hear
		EmitSoundToClient(client, "kingmod/sfx_zombiescream.mp3", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.00, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}

	// If the client is not alive then execute this section
	if(!IsPlayerAlive(client))
	{
		return;
	}

	// If the client is on the zombie infected team then execute this section
	if(GetClientTeam(client) != powerZombieAffectedTeam)
	{
		return;
	}

	// If the model is not precached already then execute this section
	if(!IsModelPrecached("models/player/zombie.mdl"))
	{
		// Precaches the specified model
		PrecacheModel("models/player/zombie.mdl");
	}

	// Changes the client's player model to the specified model
	SetEntityModel(client, "models/player/zombie.mdl");

	// Changes the health of the player
	SetEntProp(client, Prop_Send, "m_iHealth", playerHealth, 1);

	// Changes the movement speed of the player to 80% of the normal movement speed
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", movementSpeed);
}


// This happens when the king dies or the round resets
public void PowerZombieApocalypseResetSkybox()
{
	// Creates a variable which we will store data within
	char serverCommand[140];

	// Combines the sv_skyname with the name of the skybox stored within the skyboxname variable
	FormatEx(serverCommand, sizeof(serverCommand), "sv_skyname %s", skyboxName);

	// Performs a server command to change the map's skybox 
	ServerCommand(serverCommand);
}


// This happens when the king dies or the round resets
public void PowerZombieApocalypseCreateHuman(int client)
{
	// If the client is not a bot then execute this section
	if(!IsFakeClient(client))
	{
		// Removes the screen overlay if the client is the king and impregnable armor is currently active
		RemoveScreenOverlay(client);

		// Stops the ambience sounds from playing
		ClientCommand(client, "playgamesound Music.StopAllExceptMusic");
	}

	// If the client is dead then execute this section
	if(!IsPlayerAlive(client))
	{
		return;
	}

	// Changes the movement speed of the player back to the normal movement speed
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.00);

	// If the client's health is above 100 then execute this section
	if(GetEntProp(client, Prop_Send, "m_iHealth") < 100)
	{
		// Changes the health of the player to 100
		SetEntProp(client, Prop_Send, "m_iHealth", 100, 1);
	}

	if(GetClientTeam(client) == 2 && powerZombieAffectedTeam == 2)
	{
		// Changes the client's player model to the specified model
		SetEntityModel(client, "models/player/tm_phoenix.mdl");
	}

	if(GetClientTeam(client) == 3 && powerZombieAffectedTeam == 3)
	{
		// Changes the client's player model to the specified model
		SetEntityModel(client, "models/player/ctm_idf.mdl");
	}
}


// This happens when the king dies or the round resets
public void PowerZombieApocalypseRemove()
{
	// Changes the skybox back to the skybox that was saved prior to altering it to the zombie apocalypse skybox
	PowerZombieApocalypseResetSkybox();

	// If the model is not precached already then execute this section
	if(!IsModelPrecached("models/player/ctm_idf.mdl"))
	{
		// Precaches the specified model
		PrecacheModel("models/player/ctm_idf.mdl");
	}

	// If the model is not precached already then execute this section
	if(!IsModelPrecached("models/player/tm_phoenix.mdl"))
	{
		// Precaches the specified model
		PrecacheModel("models/player/tm_phoenix.mdl");
	}

	// Loops through all of the clients
	for (int i = 1; i <= MaxClients; i++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(i))
		{
			continue;
		}

		// Removes the zombie empowering from the client turning him in to humans again
		PowerZombieApocalypseCreateHuman(i);
	}

	// Changes the team that is currently affected with the zombie apocalypse to 0
	powerZombieAffectedTeam = 0;
}


// This happens when the king dies or the round resets
public void PowerZombieApocalypseSpawn(int client)
{
	// If the currently active power is not Zombie Apocalypse then execute this section
	if(!powerZombieApocalypse)
	{
		return;
	}

	// Turns the client in to a zombie with 150 health, and 80% of the normal movement speed
	PowerZombieApocalypseCreateZombie(client, 150, 0.80);
}


// This happens when the player dies while Zombie Apocalypse is active
public void ZombieApocalypseOnDeath(int client)
{
	// If the currently active power is not Zombie Apocalypse then execute this section
	if(powerZombieApocalypse)
	{
		return;
	}

	// Removes the screen overlay from the player
	RemoveScreenOverlay(client);
}


// This function is called upon briefly after a player changes team or dies
public Action Timer_PowerZombieApocalypseAmbience(Handle timer)
{
	// If the currently active power is not Zombie Apocalypse then execute this section
	if(!powerZombieApocalypse)
	{
		return Plugin_Continue;
	}

	// If the sound is not already precached then execute this section
	if(!IsSoundPrecached("kingmod/power_zombieapocalypseambience.mp3"))
	{	
		// Precaches the sound file
		PrecacheSound("kingmod/power_zombieapocalypseambience.mp3", true);
	}

	// Loops through all of the clients
	for (int i = 1; i <= MaxClients; i++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(i))
		{
			continue;
		}

		// If the client is a bot then execute this section
		if(IsFakeClient(i))
		{
			continue;
		}

		// Emits a sound to the specified client that only they can hear
		EmitSoundToClient(i, "kingmod/power_zombieapocalypseambience.mp3", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.00, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}

	// Plays the ambient sound that will be running while the zombie apocalypse power is active
	CreateTimer(55.0, Timer_PowerZombieApocalypseAmbience, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}



////////////////////////////
// - Power Blast Cannon - //
////////////////////////////


// This happens when a king acquires the Blast Cannon power 
public void PowerBlastCannon(int client)
{
	// Turns on the Blast Cannon king power 
	powerBlastCannon = true;

	// Obtains the client's team index and store it within the powerZombieAffectedTeam variable
	powerZombieAffectedTeam = GetClientTeam(client);

	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_placeholder.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "---------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Blast Cannon";
	
	// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
	nameOfTier = "Tier A";

	// Specifies which special weapon the king should be given
	kingWeapon = "weapon_sawedoff";

	// Gives the king a unique weapon if the current power requires one
	CreateTimer(0.25, Timer_GiveKingUniqueWeapon, client);
}



///////////////////////////////
// - Power Deagle Headshot - //
///////////////////////////////


// This happens when a king acquires the Deagle Headshot power 
public void PowerDeagleHeadshot(int client)
{
	// Turns on the Deagle Headshot king power 
	powerDeagleHeadshot = true;

	// Obtains the client's team index and store it within the powerZombieAffectedTeam variable
	powerZombieAffectedTeam = GetClientTeam(client);

	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_placeholder.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "--------------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Deagle Headshot";
	
	// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
	nameOfTier = "Tier A";

	// Specifies which special weapon the king should be given
	kingWeapon = "weapon_deagle";

	// Gives the king a unique weapon if the current power requires one
	CreateTimer(0.25, Timer_GiveKingUniqueWeapon, client);
}


// This happens when a deagle has been spawned
public Action entity_DeagleSpawned(int entity)
{
	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Changes the clip to 1 and the ammo to 1 after 2.19 seconds
	CreateTimer(0.1, Timer_PowerDeagleHeadshotDefaultAmmo, entity, TIMER_FLAG_NO_MAPCHANGE);

	// Adds a hook to the revolver entity which will let us track when the entity is reloaded
	SDKHook(entity, SDKHook_ReloadPost, OnWeaponReloadPostDeagle);

	return Plugin_Continue;
}


// This happens 0.1 second after a deagle has been spawned
public Action Timer_PowerDeagleHeadshotDefaultAmmo(Handle timer, int weapon)
{
	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(weapon))
	{
		return Plugin_Continue;
	}

	// Changes the amount of bullets there are inside of the deagle's clip
	SetEntProp(weapon, Prop_Send, "m_iClip1", 1);

	// Changes the ammount of ammo that the player has for their weapon
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 1);

	return Plugin_Continue;
}

 
// This happens when the player starts to reload his deagle
public Action OnWeaponReloadPostDeagle(int weapon)
{
	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(weapon))
	{
		return Plugin_Continue;
	}

	// Obtains and stores the entity owner offset within our client variable 
	int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Adds 2.3 seconds cooldown to when the player would be able to use the secondary attack / zoom function 
	SetEntDataFloat(weapon, FindSendPropOffs("CBaseCombatWeapon", "m_flNextPrimaryAttack"), GetGameTime() + 2.4);

	// Changes the clip to 1 and the ammo to 1 after 2.21 seconds
	CreateTimer(2.21, Timer_PowerDeagleHeadshotDefaultAmmo, weapon, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}


/////////////////////////////
// - Power Laser Pointer - //
/////////////////////////////



// This happens when a king acquires the Laser Pointer power 
public void PowerLaserPointer(int client)
{
	// Turns on the Laser Pointer king power 
	powerLaserPointer = true;

	// Obtains the client's team index and store it within the powerZombieAffectedTeam variable
	powerZombieAffectedTeam = GetClientTeam(client);

	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_placeholder.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "----------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Laser Pointer";
	
	// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
	nameOfTier = "Tier A";
}


// This happens when the king fires his cz75a while the laser gun power is currently active
public bool TraceRayHitPlayers(int entity, int mask, int client)
{
	// If the entity is the same as the client then execute this section 
	if(entity == client)
	{
		return false;
	}
	
	return true;
}


// This happens 0.083 seconds after the king uses his laser pointer
public Action Timer_RemoveLaserPointerTickCoolDown(Handle Timer, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Changes the player's LaserPointerTickCoolDown state to false
	LaserPointerTickCoolDown[client] = false;

	return Plugin_Continue;
}



///////////////////////////
// - Power Hammer Time - //
///////////////////////////


// This happens when a king acquires the Hammer Time power 
public void PowerHammerTime(int client)
{
	// Turns on the Hammer Time king power 
	powerHammerTime = true;

	// Obtains the client's team index and store it within the powerZombieAffectedTeam variable
	powerZombieAffectedTeam = GetClientTeam(client);

	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_placeholder.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "----------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Hammer Time";
	
	// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
	nameOfTier = "Tier A";

	// Specifies which special weapon the king should be given
	kingWeapon = "weapon_hammer";

	// Gives the king a unique weapon if the current power requires one
	CreateTimer(0.25, Timer_GiveKingUniqueWeapon, client);
}


// This happens 2.25 seconds after a player has been knocked down in the ground by the king while the Hammer Time power is active
public Action Timer_HammerKnockDown(Handle timer, int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// If the powerHammerTimeBuried is not on cooldown then execute this section
	if(powerHammerTimeBuried[client])
	{
		// Creates a variable called playerLocation which we will use to store data within
		float playerLocation[3];

		// Obtains the player's current location and store it within our playerLocation variable
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerLocation);

		// Adds 35.0 from the player's current position on the z-axis
		playerLocation[2] += 42.5;

		// Teleports the prop to the location where the player died
		TeleportEntity(client, playerLocation, NULL_VECTOR, NULL_VECTOR);
	}

	// Sets the powerHammerTimeBuried cooldown state to false
	powerHammerTimeBuried[client] = false;

	return Plugin_Continue;
}


// This happens when a player dies while the hammer time power is active
public void PowerHammerTimeDeath(int client)
{
	// If the Hammer Time power is not currently active then execute this section
	if(!powerHammerTime)
	{
		return;
	}

	// If the powerHammerTimeBuried is not on cooldown then execute this section
	if(powerHammerTimeBuried[client])
	{
		// Sets the powerHammerTimeBuried cooldown state to false
		powerHammerTimeBuried[client] = false;
	}
}


// This happens when the king dies or a new round starts
public void RemoveAllBuryCooldowns()
{
	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// If the powerHammerTimeBuried is not on cooldown then execute this section
		if(powerHammerTimeBuried[client])
		{
			// Sets the powerHammerTimeBuried cooldown state to false
			powerHammerTimeBuried[client] = false;
		}
	}
}



/////////////////////////////
// - Power Doom Chickens - //
/////////////////////////////


// This happens when a king acquires the Doom Chickens power 
public void PowerDoomChickens(int client)
{
	// Turns on the Doom Chickens king power 
	powerDoomChickens = true;

	// Obtains the client's team index and store it within the powerZombieAffectedTeam variable
	powerZombieAffectedTeam = GetClientTeam(client);

	// Changes the name of the path for the sound that is will be played when the player acquires the specific power
	powerSoundName = "kingmod/power_placeholder.mp3";

	// Changes the content of the dottedLine variable to match the length of the name of power and tier
	dottedLine = "------------------------------";

	// Changes the content of the nameOfPower variable to reflect which power the king acquired
	nameOfPower = "Doom Chickens";
	
	// Changes the content of the nameOfTier variable to reflect which tier of the power the king acquired
	nameOfTier = "Tier A";
}


public void SpawnDoomChicken(int client)
{
	// If the doom Doom Chickens power is not currently enabled then execute this section
	if(!powerDoomChickens)
	{
		// 
		return;
	}

	// Creates a variable to store our data within
	float playerLocation[3];

	// Obtains the location of the client and store it within the playerLocation variable
	GetClientAbsOrigin(client, playerLocation);

	// Changes the obtained player location by +64 on the z-axis
	playerLocation[2] += 64;

	// Creates a healthshot and store it's index within our entity variable
	int entity = CreateEntityByName("chicken");

	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return;
	}

	float entityScale = 1.0;

	int randomNumber = GetRandomInt(1, 3);

	if(randomNumber == 1)
	{
		entityScale = 2.05;
	}
	else if(randomNumber == 2)
	{
		entityScale = 2.45;
	}
	else if(randomNumber == 3)
	{
		entityScale = 2.85;
	}

	// Changes the size of the chicken to be a value between 2.05 and 3.40
	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", entityScale);

	// Changes the color of the entity to a random predefined color
	SetRandomColor(entity);

	// Attaches a light_dynamic entity to the healthshot of a random predefined color
	SetRandomLightColor(entity);

	AttachC4Bomb(entity, entityScale);

	// Spawns the entity
	DispatchSpawn(entity);

	// Teleports the entity to the specified coordinates relative to the player and rotate it
	TeleportEntity(entity, playerLocation, NULL_VECTOR, NULL_VECTOR);
}


// This happens when a player dies and drops a healthshot
public Action AttachC4Bomb(int entityChicken, float entityScale)
{
	// Creates a prop_dynamic and store the it within the entity variable
	int entity = CreateEntityByName("prop_dynamic");

	// If the entity does not meet our criteria validation then execute this section
	if(!IsValidEntity(entity))
	{
		return;
	}

	// If the model is not precached then execute this section
	if(!IsModelPrecached("models/weapons/w_c4_planted.mdl"))
	{
		// Precaches the model
		PrecacheModel("models/weapons/w_c4_planted.mdl");
	}


	// Changes the color of the SoulPrism to standard color
	DispatchKeyValue(entity, "rendercolor", "255 255 255");

	// Changes the model of the prop to a crown
	DispatchKeyValue(entity, "model", "models/weapons/w_c4.mdl");

	// Turns off receiving shadows for the model
	DispatchKeyValue(entity, "disablereceiveshadows", "1");

	// Turns off the model's own shadows 
	DispatchKeyValue(entity, "disableshadows", "1");
	
	// Changes the solidity of the model to be unsolid
	DispatchKeyValue(entity, "solid", "0");
	
	// Changes the spawn flags of the model
	DispatchKeyValue(entity, "spawnflags", "256");

	// Changes the collisiongroup to that of the ones used by weapons in CS:GO as well
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 11);
	
	// Spawns the crown model in to the world
	DispatchSpawn(entity);

	// Creates a variable which we will use to store our data within
	float entityLocation[3];

	// Creates a variable which we will use to store our data within
	float entityRotation[3];

	// Modifies the placement of the light_dynamic's z-coordinate position
	if(entityScale == 2.05)
	{
		// + Front / - Back
		entityLocation[0] -= 11.0;

		// + Left / - Right
		entityLocation[1] += 10.5;

		// + Up / - Down
		entityLocation[2] += 26.0;

		// Sets rotation of the entity's X, Y and Z axises
		entityRotation[0] = 26.89;
		entityRotation[1] = 260.28;
		entityRotation[2] = 0.57;
	}

	if(entityScale == 2.45)
	{
		// + Front / - Back
		entityLocation[0] -= 15.0;

		// + Left / - Right
		entityLocation[1] += 12.5;

		// + Up / - Down
		entityLocation[2] += 29.5;

		// Sets rotation of the entity's X, Y and Z axises
		entityRotation[0] = 26.89;
		entityRotation[1] = 260.28;
		entityRotation[2] = 0.57;
	}

	if(entityScale == 2.85)
	{
		// + Front / - Back
		entityLocation[0] -= 14.35;

		// + Left / - Right
		entityLocation[1] += 13.05;

		// + Up / - Down
		entityLocation[2] += 33.5;

		// Sets rotation of the entity's X, Y and Z axises
		entityRotation[0] = 26.89;
		entityRotation[1] = 260.28;
		entityRotation[2] = 0.57;
	}

	// Changes the variantstring to !activator
	SetVariantString("!activator");
	
	// Changes the parent of the light_dynamic to be the spawned healthshot
	AcceptEntityInput(entity, "SetParent", entityChicken, entity, 0);
	
	// Teleports the light_dynamic to the specified coordinate location
	TeleportEntity(entity, entityLocation, entityRotation, NULL_VECTOR);
}


public void DestroyChickenEntities()
{
	// Loops through all entities that are currently in the game
	for (int entity = MaxClients + 1; entity <= GetMaxEntities(); entity++)
	{
		// If the entity does not meet our criteria of validation then execute this section
		if(!IsValidEntity(entity))
		{
			continue;
		}

		// Creates a variable which we will use to store data within
		char className[64];

		// Obtains the entity's class name and store it within our className variable
		GetEntityClassname(entity, className, sizeof(className));

		// If the entity is a dronegun then execute this section
		if(!StrEqual(className, "chicken"))
		{	
			continue;
		}

		// Kills the weapon entity, removing it from the game
		AcceptEntityInput(entity, "Kill");
	}
}



////////////////////////////////
// - Return Based Functions - //
////////////////////////////////


// Returns true if the client meets the validation criteria. elsewise returns false
public bool IsValidClient(int client)
{
	if(!(1 <= client <= MaxClients) || !IsClientConnected(client) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client))
	{
		return false;
	}

	return true;
}


// Returns true if there is a current knife king, elsewise returns false
public bool IsThereACurrentKing()
{
	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// If the client is not the king then execute this section
		if(!isPlayerKing[client])
		{
			continue;
		}

		return true;
	}

	return false;
}



/////////////////////////////////////////
// - Administrator Command Functions - //
/////////////////////////////////////////


// This happens when an administrator with root access uses the sm_platform command
public Action Command_DeveloperMenu(int client, int args)
{
	// Creates a variable which we will use to store data within
	float PlayerLocation[3];

	// Creates a variable which we will use to store data within
	char CurrentMapName[64];

	// Obtains the name of the current map and then store it within the CurrentMapName variable
	GetCurrentMap(CurrentMapName, sizeof(CurrentMapName));

	// Obtains the location of the client and store it within our PlayerLocation variable
	GetClientAbsOrigin(client, PlayerLocation);
	
	// Sends a message to the player's console that can be easily copied and added to the addons/sourcemod/configs/platforms.txt
	PrintToConsole(client, "");
	PrintToConsole(client, "");
	PrintToConsole(client, "");
	PrintToConsole(client, "    \"%s platform\"", CurrentMapName);
	PrintToConsole(client, "    {");
	PrintToConsole(client, "        \"map\"                      \"%s\"", CurrentMapName);
	PrintToConsole(client, "");
	PrintToConsole(client, "        \"location_x\"               \"%0.2f\"", PlayerLocation[0]);
	PrintToConsole(client, "        \"location_y\"               \"%0.2f\"", PlayerLocation[1]);
	PrintToConsole(client, "        \"location_z\"               \"%0.2f\"", PlayerLocation[2]);
	PrintToConsole(client, "");
	PrintToConsole(client, "        \"hide_minimap\"             \"0\"");
	PrintToConsole(client, "    }");
	PrintToConsole(client, "");
	PrintToConsole(client, "");
	PrintToConsole(client, "");
}


//////////////////////////////////////
// - Download & Precache Function - //
//////////////////////////////////////


public void DownloadAndPrecacheFiles()
{
	// Weapon Restriction
	AddFileToDownloadsTable("sound/kingmod/sfx_restrictedweapon.mp3");
	PrecacheSound("kingmod/sfx_restrictedweapon.mp3");


	// Crown Model
	AddFileToDownloadsTable("materials/models/props/vip.vmt");
	AddFileToDownloadsTable("materials/models/props/vip.vtf");
	AddFileToDownloadsTable("models/props/crown.dx90.vtx");
	AddFileToDownloadsTable("models/props/crown.mdl");
	AddFileToDownloadsTable("models/props/crown.vvd");
	PrecacheModel("models/props/crown.mdl");


	// Visual Effect Sprites
	AddFileToDownloadsTable("materials/kingmod/sprites/lgtning.vtf");
	AddFileToDownloadsTable("materials/kingmod/sprites/lgtning.vmt");
	effectRing = PrecacheModel("materials/kingmod/sprites/lgtning.vmt");


	// Power Chooser System
	AddFileToDownloadsTable("sound/kingmod/power_acquiringpower.mp3");
	PrecacheSound("kingmod/power_acquiringpower.mp3");


	// Power - Impregnable Armor
	AddFileToDownloadsTable("materials/kingmod/overlays/power_assaultsuit.vtf");
	AddFileToDownloadsTable("materials/kingmod/overlays/power_assaultsuit.vmt");
	AddFileToDownloadsTable("sound/kingmod/power_impregnablearmor.mp3");
	PrecacheModel("materials/kingmod/overlays/power_assaultsuit.vmt");
	PrecacheModel("materials/models/player/custom_player/legacy/tm_phoenix_heavy.mdl");
	PrecacheModel("models/weapons/v_models/arms/phoenix_heavy/v_sleeve_phoenix_heavy.mdl");
	PrecacheSound("kingmod/power_impregnablearmor.mp3");
	PrecacheSound("items/nvg_on.wav");

	// Power - Movement Speed
	AddFileToDownloadsTable("sound/kingmod/power_movementspeed.mp3");
	PrecacheSound("kingmod/power_movementspeed.mp3");


	// Power - Sticky Nades
	AddFileToDownloadsTable("sound/kingmod/power_stickynades.mp3");
	PrecacheSound("kingmod/power_stickynades.mp3");


	// Power - Scout No Scope
	AddFileToDownloadsTable("sound/kingmod/power_scoutnoscope.mp3");
	PrecacheSound("kingmod/power_scoutnoscope.mp3");


	// Power - Carpet Bombing Flashbangs
	AddFileToDownloadsTable("sound/kingmod/power_carpetbombingflashbangs.mp3");
	PrecacheSound("kingmod/power_carpetbombingflashbangs.mp3");


	// Power - Napalm
	AddFileToDownloadsTable("sound/kingmod/power_napalm.mp3");
	PrecacheSound("kingmod/power_napalm.mp3");


	// Power - Riot
	AddFileToDownloadsTable("sound/kingmod/power_riot.mp3");
	PrecacheSound("kingmod/power_riot.mp3");


	// Power - Vampire
	AddFileToDownloadsTable("sound/kingmod/power_vampire.mp3");
	PrecacheSound("kingmod/power_vampire.mp3");


	// Power - Breachcharges
	AddFileToDownloadsTable("sound/kingmod/power_breachcharges.mp3");
	PrecacheSound("kingmod/power_breachcharges.mp3");


	// Power - Leg Crushing Bumpmines
	AddFileToDownloadsTable("sound/kingmod/power_legcrushingbumpmines.mp3");
	PrecacheSound("kingmod/power_legcrushingbumpmines.mp3");


	// Power - Hatchet Massacre
	AddFileToDownloadsTable("sound/kingmod/power_hatchetmassacre.mp3");
	AddFileToDownloadsTable("materials/kingmod/overlays/power_hatchetmassacre.vmt");
	AddFileToDownloadsTable("materials/kingmod/overlays/power_hatchetmassacre.vtf");
	PrecacheModel("materials/kingmod/overlays/power_hatchetmassacre.vmt");
	PrecacheSound("kingmod/power_hatchetmassacre.mp3");


	// Power - Chuck Norris
	AddFileToDownloadsTable("sound/kingmod/power_chucknorris.mp3");
	PrecacheSound("kingmod/power_chucknorris.mp3");


	// Power - Laser Gun
	AddFileToDownloadsTable("materials/kingmod/sprites/laserbeam.vtf");
	AddFileToDownloadsTable("materials/kingmod/sprites/laserbeam.vmt");
	AddFileToDownloadsTable("sound/kingmod/power_lasergun.mp3");
	effectLaser = PrecacheModel("materials/kingmod/sprites/laserbeam.vmt");
	PrecacheSound("kingmod/power_lasergun.mp3");


	// Power - Lucky Number Seven
	AddFileToDownloadsTable("sound/kingmod/power_luckynumberseven.mp3");
	PrecacheSound("kingmod/power_luckynumberseven.mp3");


	// Power - Western Shootout
	AddFileToDownloadsTable("sound/kingmod/power_westernshootout.mp3");
	PrecacheSound("kingmod/power_westernshootout.mp3");


	// Power - Babonic Plague
	AddFileToDownloadsTable("sound/kingmod/power_babonicplague.mp3");
	AddFileToDownloadsTable("materials/kingmod/overlays/power_babonicplague.vmt");
	AddFileToDownloadsTable("materials/kingmod/overlays/power_babonicplague.vtf");
	AddFileToDownloadsTable("materials/kingmod/overlays/power_babonicplaguedudv.vmt");
	AddFileToDownloadsTable("materials/kingmod/overlays/power_babonicplaguedudv.vtf");
	AddFileToDownloadsTable("materials/kingmod/overlays/power_babonicplaguenormal.vtf");
	PrecacheModel("materials/kingmod/overlays/power_babonicplague.vmt");
	PrecacheSound("kingmod/power_babonicplague.mp3");


	// Power - Zombie Apocalypse
	AddFileToDownloadsTable("materials/skybox/zombienightbk.vtf");
	AddFileToDownloadsTable("materials/skybox/zombienightbk.vmt");
	AddFileToDownloadsTable("materials/skybox/zombienightdn.vtf");
	AddFileToDownloadsTable("materials/skybox/zombienightdn.vmt");
	AddFileToDownloadsTable("materials/skybox/zombienightft.vtf");
	AddFileToDownloadsTable("materials/skybox/zombienightft.vmt");
	AddFileToDownloadsTable("materials/skybox/zombienightlf.vtf");
	AddFileToDownloadsTable("materials/skybox/zombienightlf.vmt");
	AddFileToDownloadsTable("materials/skybox/zombienightrt.vtf");
	AddFileToDownloadsTable("materials/skybox/zombienightrt.vmt");
	AddFileToDownloadsTable("materials/skybox/zombienightup.vtf");
	AddFileToDownloadsTable("materials/skybox/zombienightup.vmt");
	AddFileToDownloadsTable("materials/kingmod/overlays/power_zombieapocalypsezombie.vtf");
	AddFileToDownloadsTable("materials/kingmod/overlays/power_zombieapocalypsezombie.vmt");
	AddFileToDownloadsTable("materials/kingmod/overlays/power_zombieapocalypsehuman.vtf");
	AddFileToDownloadsTable("materials/kingmod/overlays/power_zombieapocalypsehuman.vmt");
	AddFileToDownloadsTable("sound/kingmod/sfx_zombiescream.mp3");
	AddFileToDownloadsTable("sound/kingmod/power_zombieapocalypse.mp3");
	AddFileToDownloadsTable("sound/kingmod/power_zombieapocalypseambience.mp3");

	PrecacheModel("materials/kingmod/overlays/power_zombieapocalypsezombie.vmt");
	PrecacheModel("materials/kingmod/overlays/power_zombieapocalypsehuman.vmt");
	PrecacheModel("models/player/zombie.mdl");
	PrecacheModel("models/player/tm_phoenix.mdl");
	PrecacheModel("models/player/ctm_idf.mdl");
	PrecacheSound("kingmod/sfx_zombiescream.mp3");
	PrecacheSound("kingmod/power_zombieapocalypse.mp3");
	PrecacheSound("kingmod/power_zombieapocalypseambience.mp3");






	effectSmoke = PrecacheModel("sprites/steam2.vmt");
	effectExplosion = PrecacheModel("sprites/blueglow2.vmt");
}
