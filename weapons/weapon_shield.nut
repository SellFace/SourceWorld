
IncludeScript("weapons/weapon_base.nut")
IncludeScript("base.nut")
self.PrecacheSoundScript("Weapon_Pipe.Hit")
self.PrecacheSoundScript("Weapon_Pipe.Crit")
self.PrecacheSoundScript("SW.Weapon.DrawMelee")
self.PrecacheSoundScript("SW.Shield.Walk.R")
self.PrecacheSoundScript("SW.Shield.Walk.L")
self.PrecacheSoundScript("SW.Weapon.DrawShield")
self.PrecacheSoundScript("SW.Weapon.ShieldPush")

local weapon=null

::PARRY_WINDOW<-0.2

PrecacheParticleSystem("ricochet_sparks")

function Think5(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_shield") return 0.005
	weapon.Update()
	return 0.005
}
::aPlayer<-null

local StoppedAttack=-1
local StoppedTarget=null
local CanParry=false

local LastStep=0;
local RightStep=true;

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
		Model="models/weapons/v_shield.mdl"
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
		DrawSound="SW.Weapon.DrawShield"
		AttackCost=0
		
		
		Firerate=0.6
		AttackDelay=0.15
		AttackDuration=0.2
		RayDist=75
		RayStart=Vector(0,170,0)
		RayEnd=Vector(0,-170,0)
		ViewPSide=31
		ViewPDown=1
		AttackForce=30
		MinDamage=25
		DamagePerSpeed=0.025

		ForcePrimaryAttack=function()
		{
			local ATTACK_HULL_MAX = Vector(8,14,12);
			local ATTACK_HULL_MIN = Vector(8,-14,-8);
			local ATTACK_RANGE = 72.0;
			
			if (player.GetAuxPower()<40||nextattack>=Time()) return
			
			Entities.FindByName(null,"stamina_system").GetOrCreatePrivateScriptScope().PlayerRemoveStamina(40)
			
			printl("Attacking")
			nextattack=Time()+1;
			player.GetActiveWeapon().EmitSound("SW.Weapon.ShieldPush")
			
			local VM=player.GetViewModel(0)
			local AttackSequence=VM.SelectWeightedSequence(VM.LookupActivity("ACT_VM_PRIMARYATTACK"),1)
			
			player.GetActiveWeapon().SendWeaponAnim(AttackSequence)
			VM.SetSequence(AttackSequence)
			player.GetActiveWeapon().SetWeaponIdleTime(Time()+VM.SequenceDuration(AttackSequence))
			
			
			local vecStart = player.EyePosition()+Vector(0,0,-15);
			local viewForward = player.GetEyeForward();
			local vecEnd = viewForward.Multiply( ATTACK_RANGE ).Add( vecStart );

			local tr = TraceHullComplex( vecStart, vecEnd, ATTACK_HULL_MIN, ATTACK_HULL_MAX, player, MASK_SHOT_HULL, COLLISION_GROUP_NONE );
			local center=(vecEnd+vecStart)*0.5
			
			debugoverlay.SweptBox( vecStart, vecEnd, ATTACK_HULL_MIN, ATTACK_HULL_MAX, player.EyeAngles(), 255, 0, 0, 2, 3.0 );

			local pEnt = tr.Entity();
			if ( pEnt )
			{
				if ( pEnt.entindex() )
				{
					local playervelocity=player.GetVelocity()-pEnt.GetVelocity()*2
					local dmg = 15;
					printl("DAMAGE: "+dmg)
					local endpos = tr.EndPos();
					local info = CreateDamageInfo( player, player, player.GetAutoaimVector( dmg * 3072. ), endpos, dmg, DMG_CLUB );
					info.SetDamageForce(player.GetEyeForward()*2000)
					info.SetAttacker(player)		
					
					if ( pEnt.GetTakeDamage() != DAMAGE_NO )
					{
						//info.ScaleDamageForce(player.GetEyeForward()*20)
						if ((pEnt.IsNPC()==true)&&(pEnt.GetHealth()>0)) {if (pEnt.GetClassname()!="npc_citizen") pEnt.SetSchedule("SCHED_FLINCH_PHYSICS");pEnt.SetVelocity(pEnt.GetVelocity()+playervelocity+player.GetEyeForward()*20*dmg)}
						Entities.FindByName(null,"stamina_system").GetOrCreatePrivateScriptScope().PassesFinalDamageFilter(pEnt, info)
						pEnt.TakeDamage( info );
					}
					else
					{
						while ( (pEnt = pEnt.GetMoveParent()) && (pEnt.GetTakeDamage() != DAMAGE_NO) )
						{
							pEnt.TakeDamage( info );
							break;
						}
					}

					DestroyDamageInfo( info );

					player.EmitSound( tr.Surface().SurfaceProps().GetSoundImpactHard() );
					player.EmitSound( "MetalVent.ImpactHard" );
					ShakePlayerScreen(200,4,0.2)
				}
				else
				{
					player.EmitSound( tr.Surface().SurfaceProps().GetSoundImpactHard() );
					player.EmitSound( "MetalVent.ImpactHard" );
					ShakePlayerScreen(200,2,0.1)
				}

				player.ViewPunch( Vector( RandomFloat(0., 2.), 0., RandomFloat(1., 3.) ) );
				player.EmitSound( tr.Surface().SurfaceProps().GetSoundImpactHard() );
			}
			else
			{
				player.ViewPunch( Vector( RandomFloat(-1.5, 0.), 0., 1.5 ) );
			}
			tr.Destroy();
			
			
		}
		
		PrimaryAttack=function()
		{
			if (player.GetButtons() & IN.ATTACK&&nextattack<Time()&&(Auto||((!LastPress)&&(player.GetButtonLast() & IN.ATTACK))))
			{
				ForcePrimaryAttack()
			}
			return
		}
		
		
	}
	
	weapon=C_BaseWeapon("weapon_shield",WeaponInfo)
	Init(weapon)
}

