IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("SW.Weapon.DrawEnergy")
self.PrecacheSoundScript("Weapon_AR1.Single")
self.PrecacheSoundScript("Weapon_AR1.Single2")
self.PrecacheSoundScript("Weapon_AR1.Reload")
self.PrecacheSoundScript("Weapon_AR1.Charge")
self.PrecacheSoundScript("Weapon_AR1.Double")
self.PrecacheSoundScript("k_lab.teleport_active")
self.PrecacheSoundScript("Weapon_AR1.Impact")
self.PrecacheSoundScript("Weapon_AR1.Flyby")
self.PrecacheSoundScript("d3_citadel.zapper_warmup")
PrecacheParticleSystem("grenade_explosion_01c")

local weapon=null
local a=UniqueString("")
function Think(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_ar1") return 0.005
	//if (SERVER_DLL) printl("thinking for "+a)
	weapon.Update()
	return 0.005
}
::aPlayer<-null

local grenadelight = {
	_cone = 0,
	_inner_cone = 0,
	_light = "249 205 127 2200",
	brightness = 2,
	distance = 400
	pitch = -90,
	//spawnflags = 1,
	style=1
}

local ar2light = {
	_cone = 0,
	_inner_cone = 0,
	_light = "255 235 57 220",
	brightness = 2,
	distance = 160
	pitch = -90,
	//spawnflags = 1,
	style=0
}

