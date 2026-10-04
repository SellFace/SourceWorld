//
// I Love You to the Moon and Back
//


IncludeScript("weapons/weapon_base.nut")
IncludeScript("base.nut")
self.PrecacheSoundScript("SW.Weapon.DrawSword")
self.PrecacheSoundScript("Weapon_Sword.Hit")
self.PrecacheSoundScript("Weapon_Sword.HitWorld")
self.PrecacheSoundScript("Weapon_Sword.Miss")
self.PrecacheSoundScript("Weapon_Pipe.Crit")
self.PrecacheSoundScript("SW.Weapon.DrawMelee")

local weapon=null

::PARRY_WINDOW<-0.2

PrecacheParticleSystem("blood_impact_synth_01_dust")
PrecacheParticleSystem("blood_impact_red_01")
PrecacheParticleSystem("blood_impact_yellow_01")
PrecacheParticleSystem("ricochet_sparks")
PrecacheParticleSystem("blood_advisor_pierce_spray")

function Think5(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_sword") return 0.005
	weapon.Update()
	return 0.005
}
::aPlayer<-null

local ViewP=function(side,down=1)
{
	local punch=Vector(RandomFloat(-0.01,-0.02)*down,RandomFloat(0.1,0.2)*side,RandomFloat(0.05,0.07)*(-side))
	player.ViewPunch(punch)
}
local ViewP2=function(side,down=1)
{
	local punch=Vector(RandomFloat(-0.08,-0.12)*down,RandomFloat(0.1,0.2)*side,RandomFloat(0.05,0.07)*(-side))
	player.ViewPunch(punch)
}

local StoppedAttack=-1
local StoppedTarget=null
local CanParry=false

