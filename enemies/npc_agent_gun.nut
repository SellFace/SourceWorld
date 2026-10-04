IncludeScript("enemies/base_enemy.nut")
IncludeScript("enemies/ai_grenade.nut")
IncludeScript("enemies/corruptor_base.nut")
local disabled=false;

self.PrecacheSoundScript("Corruptor.Spotted")
self.PrecacheSoundScript("npc/corruptor/agent_alert1.wav")
self.PrecacheSoundScript("npc/corruptor/agent_alert2.wav")
self.PrecacheSoundScript("npc/corruptor/agent_alert3.wav")
self.PrecacheSoundScript("npc/corruptor/agent_alert4.wav")
self.PrecacheSoundScript("npc/corruptor/agent_alert5.wav")
self.PrecacheSoundScript("npc/corruptor/agent_alert6.wav")
self.PrecacheSoundScript("npc/corruptor/agent_alert7.wav")
self.PrecacheSoundScript("npc/corruptor/agent_alert8.wav")
self.PrecacheSoundScript("npc/corruptor/agent_alert9.wav")

self.PrecacheSoundScript("npc/corruptor/agent_chase1.wav")
self.PrecacheSoundScript("npc/corruptor/agent_chase2.wav")
self.PrecacheSoundScript("npc/corruptor/agent_chase3.wav")
self.PrecacheSoundScript("npc/corruptor/agent_chase4.wav")
self.PrecacheSoundScript("npc/corruptor/agent_chase5.wav")
self.PrecacheSoundScript("npc/corruptor/agent_chase6.wav")
self.PrecacheSoundScript("npc/corruptor/agent_chase7.wav")
self.PrecacheSoundScript("npc/corruptor/agent_chase8.wav")

self.PrecacheSoundScript("npc/corruptor/agent_idle1.wav")
self.PrecacheSoundScript("npc/corruptor/agent_idle2.wav")
self.PrecacheSoundScript("npc/corruptor/agent_idle3.wav")
self.PrecacheSoundScript("npc/corruptor/agent_idle4.wav")
self.PrecacheSoundScript("npc/corruptor/agent_idle5.wav")
self.PrecacheSoundScript("npc/corruptor/agent_idle6.wav")
self.PrecacheSoundScript("npc/corruptor/agent_idle7.wav")
self.PrecacheSoundScript("npc/corruptor/agent_idle8.wav")

local eyedir=self.EyeDirection3D()

clip<-(18);
lastclip<-(0)

local LastShot=0;

local PrevDir=0

local lastanim=0;

function NPC_TranslateSchedule()
{
	if (GetNamedEnt("PlayerModel")) return schedule;
	
	if (self.GetEnemy()&&((self.GetEnemy().GetOrigin()-self.GetOrigin()).Length()<60)&&(schedule!="SCHED_MELEE_ATTACK1"))
	{
		printl("CHASING")
		//self.ClearSchedule("")
		self.SetSchedule("SCHED_MELEE_ATTACK1")
		//printl("attacking!"+self.GetActivity())
		//self.SetSchedule("SCHED_MELEE_ATTACK1")
		
		return "SCHED_MELEE_ATTACK1"
		//self.SetActivity("ACT_MELEE_ATTACK1")
	}
	
	if (self.GetEnemy()&&((self.GetEnemy().GetOrigin()-self.GetOrigin()).Length()<60)&&(schedule=="SCHED_MELEE_ATTACK1"))
	{
		printl("KILL")
		self.ClearSchedule("")
		//self.SetSchedule("SCHED_ZOMBIE_MELEE_ATTACK1")
		//printl("attacking!"+self.GetActivity())
		//self.SetSchedule("SCHED_MELEE_ATTACK1")
		
		return -1
		//self.SetActivity("ACT_MELEE_ATTACK1")
	}
}

local LastPrimaryAttack=0

