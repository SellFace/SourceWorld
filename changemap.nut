IncludeScript("truetocaesar.nut")
IncludeScript("lists/tips.nut")
if (GetMapName()!="background") self.PrecacheSoundScript("k_lab.teleport_sound")
	
enum SW_QUEST_STATUS
{
    UNKNOWN   = 0,   // игрок ещё не знает о квесте
    AVAILABLE = 1,   // квест доступен, но не принят
    ACTIVE    = 2,   // квест взят, выполняется
    COMPLETED = 3,   // квест выполнен
    FAILED    = 4    // квест провален
}
	
local MapToLoad="demo_city"

::SW_MULTIVERSE<-{}
::SW_WORLD_INFO<-{}

::SW_TRAVELS<-0


::SW_TABLE<-{
	iPlayerKills=0,
	iMoneyGained=0,
	iMoneySpent=0,
	iDamageTaken=0
	iPlayTime=0
}

::SW_DIALOGUE_NPCS<-[]

::SW_SetContext <- function(name, value)
{
    if (name in SW_CONTEXTS)
        SW_CONTEXTS[name].State = value;
    if (SERVER_DLL && Entities.FindByName(null, "dialogue_manager"))
        Entities.FindByName(null, "dialogue_manager").AddContext(name, value.tostring(), 0);
}

// ============================================================
//  СТАТУСЫ
// ============================================================

::SW_QUEST_STATE <- {};

::SW_QUEST_UNKNOWN   <- 0;
::SW_QUEST_ACTIVE    <- 1;
::SW_QUEST_COMPLETED <- 2;
::SW_QUEST_FAILED    <- 3;

::SW_GetQuestStatus <- function(id)
{
    local ctxName = "quest_" + id;
    if (!(ctxName in SW_CONTEXTS)) return SW_QUEST_UNKNOWN;
    return SW_CONTEXTS[ctxName].State;
}

::SW_IsQuestActive <- function(id) { return SW_GetQuestStatus(id) == SW_QUEST_ACTIVE; }
::SW_IsQuestCompleted <- function(id) { return SW_GetQuestStatus(id) == SW_QUEST_COMPLETED; }
::SW_IsQuestFailed <- function(id) { return SW_GetQuestStatus(id) == SW_QUEST_FAILED; }

// ============================================================
//  ОПЕРАЦИИ
// ============================================================

::SW_ActivateQuest <- function(id)
{
    if (!(id in SW_QUESTS)) { printl("[QUEST] Unknown: " + id); return false; }
    local ctxName = "quest_" + id;
    if (!(ctxName in SW_CONTEXTS)) { printl("[QUEST] No context: " + ctxName); return false; }
    
    local ctx = SW_CONTEXTS[ctxName];
    if (ctx.State > 0) return false;
    
    ctx.Activate();   // State = 1, AddContext, OnActivated
    SW_QuestNotify(id, "NEW");
    printl("[QUEST] Activated: " + SW_QUESTS[id].Name);
    return true;
}

::SW_CompleteQuest <- function(id)
{
    if (!(id in SW_QUESTS)) return false;
    local ctxName = "quest_" + id;
    if (!(ctxName in SW_CONTEXTS)) return false;
    
    local ctx = SW_CONTEXTS[ctxName];
    if (ctx.State == SW_QUEST_COMPLETED) return false;
    
    ctx.State = SW_QUEST_COMPLETED;
    if (SERVER_DLL && Entities.FindByName(null, "dialogue_manager"))
        Entities.FindByName(null, "dialogue_manager").AddContext(ctxName, "2", 0);
    
    SW_QuestNotify(id, "COMPLETE");
    printl("[QUEST] Completed: " + SW_QUESTS[id].Name);
    return true;
}

::SW_FailQuest <- function(id)
{
    if (!(id in SW_QUESTS)) return false;
    local ctxName = "quest_" + id;
    if (!(ctxName in SW_CONTEXTS)) return false;
    
    local ctx = SW_CONTEXTS[ctxName];
    ctx.State = SW_QUEST_FAILED;
    if (SERVER_DLL && Entities.FindByName(null, "dialogue_manager"))
        Entities.FindByName(null, "dialogue_manager").AddContext(ctxName, "3", 0);
    
    SW_QuestNotify(id, "FAIL");
    return true;
}

// ============================================================
//  УВЕДОМЛЕНИЯ
// ============================================================

local LastQuestNotification=0;

::SW_QuestNotify <- function(id, action)
{
	local NotificationDelay=max(LastQuestNotification+0.5-Time(),0.1)
	
    if (!SERVER_DLL) return;
	Entities.First().SetContextThink("quest_"+id+"_notification_"+action,function(_){
    NetMsg.Start("SW_QuestNotify");
    NetMsg.WriteString(id);
    NetMsg.WriteString(action);
    NetMsg.Send(player, true);
	}.bindenv(this),NotificationDelay)
	
	LastQuestNotification=Time()+NotificationDelay;
}

::SW_DIFFICULTY_RANK <- 0;

::SW_GetDifficultyRank <- function()
{
    return SW_DIFFICULTY_RANK;
}

::SW_GetRankNorm <- function()
{
    // -5000 → 0.0, 0 → 0.5, +5000 → 1.0
    return clamp((SW_DIFFICULTY_RANK + 5000.0) / 10000.0, 0.0, 1.0);
}

// DEATH COUNTER
// Resets after manual save loads or level transitions.
// Used to lower difficulty score after player presses continue.
if (SERVER_DLL)
{
	if (Globals.GetIndex("SW_DeathCount") == -1)
	{
		Globals.AddGlobal("SW_DeathCount", GetMapName(), 1);
		Globals.SetCounter(Globals.GetIndex("SW_DeathCount"), 0);
	}

	::SW_GetDeathCount <- function()
	{
		return Globals.GetCounter(Globals.GetIndex("SW_DeathCount"));
	}

	::SW_SetDeathCount <- function(value)
	{
		Globals.SetCounter(Globals.GetIndex("SW_DeathCount"), value);
	}

	::SW_IncrementDeathCount <- function()
	{
		local current = SW_GetDeathCount();
		SW_SetDeathCount(current + 1);
		printl("[DIFFICULTY] Death count incremented to " + (current + 1));
		return current + 1;
	}
}


IncludeScript("lists/mail.nut")
IncludeScript("lists/files.nut")
IncludeScript("lists/missions.nut")
IncludeScript("lists/contexts.nut")
IncludeScript("lists/quests.nut") 
IncludeScript("lists/events.nut")
IncludeScript("lists/savepoints.nut")

::PrintProgress<-function()
{
	printl("")
	foreach(k,v in SW_CONTEXTS) printl(k+" : "+v.State);
	printl("")
	foreach(k,v in SW_EVENTS) printl(k+" : "+v.State);
}

function CreatePlayID(id=-1)
{
	PlayID<-0
	if (id>(-1)) PlayID=id;
	if (Globals.GetIndex("MapgenTravels")==-1)
	{
		SW_TRAVELS=0
		TravelsGlobal<-Globals.AddGlobal("MapgenTravels",GetMapName(),1);
		Globals.SetCounter(TravelsGlobal,SW_TRAVELS)
		printl("\tNo registered runs count(SW_TRAVELS)! Creating one.")
		local rndseed=date().sec+date().min+date().day+date().month
		if (SERVER_DLL) SetPlaythroughSeed(rndseed)
	}
	GetTravels<-function() return Globals.GetCounter(Globals.GetIndex("MapgenTravels"));
	
	
	PlayIDGlobal<-Globals.GetIndex("PlaythroughID")
	if (PlayIDGlobal==-1&&!(id>(-1)))
	{
		while (FileExists("saves/savedata_"+PlayID+".sav") == true&&!(id>(-1))) PlayID++; 
		PlayIDGlobal=Globals.AddGlobal("PlaythroughID",GetMapName(),1);
		Globals.SetCounter(PlayIDGlobal,PlayID)
	}
	if (id>(-1)) Globals.SetCounter(PlayIDGlobal,PlayID);
	
	return Globals.GetCounter(Globals.GetIndex("PlaythroughID"))
}

function Encode(a)
{

/*
	key<-"X"
	a=a.tostring()
	if (a.find("weapon")!=null) key="%";
	if (a.find("context")!=null) key="D";
	b<-""
	for (local i=0; i<a.len();i++)
	{
		b+=(a[i]^key[i%key.len()]).tochar();
	}
	
	*/
	
	return AssCrypt.encrypt(a)
}

function Decode(a)
{
	return AssCrypt.decrypt(a)
	key<-"X"
	a=a.tostring()
	if (a.find("R@DUJK")!=null) key="%";
	if (a.find("'+*0!<07")!=null) key="D";
	b<-""
	for (local i=0; i<a.len();i++)
	{
		b+=(a[i]^key[i%key.len()]).tochar();
	}
	printl("\t"+a+"   ->   "+b)
	return b
}

::SW_SHOW_LOADING<-function()
{
	NetMsg.Start("FadeScreen")
	NetMsg.Send(player, true);
	player.SetMoveType(10)
	Entities.First().SetContextThink("LOADING",function(_){
		SendToConsole("stopsound")
		player.SetOrigin(Vector(9999,9999,99999))
	}.bindenv(this),0.6)
}

