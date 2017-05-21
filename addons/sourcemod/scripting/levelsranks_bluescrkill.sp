#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>
#include <lvl_ranks>

#define PLUGIN_NAME "Levels Ranks"
#define PLUGIN_AUTHOR "RoadSide Romeo & R1KO"

int		g_iBSKLevel,
		g_iBSKButton[MAXPLAYERS+1],
		g_iBSKColor[4] = {0, 0, 200, 100};
Handle	g_hBlueScreenKill = null;

public Plugin myinfo = {name = "[LR] Module - Blue Screen Kill", author = PLUGIN_AUTHOR, version = PLUGIN_VERSION}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch(GetEngineVersion())
	{
		case Engine_CSGO, Engine_CSS: LogMessage("[%s Blue Screen Kill] Запущен успешно", PLUGIN_NAME);
		default: SetFailState("[%s Blue Screen Kill] Плагин работает только на CS:GO и CS:S", PLUGIN_NAME);
	}
}

public void OnPluginStart()
{
	LR_ModuleCount();
	HookEvent("player_death", PlayerDeath);
	g_hBlueScreenKill = RegClientCookie("LR_BlueScrKill", "LR_BlueScrKill", CookieAccess_Private);
	LoadTranslations("levels_ranks_bluescrkill.phrases");
	
	for(int iClient = 1; iClient <= MaxClients; iClient++)
    {
		if(IsClientInGame(iClient))
		{
			if(AreClientCookiesCached(iClient))
			{
				OnClientCookiesCached(iClient);
			}
		}
	}
}

public void OnMapStart() 
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/bluescrkill.ini");
	KeyValues hLR_BSK = new KeyValues("LR_BlueScrKill");

	if(!hLR_BSK.ImportFromFile(sPath) || !hLR_BSK.GotoFirstSubKey())
	{
		SetFailState("[%s Blue Screen Kill] : фатальная ошибка - файл не найден (%s)", PLUGIN_NAME, sPath);
	}

	hLR_BSK.Rewind();

	if(hLR_BSK.JumpToKey("Settings"))
	{
		g_iBSKLevel = hLR_BSK.GetNum("rank", 0);
	}
	else SetFailState("[%s Blue Screen Kill] : фатальная ошибка - секция Settings не найдена", PLUGIN_NAME);
	delete hLR_BSK;
}

public void PlayerDeath(Handle hEvent, char[] sEvName, bool bDontBroadcast)
{	
	int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(IsValidClient(iAttacker) && !g_iBSKButton[iAttacker] && (LR_GetClientRank(iAttacker) >= g_iBSKLevel))
	{
		int iClients[1];
		iClients[0] = iAttacker;

		Handle hMessage = StartMessage("Fade", iClients, 1);
		if(GetUserMessageType() == UM_Protobuf) 
		{
			PbSetInt(hMessage, "duration", 600);
			PbSetInt(hMessage, "hold_time", 0);
			PbSetInt(hMessage, "flags", 0x0001);
			PbSetColor(hMessage, "clr", g_iBSKColor);
		}
		else
		{
			BfWriteShort(hMessage, 600);
			BfWriteShort(hMessage, 0);
			BfWriteShort(hMessage, (0x0001));
			BfWriteByte(hMessage, 0);
			BfWriteByte(hMessage, 0);
			BfWriteByte(hMessage, 200);
			BfWriteByte(hMessage, 100);
		}
		EndMessage(); 
	}
}

public void LR_OnMenuCreated(int iClient, int iRank, Menu& hMenu)
{
	if(iRank == g_iBSKLevel)
	{
		char sText[64];
		SetGlobalTransTarget(iClient);

		if(LR_GetClientRank(iClient) >= g_iBSKLevel)
		{
			switch(g_iBSKButton[iClient])
			{
				case 0: FormatEx(sText, sizeof(sText), "%t", "BSK_On");
				case 1: FormatEx(sText, sizeof(sText), "%t", "BSK_Off");
			}

			hMenu.AddItem("BlueScreenKill", sText);
		}
		else
		{
			FormatEx(sText, sizeof(sText), "%t", "BSK_RankClosed", g_iBSKLevel);
			hMenu.AddItem("BlueScreenKill", sText, ITEMDRAW_DISABLED);
		}
	}
}

public void LR_OnMenuItemSelected(int iClient, int iRank, const char[] sInfo)
{
	if(iRank == g_iBSKLevel)
	{
		if(strcmp(sInfo, "BlueScreenKill") == 0)
		{
			switch(g_iBSKButton[iClient])
			{
				case 0: g_iBSKButton[iClient] = 1;
				case 1: g_iBSKButton[iClient] = 0;
			}
			
			LR_MenuInventory(iClient);
		}
	}
}

public void OnClientCookiesCached(int iClient)
{
	char sCookie[8];
	GetClientCookie(iClient, g_hBlueScreenKill, sCookie, sizeof(sCookie));
	g_iBSKButton[iClient] = StringToInt(sCookie);
} 

public void OnClientDisconnect(int iClient)
{
	if(AreClientCookiesCached(iClient))
	{
		char sBuffer[8];
		FormatEx(sBuffer, sizeof(sBuffer), "%i", g_iBSKButton[iClient]);
		SetClientCookie(iClient, g_hBlueScreenKill, sBuffer);		
	}
}

public void OnPluginEnd()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			OnClientDisconnect(iClient);
		}
	}
}