function NPC_TranslateActivity()
{
	if (activity=="ACT_RANGE_ATTACK1")
	{
		return -1
	}
	
	if (activity=="ACT_RANGE_ATTACK_PISTOL"&&(Time()-LastPrimaryAttack)<=1)
	{
		self.AddGestureSequence("Idle_Pistol_Aim_Relaxed",true)
		return -1
	}
	else self.RemoveAllGestures()
	printl(activity)
	//if (activity=="ACT_IDLE_ANGRY") return "ACT_IDLE_AIM_PISTOL_RELAXED"
	if (activity=="ACT_IDLE_ANGRY_PISTOL") 
	{
		//self.SetActivity("ACT_IDLE")
		self.SetSequence(self.LookupSequence("Idle_Pistol_Aim_Relaxed"))
		//activity="ACT_IDLE"
		//return "ACT_IDLE_AIM_PISTOL_RELAXED"
	}
	
	if ((Time()-LastPrimaryAttack)<=1)
	{
		self.ResetSequenceInfo()
		self.SetSequence(self.LookupSequence("Idle_Pistol_Aim_Relaxed"))
	}
	
	if (activity=="ACT_RANGE_ATTACK_PISTOL"&&(Time()-LastPrimaryAttack)>1)
	{
		self.ResetSequenceInfo()
		self.SetSequence(self.LookupSequence("Idle_Pistol_Aim_Relaxed"))
		self.AddGestureSequence("gesture_shoot_357",true)
		NetProps.SetPropFloat(self,"m_flNextAttack",Time()+1)
		LastPrimaryAttack=Time()
		return "ACT_IDLE_ANGRY_PISTOL"
	}
	
	if (activity=="ACT_RANGE_ATTACK_PISTOL"&&(Time()-LastPrimaryAttack)<=1&&self.GetSequence()!=self.LookupSequence("Idle_Pistol_Aim_Relaxed"))
	{
		self.SetSequence(self.LookupSequence("Idle_Pistol_Aim_Relaxed"))
		activity="ACT_IDLE_ANGRY_PISTOL"
	}
	
	if (GetNamedEnt("PlayerModel")) return activity;
	
	//if (Time()<lastanim) return -1;
	
	if (activity=="ACT_VM_DRAW") return -1;
	if (self.GetActivity()=="ACT_VM_DRAW") return -1;
	
	if (self.GetActivity()=="ACT_RUN") self.SetSequence(self.LookupSequence("run_all_panicked"));
	if (self.GetActivity()=="ACT_RUN") return self.LookupSequence("run_all_panicked")
		
	if (activity=="ACT_METROPOLICE_DRAW_PISTOL") return "ACT_IDLE";
	if (activity=="ACT_FLINCH_PHYSICS") return "ACT_GESTURE_FLINCH_HEAD";
		
	if (activity=="ACT_MELEE_ATTACK1"&&self.GetActivity()!="ACT_SPECIAL_ATTACK1") 
	{
		//self.SetActivity("ACT_RESET")
		//if (Time()>lastanim) self.ResetSequenceInfo()
		//self.SetSequence(self.LookupSequence("agent_punch1"));
		//self.SetActivity("ACT_SPECIAL_ATTACK1")
		//self.SetSequence(self.LookupSequence("agent_punch1"))
		//self.SetContextThink("DelayedAnim",function(_) {self.SetSequence(self.LookupSequence("agent_punch1"));}.bindenv(this),0);
		self.SetPlaybackRate(0.7)
		//if (self.GetSequence()!=self.LookupSequence("agent_punch1")) self.SetContextThink("DelayedAnim2",function(_) {self.SetSequence(self.LookupSequence("agent_punch1"));}.bindenv(this),0);
		//if (self.GetSequence()!=self.LookupSequence("agent_punch1")) self.SetContextThink("DelayedAnim2",function(_) {self.SetSequence(self.LookupSequence("agent_punch1"));}.bindenv(this),0.01);
		//lastanim=Time()+0.2
		return "ACT_SPECIAL_ATTACK1"
	}
	//if (self.GetActivity()=="ACT_MELEE_ATTACK1") return self.LookupSequence("agent_punch1")
	return activity
}

/*
function StartTask()
{
	printl(task)
	if (task=="TASK_GET_CHASE_PATH_TO_ENEMY")
	{
		printl("CHASE START")
		printl(task_data)
		
		self.FindEnemyMemory(self.GetEnemy()).SetLastKnownLocation(Vector(50,0,10))
		self.FindEnemyMemory(self.GetEnemy()).SetLastSeenLocation(Vector(50,0,10))
		NetProps.SetPropVector(self,"m_vecStoredPathGoal",player.GetOrigin()+player.GetForwardVector()*100)
		
		self.ChainStartTask("TASK_GET_PATH_TO_ENEMY_LKP_LOS", 300)
		return false
	}
	return true
}

function RunTask()
{
	printl(task)
	if (task=="TASK_GET_CHASE_PATH_TO_ENEMY")
	{
		printl("CHASING")
		
		self.FindEnemyMemory(self.GetEnemy()).SetLastKnownLocation(Vector(50,0,10))
		self.FindEnemyMemory(self.GetEnemy()).SetLastSeenLocation(Vector(50,0,10))
		NetProps.SetPropVector(self,"m_vecStoredPathGoal",player.GetOrigin()+player.GetForwardVector()*100)
		
		self.ChainRunTask("TASK_GET_PATH_TO_ENEMY_LKP_LOS", 300)
		printl(self.GetEnemyLKP())
		
		return false
	}
	return true
}
*/