function SaveData(freeze=false)
{
	if (freeze==true) {
		//SendToConsole("fadeout 0.4")
		NetMsg.Start("FadeScreen")
		NetMsg.Send(player, true);
		player.SetMoveType(10)
	}
	PlayID<-CreatePlayID()
	
	// Если это успешное сохранение в слот -1 (переход через портал) — обнуляем счётчик смертей в Globals.
	// Ранг при этом сохраняется как есть.
	if (PlayID == -1)
	{
		SW_SetDeathCount(0);
		printl("[DIFFICULTY] SaveData(-1): death count reset (successful transition).");
	}
	
	Save<-CScriptKeyValues();
	Save.SetName( "SaveData" );
	local SkillsInfo=""
	for (local SkillID=0;SkillID<SKILLS_ORDER.len();SkillID++)
	{
		local Skill=SKILLS[SKILLS_ORDER[SkillID]]
		if (Skill.Unlocked==true) SkillsInfo+="1"
		else SkillsInfo+="0"
	}
	PlayerData<-Save.FindOrCreateKey("PlayerData");
	SWData<-Save.FindOrCreateKey("SWData");
	MailData<-Save.FindOrCreateKey("MailData");
	
	ContextData<-Save.FindOrCreateKey("ContextData");
	
	foreach (name,context in SW_CONTEXTS)
	{
		ContextData.SetKeyString(Encode(name),Encode(context.State))
	}
	
	EventData<-Save.FindOrCreateKey("EventData");
	
	foreach (name,event in SW_EVENTS)
	{
		EventData.SetKeyString(Encode(name),Encode(event.State))
	}
	
	// === QUESTS ===
	QuestData<-Save.FindOrCreateKey("QuestData");
	foreach (id, state in SW_QUEST_STATE)
	{
		// Формат: id → "status progress"
		QuestData.SetKeyString(Encode(id), Encode(state.Status + " " + state.Progress));
	}
	
	FileData<-Save.FindOrCreateKey("FileData");
	WeaponsData<-Save.FindOrCreateKey("WeaponsData");
	InventoryData<-Save.FindOrCreateKey("InventoryData");
	ItemChestData<-Save.FindOrCreateKey("ItemChestData");
	EquipmentData<-Save.FindOrCreateKey("EquipmentData");
	MultiverseData<-Save.FindOrCreateKey("MultiverseData");
	WorldData<-Save.FindOrCreateKey("WorldData");
	StatusFXData<-Save.FindOrCreateKey("StatusFXData");
	
	//SW_TABLE.iPlayTime+=Time().tointeger();
	foreach (k,v in SW_TABLE) SWData.SetKeyString(k, Encode(v));
	foreach (k,v in SW_TABLE) SWData.SetKeyString("iPlayTime", Encode(SW_TABLE.iPlayTime+Time().tointeger()));
	
	foreach (k,v in SW_MAILS) 
	{
		local MailKey = MailData.FindOrCreateKey(Encode(k));
		if (v.DateReceived) foreach(dateKey,dateInt in v.DateReceived) MailKey.SetKeyString(Encode(dateKey),Encode(dateInt))
		MailKey.SetKeyString(Encode("Status"),Encode(v.Status))
	}
	
	foreach(i,Status in ACTIVE_STATUS_EFFECTS)
	{
		if (Status==null) continue;
		
		if (Status.Victim==player)
		{
			local StatusKey = StatusFXData.FindOrCreateKey(Encode(i));
			StatusKey.SetKeyString(Encode("tech_name"),Encode(Status.Effect.tech_name))
			StatusKey.SetKeyString(Encode("InitialTicks"),Encode(Status.InitialTicks))
			StatusKey.SetKeyString(Encode("RemainingTicks"),Encode(Status.RemainingTicks))
		}
	}
	
	PlayerData.SetKeyString(Encode("health"), Encode(player.GetHealth()));
	PlayerData.SetKeyString(Encode("armor"), Encode(player.GetArmor()));
	PlayerData.SetKeyString(Encode("exp"), Encode(PlayerExperience));
	PlayerData.SetKeyString(Encode("money"), Encode(PlayerMoney));
	PlayerData.SetKeyString(Encode("map"), Encode(GetMapName()));
	PlayerData.SetKeyString(Encode("difficulty_rank"), Encode(SW_DIFFICULTY_RANK));
	if (SW_ACTIVE_MISSION) PlayerData.SetKeyString(Encode("active_mission"), Encode(SW_ACTIVE_MISSION));
	PlayerData.SetKeyString(Encode("playermodel"), Encode(player.GetModelName()));
	PlayerData.SetKeyString(Encode("plrskills"), Encode(SkillsInfo));
	PlayerData.SetKeyString(Encode("sp"), Encode(PlayerSkillPoints));
	PlayerData.SetKeyString(Encode("travels"), Encode(Globals.GetCounter(Globals.GetIndex("MapgenTravels"))));
	printl("Saving playthrough seed which is "+SW_PLAYTHROUGH_SEED)
	PlayerData.SetKeyString(Encode("playthroughseed"), Encode(SW_PLAYTHROUGH_SEED));
	PlayerData.SetKeyString("origin", Encode(player.GetOrigin().x+" "+player.GetOrigin().y+" "+player.GetOrigin().z ));
	PlayerData.SetKeyString("angles", Encode(player.EyeAngles().x+" "+player.EyeAngles().y+" "+player.EyeAngles().z ));
	local month=date().month+1
	if (month<10) month="0"+month
	local minutes=date().min
	if (minutes<10) minutes="0"+minutes
	local hour=date().hour
	if (hour<10) hour="0"+hour
	local seconds=date().sec
	if (seconds<10) seconds="0"+seconds
	local day=date().day
	if (day<10) day="0"+day
	
	
	PlayerData.SetKeyString("time", day+"."+month+"."+date().year+" "+hour+":"+minutes+":"+seconds);
	
	/////////////////////
	/// WEAPONS DATA ////
	/////////////////////
	local Weapons={}

	WeaponsData.SetKeyString(Encode("SW_Player_LastInv"), Encode(SW_Player_LastInv));
	
	///////////////////////
	///  INVENTORY DATA ///
	///////////////////////
	foreach (k,v in INVENTORY)
	{
		if (v==null) InventoryData.SetKeyString(Encode(k), Encode("null"));
		else if (v==null||(typeof v)=="integer") InventoryData.SetKeyString(Encode(k), Encode(v));
		else InventoryData.SetKeyString(Encode(k), Encode(v.tech_name+" "+v.Count+" "+v.Clip+" "+v.Durability));
		
		if (v!=null)
		{
			local InvSlot=InventoryData.FindOrCreateKey(Encode(k.tostring()))
			if (typeof v=="integer") InvSlot.SetKeyString(Encode("ref"),Encode(v))
			else
			{
				InvSlot.SetKeyString("tech_name",Encode(v.tech_name))
				InvSlot.SetKeyString("SizeX",Encode(v.SizeX))
				InvSlot.SetKeyString("SizeY",Encode(v.SizeY))
				InvSlot.SetKeyString("Rotated",Encode(v.Rotated))
				InvSlot.SetKeyString("Count",Encode(v.Count))
				InvSlot.SetKeyString("Clip",Encode(v.Clip))
				InvSlot.SetKeyString("Durability",Encode(v.Durability))
				InvSlot.SetKeyString("DropFlag",Encode(v.DropFlag))
				InvSlot.SetKeyString("WeaponInvID",Encode((v.WeaponInvID==null ? "null" : v.WeaponInvID)))
				InvSlot.SetKeyString("WeaponSlot",Encode((v.WeaponSlot==null ? "null" : v.WeaponSlot)))
				//InvSlot.SetKeyString("QuickUseSlot",Encode((v.QuickUseSlot==null ? "null" : v.QuickUseSlot)))
			}
		}
	}
	foreach (k,v in CONTAINERS["ItemChest"].INVENTORY)
	{
		if (v==null) ItemChestData.SetKeyString(Encode(k), Encode("null"));
		else if (v==null||(typeof v)=="integer") ItemChestData.SetKeyString(Encode(k), Encode(v));
		else ItemChestData.SetKeyString(Encode(k), Encode(v.tech_name+" "+v.Count+" "+v.Clip));
		
		if (v!=null)
		{
			local InvSlot=ItemChestData.FindOrCreateKey(Encode(k.tostring()))
			if (typeof v!="integer")
			{
				InvSlot.SetKeyString("tech_name",Encode(v.tech_name))
				InvSlot.SetKeyString("SizeX",Encode(v.SizeX))
				InvSlot.SetKeyString("SizeY",Encode(v.SizeY))
				InvSlot.SetKeyString("Rotated",Encode(v.Rotated))
				InvSlot.SetKeyString("Count",Encode(v.Count))
				InvSlot.SetKeyString("Clip",Encode(v.Clip))
				InvSlot.SetKeyString("Durability",Encode(v.Durability))
				InvSlot.SetKeyString("DropFlag",Encode(v.DropFlag))
				InvSlot.SetKeyString("WeaponInvID",Encode((v.WeaponInvID==null ? "null" : v.WeaponInvID)))
				InvSlot.SetKeyString("WeaponSlot",Encode((v.WeaponSlot==null ? "null" : v.WeaponSlot)))
				//InvSlot.SetKeyString("QuickUseSlot",Encode((v.QuickUseSlot==null ? "null" : v.QuickUseSlot)))
			}
		}
	}
	foreach (k,v in EQUIPMENT)
	{
		if (v!=null) 
		{
			EquipmentData.SetKeyString(Encode(k), Encode(v.tech_name));
		}
	}
	PlayerData.SetKeyString("WEAPON_SLOTS",WEAPON_SLOTS[0]+" "+WEAPON_SLOTS[1]+" "+WEAPON_SLOTS[2]+" "+WEAPON_SLOTS[3]+" "+WEAPON_SLOTS[4]+" "+WEAPON_SLOTS[5])
	PlayerData.SetKeyString("QUICK_USE_SLOTS",QUICK_USE_SLOTS[0]+" "+QUICK_USE_SLOTS[1]+" "+QUICK_USE_SLOTS[2]+" "+QUICK_USE_SLOTS[3])
	
	
	
	foreach (k,v in SW_MULTIVERSE)
	{
		// k is world id, v is world status
		if (v==0) continue
		MultiverseData.SetKeyString(Encode(k),Encode(v))
	}
	foreach (k,v in SW_WORLD_INFO)
	{
		WorldData.SetKeyString(Encode(k),Encode(v))
	}
	
	PlayerData.SetKeyString("COMPANIONS",SW_COMPANIONS[0]+" "+SW_COMPANIONS[1])
	
	if (Weapons.len()>0)
	{
		PlayerData.SetKeyString(Encode("active_weapon"), Encode(player.GetActiveWeapon().GetClassname()));
	}
	else PlayerData.SetKeyString("active_weapon", "");
	
	
	KeyValuesToFile("saves/savedata_"+PlayID+".sav", Save);
	printf( "\t%s\n", "Save created! For playthrough "+PlayID+"!" )
	return
}

Loaded<-false

function ClientThink()
{
	return
}

function OnNewGame()
{
	SW_DIFFICULTY_RANK = 0;
    SW_SetDeathCount(0);
    printl("[DIFFICULTY] New game. Rank reset to 0, death count reset.");
	
	local Richard=GetNamedEnt("Richard")
	Hooks.Add( this, "DialogueEnd_richard_greet", function(...)
	{
		Richard.StopFollowingPlayer()
		SW_ActivateQuest("meet_vlad_cafe")
	}.bindenv(this),"1")
	
	SW_AddDialog("richard_greet","richard",1)
	Richard.StartFollowingPlayer(true)
	
	foreach (Context in SW_CONTEXTS)
		Context.Load();
	foreach (Event in SW_EVENTS)
		Event.Load();
	
	printl("Started new game...")
	
	/*
	IncludeScript("swfm/intro")
	Hooks.Add( this, "OnClientInit", function(...)
	{
		local S4 = {
		targetname = "spawnmenu",
		vscripts = "swfm/intro.nut",
		origin = [0, 0, 0],
		thinkfunction = "Think",
		RunOnServer = 1,
		}
		
		SpawnEntityFromTable("logic_script_client",S4);	
	}.bindenv(this),"Intro")
	*/
}

