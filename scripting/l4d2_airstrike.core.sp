/*
*	F-18 Airstrike
*	Copyright (C) 2023 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION		"1.12"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] F-18 Airstrike
*	Author	:	SilverShot
*	Descrp	:	Creates F-18 flybys which shoot missiles to where they were triggered from.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=187567
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.12 (20-Dec-2023)
	- Added cvar "l4d2_airstrike_time" to set the interval between multiple Airstrikes. Requested by "bsdvjhdabf".
	- Changes to make triggering the horde more reliable.

1.11 (25-Oct-2023)
	- Added cvar "l4d2_airstrike_manual" to set how many Airstrikes should hit when using the command or menu to trigger. Requested by "ForTheSakura".
	- Added cvar "l4d2_airstrike_ring" to display a beam ring at the target position. Requested by "ForTheSakura".
	- Changed command "sm_strikes" to allow specifying how many Airstrikes should hit when using the command (overrides the cvar value). Requested by "ForTheSakura".
	- Fixed missing translations. Thanks to "ForTheSakura" for reporting.

1.10 (15-Dec-2022)
	- Removed one of the explosion effects that were temperamental. Thanks to "choppledpickusfungus" for reporting.

1.9 (11-Dec-2022)
	- Changes to fix compile warnings on SourceMod 1.11.

1.8 (24-Jul-2021)
	- Added a 0.1 second delay between Airstrikes if multiple are detected within the same frame.
	- Fixed cvar "l4d2_airstrike_scale" value "0" not preventing damage to survivors. Thanks to "King_OXO" for reporting.

1.7 (18-Sep-2020)
	- Added command "sm_strikes" to create Airstrikes by command. Thanks to "maclarens" for requesting.
	- Create them on a specific client position, where the client is aiming or at a specific vector and angle.

1.6 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Fixed forwards "F18_OnAirstrike" and "F18_OnMissileHit" from pushing individual floats instead of a vector array.
	- Various changes to tidy up code.
	- Various optimizations and fixes.

1.5 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.
	- Fixed not precaching "env_shake" which caused stutter on first explosion.

1.4.5 (02-Aug-2019)
	- Fixed invalid native param index error.

1.4.4 (04-Jul-2019)
	- Added cvar "l4d2_airstrike_limit" to set the number of simultaneous Airstrikes.

1.4.3 (03-Jul-2019)
	- Changed natives to use vectors. All Airstrike plugins must be updated and 3rd party will need updating and recompiling.

1.4.2 (28-Jun-2019)
	- Changed PrecacheParticle method.

1.4.1 (03-Jun-2019)
	- Added missing precache for explosion sounds.

1.4 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.3 (27-Jan-2018)
	- Added cvar "l4d2_airstrike_scale" to scale the damage done to survivors.
	- This cvar is now part of the core plugin. The "l4d2_airstrike.damage_scale" add-on plugin should be deleted if you had installed.

1.2.1 (23-Jan-2018)
	- Update by "Lux":
	- Removed gamedata signature/SDKCall dependency for stagger.
	- Now uses native VScript API for stagger function thanks to "Timocop"'s function and "Lux" reporting.

1.2 (31-Jul-2013)
	- Added new forwards "F18_OnAirstrike" and "F18_OnMissileHit" for developers to make custom plugins when the missile fires/hits.
	- Added new plugin "l4d2_airstrike.dead_air" to destroy the barricade on c11m3 (Garages) when the missile hits near by.
	- Added new plugin "l4d2_airstrike.no_mercy" to destroy the gas station on c8m3 (Sewers) when the missile hits near by.
	- Fixed the jet/missile spawning on most maps with high or low skyboxes, should work fine now.
	- Thanks to "worminater" for helping and lots of testing.

1.1 (20-Jun-2012)
	- Added a hard limit of 8 Airstrikes at one time, in an attempt to prevent some players from crashing.
	- Added cvar "l4d2_airstrike_shake" to set the range at which the explosion can shake players screens.
	- Added cvar "l4d2_airstrike_vocalize" to set the chance to vocalize the player nearest the explosion.
	- Changed some default cvar values.
	- Small fixes.

1.0 (15-Jun-2012)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "Downtown1", "ProdigySim" and "psychonic" for "[EXTENSION] Left 4 Downtown 2 L4D2 Only" - Used gamedata to stumble players.
	https://forums.alliedmods.net/showthread.php?t=134032

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
// #include <l4d2_airstrike>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x03[Airstrike] \x05"
#define MAX_ENTITIES		8

#define MODEL_AGM65			"models/missiles/f18_agm65maverick.mdl"
#define MODEL_F18			"models/f18/f18_sb.mdl"
#define MODEL_BOX			"models/props/cs_militia/silo_01.mdl"

#define SPRITE_BEAM			"materials/sprites/laserbeam.vmt"
#define SPRITE_HALO			"materials/sprites/glow01.vmt"

// #define SOUND_OVER1			"ambient/overhead/plane1.wav"
// #define SOUND_OVER2			"ambient/overhead/plane2.wav"
// #define SOUND_OVER3			"ambient/overhead/plane3.wav"
#define SOUND_PASS1			"animation/jets/jet_by_01_mono.wav"
#define SOUND_PASS2			"animation/jets/jet_by_02_mono.wav"
#define SOUND_PASS3			"animation/jets/jet_by_01_lr.wav"
#define SOUND_PASS4			"animation/jets/jet_by_02_lr.wav"
#define SOUND_PASS5			"animation/jets/jet_by_03_lr.wav"
#define SOUND_PASS6			"animation/jets/jet_by_04_lr.wav"
#define SOUND_PASS7			"animation/jets/jet_by_05_lr.wav"
#define SOUND_PASS8			"animation/jets/jet_by_05_rl.wav"
#define SOUND_EXPLODE3		"weapons/hegrenade/explode3.wav"
#define SOUND_EXPLODE4		"weapons/hegrenade/explode4.wav"
#define SOUND_EXPLODE5		"weapons/hegrenade/explode5.wav"

// #define PARTICLE_BOMB1		"FluidExplosion_fps" // Broken? Only shows sometimes
#define PARTICLE_BOMB2		"missile_hit1"
#define PARTICLE_BOMB3		"gas_explosion_main"
#define PARTICLE_BOMB4		"explosion_huge"
#define PARTICLE_BLUE		"flame_blue"
#define PARTICLE_FIRE		"fire_medium_01"
#define PARTICLE_SPARKS		"fireworks_sparkshower_01e"
#define PARTICLE_SMOKE		"rpg_smoke"


ConVar g_hCvarAllow, g_hCvarDamage, g_hCvarDistance, g_hCvarHorde, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarLimit, g_hCvarManual, g_hCvarRing, g_hCvarScale, g_hCvarShake, g_hCvarSpread, g_hCvarStumble, g_hCvarStyle, g_hCvarTime, g_hCvarVocalize;
int g_iCvarDamage, g_iCvarDistance, g_iCvarHorde, g_iCvarLimit, g_iCvarManual, g_iCvarRing, g_iCvarScale, g_iCvarShake, g_iCvarSpread, g_iCvarStumble, g_iCvarStyle, g_iCvarVocalize;
bool g_bCvarAllow, g_bMapStarted;

Handle g_hForwardOnAirstrike, g_hForwardOnMissileHit, g_hForwardPluginState, g_hForwardRoundState;
int g_iBeamSprite, g_iHaloSprite, g_iPlayerSpawn, g_iRoundStart, g_iEntities[MAX_ENTITIES];
bool g_bDmgHooked, g_bLateLoad, g_bPluginTrigger;
float g_fCvarTime, g_fLastAirstrike; // Delay airstrike

enum
{
	RING_OFF,
	RING_AIM,
	RING_POS,
	RING_ALL
}



// ====================================================================================================
//					NATIVES
// ====================================================================================================
int Native_ShowAirstrike(Handle plugin, int numParams)
{
	if( g_bCvarAllow )
	{
		float vPos[3];
		GetNativeArray(1, vPos, sizeof(vPos));

		if( g_iCvarRing & RING_ALL ) CreateBeamRing(vPos);
		ShowAirstrike(vPos, GetNativeCell(2));
	}

	return 0;
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] F-18 Airstrike",
	author = "SilverShot",
	description = "Creates F-18 flybys which shoot missiles to where they were triggered from.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=187567"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;
	RegPluginLibrary("l4d2_airstrike");
	CreateNative("F18_ShowAirstrike", Native_ShowAirstrike);

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hForwardOnAirstrike = CreateGlobalForward("F18_OnAirstrike", ET_Ignore, Param_Array);
	g_hForwardOnMissileHit = CreateGlobalForward("F18_OnMissileHit", ET_Ignore, Param_Array);
	g_hForwardPluginState = CreateGlobalForward("F18_OnPluginState", ET_Ignore, Param_Cell);
	g_hForwardRoundState = CreateGlobalForward("F18_OnRoundState", ET_Ignore, Param_Cell);

	g_hCvarAllow =			CreateConVar(	"l4d2_airstrike_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarDamage =			CreateConVar(	"l4d2_airstrike_damage",		"200",			"Hurt players by this much at the center of the explosion. Damages falls off based on the maximum distance.", CVAR_FLAGS );
	g_hCvarDistance =		CreateConVar(	"l4d2_airstrike_distance",		"500",			"The range at which the airstrike explosion can hurt players.", CVAR_FLAGS );
	g_hCvarHorde =			CreateConVar(	"l4d2_airstrike_horde",			"5",			"0=Off. The chance out of 100 to make a panic event when the bomb explodes.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d2_airstrike_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d2_airstrike_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d2_airstrike_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarLimit =			CreateConVar(	"l4d2_airstrike_limit",			"8",			"Maximum number of simultaneous airstrikes.", CVAR_FLAGS, true, 0.0, true, float(MAX_ENTITIES) );
	g_hCvarManual =			CreateConVar(	"l4d2_airstrike_manual",		"1",			"How many airstrikes appear when manually triggering by menu or command.", CVAR_FLAGS, true, 0.0, true, float(MAX_ENTITIES) );
	g_hCvarRing =			CreateConVar(	"l4d2_airstrike_ring",			"3",			"Display a red ring where the target will hit: 0=Off. 1=Airstrike on Crosshair (cmd/menu). 2=Airstrike on Position (cmd/menu). 4=Airstrikes not from cmd/menu. Add numbers together.", CVAR_FLAGS );
	g_hCvarScale =			CreateConVar(	"l4d2_airstrike_scale",			"50",			"0=Off. Percentage of damage to survivors. Can be 50% or 200% etc.", CVAR_FLAGS );
	g_hCvarShake =			CreateConVar(	"l4d2_airstrike_shake",			"1000",			"The range at which the explosion can shake players screens.", CVAR_FLAGS );
	g_hCvarSpread =			CreateConVar(	"l4d2_airstrike_spread",		"100",			"The maximum distance to vary the missile target zone.", CVAR_FLAGS );
	g_hCvarStumble =		CreateConVar(	"l4d2_airstrike_stumble",		"400",			"0=Off, Range at which players are stumbled from the explosion.", CVAR_FLAGS );
	g_hCvarStyle =			CreateConVar(	"l4d2_airstrike_style",			"15",			"1=Blue Fire, 2=Flames, 4=Sparks, 8=RPG Smoke, 15=All.", CVAR_FLAGS );
	g_hCvarTime =			CreateConVar(	"l4d2_airstrike_time",			"0.2",			"The time delay interval between multiple airstrikes.", CVAR_FLAGS );
	g_hCvarVocalize =		CreateConVar(	"l4d2_airstrike_vocalize",		"20",			"0=Off. The chance out of 100 to vocalize the player nearest the explosion.", CVAR_FLAGS );
	CreateConVar(							"l4d2_airstrike_version",		PLUGIN_VERSION,	"F-18 Airstrike plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d2_airstrike");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarDamage.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDistance.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHorde.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarLimit.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarManual.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRing.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarScale.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarShake.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpread.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarStumble.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarStyle.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTime.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarVocalize.AddChangeHook(ConVarChanged_Cvars);

	RegAdminCmd("sm_strike",	CmdAirstrikeMenu, ADMFLAG_ROOT, "Displays a menu with options to show/save an airstrike and triggers.");
	RegAdminCmd("sm_strikes",	CmdAirstrikeMake, ADMFLAG_ROOT, "Create an Airstrike. Usage: sm_strikes <#userid|name> <type: 1=Aim position. 2=On position> [optional number of airstrikes] -OR- vector position <X> <Y> <Z> <angle> [optional number of airstrikes]");

	LoadTranslations("common.phrases");
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnLibraryAdded(const char[] name)
{
	if( strcmp(name, "l4d2_airstrike.triggers") == 0 )
		g_bPluginTrigger = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if( strcmp(name, "l4d2_airstrike.triggers") == 0 )
		g_bPluginTrigger = false;
}

public void OnMapStart()
{
	g_bMapStarted = true;
	// PrecacheParticle(PARTICLE_BOMB1);
	PrecacheParticle(PARTICLE_BOMB2);
	PrecacheParticle(PARTICLE_BOMB3);
	PrecacheParticle(PARTICLE_BOMB4);
	PrecacheParticle(PARTICLE_BLUE);
	PrecacheParticle(PARTICLE_FIRE);
	PrecacheParticle(PARTICLE_SMOKE);
	PrecacheParticle(PARTICLE_SPARKS);
	g_iBeamSprite = PrecacheModel(SPRITE_BEAM, true);
	g_iHaloSprite = PrecacheModel(SPRITE_HALO, true);
	PrecacheModel(MODEL_AGM65, true);
	PrecacheModel(MODEL_F18, true);
	PrecacheModel(MODEL_BOX, true);
	PrecacheSound(SOUND_PASS1, true);
	PrecacheSound(SOUND_PASS2, true);
	PrecacheSound(SOUND_PASS3, true);
	PrecacheSound(SOUND_PASS4, true);
	PrecacheSound(SOUND_PASS5, true);
	PrecacheSound(SOUND_PASS6, true);
	PrecacheSound(SOUND_PASS7, true);
	PrecacheSound(SOUND_PASS8, true);
	PrecacheSound(SOUND_EXPLODE3, true);
	PrecacheSound(SOUND_EXPLODE4, true);
	PrecacheSound(SOUND_EXPLODE5, true);



	// Pre-cache env_shake -_- WTF
	int shake  = CreateEntityByName("env_shake");
	if( shake != -1 )
	{
		DispatchKeyValue(shake, "spawnflags", "8");
		DispatchKeyValue(shake, "amplitude", "16.0");
		DispatchKeyValue(shake, "frequency", "1.5");
		DispatchKeyValue(shake, "duration", "0.9");
		DispatchKeyValue(shake, "radius", "50");
		TeleportEntity(shake, view_as<float>({ 0.0, 0.0, -1000.0 }), NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(shake);
		ActivateEntity(shake);
		AcceptEntityInput(shake, "Enable");
		AcceptEntityInput(shake, "StartShake");
		RemoveEdict(shake);
	}
}

public void OnMapEnd()
{
	g_bMapStarted = false;

	ResetPlugin();
	OnRoundState(0);
}

void ResetPlugin()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarDamage = g_hCvarDamage.IntValue;
	g_iCvarDistance = g_hCvarDistance.IntValue;
	g_iCvarHorde = g_hCvarHorde.IntValue;
	g_iCvarLimit = g_hCvarLimit.IntValue;
	g_iCvarManual = g_hCvarManual.IntValue;
	g_iCvarRing = g_hCvarRing.IntValue;
	g_iCvarScale = g_hCvarScale.IntValue;
	g_iCvarShake = g_hCvarShake.IntValue;
	g_iCvarSpread = g_hCvarSpread.IntValue;
	g_iCvarStumble = g_hCvarStumble.IntValue;
	g_iCvarStyle = g_hCvarStyle.IntValue;
	g_fCvarTime = g_hCvarTime.FloatValue;
	g_iCvarVocalize = g_hCvarVocalize.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);

		DmgHookUnhook(true);

		Call_StartForward(g_hForwardPluginState);
		Call_PushCell(1);
		Call_Finish();

		if( g_bLateLoad == true )
		{
			g_bLateLoad = false;
			OnRoundState(1);
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		ResetPlugin();
		g_bCvarAllow = false;
		UnhookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);

		DmgHookUnhook(false);

		Call_StartForward(g_hForwardPluginState);
		Call_PushCell(0);
		Call_Finish();
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
	OnRoundState(0);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

Action TimerStart(Handle timer)
{
	ResetPlugin();
	OnRoundState(1);
	return Plugin_Continue;
}

void OnRoundState(int roundstate)
{
	static int mystate;

	if( roundstate == 1 && mystate == 0 )
	{
		mystate = 1;
		Call_StartForward(g_hForwardRoundState);
		Call_PushCell(1);
		Call_Finish();
	}
	else if( roundstate == 0 && mystate == 1 )
	{
		mystate = 0;
		Call_StartForward(g_hForwardRoundState);
		Call_PushCell(0);
		Call_Finish();
	}
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
Action CmdAirstrikeMake(int client, int args)
{
	// Specific client and type
	if( args == 2 || args == 3 )
	{
		char arg1[32];

		GetCmdArg(2, arg1, sizeof(arg1));

		int type = StringToInt(arg1);
		if( type != 1 && type != 2 )
		{
			ReplyToCommand(client, "Usage: sm_strikes <#userid|name> <type: 1=Aim position. 2=On position> [optional number of airstrikes] -OR- vector position <X> <Y> <Z> <angle> [optional number of airstrikes]");
			return Plugin_Handled;
		}

		GetCmdArg(1, arg1, sizeof(arg1));

		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;

		if( (target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		float vPos[3], vAng[3], direction;
		int target;
		int count;

		if( args == 3 )
		{
			GetCmdArg(3, arg1, sizeof(arg1));
			count = StringToInt(arg1);
			if( count > g_iCvarLimit ) count = g_iCvarLimit;
		}
		else
		{
			count = g_iCvarManual;
		}

		for( int i = 0; i < target_count; i++ )
		{
			target = target_list[i];

			if( type == 1 )
			{
				GetClientEyePosition(target, vPos);
				GetClientEyeAngles(target, vAng);
				direction = vAng[1];

				Handle hTrace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter);

				if( TR_DidHit(hTrace) )
				{
					float vStart[3];
					TR_GetEndPosition(vStart, hTrace);
					GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
					vPos[0] = vStart[0] + vAng[0];
					vPos[1] = vStart[1] + vAng[1];
					vPos[2] = vStart[2] + vAng[2];

					// Multiple strikes
					if( count > 1 )
					{
						for( int x = 1; x < count; x++ )
						{
							DataPack dPack = new DataPack();
							dPack.WriteCell(vPos[0]);
							dPack.WriteCell(vPos[1]);
							dPack.WriteCell(vPos[2]);
							dPack.WriteCell(direction);
							CreateTimer(x * g_fCvarTime, TimerDelayStrike, dPack);
						}
					}

					if( g_iCvarRing & RING_AIM ) CreateBeamRing(vPos);
					ShowAirstrike(vPos, direction);
				}

				delete hTrace;
			}
			else
			{
				GetClientAbsOrigin(target, vPos);
				GetClientEyeAngles(target, vAng);

				// Multiple strikes
				if( count > 1 )
				{
					for( int x = 1; x < count; x++ )
					{
						DataPack dPack = new DataPack();
						dPack.WriteCell(vPos[0]);
						dPack.WriteCell(vPos[1]);
						dPack.WriteCell(vPos[2]);
						dPack.WriteCell(vAng[1]);
						CreateTimer(x * g_fCvarTime, TimerDelayStrike, dPack);
					}
				}

				if( g_iCvarRing & RING_POS ) CreateBeamRing(vPos);
				ShowAirstrike(vPos, vAng[1]);
			}
		}
	}

	// Specific position
	else if( args == 4 || args == 5 )
	{
		char arg1[32];
		float vPos[3];

		GetCmdArg(1, arg1, sizeof(arg1));
		vPos[0] = StringToFloat(arg1);
		GetCmdArg(2, arg1, sizeof(arg1));
		vPos[1] = StringToFloat(arg1);
		GetCmdArg(3, arg1, sizeof(arg1));
		vPos[2] = StringToFloat(arg1);

		GetCmdArg(4, arg1, sizeof(arg1));
		float direction = StringToFloat(arg1);

		// Multiple strikes
		int count = g_iCvarManual;
		if( args == 5 )
		{
			GetCmdArg(5, arg1, sizeof(arg1));
			count = StringToInt(arg1);
			if( count > g_iCvarLimit ) count = g_iCvarLimit;
		}

		if( count > 1 )
		{
			for( int x = 1; x < count; x++ )
			{
				DataPack dPack = new DataPack();
				dPack.WriteCell(vPos[0]);
				dPack.WriteCell(vPos[1]);
				dPack.WriteCell(vPos[2]);
				dPack.WriteCell(direction);
				CreateTimer(x * g_fCvarTime, TimerDelayStrike, dPack);
			}
		}

		if( g_iCvarRing & RING_POS ) CreateBeamRing(vPos);
		ShowAirstrike(vPos, direction);
	}

	else
	{
		ReplyToCommand(client, "Usage: sm_strikes <#userid|name> <type: 1=Aim position. 2=On position> [optional number of airstrikes] -OR- vector position <X> <Y> <Z> <angle> [optional number of airstrikes]");
	}

	return Plugin_Handled;
}

Action CmdAirstrikeMenu(int client, int args)
{
	if( g_bCvarAllow )
		ShowMenuMain(client);
	return Plugin_Handled;
}

void ShowMenuMain(int client)
{
	Menu hMenu = new Menu(MainMenuHandler);
	hMenu.AddItem("1", "Airstrike on Crosshair");
	hMenu.AddItem("2", "Airstrike on Position");
	if( g_bPluginTrigger == true )
		hMenu.AddItem("3", "Airstrike Triggers");
	hMenu.SetTitle("F-18 Airstrike");
	hMenu.Display(client, MENU_TIME_FOREVER);
}

int MainMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
	{
		delete menu;
	}
	else if( action == MenuAction_Select )
	{
		if( index == 0 )
		{
			float vPos[3], vAng[3], direction;
			GetClientEyePosition(client, vPos);
			GetClientEyeAngles(client, vAng);
			direction = vAng[1];

			Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter);

			if( TR_DidHit(trace) )
			{
				float vStart[3];
				TR_GetEndPosition(vStart, trace);
				GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
				vPos[0] = vStart[0] + vAng[0];
				vPos[1] = vStart[1] + vAng[1];
				vPos[2] = vStart[2] + vAng[2];

				// Multiple strikes
				if( g_iCvarManual > 1 )
				{
					for( int x = 1; x < g_iCvarManual; x++ )
					{
						DataPack dPack = new DataPack();
						dPack.WriteCell(vPos[0]);
						dPack.WriteCell(vPos[1]);
						dPack.WriteCell(vPos[2]);
						dPack.WriteCell(direction);
						CreateTimer(x * g_fCvarTime, TimerDelayStrike, dPack);
					}
				}

				if( g_iCvarRing & RING_AIM ) CreateBeamRing(vStart);
				ShowAirstrike(vPos, direction);
			}

			delete trace;

			ShowMenuMain(client);
		}
		else if( index == 1 )
		{
			float vPos[3], vAng[3];
			GetClientAbsOrigin(client, vPos);
			GetClientEyeAngles(client, vAng);

			// Multiple strikes
			if( g_iCvarManual > 1 )
			{
				for( int x = 1; x < g_iCvarManual; x++ )
				{
					DataPack dPack = new DataPack();
					dPack.WriteCell(vPos[0]);
					dPack.WriteCell(vPos[1]);
					dPack.WriteCell(vPos[2]);
					dPack.WriteCell(vAng[1]);
					CreateTimer(x * g_fCvarTime, TimerDelayStrike, dPack);
				}
			}

			if( g_iCvarRing & RING_POS ) CreateBeamRing(vPos);
			ShowAirstrike(vPos, vAng[1]);

			ShowMenuMain(client);
		}
		else if( index == 2 )
		{
			FakeClientCommand(client, "sm_strike_triggers");
		}
	}

	return 0;
}

bool TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients;
}

void CreateBeamRing(float vPos[3])
{
    int colors[4];
    colors[0] = 255;
    colors[1] = 0;
    colors[2] = 0;
    colors[3] = 45;

    vPos[2] += 10.0;
    TE_SetupBeamRingPoint(vPos, 100.0, float(g_iCvarDistance), g_iBeamSprite, g_iHaloSprite, 0, 0, 1.85, 2.5, 0.0, colors, 0, 0);
    TE_SendToAll();
    
    colors[3] = 245;
    
    TE_SetupBeamRingPoint(vPos, 20.0, g_iCvarDistance / 10.0, g_iBeamSprite, g_iHaloSprite, 0, 0, 1.85, 1.5, 0.0, colors, 0, 0);
    TE_SendToAll();
    
    colors[3] = 220;

    TE_SetupBeamRingPoint(vPos, 30.0, g_iCvarDistance / 8.0, g_iBeamSprite, g_iHaloSprite, 0, 0, 1.85, 1.625, 0.0, colors, 0, 0);
    TE_SendToAll();
    
    colors[3] = 195;
    
    TE_SetupBeamRingPoint(vPos, 40.0, g_iCvarDistance / 6.25, g_iBeamSprite, g_iHaloSprite, 0, 0, 1.85, 1.75, 0.0, colors, 0, 0);
    TE_SendToAll();
    
    colors[3] = 170;
    
    TE_SetupBeamRingPoint(vPos, 50.0, g_iCvarDistance / 4.75, g_iBeamSprite, g_iHaloSprite, 0, 0, 1.85, 1.875, 0.0, colors, 0, 0);
    TE_SendToAll();
    
    colors[3] = 145;
    
    TE_SetupBeamRingPoint(vPos, 60.0, g_iCvarDistance / 3.5, g_iBeamSprite, g_iHaloSprite, 0, 0, 1.85, 2.0, 0.0, colors, 0, 0);
    TE_SendToAll();
    
    colors[3] = 120;

    TE_SetupBeamRingPoint(vPos, 70.0, g_iCvarDistance / 2.5, g_iBeamSprite, g_iHaloSprite, 0, 0, 1.85, 2.125, 0.0, colors, 0, 0);
    TE_SendToAll();
    
    colors[3] = 95;
    
    TE_SetupBeamRingPoint(vPos, 80.0, g_iCvarDistance / 1.75, g_iBeamSprite, g_iHaloSprite, 0, 0, 1.85, 2.25, 0.0, colors, 0, 0);
    TE_SendToAll();
    
    colors[3] = 70;
    
    TE_SetupBeamRingPoint(vPos, 90.0, g_iCvarDistance / 1.25, g_iBeamSprite, g_iHaloSprite, 0, 0, 1.85, 2.375, 0.0, colors, 0, 0);
    TE_SendToAll();
}



// ====================================================================================================
//					SHOW AIRSTRIKE
// ====================================================================================================
Action TimerDelayStrike(Handle timer, DataPack dPack)
{
	float vPos[3];
	float direction;
	dPack.Reset();
	vPos[0] = dPack.ReadCell();
	vPos[1] = dPack.ReadCell();
	vPos[2] = dPack.ReadCell();
	direction = dPack.ReadCell();

	ShowAirstrike(vPos, direction);

	delete dPack;

	return Plugin_Continue;
}

void ShowAirstrike(float vPos[3], float direction)
{
	// Delay if same frame
	if( GetGameTime() == g_fLastAirstrike )
	{
		DataPack dPack = new DataPack();
		dPack.WriteCell(vPos[0]);
		dPack.WriteCell(vPos[1]);
		dPack.WriteCell(vPos[2]);
		dPack.WriteCell(direction);
		CreateTimer(0.1, TimerDelayStrike, dPack);
		return;
	}

	g_fLastAirstrike = GetGameTime();

	// Find index
	int index = -1;
	for( int i = 0; i < g_iCvarLimit; i++ )
	{
		if( IsValidEntRef(g_iEntities[i]) == false )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
		return;

	// Sort position and create
	float vAng[3], vSkybox[3];
	vAng[0] = 0.0;
	vAng[1] = direction;
	vAng[2] = 0.0;

	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vSkybox);

	int entity = CreateEntityByName("prop_dynamic_override");
	g_iEntities[index] = EntIndexToEntRef(entity);
	DispatchKeyValue(entity, "targetname", "silver_f18_model");
	DispatchKeyValue(entity, "disableshadows", "1");
	DispatchKeyValue(entity, "model", MODEL_F18);
	DispatchSpawn(entity);
	SetEntProp(entity, Prop_Data, "m_iHammerID", RoundToNearest(vPos[2]));
	float height = vPos[2] + 1150.0;
	if( height > vSkybox[2] - 200 )
		vPos[2] = vSkybox[2] - 200;
	else
		vPos[2] = height;
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 5.0);

	int random = GetRandomInt(1, 5);
	switch( random )
	{
		case 1:		SetVariantString("flyby1");
		case 2:		SetVariantString("flyby2");
		case 3:		SetVariantString("flyby3");
		case 4:		SetVariantString("flyby4");
		case 5:		SetVariantString("flyby5");
	}

	AcceptEntityInput(entity, "SetAnimation");
	AcceptEntityInput(entity, "Enable");

	SetVariantString("OnUser1 !self:Kill::6.5:1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");

	CreateTimer(0.5, TimerDrop, EntIndexToEntRef(entity));

	Call_StartForward(g_hForwardOnAirstrike);
	Call_PushArray(vPos, 3);
	Call_Finish();
}

Action TimerGrav(Handle timer, int entity)
{
	if( IsValidEntRef(entity) )
		CreateTimer(0.1, TimerGravity, entity, TIMER_REPEAT);

	return Plugin_Continue;
}

Action TimerGravity(Handle timer, int entity)
{
	if( IsValidEntRef(entity) )
	{
		int tick = GetEntProp(entity, Prop_Data, "m_iHammerID");
		if( tick > 15 )
		{
			SDKHook(EntRefToEntIndex(entity), SDKHook_Touch, OnBombTouch);
			SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
			return Plugin_Stop;
		}
		else
		{
			SetEntProp(entity, Prop_Data, "m_iHammerID", tick + 1);

			float vAng[3];
			GetEntPropVector(entity, Prop_Data, "m_vecVelocity", vAng);
			vAng[2] -= 50.0;
			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vAng);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

Action TimerDrop(Handle timer, int f18)
{
	if( IsValidEntRef(f18) )
	{
		float vPos[3], vAng[3], vVec[3];
		GetEntPropVector(f18, Prop_Data, "m_vecAbsOrigin", vPos);
		GetEntPropVector(f18, Prop_Data, "m_angRotation", vAng);

		int entity = CreateEntityByName("grenade_launcher_projectile");
		DispatchSpawn(entity);
		SetEntityModel(entity, MODEL_AGM65);

		SetEntityMoveType(entity, MOVETYPE_NOCLIP);
		CreateTimer(1.2, TimerGrav, EntIndexToEntRef(entity));

		GetAngleVectors(vAng, vVec, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vVec, vVec);
		ScaleVector(vVec, -700.0);

		int height = GetEntProp(f18, Prop_Data, "m_iHammerID");
		int target = RoundToNearest(vPos[2]);
		float diff = target - height + 1600.0;
		diff -= (diff / 10);
		MoveForward(vPos, vAng, vPos, diff);

		vPos[0] += GetRandomFloat(-1.0 * g_iCvarSpread, float(g_iCvarSpread));
		vPos[1] += GetRandomFloat(-1.0 * g_iCvarSpread, float(g_iCvarSpread));
		TeleportEntity(entity, vPos, vAng, vVec);

		SetVariantString("OnUser1 !self:Kill::10.0:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");

		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.3);

		int projectile = entity;


		// BLUE FLAMES
		if( g_iCvarStyle & (1<<0) )
		{
			entity = CreateEntityByName("info_particle_system");
			if( entity != -1 )
			{
				DispatchKeyValue(entity, "effect_name", PARTICLE_BLUE);
				DispatchSpawn(entity);
				ActivateEntity(entity);
				TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

				SetVariantString("!activator");
				AcceptEntityInput(entity, "SetParent", projectile);

				SetVariantString("OnUser4 !self:Kill::10.0:1");
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser4");
				AcceptEntityInput(entity, "Start");
			}
		}


		// FLAMES
		if( g_iCvarStyle & (1<<1) )
		{
			entity = CreateEntityByName("info_particle_system");
			if( entity != -1 )
			{
				DispatchKeyValue(entity, "effect_name", PARTICLE_FIRE);
				DispatchSpawn(entity);
				ActivateEntity(entity);
				TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

				SetVariantString("!activator");
				AcceptEntityInput(entity, "SetParent", projectile);

				SetVariantString("OnUser4 !self:Kill::10.0:1");
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser4");
				AcceptEntityInput(entity, "Start");
			}
		}


		// SPARKS
		if( g_iCvarStyle & (1<<2) )
		{
			entity = CreateEntityByName("info_particle_system");
			if( entity != -1 )
			{
				DispatchKeyValue(entity, "effect_name", PARTICLE_SPARKS);
				DispatchSpawn(entity);
				ActivateEntity(entity);
				TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

				SetVariantString("!activator");
				AcceptEntityInput(entity, "SetParent", projectile);

				SetVariantString("OnUser4 !self:Kill::10.0:1");
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser4");
				AcceptEntityInput(entity, "Start");
			}
		}


		// RPG SMOKE
		if( g_iCvarStyle & (1<<3) )
		{
			entity = CreateEntityByName("info_particle_system");
			if( entity != -1 )
			{
				DispatchKeyValue(entity, "effect_name", PARTICLE_SMOKE);
				DispatchSpawn(entity);
				ActivateEntity(entity);
				AcceptEntityInput(entity, "start");
				TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

				SetVariantString("!activator");
				AcceptEntityInput(entity, "SetParent", projectile);

				SetVariantString("OnUser3 !self:Kill::10.0:1");
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser3");

				// Refire
				SetVariantString("OnUser1 !self:Stop::0.65:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser1 !self:FireUser2::0.7:-1");
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser1");

				SetVariantString("OnUser2 !self:Start::0:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser2 !self:FireUser1::0:-1");
				AcceptEntityInput(entity, "AddOutput");
			}
		}


		// SOUND
		int random = GetRandomInt(1, 8);
		switch( random )
		{
			case 1:		EmitSoundToAll(SOUND_PASS1, entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
			case 2:		EmitSoundToAll(SOUND_PASS2, entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
			case 3:		EmitSoundToAll(SOUND_PASS3, entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
			case 4:		EmitSoundToAll(SOUND_PASS4, entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
			case 5:		EmitSoundToAll(SOUND_PASS5, entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
			case 6:		EmitSoundToAll(SOUND_PASS6, entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
			case 7:		EmitSoundToAll(SOUND_PASS7, entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
			case 8:		EmitSoundToAll(SOUND_PASS8, entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
		}
	}

	return Plugin_Continue;
}

void MoveForward(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
	vReturn[2] += vDir[2] * fDistance;
}

public void OnClientPutInServer(int client)
{
	if( g_bCvarAllow )
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

void DmgHookUnhook(bool allowed)
{
	if( !allowed && g_bDmgHooked )
	{
		g_bDmgHooked = false;
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}

	if( allowed && !g_bDmgHooked )
	{
		g_bDmgHooked = true;
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( damagetype & DMG_BLAST && victim > 0 && victim <= MaxClients && GetEntProp(inflictor, Prop_Data, "m_iHammerID") == 1078682 && GetClientTeam(victim) == 2 )
	{
		damage = damage * float(g_iCvarScale) / 100.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

void OnBombTouch(int entity, int activator)
{
	char sTemp[10];
	GetEdictClassname(activator, sTemp, sizeof(sTemp));

	if(	strncmp(sTemp, "trigger_", 8) )
	{
		SDKUnhook(entity, SDKHook_Touch, OnBombTouch);

		CreateTimer(0.1, TimerBombTouch, EntIndexToEntRef(entity));
	}
}

Action TimerBombTouch(Handle timer, int entity)
{
	if( EntRefToEntIndex(entity) == INVALID_ENT_REFERENCE )
		return Plugin_Continue;

	if( g_iCvarHorde && GetRandomInt(1, 100) <= g_iCvarHorde )
	{
		L4D_ForcePanicEvent();
	}

	float vPos[3];
	char sTemp[8];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
	RemoveEntity(entity);
	IntToString(g_iCvarDamage, sTemp, sizeof(sTemp));


	Call_StartForward(g_hForwardOnMissileHit);
	Call_PushArray(vPos, 3);
	Call_Finish();


	// Create explosion, kills infected, hurts special infected/survivors, pushes physics entities.
	entity = CreateEntityByName("env_explosion");
	DispatchKeyValue(entity, "spawnflags", "1916");
	IntToString(g_iCvarDamage, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "iMagnitude", sTemp);
	IntToString(g_iCvarDistance, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "iRadiusOverride", sTemp);
	DispatchSpawn(entity);
	SetEntProp(entity, Prop_Data, "m_iHammerID", 1078682);
	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "Explode");


	// Shake!
	int shake  = CreateEntityByName("env_shake");
	if( shake != -1 )
	{
		DispatchKeyValue(shake, "spawnflags", "8");
		DispatchKeyValue(shake, "amplitude", "16.0");
		DispatchKeyValue(shake, "frequency", "1.5");
		DispatchKeyValue(shake, "duration", "0.9");
		IntToString(g_iCvarShake, sTemp, sizeof(sTemp));
		DispatchKeyValue(shake, "radius", sTemp);
		DispatchSpawn(shake);
		ActivateEntity(shake);
		AcceptEntityInput(shake, "Enable");

		TeleportEntity(shake, vPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(shake, "StartShake");
		RemoveEdict(shake);
	}


	// Loop through survivors, work out distance and stumble/vocalize.
	if( g_iCvarStumble || g_iCvarVocalize )
	{
		int client; float fDistance; float fNearest = 1500.0;
		float vPos2[3];

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
			{
				GetClientAbsOrigin(i, vPos2);
				fDistance = GetVectorDistance(vPos, vPos2);

				if( g_iCvarVocalize && fDistance <= fNearest )
				{
					client = i;
					fNearest = fDistance;
				}

				if( g_iCvarStumble && fDistance <= g_iCvarStumble )
				{
					StaggerClient(GetClientUserId(i), vPos);
				}
			}
		}

		if( client )
		{
			Vocalize(client);
		}
	}


	// Explosion effect
	entity = CreateEntityByName("info_particle_system");
	if( entity != -1 )
	{
		int random = GetRandomInt(2, 4);

		switch( random )
		{
			// case 1:		DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB1);
			case 2:		DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB2);
			case 3:		DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB3);
			case 4:		DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB4);
		}

		// if( random == 1 )
			// vPos[2] += 175.0;
		if( random == 2 )
			vPos[2] += 100.0;
		else if( random == 4 )
			vPos[2] += 25.0;

		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");

		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}


	// Sound
	int random = GetRandomInt(0, 2);
	if( random == 0 )
		EmitSoundToAll(SOUND_EXPLODE3, entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
	else if( random == 1 )
		EmitSoundToAll(SOUND_EXPLODE4, entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
	else if( random == 2 )
		EmitSoundToAll(SOUND_EXPLODE5, entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);

	return Plugin_Continue;
}

static const char g_sVocalize[][] =
{
	"scenes/Coach/WorldC5M4B04.vcd",		//Damn! That one was close!
	"scenes/Coach/WorldC5M4B05.vcd",		//Shit. Damn, that one was close!
	"scenes/Coach/WorldC5M4B02.vcd",		//STOP BOMBING US.
	"scenes/Gambler/WorldC5M4B09.vcd",		//Well, it's official: They're trying to kill US now.
	"scenes/Gambler/WorldC5M4B05.vcd",		//Christ, those guys are such assholes.
	"scenes/Gambler/World220.vcd",			//WHAT THE HELL ARE THEY DOING?  (reaction to bombing)
	"scenes/Gambler/WorldC5M4B03.vcd",		//STOP BOMBING US!
	"scenes/Mechanic/WorldC5M4B02.vcd",		//They nailed that.
	"scenes/Mechanic/WorldC5M4B03.vcd",		//What are they even aiming at?
	"scenes/Mechanic/WorldC5M4B04.vcd",		//We need to get the hell out of here.
	"scenes/Mechanic/WorldC5M4B05.vcd",		//They must not see us.
	"scenes/Mechanic/WorldC5M103.vcd",		//HEY, STOP WITH THE BOMBING!
	"scenes/Mechanic/WorldC5M104.vcd",		//PLEASE DO NOT BOMB US
	"scenes/Producer/WorldC5M4B04.vcd",		//Something tells me they're not checking for survivors anymore.
	"scenes/Producer/WorldC5M4B01.vcd",		//We need to keep moving.
	"scenes/Producer/WorldC5M4B03.vcd"		//That was close.
};

void Vocalize(int client)
{
	if( g_iCvarVocalize == 0 || GetRandomInt(1, 100) > g_iCvarVocalize )
		return;

	char sModel[64];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	int random;
	switch( sModel[29] )
	{
		case 'c': random = GetRandomInt(0, 2);		// Coach
		case 'b': random = GetRandomInt(3, 6);		// Gambler
		case 'h': random = GetRandomInt(7, 12);		// Mechanic
		case 'd': random = GetRandomInt(13, 15);	// Producer
		default: return;
	}

	int entity = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(entity, "SceneFile", g_sVocalize[random]);
	DispatchSpawn(entity);
	SetEntPropEnt(entity, Prop_Data, "m_hOwner", client);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start", client, client);
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

// Credit to Timocop on VScript function
void StaggerClient(int iUserID, const float fPos[3])
{
	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if( iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic) )
	{
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
			LogError("Could not create 'logic_script");

		DispatchSpawn(iScriptLogic);
	}

	char sBuffer[96];
	Format(sBuffer, sizeof(sBuffer), "GetPlayerFromUserID(%d).Stagger(Vector(%d,%d,%d))", iUserID, RoundFloat(fPos[0]), RoundFloat(fPos[1]), RoundFloat(fPos[2]));
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
	RemoveEntity(iScriptLogic);
}

void L4D_ForcePanicEvent()
{
	static int director = INVALID_ENT_REFERENCE;

	if( director == INVALID_ENT_REFERENCE || EntRefToEntIndex(director) == INVALID_ENT_REFERENCE )
	{
		director = FindEntityByClassname(-1, "info_director");
		if( director != INVALID_ENT_REFERENCE )
		{
			director = EntIndexToEntRef(director);
		}
	}

	if( director != INVALID_ENT_REFERENCE )
	{
		AcceptEntityInput(director, "ForcePanicEvent");
		return;
	}

	int flags = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("director_force_panic_event", flags & ~FCVAR_CHEAT);
	ServerCommand("director_force_panic_event");
	SetCommandFlags("director_force_panic_event", flags);
}
