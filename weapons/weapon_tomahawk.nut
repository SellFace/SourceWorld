
IncludeScript("weapons/weapon_base.nut")
IncludeScript("base.nut")
self.PrecacheSoundScript("Weapon_Pipe.Hit")
self.PrecacheSoundScript("Weapon_Pipe.Crit")
self.PrecacheSoundScript("SW.Weapon.DrawMelee")
self.PrecacheSoundScript("weapons/machete_swing.wav")
self.PrecacheSoundScript("weapons/axe_hit_flesh1.wav")
self.PrecacheSoundScript("weapons/melee_axe_01.wav")
self.PrecacheSoundScript("weapons/melee_axe_02.wav")
self.PrecacheSoundScript("weapons/melee_axe_03.wav")

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
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_tomahawk") return 0.005
	weapon.Update()
	return 0.005
}
::aPlayer<-null

local ViewP=function(side,down=1)
{
	local punch=Vector(RandomFloat(-0.01,-0.02)*down+RandomFloat(-0.09,-0.12)*(down-1),RandomFloat(0.1,0.2)*side,RandomFloat(0.05,0.07)*(-side))
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

local FireRay=function(mod,RayStart,RayEnd,RayDist,Attacks,AttacksRow)
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
		//player.GetActiveWeapon().EmitSound(Info.HitSound)
		ShakePlayerScreen(200,(playervelocity).Length()/100+2,0.1+(playervelocity).Length()/800)
		DispatchParticleEffect("blood_impact_synth_01_dust",hitpos,VectorAngles(-player.GetEyeForward()),target)
		local hitsound=EmitSound_t()
		hitsound.SetSoundName(attackray.Surface().SurfaceProps().GetSoundBulletImpact())
		hitsound.SetOrigin( hitpos )
		EmitSoundParamsOn(hitsound,Entities.First())
		
		hitsound=EmitSound_t()
		hitsound.SetSoundName(Info.HitSound)
		hitsound.SetOrigin( hitpos )
		EmitSoundParamsOn(hitsound,player.GetActiveWeapon())
	}
	DispatchParticleEffect("blood_impact_synth_01_dust",hitpos,VectorAngles(-player.GetEyeForward()),player.GetOrigin()) 
	if ((StoppedAttack==Attacks)&&(StoppedTarget==target)) {attackray.Destroy();return}
	StoppedAttack=Attacks
	StoppedTarget=target
	
	local Damage=CreateDamageInfo(player,player.GetActiveWeapon(),Vector(0,0,0),Vector(0,0,0),12+(playervelocity).Length()/20,128)
	Damage.SetAttacker(player)
	
	Damage.SetDamageForce((attackvector-player.ShootPosition())*Info.AttackForce+(player.GetEyeRight()*RayDir.y)*Info.AttackForce/2.0+playervelocity*2)
	
	if (target.IsNPC()==true) Damage.SetDamageForce((attackvector-player.ShootPosition())*Info.AttackForce*4+(player.GetEyeRight()*RayDir.y)*Info.AttackForce*22+playervelocity*40)
	else Damage.SetDamage(Info.MinDamage+(playervelocity).Length()*Info.DamagePerSpeed);
	Damage.SetDamagePosition(attackray.EndPos())
	local damagecycle=1-0.58
	if ((target)&&(target.IsNPC()==true))
	{
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
	//DispatchParticleEffect("blood_impact_red_01",hitpos,VectorAngles(-player.GetEyeForward()),Entities.First()) 
	
	if (target&&target.GetClassname().find("zombie")!=null&&attackray.HitGroup()!=1&&AttacksRow!=5)
	{
		//printl(Attacks)
		Damage.SetDamageType(DMG_SLASH+DMG_CRUSH)
		//Damage.SetDamage(Damage.GetDamage()*10)
	}
	
	if (target.IsNPC()==true) if (target.GetRelationship(player)!=3&&target.GetModelName().find("manhack")==null&&target.GetModelName().find("turret")==null) 
	{
		if (target.GetHealth()<=Damage.GetDamage())
		{
			local hitsound=EmitSound_t()
			hitsound.SetSoundName("weapons/melee_axe_0"+RandomInt(1,3)+".wav")
			hitsound.SetOrigin( hitpos )
			hitsound.SetVolume(0.5)
			EmitSoundParamsOn(hitsound,player.GetActiveWeapon())
		}
	
		DispatchParticleEffect(IsAlien ? "blood_impact_yellow_01" : "blood_impact_red_01",hitpos,VectorAngles(-player.GetEyeForward()),Entities.First()) 
	}	
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
	local AttacksRow=2
	local LastAttackTime=0;
	local Stamina=Entities.FindByName(null,"stamina_system").GetOrCreatePrivateScriptScope()
	
	local WeaponInfo=
	{
		AmmoType="item_ammo_none"
		Model="models/weapons/v_tomahawk.mdl"
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
		DrawSound="SW.Weapon.DrawMelee"
		AttackCost=13
		
		
		Firerate=0.7
		AttackDelay=0.2
		AttackDuration=0.2
		RayDist=90
		RayStart=Vector(35,2,0)
		RayEnd=Vector(-80,0.5,0)
		ViewPSide=1
		ViewPDown=35
		AttackForce=30
		MinDamage=15
		DamagePerSpeed=0.025
		
		MissSound="weapons/machete_swing.wav"
		HitSound="weapons/axe_hit_flesh1.wav"

		
		PrimaryAttack=function()
		{
			local Info=this.Info
		
			if (player.GetButtons() & IN.ATTACK&&nextattack<Time()&&(Auto||((!LastPress)&&(player.GetButtonLast() & IN.ATTACK))))
			{
				local VM=player.GetViewModel(0)
				
				VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_IDLE")))
				if (player.GetAuxPower()<AttackCost) return
				if (Time()<nextattack) return
				//AttackAct="swing_light"+((Attacks%2)+1).tostring()
				AttackAct="misscenter2"
				
				if (Time()-LastAttackTime>firerate+0.1) AttacksRow=2;
				
				LastAttackTime=Time()
				
				Attacks++
				AttacksRow++
				
				if (!(player.GetFlags()&1))
				{
					AttacksRow=5
				}
				
				switch(AttacksRow%3)
				{
					case 0:AttackAct="misscenter1";break;
					case 1:AttackAct="hitcenter3";break;
					case 2:AttackAct="misscenter2";break;
				}
				
				player.GetActiveWeapon().SendWeaponAnim(VM.LookupSequence(AttackAct))
				VM.SetSequence(VM.LookupSequence(AttackAct))
				
				nextattack=Time()+firerate
				VM.SetPlaybackRate(1.0)
				//LastStaminaTime=nextattack
				
				local start=Info.RayStart
				local end=Info.RayEnd
				local viewpside=Info.ViewPSide
				
				switch(AttacksRow%3)
				{
					case 0:
					{
						start=Vector(22,150,0)
						end=Vector(-28,-150,0)
						viewpside=Info.ViewPSide+31
						Info.AttackDelay=0.17
						Info.AttackDuration=0.15
						Info.ViewPDown=-7
						nextattack=Time()+firerate*0.8
						AttackCost=10
						break
					}
					case 1:
					{
						start=Vector(35,-150,0)
						end=Vector(-40,150,0)
						viewpside=Info.ViewPSide-31
						Info.AttackDelay=0.17
						Info.AttackDuration=0.15
						Info.ViewPDown=-7
						nextattack=Time()+firerate
						AttackCost=10
						break
					}
					case 2:
					{
						start=Info.RayStart
						end=Info.RayEnd
						viewpside=Info.ViewPSide
						Info.AttackDelay=0.2
						Info.AttackDuration=0.2
						Info.ViewPDown=-25
						nextattack=Time()+firerate*1.3
						AttackCost=15
						break
					}
				}
				
				Stamina.PlayerRemoveStamina(AttackCost)
				
				player.GetActiveWeapon().SetWeaponIdleTime(nextattack)
				
				player.EmitSound(Info.MissSound)
				Entities.First().SetContextThink("Melee_Viewpunch",function(...) {ViewP(viewpside,Info.ViewPDown)},Info.AttackDelay)
				
				for (local i=0;i<24.0;i++)
				{
					local a=i
					Entities.First().SetContextThink("Melee_Raycast"+i.tostring(),function(...) {FireRay(Gain(a/24.0,0.25),start,end,Info.RayDist,Attacks,AttacksRow)}.bindenv(this),Info.AttackDelay+Info.AttackDuration*(a/24.0))
				}
			}
		}
		
	}
	
	weapon=C_BaseWeapon("weapon_tomahawk",WeaponInfo)
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
Entities.First().SetContextThink(UniqueString("")+"Tomahawk",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}
