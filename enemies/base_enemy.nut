IncludeScript("lists/list_enemies.nut")
IncludeScript("lists/list_weapons.nut")

MoneyLoot<-(0)

function ClassnameToEnemyType(classname)
{
	switch (classname)
	{
		case "npc_zombie": return "ZOMBIE_CLASSIC";
		case "npc_fastzombie": return "ZOMBIE_FAST";
		case "npc_poisonzombie": return "ZOMBIE_POISON";
		case "npc_headcrab": return "HEADCRAB";
		case "npc_headcrab_fast": return "HEADCRAB_FAST";
		case "npc_manhack": return "MANHACK";
		case "npc_metropolice": return "METROCOP_BATON";
		case "npc_combine_s": return "COMBINE_SMG";
		default: return 0;
	}
}

function IsVanillaWeapon(classname)
{
	switch (classname)
	{
		case "weapon_stunstick": return true;
		case "weapon_crowbar": return true;
		case "weapon_pistol": return true;
		case "weapon_357": return true;
		case "weapon_smg1": return true;
		case "weapon_shotgun": return true;
		case "weapon_ar2": return true;
		case "weapon_crossbow": return true;
		case "weapon_rpg": return true;
		default: return false;
	}
}

function OnPostSpawn()
{
	if (!("EnemyName" in this))
	{
		local ctxName = self.GetContext("EnemyName");
		if (ctxName != null && ctxName != "")
			EnemyName <- ctxName;
		else
			EnemyName <- ClassnameToEnemyType(self.GetClassname());
	}
	
	MoneyLoot<-LIST_ENEMIES[EnemyName].cost/5;
	//printl("my loot is "+MoneyLoot)
	
	if ("maxhealth" in LIST_ENEMIES[EnemyName]) self.SetMaxHealth(LIST_ENEMIES[EnemyName].maxhealth)
	if ("health" in LIST_ENEMIES[EnemyName]) self.SetHealth(LIST_ENEMIES[EnemyName].health)
	
	if (self.GetBoundingMins().z<0)	// This fixes the engine's stupid bug where npc's hull might get lifted 6 units upwards, causing pathfinding to break. This can be caused by custom models, but i have no idea how exactly.
	{
		self.SetSize(Vector(-13,-13,0),Vector(13,13,72))
	}
	
	if ("OnHalfHealth" in LIST_ENEMIES[EnemyName]&&self.IsAlive())
	{
		this.OnHalfHealth<-LIST_ENEMIES[EnemyName].OnHalfHealth.bindenv(this)
		self.ConnectOutput( "OnHalfHealth", "OnHalfHealth" )
	}
	if ("OnDamaged" in LIST_ENEMIES[EnemyName]&&self.IsAlive())
	{
		this.OnDamaged<-LIST_ENEMIES[EnemyName].OnDamaged.bindenv(this)
		self.ConnectOutput( "OnDamaged", "OnDamaged" )
	}
	
	if ("Include" in LIST_ENEMIES[EnemyName]&&self.IsAlive())
	{
		IncludeScript(LIST_ENEMIES[EnemyName].Include)
	}
	
	if ("AltFootsteps" in LIST_ENEMIES[EnemyName]&&self.IsAlive())
	{
		NetMsg.Start("CHANGE_FOOTSTEPS")
		NetMsg.WriteEntity(self)
		NetMsg.Send(player,true);
		
		Entities.First().SetContextThink("FOOTSTEPS_"+self.entindex(),function(...){
			NetMsg.Start("CHANGE_FOOTSTEPS")
			NetMsg.WriteEntity(self)
			NetMsg.Send(player,true);
			if (!self) return;
			if (!self.IsAlive()) return;
			if (self.IsEntVisible(player)) return;
			
			return 3
		}.bindenv(this),3)
	}
	
	
	if ("additionalequipment" in LIST_ENEMIES[EnemyName]&&(!IsVanillaWeapon(LIST_ENEMIES[EnemyName].additionalequipment))) 
	{	
		printl(LIST_ENEMIES[EnemyName].additionalequipment)
		EnemyWeapon<-LIST_ENEMIES[EnemyName].additionalequipment
		
		local weaponclassname=((LIST_ITEMS[EnemyWeapon].holdtype=="AR2") ? "weapon_smg1" : "weapon_"+LIST_ITEMS[EnemyWeapon].holdtype)
		
		self.AcceptInput("giveweapon", weaponclassname,self,self)
		EntFireByHandle(self.GetActiveWeapon(),"setrendermode", 6,0.1)
		
		local weaponmodel=null;
		
		local wmodel=LIST_ITEMS[EnemyWeapon].model	
		if (!weaponmodel)
		{
			weaponmodel=SpawnEntityFromTable("prop_dynamic_ornament",{model=wmodel})
			EnemyWeaponEnt<-weaponmodel
			
			if (self.GetName().len()<=1)
			{
				// Make dummy name for our enemy so that weapon model can be parented. Unless enemy already has name
				local i=0
				local tempname="Enemy_"+i
				
				while (Entities.FindByName(null,tempname))
				{
					i++
					tempname="Enemy_"+i
				}
				
				self.SetName(tempname)
			}
			
			weaponmodel.SetName(self.GetName()+"_wepmodel")
			weaponmodel.AcceptInput("setattached",self.GetName(),self,self)
			EntFireByHandle(weaponmodel,"DisableShadow","")
		}
		if (weaponmodel&&weaponmodel.GetModelName()!=wmodel) {weaponmodel.SetModel(wmodel);};
		
		self.GetActiveWeapon().SetClip1(LIST_WEAPONS[EnemyWeapon].clip)
		
		
		local orig=self.GetOrigin()+Vector(0,0,48)
		local ang=self.GetAngles()
		local vel=Vector(RandomInt(-60,60),RandomInt(-60,60),RandomInt(-60,60))
		
		self.AddSpawnFlags(8192);
		self.GetOrCreatePrivateScriptScope().DropCustomWeapon<-function()
		{
			printl("Dropping custom weapon: "+EnemyWeapon)
			
			orig=self.GetOrigin()+Vector(0,0,48)
		    ang=self.GetAngles()
		    vel=Vector(RandomInt(-40,40),RandomInt(-40,40),RandomInt(-40,40))
			local rep=
			{
				model=wmodel
				origin=orig.x+" "+orig.y+" "+orig.z
				angles=ang.x+" "+ang.y+" "+ang.z
				vscripts="items/item.nut"
				ResponseContext="item:"+EnemyWeapon+",count:1,clip:"+this.clip+",dur:"+RandomFloat(0.02,0.15)
			}
			
			local replacement=SpawnEntityFromTable("prop_physics",rep)
			replacement.SetVelocity(vel)
		}
		
	}
	


}