function GetFireRate()
{
	return 1
}

function ItemPreFrame()
{
	if ((!("Weapon" in aPlayer))||aPlayer.Weapon.Name!="weapon_shield") return true;
	
	if (!("Blocking" in aPlayer.Weapon)) aPlayer.Weapon.Blocking<-false;
		
	ent<-null
	damagecycle<-1-0.58
	
	local VM=player.GetViewModel(0)
	
	if (VM.GetSequence()!=VM.LookupSequence("holster")) aPlayer.Weapon.Blocking=true;
	
	if (VM.GetSequence()==VM.LookupSequence("deploy")&&VM.GetCycle()<0.5) aPlayer.Weapon.Blocking=false;
	if (VM.GetSequence()==VM.LookupSequence("holster")&&VM.GetCycle()>0.5) aPlayer.Weapon.Blocking=false;
	
	local sInterval=(player.GetVelocity().Length()>300 ? 0.3 : 0.4)
	sInterval=(player.GetVelocity().Length()<100 ? 0.5 : sInterval)
	
	if ((Time()-LastStep>(sInterval))&&(player.GetFlags()&1)&&player.GetVelocity().Length()>50&&aPlayer.Weapon.Blocking)
	{
		LastStep=Time()
		RightStep=!RightStep;
		if (sInterval!=0.5) Entities.First().SetContextThink("ShieldSound",function(_) { player.EmitSound("SW.Shield.Walk."+(RightStep ? "R" : "L"))},0.2);
		else Entities.First().SetContextThink("ShieldSound",function(_) { player.GetActiveWeapon().EmitSound("SW.Shield.Walk."+(RightStep ? "R" : "L"))},0.2);
	}
	
	printl(aPlayer.Weapon.Blocking)
	
	return true
}


Entities.EnableEntityListening()
Entities.First().SetContextThink(UniqueString("")+"SHIELD",function(_) {weapon.Update();ItemPreFrame();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}
