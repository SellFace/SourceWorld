::PrintTable<-function(t)
{
	foreach(k,v in t) printl(k+" : "+v)
}

::UTF8Bytes<-function ( str, idx )
{
	local cp = str[idx];

	if ( cp & 0x80 )
	{
		if ( ( cp & 0xE0 ) == 0xC0 )
			return 2;

		if ( ( cp & 0xF0 ) == 0xE0 )
			return 3;

		if ( ( cp & 0xF8 ) == 0xF0 )
			return 4;
	}
	
	return 1;
}

::LLen<-function (text)
{
	local truelen=text.len()
	for ( local i = 0; i < text.len(); )
	{
		local bytes = UTF8Bytes( text, i );
		i += bytes;
		truelen-=(bytes-1)
	}
	return truelen;
}

::GetTextLengthMult<-function (text)
{
	local truelen=text.len()
	for ( local i = 0; i < text.len(); )
	{
		local bytes = UTF8Bytes( text, i );
		i += bytes;
		truelen-=(bytes-1)
	}
	return text.len().tofloat()/truelen;
}

::LSlice<- function (text="",start=0,end=999999,OriginalEnd=false)
{

	local truestart = 0
	local trueend = 0
	local bytes = 0
	
	local times=0
	
	for ( local i = 0; times < start; times++ )
	{
		bytes = UTF8Bytes( text, i );
		i += bytes;
		truestart+=(bytes)
	}
	
	times=0
	
	if (end<=text.len()) for ( local i = 0; times < end; times++ )
	{
		bytes = UTF8Bytes( text, i );
		i += bytes;
		trueend+=(bytes)
	}
	
	if (end>text.len()) 
		trueend=text.len()
	
	if (OriginalEnd)
		trueend=end;
	
	//printl(truestart)
	//printl(trueend)
	return text.slice(truestart,trueend)
}

if (SERVER_DLL)
{
	::NXPrintDev<-function (r,g,b,a,bol,time,text) 
	{
		if (Convars.GetInt("developer")==1)
		{
			NXPrint(r,g,b,a,bol,time,text) 
		}
	}
	
	::CNPC_Citizen.StartFollowingPlayer<-function(WaitTillSeen=false)
	{
		::printl(this+" following "+::player)
		local followtable={
			actor=this.GetName()
			goal="!player"
			MaximumState=3
			Formation=0
			SearchType=0
			StartActive=0
			NormalMemoryDiscard=1
			targetname=this.GetName()+"_goal_follow"
		}
		::SpawnEntityFromTable("ai_goal_follow",followtable)
		
		if (!WaitTillSeen) ::EntFire(this.GetName()+"_goal_follow","Activate");
		else ::Entities.First().SetContextThink("goal_follow_think_"+this.entindex(),function(...)
		{
			//printl((player.GetOrigin()-NPC.GetOrigin()).Length()+" "+NPC.IsEntVisible(player))
			if (this.IsEntVisible(::player))
			{
				::EntFire(this.GetName()+"_goal_follow","Activate");
				return
			}
			else return 0.1;
		}.bindenv(this),0)
		
		return;
	}
	
	::CNPC_Citizen.StopFollowingPlayer<-function()
	{
		::printl(this+" stopped following "+::player)
		
		::EntFire(this.GetName()+"_goal_follow","Deactivate");
		::EntFire(this.GetName()+"_goal_follow","Kill","",0.1);
		return;
	}
	
	::GetNamedEnt<-function (name) 
	{
		return Entities.FindByName(null,name)
	}
	
	//::PrintEntity<- function (name)
	//{
	//	local t={}
	//	SaveEntityKVToTable(Entities.FindByName(null,name),t)
	//	foreach(k,v in t)
	//		printl(k+": "+v)
	//}
	
	//::LSTR<-Localize.GetTokenAsUTF8
	// No, this is NOT a Signalis reference. It stands for Localized STRing.
	// update: this shit broke with new squirrel version and i have NO IDEA why
	
	NetMsg.Receive("ClientInit", function( player )
	{
		Entities.First().SetContextThink("CallOnClientInitHook",function (...) {
			Hooks.Call("OnClientInit", null)
			printl("Calling OnClientInit hook.")
		},0.15)
	} );
	
	if (Convars.GetInt("developer")!=1)
	{
		SendToConsole("exec sourceworld")
		SendToConsoleServer("exec sourceworld")
		// Safer version of autoexec. Must be executed every time because autoexec convars tend to get screwed over in extremely rare instances.
	}
}

IncludeScript("status_effects.nut")

if (CLIENT_DLL)
{
	
	::printl<-function (a) 
	{
		try { printcl(255,155,25,a) }
		catch(exception) {
			printcl(255,155,25,a+"")
		}
	}
	
	::LSTR<-Localize.GetTokenAsUTF8
	// No, this is NOT a Signalis reference. It stands for Localized STRing.
	
	
	
	Convars.SetFloat("cl_rumblescale",1.0);
	Convars.SetFloat("mat_screen_blur_override",-1);
	if (GetMapName().find("background")==null)
	{
		local a= vgui.CreatePanel("Panel", vgui.GetClientDLLRootPanel(), "Screen3")
		local back= vgui.CreatePanel("ImagePanel", vgui.GetClientDLLRootPanel(), "Screen2")
		back.SetImage("console/background_widescreen",false)
		back.MakeReadyForUse()
		back.SetVisible(true)
		back.SetPos(XRES(0), YRES(0))
		back.SetSize(XRES(640),YRES(480))
		back.SetDrawColor(133,133,133,255)
		back.SetShouldScaleImage(true)

		a.SetCallback( "OnTick", function(){back.Destroy();a.Destroy();}.bindenv(this) )
		a.AddTickSignal(70)
	}
}
if (GetMapName().find("background")!=null) IncludeScript("gamemenu.nut")