function LoadData(id=-1)
{
	if (Loaded==true) return;
	PlayID<-CreatePlayID(id)
	
	EntFire("trigger_changelevel","AddOutput","OnChangeLevel logic_script_client:Kill::0:1")
	
	if (FileExists("user_settings"))
	{
		SendToConsole(FileToString("user_settings"))
	}
	
	if (FileExists("saves/savedata_"+PlayID+".sav") == false)
	{
		printf( "\t%s\n", "No savedata to load for playthrough "+PlayID+"!" )
		if (GetMapName()=="demo_city") 
			OnNewGame();
		if (GetMapName().find("sw_")!=null)
			Hooks.Add( this, "OnClientInit", function(...)
			{
				SendToConsole("uma 100")
			}.bindenv(this),"StartingLoadout")
		return
	}
	
	local SaveKV=FileToKeyValues( "saves/savedata_"+PlayID+".sav" )
	
	Save<-SaveKV.FindOrCreateKey("PlayerData");
	WeaponsData<-SaveKV.FindOrCreateKey("WeaponsData")
	InventoryData<-SaveKV.FindOrCreateKey("InventoryData")
	ItemChestData<-SaveKV.FindOrCreateKey("ItemChestData")
	EquipmentData<-SaveKV.FindOrCreateKey("EquipmentData")
	MultiverseData<-SaveKV.FindOrCreateKey("MultiverseData")
	WorldData<-SaveKV.FindOrCreateKey("WorldData")
	SWData<-SaveKV.FindKey("SWData")
	MailData<-SaveKV.FindKey("MailData")
	FileData<-SaveKV.FindKey("FileData")
	StatusFXData<-SaveKV.FindKey("StatusFXData")
	
	ContextData<-SaveKV.FindKey("ContextData")
	EventData<-SaveKV.FindKey("EventData")
	
	Loaded=true
	
	if (ContextData) for ( local Field = ContextData.GetFirstSubKey(); Field; Field = Field.GetNextKey() )
	{
		local Name=Decode(Field.GetName())
		local state=Decode(Field.GetString()).tointeger()
		
		SW_CONTEXTS[Name].State=state
	}
	if (EventData) for ( local Field = EventData.GetFirstSubKey(); Field; Field = Field.GetNextKey() )
	{
		local Name=Decode(Field.GetName())
		local state=Decode(Field.GetString()).tointeger()
		
		SW_EVENTS[Name].State=state
	}
	
	QuestData<-SaveKV.FindKey("QuestData");
	if (QuestData)
	{
		SW_QUEST_STATE = {};
		for (local Field = QuestData.GetFirstSubKey(); Field; Field = Field.GetNextKey())
		{
			local id = Decode(Field.GetName());
			local parts = split(Decode(Field.GetString()), " ");
			if (parts.len() < 2) continue;
			
			SW_QUEST_STATE[id] <- {
				Status = parts[0].tointeger(),
				Progress = parts[1].tointeger()
			};
		}
		printl("[QUEST] Loaded " + SW_QUEST_STATE.len() + " quests.");
	}
	// Синхронизация квестов с клиентом после загрузки
	Entities.First().SetContextThink("QuestSyncToClient", function(_)
	{
		foreach (id, def in SW_QUESTS)
		{
			local ctxName = "quest_" + id;
			if (!(ctxName in SW_CONTEXTS)) continue;
			
			local state = SW_CONTEXTS[ctxName].State;
			local action = "";
			
			if (state == SW_QUEST_ACTIVE) action = "NEW";
			else if (state == SW_QUEST_COMPLETED) action = "COMPLETE";
			else if (state == SW_QUEST_FAILED) action = "FAIL";
			
			NetMsg.Start("SW_QuestRestore");
			NetMsg.WriteString(id);
			NetMsg.WriteString(action);
			NetMsg.Send(player, true);
		}
		
		return;
	}.bindenv(this), 1);
	
	if (SWData) for ( local Field = SWData.GetFirstSubKey(); Field; Field = Field.GetNextKey() )
	{
		local k=Field.GetName()
		local v=Decode(Field.GetString())
	
		NetMsg.Start("SW_TableToClient")
		NetMsg.WriteString(k)
		NetMsg.WriteString(v)
		NetMsg.Send(player,true)
		
		switch(k.slice(0,1))
		{
			case "i": v=v.tointeger();break;
			case "f": v=v.tofloat();break;
			case "s": break;
		}
		
		SW_TABLE.rawset(k,v)
	}
	
	if (MailData) for ( local Field = MailData.GetFirstSubKey(); Field; Field = Field.GetNextKey() )
	{
		local MailName=Decode(Field.GetName())
		local MailStatus=Decode(Field.FindKey(Encode("Status")).GetString()).tointeger()
		local MailDate={}
		for ( local DateField = Field.GetFirstSubKey(); DateField; DateField = DateField.GetNextKey() )
		{
			if (DateField.GetName()!=Encode("Status")) MailDate.rawset(Decode(DateField.GetName()),Decode(DateField.GetString()).tointeger())
		}
		
		SW_MAILS[MailName].DateReceived=MailDate
		if (MailDate.len()==0) 
			SW_MAILS[MailName].DateReceived=null;
		if (MailStatus>0) SW_MAILS[MailName].Restore(MailStatus)
	}
	
	if (StatusFXData) for ( local Field = StatusFXData.GetFirstSubKey(); Field; Field = Field.GetNextKey() )
	{
		local ID=Decode(Field.GetName())
		local tech_name=Decode(Field.FindKey(Encode("tech_name")).GetString())
		local InitialTicks=Decode(Field.FindKey(Encode("InitialTicks")).GetString()).tointeger()
		local RemainingTicks=Decode(Field.FindKey(Encode("RemainingTicks")).GetString()).tointeger()
		
		Hooks.Add( this, "OnClientInit", function(...)
		{
			StatusEffect = SW_ApplyStatusEffect(tech_name,player,InitialTicks)
			StatusEffect.SetRemainingTicks(RemainingTicks)
		}.bindenv(this),"StatusFXRestore_"+ID)
	}
	
	Health<-Decode(Save.GetKeyString(Encode("health"))).tointeger()
	Armor<-Decode(Save.GetKeyString(Encode("armor"))).tointeger()
	Playermodel<-Decode(Save.GetKeyString(Encode("playermodel")))
	Map<-Decode(Save.GetKeyString(Encode("map")))
	Active_Mission<-null
	if (Save.FindKey(Encode("active_mission"))&&GetMapName().find(SW_MISSIONS[Decode(Save.GetKeyString(Encode("active_mission")))].Maps[0])!=null) Active_Mission<-Decode(Save.GetKeyString(Encode("active_mission")))
	//if (SW_ACTIVE_MISSION&&SW_ACTIVE_MISSION!=""&&GetMapName().find(SW_MISSIONS[SW_ACTIVE_MISSION].Maps[0])==null) SW_ACTIVE_MISSION=null;
	XP<-Decode(Save.GetKeyString(Encode("exp"))).tofloat()
	Money<-Decode(Save.GetKeyString(Encode("money"))).tofloat()
	SkillsInfo<-Decode(Save.GetKeyString(Encode("plrskills")))
	//ContextsInfo<-Decode(Save.GetKeyString(Encode("contexts")))
	SkillPoints<-Decode(Save.GetKeyString(Encode("sp"))).tointeger()
	SW_TRAVELS=Decode(Save.GetKeyString(Encode("travels"))).tointeger()
	printl("Saved playthrough seed is "+Decode(Save.GetKeyString(Encode("playthroughseed"))).tointeger())
	if (SERVER_DLL) SetPlaythroughSeed(Decode(Save.GetKeyString(Encode("playthroughseed"))).tointeger());
	if (Save.GetKeyString("origin").len()>4)
	{
		printl(Decode(Save.GetKeyString("origin")))
		printl(Decode(Save.GetKeyString("angles")))
		local playerorigin_string=split(Decode(Save.GetKeyString("origin"))," ")
		PlayerOrigin<-Vector(playerorigin_string[0].tofloat(),playerorigin_string[1].tofloat(),playerorigin_string[2].tofloat())
		local playerangles_string=split(Decode(Save.GetKeyString("angles"))," ")
		PlayerAngles<-Vector(playerangles_string[0].tofloat(),playerangles_string[1].tofloat(),playerangles_string[2].tofloat())
	}
	
	// Загружаем ранг из сейва
	if (Save.FindKey(Encode("difficulty_rank")))
		SW_DIFFICULTY_RANK = Decode(Save.GetKeyString(Encode("difficulty_rank"))).tofloat();
	else
		SW_DIFFICULTY_RANK = 0;

	// Читаем счётчик смертей из Globals
	local deathCount = SW_GetDeathCount();

	// Если игрок умер N раз с последнего успешного сохранения — понижаем ранг.
	if (deathCount > 0)
	{
		local totalPenalty = 0;
		for (local i = 1; i <= deathCount; i++)
		{
			totalPenalty += min(550.0 * pow(1.2, i - 1), 1500.0).tointeger();
		}
		
		SW_DIFFICULTY_RANK = clamp(SW_DIFFICULTY_RANK - totalPenalty, -5000, 5000);
		printl("[DIFFICULTY] Loaded. Deaths: " + deathCount + ". Rank reduced by " + totalPenalty + " to " + SW_DIFFICULTY_RANK);
		
	}
	else
	{
		printl("[DIFFICULTY] Loaded. Rank: " + SW_DIFFICULTY_RANK + " (no deaths).");
	}
	
	// Это дерьмо в сохранении записано как один а после перехода на карту оно НУЛЁМ ЗАГРУЖАТЬСЯ НАЧАЛО ИЗ КАКОЙ-ТО ПИЗДЫ блять ну хуй с вами
	// раз пока транзишены есть, то через существующий глобал
	//if (Globals.GetCounter(Globals.GetIndex("MapgenTravels"))>SW_TRAVELS) SW_TRAVELS=Globals.GetCounter(Globals.GetIndex("MapgenTravels"));
	printl("TRAVELS IS "+SW_TRAVELS)	
	//тупое дерьмо блять. кто придумал делать вскрипты в мапбазе так что они нихуя нормально не работают с маптранзишенами.
	//у меня на карте блять стоит ложик авто с ONнMAPTRANSITION когда я ПО ТРИГГЕР ЧЕЙНДЖХУЮ перехожу на эту карту и ни один тз этих инпутов больше не работает
	// блять какая тупая хуйня я ебал. в следующий раз в пизду эти триггеры чейнжхуяки. всё дерьмо буду по файликам грузить хоть блять позицию игрока
	local i=0
	
	Entities.First().SetContextThink("ReUnlockSkills",function (...) {
		local i=0
		printl(SkillsInfo)
		for (local SkillID=0;SkillID<SKILLS_ORDER.len();SkillID++)
		{
			local Skill=SKILLS[SKILLS_ORDER[SkillID]]
			printl("Checking status of skill "+Skill.Name)
			if (SkillsInfo.slice(i,i+1)=="1") {
				//printl("Reunlocked "+Skill.Name);
				Skill.ForceUnlock();
			}
			i++
		}
	}.bindenv(this),0.12);
	
	foreach (Context in SW_CONTEXTS)
		Context.Load();
	foreach (Event in SW_EVENTS)
		Event.Load();
	
	ActiveWeapon<-Decode(Save.GetKeyString(Encode("active_weapon")))
	
	Weapons<-{}
	WeaponsData.SubKeysToTable(Weapons)
	Inventory<-{}
	InventoryData.SubKeysToTable(Inventory)
	ItemChest<-{}
	ItemChestData.SubKeysToTable(ItemChest)
	Equipment<-{}
	EquipmentData.SubKeysToTable(Equipment)
	
	local ply=Entities.FindByName(null,"stamina_system").GetOrCreatePrivateScriptScope()
	
	EntFire("stamina_system","RunScriptCode","SetPlayerXP("+XP+")",0.12)
	EntFire("stamina_system","RunScriptCode","PlayerSkillPoints="+SkillPoints,0.12)
	EntFire("stamina_system","RunScriptCode","AddPlayerMoney("+Money+" false)",0.12)
	
	player.SetHealth(Health)
	player.SetArmor(Armor)
	player.SetModel(Playermodel)
	if (Active_Mission) Hooks.Add( this, "OnClientInit", function(...)
	{
		SW_MISSIONS[Active_Mission].Restore()
	}.bindenv(this),"RestoreMissionData")
	
	
	Globals.SetCounter(Globals.GetIndex("MapgenTravels"),SW_TRAVELS)
	if (Entities.FindByName(null,"dialogue_manager")) Entities.FindByName(null,"dialogue_manager").AddContext("SW_TRAVELS",SW_TRAVELS.tostring(),0)
	
	if (GetLoadType()==2) 
	{
		Save=null
		WeaponsData=null
		return
	}
	
	
	foreach (k,v in Weapons)
	{
		/*
		k=Decode(k)
		local Weapon=SpawnEntityFromTable(k,{spawnflags=1})
		//player.EquipWeapon(Weapon)
		v=Decode(v)
		ply.GiveSilent(k,split(v," ")[0])
		player.SetAmmoCount(Weapon.GetPrimaryAmmoType(),split(v," ")[1].tointeger())
		player.SetAmmoCount(Weapon.GetSecondaryAmmoType(),split(v," ")[2].tointeger())
		Weapon.Destroy()
		*/
		NetMsg.Start("HideWeaponHistory");
		NetMsg.Send(player, true);
	}
	
	foreach (k,v in Inventory)
	{
		/*
		k=Decode(k)
		v=Decode(v)
		if (v.len()<5) continue;
		local itemname=split(v," ")[0]
		local itemcount=split(v," ")[1].tointeger()
		local itemclip=split(v," ")[2].tointeger()
		PlaceItem(itemname,k.tointeger(),itemcount,itemclip)
		*/
		//printl(v)
		if ((typeof v=="string")&&Decode(v)=="null") continue;
		
		if (Encode("ref") in v)
		{
			INVENTORY[Decode(k).tointeger()]=Decode(v[Encode("ref")]).tointeger()
		}
		else
		{
			//foreach (ke,va in v) printl(ke+" "+va)
			if (!("Durability" in v)) v.Durability<-(Encode(LIST_ITEMS[Decode(v.tech_name)].cost))
			//printl(Decode(k).tointeger())
			CreateItemInInventory(Decode(v.tech_name),
			{
				SizeX=Decode(v.SizeX).tointeger()
				SizeY=Decode(v.SizeY).tointeger()
				Rotated=Decode(v.Rotated)=="true"
				Count=Decode(v.count).tointeger()
				Clip=Decode(v.Clip).tointeger()
				Durability=Decode(v.Durability).tointeger()
				DropFlag=(Decode(v.DropFlag)=="true")
				WeaponInvID=((Decode(v.WeaponInvID)=="null") ? null : Decode(v.WeaponInvID).tointeger()),
				WeaponSlot=(Decode(v.WeaponSlot)=="null") ? null : Decode(v.WeaponSlot).tointeger(),
				//QuickUseSlot=((Decode(v.QuickUseSlot)=="null") ? null : Decode(v.QuickUseSlot).tointeger())
			},Decode(k).tointeger())
		}
	}
	
	foreach (k,v in ItemChest)
	{
		//printl(v)
		if ((typeof v=="string")&&Decode(v)=="null") continue;
		if ((typeof v=="integer")&&Decode(v)=="null") continue;
		if (!("tech_name" in v)) continue;
		
		if (!("Durability" in v)) v.Durability<-(Encode(LIST_ITEMS[Decode(v.tech_name)].cost))
		
		PlaceItem("ItemChest",Decode(v.tech_name),Decode(k).tointeger(),Decode(v.count).tointeger(),Decode(v.Clip).tointeger(),Decode(v.Durability).tointeger(),(Decode(v.Rotated)=="true") ? true : false)
		
	}
	
	
	if (Save.FindKey("COMPANIONS"))
	{
		SW_COMPANIONS=split(Save.GetKeyString("COMPANIONS")," ");
		foreach (i,v in SW_COMPANIONS)
		{
			//printl("UNDECODED "+v)
			//printl("DECODED "+Decode(v)
			
			if (v=="null") SW_COMPANIONS[i]=null;
			else SW_COMPANIONS[i]=v;
			
			
			if (SW_COMPANIONS[i]!=null)
			{
				if (SW_COMPANIONS[0]==SW_COMPANIONS[1]) SW_COMPANIONS[1]=null
				
				local i=i
				//printl("SPAWNING COMPANION "+SW_COMPANIONS[i])
				
				NetMsg.Start("InitCompanionOnClient")
				NetMsg.WriteString(SW_COMPANIONS[i])
				NetMsg.Send(player,true)
				
				Entities.First().SetContextThink("CompanionSpawner"+i,function (...) {InitCompanion(SW_COMPANIONS[i],false);NetMsg.Start("InitCompanionOnClient")
				NetMsg.WriteString(SW_COMPANIONS[i])
				NetMsg.Send(player,true)}.bindenv(this),0.25);
			}
		}
	}
	
	local WepSlots=split(Save.GetKeyString("WEAPON_SLOTS")," ")	
	local QuickUseSlots=split(Save.GetKeyString("QUICK_USE_SLOTS"), " ")
	
	Entities.First().SetContextThink("RegiveWeapons",function (...) {
		foreach (i,w in WepSlots)
		{
			WEAPON_SLOTS[i]=(w=="null") ? null : w.tointeger();
			if (w!="null") 
			{
				NetMsg.Start("WEAPON_SLOT_CHANGE_TO_CLIENT")
				NetMsg.WriteShort(i)
				NetMsg.WriteShort(w.tointeger())
				NetMsg.Send(player,true)
			}
		}
		
		/*
		foreach (i,w in QuickUseSlots)
		{
			QUICK_USE_SLOTS[i]=(w=="null") ? null : w.tointeger();
			if (w!="null") 
			{
				NetMsg.Start("QUICK_USE_SLOTS_CHANGE_TO_CLIENT")
				NetMsg.WriteShort(i)
				NetMsg.WriteShort(w.tointeger())
				NetMsg.Send(player,true)
			}
		}
		*/
		//aPlayer.ActiveWeaponSlot=Decode(Weapons[Encode("SW_Player_LastInv")]).tointeger()
		//aPlayer.ActiveWeaponSlot=Decode(Save.GetKeyString(Encode("ActiveWeaponSlot")))
		//SendToConsole("slot10")
		aPlayer.ActiveWeaponSlot=-1
		SendToConsole("slot"+(Decode(Weapons[Encode("SW_Player_LastInv")]).tointeger()).tostring())
		//printl("slot"+(Decode(Weapons[Encode("SW_Player_LastInv")]).tointeger()).tostring())
		
		foreach (k,v in Equipment)
		{
			if (v!=null) 
			{
				EQUIPMENT[Decode(k).tointeger()]=Item(Decode(v),1,1)
				NetMsg.Start("PlaceEquipmentOnClient")
				NetMsg.WriteShort(Decode(k).tointeger())
				NetMsg.WriteString(Decode(v))
				NetMsg.Send(player,true)
			}
		}
		
	}.bindenv(this),0.5)
	
	
	local MultiverseRaw={}
	MultiverseData.SubKeysToTable(MultiverseRaw)
	foreach (k,v in MultiverseRaw)
	{
		k=Decode(k)	//world id
		v=Decode(v)	//world status
		SW_MULTIVERSE.rawset(k,v.tointeger())
		//printl("SAVEDATA HAS WORLDINFO FOR "+k+" and it's "+v)
	}
	
	local WorldRaw={}
	WorldData.SubKeysToTable(WorldRaw)
	
	local StageID=Globals.GetCounter(Globals.GetIndex("StageID"))
	local StageCount=Globals.GetCounter(Globals.GetIndex("StageCount"))
	
	printl("Loading Mapgen Info:")
	foreach (k,v in WorldRaw)
	{
		local k=Decode(k)
		local v=Decode(v)
		SW_WORLD_INFO.rawset(k,v)
		Entities.First().SetContextThink("MAPGEN_INFO_DELAYED_SEND_"+k,function(...)
		{
			NetMsg.Start("SetMapgenInfoOnClient")
			NetMsg.WriteString(k)
			NetMsg.WriteString(v)
			NetMsg.Send(player,true)
			printl("sent to the player info that "+k+" is "+v)
			
		}.bindenv(this),0.5)
		printl(k+": "+v)
	}
	Entities.First().SetContextThink("MAPGEN_INFO_STAGES",function(...)
	{
		NetMsg.Start("SetStageInfoOnClient")
		NetMsg.WriteShort(StageID+1)
		NetMsg.WriteShort(StageCount)
		NetMsg.Send(player,true)
	}.bindenv(this),0.5)
	EntFire("stamina_system","RunScriptCodeQuotable","player.StopSound(''HL2Player.PickupWeapon'')",0.12)
	//EntFire("stamina_system","CallScriptFunctionClient","HideHistory",0.12)
	EntFireByHandle(player,"switchtoweapon",ActiveWeapon,0.12)
	EntFire("stamina_system","RunScriptCodeQuotable","player.StopSound(''HL2Player.PickupWeapon'')",0.15)
	EntFire("stamina_system","CallScriptFunctionClient","HideHistory",0.15)
	//EntFire("stamina_system","CallScriptFunctionClient","HideHistory",0.5)
	
	//Entities.FindByName(null,"stamina_system").GetOrCreatePrivateScriptScope().AddPlayerMoney(Money)
	printl("SAVED AND LOADED XP IS "+XP)
	
	if (Map!="demo_city"&&Map!=GetMapName()&&GetMapName()=="teleporting_room_v1")
	{
		player.SetOrigin(Vector(-1872,116,96))
		player.SetAngles(Vector(0,0,0))
		EntFire("return_back","trigger","",0)
		SW_AMBIENT="lines_in_the_sand"
		
		if (SkillPoints>0) Entities.First().SetContextThink("SPReminder",function (...) {SWHint("You have "+SkillPoints+" unspent skill points! Open skills menu with F4.")}.bindenv(this),5);
		
		SW_TRAVELS++
		Globals.SetCounter(Globals.GetIndex("MapgenTravels"),SW_TRAVELS)
		Entities.FindByName(null,"dialogue_manager").AddContext("SW_TRAVELS",SW_TRAVELS.tostring(),0)
		printf( "\t%s\n", "MapgenTravels "+SW_TRAVELS+"!" )

		player.EmitSound("k_lab.teleport_sound")
	}
	
	local city_to_lab_dif=Vector(725, 316, 348)-Vector(2981, -3504, -1612)
	
	if (Map=="demo_city"&&GetMapName()=="teleporting_room_v1")	//Works like a fuckin clock! Screw vanilla map transitions!
	{
		printl("LOADED FROM CITY TO LAB")
		
		SW_CompleteQuest("get_lab_keys")
		
		player.SetOrigin(PlayerOrigin+city_to_lab_dif)
		player.SetAngles(PlayerAngles)
		if (SW_TRAVELS<=0) SW_AMBIENT="domain"
		else
		{			
			SW_AMBIENT="lobby"
			EntFire("mine_soundscapes","RemoveOutput","OnPlay",0)
			EntFire("mine_soundscapes","AddOutput","OnPlay stamina_system:RunScriptCodeQuotable:SW_AMBIENT=''lobby'':0:-1",0.01)
		}
	}
	
	if (Map=="demo_city"&&GetMapName()=="demo_city")	//Works like a fuckin clock! Screw vanilla map transitions!
	{
		printl("LOADED FROM Somewhere to CITY")
		player.SetOrigin(PlayerOrigin)
		player.SetAngles(PlayerAngles)
		Entities.First().SetContextThink("RandomTip",function (...) {SWHint(GetRandomTip())}.bindenv(this),2);
		if (SkillPoints>0) Entities.First().SetContextThink("SPReminder",function (...) {SWHint("You have "+SkillPoints+" unspent skill points! Open skills menu with F4.")}.bindenv(this),5);
		
		if (PlayerOrigin.z<(-1000)) 
		{
			EntFire("door_elevator1small","close","",0);
			EntFire("door_elevator1","close","",0);
		}
		//SW_AMBIENT="lines_in_the_sand"
		if (SW_TRAVELS>0)
		{			
			EntFire("mine_soundscapes","RemoveOutput","OnPlay",0)
			EntFire("mine_soundscapes","AddOutput","OnPlay stamina_system:RunScriptCodeQuotable:SW_AMBIENT=''lobby'':0:-1",0.01)
		}
	}
	
	if (Map=="teleporting_room_v1"&&GetMapName()=="teleporting_room_v1")
	{
		printl("LOADED FROM Somewhere to LAB")
		player.SetOrigin(PlayerOrigin)
		player.SetAngles(PlayerAngles)
		Entities.First().SetContextThink("RandomTip",function (...) {SWHint(GetRandomTip())}.bindenv(this),2);
		if (SkillPoints>0) Entities.First().SetContextThink("SPReminder",function (...) {SWHint("You have "+SkillPoints+" unspent skill points! Open skills menu with F4.")}.bindenv(this),5);
		
		//SW_AMBIENT="lines_in_the_sand"
		if (SW_TRAVELS>0)
		{			
			EntFire("mine_soundscapes","RemoveOutput","OnPlay",0)
			EntFire("mine_soundscapes","AddOutput","OnPlay stamina_system:RunScriptCodeQuotable:SW_AMBIENT=''lobby'':0:-1",0.01)
		}
	}
	
	if (Map==GetMapName()&&GetMapName().find("mapgen")==null)
	{
		printl("LOADED FROM Somewhere to Somewhere")
		player.SetOrigin(PlayerOrigin)
		player.SetAngles(PlayerAngles)
		//Entities.First().SetContextThink("RandomTip",function (...) {SWHint(GetRandomTip())}.bindenv(this),2);
	}
	
	if (Map=="teleporting_room_v1"&&GetMapName()=="demo_city")
	{
		printl("LOADED FROM LAB TO CITY")
		player.SetOrigin(PlayerOrigin-city_to_lab_dif)
		player.SetAngles(PlayerAngles)
		EntFire("secret_door","open","",1.5)
		EntFire("door_elevator1small","close","",0);
		EntFire("door_elevator1","close","",0);
		if (SW_TRAVELS<=0) SW_AMBIENT="domain"
		else
		{			
			SW_AMBIENT="lobby"
			EntFire("mine_soundscapes","RemoveOutput","OnPlay",0)
			EntFire("mine_soundscapes","AddOutput","OnPlay stamina_system:RunScriptCodeQuotable:SW_AMBIENT=''lobby'':0:-1",0.01)
		}
	}
	
	/*
	if (GetMapName()=="teleporting_room_v1"&&SW_TRAVELS>=2&&(SW_CONTEXTS[1]!=1))
	{
		EntFire("changelevel_tocity","Disable","",0)
		EntFire("savebed","Lock","",0)
		EntFire("bomb_init","trigger","",3)
		EntFire("Richard","setlightingorigin","",3)
		EntFire("Richard","RemoveSpawnflags","16384",3)
		EntFire("mine_soundscapes","RemoveOutput","OnPlay",2)
		EntFire("lab_soundscapes","RemoveOutput","OnPlay",2)
		EntFire("chamber_door","open","",1)
		EntFire("portal_m1_trig","disable","",0)
		EntFire("m_trigger","disable","",0)
		printl("bomb event")
	}
	*/
	
	/*
	if (GetMapName()=="teleporting_room_v1"&&SW_TRAVELS>=4&&(SW_CONTEXTS[1]==1)&&(SW_CONTEXTS[3]!=1))
	{
		EntFire("changelevel_tocity","Disable","",0)
		EntFire("savebed","Lock","",0)
		EntFire("inv_init","trigger","",3)
		EntFire("Richard","setlightingorigin","",3)
		EntFire("Richard","RemoveSpawnflags","16384",3)
		EntFire("mine_soundscapes","RemoveOutput","OnPlay",2)
		EntFire("lab_soundscapes","RemoveOutput","OnPlay",2)
		EntFire("pc_seat","kill","",1)
		EntFire("chamber_door","open","",1)
		printl("invasion event")
	}
	*/
	
	/*
	if (GetMapName()=="teleporting_room_v1"&&(SW_CONTEXTS[1]==1)&&(SW_CONTEXTS[3]==1)&&SW_TRAVELS>=10&&(SW_CONTEXTS[5]==0))
	{
		EntFire("Richard","kill","",0.2)
		EntFire("pc_seat","kill","",0.2)
		EntFire("finale_init","trigger","",1.2)
		EntFire("Vlad","RemoveOutput","OnPlayerUse",0.2)
		EntFire("Vlad","RemoveOutput","OnPlayerUse*",0.2)
		EntFire("Vlad","RemoveSpawnflags","16384",1)
		printl("finale start event")
	}
	*/
		
	/*
	if (GetMapName()=="teleporting_room_v1"&&(SW_CONTEXTS[2]!=1))
	{
		EntFire("equipment_init","trigger","",2.0)
		printl("equipment spawn event")
		Entities.FindByName(null,"dialogue_manager").AddContext("equipment","1",0)
	}
	*/
	
	/*
	if (GetMapName()=="demo_city"&&(SW_CONTEXTS[0]==1))
	{
		EntFire("Richard","kill","",1.0)
		EntFire("Richard_g*","kill","",1.0)
		EntFire("Richard_r*","kill","",1.0)
	}
	*/
	
	/*
	if (GetMapName()=="demo_city"&&(SW_CONTEXTS[4]==1)&&(SW_CONTEXTS[5]==0))
	{
		EntFire("district_soundscapes","RemoveOutput","OnPlay",0.5)
		EntFire("club_soundscapes","RemoveOutput","OnPlay",0.5)
		EntFire("district_soundscapes","AddOutput","OnPlay stamina_system:RunScriptCodeQuotable:SW_AMBIENT=''district_unrest'':0:-1''",1)
		EntFire("stamina_system","RunScriptCodeQuotable","SWHint(''FIND RICHARD'')",3)
		EntFire("changelevel_tocity","Disable","",0)
		EntFire("changelevel_tocity","Disable","",0.5)
		EntFire("changelevel_tocity","Disable","",1)
		EntFire("changelevel_tocity","Disable","",0.25)
		EntFire("stamina_system","RunScriptCodeQuotable","player.RemoveAmmo(10,22)",3)	//NO BALLS
	}
	*/
	
	
	printf( "\t%s\n", "Save loaded! For playthrough "+PlayID+"!" )
	
	if (PlayID==(-1))
	{
		SW_RETRY_AVAILABLE=true
	}
	
	Save=null
	WeaponsData=null
	return
}