local FireRay=function(mod,RayStart,RayEnd,RayDist,Attacks,wepinfo)
{

	local RayDir=RayStart+(RayEnd-RayStart)*mod
	local RayRight=RayDir.y
	local RayUp=RayDir.x
	
	local viewpside=Info.ViewPSide
	
	if (RayEnd.y<0) viewpside=-viewpside
	
	//printl(mod)
	//printl(RayDir)

	local attackvector=player.ShootPosition()+(((player.GetEyeRight())*RayRight+player.GetEyeUp()*RayUp)+player.GetEyeForward()*RayDist).Normalized()*RayDist
	
	local inverted_attackvector=player.ShootPosition()+(((player.GetEyeRight())*(-RayRight)+player.GetEyeUp()*(-RayUp))+player.GetEyeForward()*RayDist).Normalized()*RayDist
	
	local attackray=TraceLineComplex(player.ShootPosition(), attackvector,player,MASK_SHOT,0)
	local target=attackray.Entity()
	
	local hitpos=attackray.StartPos()+(attackray.EndPos()-attackray.StartPos())*attackray.Fraction()
	
	
	debugoverlay.Line(player.ShootPosition()+Vector(0,0,-2),attackvector,200,200,12,false,1.0)
	if (!target) {attackray.Destroy();return}
	
	
	local playervelocity=player.GetVelocity()-target.GetVelocity()*2
	
	
	if (StoppedAttack!=Attacks)
	{
		ViewP2(viewpside,Info.ViewPDown)
		
		if (target.IsNPC()!=true) 
			player.GetActiveWeapon().EmitSound("Weapon_Sword.HitWorld");
		
		ShakePlayerScreen(200,(playervelocity).Length()/100+2,0.1+(playervelocity).Length()/800)
		DispatchParticleEffect("blood_impact_synth_01_dust",hitpos,VectorAngles(-player.GetEyeForward()),target)
		//local hitsound=EmitSound_t()
		//hitsound.SetSoundName(attackray.Surface().SurfaceProps().GetSoundBulletImpact())
		//hitsound.SetOrigin( hitpos )
		//EmitSoundParamsOn(hitsound,Entities.First())
		
	}
	DispatchParticleEffect("blood_impact_synth_01_dust",hitpos,VectorAngles(-player.GetEyeForward()),player.GetOrigin()) 
	if ((StoppedAttack==Attacks)&&(StoppedTarget==target)) {attackray.Destroy();return}
	StoppedAttack=Attacks
	StoppedTarget=target
	
	local Damage=CreateDamageInfo(player,player.GetActiveWeapon(),Vector(0,0,0),Vector(0,0,0),Info.MinDamage+(playervelocity).Length()*Info.DamagePerSpeed,128)
	Damage.SetAttacker(player)
	Damage.SetDamageType(DMG_SLASH)
	
	Damage.SetDamageForce((attackvector-player.ShootPosition())*Info.AttackForce+(player.GetEyeRight()*RayDir.y)*Info.AttackForce/2.0+playervelocity*2)
	
	if (target.IsNPC()==true) Damage.SetDamageForce((attackvector-player.ShootPosition())*Info.AttackForce*4+(player.GetEyeRight()*RayDir.y)*Info.AttackForce*22+playervelocity*40)
	else Damage.SetDamage(Info.MinDamage+(playervelocity).Length()*Info.DamagePerSpeed);

	if (target&&target.GetClassname().find("zombie")!=null&&attackray.HitGroup()!=1)
	{
		Damage.SetDamageType(DMG_SLASH+DMG_CRUSH)
		//Damage.SetDamage(Damage.GetDamage()*10)
	}

	Damage.SetDamagePosition(attackray.EndPos())
	local damagecycle=1-0.58
	if ((target)&&(target.IsNPC()==true))
	{
		player.GetActiveWeapon().EmitSound("Weapon_Sword.Hit")
		
		if (target.GetSequenceName(target.GetSequence())=="attackE"||target.GetSequenceName(target.GetSequence())=="attackF") damagecycle=0.49
		if (target.GetActivity()=="ACT_MELEE_ATTACK1"&&target.GetClassname()=="npc_combine_s") damagecycle=0.49
	}
	
	CanParry=((target)&&(target.IsNPC()==true)&&(target.GetHealth()>0)&&(target.GetActivity()=="ACT_MELEE_ATTACK1")&&(fabs(target.GetCycle()-damagecycle)<PARRY_WINDOW))
	if ("attacktime" in target.GetScriptScope()) if ((Time()-target.GetScriptScope().attacktime)<0.2)
	{
		CanParry=false
		printl("Enemy attacked. Parrying denied")
	}
	
	if (CanParry) 
	{
		//target.SetLayerNoEvents(target.FindGestureLayer("ACT_MELEE_ATTACK1"),true)
		//target.SetLayerPlaybackRate(target.FindGestureLayer("ACT_MELEE_ATTACK1"),-1)
		DestroyDamageInfo(Damage);
		//printl("PARRY! "+fabs(target.GetCycle()-damagecycle))
		local VM=player.GetViewModel(0)
		VM.SetSequence(VM.LookupSequence("hitcenter3"))
		
		player.EmitSound("Flesh.ImpactHard")
		player.EmitSound("Canister.ImpactHard")
		target.EmitSound("Canister.ImpactHard")
		target.EmitSound("Flesh.ImpactHard")
		DispatchParticleEffect("ricochet_sparks",hitpos,VectorAngles(-player.GetEyeForward()),target) 
		attackray.Destroy();
		//target.SetSchedule("SCHED_FLINCH_PHYSICS")
		//target.SetActivity("ACT_FLINCH_PHYSICS")
		local parrysequence=target.GetSequence()
		target.GetOrCreatePrivateScriptScope().Parry(parrysequence)
		//target.SetSequence(target.GetLayerSequence(target.FindGestureLayer("ACT_MELEE_ATTACK1")))
		//target.SetCycle(0.25)
		//target.SetPlaybackRate(-1)
		//target.RemoveAllGestures()
		local flinch="ACT_GESTURE_FLINCH_HEAD"
		if ((Attacks%2)!=0&&(target.LookupActivity("ACT_GESTURE_FLINCH_RIGHTARM")!=-1)) flinch="ACT_GESTURE_FLINCH_RIGHTARM" 
		if ((Attacks%2)==0&&(target.LookupActivity("ACT_GESTURE_FLINCH_LEFTARM")!=-1)) flinch="ACT_GESTURE_FLINCH_LEFTARM" 
		//target.AddGesture(flinch,true)
		//target.SetPlaybackRate(target.GetPlaybackRate()*(-1.5))
		target.SetVelocity(target.GetVelocity()/10+playervelocity/2+(inverted_attackvector-player.ShootPosition())*3)
		player.SetVelocity(player.GetVelocity()+playervelocity/(-10)+(inverted_attackvector-player.ShootPosition())*(-3))
		ViewP2(-viewpside,-Info.ViewPDown)
		return
	}
	
	Entities.FindByName(null,"SW_DMG").PassesFinalDamageFilter(target,Damage)
	local IsAlien=(target.GetModelName().find("crab")!=null||(target.GetModelName().find("zombie")!=null&&target.GetBodygroup(1)&&attackray.HitGroup()==1))
	local IsCorruptor=(target.GetModelName().find("corrupt")!=null)
	//DispatchParticleEffect("blood_impact_red_01",hitpos,VectorAngles(-player.GetEyeForward()),Entities.First()) 
	if (target.IsNPC()==true) if (target.GetRelationship(player)!=3&&target.GetModelName().find("manhack")==null&&target.GetModelName().find("turret")==null) DispatchParticleEffect(IsAlien ? "blood_impact_yellow_01" : (IsCorruptor ? "blood_impact_purple_01" : "blood_impact_red_01"),hitpos,VectorAngles(-player.GetEyeForward()),Entities.First()) 
		
	local impacteffect=CreateFireBulletsInfo(1, player.EyePosition(), hitpos-player.EyePosition(), Vector(), 0, player)
	impacteffect.SetTracerFreq(0)
	impacteffect.SetAmmoType(0)
	impacteffect.SetDamageForceScale(0)
	impacteffect.SetDamage(0)
	impacteffect.SetDistance(200)
	player.GetActiveWeapon().FireBullets(impacteffect)
		
	target.TakeDamage(Damage)
	
	if (target==null) {attackray.Destroy();DestroyDamageInfo(Damage);return}
	if (!("GetHealth" in target)) {attackray.Destroy();DestroyDamageInfo(Damage);return}
	try if (target.GetHealth()==null) {attackray.Destroy();DestroyDamageInfo(Damage);return}
	catch(exception){attackray.Destroy();DestroyDamageInfo(Damage);return}
	if (!target.IsNPC()) {attackray.Destroy();DestroyDamageInfo(Damage);return}
	local flinch="ACT_GESTURE_FLINCH_HEAD"
	if (target.LookupActivity("ACT_GESTURE_FLINCH_CHEST")!=-1) flinch="ACT_GESTURE_FLINCH_CHEST" 
	if (target.LookupActivity("ACT_FASTZOMBIE_FRENZY")!=-1) flinch="ACT_FASTZOMBIE_FRENZY" 
	if (target.LookupActivity("ACT_SMALL_FLINCH")!=-1) flinch="ACT_SMALL_FLINCH" 
	if ((Attacks%2)!=0&&(target.LookupActivity("ACT_GESTURE_FLINCH_RIGHTARM")!=-1)) flinch="ACT_GESTURE_FLINCH_RIGHTARM" 
	if ((Attacks%2)==0&&(target.LookupActivity("ACT_GESTURE_FLINCH_LEFTARM")!=-1)) flinch="ACT_GESTURE_FLINCH_LEFTARM" 
	//printl(target.IsNPC())
	if ((target)&&(target.IsNPC()==true)&&(target.GetHealth()>0)) {target.RemoveAllGestures();target.AddGesture(flinch,true);if (target.GetClassname()!="npc_citizen") target.SetSchedule("SCHED_FLINCH_PHYSICS");target.SetVelocity(target.GetVelocity()/10+playervelocity+(inverted_attackvector-player.ShootPosition())*Info.AttackForce/8.0)}
	//printl("Aw.. "+fabs(target.GetCycle()-damagecycle))
	attackray.Destroy();
	DestroyDamageInfo(Damage);
}