local LastEnemyPos=0;

::CORRUPTOR_AGENT_LASTSAY<-Time()
::CORRUPTOR_AGENT_LASTSAY_TYPE<-""

local FoundOnce=0;

function Think()
{
	if (GetNamedEnt("PlayerModel")) return;
	
	//printl(self.FindEnemyMemory(self.GetEnemy()))
	//self.FindEnemyMemory(self.GetEnemy()).SetLastKnownLocation(self.GetEnemy().GetOrigin()+Vector(200,0,0))
	//self.FindEnemyMemory(self.GetEnemy()).SetLastSeenLocation(self.GetEnemy().GetOrigin()+Vector(200,0,0))
	//NetProps.SetPropVector(self,"m_vecLastPosition",player.GetOrigin()+player.GetForwardVector()*100)
	//NetProps.SetPropVector(self,"m_vecStoredPathGoal",player.GetOrigin()+player.GetForwardVector()*100)
	
	//if (self.GetEnemy()) self.UpdateEnemyMemory(self.GetEnemy(),self.GetEnemy().GetOrigin()+Vector(200,0,0),null)
	
	if (self.GetEnemy()&&((self.GetEnemy().GetOrigin()-self.GetOrigin()).Length()<60)&&(self.GetSchedule()!="SCHED_MELEE_ATTACK1"))
	{
		//printl("KILL")
		//self.SetSchedule("SCHED_ZOMBIE_MELEE_ATTACK1")
		//printl("attacking!"+self.GetActivity())
		self.SetSchedule("SCHED_MELEE_ATTACK1")
		//self.SetActivity("ACT_MELEE_ATTACK1")
	}
	
	if (self.GetEnemy()&&((self.GetEnemy().GetOrigin()-self.GetOrigin()).Length()<60)&&RandomInt(1,2)==1)
	{
		self.SetAngles(Vector(0,VectorAngles(self.GetEnemy().GetCenter()-self.GetCenter()).y,0))
	}
	
	if (self.GetEnemy())
	{
		if (Time()-CORRUPTOR_AGENT_LASTSAY>3&&(Time()-FoundOnce)>3) 
		{
			self.GetExpresser().SpeakRawSentence("AGENT_CHASE",1)
			CORRUPTOR_AGENT_LASTSAY=Time()+RandomFloat(3,15)
			CORRUPTOR_AGENT_LASTSAY_TYPE="CHASE"
		}
	}
	else
	{
		if (Time()-CORRUPTOR_AGENT_LASTSAY>3||CORRUPTOR_AGENT_LASTSAY_TYPE!="IDLE") 
		{
			self.GetExpresser().SpeakRawSentence("AGENT_IDLE",1)
			CORRUPTOR_AGENT_LASTSAY=Time()+RandomFloat(3,25)
			CORRUPTOR_AGENT_LASTSAY_TYPE="IDLE"
		}
	}
	
	if (self.GetEnemy()&&((self.GetEnemy().GetOrigin()-self.GetOrigin()).Length()>80)&&(self.GetSchedule()=="SCHED_MELEE_ATTACK1")&&self.GetActivity()!="ACT_SPECIAL_ATTACK1")
		self.ClearSchedule("");
	
	if ("extra_think" in LIST_ENEMIES[EnemyName]&&self.IsAlive())
	{
		LIST_ENEMIES[EnemyName].extra_think(self)
	}
	
	if (self.GetSchedule()=="SCHED_TAKE_COVER_FROM_ENEMY") self.SetSchedule("SCHED_METROPOLICE_CHASE_ENEMY");

	
	eyedir=eyedir+(self.EyeDirection3D()-eyedir)/2
	
	//debugoverlay.Line(self.ShootPosition(), self.ShootPosition()+self.EyeDirection3D()*170, 155, 5, 5, true, 0.12)
	//debugoverlay.Line(self.ShootPosition(), self.ShootPosition()+eyedir*170, 255, 255, 25, true, 0.12)
	
	if (self.GetActiveWeapon()&&("EnemyWeapon" in this)&&lastclip<self.GetActiveWeapon().Clip1())
	{
		local weapon_info=LIST_WEAPONS[EnemyWeapon]
		
		self.GetActiveWeapon().SetClip1(weapon_info.clip)
	}
	
	if (self.GetActiveWeapon()&&("EnemyWeapon" in this)&&lastclip>(self.GetActiveWeapon().Clip1()+1))
	{
		local weapon_info=LIST_WEAPONS[EnemyWeapon]
		
		self.GetActiveWeapon().SetClip1(self.GetActiveWeapon().Clip1()+1)
	}
	
	
	if (self.GetActiveWeapon()) lastclip=self.GetActiveWeapon().Clip1()
		
	if (self.GetActiveWeapon()) clip=self.GetActiveWeapon().Clip1()
		
	//printl("meow "+self.GetActiveWeapon().Clip1())
	
	if (GetMapName().find("mapgen")==null) return 0.11
	
	if (self.GetSchedule()=="SCHED_IDLE_STAND"&&(self.entindex()%4)==0) self.SetSchedule("SCHED_IDLE_WANDER")
	
	if ((player.GetOrigin()-self.GetOrigin()).Length()>1000&&!disabled&&GetMapName().find("mapgens")!=null) {EntFireByHandle(self,"setthinknull");disabled=true}
	if ((player.GetOrigin()-self.GetOrigin()).Length()<=1000&&disabled&&GetMapName().find("mapgens")!=null) {EntFireByHandle(self,"setthinknpc");disabled=false}
	
	if (Time()-Time().tointeger()>0.8) EntFireByHandle(self,"CallScriptFunction","CheckObstruction",0);
	
    return 0.11;
}

