///////////////////////
// Actual Code Below //
///////////////////////

// List of Includes
#include <sourcemod>
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

bool isPlayerKing[MAXPLAYERS + 1] = {false,...};


// Global Integers
int kingIsOnTeam = 0;
int pointCounterT = 0;
int pointCounterCT = 0;


// Global Characters
char kingName[64];


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

	// Creates a timer that will update the team score hud every 1 second
	CreateTimer(1.0, UpdateTeamScoreHud, _, TIMER_REPEAT);

	// Loads the translaltion file which we intend to use
	LoadTranslations("manifest_kingmod.phrases");
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

	// Changes the indicator of which team the King is currently on be none
	kingIsOnTeam = 0;

	// Changes the kingName variable's value to just be None
	kingName = "None";

	PrintToChatAll("Debug: The king has disconnected from the game");

	return;
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
	// If the game is not currently in progress then execute this section	
	if(!gameInProgress)
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
		PrintToChat(client, "Debug: You lost your kingship because you committed suicide");

		// Changes the indicator of which team the King is currently on be none
		kingIsOnTeam = 0;

		// Changes the kingName variable's value to just be None
		kingName = "None";

		return Plugin_Continue;
	}

	// If there is a king currently then execute this section
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
				// Adds the value of cvar_PointsNormalKill to the pointCounterT variable's value
				pointCounterT += cvar_PointsNormalKill;
			}
			// If the attacker is on the Coutner-Terrorist team then execute this section
			if(GetClientTeam(attacker) == 3)
			{
				// Adds the value of cvar_PointsNormalKill to the pointCounterCT variable's value
				pointCounterCT += cvar_PointsNormalKill;
			}

			return Plugin_Continue;
		}
	}

	// Changes the attacking player's king status to true
	isPlayerKing[attacker] = true;
	PrintToChat(attacker, "Debug: You became the new king");

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

	// Changes the indicator of which team the King is currently on to be on no team
	kingIsOnTeam = 0;

	// Changes the kingName variable's value to just be None
	kingName = "None";
	
	// Resets the terrorists' team score back to 0 
	pointCounterT = 0;

	// Resets the counter-terrorists' team score back to 0
	pointCounterCT = 0;

	PrintToChatAll("Debug: A new round has started, kill an enemy to become the first King");

	return Plugin_Continue;
}



// This happens when the round ends
public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	// Changes the gameInProgress state to false
	gameInProgress = false;

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

		// If the Terrorist team have more points than the Counter-Terrorist team then execute this section
		if(pointCounterT > pointCounterCT)
		{
			// Sends a colored multi-language message to everyone in the chat area
			// CPrintToChat(client, "%t", "Terrorists Won", pointCounterT, pointCounterCT);
			PrintToChat(client, "Round Draw - T: %i CT: %i", pointCounterT, pointCounterCT);

		}

		// If the Terrorist team have less points than the Counter-Terrorist team then execute this section
		else if(pointCounterT < pointCounterCT)
		{
			// Sends a colored multi-language message to everyone in the chat area
			// CPrintToChat(client, "%t", "Counter-Terrorists Won", pointCounterT, pointCounterCT);
			PrintToChat(client, "Round Draw - T: %i CT: %i", pointCounterT, pointCounterCT);
		}

		// If the Terrorist team have the same amount of points as the Counter-Terrorist team then execute this section
		else
		{
			// Sends a colored multi-language message to everyone in the chat area
			// CPrintToChat(client, "%t", "Round Draw", pointCounterT, pointCounterCT);
			PrintToChat(client, "Round Draw - T: %i CT: %i", pointCounterT, pointCounterCT);
		}
	}



	PrintToChatAll("Debug: A new round has started, kill an enemy to become the first King");

	return Plugin_Continue;
}



///////////////////////////
// - Regular Functions - //
///////////////////////////






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

		// If the client is not a king then execute this section
		if(!isPlayerKing[client])
		{
			continue;
		}

		return true;
	}

	return false;
}