function OnDeath()
{
	// apparently this gets called two times. 
	// First before the npc actually dies, and second after the death. on first iteration there's no activator. hence there's this alive check.
	if (self.IsValid()&&self.IsAlive()) return
	
	
	Entities.FindByName(null,"stamina_system").GetOrCreatePrivateScriptScope().AddPlayerMoney(MoneyLoot)
	Entities.FindByName(null,"stamina_system").GetOrCreatePrivateScriptScope().AddPlayerXP(MoneyLoot/5)
	//printl(EnemyName+" killed by "+activator+" and dropped "+MoneyLoot+"$")
	if (activator==player)
	{
		Convars.SetInt("%PlayerKills",Convars.GetInt("%PlayerKills")+1)
	}
}

local speedmod=null
local GagFlag=self.HasSpawnFlags(2)

local IsEnabled=false
local FirstClientSound=false
// set speedmod. and probably also set thinking to null(unless angry)

function CheckObstruction()
{
	if (GetMapName().find("mapgens")==null) return;
	if (!self||!self.IsValid()||!self.IsAlive()) return;
	
	local lastEnable=IsEnabled
	foreach (i,hull in Hulls)
	{
		//if (!(i.tostring() in PVSStatus)) PVSStatus.rawset(i.tostring(),null);
		//printl(PVSStatus.len())
		if (PVSStatus.len()==0) break;
		
		if (VisibleSet.find(i)==null)
		{
			// INVISIBLE
			//DrawHull(hull,55,55,55,0);
			
			//EntFire(i+"_*","addeffects",32)
			//printl(PVSStatus[i.tostring()])
			if (IsOriginInBBox(self.GetCenter(),hull[0],hull[1])) {IsEnabled=false;break}
		}
		else
		{
			if (IsOriginInBBox(self.GetCenter(),hull[0],hull[1])) {IsEnabled=true;break}
		}
	}
	
	if (lastEnable!=IsEnabled||!FirstClientSound)
	{
		NetMsg.Start("EMITSOUND_CL")
		NetMsg.WriteEntity(self)
		printl("sending "+IsEnabled)
		NetMsg.WriteBool(IsEnabled);
		NetMsg.Send(player,true);
		FirstClientSound=true
	}
}

