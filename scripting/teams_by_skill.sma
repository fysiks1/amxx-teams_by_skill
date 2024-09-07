#include <amxmodx>
#include <amxmisc>

// #define NOPLAYERTEST

new Trie:g_tSkillLevels
new g_iPlayers[32], g_iTeam[sizeof g_iPlayers]
new g_iPlayersNum, g_iAssignmentCounter
new g_iCaller
new const TASKID = 874434

enum asdf {
	ID,
	SKILL
}

#if defined NOPLAYERTEST
new g_szTestAuthIds[][] = {
	"STEAM_0:0:1",
	"STEAM_0:0:2",
	"STEAM_0:0:3",
	"STEAM_0:0:4",
	"STEAM_0:0:5",
	"STEAM_0:0:6",
	"STEAM_0:0:7",
	"STEAM_0:0:8",
	"STEAM_0:0:9",
	"STEAM_0:0:10"
}
#endif

public plugin_init()
{
	register_plugin("Assign Teams by Skill", "0.7", "Fysiks")
	
	register_concmd("amx_assignteams", "cmdAssignTeams", ADMIN_MAP)

	g_tSkillLevels = TrieCreate()
	LoadSkillLevels(g_tSkillLevels)
}

public plugin_end()
{
	TrieDestroy(g_tSkillLevels)
}

public cmdAssignTeams(id, level, cid)
{
	if( !cmd_access(id, level, cid, 1) )
	{
		return PLUGIN_HANDLED
	}

	log_amx("amx_assignteams: called")

	if( task_exists(TASKID) )
	{
		console_print(id, "Team assignments are in progress")
		return PLUGIN_HANDLED
	}

	log_amx("amx_assignteams: calculate teams")

	g_iCaller = id
	new _id, szAuthId[33], iPlayerSkill[32][asdf]

#if defined NOPLAYERTEST
	g_iPlayersNum = sizeof g_szTestAuthIds
	for( new i = 0; i < g_iPlayersNum; i++ )
	{
		g_iPlayers[i] = i+1
	}
#else
	get_players(g_iPlayers, g_iPlayersNum)
#endif

	log_amx("amx_assignteams: player count is %d", g_iPlayersNum)

	for( new i = 0; i < g_iPlayersNum; i++ )
	{
		_id = g_iPlayers[i]
#if defined NOPLAYERTEST
		copy(szAuthId, charsmax(szAuthId), g_szTestAuthIds[i])
#else
		get_user_authid(_id, szAuthId, charsmax(szAuthId))
#endif
		iPlayerSkill[i][ID] = _id
		TrieGetCell(g_tSkillLevels, szAuthId, iPlayerSkill[i][SKILL])
	}

	// Sort by skill
	SortCustom2D(iPlayerSkill, g_iPlayersNum, "SortBySkill")

	// Assign Teams
	for( new i = 0; i < g_iPlayersNum; i++ )
	{
		g_iTeam[i] = (i % 2) == 0 ? 1 : 2

		switch( g_iTeam[i] )
		{
			case 1: server_print("%d -> %d >> Allies", iPlayerSkill[i][ID], iPlayerSkill[i][SKILL])
			case 2: server_print("%d -> %d >> Axis", iPlayerSkill[i][ID], iPlayerSkill[i][SKILL])
		}
	}

	g_iAssignmentCounter = 0
	set_task(0.75, "ExecuteTeamAssignments", TASKID, .flags="a", .repeat=g_iPlayersNum)

	console_print(id, "Team assignments in progress")

	log_amx("amx_assignteams: task started")

	return PLUGIN_HANDLED
}

public ExecuteTeamAssignments()
{
	new i = g_iAssignmentCounter
	new id = g_iPlayers[i]

	log_amx("amx_assignteams: assign team for %N to %d", id, g_iTeam[i])

#if !defined NOPLAYERTEST
	if( !is_user_connected(id) )
		return
#endif
	switch( g_iTeam[i] )
	{
		case 1:
		{
#if defined NOPLAYERTEST
			server_print("%d -> Allies", id)
#else
			amxclient_cmd(id, "jointeam", "1")
			client_print(id, print_chat, "You have been assigned to Allies")
			console_print(g_iCaller, "%n was assigned to Allies (%i/%i)", id, i+1, g_iPlayersNum)
#endif
		}
		case 2:
		{
#if defined NOPLAYERTEST
			server_print("%d -> Axis", id)
#else
			amxclient_cmd(id, "jointeam", "2")
			client_print(id, print_chat, "You have been assigned to Axis")
			console_print(g_iCaller, "%n was assigned to Axis (%i/%i)", id, i+1, g_iPlayersNum)
#endif
		}
	}

	client_print(0, print_chat, "Team Assignment Progress:  %i/%i", i+1, g_iPlayersNum)

	log_amx("amx_assignteams: team assigned %i/%i", i+1, g_iPlayersNum)

	g_iAssignmentCounter += 1

	if( g_iAssignmentCounter == g_iPlayersNum )
	{
		if( is_user_connected(g_iCaller) || g_iCaller == 0 )
		{
			console_print(g_iCaller, "Team assignments complete")
		}
		log_amx("amx_assignteams: task over")
	}
}

public SortBySkill(const elem1[], const elem2[], const array[], data[], data_size)
{
	if( elem1[SKILL] > elem2[SKILL] )
	{
		return -1
	}
	else if( elem1[SKILL] == elem2[SKILL] )
	{
		return 0
	}
	else
	{
		return 1
	}
}

LoadSkillLevels(Trie:tSkillLevels)
{
	new szFilename[128], szBuffer[59], szAuthId[32], szSkill[6], iSkill
	get_configsdir(szFilename, charsmax(szFilename))
	add(szFilename, charsmax(szFilename), "/skill.ini")

	server_print("Filename:  %s", szFilename)

	new f = fopen(szFilename, "rt")
	if( f )
	{
		while( fgets(f, szBuffer, charsmax(szBuffer)) )
		{
			trim(szBuffer)
			if( szBuffer[0] == EOS )
			{
				continue
			}
			
			parse(szBuffer, szAuthId, charsmax(szAuthId), szSkill, charsmax(szSkill))
			iSkill = str_to_num(szSkill)
			TrieSetCell(tSkillLevels, szAuthId, iSkill)
		}

		fclose(f)
	}
}