function GetWeps()
{
	local Weps={}
	player.GetAllWeapons(Weps)
	foreach (k,v in Weps)
	{
		local AmmoType=v.GetPrimaryAmmoType()
		local AmmoType2=v.GetSecondaryAmmoType()
		printl(k+" "+v.Clip1()+" "+player.GetAmmoCount(AmmoType)+" "+player.GetAmmoCount(AmmoType2))
	}
	Save<-CScriptKeyValues();
	Save.SetName( "SaveData" );
	PlayerData<-Save.FindOrCreateKey("PlayerData");
	PlayerData.SetKeyInt("health", player.GetHealth());
	local tab={}
	PlayerData.SubKeysToTable(tab)
	printl(tab.health)
}

function IsSaveEmpty(id=-1)
{
	PlayID<-id
	if (FileExists("saves/savedata_"+PlayID+".sav")&&(FileToString("saves/savedata_"+PlayID+".sav") == null))
	{
		return true
	}
	return false
}

function LoadPreviewData(id=-1)
{
	PlayID<-id
	if (FileExists("saves/savedata_"+PlayID+".sav") == false)
	{
		printf( "\t%s\n", "No savedata to preload for playthrough "+PlayID+"!" )
		return false
	}
	if (FileToString("saves/savedata_"+PlayID+".sav") == null)
	{
		printf( "\t%s\n", "Attempted to preload empty savedata for playthrough "+PlayID+"!" )
		return false
	}
	
	Save<-FileToKeyValues( "saves/savedata_"+PlayID+".sav" ).FindOrCreateKey("PlayerData");
	local SWData=FileToKeyValues( "saves/savedata_"+PlayID+".sav" ).FindOrCreateKey("SWData");
	Loaded=true
	local table={
	Health=Decode(Save.GetKeyString(Encode("health"))).tointeger()
	Armor=Decode(Save.GetKeyString(Encode("armor"))).tointeger()
	Playermodel=Decode(Save.GetKeyString(Encode("playermodel")))
	Origin=Decode(Save.GetKeyString("origin"))
	Map=Decode(Save.GetKeyString(Encode("map")))
	MapToLoad=Decode(Save.GetKeyString(Encode("map")))
	XP=Decode(Save.GetKeyString(Encode("exp"))).tofloat()
	Money=Decode(Save.GetKeyString(Encode("money"))).tofloat()
	SkillsInfo=Decode(Save.GetKeyString(Encode("plrskills")))
	ContextsInfo=Decode(Save.GetKeyString(Encode("contexts")))
	SkillPoints=Decode(Save.GetKeyString(Encode("sp"))).tointeger()
	Time=Save.GetKeyString("time")
	PlayTime=(SWData.GetKeyString("iPlayTime")=="") ? "11:50:14" : Decode(SWData.GetKeyString("iPlayTime"))
	Kills=Decode(SWData.GetKeyString("iPlayerKills"))
	}
	return table
}

