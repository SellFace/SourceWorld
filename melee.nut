//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Melee attack regardless of weapons player is wielding
//
// +attack3 to swing
//

const ATTACK_DELAY = 0.09;
const ATTACK_INTERVAL = 0.6;
const ATTACK_RANGE = 76.0;

self.PrecacheSoundScript("ep2_outland_11.hunter_bang_door")
self.PrecacheSoundScript("Weapon_Leg.Single")

local m_hCrowbar;

if ( SERVER_DLL )
{
	local Time = Time,
		RandomFloat = RandomFloat,
		RandomInt = RandomInt,
		Convars = Convars,
		CreateDamageInfo = CreateDamageInfo,
		DestroyDamageInfo = DestroyDamageInfo,
		TraceHullComplex = TraceHullComplex;

	local m_flNextAttackTime = 0.0;

	local ATTACK_HULL_MAX = Vector(4,4,8);
	local ATTACK_HULL_MIN = Vector(4,-4,-8);

	//
	// Leg model animation does not look good outside of viewmodel space,
	//
	// Create the prop on server because animation on client is not yet possible
	//
	local function AnimThink( player )
	{
		if ( m_hCrowbar.IsSequenceFinished() )
		{
			m_hCrowbar.Destroy();
			m_hCrowbar = null;

			local wep = player.GetActiveWeapon();
			if ( wep )
			{
				//NetProps.SetPropInt( wep, "m_bLowered", 0 );
				//wep.SendWeaponAnim( 173 ); // ACT_VM_IDLE
			}

			return -1;
		}

		m_hCrowbar.StudioFrameAdvance();

		return 0.0;
	}

	local function PlaySwingAnimation( player )
	{
		if ( m_hCrowbar && m_hCrowbar.IsValid() )
			m_hCrowbar.Destroy();

		m_hCrowbar = Entities.CreateByClassname("prop_dynamic");
		m_hCrowbar.SetModel("models/weapons/v_leg.mdl");
		m_hCrowbar.SetName("SW_LEG");
		m_hCrowbar.SetModelScale(0.35,0)
		m_hCrowbar.ResetSequenceInfo();
		m_hCrowbar.SetSequence( 1 );
		m_hCrowbar.SetCycle( 0.1 );
		m_hCrowbar.AddEffects( 16 );
		
		m_hCrowbar.AcceptInput("setviewhideflags","188",m_hCrowbar,m_hCrowbar)
		
		//if (Convars.GetFloat("host_timescale")<1) m_hCrowbar.SetPlaybackRate( 1.3 );
		//if (Convars.GetFloat("host_timescale")<1) m_hCrowbar.SetCycle( 0.10 );

		player.SetContextThink( "MeleeAttack.Anim", AnimThink, 0.0 );

		NetMsg.Start("MeleeAttack.Anim");
			m_hCrowbar.SetTransmitState( 8 );
			NetMsg.WriteEntity( m_hCrowbar );
		NetMsg.Send( player, true );
	}

	local function TraceAttack( player )
	{
		local vecStart = player.EyePosition()+Vector(0,0,-15);
		local viewForward = player.GetEyeForward();
		local vecEnd = viewForward.Multiply( ATTACK_RANGE ).Add( vecStart );

		local tr = TraceHullComplex( vecStart, vecEnd, ATTACK_HULL_MIN, ATTACK_HULL_MAX, player, MASK_SHOT_HULL, COLLISION_GROUP_NONE );
		local center=(vecEnd+vecStart)*0.5
		//debugoverlay.SweptBox(vecStart,vecEnd, ATTACK_HULL_MAX, ATTACK_HULL_MIN, ATTACK_HULL_MAX,200,200,12,2,1.0)

		//debugoverlay.EntityBounds( tr.Entity(), 255, 0, 255, 15, 3.0 )
		debugoverlay.SweptBox( vecStart, vecEnd, ATTACK_HULL_MIN, ATTACK_HULL_MAX, player.EyeAngles(), 255, 0, 0, 2, 3.0 );

		local pEnt = tr.Entity();
		if ( pEnt )
		{
			if ( pEnt.entindex() )
			{
				local playervelocity=player.GetVelocity()-pEnt.GetVelocity()*2
				local dmg = 12+(playervelocity).Length()/20;
				printl("DAMAGE: "+dmg)
				local endpos = tr.EndPos();
				local info = CreateDamageInfo( player, player, player.GetAutoaimVector( dmg * 3072. ), endpos, dmg, DMG_CLUB );
				info.SetDamageForce(player.GetEyeForward()*1000)
				info.SetAttacker(player)
				
				local lastent=pEnt
				
				if (pEnt.GetClassname()=="prop_door_rotating"&&!pEnt.IsDoorLocked())
				{
					EntFireByHandle(pEnt,"openawayfrom","!player",0.0)
					//if (pEnt.GetClassname()=="func_door_rotating") EntFireByHandle(pEnt,"open","",0.02);
					EntFireByHandle(pEnt,"setspeed","900",0.01)
					EntFireByHandle(pEnt,"setspeed","100",0.3)



					pEnt.ConnectOutput( "OnBlockedOpening", "KillBlocker" )
					
					function KillBlocker()
					{
						printl("BLOCKED by "+activator)
						if (activator==player) return;
						activator.SetHealth(activator.GetHealth()-50)
						local Damage=CreateDamageInfo(self,self,Vector(0,0,0),Vector(0,0,0),70,128)
						Damage.SetDamageForce((self.GetOrigin()-player.GetOrigin()).Normalized()*20000)
						EntFireByHandle(self,"setspeed","900",0.0)
						EntFireByHandle(self,"setspeed","135",0.3)
						activator.TakeDamage(Damage)
						DestroyDamageInfo(Damage);
						EntFireByHandle(self,"openawayfrom","!player",0)
						self.EmitSound("ep2_outland_11.hunter_bang_door")
						activator.EmitSound("ep2_outland_11.hunter_bang_door")
					}
					pEnt.ConnectOutput( "OnBlockedOpening", "KillBlocker" )
					
					
					local doororigin=pEnt.GetCenter()
					pEnt=null
					while (pEnt=Entities.FindByClassnameWithin(pEnt,"prop_door_rotating",doororigin,128))
					{
						if (pEnt==lastent) continue;
						
						EntFireByHandle(pEnt,"openawayfrom","!player",0.0)
						//if (pEnt.GetClassname()=="func_door_rotating") EntFireByHandle(pEnt,"open","",0.02);
						EntFireByHandle(pEnt,"setspeed","900",0.01)
						EntFireByHandle(pEnt,"setspeed","100",0.3)



						pEnt.ConnectOutput( "OnBlockedOpening", "KillBlocker" )
						
						function KillBlocker()
						{
							printl("BLOCKED by "+activator)
							if (activator==player) return;
							activator.SetHealth(activator.GetHealth()-50)
							local Damage=CreateDamageInfo(self,self,Vector(0,0,0),Vector(0,0,0),70,128)
							Damage.SetDamageForce((self.GetOrigin()-player.GetOrigin()).Normalized()*20000)
							EntFireByHandle(self,"setspeed","900",0.0)
							EntFireByHandle(self,"setspeed","135",0.3)
							activator.TakeDamage(Damage)
							DestroyDamageInfo(Damage);
							EntFireByHandle(self,"openawayfrom","!player",0)
							self.EmitSound("ep2_outland_11.hunter_bang_door")
							activator.EmitSound("ep2_outland_11.hunter_bang_door")
						}
						pEnt.ConnectOutput( "OnBlockedOpening", "KillBlocker" )
					}
					pEnt=lastent
					
				}
				
				
				if ( pEnt.GetTakeDamage() != DAMAGE_NO )
				{
					info.ScaleDamageForce((pEnt.GetVelocity()+playervelocity+player.GetEyeForward()*20*dmg).Length()/40)
					if (!(player.GetFlags()&1)&&SKILLS.Kick2.Unlocked) info.ScaleDamageForce(2.5)
					if (!(player.GetFlags()&1)&&SKILLS.Kick2.Unlocked) playervelocity*=2.5
					if (!(player.GetFlags()&1)&&SKILLS.Kick2.Unlocked) info.SetDamage(dmg*2)
					if (!(player.GetFlags()&1)&&SKILLS.Kick2.Unlocked) ShakePlayerScreen(200,6,0.2);
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

				//player.EmitSound( "Weapon_Crowbar.Melee_Hit" );
				player.EmitSound( tr.Surface().SurfaceProps().GetSoundImpactHard() );
				ShakePlayerScreen(200,4,0.2)
			}
			else
			{
				player.EmitSound( tr.Surface().SurfaceProps().GetSoundImpactHard() );
				ShakePlayerScreen(200,2,0.1)
			}

			player.ViewPunch( Vector( RandomFloat(0., 4.), 0., RandomFloat(3., 5.) ) );
			player.EmitSound( tr.Surface().SurfaceProps().GetSoundImpactHard() );
		}
		else
		{
			player.ViewPunch( Vector( RandomFloat(-2.5, 0.), 0., 2.5 ) );
		}
		player.EmitSound( "Weapon_Leg.Single" );
		tr.Destroy();
	}

	local function DoAttack( player )
	{
		if (GetMapName()=="tutorial") return	//sowwy, no kicking in tutorial level.
		if (!SKILLS.Kick.Unlocked) return
		
		if (("Weapon" in aPlayer)&&(aPlayer.Weapon.Name=="weapon_shield")) {aPlayer.Weapon.ForcePrimaryAttack();return};
		
		if (player.GetAuxPower()<52) return
		// Don't swing if dead or driving
		if ( !player.IsAlive() || player.GetVehicleEntity() )
			return;

		local curtime = Time();

		if ( curtime < m_flNextAttackTime )
			return;

		Entities.FindByName(null,"stamina_system").GetOrCreatePrivateScriptScope().PlayerRemoveStamina(52)

		m_flNextAttackTime = curtime + ATTACK_INTERVAL;

		local wep = player.GetActiveWeapon();

		if ( wep )
		{
			//NetProps.SetPropInt( wep, "m_bLowered", 1 );
			//wep.SendWeaponAnim( 203 ); // ACT_VM_IDLE_LOWERED
		}

		player.SetContextThink( "PlaySwingAnimation", PlaySwingAnimation, 0 );
		player.SetContextThink( "MeleeAttack", TraceAttack, ATTACK_DELAY * 2 );
		
	}

	NetMsg.Receive( "MeleeAttack", DoAttack );
	
	Convars.RegisterCommand( "+attack3", function(...)
	{
		DoAttack( player );
		return true;
	}, "", 0 );
}

if ( CLIENT_DLL )
{
	local LastAir=Time()
	
	local function AnimThink(_)
	{
		if ( m_hCrowbar.IsValid() && player.GetHealth()>0)
		{
			local origin = MainViewOrigin()
				.Subtract( MainViewForward().Multiply( -1.6 ) )
				.Subtract( MainViewUp().Multiply( 6 ) )

			local angles = MainViewAngles();
			angles.x += -15.0;
			angles.y -= 3.0;
			
			if ((!(player.GetFlags()&1)||(Time()-LastAir<0.5))&&SKILLS.Kick2.Unlocked)
			{
				angles.z -= 30.0;
				angles.y += 10.0;
				angles.x -= 10.0;
				origin.Subtract( MainViewUp() )
				if (Time()-LastAir>=0.5) LastAir=Time();
			}

			m_hCrowbar.SetLocalOrigin( origin );
			
			m_hCrowbar.SetLocalAngles( angles );

			return 0.0;
		}

		m_hCrowbar = null;

		return -1;
	}

	NetMsg.Receive( "MeleeAttack.Anim", function()
	{
		m_hCrowbar = NetMsg.ReadEntity();

		Entities.First().SetContextThink( "MeleeAttack.Anim", AnimThink, 0.0 );
	} );

	local function Attack()
	{
		NetMsg.Start( "MeleeAttack" );
		return NetMsg.Send();
	}
}