PrecacheParticleSystem("muzzle_mg42")

local muzzlelight = {
	_cone = 0,
	_inner_cone = 0,
	_light = "249 205 67 2200",
	brightness = 2,
	distance = 100
	pitch = -90,
	//spawnflags = 1,
	style=0
}

local LastAltFire=Time()+3;

self.PrecacheSoundScript("Flesh.ImpactHard")
self.PrecacheSoundScript("PlayerPunch")

function HandleAttack(event)
{
	if (LastShot>Time()) 
	{
		//self.ResetSequenceInfo()
		//self.SetSequence(self.LookupSequence("Idle_Pistol_Aim_Relaxed"))
		return false;
	}
	
	if (event.GetEvent()==3&&((self.GetEnemy().GetOrigin()-self.GetOrigin()).Length()<60))
	{
		local Damage=CreateDamageInfo(self,self,self.GetForwardVector()*100,self.GetForwardVector()*100,10,DMG_CLUB)
		Damage.SetDamageType(DMG_CLUB)
		Damage.SetAttacker(self)
		Entities.FindByName(null,"SW_DMG").PassesFinalDamageFilter(self.GetEnemy(),Damage)
		self.GetEnemy().TakeDamage(Damage)
		
		local punch=Vector()
		if (self.GetSequence()==self.LookupSequence("agent_punch1")) punch=Vector(RandomFloat(-10,10),-45,15)
		if (self.GetSequence()==self.LookupSequence("agent_punch2")) punch=Vector(RandomFloat(-10,10),45,-15)
		if (self.GetSequence()==self.LookupSequence("agent_punch3")) punch=Vector(-50,RandomFloat(-5,5),RandomFloat(-20,20))
			
		punch=punch*0.5
		
		if (self.GetEnemy()==player) self.GetEnemy().ViewPunch(punch)
		if (self.GetEnemy()==player) self.SetContextThink("AttackViewPunch",function(_){self.GetEnemy().ViewPunch(punch*0.6)}.bindenv(this),0.15)
		if (self.GetEnemy()==player) self.SetContextThink("AttackViewPunch2",function(_){self.GetEnemy().ViewPunch(punch*0.3)}.bindenv(this),0.3)
		self.EmitSound(self.GetSequence()==self.LookupSequence("agent_punch3") ? "Flesh.ImpactHard" : "PlayerPunch")
	}
	
	printl(event.GetEvent())
	printl(event.GetEvent())
	printl(event.GetEvent())
	if (event.GetEvent()==3002||event.GetEvent()==3004||event.GetEvent()==3014)
	{
		
		local attach=self.GetActiveWeapon().LookupAttachment("muzzle")
		local muzzle=self.GetActiveWeapon().GetAttachmentOrigin(attach)
		
		NetMsg.Start("BigBullet")
		NetMsg.WriteVec3Coord(muzzle)
		NetMsg.Send(player,true)
	}
	
	
	if (!("EnemyWeapon" in this)) return true;
	
	local weapon_info=LIST_WEAPONS[EnemyWeapon]
	
	
	self.PrecacheSoundScript(weapon_info.shootsound)
	
	//printl(event.GetEvent())
	//printl(event.GetEvent())
	//printl(event.GetEvent())
	//printl(event.GetType())
	//printl(event.GetEventTime())
	
	if ((Time()-LastAltFire)>10&&self.GetEnemy()&&self.GetKeyValue("NumGrenades").tointeger()>0)
	{
		self.SetNPCTarget(self.GetEnemy())
		self.SetSchedule("SCHED_COMBINE_AR2_ALTFIRE")
		self.SetNPCTarget(self.GetEnemy())
		LastAltFire=Time()
		NetProps.SetPropVector(self,"m_vecAltFireTarget",self.GetEnemyLKP()+Vector(0,0,20))

	}
	
	if (event.GetEvent()==50) {
		
		
		local VecToss=VecCheckToss( self, self.ShootPosition()+self.GetForwardVector()*28, self.GetEnemyLKP()+Vector(0,0,self.GetEnemy().GetBoundingMaxs().z/2), 0.1, 0.66, Vector(-4,-4,-4), Vector(4,4,4) );
		
		if (VecToss==false)
		{
			local Nades=self.GetKeyValue("NumGrenades").tointeger()
		
			EntFireByHandle(self,"setgrenades",0,0)
			EntFireByHandle(self,"setgrenades",Nades-1,2)
			
			LastAltFire=Time()+5
			
			return false
		}
		
		self.PrecacheSoundScript("Weapon_M16A2_M203.Launcher")
		
		local GrenadeTable=
		{
			origin=(self.ShootPosition()+self.GetForwardVector()*28).ToKVString()
			angles=(self.EyeAngles()).ToKVString()
			modelscale=2
		}
		local Grenade=SpawnEntityFromTable("grenade_ar2",GrenadeTable)
		
		local TrailTable=
		{
			origin=(self.ShootPosition()+self.GetForwardVector()*28).ToKVString()
			angles=(self.EyeAngles()).ToKVString()
			lifetime=0.5
			startwidth=3
			endwidth=0.1
			spritename="sprites/smoke.vmt"
			rendermode=5
			rendercolor="95 90 40"
		}
		Grenade.AcceptInput("SetDamage","80",null,null)
		Grenade.AcceptInput("AddOutput","radius 250",null,null)
		Grenade.SetOwner(player)
		
		local GrenadeLight = SpawnEntityFromTable("light_dynamic", muzzlelight)
		
		local Trail=SpawnEntityFromTable("env_spritetrail",TrailTable)
		Trail.FollowEntity(Grenade,false)
		GrenadeLight.FollowEntity(Grenade,false)
		GrenadeLight.SetLocalOrigin(Vector(10,0,4))
		Grenade.EmitSound("Weapon_M16A2_M203.Launcher")
		Grenade.EmitSound("Weapon_M16A2_M203.Launcher")
		Grenade.EmitSound("Weapon_M16A2_M203.Launcher")
		Grenade.EmitSound("Weapon_M16A2_M203.Launcher")
		Grenade.EmitSound("Weapon_M16A2_M203.Launcher")
		self.EmitSound("Weapon_M16A2_M203.Launcher")
		self.GetActiveWeapon().EmitSound("Weapon_M16A2_M203.Launcher")
		
		//Grenade.GetPhysicsObject().ApplyForceCenter((player.GetEyeForward()*1000+player.GetEyeUp()*170)*Grenade.GetPhysicsObject().GetMass())
		
		
		
		local dir=(self.GetEnemyLKP()-self.GetOrigin()).Normalized()
		local dist=(self.GetEnemyLKP()-self.GetOrigin()).Length()
		
		local angle=RemapValClamped(dist,400,1000,0,0.25)
		
		local x=600*cos(PI*angle)
		local y=600*sin(PI*angle)
		
		printl("DISTANCE "+dist)
		printl("ANGLE "+(angle*180))
		
		//Grenade.SetVelocity(dir*x+Vector(0,0,1)*y)
		Grenade.SetVelocity(VecToss)
		
		Grenade.SetAngles(VectorAngles(dir*x+Vector(0,0,1)*y))
		
		Grenade.SetAngularVelocity(60,0,0)
		
		local Nades=self.GetKeyValue("NumGrenades").tointeger()
		
		EntFireByHandle(self,"setgrenades",0,0)
		EntFireByHandle(self,"setgrenades",Nades-1,2)
		
		return false
	}
	
	
	
	if (event.GetEvent()==3002||event.GetEvent()==3004||event.GetEvent()==3014) {
		
	LastShot=Time()+1
	
		
	Entities.First().SetContextThink("DelayedSound",function(_) {self.GetActiveWeapon().EmitSound(weapon_info.shootsound)}.bindenv(this),0.01);
	local info = CreateFireBulletsInfo(1, self.ShootPosition(), (eyedir+(self.GetEnemy().GetCenter()-self.ShootPosition()).Normalized())*0.5, weapon_info.spread, 1, self)
	info.SetTracerFreq(1)
	info.SetAttacker(self)
	//self.EmitSound("Weapon_357.Single")
	info.SetAmmoType(1)
	info.SetDamage(weapon_info.damage)
	info.SetDamageForceScale(1)
	info.SetShots(weapon_info.shots)
	info.SetDistance(5000)
	//printl("Firing !")
	//self.GetActiveWeapon().FireBullets(info)
	self.FireBullets(info)
	printl("Fired a shot!")
	//self.DoMuzzleFlash()
	
	local attach=self.GetActiveWeapon().LookupAttachment("muzzle")
	local muzzle=self.GetActiveWeapon().GetAttachmentOrigin(attach)
	
	DispatchParticleEffect("muzzle_mg42",muzzle,EnemyWeaponEnt.GetAngles(),player)

	//NetProps.SetPropFloat(self,"m_flNextAttack",Time()-1)

	self.GetActiveWeapon().SetClip1(clamp(self.GetActiveWeapon().Clip1()-1,0,weapon_info.clip))

	//self.SetCycle(0.9)
	if (self.GetActiveWeapon()) clip=self.GetActiveWeapon().Clip1()
	


	return false
	}
	return true
}

