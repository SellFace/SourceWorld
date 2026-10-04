EnemyName<-"WON"

IncludeScript("enemies/base_enemy.nut")
IncludeScript("enemies/ai_grenade.nut")
local disabled=false;

local eyedir=self.EyeDirection3D()

clip<-(18);
lastclip<-(0)

local LastShot=0;

local PrevDir=0

function NPC_TranslateActivity()
{
	if (activity.find("MELEE_ATTACK")!=null&&(self.GetCycle()<0.1) )
	{
		self.SetVelocity((self.GetEnemy().GetVelocity()/3+self.GetEnemy().GetOrigin()-self.GetOrigin()).Normalized()*200)
		self.SetPlaybackRate(1.15)
	}
	return activity
}

local EyeOnSpawn=Time()


function Think()
{
	
	eyedir=eyedir+(self.EyeDirection3D()-eyedir)*0.6
	
	if ((Time()-EyeOnSpawn)<2)
	{
		eyedir=self.EyeDirection3D() // This fixes bug where they would aim into nowhere for a moment after spawning
	}
	
	//debugoverlay.Line(self.ShootPosition(), self.ShootPosition()+self.EyeDirection3D()*370, 155, 5, 5, true, 0.12)
	//debugoverlay.Line(self.ShootPosition(), self.ShootPosition()+eyedir*370, 255, 255, 25, true, 0.12)
	
	if (self.GetEnemy()) self.AddLookTarget(self.GetEnemy(),0.5,41,0);
	
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
	
	if (self.GetActiveWeapon().Clip1()<=0&&self.GetEnemy()&&((self.GetEnemy().GetOrigin()-self.GetOrigin()).Length()<60)&&(self.GetSchedule()!="SCHED_MELEE_ATTACK1"))
	{
		//printl("KILL")
		//self.SetSchedule("SCHED_ZOMBIE_MELEE_ATTACK1")
		//printl("attacking!"+self.GetActivity())
		self.SetSchedule("SCHED_MELEE_ATTACK1")
		//self.SetActivity("ACT_MELEE_ATTACK1")
	}
		
	
	if (self.GetActivity().find("RANGE_ATTACK")!=null)
	{
		//printl("SHOOTING")
		self.ResetActivity()
		return 0.11
	}
	
	
	if (GetMapName().find("mapgen")==null) return 0.11
	
	if (self.GetSchedule()=="SCHED_IDLE_STAND"&&(self.entindex()%4)==0) self.SetSchedule("SCHED_IDLE_WANDER")
	
	if ((player.GetOrigin()-self.GetOrigin()).Length()>1000&&!disabled) {EntFireByHandle(self,"setthinknull");disabled=true}
	if ((player.GetOrigin()-self.GetOrigin()).Length()<=1000&&disabled) {EntFireByHandle(self,"setthinknpc");disabled=false}
	
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

function HandleAttack(event)
{
	printl(event.GetEvent())
	printl(event.GetEvent())
	printl(event.GetEvent())
	
	if (event.GetEvent()==3&&((self.GetEnemy().GetOrigin()-self.GetOrigin()).Length()<60))
	{
		local Damage=CreateDamageInfo(self,self,self.GetForwardVector()*100,self.GetForwardVector()*100,10,DMG_CLUB)
		Damage.SetDamageType(DMG_CLUB)
		Damage.SetAttacker(self)
		Entities.FindByName(null,"SW_DMG").PassesFinalDamageFilter(self.GetEnemy(),Damage)
		self.GetEnemy().TakeDamage(Damage)
		
		local punch=Vector(RandomFloat(-10,10),-45,15)
			
		punch=punch*0.5
		
		if (self.GetEnemy()==player) self.GetEnemy().ViewPunch(punch)
		if (self.GetEnemy()==player) self.SetContextThink("AttackViewPunch",function(_){self.GetEnemy().ViewPunch(punch*0.6)}.bindenv(this),0.15)
		if (self.GetEnemy()==player) self.SetContextThink("AttackViewPunch2",function(_){self.GetEnemy().ViewPunch(punch*0.3)}.bindenv(this),0.3)
		self.EmitSound("Flesh.ImpactHard")
	}
	
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
		
	if (LastShot==Time()) return false;
	
	LastShot=Time()
		
	Entities.First().SetContextThink("DelayedSound",function(_) {self.GetActiveWeapon().EmitSound(weapon_info.shootsound)}.bindenv(this),0.01);
	local info = CreateFireBulletsInfo(1, self.ShootPosition(), eyedir, weapon_info.spread, 1, self)
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
	//printl("Fired a shot!")
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

function FireBullets()
{
	local shots=info.GetShots()
	info.SetShots(1)
	
	info.SetTracerFreq(0)
	local dif=self.EyeDirection3D()-eyedir
	info.SetDirShooting(info.GetDirShooting()-dif)
	
	if (shots>1) info.SetDirShooting(info.GetDirShooting()-dif*0.5) //Shotgunners have better precision.
	
	//info.SetSource(self.GetOrigin()+Vector(0,0,48))
	
	local spred=info.GetSpread()
	info.SetSpread(Vector())
	
	local shootdir=info.GetDirShooting()
	
	for (local i=0;i<shots;i++)
	{
		local deg=RandomFloat(-PI,PI)
		local dist=RandomFloat(-1,1)
		info.SetDirShooting(shootdir+Vector(0,spred.y*sin(deg)*dist,spred.z*cos(deg)*dist))
		
		self.GetActiveWeapon().FireBullets(info);
		
		local trace=TraceLineComplex(info.GetSource(), info.GetSource()+info.GetDirShooting()*5000,self,MASK_SHOT,0)
		
		
		local traceeffect="weapon_tracers"
		//if (ImpactOverride)
		//{
		//	DispatchEffect("AR2Impact",info.GetSource()+info.GetDirShooting()*5000*trace.Fraction(),VectorAngles(trace.Plane().normal))
		//}
		//if (TracerOverride)
		//{
		//	traceeffect=TracerOverride;
		//}
		local endpoint_name=UniqueString("ar1tracer")
		local EndPoint=SpawnEntityFromTable("info_target",{spawnflags=1,targetname=endpoint_name,origin=info.GetSource()+info.GetDirShooting()*5000*trace.Fraction()})
		
		local Tracer_t={
			effect_name=traceeffect//weapon_ar1_tracer
			start_active=1
			//cpoint0="!self"
			cpoint1=endpoint_name
			parentname=self.GetName()
			origin=(info.GetSource()+Vector(0,0,-3)).ToKVString()
			//origin=(muzzle+player.GetEyeRight()*0-player.GetEyeUp()*0+player.GetEyeForward()*10+player.GetVelocity()*0.015).ToKVString()
		}
		
		if (trace.Entity()!=player&&CalcDistanceToLineSegment(player.EyePosition(),shootdir,info.GetSource()+info.GetDirShooting()*5000*trace.Fraction())<70)
		{
			local s=EmitSound_t()
			s.SetSoundName("Bullets.DefaultNearmiss")
			s.SetOrigin(CalcClosestPointOnLine(player.EyePosition(),shootdir,info.GetSource()+info.GetDirShooting()*5000*trace.Fraction()))
			s.SetVolume(1)
			EmitSoundParamsOn(s,player)
			printl("NEARMISS")
		}
		
		local Tracer = SpawnEntityFromTable("info_particle_system",Tracer_t)
		EntFireByHandle(Tracer,"DestroyImmediately","",1)
		EntFireByHandle(Tracer,"Kill","",1.1)
		EntFireByHandle(EndPoint,"Kill","",0.1)
		DestroyFireBulletsInfo(info)
	}
	
	debugoverlay.Line(info.GetSource(), info.GetSource()+eyedir*270, 255, 25, 25, true, 0.5)
	
	return info
}

function OnTakeDamage(info)
{
	//if (!SW_BOSS_ACTIVE) return false;
	
	NetMsg.Start("BossHP")
	NetMsg.WriteFloat((self.GetHealth()-info.GetDamage())/self.GetMaxHealth())
	NetMsg.Send(player,true)

	if (info.GetDamage()>=self.GetHealth())
	{
		/*
		local scripttable={
			targetname=self.GetName()+"_down_anim"
			spawnflags=32+64
			m_fMoveTo=0
			m_iszEntity=self.GetName()
			m_iszPlay="downed_loop"
			m_iszEntry="downed"
			m_bLoopActionSequence=1
			m_bIgnoreGravity=0
		}
		local sequence=SpawnEntityFromTable("scripted_sequence",scripttable);
		sequence.AcceptInput("beginsequence","",self,self)
		*/
		
		self.PrecacheSoundScript("ep1_citizen.cit_pain07")
		self.EmitSound("ep1_citizen.cit_pain07")
		
		SetBossStatus(false)
		
		GetNamedEnt("stamina_system").GetScriptScope().DeathCam(self,self.GetModelName(),Time(),info.GetDamageForce()*16)
		
		OnBossDefeated()
		
		return true
	}
	
	return true;
}

Hooks.Add( this, "HandleAnimEvent", HandleAttack, "HandleAttack" );
Hooks.Add( this, "OnTakeDamage", OnTakeDamage, "OnTakeDamage" );
Hooks.Add( this, "OnDeath", OnTakeDamage, "OnTakeDamage" );