function InitWeapon(...)
{

	IncludeScript("weapons/weapon_base.nut")
	aPlayer=player.GetOrCreatePrivateScriptScope()
	
	local AttackAct="swing_light1"
	local Attacks=2
	local Stamina=Entities.FindByName(null,"stamina_system").GetOrCreatePrivateScriptScope()
	
	local WeaponInfo=
	{
		AmmoType="item_ammo_none"
		Model="models/weapons/v_sword.mdl"
		RecoilMult=10
		InAccuracy=10
		Damage=8
		BulletsPerShot=1
		IsShotgun=false
		Clip=1
		ShootSound="Weapon_Shotgun.Single"
		SemiAuto=false
		ReloadSound="Weapon_Shotgun.Reload"
		ReloadsSingly=false
		DrawSound="SW.Weapon.DrawSword"
		AttackCost=23
		
		
		Firerate=0.7
		AttackDelay=0.18
		AttackDuration=0.19
		RayDist=95
		RayStart=Vector(0,170,0)
		RayEnd=Vector(0,-170,0)
		ViewPSide=31
		ViewPDown=1
		AttackForce=15
		MinDamage=15
		DamagePerSpeed=0.1

		
		PrimaryAttack=function()
		{
			local Info=this.Info
		
			if (player.GetButtons() & IN.ATTACK&&nextattack<Time()&&(Auto||((!LastPress)&&(player.GetButtonLast() & IN.ATTACK))))
			{
				local VM=player.GetViewModel(0)
				
				VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_IDLE")))
				if (player.GetAuxPower()<AttackCost) return
				if (Time()<nextattack) return
				Stamina.PlayerRemoveStamina(AttackCost)
				AttackAct="swing_light"+((Attacks%2)+1).tostring()
				VM.SetSequence(VM.LookupSequence(AttackAct))
				
				nextattack=Time()+firerate
				VM.SetPlaybackRate(1.0)
				//LastStaminaTime=nextattack
				Attacks++
				
				local start=Info.RayStart
				local end=Info.RayEnd
				local viewpside=Info.ViewPSide
				
				if (Attacks%2==0)
				{
					start=-start
					end=-end
					viewpside=-viewpside
				}
				
				player.GetActiveWeapon().SetWeaponIdleTime(nextattack)
				
				Entities.First().SetContextThink("Melee_Viewpunch",function(...) {ViewP(viewpside,Info.ViewPDown)},Info.AttackDelay)
				
				for (local i=0;i<24.0;i++)
				{
					local a=i
					Entities.First().SetContextThink("Melee_Raycast"+i.tostring(),function(...) {FireRay(Gain(a/24.0,0.25),start,end,Info.RayDist,Attacks,Info)}.bindenv(this),Info.AttackDelay+Info.AttackDuration*(a/24.0))
				}
			}
		}
		
	}
	
	weapon=C_BaseWeapon("weapon_sword",WeaponInfo)
	Init(weapon)
}

function GetFireRate()
{
	return Time()+player.GetViewModel(0).SequenceDuration(player.GetViewModel(0).LookupSequence(AttackAct))*0.7*BulletTimeSpeed
}

function ItemPostFrame()
{
	ent<-null
	damagecycle<-1-0.58
	while (ent=Entities.FindByClassname(ent,"npc_combine_s"))
	{
		//if ((ent)&&(ent.GetActivity().find("ACT_MELEE_ATTACK")!=null)) printl(fabs(ent.GetCycle()-damagecycle)+" ")
		if ((ent)&&(ent.GetActivity().find("ACT_MELEE_ATTACK")!=null)&&(fabs(ent.GetCycle()-damagecycle)<PARRY_WINDOW))
		{
			//debugoverlay.Text(ent.EyePosition(),"PARRYABLE",0.015)
			//ent.SetRenderColor(255,0,0)
		}
		else
		{
			//ent.SetRenderColor(255,255,255)
		}
	}
	
	return true
}

Entities.EnableEntityListening()
Entities.First().SetContextThink(UniqueString("")+"SWORD",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}