function OnDeath(info=0)
{
	self.GetExpresser().SpeakRawSentence("AGENT_DEATH",0)
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

function OnTakeDamage(info)
{
	if (RandomInt(1,2)==1) self.GetExpresser().SpeakRawSentence("AGENT_PAIN",0);
	
	if (self.LastHitGroup()==1)
	{
		self.SetBodygroup(1,self.GetBodygroup(1)+1)
	}
}

function OnFoundEnemy()
{
	if (FoundOnce!=0) return;
	
	FoundOnce=Time()
	
	printl("FOUND YOU")
	self.AddLookTarget(self.GetEnemy(),2,20,0);
	self.AddLookTarget(self.GetEnemy(),2,20,0);
	self.AddLookTarget(self.GetEnemy(),2,20,0);
	
	self.EmitSound("Corruptor.Spotted")
	self.SetSkin(1)
	if (Time()-CORRUPTOR_AGENT_LASTSAY>3||CORRUPTOR_AGENT_LASTSAY_TYPE!="ALERT") 
	{
		Entities.First().SetContextThink("AGENT_ALERT",function(_) {self.GetExpresser().SpeakRawSentence("AGENT_ALERT",1)}.bindenv(this),RandomFloat(0,2));
		CORRUPTOR_AGENT_LASTSAY=Time()+RandomFloat(2,5)
		CORRUPTOR_AGENT_LASTSAY_TYPE="ALERT"
	}
}


self.ConnectOutput( "OnFoundEnemy", "OnFoundEnemy" )

Hooks.Add( this, "OnDeath", OnDeath, "OnDeath" );
Hooks.Add( this, "OnTakeDamage", OnTakeDamage, "OnTakeDamage" );
Hooks.Add( this, "HandleAnimEvent", HandleAttack, "HandleAttack" );