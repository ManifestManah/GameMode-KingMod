///////////////////////
// Actual Code Below //
///////////////////////

// List of Includes
#include <sourcemod>

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


// Global Booleans
bool IsPlayerKing[MAXPLAYERS + 1] = {false,...};

bool IsThereAlreadyAKing = false;
bool PlatformFailSafe = false;
bool IsGameInProgress = true;




// Global Integers
int KingProtectionCount[MAXPLAYERS + 1] = {0, ...};



// This happens when the plugin is loaded
public void OnPluginStart()
{
	// Hooks the events that we intend to use in our plugin

	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);

}




public void OnClientDisconnect(int client)
{
	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return;
	}

	// If the client is not the current king then execute this section
	if(!IsPlayerKing[client])
	{
		return;
	}

	// Changes the killed player's king status to false
	IsPlayerKing[client] = false;

	PrintToChatAll("Debug: The king has disconnected from the game");

	return;
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
		return Plugin_Continue;
	}

	// If the client is the current king then execute this section
	if(IsPlayerKing[client])
	{
		// Changes the killed player's king status to false
		IsPlayerKing[client] = false;
		PrintToChatClient(client, "Debug: You lost your kingship as were killed");

		// Changes the attacking player's king status to true
		IsPlayerKing[attacker] = true;
		PrintToChatClient(attacker, "Debug: You stole the king title from the enemy that died");

		return Plugin_Continue;
	}

	// If there is not a king currently then execute this section
	if(!IsThereACurrentKing())
	{
		// Changes the attacking player's king status to true
		IsPlayerKing[attacker] = true;

		PrintToChatClient(attacker, "Debug: You became the new king");
	}

	return Plugin_Continue;
}








// This happens when the round starts 
public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// If the client is not the current king then execute this section
		if(!IsPlayerKing[client])
		{
			continue;
		}

		// Changes the client king status to false
		IsPlayerKing[client] = false;

		PrintToChatAll("Debug: A new round has started, kill an enemy to become the first King");

		break;
	}

	return Plugin_Continue;
}









////////////////////////////////
// - Return Based Functions - //
////////////////////////////////


// Returns true if the client meets the validation criteria. elsewise returns false
public bool IsValidClient(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientConnected(client) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client))
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
		if(!IsPlayerKing[client])
		{
			continue;
		}

		return true;
	}

	return false;
}