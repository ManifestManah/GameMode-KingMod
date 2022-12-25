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

int cvar_PointsNormalKill = 1;
int cvar_PointsKingKill = 3;

float cvar_RespawnTime = 1.50;



//////////////////////////
// - Global Variables - //
//////////////////////////


// Global Booleans
bool gameInProgress = true;
bool mapHasPlatformSupport = false;

bool isPlayerKing[MAXPLAYERS + 1] = {false,...};


// Global Integers
int kingIsOnTeam = 0;
int pointCounterT = 0;
int pointCounterCT = 0;

int EntityOwner[2049] = {-1, ...};



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
	// Hooks the events that we intend to use in our plugin
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);

	// Calls upon our CommandListenerJoinTeam function whenever a player changes team
	AddCommandListener(CommandListenerJoinTeam, "jointeam");

	// Creates a timer that will update the team score hud every 1 second
	CreateTimer(1.0, UpdateTeamScoreHud, _, TIMER_REPEAT);

	// Adds all of the game mode's required files to the download list and precaches content that needs precaching
	DownloadAndPrecacheFiles();

	// Allows the modification to be loaded while the server is running, without causing gameplay issues
	LateLoadSupport();

	// Loads the translaltion file which we intend to use
	LoadTranslations("manifest_kingmod.phrases");
}


// This happens when a new map is loaded
public void OnMapStart()
{
	// Adds all of the game mode's required files to the download list and precaches content that needs precaching
	DownloadAndPrecacheFiles();

	// Checks if the current map has been configured to have platform support included 
	CheckForPlatformSupport();
}


// This happens when a player disconnects
public void OnClientDisconnect(int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return;
	}

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

			// If the map have been configured to have platform support then execute this section
			if(mapHasPlatformSupport)
			{
				// Teleports the client to the specified location of the map's platform
				TeleportEntity(attacker, platformLocation, NULL_VECTOR, NULL_VECTOR);
			}

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

	// If the map have been configured to have platform support then execute this section
	if(mapHasPlatformSupport)
	{
		// Teleports the client to the specified location of the map's platform
		TeleportEntity(attacker, platformLocation, NULL_VECTOR, NULL_VECTOR);
	}

	// Assigsn a clantag to the player which indicates that the player is the current king
	AssignClanTag(attacker);

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



///////////////////////////
// - Regular Functions - //
///////////////////////////


public void LateLoadSupport()
{
	// Changes the kingName variable's value to just be None
	kingName = "None";
}


// This function is called upon whenever a new round starts or a new map is loaded
void CheckForPlatformSupport()
{
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




///////////////////////////////
// - Timer Based Functions - //
///////////////////////////////


// This function happens once every 1 second and is used to update the custom team score hud element
public Action UpdateTeamScoreHud(Handle timer, any unused)
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

		// Displays the contents of our hudMessage variable for the client to see in the hint text area of their screen 
		PrintHintText(client, hudMessage);
	}

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
}