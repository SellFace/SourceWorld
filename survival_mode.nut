printl("SURVIVAL MODE START")

local WaveActive=true;
local RemainingEnemies=0;
local EnemiesToSpawn=0
local DesiredFaction="corruptors"

function GetRandomCombatMusic(excluded="")
{
	local Music=[
	"disturbed_and_powerful",
	"acid_breakbeat_death_jam",
	"methods",
	"mayhem",
	"combat3",
	"overdrive",
	"abra"
	]
	local Track=Music[RandomInt(0,Music.len()-1)];
	while (Track==excluded) Track=Music[RandomInt(0,Music.len()-1)];
	
	return Track
}

function Think()
{
	if (WaveActive&&RemainingEnemies==0)
	{
		printl("Next wave in 10")
		SW_MUSIC_OVERRIDE="shinjuku"
		WaveActive=false;
		RemainingEnemies=10
		
		local n=null
		while (n=Entities.FindByClassname(n,"npc*"))
		{
			if (n.GetClassname()!="npc_citizen") n.Destroy();
		}
		
		return 10
	}
	if (!WaveActive&&RemainingEnemies>0)
	{
		WaveActive=true
		SW_MUSIC_OVERRIDE=GetRandomCombatMusic()
		EnemiesToSpawn=RemainingEnemies
	}
	if (WaveActive&&RemainingEnemies>0&&EnemiesToSpawn==0)
	{
		local c=0
		local n=null
		while (n=Entities.FindByClassname(n,"npc*")) 
		{
			if (n&&n.GetClassname()!="npc_citizen") c++;
		}
		if (c<=0) RemainingEnemies=0;
		if (c<=0) DesiredFaction="";
	}
	if (WaveActive&&RemainingEnemies>0&&EnemiesToSpawn>0)
	{	
		if (DesiredFaction=="")
		{
			switch(RandomInt(0,3))
			{
				case 0: DesiredFaction="undead";break;
				case 1: DesiredFaction="combine";break;
				case 2: DesiredFaction="hecu";break;
				case 3: DesiredFaction="corruptors";break;
			}
		}

		local Num=AINetwork.NumNodes()
		local Pos=Vector(4999,4999,4999)
		local fails=0
		while (!(((Pos-player.GetOrigin()).Length()>600)&&((Pos-player.GetOrigin()).Length()<1200))&&fails<20) {Pos=AINetwork.GetNodePosition(RandomInt(0,Num-1));fails++}
		
		local IDName=LIST_ENEMY_NAMES[RandomInt(0,LIST_ENEMIES.len()-1)]
		local ID=LIST_ENEMIES[IDName]
		local i=0
		while (ID.faction!=DesiredFaction)
		{
			IDName=LIST_ENEMY_NAMES[RandomInt(0,LIST_ENEMIES.len()-1)]
			ID=LIST_ENEMIES[IDName]
		}
		if (IDName=="MANHACK") return 0;
		if (IDName.find("SECRET")!=null) return 0;
		
		
		local enemy=ID
			
		DesiredFaction=enemy.faction

		enemy.rawset("origin",Pos.ToKVString())
		enemy.rawset("angles","0 "+RandomInt(0,359)+" 0")
		enemy.rawset("squadname","squaddy_1")
		local enemyentity = SpawnEntityFromTable(enemy.classname,enemy)
		if ("model" in enemy) enemyentity.SetModel(enemy.model)
		if ("maxhealth" in enemy) enemyentity.SetMaxHealth(enemy.maxhealth)
		if ("health" in enemy) enemyentity.SetHealth(enemy.health)
		enemyentity.GetOrCreatePrivateScriptScope().EnemyName<-IDName
	
		enemyentity.UpdateEnemyMemory(player,player.GetOrigin(),null)
		
		EnemiesToSpawn--;
	}
	local n=null
	while (n=Entities.FindByClassname(n,"npc*")) 
	{
		if (n&&n.GetClassname()!="npc_citizen") n.UpdateEnemyMemory(player,player.GetCenter(),null);
	}
	
	return 1;
}