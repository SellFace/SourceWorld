
IncludeScript("weapons/weapon_base.nut")
IncludeScript("base.nut")
self.PrecacheSoundScript("Weapon_Pipe.Hit")
self.PrecacheSoundScript("Weapon_Pipe.Crit")

local weapon=null




function Update(...)
{
	if (!weapon) return
	weapon.Update()
	return 0.005
}
::aPlayer<-null

local ViewP=function(side)
{
	local punch=Vector(RandomFloat(-0.01,-0.02),RandomFloat(0.1,0.2)*side,RandomFloat(0.05,0.07)*(-side))
	player.ViewPunch(punch)
}
local ViewP2=function(side)
{
	local punch=Vector(RandomFloat(-0.08,-0.12),RandomFloat(0.1,0.2)*side,RandomFloat(0.05,0.07)*(-side))
	player.ViewPunch(punch)
}

local StoppedAttack=-1
local StoppedTarget=null

local FireRay=function(angle,Attacks)
{
	local attackvector=player.ShootPosition()+((player.GetEyeRight()*pow(-1,Attacks))*angle+player.GetEyeForward()).Normalized()*75
	local inverted_attackvector=player.ShootPosition()+(((-player.GetEyeRight())*pow(-1,Attacks))*angle+player.GetEyeForward()).Normalized()*75
	local attackray=TraceLineComplex(player.ShootPosition(), attackvector,player,33570819,0)
	local target=attackray.Entity()
	//debugoverlay.Line(player.ShootPosition()+Vector(0,0,-5),attackvector,200,200,12,false,1.0)
	if (!target) {attackray.Destroy();return}
	if (StoppedAttack!=Attacks)
	{
		ViewP2(pow(-1,Attacks)*31)
		player.GetActiveWeapon().EmitSound("Weapon_Pipe.Hit")
	}
	if ((StoppedAttack==Attacks)&&(StoppedTarget==target)) {attackray.Destroy();return}
	StoppedAttack=Attacks
	StoppedTarget=target
	local playervelocity=player.GetVelocity()-target.GetVelocity()*2
	local Damage=CreateDamageInfo(player,player.GetActiveWeapon(),Vector(0,0,0),Vector(0,0,0),12+(playervelocity).Length()/20,128)
	//printl(12+(playervelocity).Length()/20)
	//printl(target.IsNPC())
	Damage.SetAttacker(player)
	Damage.SetDamageForce((attackvector-player.ShootPosition())*30+(player.GetEyeRight()*pow(-1,Attacks))*15*angle+playervelocity*2)
	if (target.IsNPC()==true) Damage.SetDamageForce((attackvector-player.ShootPosition())*130+(player.GetEyeRight()*pow(-1,Attacks+1))*6000*angle+playervelocity*40)
	Damage.SetDamagePosition(attackray.EndPos())
	local damagecycle=0.35
	if ((target)&&(target.IsNPC()==true))
	{
		if (target.GetSequenceName(target.GetSequence())=="attackE"||target.GetSequenceName(target.GetSequence())=="attackF") damagecycle=0.49
	}
	if ((target)&&(target.IsNPC()==true)&&(target.GetHealth()>0)&&(target.GetClassname()=="npc_zombie")&&(target.GetActivity()=="ACT_MELEE_ATTACK1")&&(fabs(target.GetCycle()-damagecycle)<0.11)) 
	{
		//target.SetLayerNoEvents(target.FindGestureLayer("ACT_MELEE_ATTACK1"),true)
		//target.SetLayerPlaybackRate(target.FindGestureLayer("ACT_MELEE_ATTACK1"),-1)
		attackray.Destroy();
		DestroyDamageInfo(Damage);
		//printl("PARRY! "+fabs(target.GetCycle()-damagecycle))
		local VM=player.GetViewModel(0)
		VM.SetSequence(VM.LookupSequence("hitcenter3"))
		
		player.EmitSound("Flesh.ImpactHard")
		player.EmitSound("Canister.ImpactHard")
		target.EmitSound("Canister.ImpactHard")
		target.EmitSound("Flesh.ImpactHard")
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
		target.SetVelocity(target.GetVelocity()/10+playervelocity/2+((player.GetEyeRight()*pow(-1,Attacks))+inverted_attackvector-player.ShootPosition())*3)
		player.SetVelocity(player.GetVelocity()+playervelocity/(-10)+((player.GetEyeRight()*pow(-1,Attacks))+inverted_attackvector-player.ShootPosition())*(-3))
		ViewP2(pow(-1,Attacks)*31)
		return
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
	if ((target)&&(target.IsNPC()==true)&&(target.GetHealth()>0)) {target.RemoveAllGestures();target.AddGesture(flinch,true);target.SetSchedule("SCHED_FLINCH_PHYSICS");target.SetVelocity(target.GetVelocity()/10+playervelocity+((player.GetEyeRight()*pow(-1,Attacks))+inverted_attackvector-player.ShootPosition())*4)}
	if ((12+(playervelocity).Length()/20)>45) 
	{
		printl("CRIT -"+(12+(playervelocity).Length()/20));
		target.AddGesture("ACT_FLINCH_RIGHTLEG",true);
		player.EmitSound("Weapon_Pipe.Hit");
		target.EmitSound("Weapon_Pipe.Hit");
		player.EmitSound("Weapon_Pipe.Crit")
		target.EmitSound("Flesh.Break")
		ViewP2(pow(-1,Attacks+1)*31)
		ViewP2(pow(-1,Attacks+1)*31)
		ViewP2(pow(-1,Attacks+1)*31)
	}
	//printl("Aw.. "+fabs(target.GetCycle()-damagecycle))
	attackray.Destroy();
	DestroyDamageInfo(Damage);
}

function InitWeapon(...)
{
	printl("weapon pipe inits i guess?")
	IncludeScript("weapons/weapon_base.nut")
	aPlayer=player.GetOrCreatePrivateScriptScope()
	weapon=C_BaseWeapon("weapon_mattpipe","None","models/weapons/v_pipe.mdl",0.065,1.5,0,5,"Weapon_SMG1.Single")
	local AttackAct="swing_light1"
	local Attacks=2
	local AttackCost=18
	local Stamina=Entities.FindByName(null,"stamina_system").GetOrCreatePrivateScriptScope()
	Init(weapon)
	weapon.PrimaryAttack=function (...)
	{
		local VM=player.GetViewModel(0)
		//player.RemoveAuxPower(0.1875)
		//if ((Time()-nextattack)<=0.1) player.RemoveAuxPower(0.1875);
		//if ((Time()-LastStaminaTime)>0.33&&!(player.GetButtons() & IN.SPEED)) player.AddAuxPower((Time()-LastStaminaTime)/5+0.002*player.GetAuxPower());
		if (player.GetButtons() & IN.ATTACK&&nextattack<Time())
		{
			if (player.GetAuxPower()<AttackCost) return
			Stamina.PlayerRemoveStamina(AttackCost)
			AttackAct="swing_light"+((Attacks%2)+1).tostring()
			VM.SetSequence(VM.LookupSequence(AttackAct))
			nextattack=Time()+VM.SequenceDuration(VM.LookupSequence(AttackAct))*0.6
			//LastStaminaTime=nextattack
			Attacks++
			player.GetActiveWeapon().SetWeaponIdleTime(nextattack)
			Entities.First().SetContextThink("Melee_Viewpunch",function(...) {ViewP(pow(-1,Attacks+1)*31)},VM.SequenceDuration(VM.LookupSequence(AttackAct))*0.2)
			for (local i=0;i<12;i++)
			{
				local a=i
				Entities.First().SetContextThink("Melee_Raycast"+i.tostring(),function(...) {FireRay((a+1)/6.0-1,Attacks)},VM.SequenceDuration(VM.LookupSequence(AttackAct))*0.25+i/100.0)
			}
		}
	}
}
Entities.EnableEntityListening()
ListenToGameEvent( "player_spawn", InitWeapon,"Init");