local LaunchBall=function()
{
	local VM=player.GetViewModel(0)
	
	SW_ScreenFade(0.01,0.15,250,250,250,65,true)
	
	local GrenadeTable=
	{
		origin=(player.EyePosition()+player.GetEyeForward()*16+player.GetEyeRight()*3+player.GetEyeUp()*(-3)).ToKVString()
		angles=(player.EyeAngles()).ToKVString()
		spawnflags=65536
		ballcount=1
		balltype=2
		minspeed=350
		maxspeed=350
		ballradius=32
		maxballbounces=25
		rendermode=5
		rendercolor="255 255 0"
	}
	local Grenade=SpawnEntityFromTable("point_combine_ball_launcher",GrenadeTable)
	Grenade.AcceptInput("LaunchBall","",null,null);
	Grenade.Destroy()
	Grenade=null
	
	local LastBall=null;
	while (Grenade=Entities.FindByClassname(Grenade,"prop_combine_ball")) {LastBall=Grenade};
	Grenade=LastBall;
	Grenade.SetRenderMode(6)
	Grenade.SetAlpha(0)
	Grenade.SetCollisionGroup(1)
	
	EntFireByHandle(Grenade,"explode","",7)
	
	local BeamTable=
	{
		origin=(player.EyePosition()+player.GetEyeForward()*16+player.GetEyeRight()+player.GetEyeUp()*(-2)).ToKVString()
		angles=(player.EyeAngles()).ToKVString()
		BoltWidth=1
		damage=1
		life=0.1
		NoiseAmplitude=13
		Radius=256
		StrikeTime=0.01
		TextureScroll=35
		TouchType=3
		texture="sprites/laserbeam.vmt"
		rendercolor="255 140 80"
		dissolvetype=0
	}
	Grenade.AcceptInput("SetDamage","80",null,null)
	Grenade.AcceptInput("AddOutput","radius 250",null,null)
	Grenade.SetOwner(player)
	
	local sprite_t=
	{
		model="sprites/animglow01.vmt"
		rendercolor="255 140 80"
		rendermode=9
		scale=1.0
		framerate=10
	}
	
	local ModifyEmitSoundParams=function(params)
	{
		//printl(params.GetSoundName())
		if (params.GetSoundName()=="NPC_CombineBall_Episodic.Impact")
		{
			params.SetSoundName("Weapon_AR1.Impact")
		}
		if (params.GetSoundName()=="NPC_CombineBall_Episodic.WhizFlyby")
		{
			params.SetSoundName("Weapon_AR1.Flyby")
		}
		if (params.GetSoundName()=="NPC_CombineBall_Episodic.Explosion")
		{
			params.SetSoundName("d3_citadel.zapper_warmup")
		}
	}
	
	Hooks.Add(Grenade.GetOrCreatePrivateScriptScope(),"ModifyEmitSoundParams",ModifyEmitSoundParams.bindenv(this),"ModifyEmitSoundParams");
	
	local GrenadeSprite = SpawnEntityFromTable("env_sprite", sprite_t)

	GrenadeSprite.FollowEntity(Grenade,false)
	
	local GrenadeLight = SpawnEntityFromTable("light_dynamic", grenadelight)

	GrenadeLight.FollowEntity(Grenade,false)
	GrenadeLight.SetLocalOrigin(Vector(10,0,4))
	
	Grenade.EmitSound("k_lab.teleport_active")
	GrenadeLight.EmitSound("k_lab.teleport_active")
	Grenade.SetContextThink("StopSound",function(_){Grenade.StopSound("k_lab.teleport_active")}.bindenv(this),7)
	GrenadeLight.SetContextThink("StopSound",function(_){GrenadeLight.StopSound("k_lab.teleport_active")}.bindenv(this),7)
	
	for (local i=0;i<10;i++)
	{
	BeamTable.NoiseAmplitude=RandomInt(1,13)
		
	local Trail=SpawnEntityFromTable("env_beam",BeamTable)
	Trail.SetName("ar1ball"+i)
	EntFireByHandle(Trail,"SetStartEntity","ar1ball"+i)
	EntFireByHandle(Trail,"Toggle")
	EntFireByHandle(Trail,"AddOutput","StrikeTime "+RandomFloat(0.03,0.1))
	EntFireByHandle(Trail,"AddOutput","life "+RandomFloat(0.06,0.15))
	local LastPos=Trail.GetOrigin()
	Trail.SetContextThink("beam"+Trail.GetName(),function(_)
	{
		if (!Grenade) return;
		//printl((Grenade.GetOrigin()-LastPos))
		Trail.SetOrigin(Grenade.GetOrigin()+(Grenade.GetOrigin()-LastPos).Normalized()*32);
		LastPos=Grenade.GetOrigin()
		return 0
	}.bindenv(this),0)
	
	if (i==0) Trail.SetContextThink("beamDAMAGE"+Trail.GetName(),function(_)
	{
		if (!Grenade) return; 
		
		local Target=null;
		//EntFireByHandle(Trail,"SetEndEntity","")
		while (Target=Entities.FindByClassnameWithin(Target, "npc*", Trail.GetOrigin(), 160))
		{	
			if (Target==player) continue;
			if (!Target.IsAlive()) continue;
			if (!Target.IsVisible(Grenade.GetOrigin())) continue;

			local Damage=CreateDamageInfo(player,player.GetActiveWeapon(),Target.GetCenter(),Target.GetCenter(),3,DMG_SHOCK+DMG_PHYSGUN)
			if (Target.GetCenter().DistTo(Grenade.GetOrigin())<25) 
			{
				Trail.EmitSound("Weapon_AR1.Impact")
				Damage.SetDamage(10)
			}
			Damage.SetDamageForce((Target.GetCenter()-Trail.GetOrigin()).Normalized()*1000000)
			Damage.SetAttacker(player)
			if (Target.GetHealth()>0&&Target.GetHealth()<=Damage.GetDamage())
			{
				Target.PrecacheSoundScript("Weapon_AR1.BallKill.,")
				Target.EmitSound("Weapon_AR1.BallKill")
				//DispatchParticleEffect("grenade_explosion_01c",Target.GetCenter(),Vector(),Target)
				DispatchEffect("cball_explode",Target.GetCenter(),Vector())
				DispatchEffect("cball_explode",Target.GetOrigin(),Vector())
				DispatchEffect("cball_explode",Target.EyePosition(),Vector())
			}
			Target.TakeDamage(Damage)
			//Target.Dissolve("sprites/laserbeam.vmt", Time()-1, false, 2, Trail.GetOrigin(), 0)
			//EntFireByHandle(Trail,"SetEndEntity",Target.GetName())
			
		}
		return 0.05
	}.bindenv(this),0)
	
	EntFireByHandle(Trail,"kill","",7)

	Trail.GetOrCreatePrivateScriptScope().Damager<-function()
	{
		printl(activator)
	}
	Trail.ConnectOutput("OnTouchedByEntity","Damager")

	}
	//Trail.AcceptInput("AddOutput","LightningStart "+Grenade.GetName(),null,null)
	player.EmitSound("Weapon_AR1.Double")
	
	//Grenade.GetPhysicsObject().ApplyForceCenter((player.GetEyeForward()*1000+player.GetEyeUp()*170)*Grenade.GetPhysicsObject().GetMass())
	//Grenade.ApplyLocalAngularVelocityImpulse(Vector(-300,600,550))
	Grenade.SetVelocity(player.GetEyeForward()*900+player.GetEyeUp()*70)
	
	player.GetActiveWeapon().SendWeaponAnim(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_SECONDARYATTACK")))
	VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_SECONDARYATTACK")))
	player.ViewPunch(Vector(-5,0,0))
	
	player.GetActiveWeapon().SetWeaponIdleTime(Time()+0.5+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_SECONDARYATTACK"))))
}


function InitWeapon(...)
{
	//IncludeScript("weapons/weapon_base.nut")
	aPlayer=player.GetOrCreatePrivateScriptScope()
	
	local WeaponInfo=
	{
		AmmoType="item_ammo_energy"
		Model="models/weapons/v_irifle2.mdl"
		Firerate=0.11
		RecoilMult=3
		Spread=0.15
		InAccuracy=0.25
		Damage=12
		Clip=30
		ShootSound="Weapon_AR1.Single"
		ShootSound2="Weapon_AR1.Single2"
		ReloadSound="Weapon_AR1.Reload"
		DrawSound="SW.Weapon.DrawEnergy"
		ImpactOverride="AR2Impact"
		TracerOverride="weapon_ar1_tracer"
		
		SecondaryAttack=function(hnd)
		{			
			local VM=player.GetViewModel(0)
			
			local AttackSequences=[VM.SelectWeightedSequence(VM.LookupActivity("ACT_VM_PRIMARYATTACK"),1),
			VM.SelectWeightedSequence(VM.LookupActivity("ACT_VM_RECOIL1"),1),
			VM.SelectWeightedSequence(VM.LookupActivity("ACT_VM_RECOIL2"),1),
			VM.SelectWeightedSequence(VM.LookupActivity("ACT_VM_RECOIL3"),1)]
			
			if (AttackSequences.find(VM.GetSequence())!=null)
			{
				local cycle=VM.GetCycle()
				if (cycle<0.1) Convars.SetInt("spec_track",0)
				else Convars.SetInt("spec_track",1)
			}
			else
			{
				Convars.SetInt("spec_track",1)
				if ((reloading&&nextattack-Time()>0.75)) Convars.SetInt("spec_track",0)
			}
		
			if (player.GetButtons() & IN.ATTACK2&&(player.GetButtonLast() & IN.ATTACK2)&&Time()>nextattack&&clip==maxclip)
			{
				clip=0;
				player.GetActiveWeapon().SendWeaponAnim(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_FIDGET")))
				VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_FIDGET")))
				player.GetActiveWeapon().SetWeaponIdleTime(Time()+0.5+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_FIDGET"))))
				
				player.EmitSound("Weapon_AR1.Charge")
				
				Entities.First().SetContextThink("AR2Ball",function(_){
				LaunchBall()}.bindenv(this),1)
				
				nextattack=Time()+1.8;
				
				local GrenadeLight = SpawnEntityFromTable("light_dynamic", ar2light)

				GrenadeLight.FollowEntity(player,false)
				GrenadeLight.SetLocalOrigin(Vector(28,-7,57))
				EntFireByHandle(GrenadeLight,"distance", "0",0)
				EntFireByHandle(GrenadeLight,"distance", "10",0.1)
				EntFireByHandle(GrenadeLight,"distance", "20",0.2)
				EntFireByHandle(GrenadeLight,"distance", "30",0.3)
				EntFireByHandle(GrenadeLight,"distance", "40",0.4)
				EntFireByHandle(GrenadeLight,"distance", "50",0.5)
				EntFireByHandle(GrenadeLight,"distance", "70",0.6)
				EntFireByHandle(GrenadeLight,"distance", "90",0.7)
				EntFireByHandle(GrenadeLight,"distance", "120",0.8)
				EntFireByHandle(GrenadeLight,"distance", "140",0.9)
				EntFireByHandle(GrenadeLight,"kill","",1)
				
			}
			
		}
	}
	
	weapon=C_BaseWeapon("weapon_ar1",WeaponInfo)
	Init(weapon)
}

Entities.EnableEntityListening()
//Entities.First().SetContextThink(UniqueString("")+"SMG45",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}