function StartTask()
{
	if (task=="TASK_FACE_REASONABLE") return false;	//fix broken piece of shit that makes them turn to 0 degrees
	else return true
}

function QueryHearSound()
{
	return true
	
	if (sound.GetOwner()!=player) return false;
	if (GetMapName().find("mapgen")==null) return true;
	
	
	CheckObstruction()
	EntFireByHandle(self,"CallScriptFunction","CheckObstruction")
	if (!IsEnabled)
	{
		return false
	}
	else
	{
		return true
	}
}

function QuerySeeEntity()
{
	return true
	
	if (GetMapName().find("mapgen")==null) return true;
	
	
	if (!IsEnabled&&entity==player)
	{
		return false
	}
	else
	{
		return true
	}
}

EntFireByHandle(self,"CallScriptFunction","CheckObstruction",1)
function SetNPCEnabled(enabled)
{
	

	if (!enabled)
	{
		speedmod=self.GetKeyValue("BaseSpeedModifier")
		self.AcceptInput("setspeedmodifier","0",self,self)
		IsEnabled=false;
		self.SetRenderColor(0,0,255)
		self.AddSpawnFlags(2)
	}
	if (enabled)
	{
		if (speedmod) self.AcceptInput("setspeedmodifier",speedmod.tostring(),self,self);
		IsEnabled=true;
		self.SetRenderColor(255,255,255)
		if (GagFlag) self.RemoveSpawnFlags(2)
	}
}

self.ConnectOutput( "OnDeath", "OnDeath" )

if (Convars.GetClientConvarValue(1,"%PlayerKills")=="")
{
	Convars.RegisterConvar( "%PlayerKills", "0", "", FCVAR_NONE )
}

local sound1set=false
local sound2set=false

local bladesound=UniqueString("BladeSound")
local enginesound=UniqueString("EngineSound1")

function OnHearPlayer()
{
	if (!sound1set&&self.GetClassname()=="npc_manhack")
	{
		Entities.First().SetContextThink(bladesound,function(...){self.StopSound("NPC_Manhack.BladeSound");self.EmitSound("NPC_Manhack.BladeSound");return 1}.bindenv(this),1.7)
		sound1set=true
	}
	if (!sound2set&&self.GetClassname()=="npc_manhack")
	{
		Entities.First().SetContextThink(enginesound,function(...){self.StopSound("NPC_Manhack.EngineSound1");self.EmitSound("NPC_Manhack.EngineSound1");return 1}.bindenv(this),1.7)
		sound2set=true
	}
}
self.ConnectOutput( "OnHearPlayer", "OnHearPlayer" )

function ModifyEmitSoundParams()
{
	if (EnemyName.tostring()!="0"&&("sound_modify" in LIST_ENEMIES[EnemyName])&&self.IsAlive())
	{
		local newparams=LIST_ENEMIES[EnemyName].sound_modify(self,params)
		params=newparams
	}
	
	if (GetMapName().find("mapgens")==null) return true;
	CheckObstruction()
	//for (local i=1;i<6;i++) EntFireByHandle(self,"CallScriptFunction","CheckObstruction",i)
	EntFireByHandle(self,"CallScriptFunction","CheckObstruction")
	if (!IsEnabled) 
	{
		params.SetSpecialDSP(55)
		//params.SetFlags(32)
	}
	//else if (self.GetClassname()=="npc_manhack") self.EmitSound("NPC_Manhack.BladeSound")
	
	//if (params.GetSoundName()!="NPC_Manhack.EngineSound1"&&self.GetClassname()=="npc_manhack") {self.StopSound("NPC_Manhack.EngineSound1");self.EmitSound("NPC_Manhack.EngineSound1")}
}

function ModifySentenceParams()
{
	if (GetMapName().find("mapgens")==null) return true;

	CheckObstruction()
	//for (local i=1;i<6;i++) EntFireByHandle(self,"CallScriptFunction","CheckObstruction",i)
	EntFireByHandle(self,"CallScriptFunction","CheckObstruction")

	if (!IsEnabled) 
	{
		params.SetSpecialDSP(55)
		params.SetFlags(32)
	}
}