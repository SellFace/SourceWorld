IncludeScript("enemies/base_enemy.nut")
IncludeScript("enemies/ai_grenade.nut")
local disabled=false;

local eyedir=self.EyeDirection3D()

clip<-(18);
lastclip<-(0)

local LastShot=0;

local PrevDir=0

function Think()
{
	//printl((self.EyeDirection3D()-eyedir).Length())
	
	if ("extra_think" in LIST_ENEMIES[EnemyName]&&self.IsAlive())
	{
		LIST_ENEMIES[EnemyName].extra_think(self)
	}

	
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
	
	if ((player.GetOrigin()-self.GetOrigin()).Length()>2000&&!disabled) {EntFireByHandle(self,"setthinknull");disabled=true}
	if ((player.GetOrigin()-self.GetOrigin()).Length()<=2000&&disabled) {EntFireByHandle(self,"setthinknpc");disabled=false}
	
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
	//printl(event.GetEvent())
	//printl(event.GetEvent())
	//printl(event.GetEvent())
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
		Grenade.SetOwner(self)
		
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

function FireBullets()
{
	if (self.GetEnemy()&&self.GetEnemy()!=!player)
		return info;

	local dif=self.EyeDirection3D()-eyedir
	info.SetDirShooting(info.GetDirShooting()-dif)
	info.SetSource(self.GetOrigin()+Vector(0,0,48))
	debugoverlay.Line(info.GetSource(), info.GetSource()+eyedir*270, 255, 25, 25, true, 0.5)
	return info
}

function NPC_TranslateActivity()
{
	//printl("bbb")
    local newactivity = -1;
    if (activity.find("ACT_MELEE_ATTACK1") != null)
	{
		return "ACT_MELEE_ATTACK2"
	}
	 if ((activity.find("IDLE") != null)&&(activity.find("RELAXED") == null)&&(self.GetNPCState()<2)&&self.entindex()%2==0)
	{
		//printl("bbb2")
		return "ACT_IDLE_RELAXED"
	}
    return newactivity;
}

Hooks.Add( this, "HandleAnimEvent", HandleAttack, "HandleAttack" );