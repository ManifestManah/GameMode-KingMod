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

int cvar_PointsNormalKill = 1;
int cvar_PointsKingKill = 3;

int cvar_KingHealth = 200;

float cvar_RespawnTime = 1.50;
float cvar_ImmobilityTime = 3.00;
float cvar_SpawnProtectionDuration = 3.0;
float cvar_RecoveryCooldownDuration = 10.00;


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


// Global Integers
int kingIsOnTeam = 0;
int pointCounterT = 0;
int pointCounterCT = 0;
int mapHasMinimapHidden = 0;
int kingRecoveryCounter = 0;
int effectSprite = 0;
int weaponOwner = -1;

int PlayerSpawnCount[MAXPLAYERS+1] = {0, ...};
int EntityOwner[2049] = {-1, ...};


// Global Floats
float platformLocation[3];


// Global Characters
char kingName[64];

char PlayerClanTag[MAXPLAYERS + 1][14];



//////////////////////////
// - Forwards & Hooks - //
//////////////////////////


// This happens when the plugin is loaded
public void OnPluginStart()
{
	// Adds a command only available to administrators with the Root flag
	RegAdminCmd("sm_platform", Command_DeveloperMenu, ADMFLAG_ROOT);

	// Hooks the events that we intend to use in our plugin
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);

	// Calls upon our CommandListenerJoinTeam function whenever a player changes team
	AddCommandListener(CommandListenerJoinTeam, "jointeam");

	// Obtains and stores the entity owner offset within our weaponOwner variable 
	weaponOwner = FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity");

	// Creates a timer that will update the team score hud every 1.0 second
	CreateTimer(1.0, Timer_UpdateTeamScoreHud, _, TIMER_REPEAT);

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

	// Removes the hook that we had added to the player to track when he was eligible to pick up weapons
	SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);

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
		// If the weapon's entity name is weapon_knifegg then execute this section
		if(StrEqual(ClassName, "weapon_knifegg", false))
		{
			return Plugin_Continue;
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

	// If the attacker does not meet our validation criteria then execute this section
	if(!IsValidClient(attacker))
	{
		return Plugin_Continue;
	}

	// If the attacker is the same as the victim (suicide) then execute this section
	if(attacker == client)
	{
		// If the client is not the current king then execute this section
		if(!isPlayerKing[client])
		{
			return Plugin_Continue;
		}

		// Changes the killed player's king status to false
		isPlayerKing[client] = false;

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

	// If there is the king currently then execute this section
	if(IsThereACurrentKing())
	{
		// If the client is the current king then execute this section
		if(isPlayerKing[client])
		{
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

			// Strips the client of all their weapons
			StripPlayerOfWeapons(attacker);

			// After 0.1 seconds gives the player a golden knife
			CreateTimer(0.1, Timer_GiveGoldenKnife, attacker, TIMER_FLAG_NO_MAPCHANGE);

			// If the map have been configured to have platform support then execute this section
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

	// Strips the client of all their weapons
	StripPlayerOfWeapons(attacker);

	// After 0.1 seconds gives the player a golden knife
	CreateTimer(0.1, Timer_GiveGoldenKnife, attacker, TIMER_FLAG_NO_MAPCHANGE);

	// If the map have been configured to have platform support then execute this section
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
	// Checks if the current map has been configured to have platform support included 
	CheckForPlatformSupport();

	// Changes the gameInProgress state to true
	gameInProgress = true;

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


public void LateLoadSupport()
{
	// Changes the kingName variable's value to just be None
	kingName = "None";

	// Forcefully ends the round and considers it a round draw
	CS_TerminateRound(3.0, CSRoundEnd_Draw);

	PrintToChatAll("King Mod has been loaded. ");
	PrintToChatAll("A new round will soon commence.");

	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// Adds a hook to the client which will let us track when the player is eligible to pick up a weapon
		SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
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

	// Plays a sound that only the king can hear
	ClientCommand(client, "play */manifest/kingmod/king_threat_detected.wav");

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
		TE_SetupBeamRingPoint(playerLocation, 40.0, 2000.0, effectSprite, effectSprite, 0, 20, 1.5, 90.0, 2.0, effectColor, 1, 1);

		// Sends the visual effect temp entity to the players with visual headshot effects enabled 
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
	DispatchKeyValue(point_tesla, "texture", "manifest/sprites/lgtning.vmt");

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

		// Displays the contents of our hudMessage variable for the client to see in the hint text area of their screen 
		PrintHintText(client, hudMessage);
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

		// If the entity has an ownership relation to somebody or something, then execute this section
		if(GetEntDataEnt2(entity, weaponOwner) != -1)
		{
			continue;
		}

		PrintToChatAll("Debug removed weapon %s", className);

		// Removes the entity from the map 
		AcceptEntityInput(entity, "Kill");
	}

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

	// Gives the client the specified weapon
	GivePlayerItem(client, "weapon_knifegg");

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

	// Changes the movement speed of the player to 1.0 essentially returning their movement to the normal speed
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);

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
	AddFileToDownloadsTable("materials/models/props/vip.vmt");
	AddFileToDownloadsTable("materials/models/props/vip.vtf");
	AddFileToDownloadsTable("models/props/crown.dx90.vtx");
	AddFileToDownloadsTable("models/props/crown.mdl");
	AddFileToDownloadsTable("models/props/crown.vvd");

	PrecacheModel("models/props/crown.mdl");

	AddFileToDownloadsTable("materials/kingmod/sprites/lgtning.vtf");
	AddFileToDownloadsTable("materials/kingmod/sprites/lgtning.vmt");

	effectSprite = PrecacheModel("kingmod/sprites/lgtning.vmt");
}