if (CLIENT_DLL)
{
	IncludeScript("savemenu.nut")
	
	::DisplayExitConfirm<-function()
	{
		resX<-ScreenWidth()
		local OpenTime=clock()
		
		if ( c_panel && c_panel.IsValid() )
			return;
		
		c_panel = vgui.CreatePanel( "Panel", vgui.GetGameUIRootPanel(), "ConfirmPanel" );
		c_panel.MakeReadyForUse();
		//c_panel.SetPaintEnabled( false );
		c_panel.SetPaintBackgroundEnabled( true );
		c_panel.SetPaintBackgroundType( 2 );
		c_panel.SetPaintBorderEnabled( true );
		
		
		c_panel.SetBgColor( 6, 10, 20, 238 );
		c_panel.SetSize( XRES(140), YRES(80));
		c_panel.SetPos( XRES(320)-c_panel.GetWide()/2, YRES(240)-c_panel.GetTall()/2 );
		c_panel.SetMouseInputEnabled(true);
		
		// чтобы сделать рамочки как в вгуи мне, как дебилу, приходится использовать КНОПКИ пушто iframe забыть спросили и он не работает
		
		b_panel_bg <- vgui.CreatePanel( "Panel", c_panel, "ConfirmPanel2" );
		b_panel_bg.MakeReadyForUse();
		b_panel_bg.SetPos( XRES(2),YRES(12)+1  );
		b_panel_bg.SetSize(c_panel.GetWide()-XRES(4), c_panel.GetTall()-YRES(14));
		b_panel_bg.SetBgColor( 0,1,2,155 );
		b_panel <- vgui.CreatePanel( "Button", b_panel_bg, "ConfirmPanel3" );
		b_panel.MakeReadyForUse();
		b_panel.SetPaintEnabled( true );
		b_panel.SetPaintBackgroundEnabled( true );
		b_panel.SetPaintBackgroundType( 0 );
		b_panel.SetPaintBorderEnabled( true );
		b_panel.SetButtonActivationType(2);
		b_panel.SetPos( 1,1  );
		b_panel.SetFgColor( 255,3,6,255 );
		b_panel.SetSize( b_panel_bg.GetWide()-2, b_panel_bg.GetTall()-2);
		c_panel.SetAlpha(0)
		
		
		c_panel.AddTickSignal(10);
		c_panel.SetCallback("OnTick", function() {
			c_panel.SetAlpha(clamp((clock()-OpenTime)*255*4,0,255))
			if (resX == ScreenWidth()) {
				return
			}

			resX = ScreenWidth();
			printl("ResolutionChanged");
			c_panel.Destroy();
			c_panel = null;
			DisplayExitConfirm()
		}.bindenv(this));
		
		
		label <- (vgui.CreatePanel( "Label", c_panel, "ExampleLabel3" ));
		label.MakeReadyForUse();
		label.SetPaintEnabled( true );
		label.SetPaintBackgroundEnabled( false );
		label.SetFgColor( 5, 175, 255, 255 );
		label.SetPos( 0,YRES(5) );
		label.SetSize(c_panel.GetWide(),c_panel.GetTall())
		label.SetPaintBorderEnabled( true );
		label.SetContentAlignment( Alignment.north );
		//label.SetFont( surface.GetFont( "Trader", true ) );
		label.SetText( "CONFIRM EXIT" );
		label.SetFont( 21 );
		label.SetEnabled(true)
		label.SetVisible(true)
		
		slabel <- (vgui.CreatePanel( "Label", b_panel, "ExampleLabel4" ));
		slabel.MakeReadyForUse();
		slabel.SetFgColor( 5, 175, 255, 255 );
		slabel.SetPos( 0,0 );
		slabel.SetSize(b_panel.GetWide(), b_panel.GetTall()*0.5)
		slabel.SetContentAlignment( Alignment.center );
		slabel.SetText( "Are you sure you want to exit to main menu?" );
		slabel.SetFont( 19 );
		
		slabel2 <- (vgui.CreatePanel( "Label", b_panel, "ExampleLabel4" ));
		slabel2.MakeReadyForUse();
		slabel2.SetFgColor( 5, 175, 255, 255 );
		slabel2.SetPos( 0,surface.GetFontTall(19)+2 );
		slabel2.SetSize(b_panel.GetWide(), b_panel.GetTall()*0.5)
		slabel2.SetContentAlignment( Alignment.center );
		slabel2.SetText( "All unsaved progress will be lost" );
		slabel2.SetFont( 19 );
		
		c_panel.MakePopup();
		
		s_pClose <- vgui.CreatePanel( "Button", c_panel, "Close" );
		//s_pClose.SetVisible( true );
		//s_pClose.SetPaintEnabled( true );
		//s_pClose.SetPaintBackgroundEnabled( false );
		s_pClose.SetPos(c_panel.GetWide()-s_pClose.GetTall(),s_pClose.GetTall()/4)
		s_pClose.SetPaintBorderEnabled( false );
		s_pClose.SetFont( surface.GetFont( "Marlett", false, "Tracker" ) );
		s_pClose.SetText( "r" );
		s_pClose.SetTextInset( 1, 0 );
		s_pClose.SetContentAlignment( Alignment.northwest );
		s_pClose.SetCallback( "DoClick", HideConfirmPanels.bindenv(this) );
		
		
		s_pAction <- vgui.CreatePanel( "Button", c_panel, "CAction" );
		s_pAction.SetSize(YRES(32), YRES(16))
		s_pAction.SetPos(b_panel.GetWide()/4-s_pAction.GetWide()/2+b_panel_bg.GetXPos() b_panel.GetTall()-s_pAction.GetTall()*1.5+b_panel_bg.GetYPos())
		s_pAction.SetPaintEnabled( true );
		s_pAction.SetPaintBackgroundEnabled( true );
		s_pAction.SetPaintBackgroundType( 1 );
		s_pAction.SetPaintBorderEnabled( true );
		s_pAction.SetBgColor( 220,3,6,255 );
		s_pAction.SetDepressedSound("ui/buttonrollover.wav");
		s_pAction.SetDepressedColor(80,80,80,255,80,80,80,255);
		s_pAction.SetVisible(true)
		s_pAction.SetText( "YES" );
		s_pAction.SetTextInset( 1, 0 );
		s_pAction.SetContentAlignment( Alignment.center );
		local lastclick=Time()
		s_pAction.SetCallback( "DoClick", function(...) {NetMsg.Start("ExitToMainMenu"); NetMsg.Send()} );
		
		s_pAction2 <- vgui.CreatePanel( "Button", c_panel, "CAction2" );
		s_pAction2.SetSize(YRES(32), YRES(16))
		s_pAction2.SetPos(b_panel.GetWide()*0.75-s_pAction.GetWide()/2+b_panel_bg.GetXPos(), b_panel.GetTall()-s_pAction.GetTall()*1.5+b_panel_bg.GetYPos())
		s_pAction2.SetPaintEnabled( true );
		s_pAction2.SetPaintBackgroundEnabled( true );
		s_pAction2.SetPaintBackgroundType( 1 );
		s_pAction2.SetPaintBorderEnabled( true );
		s_pAction2.SetBgColor( 220,3,6,255 );
		s_pAction2.SetDepressedSound("ui/buttonrollover.wav");
		s_pAction2.SetDepressedColor(80,80,80,255,80,80,80,255);
		s_pAction2.SetVisible(true)
		s_pAction2.SetText( "NO" );
		s_pAction2.SetTextInset( 1, 0 );
		s_pAction2.SetContentAlignment( Alignment.center );
		s_pAction2.SetCallback( "DoClick", HideConfirmPanels.bindenv(this) );
		
	}
	
	::DisplayContinuePanels<-function()
	{
		resX<-ScreenWidth()
		local OpenTime=clock()
		
		if ( d_panel && d_panel.IsValid() )
			return;
		
		d_panel = vgui.CreatePanel( "Panel", vgui.GetRootPanel(), "ContinuePanel" );
		d_panel.MakeReadyForUse();
		//d_panel.SetPaintEnabled( false );
		d_panel.SetPaintBackgroundEnabled( true );
		d_panel.SetPaintBackgroundType( 2 );
		d_panel.SetPaintBorderEnabled( true );
		
		
		d_panel.SetBgColor( 6, 10, 20, 238 );
		d_panel.SetSize( XRES(140), YRES(50));
		d_panel.SetPos( XRES(320)-d_panel.GetWide()/2, YRES(240)-d_panel.GetTall()/2 );
		d_panel.SetMouseInputEnabled(true);
		
		// чтобы сделать рамочки как в вгуи мне, как дебилу, приходится использовать КНОПКИ пушто iframe забыть спросили и он не работает
		
		b_panel_bg <- vgui.CreatePanel( "Panel", d_panel, "ConfirmPanel2" );
		b_panel_bg.MakeReadyForUse();
		b_panel_bg.SetPos( XRES(2),YRES(12)+1  );
		b_panel_bg.SetSize(d_panel.GetWide()-XRES(4), d_panel.GetTall()-YRES(14));
		b_panel_bg.SetBgColor( 0,1,2,155 );
		b_panel <- vgui.CreatePanel( "Button", b_panel_bg, "ConfirmPanel3" );
		b_panel.MakeReadyForUse();
		b_panel.SetPaintEnabled( true );
		b_panel.SetPaintBackgroundEnabled( true );
		b_panel.SetPaintBackgroundType( 0 );
		b_panel.SetPaintBorderEnabled( true );
		b_panel.SetButtonActivationType(2);
		b_panel.SetPos( 1,1  );
		b_panel.SetFgColor( 255,3,6,255 );
		b_panel.SetSize( b_panel_bg.GetWide()-2, b_panel_bg.GetTall()-2);
		d_panel.SetAlpha(0)
		
		
		d_panel.AddTickSignal(10);
		d_panel.SetCallback("OnTick", function() {
			d_panel.SetAlpha(clamp((clock()-OpenTime)*255*4,0,255))
			if (resX == ScreenWidth()) {
				return
			}

			resX = ScreenWidth();
			printl("ResolutionChanged");
			d_panel.Destroy();
			d_panel = null;
			DisplayExitConfirm()
		}.bindenv(this));
		
		
		label <- (vgui.CreatePanel( "Label", d_panel, "ExampleLabel3" ));
		label.MakeReadyForUse();
		label.SetPaintEnabled( true );
		label.SetPaintBackgroundEnabled( false );
		label.SetFgColor( 5, 175, 255, 255 );
		label.SetPos( 0,YRES(5) );
		label.SetSize(d_panel.GetWide(),d_panel.GetTall())
		label.SetPaintBorderEnabled( true );
		label.SetContentAlignment( Alignment.north );
		//label.SetFont( surface.GetFont( "Trader", true ) );
		label.SetText( "Continue from..." );
		label.SetFont( 21 );
		label.SetEnabled(true)
		label.SetVisible(true)
		
		d_panel.MakePopup();
		
		
		s_pAction <- vgui.CreatePanel( "Button", d_panel, "CAction" );
		s_pAction.SetSize(YRES(64), YRES(16))
		s_pAction.SetPos(b_panel.GetWide()/4-s_pAction.GetWide()/2+b_panel_bg.GetXPos() b_panel.GetTall()-s_pAction.GetTall()*1.5+b_panel_bg.GetYPos())
		s_pAction.SetPaintEnabled( true );
		s_pAction.SetPaintBackgroundEnabled( true );
		s_pAction.SetPaintBackgroundType( 1 );
		s_pAction.SetPaintBorderEnabled( true );
		s_pAction.SetBgColor( 220,3,6,255 );
		s_pAction.SetDepressedSound("ui/buttonrollover.wav");
		s_pAction.SetDepressedColor(80,80,80,255,80,80,80,255);
		s_pAction.SetVisible(true)
		s_pAction.SetText( "Last Checkpoint" );
		s_pAction.SetTextInset( 1, 0 );
		s_pAction.SetContentAlignment( Alignment.center );
		local lastclick=Time()
		s_pAction.SetCallback( "DoClick", function(...) {NetMsg.Start("LoadCheckpoint");NetMsg.Send()} );
		
		s_pAction2 <- vgui.CreatePanel( "Button", d_panel, "CAction2" );
		s_pAction2.SetSize(YRES(64), YRES(16))
		s_pAction2.SetPos(b_panel.GetWide()*0.75-s_pAction.GetWide()/2+b_panel_bg.GetXPos(), b_panel.GetTall()-s_pAction.GetTall()*1.5+b_panel_bg.GetYPos())
		s_pAction2.SetPaintEnabled( true );
		s_pAction2.SetPaintBackgroundEnabled( true );
		s_pAction2.SetPaintBackgroundType( 1 );
		s_pAction2.SetPaintBorderEnabled( true );
		s_pAction2.SetBgColor( 220,3,6,255 );
		s_pAction2.SetDepressedSound("ui/buttonrollover.wav");
		s_pAction2.SetDepressedColor(80,80,80,255,80,80,80,255);
		s_pAction2.SetVisible(true)
		s_pAction2.SetText( "Previous Save" );
		s_pAction2.SetTextInset( 1, 0 );
		s_pAction2.SetContentAlignment( Alignment.center );
		s_pAction2.SetCallback( "DoClick", function(...) {HideContinuePanels();DisplayLoadPanels(false)}.bindenv(this) );
		
	}
	
	function HideContinuePanels()
	{
		local OpenTime=clock()
		if ( d_panel && d_panel.IsValid() )
		{
			d_panel.AddTickSignal(10);
			d_panel.SetCallback("OnTick", function() {
				d_panel.SetAlpha(clamp(255-(clock()-OpenTime)*255*5,0,255))
				if (clamp(255-(clock()-OpenTime)*255*5,0,255)<1)
				{
					d_panel.Destroy();
					d_panel = null;
				}
			}.bindenv(this));
		}
	}
	
	function HideConfirmPanels()
	{
		local OpenTime=clock()
		if ( c_panel && c_panel.IsValid() )
		{
			c_panel.AddTickSignal(10);
			c_panel.SetCallback("OnTick", function() {
				c_panel.SetAlpha(clamp(255-(clock()-OpenTime)*255*5,0,255))
				if (clamp(255-(clock()-OpenTime)*255*5,0,255)<1)
				{
					c_panel.Destroy();
					c_panel = null;
				}
			}.bindenv(this));
		}
	}
	
	
	::DisplayNewGamePanels<-function(DoTraining=false)
	{
		resX<-ScreenWidth()
		local OpenTime=clock()
		
		local TrainingPassed=FileExists("training_passed")
		
		if ( c_panel && c_panel.IsValid() )
			return;
		
		c_panel = vgui.CreatePanel( "Panel", vgui.GetGameUIRootPanel(), "ConfirmPanel" );
		c_panel.MakeReadyForUse();
		//c_panel.SetPaintEnabled( false );
		c_panel.SetPaintBackgroundEnabled( true );
		c_panel.SetPaintBackgroundType( 2 );
		c_panel.SetPaintBorderEnabled( true );
		
		
		c_panel.SetBgColor( 6, 10, 20, 238 );
		c_panel.SetSize( XRES(140), YRES(80));
		c_panel.SetPos( XRES(320)-c_panel.GetWide()/2, YRES(240)-c_panel.GetTall()/2 );
		c_panel.SetMouseInputEnabled(true);
		
		// чтобы сделать рамочки как в вгуи мне, как дебилу, приходится использовать КНОПКИ пушто iframe забыть спросили и он не работает
		
		b_panel_bg <- vgui.CreatePanel( "Panel", c_panel, "ConfirmPanel2" );
		b_panel_bg.MakeReadyForUse();
		b_panel_bg.SetPos( XRES(2),YRES(12)+1  );
		b_panel_bg.SetSize(c_panel.GetWide()-XRES(4), c_panel.GetTall()-YRES(14));
		b_panel_bg.SetBgColor( 0,1,2,155 );
		b_panel <- vgui.CreatePanel( "Button", b_panel_bg, "ConfirmPanel3" );
		b_panel.MakeReadyForUse();
		b_panel.SetPaintEnabled( true );
		b_panel.SetPaintBackgroundEnabled( true );
		b_panel.SetPaintBackgroundType( 0 );
		b_panel.SetPaintBorderEnabled( true );
		b_panel.SetButtonActivationType(2);
		b_panel.SetPos( 1,1  );
		b_panel.SetFgColor( 255,3,6,255 );
		b_panel.SetSize( b_panel_bg.GetWide()-2, b_panel_bg.GetTall()-2);
		c_panel.SetAlpha(0)
		
		
		c_panel.AddTickSignal(10);
		c_panel.SetCallback("OnTick", function() {
			c_panel.SetAlpha(clamp((clock()-OpenTime)*255*4,0,255))
			if (resX == ScreenWidth()) {
				return
			}

			resX = ScreenWidth();
			printl("ResolutionChanged");
			c_panel.Destroy();
			c_panel = null;
			DisplayExitConfirm()
		}.bindenv(this));
		
		
		label <- (vgui.CreatePanel( "Label", c_panel, "ExampleLabel3" ));
		label.MakeReadyForUse();
		label.SetPaintEnabled( true );
		label.SetPaintBackgroundEnabled( false );
		label.SetFgColor( 5, 175, 255, 255 );
		label.SetPos( 0,YRES(5) );
		label.SetSize(c_panel.GetWide(),c_panel.GetTall())
		label.SetPaintBorderEnabled( true );
		label.SetContentAlignment( Alignment.north );
		//label.SetFont( surface.GetFont( "Trader", true ) );
		label.SetText( "START NEW GAME" );
		if (DoTraining) label.SetText( "START TRAINING LEVEL" );
		label.SetFont( 21 );
		label.SetEnabled(true)
		label.SetVisible(true)
		
		slabel <- (vgui.CreatePanel( "Label", b_panel, "ExampleLabel4" ));
		slabel.MakeReadyForUse();
		slabel.SetFgColor( 5, 175, 255, 255 );
		slabel.SetPos( 0,0 );
		slabel.SetSize(b_panel.GetWide(), b_panel.GetTall()*0.5)
		slabel.SetContentAlignment( Alignment.center );
		slabel.SetText( "Start new game?" );
		if (DoTraining) slabel.SetText( "Start Training level to learn the basics?" );
		if (!DoTraining&&!TrainingPassed) slabel.SetText( "Start the Training level first, to learn the basics?" );
		slabel.SetFont( 19 );
		
		slabel2 <- (vgui.CreatePanel( "Label", b_panel, "ExampleLabel4" ));
		slabel2.MakeReadyForUse();
		slabel2.SetFgColor( 5, 175, 255, 255 );
		slabel2.SetPos( 0,surface.GetFontTall(19)+2 );
		slabel2.SetSize(b_panel.GetWide(), b_panel.GetTall()*0.5)
		slabel2.SetContentAlignment( Alignment.center );
		slabel2.SetText( "" );
		if (!DoTraining&&!TrainingPassed) slabel2.SetText( "Press NO, if you wish to start new game immediately." );
		slabel2.SetFont( 19 );
		
		c_panel.MakePopup();
		
		s_pClose <- vgui.CreatePanel( "Button", c_panel, "Close" );
		//s_pClose.SetVisible( true );
		//s_pClose.SetPaintEnabled( true );
		//s_pClose.SetPaintBackgroundEnabled( false );
		s_pClose.SetPos(c_panel.GetWide()-s_pClose.GetTall(),s_pClose.GetTall()/4)
		s_pClose.SetPaintBorderEnabled( false );
		s_pClose.SetFont( surface.GetFont( "Marlett", false, "Tracker" ) );
		s_pClose.SetText( "r" );
		s_pClose.SetTextInset( 1, 0 );
		s_pClose.SetContentAlignment( Alignment.northwest );
		s_pClose.SetCallback( "DoClick", HideNewGamePanels.bindenv(this) );
		
		
		s_pAction <- vgui.CreatePanel( "Button", c_panel, "CAction" );
		s_pAction.SetSize(YRES(32), YRES(16))
		s_pAction.SetPos(b_panel.GetWide()/4-s_pAction.GetWide()/2+b_panel_bg.GetXPos() b_panel.GetTall()-s_pAction.GetTall()*1.5+b_panel_bg.GetYPos())
		s_pAction.SetPaintEnabled( true );
		s_pAction.SetPaintBackgroundEnabled( true );
		s_pAction.SetPaintBackgroundType( 1 );
		s_pAction.SetPaintBorderEnabled( true );
		s_pAction.SetBgColor( 220,3,6,255 );
		s_pAction.SetDepressedSound("ui/buttonrollover.wav");
		s_pAction.SetDepressedColor(80,80,80,255,80,80,80,255);
		s_pAction.SetVisible(true)
		s_pAction.SetText( "YES" );
		s_pAction.SetTextInset( 1, 0 );
		s_pAction.SetContentAlignment( Alignment.center );
		local lastclick=Time()
		if (!DoTraining&&TrainingPassed) s_pAction.SetCallback( "DoClick", function(...) {NetMsg.Start("StartNewGame"); NetMsg.Send()} );
		else s_pAction.SetCallback( "DoClick", function(...) {NetMsg.Start("StartTraining"); NetMsg.Send()} );
		s_pAction2 <- vgui.CreatePanel( "Button", c_panel, "CAction2" );
		s_pAction2.SetSize(YRES(32), YRES(16))
		s_pAction2.SetPos(b_panel.GetWide()*0.75-s_pAction.GetWide()/2+b_panel_bg.GetXPos(), b_panel.GetTall()-s_pAction.GetTall()*1.5+b_panel_bg.GetYPos())
		s_pAction2.SetPaintEnabled( true );
		s_pAction2.SetPaintBackgroundEnabled( true );
		s_pAction2.SetPaintBackgroundType( 1 );
		s_pAction2.SetPaintBorderEnabled( true );
		s_pAction2.SetBgColor( 220,3,6,255 );
		s_pAction2.SetDepressedSound("ui/buttonrollover.wav");
		s_pAction2.SetDepressedColor(80,80,80,255,80,80,80,255);
		s_pAction2.SetVisible(true)
		s_pAction2.SetText( "NO" );
		s_pAction2.SetTextInset( 1, 0 );
		s_pAction2.SetContentAlignment( Alignment.center );
		if (!DoTraining&&!TrainingPassed) s_pAction2.SetCallback( "DoClick", function(...) {NetMsg.Start("StartNewGame"); NetMsg.Send()} );
		else s_pAction2.SetCallback( "DoClick", HideNewGamePanels.bindenv(this) );
		
	}
	
	::DisplayTrainingPanels<-function() {DisplayNewGamePanels(true)};
	
	function HideNewGamePanels()
	{
		local OpenTime=clock()
		if ( c_panel && c_panel.IsValid() )
		{
			c_panel.AddTickSignal(10);
			c_panel.SetCallback("OnTick", function() {
				c_panel.SetAlpha(clamp(255-(clock()-OpenTime)*255*5,0,255))
				if (clamp(255-(clock()-OpenTime)*255*5,0,255)<1)
				{
					c_panel.Destroy();
					c_panel = null;
				}
			}.bindenv(this));
		}
	}
	
	
	
	
	
	
	
	
	
	::DisplayOptions<-function()
	{
		resX<-ScreenWidth()
		local OpenTime=clock()
		
		if ( o_panel && o_panel.IsValid() )
			return;
		
		o_panel = vgui.CreatePanel( "Panel", vgui.GetGameUIRootPanel(), "AdvOptionsPanel" );
		o_panel.MakeReadyForUse();
		//o_panel.SetPaintEnabled( false );
		o_panel.SetPaintBackgroundEnabled( true );
		o_panel.SetPaintBackgroundType( 2 );
		o_panel.SetPaintBorderEnabled( true );
		
		
		o_panel.SetBgColor( 6, 10, 20, 253 );
		o_panel.SetSize( XRES(240), YRES(300));
		o_panel.SetPos( XRES(320)-o_panel.GetWide()/2, YRES(240)-o_panel.GetTall()/2 );
		o_panel.SetMouseInputEnabled(true);
		
		// чтобы сделать рамочки как в вгуи мне, как дебилу, приходится использовать КНОПКИ пушто iframe забыть спросили и он не работает
		
		b_panel_bg <- vgui.CreatePanel( "Panel", o_panel, "ConfirmPanel2" );
		b_panel_bg.MakeReadyForUse();
		b_panel_bg.SetPos( XRES(4),YRES(12)+1  );
		b_panel_bg.SetSize(o_panel.GetWide()-XRES(8), o_panel.GetTall()-YRES(40));
		b_panel_bg.SetBgColor( 0,1,2,155 );
		b_panel <- vgui.CreatePanel( "Button", b_panel_bg, "ConfirmPanel3" );
		b_panel.MakeReadyForUse();
		b_panel.SetPaintEnabled( true );
		b_panel.SetPaintBackgroundEnabled( true );
		b_panel.SetPaintBackgroundType( 0 );
		b_panel.SetPaintBorderEnabled( true );
		b_panel.SetButtonActivationType(2);
		b_panel.SetPos( 1,1  );
		b_panel.SetFgColor( 255,3,6,255 );
		b_panel.SetSize( b_panel_bg.GetWide()-2, b_panel_bg.GetTall()-2);
		o_panel.SetAlpha(0)
		
		
		o_panel.AddTickSignal(10);
		o_panel.SetCallback("OnTick", function() {
			o_panel.SetAlpha(clamp((clock()-OpenTime)*255*4,0,255))
			if (resX == ScreenWidth()) {
				return
			}

			resX = ScreenWidth();
			printl("ResolutionChanged");
			o_panel.Destroy();
			o_panel = null;
			DisplayOptions()
		}.bindenv(this));
		
		
		label <- (vgui.CreatePanel( "Label", o_panel, "ExampleLabel3" ));
		label.MakeReadyForUse();
		label.SetPaintEnabled( true );
		label.SetPaintBackgroundEnabled( false );
		label.SetFgColor( 5, 175, 255, 255 );
		label.SetPos( YRES(8),YRES(5) );
		label.SetSize(o_panel.GetWide(),o_panel.GetTall())
		label.SetPaintBorderEnabled( true );
		label.SetContentAlignment( Alignment.northwest );
		//label.SetFont( surface.GetFont( "Trader", true ) );
		label.SetText( "ADVANCED OPTIONS" );
		label.SetFont( 21 );
		label.SetEnabled(true)
		label.SetVisible(true)
		
		//slabel <- (vgui.CreatePanel( "Label", b_panel, "ExampleLabel4" ));
		//slabel.MakeReadyForUse();
		//slabel.SetFgColor( 5, 175, 255, 255 );
		//slabel.SetPos( 0,0 );
		//slabel.SetSize(b_panel.GetWide(), b_panel.GetTall()*0.5)
		//slabel.SetContentAlignment( Alignment.center );
		//slabel.SetText( "Are you sure you want to exit to main menu?" );
		//slabel.SetFont( 19 );
		//
		//slabel2 <- (vgui.CreatePanel( "Label", b_panel, "ExampleLabel4" ));
		//slabel2.MakeReadyForUse();
		//slabel2.SetFgColor( 5, 175, 255, 255 );
		//slabel2.SetPos( 0,surface.GetFontTall(19)+2 );
		//slabel2.SetSize(b_panel.GetWide(), b_panel.GetTall()*0.5)
		//slabel2.SetContentAlignment( Alignment.center );
		//slabel2.SetText( "All unsaved progress will be lost" );
		//slabel2.SetFont( 19 );
		
		o_panel.MakePopup();
		
		s_pClose <- vgui.CreatePanel( "Button", o_panel, "Close" );
		//s_pClose.SetVisible( true );
		//s_pClose.SetPaintEnabled( true );
		//s_pClose.SetPaintBackgroundEnabled( false );
		s_pClose.SetPos(o_panel.GetWide()-s_pClose.GetTall(),s_pClose.GetTall()/4)
		s_pClose.SetPaintBorderEnabled( false );
		s_pClose.SetFont( surface.GetFont( "Marlett", false, "Tracker" ) );
		s_pClose.SetText( "r" );
		s_pClose.SetTextInset( 1, 0 );
		s_pClose.SetContentAlignment( Alignment.northwest );
		s_pClose.SetCallback( "DoClick", HideOptionsPanels.bindenv(this) );
		
		
		function PaintCheck()
		{
			if (!s_pCheck||!s_pCheck.IsValid()) return;
			surface.DrawColoredText(surface.GetFont( "Marlett", false, "Tracker" ),0,0,25,25,25,255,"c")
			surface.DrawColoredText(surface.GetFont( "Marlett", false, "Tracker" ),0,0,25,185,255,255,"d")
			if (Convars.GetInt("sourceworld_hud")==0) surface.DrawColoredText(surface.GetFont( "Marlett", false, "Tracker" ),0,0,25,185,255,255,"a");
			surface.DrawColoredText(19,YRES(16),0,25,185,255,255,"Enable HUD")
			s_pCheck.SetSize(YRES(24)+surface.GetTextWidth(19,"Enable HUD"),s_pCheck.GetTall())
		}
		function CheckToggle()
		{
			Convars.SetInt("sourceworld_hud",(Convars.GetInt("sourceworld_hud")==0) ? 2 : 0)
			surface.PlaySound("common/menu3.wav")
		}
		
		s_pCheck <- vgui.CreatePanel( "Button", o_panel, "Check" );
		//sCheckse.SetVisible( true );
		//sCheckse.SetPaintEnabled( true );
		//sCheckse.SetPaintBackgroundEnabled( false );
		s_pCheck.SetPos(o_panel.GetWide()/12,o_panel.GetTall()/10)
		s_pCheck.SetPaintBorderEnabled( false );
		//s_pCheck.SetFont( surface.GetFont( "Marlett", false, "Tracker" ) );
		//s_pCheck.SetText( "abcdefghijklmnopstu" );
		//s_pCheck.SetTextInset( 1, 0 );
		s_pCheck.SetContentAlignment( Alignment.northwest );
		s_pCheck.SetCallback( "DoClick", CheckToggle.bindenv(this) );
		s_pCheck.SetCallback( "Paint", PaintCheck.bindenv(this) );
		
		function PaintColor()
		{
			if (!s_pColor||!s_pColor.IsValid()) return;
			surface.DrawColoredText(surface.GetFont( "Marlett", false, "Tracker" ),0,0,25,25,25,255,"c")
			surface.DrawColoredText(surface.GetFont( "Marlett", false, "Tracker" ),0,0,25,25,25,255,"d")
			switch (Convars.GetInt("sw_terminal_danger_color")) 
			{
				case 0: surface.DrawColoredText(surface.GetFont( "Marlett", false, "Tracker" ),0,0,255,0,0,255,"g");break
				case 1: surface.DrawColoredText(surface.GetFont( "Marlett", false, "Tracker" ),0,0,0,190,255,255,"g");break
				case 2: surface.DrawColoredText(surface.GetFont( "Marlett", false, "Tracker" ),0,0,255,100,255,255,"g");break
				case 3: surface.DrawColoredText(surface.GetFont( "Marlett", false, "Tracker" ),0,0,255,255,255,255,"g");break
			}
			surface.DrawColoredText(19,YRES(16),0,25,185,255,255,"Terminal Danger Color")
			s_pColor.SetSize(YRES(24)+surface.GetTextWidth(19,"Terminal Danger Color"),s_pColor.GetTall())
		}
		function ColorToggle()
		{
			Convars.SetInt("sw_terminal_danger_color",(Convars.GetInt("sw_terminal_danger_color")==3) ? 0 : Convars.GetInt("sw_terminal_danger_color")+1)
			surface.PlaySound("common/menu3.wav")
		}
		
		s_pColor <- vgui.CreatePanel( "Button", o_panel, "Color" );
		//sColorse.SetVisible( true );
		//sColorse.SetPaintEnabled( true );
		//sColorse.SetPaintBackgroundEnabled( false );
		s_pColor.SetPos(o_panel.GetWide()/12,o_panel.GetTall()/10*2)
		s_pColor.SetPaintBorderEnabled( false );
		//s_pColor.SetFont( surface.GetFont( "Marlett", false, "Tracker" ) );
		//s_pColor.SetText( "abcdefghijklmnopstu" );
		//s_pColor.SetTextInset( 1, 0 );
		s_pColor.SetContentAlignment( Alignment.northwest );
		s_pColor.SetCallback( "DoClick", ColorToggle.bindenv(this) );
		s_pColor.SetCallback( "Paint", PaintColor.bindenv(this) );
		
		
		
		s_pAction <- vgui.CreatePanel( "Button", o_panel, "CAction" );
		s_pAction.SetSize(YRES(30), YRES(14))
		s_pAction.SetPos(b_panel.GetWide()*0.8-s_pAction.GetWide()/2+b_panel_bg.GetXPos(), b_panel.GetTall()+s_pAction.GetTall()*0.7+b_panel_bg.GetYPos())
		s_pAction.SetPaintEnabled( true );
		s_pAction.SetPaintBackgroundEnabled( true );
		s_pAction.SetPaintBackgroundType( 1 );
		s_pAction.SetPaintBorderEnabled( true );
		s_pAction.SetBgColor( 220,3,6,255 );
		s_pAction.SetDepressedSound("ui/buttonrollover.wav");
		s_pAction.SetDepressedColor(80,80,80,255,80,80,80,255);
		s_pAction.SetVisible(true)
		s_pAction.SetText( "OK" );
		s_pAction.SetTextInset( 1, 0 );
		s_pAction.SetContentAlignment( Alignment.center );
		local lastclick=Time()
		//s_pAction.SetCallback( "DoClick", function(...) {NetMsg.Start("ExitToMainMenu"); NetMsg.Send()} );
		s_pAction.SetCallback( "DoClick", HideOptionsPanels.bindenv(this) );
		
		s_pAction2 <- vgui.CreatePanel( "Button", o_panel, "CAction2" );
		s_pAction2.SetSize(YRES(30), YRES(14))
		s_pAction2.SetPos(b_panel.GetWide()*0.95-s_pAction.GetWide()/2+b_panel_bg.GetXPos(), b_panel.GetTall()+s_pAction.GetTall()*0.7+b_panel_bg.GetYPos())
		s_pAction2.SetPaintEnabled( true );
		s_pAction2.SetPaintBackgroundEnabled( true );
		s_pAction2.SetPaintBackgroundType( 1 );
		s_pAction2.SetPaintBorderEnabled( true );
		s_pAction2.SetBgColor( 220,3,6,255 );
		s_pAction2.SetDepressedSound("ui/buttonrollover.wav");
		s_pAction2.SetDepressedColor(80,80,80,255,80,80,80,255);
		s_pAction2.SetVisible(true)
		s_pAction2.SetText( "CLOSE" );
		s_pAction2.SetTextInset( 1, 0 );
		s_pAction2.SetContentAlignment( Alignment.center );
		s_pAction2.SetCallback( "DoClick", HideOptionsPanels.bindenv(this) );
		
	}
	
	function HideOptionsPanels()
	{
		local OpenTime=clock()
		if ( o_panel && o_panel.IsValid() )
		{
			o_panel.AddTickSignal(10);
			o_panel.SetCallback("OnTick", function() {
				o_panel.SetAlpha(clamp(255-(clock()-OpenTime)*255*5,0,255))
				if (clamp(255-(clock()-OpenTime)*255*5,0,255)<1)
				{
					o_panel.Destroy();
					o_panel = null;
				}
			}.bindenv(this));
		}
		StringToFile("user_settings","sw_terminal_danger_color "+Convars.GetInt("sw_terminal_danger_color"))
	}
	
	NetMsg.Receive("InitCompanionOnClient", function( )
	{
		local name=NetMsg.ReadString()
		
		SW_COMPANIONS[SW_COMPANIONS.find(null)]=name;
	}.bindenv(this) );		
	
	NetMsg.Receive("SetMapgenInfoOnClient", function()
	{
		local k=NetMsg.ReadString()
		local v=NetMsg.ReadString()
		printl("we read that "+k+" is "+v)
		SW_WORLD_INFO.rawset(k,v)
		printl(k+": "+v)
	}.bindenv(this))
	
	NetMsg.Receive("SW_TableToClient", function()
	{
		local k=NetMsg.ReadString()
		local v=NetMsg.ReadString()
		
		switch(k.slice(0,1))
		{
			case "i": v=v.tointeger();break;
			case "f": v=v.tofloat();break;
			case "s": break;
		}
		
		SW_TABLE.rawset(k,v)
	}.bindenv(this))
	
	NetMsg.Receive("SW_MailToClient", function()
	{
		local MailName = NetMsg.ReadString()
		local MailStatus = NetMsg.ReadShort()
		local MailWDay = NetMsg.ReadShort()
		local MailDay = NetMsg.ReadShort()
		local MailYear = NetMsg.ReadShort()
		local MailMonth = NetMsg.ReadShort()
		local MailHour = NetMsg.ReadShort()
		local MailMin = NetMsg.ReadShort()
		local MailSec = NetMsg.ReadShort()
		
		printl("received mail "+MailName)
		printl("status "+MailStatus)
		
		SW_MAILS[MailName].DateReceived={
			wday=MailWDay,
			day=MailDay,
			year=MailYear,
			month=MailMonth,
			hour=MailHour,
			min=MailMin
			sec=MailSec
		}
		SW_MAILS[MailName].Restore(MailStatus)
	}.bindenv(this))
	
	NetMsg.Receive("SetStageInfoOnClient", function()
	{
		::SW_MAPGEN_STAGE_CURRENT<-NetMsg.ReadShort()
		::SW_MAPGEN_STAGE_COUNT<-NetMsg.ReadShort()
	}.bindenv(this))
}