if (SERVER_DLL) SendToConsoleServer("host_timescale 1");

if (CLIENT_DLL) return
local script = Entities.FindByName(null, "mapgen3/graph");
local scriptstamina = Entities.FindByName(null, "stamina_system");
local script2 = Entities.FindByName(null, "inventory_client");
local script3 = Entities.FindByName(null, "minimap_client");
local script4 = Entities.FindByName(null, "minimap_client");
if (GetMapName()=="background") //play the main menu theme because source cant do that on it's own
{
	Entities.First().SetContextThink("music",function(_) {
	//SendToConsoleServer("play *#ui/gamestartup1.mp3")
	},0.1)
}
scriptstamina = Entities.FindByName(null, "stamina_system");
local s_script="stamina.nut"
if (GetMapName().find("back")!=null) s_script="changemap.nut"
if (scriptstamina==null)
{
	printf("Script not found. Spawning...");
	local S = {
	targetname = "stamina_system",
	vscripts = s_script,
	thinkfunction = "Think",
	RunOnServer = 1,
	ClientThink = 1,
	origin = [0, 0, 0]
	}
	
	SpawnEntityFromTable("logic_script_client",S);
	SendToConsole("fadein 5")
}

// REMOVE THIS LATER
if (Convars.GetInt("developer")!=3)
{
	local S2 = {
	targetname = "spawnmenu",
	vscripts = "dev/spawnmenu.nut",
	origin = [0, 0, 0],
	thinkfunction = "Think",
	RunOnServer = 1,
	}
	
	if (!GetNamedEnt("spawnmenu")) SpawnEntityFromTable("logic_script_client",S2);	
}

if (GetMapName().find("s_")!=null&&GetMapName().find("s_")<2)
{
	local S = {
	targetname = "survival_thinker",
	vscripts = "survival_mode.nut",
	thinkfunction = "Think",
	RunOnServer = 1,
	}
	
	SpawnEntityFromTable("logic_script_client",S);	
	
	return
}

if (GetMapName().find("mapgens")!=null)
{
	local S = {
	targetname = "mapgen_thinker",
	vscripts = "mapgen.nut",
	}
	local S2 = {
	IDENTIFIER = "inv_client",
	targetname = "minimap_client",
	vscripts = "minimap.nut",
	origin = [0, 0, 0],
	thinkfunction = "Think",
	RunOnServer = 1,
	}
	
	SpawnEntityFromTable("logic_script_client",S2);	
	
	SpawnEntityFromTable("logic_script",S);
	return
}
else
{
	local S2 = {
	targetname = "minimap_client",
	vscripts = "minimap_redux.nut",
	origin = [0, 0, 0],
	thinkfunction = "Think",
	RunOnServer = 1,
	}
	
	if (!GetNamedEnt("minimap_client")) SpawnEntityFromTable("logic_script_client",S2);	
}


if (script==null)
{
	Entities.First().SetContextThink("mapgen",function(_) {
	
		//SendToConsole("script_execute_client mapgen3/graph")
		SendToConsole("script_execute mapgen3/graph")
		SendToConsole("script_execute_client mapgen3/graph")
	
	}.bindenv(this),1)
}

return
if (script2==null)
{
	printf("Script not found. Spawning...");
	local S = {
	IDENTIFIER = "inv_client",
	targetname = "inventory_client",
	vscripts = "inventory.nut",
	origin = [0, 0, 0],
	thinkfunction = "Think",
	RunOnServer = 1,
	}
	
	//SpawnEntityFromTable("logic_script_client",S);
}
if (script3==null)
{
	printf("Script not found. Spawning...");
	local S = {
	IDENTIFIER = "inv_client",
	targetname = "dialogue_client",
	vscripts = "dialogue_system.nut",
	origin = [0, 0, 0],
	thinkfunction = "Think",
	RunOnServer = 1,
	}
	
	//SpawnEntityFromTable("logic_script_client",S);
}
//EntFire("inventory_client","CallScriptFunction","InventoryInit",0)
//EntFire("inventory_client","CallScriptFunctionClient","InventoryInit",0.5) // this is bad, but it works ig
//EntFire("minimap_client","CallScriptFunction","MinimapInit",0)
//EntFire("minimap_client","CallScriptFunctionClient","MinimapInit",0.5)

function initclient(a)
{
	return
	//Hooks.Add( Entities.GetLocalPlayer().GetOrCreatePrivateScriptScope(),"UpdateOnRemove",function() { EntFire("inventory_client","CallScriptFunctionClient","InventoryInit",0) },"a" );
	//EntFire("inventory_client","CallScriptFunctionClient","InventoryInit",0)
	//EntFire("minimap_client","CallScriptFunctionClient","MinimapInit",0)
}
ListenToGameEvent( "player_spawn", initclient, "onplayerspawn" )
