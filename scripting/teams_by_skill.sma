#include <amxmodx>
#include <amxmisc>

// #define NOPLAYERTEST

new Trie:g_tSkillLevels
new Bool:g_bActive

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
	register_plugin("Assign Teams by Skill", "0.2", "Fysiks")
	
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

	if( g_bActive )
	{
		console_print(id, "Team assignments are in progress")
		return PLUGIN_HANDLED
	}

	new id, szAuthId[33], iPlayerSkill[32][asdf]

	new iPlayers[32], iPlayersNum

#if defined NOPLAYERTEST
	iPlayersNum = 8
	for( new i = 0; i < iPlayersNum; i++ )
	{
		iPlayers[i] = i+1
	}
#else
	get_players(iPlayers, iPlayersNum)
#endif

	for( new i = 0; i < iPlayersNum; i++ )
	{
		id = iPlayers[i]
#if defined NOPLAYERTEST
		copy(szAuthId, charsmax(szAuthId), g_szTestAuthIds[i])
#else
		get_user_authid(id, szAuthId, charsmax(szAuthId))
#endif
		iPlayerSkill[i][ID] = id
		TrieGetCell(g_tSkillLevels, szAuthId, iPlayerSkill[i][SKILL])
	}

	// Sort by skill
	SortCustom2D(iPlayerSkill, iPlayersNum, "SortBySkill")

	// Assign Teams
	for( new i = 0; i < iPlayersNum; i++ )
	{
		if( (i % 2) == 0 )
		{
#if defined NOPLAYERTEST
			server_print("%d -> %d >> Allies", iPlayerSkill[i][ID], iPlayerSkill[i][SKILL])
#else
			amxclient_cmd(iPlayerSkill[i][ID], "jointeam", "1")
#endif
		}
		else
		{
#if defined NOPLAYERTEST
			server_print("%d -> %d >> Axis", iPlayerSkill[i][ID], iPlayerSkill[i][SKILL])
#else
			amxclient_cmd(iPlayerSkill[i][ID], "jointeam", "2")
#endif
		}
	}

	return PLUGIN_HANDLED
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