if (SERVER_DLL)
{
	Convars.RegisterConvar( "sw_terminal_danger_color" "0", "0 - red, 1 - cyan, 2 - pink, 3 - white", FCVAR_ARCHIVE )
	
	::SW_RETRY_AVAILABLE<-false;

	NetMsg.Receive("Load_a_save", function( player )
	{
		local slot=NetMsg.ReadShort()
		printl("loading save "+slot)
		PlayIDGlobal<-Globals.AddGlobal("PlaythroughID",GetMapName(),1);
		Globals.SetCounter(PlayIDGlobal,slot)
		
		// Загрузка сейва из лобби — сбрасываем счётчик смертей.
		// Ранг будет загружен из файла в LoadData.
		SW_SetDeathCount(0);
		printl("[DIFFICULTY] Save loaded from slot " + slot + ". Death count reset.");
		
		Save<-FileToKeyValues( "saves/savedata_"+slot+".sav" ).FindOrCreateKey("PlayerData");
		MapToLoad=Decode(Save.GetKeyString(Encode("map")))
		
		SendToConsole("changelevel "+MapToLoad);
	}.bindenv(this))
	NetMsg.Receive("Save_a_game", function( player )
	{
		local slot=NetMsg.ReadShort()
		printl("saving in slot "+slot)
		Globals.SetCounter(Globals.GetIndex("PlaythroughID"),slot)
		SaveData()
		//ShowMessage("GAMESAVED")
		
		SendToConsole("play ui/beep_synthtone01.wav");
		Globals.SetCounter(Globals.GetIndex("PlaythroughID"),-1)
		SW_RETRY_AVAILABLE=false;
	}.bindenv(this))
	
	NetMsg.Receive("ExitToMainMenu", function( player )
	{
		SendToConsole("map_background background");
	}.bindenv(this))
	
	NetMsg.Receive("LoadCheckpoint", function( player )
	{
		if (!SW_RETRY_AVAILABLE)
		{
			SendToConsole("play buttons/button10");
			return
		}
		
		// CONTINUE — игрок умер. Увеличиваем счётчик в Globals.
		// Понижение ранка произойдёт при следующей загрузке карты (в LoadData).
		SW_IncrementDeathCount();
		printl("[DIFFICULTY] CONTINUE pressed. Death count: " + SW_GetDeathCount());
		
		Globals.SetCounter(Globals.GetIndex("RNGSeed"),Globals.GetCounter(Globals.GetIndex("InitialRNGSeed")))
		SendToConsole("changelevel "+GetMapName());
	}.bindenv(this))
	
	NetMsg.Receive("StartNewGame", function( player )
	{
		SendToConsole("map demo_city");
	}.bindenv(this))
	
	NetMsg.Receive("StartTraining", function( player )
	{
		SendToConsole("map tutorial");
	}.bindenv(this))
	
	
	function ChangeLevelToCity()
	{
		SendToConsole("changelevel demo_city");
	}
	
	function ChangeLevelToLab()
	{
		SendToConsole("changelevel teleporting_room_v1");
	}
}