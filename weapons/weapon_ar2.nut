IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("SW.Weapon.DrawCombine")
self.PrecacheSoundScript("Weapon_AR2.Single")
self.PrecacheSoundScript("Weapon_AR2.Reload")
self.PrecacheSoundScript("Weapon_CombineGuard.Special1")
self.PrecacheSoundScript("Weapon_IRifle.Single")

local weapon=null
local a=UniqueString("")
function Think(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_ar2") return 0.005
	//if (SERVER_DLL) printl("thinking for "+a)
	weapon.Update()
	return 0.005
}
::aPlayer<-null

local grenadelight = {
	_cone = 0,
	_inner_cone = 0,
	_light = "249 205 167 2200",
	brightness = 2,
	distance = 160
	pitch = -90,
	//spawnflags = 1,
	style=0
}

local ar2light = {
	_cone = 0,
	_inner_cone = 0,
	_light = "255 235 57 220",
	brightness = 3,
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
		balltype=1
		minspeed=1500
		maxspeed=1500
		maxballbounces=20
	}
	local Grenade=SpawnEntityFromTable("point_combine_ball_launcher",GrenadeTable)
	Grenade.AcceptInput("LaunchBall","",null,null)
	Grenade.Destroy()
	Grenade=null
	
	local LastBall=null;
	while (Grenade=Entities.FindByClassname(Grenade,"prop_combine_ball")) {LastBall=Grenade};
	Grenade=LastBall;
	
	EntFireByHandle(Grenade,"explode","",5)
	
	local TrailTable=
	{
		origin=(player.EyePosition()+player.GetEyeForward()*16+player.GetEyeRight()+player.GetEyeUp()*(-2)).ToKVString()
		angles=(player.EyeAngles()).ToKVString()
		lifetime=0.5
		startwidth=6
		endwidth=0.1
		spritename="sprites/laserbeam.vmt"
		rendermode=5
		rendercolor="125 120 80"
	}
	Grenade.AcceptInput("SetDamage","80",null,null)
	Grenade.AcceptInput("AddOutput","radius 250",null,null)
	Grenade.SetOwner(player)
	
	local GrenadeLight = SpawnEntityFromTable("light_dynamic", grenadelight)

	GrenadeLight.FollowEntity(Grenade,false)
	GrenadeLight.SetLocalOrigin(Vector(10,0,4))
	
	local Trail=SpawnEntityFromTable("env_spritetrail",TrailTable)
	Trail.FollowEntity(Grenade,false)
	player.EmitSound("Weapon_IRifle.Single")
	
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
		Model="models/weapons/v_irifle.mdl"
		Firerate=0.085
		RecoilMult=5
		Spread=0.05
		InAccuracy=0.1
		Damage=18
		Clip=50
		ShootSound="Weapon_AR2.Single"
		ReloadSound="Weapon_AR2.Reload"
		DrawSound="SW.Weapon.DrawCombine"
		ImpactOverride="AR2Impact"
		TracerOverride="weapon_ar2_tracer"
		
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
				if (cycle<0.05) Convars.SetInt("spec_track",1)
				else Convars.SetInt("spec_track",0)
			}
			else
			{
				Convars.SetInt("spec_track",0)
				if (reloading&&nextattack-Time()>0.75) Convars.SetInt("spec_track",1)
			}
		
			if (player.GetButtons() & IN.ATTACK2&&(player.GetButtonLast() & IN.ATTACK2)&&Time()>nextattack&&clip==maxclip)
			{
				clip=0;
				player.GetActiveWeapon().SendWeaponAnim(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_FIDGET")))
				VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_FIDGET")))
				player.GetActiveWeapon().SetWeaponIdleTime(Time()+0.5+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_FIDGET"))))
				
				player.EmitSound("Weapon_CombineGuard.Special1")
				
				Entities.First().SetContextThink("AR2Ball",function(_){
				LaunchBall()}.bindenv(this),0.65)
				
				nextattack=Time()+1.4;
				
				local GrenadeLight = SpawnEntityFromTable("light_dynamic", ar2light)

				GrenadeLight.FollowEntity(player,false)
				GrenadeLight.SetLocalOrigin(Vector(28,-7,57))
				EntFireByHandle(GrenadeLight,"distance", "0",0)
				EntFireByHandle(GrenadeLight,"distance", "20",0.1)
				EntFireByHandle(GrenadeLight,"distance", "40",0.2)
				EntFireByHandle(GrenadeLight,"distance", "60",0.3)
				EntFireByHandle(GrenadeLight,"distance", "80",0.4)
				EntFireByHandle(GrenadeLight,"distance", "120",0.5)
				EntFireByHandle(GrenadeLight,"distance", "160",0.6)
				
				EntFireByHandle(GrenadeLight,"kill","",0.75)
				
			}
			
		}
	}
	
	weapon=C_BaseWeapon("weapon_ar2",WeaponInfo)
	Init(weapon)
}

Entities.EnableEntityListening()
//Entities.First().SetContextThink(UniqueString("")+"SMG45",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}
