IncludeScript("base.nut")
IncludeScript("changemap.nut")
IncludeScript("skills.nut")
IncludeScript("inventory.nut")
IncludeScript("phone.nut")
IncludeScript("music_manager.nut")
IncludeScript("rng_seed.nut")
IncludeScript("takedowns.nut")
IncludeScript("companions/companions.nut")

IncludeScript("player_client.nut")




local weapon=null
local LastStaminaTime=0
::PlayerExperience<-0.0
::PlayerMoney<-0.0
::PlayerMaxHeat<-50
::PlayerMaxHealth<-100
::PlayerHeat<-0
::PlayerSkillPoints<-0
::AbilitiesActive<-false
Entities.First().PrecacheSoundScript("player/rage.wav")
Entities.First().PrecacheSoundScript("BulletTime.Start")
Entities.First().PrecacheSoundScript("PlayerDeath")
Entities.First().PrecacheSoundScript("PlayerHurt")
Entities.First().PrecacheSoundScript("PlayerHurtBad")
Entities.First().PrecacheSoundScript("PlayerFall")
Entities.First().PrecacheSoundScript("BulletTime.Loop")
Entities.First().PrecacheSoundScript("BulletTime.Stop")
Entities.First().PrecacheSoundScript("weapon.ImpactSoft")
Entities.First().PrecacheSoundScript("weapon.StepLeft")
Entities.First().PrecacheSoundScript("Headshot")
Entities.First().PrecacheSoundScript("player/sprint.wav")
Entities.First().PrecacheSoundScript("player/decapitation.wav")
Entities.First().PrecacheSoundScript("ambient/wind/windgust_strong.wav")
Entities.First().PrecacheSoundScript("MetalVent.ImpactHard")

function PrecacheFootsteps()
{
	// I could've done this in much much fewer lines, but for some stupid reason precaching raw footstep noises with joined strings or format() does not work.
	// Looks like shit, but at least it works and i just have to not stare at this.
	
	player.PrecacheSoundScript("player/footsteps/metal/up1.wav")
	player.PrecacheSoundScript("player/footsteps/metal/up2.wav")
	player.PrecacheSoundScript("player/footsteps/metal/up3.wav")
	player.PrecacheSoundScript("player/footsteps/metal/up4.wav")
	player.PrecacheSoundScript("player/footsteps/metal/down1.wav")
	player.PrecacheSoundScript("player/footsteps/metal/down2.wav")
	player.PrecacheSoundScript("player/footsteps/metal/down3.wav")
	player.PrecacheSoundScript("player/footsteps/metal/down4.wav")
	player.PrecacheSoundScript("player/footsteps/metal/land1.wav")
	player.PrecacheSoundScript("player/footsteps/metal/walk1.wav")
	player.PrecacheSoundScript("player/footsteps/metal/walk2.wav")
	player.PrecacheSoundScript("player/footsteps/metal/walk3.wav")
	player.PrecacheSoundScript("player/footsteps/metal/walk4.wav")
	player.PrecacheSoundScript("player/footsteps/metal/walk5.wav")
	player.PrecacheSoundScript("player/footsteps/metal/walk6.wav")
	player.PrecacheSoundScript("player/footsteps/metal/run1.wav")
	player.PrecacheSoundScript("player/footsteps/metal/run2.wav")
	player.PrecacheSoundScript("player/footsteps/metal/run3.wav")
	player.PrecacheSoundScript("player/footsteps/metal/run4.wav")
	player.PrecacheSoundScript("player/footsteps/metal/run5.wav")
	player.PrecacheSoundScript("player/footsteps/metal/run6.wav")
	
	player.PrecacheSoundScript("player/footsteps/wood/up1.wav")
	player.PrecacheSoundScript("player/footsteps/wood/up2.wav")
	player.PrecacheSoundScript("player/footsteps/wood/up3.wav")
	player.PrecacheSoundScript("player/footsteps/wood/up4.wav")
	player.PrecacheSoundScript("player/footsteps/wood/down1.wav")
	player.PrecacheSoundScript("player/footsteps/wood/down2.wav")
	player.PrecacheSoundScript("player/footsteps/wood/down3.wav")
	player.PrecacheSoundScript("player/footsteps/wood/down4.wav")
	player.PrecacheSoundScript("player/footsteps/wood/land1.wav")
	player.PrecacheSoundScript("player/footsteps/wood/walk1.wav")
	player.PrecacheSoundScript("player/footsteps/wood/walk2.wav")
	player.PrecacheSoundScript("player/footsteps/wood/walk3.wav")
	player.PrecacheSoundScript("player/footsteps/wood/walk4.wav")
	player.PrecacheSoundScript("player/footsteps/wood/walk5.wav")
	player.PrecacheSoundScript("player/footsteps/wood/walk6.wav")
	player.PrecacheSoundScript("player/footsteps/wood/run1.wav")
	player.PrecacheSoundScript("player/footsteps/wood/run2.wav")
	player.PrecacheSoundScript("player/footsteps/wood/run3.wav")
	player.PrecacheSoundScript("player/footsteps/wood/run4.wav")
	player.PrecacheSoundScript("player/footsteps/wood/run5.wav")
	player.PrecacheSoundScript("player/footsteps/wood/run6.wav")
	
	
	player.PrecacheSoundScript("player/footsteps/tile/up1.wav")
	player.PrecacheSoundScript("player/footsteps/tile/up2.wav")
	player.PrecacheSoundScript("player/footsteps/tile/up3.wav")
	player.PrecacheSoundScript("player/footsteps/tile/up4.wav")
	player.PrecacheSoundScript("player/footsteps/tile/down1.wav")
	player.PrecacheSoundScript("player/footsteps/tile/down2.wav")
	player.PrecacheSoundScript("player/footsteps/tile/down3.wav")
	player.PrecacheSoundScript("player/footsteps/tile/down4.wav")
	player.PrecacheSoundScript("player/footsteps/tile/land1.wav")
	player.PrecacheSoundScript("player/footsteps/tile/walk1.wav")
	player.PrecacheSoundScript("player/footsteps/tile/walk2.wav")
	player.PrecacheSoundScript("player/footsteps/tile/walk3.wav")
	player.PrecacheSoundScript("player/footsteps/tile/walk4.wav")
	player.PrecacheSoundScript("player/footsteps/tile/walk5.wav")
	player.PrecacheSoundScript("player/footsteps/tile/walk6.wav")
	player.PrecacheSoundScript("player/footsteps/tile/run1.wav")
	player.PrecacheSoundScript("player/footsteps/tile/run2.wav")
	player.PrecacheSoundScript("player/footsteps/tile/run3.wav")
	player.PrecacheSoundScript("player/footsteps/tile/run4.wav")
	player.PrecacheSoundScript("player/footsteps/tile/run5.wav")
	player.PrecacheSoundScript("player/footsteps/tile/run6.wav")
	
	player.PrecacheSoundScript("player/footsteps/carpet/up1.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/up2.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/up3.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/up4.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/down1.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/down2.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/down3.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/down4.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/land1.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/walk1.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/walk2.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/walk3.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/walk4.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/walk5.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/walk6.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/run1.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/run2.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/run3.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/run4.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/run5.wav")
	player.PrecacheSoundScript("player/footsteps/carpet/run6.wav")
	
		
	player.PrecacheSoundScript("player/footsteps/dirt/up1.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/up2.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/up3.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/up4.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/down1.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/down2.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/down3.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/down4.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/land1.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/walk1.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/walk2.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/walk3.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/walk4.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/walk5.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/walk6.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/run1.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/run2.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/run3.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/run4.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/run5.wav")
	player.PrecacheSoundScript("player/footsteps/dirt/run6.wav")
	
	player.PrecacheSoundScript("player/footsteps/sand/land1.wav")
	player.PrecacheSoundScript("player/footsteps/sand/walk1.wav")
	player.PrecacheSoundScript("player/footsteps/sand/walk2.wav")
	player.PrecacheSoundScript("player/footsteps/sand/walk3.wav")
	player.PrecacheSoundScript("player/footsteps/sand/walk4.wav")
	player.PrecacheSoundScript("player/footsteps/sand/walk5.wav")
	player.PrecacheSoundScript("player/footsteps/sand/walk6.wav")
	player.PrecacheSoundScript("player/footsteps/sand/run1.wav")
	player.PrecacheSoundScript("player/footsteps/sand/run2.wav")
	player.PrecacheSoundScript("player/footsteps/sand/run3.wav")
	player.PrecacheSoundScript("player/footsteps/sand/run4.wav")
	player.PrecacheSoundScript("player/footsteps/sand/run5.wav")
	player.PrecacheSoundScript("player/footsteps/sand/run6.wav")
	
	player.PrecacheSoundScript("SW.Armor_Hit")
}

::_hashstr <- function( s )
{
	local l = s.len(), h = l, t = (l >> 5) | 1, i = 0;
	for ( ; l >= t; l -= t )
		h = h ^ ( (h<<5)+(h>>2)+s[i++] );
		
	printl(h)
	printl(format( "%u", h ))
	
	return h;
}

function Bullets(ent,speed,point,normal)
{
	printl("BULLET "+speed)
}

function Update(...)
{
}
::aPlayer<-null


::PlayerDefaultSpeed<-1
::PlayerWeaponSpeed<-1

local LastStep=0;

function SW_SetPlayerSpeed(a)
{
	Convars.SetFloat("sv_maxspeed",320*a)
	if (player.GetMoveType()==MOVETYPE_LADDER)
	{
		EntFire("player_speedmod","modifyspeed",0.8)
		EntFire("player_speedmod","modifyspeed",1,0.1)
		Entities.First().SetContextThink("unholstertimed",function(...){SendToConsole("temp_unholster")},0.05+0.5*(player.GetViewModel(0).GetModelName().find("blackout")==null).tointeger())
		SendToConsole("temp_holster")
			
	}
}

function PlayerRemoveStamina(amount)
{
	player.RemoveAuxPower(amount)
	LastStaminaTime=Time()
	if ((player.GetAuxPower())<=5) LastStaminaTime=Time()+1
}

if (CLIENT_DLL)
{
	//InitClient()
}

function CorruptorBlood(handle, info)
{
	if (handle.GetModelName().find("corrupt")==null) return false;
	printl(info.GetDamagePosition())
	PrecacheParticleSystem("blood_impact_purple_01")
	DispatchParticleEffect("blood_impact_purple_01",info.GetDamagePosition(),VectorAngles(-info.GetDamageForce()),player)
	
	return true;
}

if (SERVER_DLL)
{	
	
	Filter<-Entities.FindByName(null,"SW_DMG")
	

	if (!Filter)
	{
		local S={
			targetname="SW_DMG"
		}
		Filter=SpawnEntityFromTable("filter_script",S)
	}
	
	Shaker<-Entities.FindByName(null,"SW_SHAKE")
	
	Convars.RegisterConvar( "sw_shake" "1", "Toggles screen shake effect for attacks and other instances", FCVAR_NONE )


	local Sh={
		targetname="SW_SHAKE"
		frequency=200	// Not sure how it works, but setting it on low value makes shake be one-directional
		duration=0.2
		amplitude=5
		radius=0
		spawnflags=4	// Necessary to make it work when player is mid-air, thank god this spawnflag exists.
	}
	Shaker=SpawnEntityFromTable("env_shake",Sh)


	::DispatchEffect<-function(name,origin,angles)
	{
		local Target=SpawnEntityFromTable("info_target",{origin=origin.ToKVString(),angles=angles.ToKVString()});
		Target.AcceptInput("dispatcheffect",name,null,null)
		Target.Destroy()
	}.bindenv(this)
	
	/*
	::EmitSoundOnExpensive<-function(name,ent)
	{
		local Target=SpawnEntityFromTable("info_target",{origin=(ent.EyePosition()+ent.GetEyeForward()).ToKVString()});
		//EmitSoundOn(name,player)
		
		local s=EmitSound_t()
		
		s.SetSoundName(name)
		s.SetOrigin(player.GetOrigin())
		s.SetVolume(1)
		EmitSoundParamsOn(s,player)
		
		Target.Destroy()
	}.bindenv(this)
	*/
	
	::ShakePlayerScreen<-function(freq,amp,dur,Extended=false,RealDuration=0)
	{
		amp*=2
		dur*=2
		freq*=0.15
		if (Convars.GetInt("sw_shake")==0) return;
		if (!Shaker||!Shaker.IsValid()) Shaker=SpawnEntityFromTable("env_shake",Sh);
		Shaker.AcceptInput("frequency",freq.tostring(),null,null)
		Shaker.AcceptInput("amplitude",amp.tostring(),null,null)
		//Shaker.AcceptInput("duration",dur.tostring(),null,null)
		if (!RealDuration)Shaker.AcceptInput("addoutput","duration "+(Extended ? 0.3 : 0.2),null,null)
		else Shaker.AcceptInput("addoutput","duration "+RealDuration,null,null)
		EntFire("SW_SHAKE","StartShake")
	}.bindenv(this)
	
	PrimaryAttacks<-0
	Hits<-0
	
	PlayerPain<-0
	PlayerLastPain<-0
	
	function GetSimpleDamageType(info)
	{
		local type=info.GetDamageType()
		
		if ((type&DMG_SLASH)||(type&DMG_CLUB))
		{
			return "MELEE"
		}
		if (type&DMG_BLAST)
		{
			return "BLAST"
		}
		if ((type&DMG_BULLET)||(type&DMG_BUCKSHOT))
		{
			return "BULLET"
		}
		if (type&DMG_PLASMA)
		{
			return "ENERGY"
		}
		return
	}
	function GetDefenseValue(info,ItemEntry)
	{
		local resist=""
		
		//printl(info.GetDamageType())
		//printl(GetSimpleDamageType(info))
		
		switch (GetSimpleDamageType(info))
		{
			case "MELEE": resist="resist_melee";break;
			case "BULLET": resist="resist_bullet";break;
			case "BLAST": resist="resist_blast";break;
			case "ENERGY": resist="resist_energy";break;
		}
		if (resist!=""&&(resist in ItemEntry))
		{
			return ItemEntry[resist]
		}
		return 0
	}
	
	local penetrations=0;
	
	local HasShield=function(handle, info)
	{
		if (handle!=player) return false;
		
		local PlayerY=(handle.EyeAngles().y)
		local EnemyY=info.GetDamageForce().y
		if (info.GetAttacker()&&info.GetAttacker().IsValid())
		{
			
			printl(info.GetDamagePosition())
			printl(info.GetAttacker().GetCenter())
			printl((info.GetDamagePosition()-info.GetAttacker().GetCenter()).Length())
			
			EnemyY=VectorAngles(info.GetDamagePosition()-info.GetAttacker().GetCenter()).y;
			
			if ((info.GetDamagePosition()-info.GetAttacker().GetCenter()).Length()<5) 
				EnemyY=info.GetAttacker().GetAngles().y;
			
			if (info.GetAttacker().GetClassname().find("grenade")!=null)
			{
				EnemyY=VectorAngles(player.GetCenter()-info.GetAttacker().GetCenter()).y;
			}
		}
		
		printl("----  "+EnemyY)
		
		local Blockable=((180-abs( AngleDistance(EnemyY,PlayerY)))<60)
		
		printl((180-abs( AngleDistance(EnemyY,PlayerY) )))
		
		return (("Weapon" in aPlayer)&&("Name" in aPlayer.Weapon)&&aPlayer.Weapon.Name=="weapon_shield"&&Blockable&&aPlayer.Weapon.Blocking);
	}
	
	function PassesFinal(handle, info)	// should NOT modify damage, but this runs before blood particles
	{
		local passeddmg=0;
		if (handle==player&&(EQUIPMENT[0]!=null||EQUIPMENT[1]!=null||EQUIPMENT[2]!=null||HasShield(handle, info)||RageActive))
		{
			local totaldefense = EQUIPMENT[0]!=null ? GetDefenseValue(info,LIST_ITEMS[EQUIPMENT[0].tech_name]) : 0
			totaldefense += EQUIPMENT[1]!=null ? GetDefenseValue(info,LIST_ITEMS[EQUIPMENT[1].tech_name]) : 0
			totaldefense += EQUIPMENT[2]!=null ? GetDefenseValue(info,LIST_ITEMS[EQUIPMENT[2].tech_name]) : 0
			
			if (RageActive) totaldefense+=clamp(70,0,100-totaldefense);
			
			if (HasShield(handle, info))
			{
				totaldefense=max(totaldefense,98)
				printl("SHIELD HIT (BLOOD)")
			}
		
			local dmg=info.GetDamage()*(1-totaldefense/100.0)
			if (dmg<1&&(NetProps.GetPropFloat(player,"m_flDamageAccumulator")+(dmg-dmg.tointeger()))<1) {
				player.GetActiveWeapon().EmitSound((HasShield(handle, info)&&GetSimpleDamageType(info)!="BULLET") ? "MetalVent.ImpactHard" : "SW.Armor_Hit");
				NetProps.SetPropInt(player,"m_bloodColor",3)
			}
			else NetProps.SetPropInt(player,"m_bloodColor",0);
			
			passeddmg=dmg
		}
		else NetProps.SetPropInt(player,"m_bloodColor",0);
		
		//woo, penetration
		if (handle.GetClassname().find("npc")!=null&&(info.GetDamageType()&DMG_BULLET||info.GetDamageType()&DMG_BUCKSHOT)&&info.GetAttacker()==player&&("Weapon" in aPlayer)&&aPlayer.Weapon&&aPlayer.Weapon.IsShotgun)
		{
			if (RandomInt(0,1)==0) return true;
		
			debugoverlay.Line(info.GetDamagePosition(),info.GetDamagePosition()+info.GetDamageForce().Normalized()*64,255,30,30,true,3)
			
			local info2 = CreateFireBulletsInfo(1, info.GetDamagePosition(), info.GetDamageForce().Normalized(), Vector(), info.GetDamage(), info.GetAttacker())
			info2.SetTracerFreq(1)
			info2.SetDamage(info.GetDamage())
			info2.SetDamageForceScale(info2.GetDamage()*0.33)
			info2.SetAmmoType(3)
			info2.SetDistance(5000)
			info2.SetShots(1)
			info2.SetAttacker(info.GetAttacker())
			local a=info.GetAttacker()
			Entities.First().SetContextThink("penetration"+RandomInt(0,255),function(...){if (handle&&handle.IsValid()) info2.SetAdditionalIgnoreEnt(handle); a.GetActiveWeapon().FireBullets(info2)},0.01)
			//DestroyFireBulletsInfo(info2)
		}
		
		//if (HasShield(handle, info)&&GetSimpleDamageType(info)!="BULLET"&&(passeddmg+NetProps.GetPropFloat(player,"m_flDamageAccumulator"))<1) return false;
		
		return true
	}
	
	::LastRadiationDamage<-(-10)
	
	function PassesFinalDamageFilter(handle, info)
	{
		
		if (info.GetAttacker()&&info.GetAttacker().GetClassname()=="npc_zombie_torso")
		{
			info.SetDamage(info.GetDamage()*0.5)	// Crawlers do twice less damage than normal ones.
		}

		if (info.GetAttacker()&&info.GetAttacker().GetClassname()=="prop_ragdoll"&&info.GetAttacker().GetModelName().find("crab")==null)
		{
			info.SetDamage(clamp(info.GetDamage(),0,5))
		}
		
		if (handle.GetClassname()=="player")
		{
			
			local pos=info.GetAttacker().GetOrigin()-player.EyePosition()
			//printl(VectorAngles(pos).y-player.EyeAngles().y)
			local hurtsound=""
			
			//printl("TESTING PAIN "+PlayerPain)

			if ("GetName" in info.GetAttacker()&&info.GetAttacker().GetName().find("elevator")!=null)
			{
				printl("Player damaged by elevator!")
				info.SetDamage(1)
				if (Time()*2-(Time()*2).tointeger()>0.1) return false;
			}
			
			// === РАНГ: урон по игроку ===
			local rankDmgMult = 1.0 + (SW_DIFFICULTY_RANK / 5000.0) * 0.8;
			rankDmgMult = clamp(rankDmgMult, 0.5, 1.8);
			info.SetDamage(info.GetDamage() * rankDmgMult);
			
			local dmg=info.GetDamage();
			
			
			local hp=player.GetHealth()
			
			NetMsg.Start("DamageDirection")
			NetMsg.WriteFloat(VectorAngles(pos).y)
			
			
			if (handle==player&&(EQUIPMENT[0]!=null||EQUIPMENT[1]!=null||EQUIPMENT[2]!=null||HasShield(handle, info)||RageActive))
			{
				local totaldefense = EQUIPMENT[0]!=null ? GetDefenseValue(info,LIST_ITEMS[EQUIPMENT[0].tech_name]) : 0
				totaldefense += EQUIPMENT[1]!=null ? GetDefenseValue(info,LIST_ITEMS[EQUIPMENT[1].tech_name]) : 0
				totaldefense += EQUIPMENT[2]!=null ? GetDefenseValue(info,LIST_ITEMS[EQUIPMENT[2].tech_name]) : 0
				
				if (RageActive) totaldefense+=clamp(70,0,100-totaldefense)
				
				if (HasShield(handle, info))
				{
					totaldefense=max(totaldefense,98)
					printl("SHIELD HIT")
				}
			
				info.SetDamage(info.GetDamage()*(1-totaldefense/100.0))
				if (info.GetDamage()<1&&(NetProps.GetPropFloat(player,"m_flDamageAccumulator")+(info.GetDamage()-info.GetDamage().tointeger()))<1)
				{				
					handle.TakeDamage(info)
					//Entities.First().SetContextThink("afterdmg",function (_) { printl(format("Supposed reduction: %i%%. Real reduction: %i%%",95.0,100-((hp-player.GetHealth())/dmg)*100));return }.bindenv(this),0.05 )
					NetMsg.WriteBool(true)
					NetMsg.Send(player,true)
					return false;
				}
				
				//printl("DEFENSE")
				//printl(info.GetDamage())
				//printl(totaldefense)
				//NetProps.SetPropInt(player,"m_bloodColor",3)
				//Entities.First().SetContextThink("RestoreBloodColor",function(...){NetProps.SetPropInt(player,"m_bloodColor",0)},0.01)
			}
			NetMsg.WriteBool(false)
			NetMsg.Send(player,true)
			
			// === РАНГ: урон по игроку ===
			local dmgTaken = info.GetDamage();
			SW_AddRank(-(dmgTaken * 2).tointeger());
			if (dmgTaken > 30) SW_AddRank(-50);
			SW_LAST_DAMAGE_TIME = Time();
		
			PlayerPain+=info.GetDamage();
			PlayerPain+=info.GetDamageBonus();
			
			
			if (PlayerPain>=15)
			{
				hurtsound="PlayerHurt"
			}
			if (PlayerPain>=30)
			{
				hurtsound="PlayerHurtBad"
			}
			//printl("Pain "+PlayerPain)
			//printl("Playing sound "+hurtsound)
			if ((Time()-PlayerLastPain)>1&&hurtsound!=""&&player.GetHealth()>info.GetDamage()) 
			{
				player.EmitSound(hurtsound);
				PlayerLastPain=Time();
				
			}
			if (hurtsound!="")
			{
				PlayerHeat=clamp(PlayerHeat-(info.GetDamage()/5).tointeger(),0,PlayerMaxHeat)
				SyncPlayerStats()
				if (info.GetDamageType()!=DMG_PREVENT_PHYSICS_FORCE) ShakePlayerScreen(100,100*(1+(hurtsound=="PlayerHurtBad").tointeger()),1,(hurtsound=="PlayerHurtBad"));
			}
			
			SW_TABLE.iDamageTaken+=info.GetDamage().tointeger()
			
		}
		
		//if (handle.GetName()=="testtarget") EntFire("dmgshow","SetText",info.GetDamage())
		//if (handle.GetName()=="testtarget") EntFire("dmgshow","Display")
			
		//printl(info.GetInflictor())
		
		if (handle==player&&info.GetAttacker()&&"GetActiveWeapon" in info.GetAttacker()&&info.GetAttacker().GetActiveWeapon()&&info.GetAttacker().GetActiveWeapon().GetClassname()=="weapon_stunstick")
		{
			SW_ApplyStatusEffect("STUN",player,4)
		}
		
		if (handle==player&&info.GetDamageType()==DMG_POISON)
		{
			SW_ApplyStatusEffect("POISON",player,RemapValClamped(info.GetDamage(),0,100,2,13).tointeger())
			PlayerPain-=info.GetDamage();
			return false
		}
		
		if (handle==player&&info.GetDamageType()&DMG_RADIATION)
		{
			LastRadiationDamage=Time()
		}
		
		if ((info.GetDamageType()==DMG_SLASH+DMG_CRUSH)&&handle.IsAlive()&&handle.GetClassname()=="npc_combine_s")
		{
			info.SetDamageType(DMG_SLASH)
			// Change damage type just to slash, so we don't cut combine soldiers in half.
			
			// For some strange reason trying to cut combine soldiers in half crashes the game. This is obviously due to non-existing gib models, but this is like part of vanilla hl2.
			// Does that mean cutting combines in half with ravenholm traps cause hl2 to crash too?
		}
		
		if (info.GetDamageType()&DMG_SLASH&&handle.IsAlive()&&(RandomInt(1,6)==1)&&((!handle.IsNPC())||handle.GetRelationship(player)!=3))
		{
			SW_ApplyStatusEffect("BLEED",handle,RemapValClamped(info.GetDamage(),0,50,5,30).tointeger())
			//PlayerPain-=info.GetDamage();
		}
		
		printl(info.GetDamageType())
		printl(info.GetDamageType())
		printl(info.GetDamageType())
		printl(info.GetDamageType())
		
		if (handle==player&&info.GetDamageType()&DMG_BLAST&&RemapValClamped(info.GetDamage(),-10,100,0,10).tointeger()>1)
		{
			SW_ApplyStatusEffect("STUN",player,RemapValClamped(info.GetDamage(),-10,100,0,10).tointeger())
		}
		
		if (info.GetDamageType()&DMG_BULLET&&handle.IsAlive()&&(RandomInt(1,20)==1))
		{
			SW_ApplyStatusEffect("BLEED",handle,RemapValClamped(info.GetDamage(),0,25,RandomInt(1,5)*2,RandomInt(6,15)*2).tointeger())
			//PlayerPain-=info.GetDamage();
		}
		
		if ((handle.GetClassname().find("npc")!=null||handle.GetClassname().find("ragd")!=null||handle==player)&&(info.GetDamageType()|2||info.GetDamageType()|536870912))
		{
			local IsOrganic=(handle.GetModelName().find("turret")==null&&handle.GetModelName().find("manhack")==null)
			
			
			
			if (handle.GetNumBones()>15&&IsOrganic&&(handle.GetClassname().find("npc")==null||handle.GetRelationship(player)!=3)) 
			{
				local blood="Blood_s"
				local bloodimpact="Impact.Flesh"
				
				local trace=TraceLineComplex(info.GetDamagePosition(),info.GetDamagePosition()+info.GetDamageForce(),Entities.First(),MASK_SHOT,0)
				
				local IsAlien=(handle.GetModelName().find("crab")!=null||(handle.GetModelName().find("zombie")!=null&&handle.GetBodygroup(1)&&trace.HitGroup()==1))
				local IsCorruptor=(handle.GetModelName().find("corrupt")!=null)
				
				if (IsAlien)
				{
					blood="YellowBlood"
					bloodimpact="YellowBlood"
				}
				
				if (IsCorruptor)
				{
					blood="PurpleBlood"
					bloodimpact="PurpleBlood"
				}
				
				if (handle.IsNPC()) if (handle.GetRelationship(player)==3) blood=""
				//printl(info.GetDamage())
				//if (GetMapName().find("mapgens")!=null) blood="Bloods"
				local dmgtrace=TraceLineComplex(info.GetDamagePosition(),info.GetDamagePosition()+info.GetDamageForce().Normalized()*100,handle,MASK_SHOT,1)
				for (local i=0;i<2;i++)
				{
				local dmgtrace2=TraceLineComplex(info.GetDamagePosition(),info.GetDamagePosition()+(info.GetDamageForce().Normalized()+Vector(RandomFloat(-1,1),RandomFloat(-1,1),-1))*100,handle,MASK_SHOT,1)
				if (info.GetDamagePosition().DistTo(Vector())>1) DecalTrace(dmgtrace2,blood)
				dmgtrace2.Destroy()
				}
				if (info.GetDamagePosition().DistTo(Vector())>1) DecalTrace(dmgtrace,blood)
				dmgtrace.Destroy()
				
				
				local trace=TraceLineComplex(info.GetDamagePosition(),info.GetDamagePosition()+info.GetDamageForce(),Entities.First(),MASK_SHOT,0)
				if (trace.HitGroup()==1) handle.EmitSound("Headshot")
				if (trace.HitGroup()==1&&handle.GetHealth()<=info.GetDamage())
				{
					handle.GetOrCreatePrivateScriptScope().KilledByHeadshot<-true
				}
				if (trace.HitGroup()==1) info.SetDamage(info.GetDamage()*1.5)
				//printl(info.GetDamage());
				if (trace.HitGroup()==1&&handle.GetHealth()<=info.GetDamage()) handle.EmitSound("Headshot")
				if (trace.HitGroup()==1&&handle.GetHealth()<=info.GetDamage()) handle.EmitSound("Headshot")
				trace.Destroy()
				if (handle.GetClassname().find("ragd")!=null&&info.GetDamage()>10) handle.StopSound("Flesh.Break")
				if (handle.GetClassname().find("ragd")!=null&&info.GetDamage()>10) handle.EmitSound("Flesh.Break")
				if (handle.GetClassname().find("ragd")!=null&&info.GetDamage()>20&&IsCorruptor) DispatchParticleEffect("blood_impact_purple_01",info.GetDamagePosition(),Vector(),handle)
				if (handle.GetClassname().find("ragd")!=null&&info.GetDamage()>20&&!IsAlien&&!IsCorruptor) DispatchParticleEffect("blood_impact_red_01",info.GetDamagePosition(),Vector(),handle)
				if (handle.GetClassname().find("ragd")!=null&&info.GetDamage()>20&&IsAlien) DispatchParticleEffect("blood_impact_yellow_01",info.GetDamagePosition(),Vector(),handle)
				if (handle.GetName()=="player_body"&&info.GetDamage()>10) LastDmgTime=Time()
					
				local CenterVec=(handle.GetCenter()-info.GetDamagePosition()).Normalized()
				CenterVec*=3;
				CenterVec.z=0;
				local dmgimpact=TraceLineComplex(info.GetDamagePosition()-CenterVec,info.GetDamagePosition()+CenterVec,player,MASK_SHOT,0)
				if (info.GetDamage()>=handle.GetHealth()) bloodimpact=blood;	// If deathblow, get more bloody
				if (info.GetDamagePosition().DistTo(Vector())>1) DecalTrace(dmgimpact,bloodimpact);
				dmgimpact.Destroy()
				//debugoverlay.Line(info.GetDamagePosition()-info.GetDamageForce().Normalized()*5,info.GetDamagePosition()+info.GetDamageForce().Normalized()*5,255,30,30,true,2)
			}
		}
		//printl(info.GetAttacker())
		//printl(info.GetWeapon())
		//printl(clamp(info.GetDamage(),0,handle.GetMaxHealth()))
		
		if (!("GetOwner" in info.GetAttacker())) return true;
		
		if ((info.GetAttacker()==player||info.GetAttacker().GetOwner()==player)&&info.GetDamageType()==2) PrimaryAttacks++;
		
		if (handle.GetClassname().find("npc")!=0||(info.GetAttacker()!=player&&info.GetAttacker().GetOwner()!=player)) return true;
		//printl(handle.GetRelationship(player))
		//printl(info.IsForceFriendlyFire())
		if ("GetRelationship" in handle&&handle.GetRelationship(player)==3) info.SetDamagePosition(Vector(0,0,0));
		if ("GetRelationship" in handle&&handle.GetRelationship(player)==3) info.SetDamage(0);
		Hits++
		if (!AbilitiesActive&&!(Entities.FindByName(null,"PlayerModel"))) 
		{
			PlayerHeat+=clamp(info.GetDamage(),0,handle.GetHealth())/10.0;
		}
		//AddPlayerXP(clamp(info.GetDamage(),0,handle.GetMaxHealth())/5)
		PlayerHeat=clamp(PlayerHeat,0,PlayerMaxHeat)
		SyncPlayerStats()
		if (info.GetAttacker().GetClassname()=="weapon_dual_pistols") info.SetDamage(info.GetDamage()*2.33)
		
	
		return true
	}
	


	Hooks.Add(Filter.GetOrCreatePrivateScriptScope(),"PassesFinalDamageFilter",PassesFinalDamageFilter.bindenv(this),"PassesFinalDamageFilter");
	Hooks.Add(Filter.GetOrCreatePrivateScriptScope(),"PassesDamageFilter",PassesFinal.bindenv(this),"PassesFinal");
	Hooks.Add(Filter.GetOrCreatePrivateScriptScope(),"BloodAllowed",function (handle, info) {if (CorruptorBlood(handle,info)||(info.GetAttacker().GetOwner()==player&&handle.GetRelationship(player)==3)) return false; else return true}.bindenv(this),"PassesFinal2");
	
}

/*
if (CLIENT_DLL)
{
	local dummy=null
	if (dummy!=null) return
	dummy = vgui.CreatePanel("Panel", vgui.GetRootPanel(), "ScreenDummy")
	dummy.MakeReadyForUse()
	dummy.SetVisible(true)
	function CheckCheats()
	{
		if (Convars.GetBool("sv_cheats")==true)
		{
			printl("\n\nDo not cheat, please!\n")
			Convars.SetBool("sv_cheats",false)
		}
	}
	dummy.SetCallback( "Paint", CheckCheats.bindenv(this) )
}*/

function ForcePrimaryAttack(...)
{
	printl("FORCING PRIMARY FIRE")
	player.ForceButtons(IN.ATTACK)
	//player.GetActiveWeapon().SetNextPrimaryAttack(PrevNextPrimaryAttack)
	Entities.First().SetContextThink("UnForceFiring",function (_) { player.UnforceButtons(IN.ATTACK);return }.bindenv(this),0.05 )
	return
}
::forceattack<-ForcePrimaryAttack

function ProcessDualWeapons()
{
	if (!player.GetActiveWeapon()) return;
	if (player.GetActiveWeapon().GetClassname().find("dual")==null) return;
	return
}

RageActive<-false;
local RageStartTime=0;

if (SERVER_DLL)
{
	function TempThirdperson(dur=3)
	{
		local Dist=150
		local speed=5.0
		local StartTime=Time()
		
		SendToConsole("thirdperson")
		SendToConsole("crosshair 0")
		SendToConsole("cam_idealdist 0")
		SendToConsole("cam_idealdistup -30")
		
		player.AddFlag(32)
		
		Entities.First().SetContextThink("TempThirdperson",function (_) 
		{ 
		
			local prog=((Time()-StartTime))
			if (prog>dur*0.5) prog=(dur-(Time()-StartTime))
			
			local speed2=speed*(0.1+pow(0.5-prog,2)*4)
		
			if (Convars.GetFloat("cam_idealdist")<Dist&&(Time()-StartTime)<(2/speed)) Convars.SetFloat("cam_idealdist",Convars.GetFloat("cam_idealdist")+speed2)
				
			if ((Time()-StartTime)>(dur-2/speed)) Convars.SetFloat("cam_idealdist",Convars.GetFloat("cam_idealdist")-speed2)
				
			if ((Time()-StartTime)>dur)
			{
				SendToConsole("firstperson")
				SendToConsole("crosshair 1")
				player.RemoveFlag(32)
				return 
			}
				
			return 0.01
		
		}.bindenv(this),0.01 )
	}
	function Rage()
	{
		if (RageActive||PlayerHeat<100) return;
		
		AddPlayerHeat(-100)
		
		RageActive=true
		RageStartTime=Time()
		TempThirdperson(player.SequenceDuration(player.LookupSequence("rage"))-0.2)
		//player.FastRemoveLayer(1)
		player.AddGestureSequence("rage", true)
		player.AddGestureSequence("rage", true)
		//player.SetLayerAutokill(1,false)
		
		Entities.First().PrecacheSoundScript("player/rage.wav")
		player.PrecacheSoundScript("PlayerRage")
		Entities.First().SetContextThink("RageSound2",function (_) 
		{ 
			player.EmitSound("PlayerRage")
		}.bindenv(this),0.2 )
		
		Entities.First().SetContextThink("RageSound",function (_) 
		{ 
			Entities.First().EmitSound("player/rage.wav")
			//Entities.First().EmitSound("player/rage.wav")
		}.bindenv(this),0.5 )
		
		Entities.First().SetContextThink("RageEnd",function (_) 
		{ 
			RageActive=false
			SendToConsole("host_pitchscale 1")
		}.bindenv(this),15 )
		
		NetMsg.Start("Rage");
		NetMsg.Send(player, true);
	}
}

change<-Time()

local Holstered=false;
local DamageAngle=0;

local FallTime=Time()-10
function PlayerFalling()
{
	if (FallTime+10>Time()) return;
	player.EmitSound("PlayerFall")
	FallTime=Time()
}

local LastCombat=Time()-100
local LastCombatStart=Time()
local InCombat=false

function GetRandomMusic(excluded="")
{
	local Music=[
	"covenant_terror",
	"opening",
	"the_library",
	"aftermath",
	"hecu_takeover"
	"morphine"
	"abandoned_facility"
	"malfunction"
	"stars"
	"drums"
	"the_ring"
	]
	local Track=Music[RandomInt(0,Music.len()-1)];
	while (Track==excluded) Track=Music[RandomInt(0,Music.len()-1)];
	
	return Track
}
function GetRandomCombatMusic(excluded="")
{
	local Music=[
	"disturbed_and_powerful",
	"acid_breakbeat_death_jam",
	"methods",
	"mayhem",
	"combat3",
	"overdrive",
	"abra"
	]
	local Track=Music[RandomInt(0,Music.len()-1)];
	while (Track==excluded) Track=Music[RandomInt(0,Music.len()-1)];
	
	return Track
}

::SW_AMBIENT<-((GetMapName().find("mapgen")!=null) ? GetRandomMusic() : "reconciliation")
if (GetMapName().find("sw_")!=null) SW_AMBIENT="";

::SW_COMBAT<-GetRandomCombatMusic()

::SW_MUSIC_OVERRIDE<-""

::SW_CAPTIONS<-[]

::SW_NO_DYING<-false;

::SW_RESPAWN_SPOT<-[Vector(),Vector()]	//pos and angles

::SW_BOSS_ACTIVE<-false;
::SetBossStatus<-function(status)
{
	SW_BOSS_ACTIVE=status
	NetMsg.Start("SetBossStatus")
	NetMsg.WriteBool(status)
	NetMsg.Send(player,true)
}
::SetBossName<-function(name)
{
	NetMsg.Start("SetBossName")
	NetMsg.WriteString(name)
	NetMsg.Send(player,true)
}
//SW_CAPTIONS.append(["Hi, Jack!","Richard"])

if (SERVER_DLL)
{
	::SWCaption<-function(text,actor) 
	{
		//SW_CAPTIONS.append(["Hi, Jack!","Richard",Time()])
		NetMsg.Start("SWCaption");
		NetMsg.WriteString(text)
		NetMsg.WriteString(actor)
		NetMsg.Send(player, true);
		Entities.FindByName(null,actor).AddLookTarget(player,0.8,5,0)
		Entities.FindByName(null,actor).GetExpresser().Speak("TLK_SO_PEEK","")
	}
	
	::SWHint<-function(text,sound=true) 
	{
		NetMsg.Start("SWHint");
		NetMsg.WriteString(text)
		NetMsg.Send(player, true);
		if (sound) SendToConsole("play ui/hint")
	}
	
	::SWSmallNotification<-function(text,color=Vector(0,180,255)) 
	{
		NetMsg.Start("SWSmallNotification");
		NetMsg.WriteString(text)
		NetMsg.WriteByte(color.x)
		NetMsg.WriteByte(color.y)
		NetMsg.WriteByte(color.z)
		NetMsg.Send(player, true);
	}
	
	::SWBigNotification<-function(text,color=Vector(0,180,255),dur=13,fade=4) 
	{
		NetMsg.Start("SWBigNotification");
		NetMsg.WriteString(text)
		NetMsg.WriteByte(color.x)
		NetMsg.WriteByte(color.y)
		NetMsg.WriteByte(color.z)
		NetMsg.WriteFloat(dur)
		NetMsg.WriteFloat(fade)
		NetMsg.Send(player, true);
	}
	
	::SWRadio<-function(id,ShouldContinue=false) 
	{
		NetMsg.Start("SWRadio");
		NetMsg.WriteShort(id)
		NetMsg.WriteBool(ShouldContinue)
		NetMsg.Send(player, true);
	}
	//self.ConnectOutput( "OutUser1","Capty")
}

local LastAir=(-10);
local LastMoan=(-999);
RightStep<-true;

FootStep<-function()
{
	local bobmult=2;
	
	//printl(Time()-LastStep)
	
	LastStep=Time();
	
	NetMsg.Start("FootStep");
	NetMsg.Send(player, true);
	
	RightStep=!RightStep;
	bobmult=player.GetVelocity().Length()/80.0
	if (player.GetMoveType()==MOVETYPE_LADDER) bobmult*=15;
	if ((player.GetHealth()<=20)&&!RightStep) bobmult*=2.5;
	player.ViewPunch(Vector(0.1,0,RightStep ? 0.1 : -0.1)*bobmult);
}

function Capty(a,b)
{
	switch(a)
	{
		case 1: SWCaption("Got something to tell me?",b);break;
		case 2: SWCaption("I think I saw you before... I'm not sure.",b);break;
		case 3: SWCaption("You look familiar...",b);break;
		case 4: SWCaption("Try to stay out of trouble.",b);break;
		case 5: SWCaption("I think we met at the bar before?",b);self.SetContextThink("VoiceLineAgain",function(...){SWCaption("No... No, I confuse you for somebody else, sorry.",b)}.bindenv(this),6);break;
		case 6: SWCaption("Get lost.",b);break;
		case 7: SWCaption("Are you looking for trouble?",b);break;
		case 8: SWCaption("This is not your first time seeing me, this time, not behind the bars.",b);break;
		case 9: SWCaption("Still looking for trouble? Get lost.",b);break;
		case 101: SWCaption("Sir, I can't let you pass until you put on your protective vest.",b);break;
		case 102: SWCaption("Lunin, you need to put on that vest first.",b);break;
		case 103: SWCaption("Did you hear what instructor said? Get your vest.",b);break;
		case 104: SWCaption("Have you lost your vest? Go get it!",b);break;
		case 105: SWCaption("Alright. One moment.",b);break;
		case 106: SWCaption("Here, you can go now.",b);break;
	}
}

if (SERVER_DLL) SW_MUS.Reset()
	
Unstuck<-false
Unstuck2<-false
StuckTime<-0;

local origins=Vector(0,0,0)
local reald=0
local time=0

local LastBreathTime=0;

local BadCrouches=0

local weaponmodel=null

local lastplayeranim=null

local LastOrigin=Vector();
local LastOrigin2=Vector();
local LastOrigin3=Vector();
local LastOrigin4=Vector();
local LastOrigin5=Vector();
local LastOrigin6=Vector();
local LastOrigin7=Vector();
local LastOrigin8=Vector();
local LastOrigin9=Vector();
local LastOriginReal=Vector();

local LastMusicChangeTime=0

function Think()
{
	if (Time()>(180+LastMusicChangeTime)&&(!InCombat)&&((Time()-LastCombat)>20))
	{
		if (GetMapName().find("mapgen")!=null) 
		{
			SW_AMBIENT=GetRandomMusic(SW_AMBIENT)
			SW_COMBAT=GetRandomCombatMusic(SW_COMBAT)
		}
		LastMusicChangeTime=Time()
	}
	
	if (player.GetVehicleEntity())
	{
		//printl(player.GetVehicleEntity().GetPhysics().GetSteering());
		
		//EntFire("engine","pitch",(clamp(RemapVal(player.GetVehicleEntity().GetPhysics().GetRPM(),0,5000,60,200),100,255)))
		//EntFire("engine","volume",10)
		
		//RPMLast=player.GetVehicleEntity().GetPhysics().GetRPM()
	}
	else
	{
		EntFire("engine","volume",0)
	}
	
	if (GetNamedEnt("Eric")&&RandomInt(1,100)==1) GetNamedEnt("Eric").AddGestureSequence("katana_hold",false);
	
	if (!AbilitiesActive)
	{
		//if (PlayerHeat>0) PlayerHeat-=0.01;
		PlayerHeat=clamp(PlayerHeat,0,PlayerMaxHeat)
		//SyncPlayerStats()
	}
	
	if (RageActive)
	{
		local mod=1-clamp(Time()-RageStartTime-1,0,0.1)
		
		player.AddAuxPower(100-player.GetAuxPower())
		SendToConsole("host_pitchscale "+mod)
		player.ViewPunch(Vector(RandomInt(-1,1),RandomInt(-1,1),RandomFloat(-1,1))*0.06)
		
		Convars.SetInt("dsp_room",26)
		Convars.SetFloat("dsp_volume",10)
		if (Time()-RageStartTime>14||Time()-RageStartTime<1) Convars.SetInt("dsp_room",0)
		if (Time()-RageStartTime>14||Time()-RageStartTime<1) Convars.SetFloat("dsp_volume",1)
	}

	//local Accuracy=0
	//if (PrimaryAttacks==0) Accuracy=100.0;
	//else Accuracy=Hits.tofloat()/PrimaryAttacks*100.0;
	//printl("Accuracy: "+format("%.2f",Accuracy))
	//printl(PrimaryAttacks)
	//printl(Hits)
	
	local SP=player.GetVelocity().Length()
	
	LastOriginReal=LastOrigin9
	LastOrigin9=LastOrigin8
	LastOrigin8=LastOrigin7
	LastOrigin7=LastOrigin6
	LastOrigin6=LastOrigin5
	LastOrigin5=LastOrigin4
	LastOrigin4=LastOrigin3
	LastOrigin3=LastOrigin2
	LastOrigin2=LastOrigin
	LastOrigin=player.GetOrigin()
	
	if (!(player.GetFlags()&1)) LastAir=Time();
	
	//player.ViewPunch(Vector(1*cos(Time()*2),1*sin(Time()),0)*SP*IntervalPerTick()*0.01);
	
	if (player.GetHealth()<20)
	{
		local mod=clamp(1-(player.GetHealth()*5)/100.0,0,1)
		
		ShakePlayerScreen(0.15*mod,0.1*mod,0.1,true);
	}
	
	if (player.GetHealth()<20&&player.GetHealth()>0&&Time()>LastMoan)
	{
		// Bitch and moan once in a while
		if ((Time()-LastMoan)>5)
		{
			LastMoan=Time()+RandomInt(10,25)/(1+(player.GetHealth()<10).tointeger())
			
		}
		else
		{
			LastMoan=Time()+RandomInt(15,45)/(1+(player.GetHealth()<10).tointeger())
			PlaySoundAtPlayer("vo/npc/male01/moan0"+RandomInt(1,4)+".wav",0.1*(1+(player.GetHealth()<10).tointeger()))
		}
	}
	
	if (player.GetHealth()>0&&player.GetVelocity().z<(-400)&&TraceLine(player.GetOrigin(),player.GetOrigin()-Vector(0,0,500),player)>(0.9)&&!player.IsNoclipping())
	{
		PlayerFalling()
	}
	local s2=EmitSound_t()
	if (player.GetVelocity().z<(-500))
	{
		s2.SetVolume(clamp(RemapVal(player.GetVelocity().z,-500,-1500,0,2),0,1))
		s2.SetFlags(1+2+128)
		s2.SetSoundName("ambient/wind/windgust_strong.wav")
		s2.SetOrigin(player.GetOrigin())
	}
	else
	{
		s2.SetVolume(0)
		s2.SetFlags(1+2)
		s2.SetSoundName("ambient/wind/windgust_strong.wav")
		player.StopSound("ambient/wind/windgust_strong.wav")
	}
	EmitSoundParamsOn(s2,player)
	
	if (Time()<(7+StuckTime)&&GetMapName().find("mapgen")==null) if (TraceHullComplex(player.GetOrigin(),player.GetOrigin(),player.GetBoundingMins(),player.GetBoundingMaxs(),player,MASK_PLAYERSOLID,0).DidHit()&&!player.IsNoclipping())
	{
		
		local spacedown=TraceHullComplex(player.GetOrigin()+Vector(0,0,16),player.GetOrigin()-Vector(0,0,128),player.GetBoundingMins(),player.GetBoundingMaxs(),player,MASK_SHOT,0).Fraction()
		if (Time()>(3+StuckTime)&&(!Unstuck)&&Time()<(3.5+StuckTime)) {SWHint("Did you get stuck just now?");Unstuck=true}
		if (0<spacedown&&Time()>(StuckTime+6)&&Unstuck)
		{
			o<-Entities.FindByClassname(null,"info_player_start").GetOrigin()
			
			local Node=AINetwork.NearestNodeToPoint(player.GetOrigin(),false)
			local NodePos=AINetwork.GetNodePosition(Node)
			
			//if (GetMapName()=="teleporting_room_v1") EntFireByHandle(player,"setabsorigin",473 -520 405)
			if (GetMapName()=="teleporting_room_v1") EntFireByHandle(player,"setabsorigin",473+" "+(-520)+" "+405);
			else if (GetMapName()=="demo_city") EntFireByHandle(player,"setabsorigin",2213+" "+(-4078)+" "+(-1500));
			else if (Node!=null) EntFireByHandle(player,"setabsorigin",NodePos.ToKVString());
			else EntFireByHandle(player,"setabsorigin",o.ToKVString());
			printl("unstucking from ceiling!")
			if (!Unstuck2) {SWHint("There. Be careful next time please.");Unstuck2=true}
		}
	}
	
	local npc=null
	local Enemies=0
	
	while (npc=Entities.FindByClassname(npc,"npc*"))
	{
		if (npc.GetClassname()=="npc_tripmine") continue;
		//if (npc.GetModelName().find("hgrunt")!=null) SW_COMBAT="surface_tension";
		//if (npc.GetModelName().find("combine")!=null) SW_COMBAT="they_here_for_you";
		//if (npc.GetModelName().find("zomb")!=null) SW_COMBAT="penultimatum";
		//if (npc.GetModelName().find("metro")!=null) SW_COMBAT="they_here_for_you";
		
		if ("GetEnemy" in npc&&npc.GetEnemy()==player&&player.GetHealth()>0) 
		{
			Enemies++;
			//printl("IN COMBAT "+(npc.GetOrigin()-player.GetOrigin()).Length())
		}
		if (SW_COMPANIONS[0]!=null&&GetNamedEnt(SW_COMPANIONS[0])&&("GetEnemy" in npc)&&npc.GetEnemy()==GetNamedEnt(SW_COMPANIONS[0])&&GetNamedEnt(SW_COMPANIONS[0]).IsAlive()) 
		{
			Enemies++;
			//printl("IN COMBAT "+(npc.GetOrigin()-player.GetOrigin()).Length())
		}
		if (SW_COMPANIONS[1]!=null&&GetNamedEnt(SW_COMPANIONS[1])&&("GetEnemy" in npc)&&npc.GetEnemy()==GetNamedEnt(SW_COMPANIONS[1])&&GetNamedEnt(SW_COMPANIONS[1]).IsAlive()) 
		{
			Enemies++;
			//printl("IN COMBAT "+(npc.GetOrigin()-player.GetOrigin()).Length())
		}
	}
	
	local MusicOverride=(SW_MUSIC_OVERRIDE!="")
	
	if (!MusicOverride&&Enemies>2&&GetMapName().find("teleporting_room_v1")==null)
	{
		if (!InCombat) LastCombatStart=Time();
		//if (npc.GetName().find("enemy")!=null) if (!InCombat) EntFire(npc.GetName().slice(0,4)+"*","UpdateEnemyMemory","!player")
		if (InCombat&&LastCombatStart+1<Time()) SW_MUS.PlaySmooth(SW_COMBAT,5);
		InCombat=true
		LastCombat=Time()
	}
	//printl(clamp(7-(Time()-LastCombat),0,7).tointeger())
	if (!MusicOverride&&((LastCombat+2<Time()&&Enemies==0)||(LastCombat+15<Time()&&Enemies>0))&&player.GetHealth()>0) 
	{
		InCombat=false;
		SW_MUS.PlaySmooth(SW_AMBIENT,clamp(20-(Time()-LastCombat),1,7).tointeger());
		//else SW_MUS.PlaySmooth("",clamp(20-(Time()-LastCombat),1,7).tointeger());
	}
	if (MusicOverride&&player.GetHealth()>0)
	{
		SW_MUS.PlaySmooth(SW_MUSIC_OVERRIDE,1);
	}
	
	if (Time()-Time().tointeger()<0.02&&(Time()-change)>Convars.GetFloat("host_timescale")*3)
	{
		//SendToConsole("mapbase_rpc_enabled 0")
		SendToConsole("cl_discord_override 1")
		aweapon<-null;
		if (player.GetActiveWeapon()&&"Weapon" in aPlayer) aweapon=LIST_ITEMS[aPlayer.Weapon.Name].name;
		else aweapon="None"
		
		
		//Mapbase.SetDiscordBigImageText("Health:"+player.GetHealth()+"/"+player.GetMaxHealth()+" Armour:"+player.GetArmor()+"/100 Heat:"+format("%0.1f",PlayerHeat)+"/"+format("%0.1f",PlayerMaxHeat)+" Weapon:"+aweapon)
		//SendToConsole("cl_discord_largeimage_text Health:"+player.GetHealth()+"/"+player.GetMaxHealth()+" Armour:"+player.GetArmor()+"/100 Heat:"+format("%0.1f",PlayerHeat)+"/"+format("%0.1f",PlayerMaxHeat)+" Weapon:"+aweapon)
		SendToConsole("cl_discord_largeimage neat_icon")
		

		SendToConsole("cl_discord_override 1")
		//SendToConsole("cl_discord_largeimage neat_icon")
		//SendToConsole("cl_discord_state ❬In-Game❭ [ LVL "+((1+0.07*sqrt(PlayerExperience)).tointeger()).tostring()+" ]"+" [ $"+PlayerMoney.tostring()+" ]")
		//SendToConsole("cl_discord_details Map: "+GetMapName())
		//SendToConsole("mapbase_discord_update")
		local Location=""
		switch (GetMapName())
		{
			case "teleporting_room_v1": Location="Laboratory";break;
			case "demo_city": Location="District 64";break;
			case "city_d64_v2": Location="District 64";break;
			case "mapgen_level": Location=format("World %X",Globals.GetCounter(Globals.GetIndex("InitialRNGSeed")));break;
			case "mapgen_day": Location=format("World %X",Globals.GetCounter(Globals.GetIndex("InitialRNGSeed")));break;
			case "weapons_range": Location="Dev Room";break;
			default: Location=GetMapName();
		}
		local PlayerLVL=(1+0.07*sqrt(PlayerExperience))
		
		
		NetMsg.Start("RPCInfo")	// Order of strings is: state, details, largeimagetext.
		NetMsg.WriteString(format("❬ %s ❭", Location))
		NetMsg.WriteString(format("LVL %i | $%i", PlayerLVL, PlayerMoney))
		NetMsg.WriteString(format("Health:%i/%i Armour:%i/100 Heat:%0.1f/%0.1f Weapon:%s", player.GetHealth(), player.GetMaxHealth(), player.GetArmor(), PlayerHeat, PlayerMaxHeat, aweapon))
		NetMsg.Send( player, true )
		
		SendToConsole("mapbase_discord_update")
		
		//SendToConsole("mapbase_discord_update")
		change=Time()
	}
	player.RemoveAuxPower(0.1875)	//Passive drain to prevent automatic regeneration
	if (player.GetButtons() & IN.SPEED) LastStaminaTime=Time();
	
	
	if (player.GetButtons() & IN.SPEED&&player.GetVelocity().Length()<5&&!(player.GetFlags() & FL_DUCKING)) 
	{
		if ("Weapon" in aPlayer &&("Scoped" in aPlayer.Weapon.Info)&&aPlayer.Weapon.Info.Scoped)
		{
			player.AddAuxPower(-0.1);
		}
		else player.AddAuxPower(0.1875*2);
	}
	// 	FOLLOWING LINE MAKES STAMINA 2X LESS DRAIN WHEN SPRINTING WITH NO WEAPONS
	
	//player.AddAuxPower(0.3)
	
	if (aPlayer&&(!("Weapon" in aPlayer)||!aPlayer.Weapon)&&player.GetButtons() & IN.SPEED) player.AddAuxPower(0.1875)
	
	//if ((player.GetAuxPower())<=5&&(player.GetButtons() & IN.SPEED)) LastStaminaTime=Time()+1

	if ((player.GetAuxPower())<=12)
	{
		player.DisableButtons(IN.SPEED)
	}
	else player.EnableButtons(IN.SPEED);
	
	if (player.GetAuxPower()<5) PlayerDefaultSpeed=(player.GetAuxPower()/40.0)+0.2;
	else PlayerDefaultSpeed=1;
	
	SW_SetPlayerSpeed(min(PlayerDefaultSpeed,PlayerWeaponSpeed))
	
	// Disabled for being an annoying-ass feature, thanks volvo for making flashlight count as a weapon.
	//if (player.GetButtons() & IN.SPEED) EntFire("logic_playerproxy","lowerweapon");
	//if (player.GetButtons() & IN.SPEED) EntFire("player_speedmod","enable","0");
	//else if (!Holstered) EntFire("player_speedmod","disable","0");
	
	local IsStanding=(!(player.GetButtons() & IN.FORWARD)&&!(player.GetButtons() & IN.BACK)&&!(player.GetButtons() & IN.MOVELEFT)&&!(player.GetButtons() & IN.MOVERIGHT))
	
	if ((!SKILLS.StaminaRecovery.Unlocked||!IsStanding)&&(Time()-LastStaminaTime)>0.33&&!(player.GetButtons() & IN.SPEED)) player.AddAuxPower((Time()-LastStaminaTime)/5+0.002*player.GetAuxPower());	//start regenerating when not attacking.
	if ((SKILLS.StaminaRecovery.Unlocked&&IsStanding)&&(Time()-LastStaminaTime)>0.165&&!(player.GetButtons() & IN.SPEED)) player.AddAuxPower((Time()-LastStaminaTime)/2.5+0.002*player.GetAuxPower());	//start regenerating when not attacking.
	//local cam=Entities.FindByName(null,"player_thirdperson_camera")
	local s=EmitSound_t()
	if (player.GetAuxPower()<5&&(Time()-LastBreathTime)>2)
	{
		LastBreathTime=Time()
		s.SetSoundName("player/sprint.wav")
		s.SetOrigin(player.GetOrigin())
		s.SetFlags(128+2+1)
		s.SetVolume(clamp(RemapVal(sqrt(player.GetAuxPower()*0.01)*100,0,80,0.1,0),0,1))
		if (player.GetAuxPower()<10) s.SetVolume(1);
		EmitSoundParamsOn(s,player)
		//printl("sound")
	}
	s.SetVolume(clamp(RemapVal(sqrt(player.GetAuxPower()*0.01)*100,5,80,0.2,0),0,1))
	s.SetFlags(1+2+128)
	s.SetSoundName("player/sprint.wav")
	s.SetOrigin(player.GetOrigin())
	//printl(0.5-player.GetAuxPower()/100.0)
	EmitSoundParamsOn(s,player)
	//cam.SetLocalOrigin(pos-player.GetEyeForward()*20)
	//cam.SetVelocity((pos-player.GetEyeForward()*20)-cam.GetOrigin())
	//printl(cam.GetEffects())
	//cam.RemoveEFlags(12845056)
	//cam.AddFlag(FL_GRAPHED)
	//cam.AddEFlags(8388608)
	//cam.SetVelocity(Vector(0,0,1110))
	//cam.SetParent(player,"")
	//cam.SetLocalOrigin(player.EyePosition()-player.GetEyeForward()*20+player.GetEyeRight()*10)
	//cam.SetLocalAngles(player.EyeAngles())
	//printl((player.GetButtons()&IN.DUCK)&&(player.GetFlags()&FL_DUCKING))
	//printl((player.GetOrigin()-player.EyePosition()).z)
	
	//printl(player.GetSequenceActivityName(player.GetSequence()))
	local playerActivity=player.GetSequenceActivityName(player.GetSequence())
	if (player.GetActiveWeapon()&&"Weapon" in aPlayer&&aPlayer.Weapon)
	{
		local wmodel=LIST_ITEMS[aPlayer.Weapon.Name].model	
		if (!weaponmodel)
		{
			weaponmodel=SpawnEntityFromTable("prop_dynamic_ornament",{model=wmodel})
			EntFireByHandle(weaponmodel,"setattached","!player")
			EntFireByHandle(weaponmodel,"DisableShadow","")
		}
		if (weaponmodel&&weaponmodel.IsValid()&&weaponmodel.GetModelName()!=wmodel) {weaponmodel.SetModel(wmodel);};
		
		local holdtype=LIST_ITEMS[aPlayer.Weapon.Name].holdtype
		
		local sequenceID=player.SelectHeaviestSequence(player.LookupActivity(playerActivity+"_"+holdtype))
		
		//printl(player.GetLayerActivity(1))

		if (player.GetLayerActivity(1)!=(playerActivity+"_"+holdtype)&&(!RageActive)) 
		{
			player.FastRemoveLayer(1)
			player.AddGesture(playerActivity+"_"+holdtype, true)
			player.SetLayerLooping(1,true)
			//player.SetLayerDuration(1,30)
			player.SetLayerAutokill(1,false)
		}
		
		lastplayeranim=sequenceID;
	}
	if (!("Weapon" in aPlayer)&&weaponmodel) {weaponmodel.Destroy();weaponmodel=null;lastplayeranim=null;player.FastRemoveLayer(1)}
	
	if (((player.GetButtons()&IN.DUCK)&&(player.GetFlags()&FL_DUCKING))==2&&(player.GetOrigin()-player.EyePosition()).z<(-30))
	{
		//	This is kinda rude idk. What if someone does it by accident?
		//
		//if (BadCrouches>10)
		//{
		//	SWHint("NO, you cannot do that.");
		//	player.GetActiveWeapon().EmitSound("Flesh.Break")
		//	player.TakeDamage(CreateDamageInfo(player,player,player.GetOrigin(),Vector(),BadCrouches,0))
		//}
		//else SWHint("Schrodinger's crouch detected!");
		//
		//
		//
		//BadCrouches++
		
		player.RemoveFlag(FL_DUCKING)
	}
	
	
	local eyepos=player.EyePosition()+player.GetEyeForward()*100
	
	//EntFireByHandle(player,"changevariable", "m_viewtarget "+eyepos.x.tointeger()+" "+eyepos.y.tointeger()+" "+eyepos.z.tointeger(),0)
	player.SetViewtarget(eyepos)
	//printl("m_viewtarget "+eyepos.x.tointeger()+" "+eyepos.y.tointeger()+" "+eyepos.z.tointeger())
	
	
	if (PlayerPain>45) PlayerPain=clamp(PlayerPain-0.5,0,100);
	else if (PlayerPain>30) PlayerPain=clamp(PlayerPain-0.3,0,100);
	else if (PlayerPain>15) PlayerPain=clamp(PlayerPain-0.1,0,100);
	else PlayerPain=clamp(PlayerPain-0.1,0,100);
	
	//printl("PAIN LEVEL: "+PlayerPain)
	
	// Раз в 5 секунд применяем буфер ранка
	if (Time() - SW_LAST_RANK_UPDATE > 5.0)
	{
		SW_ApplyRankBuffer();
	}
	
	
	return 0.0
}
Entities.EnableEntityListening()
Convars.SetInt("r_nearz",-1)

local DeathScreamPlayed=false

Drunkness<-0

PrecacheParticleSystem("blood_impact_red_01")
local Blood2 = {
	effect_name = "blood_impact_red_01",
	start_active = 1,
}

::LastDmgTime<-Time()-100


// DIFFICULTY RANKS

::SW_RANK_BUFFER <- 0;   // integer
::SW_LAST_RANK_UPDATE <- 0.0;
::SW_LAST_KILL_TIME <- 0.0;
::SW_LAST_DAMAGE_TIME <- 0.0;
::SW_LAST_INVENTORY_CHECK <- 0.0;

::SW_AddRank <- function(delta)
{
    SW_RANK_BUFFER += delta;
}

::SW_CACHED_INV_MULT <- 1.0;
::SW_LAST_INVENTORY_CHECK <- 0.0;

::SW_ApplyRankBuffer <- function()
{
    if (SW_RANK_BUFFER == 0) return;
    
    // Инерция от ранка
    local inertia = 1.0;
    if (SW_DIFFICULTY_RANK > 2500) inertia = 0.5;
    else if (SW_DIFFICULTY_RANK < -2500) inertia = 1.5;
    
    // Множитель от инвентаря
    local invMult = SW_GetInventoryMultiplier();
    
    // Финальное изменение
    local finalDelta = (SW_RANK_BUFFER * inertia * invMult).tointeger();
    
    // Если буфер положительный, а инвентарь пустой — рост тормозится
    // Если буфер отрицательный, а инвентарь пустой — падение ускоряется
    if (SW_RANK_BUFFER > 0 && invMult < 1.0)
        finalDelta = (SW_RANK_BUFFER * invMult).tointeger();
    else if (SW_RANK_BUFFER < 0 && invMult < 1.0)
        finalDelta = (SW_RANK_BUFFER / invMult).tointeger();   // усиление штрафа
    
    SW_DIFFICULTY_RANK = clamp(
        SW_DIFFICULTY_RANK + finalDelta,
        -5000, 5000);
    
    printl("[DIFFICULTY] Buffer " + SW_RANK_BUFFER + " × inertia " + inertia + " × inv " + invMult + " = " + finalDelta + " → rank " + SW_DIFFICULTY_RANK);
    
    SW_RANK_BUFFER = 0;
    SW_LAST_RANK_UPDATE = Time();
}


function CheatDeath(info,model="models/player.mdl",silent=false)
{
	if (SW_NO_DYING)
	{
		player.SetHealth(1)
		info.SetDamage(0)
		if (GetNamedEnt("PlayerModel")) return false;	// if player dies AGAIN when there's playermodel, just deny it fully.
		
		if (("Weapon" in aPlayer)&&aPlayer.Weapon) GetNamedEnt("stamina_system").GetScriptScope().IntroAction("downed",aPlayer.Weapon.Name)
		else GetNamedEnt("stamina_system").GetScriptScope().IntroAction("downed","",false)
	
		EntFire("PlayerCamera","SetParentAttachment","eyes")
		SendToConsole("fadeout "+(player.SequenceDuration(player.LookupSequence("downed"))-0.25))
		Hooks.Call("Player_Incap",null)
		player.SetHealth(25)
		player.EmitSound("PlayerDeath")
		
		Entities.First().SetContextThink("PlayerRevive",function(_){
			local RevivePos=SW_RESPAWN_SPOT[0]
			local ReviveAng=SW_RESPAWN_SPOT[1]
			player.SetOrigin(RevivePos)
			player.SetAngles(ReviveAng)
			SendToConsole("fadein 2")
			
		}.bindenv(this),player.SequenceDuration(player.LookupSequence("downed"))+1)
		
		return false
	}
	
	if (model=="models/player.mdl"&&(info.GetDamageType()&DMG_SLASH)&&RandomInt(1,50)<info.GetDamage())
	{
		player.SetModel("models/player_headless.mdl")
		
		DeathScreamPlayed=true
		
		plr<-player
		eyes<-plr.LookupAttachment("eyes")
		pos<-plr.GetAttachmentOrigin(eyes)
		ang<-plr.GetAttachmentAngles(eyes)
		
		pos=pos-AngleVectors(ang)*4-AngleVectors(ang+Vector(90,0,0))*4
		
		model="models/player_headless.mdl"
		
		local head_table={model="models/player_head.mdl",origin=pos.ToKVString(),angles=ang.ToKVString()}
		local head=SpawnEntityFromTable("prop_physics",head_table)
		head.SetCollisionGroup(1)
		
		head.GetPhysicsObject().SetMass(15)
		head.GetPhysicsObject().ApplyForceOffset(info.GetDamageForce(),head.GetCenter());
		
		head.EmitSound("player/decapitation.wav")
		player.EmitSound("player/decapitation.wav")
		info.SetDamageForce(Vector())
		
		Entities.First().SetContextThink("So-No-Head?",function(_)
		{
			
			plr=Entities.FindByName(null,"player_body")
			if (!plr) return 0.01;
			head.SetCollisionGroup(0)
			eyes<-plr.LookupAttachment("eyes")
			pos<-plr.GetAttachmentOrigin(eyes)
			ang<-plr.GetAttachmentAngles(eyes)
			
			pos=pos-AngleVectors(ang)*5+AngleVectors(ang+Vector(90,0,0))*1
			
			if (Time()-LastDmgTime<0.2) head.GetPhysicsObject().ApplyForceOffset((pos-head.GetCenter())*100,head.GetCenter());
			
			if (Time()-LastDmgTime<1)
			{
				DispatchParticleEffectParented("blood_impact_red_01",pos,ang,player)
				DispatchParticleEffectParented("blood_impact_red_01",head.GetCenter()+AngleVectors(head.GetAngles()+Vector(90,0,0))*16,Vector(),head)
				
			}
			DispatchParticleEffectParented("blood_impact_red_01_droplets",pos,ang,player)
			DispatchParticleEffectParented("blood_impact_red_01_droplets",head.GetCenter()+AngleVectors(head.GetAngles()+Vector(90,0,0))*16,Vector(),head)
			
			local trace=TraceLineComplex(head.GetOrigin(),head.GetOrigin()-Vector(RandomFloat(-8,8),RandomFloat(-8,8),32),head,MASK_SHOT,0)
			DecalTrace(trace,"Blood_s")
			
			local trace=TraceLineComplex(pos,pos-Vector(RandomFloat(-8,8),RandomFloat(-8,8),32),plr,MASK_SHOT,0)
			DecalTrace(trace,"Blood_s")
			
			if (Time()-LastDmgTime>3) return;
			
			return 0.1
		}.bindenv(this),0)
	}
	
	if (!silent) player.SetFOV(21,0.05);
	SW_MUS.Stop()
	player.StopSound("PlayerFall")
	if (weaponmodel&&("Destroy" in weaponmodel)) weaponmodel.Destroy();
	//if (info.GetDamageType()==32) DeathScreamPlayed=true;
	if (info.GetDamageType()==32) SendToConsole("fadein 0.0000001")
	local force=info.GetDamageForce()
	//info.ScaleDamageForce(0.001)
	
	local eyevec=Vector(player.GetEyeForward().x,player.GetEyeForward().y,0)
	local eyevec2=Vector(player.GetEyeRight().x,player.GetEyeRight().y,0)
	
	cameraT<-{targetname="deathcam",speed=50,moveto="",trackspeed=1100,target="!player",spawnflags=4+8+16+256,fov=95,fov_rate=IntervalPerTick()}
	//SendToConsole("thirdperson")
	if (!silent) 
	{
		camera<-SpawnEntityFromTable("point_viewcontrol",cameraT)
		camera.AcceptInput("enable","",null,null)
		camera.SetOrigin(player.EyePosition())
		camera.SetAngles(player.EyeAngles())
	}
		
	local DeathThinkOn=false
	LastDmgTime=Time()
	//Entities.FindByModel(null,model).SetName("player_body")
		//plr<-Entities.FindByModel(null,model)
		//body<-Entities.FindByModel(plr,model)
		//body.SetName("player_body")
		//camera.AcceptInput("settarget","player_body",null,null)
	Entities.First().SetContextThink("CreateDeathcam",function(_)
	{
		if (!silent)
		{
			plr<-Entities.FindByModel(null,model)
			body<-Entities.FindByModel(plr,model)
			body.SetName("player_body")
			body.SetCollisionGroup(1)
		}
		
		
		CC_T<-{targetname="death_cc",exclusive=1,filename="sw_death.raw",fadeInDuration=1,StartDisabled=1,fadeOutDuration=1}
		//SendToConsole("thirdperson")
		if (!GetNamedEnt("death_cc")) CC<-SpawnEntityFromTable("color_correction",CC_T);
		if (!silent)camera.AcceptInput("settarget","player_body",null,null)
		BE_T<-{targetname="deathcam_bullseye",spawnflags=65536, health=500000,modelscale=0.1}
		//SendToConsole("thirdperson")
		if (!silent) BE<-SpawnEntityFromTable("npc_bullseye",BE_T)
		EntFire("color_correction","Disable")
		EntFireByHandle(CC,"Enable","",0.1)
		
		player.SetAngles(Vector(0,0,0))
		if (!silent)
		{
			plr<-Entities.FindByModel(null,model)
			eyes<-Entities.FindByModel(plr,model).LookupAttachment("chest")
			ang<-Entities.FindByModel(plr,model).GetAttachmentAngles(eyes)
			ang=AngleVectors(ang)
		}
		local playerorigin=null
		if (!silent) playerorigin=Entities.FindByModel(plr,model).GetAttachmentOrigin(eyes)+Vector(0,0,20)
		
		//printl(TraceLineComplex(playerorigin,playerorigin-eyevec*65,plr, MASK_SHOT, 1).DidHit())
		
		if (!silent)
		{
			if (!TraceLineComplex(playerorigin,playerorigin-eyevec*65,plr, MASK_SHOT, 1).DidHit()) playerorigin=playerorigin-eyevec*64;
			else if (!TraceLineComplex(playerorigin,playerorigin-eyevec*33,plr, MASK_SHOT, 1).DidHit()) playerorigin=playerorigin-eyevec*32;
			else if (!TraceLineComplex(playerorigin,playerorigin-eyevec2*65,plr, MASK_SHOT, 1).DidHit()) playerorigin=playerorigin-eyevec2*64;
			else if (!TraceLineComplex(playerorigin,playerorigin-eyevec2*33,plr, MASK_SHOT, 1).DidHit()) playerorigin=playerorigin-eyevec2*32;
			else if (!TraceLineComplex(playerorigin,playerorigin+eyevec2*65,plr, MASK_SHOT, 1).DidHit()) playerorigin=playerorigin+eyevec*64;
			
			camera.SetOrigin(playerorigin)
			
			camera.SetAngles(Entities.FindByModel(plr,model).GetAttachmentAngles(eyes))
		
		CC.SetOrigin(Entities.FindByModel(plr,model).GetAttachmentOrigin(eyes)+Vector(0,0,20))
		BE.SetOrigin(Entities.FindByModel(plr,model).GetAttachmentOrigin(eyes))
		}
		//BE.SetParent(Entities.FindByModel(plr,model),"chest")
		if (!silent) camera.SetCollisionGroup(1)
		Convars.SetInt("r_nearz",1)
		if (!DeathScreamPlayed&&!silent&&model.find("player")!=null) player.EmitSound("PlayerDeath")
		if (!DeathScreamPlayed&&!silent&&model.find("player")!=null) SendToConsole("dsp_off 1")
		else SendToConsole("dsp_off 0")
		//camera.SetAngles(Entities.FindByModel(plr,model).GetAttachmentAngles(eyes))
		//camera.SetParent(Entities.FindByModel(plr,model),"chest")
		if (!silent) camera.AcceptInput("enable","",null,null);
		//EntFire("npc_combin*","Wake")
		EntFire("npc_combin*","SetRelationShip","deathcam_bullseye d_ht 99")
		//EntFire("npc_combin*","updateenemymemory","deathcam_bullseye")
		EntFire("npc_zomb*","SetRelationShip","deathcam_bullseye d_ht 99")
		EntFire("npc_*zomb*","SetRelationShip","deathcam_bullseye d_ht 99")
		if (!silent) EntFireByHandle(body,"AddEffects",4);
		SendToConsole("fadein 0.0000001")
		local deadtime=Time()
		if (!silent&&"ApplyForceOffset" in body.GetPhysicsObject()&&model!="models/player_headless.mdl")
		{
			body.GetPhysicsObject().ApplyForceOffset(force*2,body.GetAttachmentOrigin(body.LookupAttachment("eyes")));
			body.GetPhysicsObject().ApplyForceOffset(force/2,body.GetAttachmentOrigin(body.LookupAttachment("chest")));
		}
		Entities.First().SetContextThink("CreateDeathcam2",function(_)
		{
			local DeadUnZoom=clamp(Time()-deadtime-2,0,50)*15
			if (!silent&&DeadUnZoom<1&&("ApplyForceOffset" in body.GetPhysicsObject())) EntFireByHandle(camera,"SetFOV",clamp(7000/(body.GetOrigin()-camera.GetOrigin()).Length(),0,90));
			else 
			{
				if (!DeathThinkOn&&!silent)
				{
					EntFireByHandle(camera,"SetFOVRate",4,1);
					EntFireByHandle(camera,"SetFOV",clamp(camera.GetFov()*RemapVal(camera.GetFov(),5,90,9,3),0,175),1.01);
					DeathThinkOn=true
				}
			}
			if ((Time()-deadtime)>0)
			{
				if ((Time()-deadtime)<1.5) SendToConsole("host_timescale "+clamp(min(Time()-deadtime,Time()-LastDmgTime+0.2)-0.06,0.3,1));
				else SendToConsole("host_timescale "+clamp(Time()-deadtime-0.06,0.3,1));
				SendToConsole("host_pitchscale "+clamp((Time()-deadtime-0.06)/2+0.3,0.5,1))
			}
			local dist=0
			if (!silent)
			{
				if (BE!=null) dist=(body.GetAttachmentOrigin(eyes)-BE.GetOrigin()).Length()
				if (BE!=null) BE.SetMoveType(4)
				if (BE&&Entities.FindByModel(plr,model)) BE.SetVelocity((Entities.FindByModel(plr,model).GetOrigin()-BE.GetOrigin()+Vector(0,0,-8))*4)
				if ((Time()-deadtime)>3&&BE) {BE.Destroy();BE=null}
				//EntFire("npc_combin*","updateenemymemory","deathcam_bullseye")
				//EntFire("npc_zomb*","updateenemymemory","deathcam_bullseye")
				//EntFire("npc_*zomb*","updateenemymemory","deathcam_bullseye")
				if ((Time()-deadtime)>6&&(Time()-deadtime)<12) camera.SetOrigin(camera.GetOrigin()+Vector(0,0,10))
			}
			if ((Time()-deadtime)>11&&!SW_RETRY_AVAILABLE) SendToConsole("ent_fire stamina_system callscriptfunctionclient DisplayLoadPanels");
			if ((Time()-deadtime)>11&&(Time()-deadtime)<11.3&&SW_RETRY_AVAILABLE) SendToConsole("ent_fire stamina_system callscriptfunctionclient DisplayContinuePanels");
			return 0
		}.bindenv(this),0)
		
		
	}.bindenv(this),0)
	return true
	//printl(info)
	if ((player.GetButtonForced()&IN.DUCK)==4) return true;
	//printl(Entities)
	//if (info.entindex_killed)
	printl("REFUSING TO DIE!!!")
	//info.SetDamage(clamp(info.GetDamage(),0,player.GetHealth()-1))
	player.SetHealth(255)
	local angles=player.GetAngles()
	player.SetAngles(Vector(angles.x,angles.y,15))
	player.SetModelScale(0.75,0.1)
	
	local PP=SpawnEntityFromTable("postprocess_controller",{})
	
	Entities.First().SetContextThink("ViewDrunk",function(_)
	{
		if (player.GetHealth()<=0) return;
		local angles=player.GetAutoaimVector(1)
		local seed=(Time().tointeger()+127)*123%12222
		local RandVec=Vector(cos(seed),sin(seed),0)/2
		angles.z=15
		//player.SetAngles(player.GetAngles())
		local punch=player.GetAutoaimVector(1)*sin(Time())
		player.ViewPunch((player.GetAutoaimVector(1)*sin(Time())*RandVec.x*RandVec.y+Vector(cos(Time()),sin(Time()),0)*RandVec.y*RandVec.x+player.GetAutoaimVector(1)))
		//printl(RandVec)
		EntFireByHandle(PP,"SetDepthBlurStrength",(255-player.GetHealth())/100)
		return 0
	}.bindenv(this),0)
	
	Entities.First().SetContextThink("Bleedout",function(_)
	{
		if (player.GetHealth()<=0) return;
		//printl(((player.GetButtonForced()&IN.DUCK)))
		local dmg=CreateDamageInfo(player,player,Vector(),Vector(),10,DMG_DIRECT)
		dmg.ScaleDamageForce(0)
		dmg.SetDamagePosition(player.GetOrigin()+Vector(0,0,200))
		dmg.SetReportedPosition(player.GetOrigin()+Vector(0,0,200))
		if (player.GetHealth()<=1 ) player.TakeDamage(dmg);
		else player.SetHealth(clamp(player.GetHealth()-3,1,999))
		return 1
	}.bindenv(this),1)
	
	player.ForceButtons(IN.DUCK)
	return false
}

::SW_GAMEOVER<-CheatDeath

function GetDrunk()
{
	if (Drunkness>200) Drunkness=200;
	Drunkness+=50
	AddPlayerMoney(-100)
	player.SetHealth(clamp(player.GetHealth()+15,0,PlayerMaxHealth*2.0))	// you may guess that the hidden strategy here is to eat first, then order beer several times and you will get unnoticeable overheal.
	Entities.First().SetContextThink("ViewDrunk",function(_)
	{
		if (player.GetHealth()<=0) return;
		local angles=player.GetAutoaimVector(1)
		local seed=(Time().tointeger()+127)*123%3600
		local RandVec=Vector(cos(seed),sin(seed),0)/2
		angles.z=15
		//player.SetAngles(player.GetAngles())
		local punch=player.GetAutoaimVector(1)*sin(Time())
		player.ViewPunch((player.GetAutoaimVector(1)*sin(Time())*RandVec.x*RandVec.y+Vector(cos(Time()),sin(Time()),0)*RandVec.y*RandVec.x+player.GetAutoaimVector(1)*2)*Drunkness/100.0)
		//printl(RandVec)
		Drunkness-=0.04
		SendToConsole("sv_rollangle "+Drunkness/8.0)
		SendToConsole("r_screenoverlay effects/tp_refract")
		if (Drunkness<10) SendToConsole("r_screenoverlay 0")
		if (Drunkness<=0) return
		//EntFireByHandle(PP,"SetDepthBlurStrength",(255-player.GetHealth())/100)
		return 0
	}.bindenv(this),0)
}

::SW_ScreenFade<-function(holdtime,duration,r,g,b,a,UnFade=false)
{
	local fadetable={ 
		duration=duration,
		holdtime=holdtime,
		renderamt=a,
		rendercolor=r+" "+g+" "+b,
		spawnflags=UnFade.tointeger()
	}
	local fadeent=SpawnEntityFromTable("env_fade",fadetable)
	fadeent.AcceptInput("Fade","",null,null)
	fadeent.Destroy()
}

::SW_AddDrunkness <-function(amount)
{
	if (Drunkness>200) Drunkness=200;
	Drunkness+=amount
	Entities.First().SetContextThink("ViewDrunk",function(_)
	{
		if (player.GetHealth()<=0) return;
		local angles=player.GetAutoaimVector(1)
		local seed=(Time().tointeger()+127)*123%3600
		local RandVec=Vector(cos(seed),sin(seed),0)/2
		angles.z=15
		//player.SetAngles(player.GetAngles())
		local punch=player.GetAutoaimVector(1)*sin(Time())
		player.ViewPunch((player.GetAutoaimVector(1)*sin(Time())*RandVec.x*RandVec.y+Vector(cos(Time()),sin(Time()),0)*RandVec.y*RandVec.x+player.GetAutoaimVector(1)*2)*Drunkness/100.0)
		//printl(RandVec)
		Drunkness-=0.03
		SendToConsole("sv_rollangle "+Drunkness/8.0)
		SendToConsole("r_screenoverlay effects/tp_refract")
		if (Drunkness<10) SendToConsole("r_screenoverlay 0")
		if (Drunkness<=0) return
		//EntFireByHandle(PP,"SetDepthBlurStrength",(255-player.GetHealth())/100)
		return 0
	}.bindenv(this),0)
}.bindenv(this)

function FoodHeal(amount)
{
	AddPlayerMoney(-amount)
	player.SetHealth(clamp(player.GetHealth()+amount/2.0,0,PlayerMaxHealth*2))
}
::SW_DRUNK<-GetDrunk
::SW_FOOD<-FoodHeal

local flash=false
function Flashlight()
{
	if (flash) {EntFire("flashlight","kill","",0);flash=false;return}
	local flashAngle = VectorAngles(player.GetAutoaimVector(AUTOAIM_SCALE_DEFAULT))
	flash=true
	printl("flash!")
	local S = {
	//angles = player.GetAngles().x+" "+player.GetAngles().y+" "+player.GetAngles().z,
	targetname = "flashlight",
	_cone = 30,
	_inner_cone = 20,
	_light = "250 222 124 200",
	brightness = 3,
	distance = 500
	pitch = flashAngle.x-20,
	spawnflags = 1,
	style = 6
	}
	local flashlight=SpawnEntityFromTable("light_dynamic",S);
	local VM=player.GetViewModel(0)
	flashlight.SetOrigin(VM.GetOrigin()+Vector(0,0,60))
	flashlight.SetAngles(flashAngle)
	local muzzle=VM.GetAttachmentOrigin(VM.LookupAttachment("muzzle"))+Vector(0,0,player.GetBoundingMaxs().z-8)+player.GetEyeForward()*3
	flashlight.SetParent(VM,"")
	EntFire("flashlight","addoutput","pitch -20",0)
	return
}

function GiveSilent(...)
{
	local WeaponTable={}
	if (vargv.len()>1)
	{
		WeaponTable={spawnflags=16,SetAmmo1=vargv[1].tostring()}
	}
	local weapon=SpawnEntityFromTable(vargv[0],WeaponTable)
	player.EquipWeapon(weapon)
	printl("SILENTLY GIVING "+vargv[0])
}

::SyncPlayerStats<-function()
{
	NetMsg.Start("SyncPlayerStats");
	NetMsg.WriteFloat(PlayerExperience)
	NetMsg.WriteFloat(PlayerMoney)
	NetMsg.WriteFloat(PlayerHeat)
	NetMsg.WriteFloat(PlayerMaxHeat)
	NetMsg.WriteFloat(PlayerMaxHealth)
	NetMsg.WriteShort(PlayerSkillPoints)
	NetMsg.WriteBool(AbilitiesActive)
	foreach (Skill in SKILLS)
	{
		NetMsg.WriteBool(Skill.Unlocked)
	}
	NetMsg.WriteBool(SKILLS.BulletTimeAbility.Unlocked)
	NetMsg.Send(player, true);
	
	
	//absolutely awful, should've improved dialogue system instead of doing this crap.
	if (PlayerMoney>=100) {EntFire("dialogue_manager","AddContext","Has100:1",0);EntFire("dialogue_manager","RemoveContext","No100",0)}
	if (PlayerMoney<100) {EntFire("dialogue_manager","AddContext","No100:1",0);EntFire("dialogue_manager","RemoveContext","Has100",0)}
	
	if (PlayerMoney>=150) {EntFire("dialogue_manager","AddContext","Has150:1",0);EntFire("dialogue_manager","RemoveContext","No150",0)}
	if (PlayerMoney<150) {EntFire("dialogue_manager","AddContext","No150:1",0);EntFire("dialogue_manager","RemoveContext","Has150",0)}
	
	if (PlayerMoney>=200) {EntFire("dialogue_manager","AddContext","Has200:1",0);EntFire("dialogue_manager","RemoveContext","No200",0)}
	if (PlayerMoney<200) {EntFire("dialogue_manager","AddContext","No200:1",0);EntFire("dialogue_manager","RemoveContext","Has200",0)}
}
if (SERVER_DLL) SendToConsoleServer("fadein 11");

function PlaySoundAtPlayer(name,vol)
{
	Entities.First().PrecacheSoundScript(name)
					
	local s3=EmitSound_t()
	s3.SetSoundName(name)
	s3.SetVolume(vol)
	s3.SetOrigin(player.GetOrigin())
	EmitSoundParamsOn(s3,Entities.First())
}

local MatOverride=null
		
::InputFootstepMaterial<-function()
{
	MatOverride=parameter
}.bindenv(this)

::InputFootstepClear<-function()
{
	MatOverride=null
}.bindenv(this)

function SetPHealth(ent)
{
	//if (!player) return
	//if (GetMapName()!="teleporting_room_v1") SendToConsole("fadein 1")
	//printl(ent.GetClassname())
	
	if (ent.GetClassname()=="player")
	{
		//scop=ent.GetOrCreatePrivateScriptScope()
		
		//scop.FireBullets<-Bullets
		SendToConsoleServer("fadein 0.1");
		SendToConsole("firstperson")
		SendToConsole("closecaption 0")
		SendToConsole("host_timescale 1")
		SendToConsole("mat_bloomscale 1")
		SendToConsole("mat_local_contrast_scale_override 0")
		SendToConsole("host_pitchscale 1")
		SendToConsole("sv_rollangle 0")
		SendToConsole("r_screenoverlay  0")
		//ent.SetMaxHealth(1000)
		//ent.SetHealth(1000)
		EntFire("!player","SetMaxHealth",100,0)
		EntFire("!player","SetHealth",100,0)
		EntFire("stamina_system","CallScriptFunction","LoadData",0.18)
		//EntFire("stamina_system","CallScriptFunction","LoadData",0.3)
		//EntFire("stamina_system","CallScriptFunctionClient","LoadData",0.5)
		printl("Health set!")
		EntFire("info_player_start","SetEntityName","info_player_start")
		local rtpos=Entities.FindByClassname(null,"info_player_start").GetOrigin()+Vector(0,0,64)
		
		local direction=ent.GetOrigin()+Vector(0,0,64)-ent.EyePosition()
		direction.z=0
		local direction90=(-direction).Cross(Vector(0,0,1))
		local pos=ent.GetOrigin()+Vector(0,0,64)//+direction.Normalized()*24-direction90.Normalized()*11+Vector(0,0,6)
		local angles=ent.GetAngles()
		
		local IntroTable = {
			targetname = "player_script_intro",
			alternatefovchange = 1,
			DrawSky = 1,
			DrawSky2 = 1
		}
		local PlayerWeaponTable = {
			targetname = "player_weapon",
			vscripts = "weapons/weapon_base",
			weapondatascript_name = "none",
			model = "models/props_c17/suitcase_passenger_physics.mdl"
			model = "models/props_c17/suitcase_passenger_physics.mdl"
		}
		local ProxyTable = {
		}
		local STable = {spawnflags=64}
		local CameraTable = {
			targetname = "player_thirdperson_camera",
			SkyMode = 2,
			origin = pos.x+" "+pos.y+" "+pos.z,
			angles = angles.x+" "+angles.y+" "+angles.z
		}
		local RTTable = {
			targetname = "SW_RT",
			origin = rtpos.x+" "+rtpos.y+" "+(rtpos.z+12)
			angles = "40 0 0"
			FOV = "50"
			RenderTarget = "_rt_Camera2"
			fogEnable = "1"
			fogColor = "220 20 20"
			fogStart = "0"
			fogEnd = "40"
			UseScreenAspectRatio = "0"
			EFlags = "131072"

		}
		local RTLinkTable = {
			targetname = "SW_RT_LINK",
			origin = rtpos.x+" "+rtpos.y+" "+rtpos.z
			angles = "0 0 0"
			target = (Entities.FindByName(null,"playermodel") ? "playermodel" : "!player")
			parent = (Entities.FindByName(null,"playermodel") ? "playermodel" : "!player")
			PointCamera = "SW_RT"
		}
		local RTModelTable = {
			targetname = "SW_RT_MODEL",
			origin = (rtpos.x+16)+" "+rtpos.y+" "+(rtpos.z+2)
			angles = "0 90 0"
			//lightingorigin = "!player"
			model = "models/weapons/pipe/mattpipe.mdl"
			//model = "models/props/cs_militia/crate_extrasmallmill.mdl"
			viewhideflags = "193"
			EFlags = "131072"
		}
		local Intro = SpawnEntityFromTable("script_intro", IntroTable)
		local Proxy = SpawnEntityFromTable("logic_playerproxy", ProxyTable)
		local Speedmod = SpawnEntityFromTable("player_speedmod", STable)
		local PlayerWeapon = SpawnEntityFromTable("weapon_custom_scripted1", PlayerWeaponTable)
		PlayerWeapon.SetOrigin(player.GetOrigin())
		local ThirdpersonCamera = SpawnEntityFromTable("point_viewcontrol", CameraTable)
		local RTCamera = SpawnEntityFromTable("point_camera", RTTable)
		local RTModel = SpawnEntityFromTable("prop_dynamic", RTModelTable)
		local RTLink = SpawnEntityFromTable("info_camera_link", RTLinkTable)
		
		local Starfield = SpawnEntityFromTable("env_starfield", {targetname="SW_STARFIELD",density=10})
		EntFireByHandle(Starfield,"setdensity",0.5)
		
		RTModel.SetModelScale(14/(RTModel.GetBoundingMins()-RTModel.GetBoundingMaxs()).Length(),0)
		RTModel.SetMoveType(4)
		RTModel.SetAngularVelocity(0,30,0)
		RTModel.SetOrigin(rtpos+Vector(16,0,0)+(RTModel.GetOrigin()-RTModel.GetCenter()))
		//local RTMonitor = SpawnEntityFromTable("func_monitor", RTMonitorTable)
		
		local RightStop=false
		
		//local StairMode=false
		
		if (!player.IsSuitEquipped())
		{
			//Suit<-SpawnEntityFromTable("item_suit",{spawnflags=1})
			//Suit.SetOrigin(player.GetOrigin())
			NetProps.SetPropInt( player, "m_Local.m_bWearingSuit", 1 ) //Thanks, Sam
			
			if (Entities.FindByClassname(null,"item_suit")) Entities.FindByClassname(null,"item_suit").Destroy()
		}
		
		local LastYaw=0;
		
		
		function FootstepSound(name)
		{
			
			local material=""
			if (name.find("concrete")!=null) material="concrete/";
			if (name.find("metal")!=null) material="metal/";
			if (name.find("ladder")!=null) material="metal/";
			if (name.find("sand")!=null) material="sand/";
			if (name.find("tile")!=null) material="tile/";
			if (name.find("wood")!=null) material="wood/";
			if (name.find("dirt")!=null) material="dirt/";
			if (name.find("carpet")!=null) material="carpet/";
			
			if (MatOverride) material=MatOverride+"/";
			
			local type="walk"
			local id=1;
			local OnGround=(player.GetFlags()&1)
			
			local Land=(Time()-LastAir)<0.05
			//printl(player.GetVelocity().Length2D())
			
			local StepTime=Time()
			
			Entities.First().SetContextThink("PlayerStopStep",function(...)
			{
				if (player.GetVelocity().Length2D()<50)
				{
					type="stop"
					id=RandomInt(1,2)+2*(RightStop.tointeger())
					
					//printl("Stop Sound!")
					
					RightStop=!RightStop
					
					PlaySoundAtPlayer("player/footsteps/"+material+type+id+".wav",(material=="concrete/") ? 0.15 : 0.25)
					
					Entities.First().PrecacheSoundScript("player/footsteps/"+material+type+id+".wav")
					//printl(id)
					return
				}
				if (Time()-StepTime>0.5) return;
				return 0.1;
			}.bindenv(this),0.1)
			
			Entities.First().SetContextThink("PlayerTurnStep",function(...)
			{
			//	printl(abs(AngleDistance(LastYaw,player.GetAngles().y)))
				
				if (LastYaw==(-1)) LastYaw=player.GetAngles().y;
				
				if (player.GetVelocity().Length2D()<50&&abs(AngleDistance(LastYaw,player.GetAngles().y))>65)
				{
					RightStep=!RightStep
					local type="stop"
					id=RandomInt(1,2)+2*(RightStop.tointeger())
					
					PlaySoundAtPlayer("player/footsteps/"+material+type+id+".wav",(material=="concrete/") ? 0.15 : 0.25)
					
					Entities.First().PrecacheSoundScript("player/footsteps/"+material+type+id+".wav")
					LastYaw=-1;
					return 0.8
				}
				if (abs(AngleDistance(LastYaw,player.GetAngles().y))<5)
				{
					LastYaw=player.GetAngles().y;
					return 0.05
				}
				LastYaw=player.GetAngles().y;
				return 0.15;
			}.bindenv(this),0.15)
			
			if (material!="")
			{
				id=RandomInt(1,3)+3*(RightStep.tointeger())
				//printl(RightStep)
				
				//printl((Time()-LastAir)<0.05)
				
				if (player.GetVelocity().Length2D()>300) type="run"
				
				if (Land&&OnGround) {
					id=1
					type="land"
				}
				
				//printl((player.GetOrigin()-LastOriginReal).z)
				
				if (material!="dirt/"&&material!="carpet/"&&material!="sand/"&&fabs((player.GetOrigin()-LastOriginReal).z)>5) 
				{
					if (type=="walk")
					{
						id=RandomInt(1,2)+2*(RightStep.tointeger())
						type=((player.GetOrigin()-LastOriginReal).z>0.3) ? "up" : "down"
					}
					//printl(NetProps.GetPropFloat(player,"m_flStepSoundTime"))
					
					NetProps.SetPropFloat(player,"m_flStepSoundTime",NetProps.GetPropFloat(player,"m_flStepSoundTime")*((type=="run") ? 0.8 : 0.675))
					
				}
				player.PrecacheSoundScript("player/footsteps/"+material+type+id+".wav")
				
				//printl("player/footsteps/"+material+type+id+".wav")
				
				if ((player.GetHealth()<=20))
				{
					NetProps.SetPropFloat(player,"m_flStepSoundTime",NetProps.GetPropFloat(player,"m_flStepSoundTime")*(RightStep ? 0.75 : 1.1))
				}
				
				return ("player/footsteps/"+material+type+id+".wav")
			}
			
			return name
		}
		
		
		function ModifyEmitSoundParams(params)
		{
			
			
			if (params.GetSoundName().find("footstep")!=null) 
			{
				//printl(params.GetSoundName())
				if (params.GetSoundName().find("duct")==null) params.SetSoundName(FootstepSound(params.GetSoundName()))
				//if (params.GetSoundName().find("ladder")==null) params.SetSoundName(FootstepSound(params.GetSoundName()))
				//printl(params.GetVolume())
				
				if (params.GetSoundName().find("walk")!=null&&params.GetVolume()==0.5)
					params.SetVolume(0.2);
				
				params.SetVolume(params.GetVolume()*0.8)
				
				//printl(params.GetSoundName())
				
				Entities.FindByName(null,"stamina_system").GetOrCreatePrivateScriptScope().FootStep();
			}
			return true
		}
		
		Hooks.Add(player.GetOrCreatePrivateScriptScope(),"ModifyEmitSoundParams",ModifyEmitSoundParams.bindenv(this),"ModifyEmitSoundParams");
		
		NetMsg.Receive("RT_ChangeModel", function( player )
		{
			if (RTLink&&RTLink.IsValid())
				RTLink.Destroy();
		
			RTLinkTable = {
				targetname = "SW_RT_LINK",
				origin = rtpos.x+" "+rtpos.y+" "+rtpos.z
				angles = "0 0 0"
				target = (Entities.FindByName(null,"playermodel") ? "playermodel" : "!player")
				parent = (Entities.FindByName(null,"playermodel") ? "playermodel" : "!player")
				PointCamera = "SW_RT"
			}
			RTLink = SpawnEntityFromTable("info_camera_link", RTLinkTable)
		
			if (Entities.FindByName(Entities.FindByName(null,"SW_RT_MODEL"),"SW_RT_MODEL")) 
			{
				Entities.FindByName(null,"SW_RT_MODEL").Destroy();
				RTModel=Entities.FindByName(null,"SW_RT_MODEL");
			}
		
			local itemname=NetMsg.ReadString()
			local model=NetMsg.ReadString()
			RTModel.SetModel(model)
			RTModel.SetModelScale(1,0)
			local maxi=min((RTModel.GetBoundingMins().x-RTModel.GetBoundingMaxs().x),(RTModel.GetBoundingMins().y-RTModel.GetBoundingMaxs().y))
			maxi=fabs(min(maxi,(RTModel.GetBoundingMins().z-RTModel.GetBoundingMaxs().z)))
			//maxi=pow(maxi,)
			
			local sizemod=1
			
			if ("preview_scale" in LIST_ITEMS[itemname]) 
				sizemod=LIST_ITEMS[itemname].preview_scale;
			
			printl(maxi)
			printl(maxi*(12/maxi))
			RTModel.SetAngles(Vector(0,180-90*(RTModel.GetBoundingMaxs().x>RTModel.GetBoundingMaxs().y).tointeger(),0))
			RTModel.SetModelScale(12.0/maxi*sizemod,0)

			RTModel.SetOrigin(rtpos+Vector(16,0,0))
			RTModel.SetOrigin(rtpos+Vector(16,0,0)+(RTModel.GetOrigin()-RTModel.GetCenter())+Vector(2,0,5)*(model.find("healthkit")!=null).tointeger())
			RTModel.SetAngularVelocity(0,20,0)
			RTModel.SetAngles(Vector(90*(model.find("healthkit")!=null||model.find("tomahawk")!=null).tointeger(),180-90*(RTModel.GetBoundingMaxs().x>RTModel.GetBoundingMaxs().y).tointeger(),0))
			RTModel.SetAngles(Vector(90*(model.find("healthkit")!=null||model.find("tomahawk")!=null).tointeger(),180-90*(RTModel.GetBoundingMaxs().x>RTModel.GetBoundingMaxs().y).tointeger(),0))
			
		}.bindenv(this))
		
		
		EntFireByHandle(ThirdpersonCamera,"enable")
		EntFireByHandle(ThirdpersonCamera,"disable")
		//EntFireByHandle(ThirdpersonCamera, "SetParent", "!player", 0)
		EntFireByHandle(ThirdpersonCamera, "SetLocalOrigin", "-40 -20 64", 0)
		EntFireByHandle(ThirdpersonCamera, "SetLocalAngles", angles.x+" "+angles.y+" "+angles.z, 0)
		//EntFireByHandle(Intro, "SetCameraViewEntity", "player_thirdperson_camera", 0)
		EntFireByHandle(Proxy, "SetPlayerDrawExternally", "1", 0)
		//EntFireByHandle(Intro, "Activate", "", 1)
		EntFireByHandle(Intro, "SetBlendMode", "8", 1)
		
		
		//player.GetViewModel(1).SetModel("weapons/v_pipe")
		
		//SendToConsole("alias god r_drawpoop")
		//SendToConsole("alias ent_fire r_drawpoop")
		//Convars.UnregisterCommand("god")
		
		switch (GetMapName())	// used for changing sleeve skin
		{
			case "tutorial": Convars.SetInt("spec_scoreboard",1);break;
			default: Convars.SetInt("spec_scoreboard",0);
		}
	
		
		
		Convars.RegisterCommand( "give_silent", function(...)
		{
			local WeaponTable={}
			if (vargv.len()>2)
			{
				WeaponTable={spawnflags=16,SetAmmo1=vargv[2]}
			}
			local weapon=SpawnEntityFromTable(vargv[1],WeaponTable)
			player.EquipWeapon(weapon)
			NetMsg.Start("HideWeaponHistory");
			NetMsg.Send(player, true);
			for (local i=0;i<2.5;i+=0.01)
			{
				EntFireByHandle(self,"RunScriptCodeQuotable","player.StopSound(''HL2Player.PickupWeapon'')",IntervalPerTick()*i)
			}
		}.bindenv(this), "ey", FCVAR_NONE );
		

		SendToConsoleServer("alias disconnect \"map_background background\"")
		// Instead of simply disconnecting, load the main menu map to prevent softlocks for whoever decides using disconnect command is a smart idea.
		
		Entities.First().SetContextThink("StatsSyncer",function (...) {SyncPlayerStats();return 1}.bindenv(this),1)
		
		local LastRadSound=0;
		local LastRad=-1;
		
		Entities.First().SetContextThink("RadiationMeter",function (...) 
		{
			local meter=0
			local hurter=null
			while (hurter=Entities.FindByClassnameWithin(hurter,"trigger_hurt",player.GetOrigin(),400))
			{
				if (hurter.GetKeyValue("damagetype")!="262144") continue;
				
				local dist=400-(hurter.GetOrigin()-player.GetOrigin()).Length()
				if (!player.IsEntVisible(hurter)&&!player.IsVisible(hurter.GetOrigin())) dist*=0.1;
				
				dist*=clamp((hurter.GetBoundingMaxs()-hurter.GetBoundingMins()).Length()/100.0,1,2.5)
				
				meter+=dist
			}
			
			if ((Time()-LastRadiationDamage)<3) meter+=Bias(3-clamp(Time()-LastRadiationDamage,0,3),0.85)*1000
			
			SendToConsole("mat_grain_scale_override "+meter/100.0)
			
			if (meter==0) SendToConsole("mat_grain_scale_override -1");
			
			local n=(RandomInt(1,2)==1) ? "a" : ((RandomInt(1,2)==1) ? "b" : "c")
			local snd=clamp((meter/300).tointeger(),0,4)
			if (snd!=0&&(snd!=LastRad||LastRadSound<Time()))
			{
				player.PrecacheSoundScript("player/geiger"+snd+"_"+n+".wav")
				player.EmitSound("player/geiger"+snd+"_"+n+".wav")
				LastRadSound=Time()+player.GetSoundDuration("player/geiger"+snd+"_"+n+".wav","")
				LastRad=snd
			}
			
			if ((Time()-LastRadiationDamage)<3) return 0.0;
			if (meter>3) return 0.0;
			if (meter>1) return 0.05;
			
			return 0.2
		}.bindenv(this),0.2)
		
		EntFireByHandle(player,"runscriptfile","flash")
		
		Convars.RegisterCommand( "flashlight", function(_)
		{
			//DespawnLayout()
			self.SetContextThink("Flash",function(_) { Flashlight() }.bindenv(this),0.015)
		}.bindenv(this), "", FCVAR_CLIENTDLL );
		
		Convars.RegisterCommand( "sw_rank", function(...)
		{
			if (vargv.len() > 1) {
				SW_DIFFICULTY_RANK = clamp(vargv[1].tointeger(), -5000, 5000);
				printl("Rank set to " + SW_DIFFICULTY_RANK);
				return;
			}
			printl("Rank: " + SW_DIFFICULTY_RANK);
			printl("Norm: " + SW_GetRankNorm());
			printl("Death count: " + SW_GetDeathCount());
			printl("Buffer: " + SW_RANK_BUFFER);
			printl("Inventory score: " + SW_GetInventoryScore());
		}, "", 0 )
		
		Hooks.Add(player.GetOrCreatePrivateScriptScope(),"OnDeath",CheatDeath,"CheatDeath");
		Hooks.Add(player.GetOrCreatePrivateScriptScope(),"FireBullets",Bullets,"FireBullets");
		printl("hook added")
		//ListenToGameEvent("player_death",CheatDeath,nil)
		SendToConsole("r_screenoverlay effects/flicker_512")
		return
	}
}

Convars.RegisterCommand( "holster", function(_)
		{
			if (!Holstered)
			{
				EntFire("player_speedmod","enable","0");
				EntFire("player","holsterweapon")
				player.GetActiveWeapon().EmitSound("weapon.StepLeft")
				SendToConsole("hud_fastswitch 5")
				SendToConsole("crosshair 0")
			}
			else
			{
				if (!(player.GetButtons() & IN.SPEED)) EntFire("player_speedmod","disable","0");
				EntFire("player","unholsterweapon")
				player.GetActiveWeapon().EmitSound("weapon.ImpactSoft")
				SendToConsole("hud_fastswitch 0")
				SendToConsole("crosshair 1")
			}
			
			NetMsg.Start("Holster")
			NetMsg.Send(player,true)
			
			Holstered=!Holstered
		}.bindenv(this), "ey", FCVAR_CHEAT );

function HideHistory()
{
	if (CLIENT_DLL) 
	{
		printl("history hidden")
		SetHudElementVisible("CHudHistoryResource",false); 
		Entities.First().SetContextThink("Flash",function(_) { SetHudElementVisible("CHudHistoryResource",true);  }.bindenv(this),5)
	}
}

::AddPlayerXP<-function(xp)
{
	if (((1+0.07*sqrt(PlayerExperience)).tointeger())<((1+0.07*sqrt(PlayerExperience+xp)).tointeger()))
	{
		//printl("LEVEL UP")
		PlayerSkillPoints+=((1+0.07*sqrt(PlayerExperience+xp)).tointeger())-((1+0.07*sqrt(PlayerExperience)).tointeger())
		SWBigNotification("--- LEVEL UP! ---",Vector(25,255,25));
		//SW_CreateScreenGradient([235,235,235,55],1000,5,2,1);
		Entities.First().SetContextThink("LVLUP2",function(...)
		{
			SWBigNotification("Earned a Skill Point",Vector(255,255,75));
		},1)
		
		Entities.First().SetContextThink("LVLUP2",function(...)
		{
			SWBigNotification("Earned a Skill Point",Vector(255,255,75));
			SendToConsole("mat_autoexposure_min 100")
		},1)
		Entities.First().SetContextThink("LVLUP3",function(...)
		{
			SendToConsole("mat_autoexposure_min 0.5")
		},1.1)
		
		if (SW_MUSIC_OVERRIDE=="")
		{		
			SW_MUSIC_OVERRIDE="levelup";
			Entities.First().SetContextThink("LVLUP_MUSIC_END",function(...)
			{
			
				if (SW_MUSIC_OVERRIDE=="levelup") 
					SW_MUSIC_OVERRIDE="";
				
				return
			
			},14)
		}
		
	}
	//printl(((1+0.07*sqrt(PlayerExperience)).tointeger())+"  "+((1+0.07*sqrt(PlayerExperience+xp)).tointeger()))
	PlayerExperience+=xp
	if (Time()>3&&xp>0) SWSmallNotification(xp.tointeger()+" XP",Vector(30,255,30));
	SyncPlayerStats()
}

::SetPlayerXP<-function(xp)
{
	PlayerExperience=xp
	SyncPlayerStats()
}

::AddPlayerMoney<-function(money,AffectStats=true)
{
	PlayerMoney+=money
	if (SERVER_DLL) SyncPlayerStats();
	else 
	{
		NetMsg.Start("AddPlayerMoneyFromClient")
		NetMsg.WriteShort(money)
		NetMsg.Send()
	}
	
	if (!AffectStats) return;
	
	if (money>0) {
		if (SERVER_DLL) SWSmallNotification("+$"+money,Vector(0,205,0));
		SW_TABLE.iMoneyGained+=money;
	}
	else 
	{
		if (money<0&&SERVER_DLL) SWSmallNotification("-$"+abs(money),Vector(205,0,0));
		SW_TABLE.iMoneySpent-=money;
	}
}

if (SERVER_DLL)
{
	NetMsg.Receive("AddPlayerMoneyFromClient", function( player )
	{
		AddPlayerMoney(NetMsg.ReadShort())
	} );	
}

::ChangePlayerMaxHealth<-function(hp)
{
	if (PlayerMaxHealth>=hp) return
	PlayerMaxHealth=hp
	if (SERVER_DLL)
	{
		if (player.GetMaxHealth()>=PlayerMaxHealth) return
		local PrevMaxHealth=player.GetMaxHealth()*1.0
		player.SetMaxHealth(PlayerMaxHealth);
		//player.SetHealth(player.GetHealth()*player.GetMaxHealth()/PrevMaxHealth)
		//printl(player.GetHealth()*player.GetMaxHealth()/PrevMaxHealth)
		//printl(player.GetMaxHealth()/PrevMaxHealth)
	}
}

::AddPlayerHeat<-function(heat)
{
	PlayerHeat+=clamp(heat,-999,PlayerMaxHeat-PlayerHeat)
	SyncPlayerStats()
}

function OnSpawnedPlayer(info)
{
	PrecacheFootsteps()
	printl(info.userid)
	printl("RESPAWNING")
	if (info.userid)
	{
		printl(player)
		SetPHealth(player)
		Entities.First().SetContextThink("player_spawning",function (...){
		PlayIDGlobal<-Globals.AddGlobal("PlaythroughID",GetMapName(),1);
		Globals.SetCounter(PlayIDGlobal,-1)}.bindenv(this),1)
	}
}

function Precache()
{
	Entities.First().SetContextThink("player_spawning",function (...){if (!player) return 0.1;SetPHealth(player)}.bindenv(this),0.1)
}

function InitCustomWeapon(ent)
{
	switch	(ent.GetClassname())
	{
	case "weapon_pipe":ent.__KeyValueFromString("vscripts","weapons/pipe.nut");break;
	case "weapon_m590":ent.__KeyValueFromString("vscripts","weapons/shotgun.nut");ent.__KeyValueFromString("thinkfunction","Think");break;
	case "weapon_dual_pistols":ent.__KeyValueFromString("vscripts","weapons/akimbo.nut");ent.__KeyValueFromString("thinkfunction","Think");break;
	}
	
	//printl(ent.GetKeyValue("vscripts"))
	
	//if (ent.GetScriptScope()!=null) ent.GetScriptScope().InputCock<-function(...)
	//{
	//	printl("huesos")
	//}
	
	if (ent.GetClassname().find("npc_")!=null)
	{
		ent.SetContextThink("DA_Set",function(...)
		{
			if (("GetRelationship" in ent)&&ent.GetRelationship(player)==3) return;
			// === РАНГ: HP врагов ===
			local rankHealthMult = 1.0 + (SW_DIFFICULTY_RANK / 5000.0);
			rankHealthMult = clamp(rankHealthMult, 0.5, 2.0);

			ent.SetMaxHealth(ent.GetMaxHealth() * rankHealthMult);
			ent.SetHealth(ent.GetHealth() * rankHealthMult);
			//printl("Set enemy health to "+ent.GetHealth())
		}.bindenv(this),2)
	}

	if (ent.GetClassname()=="item_healthvial")
	{
		EntFireByHandle(ent,"RunScriptCode","GetReplace(self)") // since when entity is just created we dont know it's data(origin, angles, model) yet, so we do the replacement by entfire which has mini delay
		ent.AddSpawnFlags(2) // this flag is necessary to prevent items and weapons from being picked up in case they spawn right inside player's bounding box.
		return
	}
	if (ent.GetClassname()=="item_ammo_ar2_altfire")
	{
		EntFireByHandle(ent,"RunScriptCode","GetReplace(self)") // since when entity is just created we dont know it's data(origin, angles, model) yet, so we do the replacement by entfire which has mini delay
		ent.AddSpawnFlags(2) // this flag is necessary to prevent items and weapons from being picked up in case they spawn right inside player's bounding box.
		return
	}
	if (ent.GetClassname()=="item_wine")
	{
		EntFireByHandle(ent,"RunScriptCode","GetReplace(self)") // since when entity is just created we dont know it's data(origin, angles, model) yet, so we do the replacement by entfire which has mini delay
		ent.AddSpawnFlags(2)
		return
	}
	if (ent.GetClassname()=="item_healthkit")
	{
		EntFireByHandle(ent,"RunScriptCode","GetReplace(self)") // since when entity is just created we dont know it's data(origin, angles, model) yet, so we do the replacement by entfire which has mini delay
		ent.AddSpawnFlags(2) // this flag is necessary to prevent items and weapons from being picked up in case they spawn right inside player's bounding box.
		return
	}
	if (ent.GetClassname()=="weapon_smg1")
	{
		EntFireByHandle(ent,"RunScriptCode","GetReplace(self)") // since when entity is just created we dont know it's data(origin, angles, model) yet, so we do the replacement by entfire which has mini delay
		ent.AddSpawnFlags(2) // this flag is necessary to prevent items and weapons from being picked up in case they spawn right inside player's bounding box.
		return
	}
	if (ent.GetClassname()=="weapon_pistol")
	{
		EntFireByHandle(ent,"RunScriptCode","GetReplace(self)") // since when entity is just created we dont know it's data(origin, angles, model) yet, so we do the replacement by entfire which has mini delay
		ent.AddSpawnFlags(2) // this flag is necessary to prevent items and weapons from being picked up in case they spawn right inside player's bounding box.
		return
	}
	if (ent.GetClassname()=="weapon_shotgun")
	{
		EntFireByHandle(ent,"RunScriptCode","GetReplace(self)") // since when entity is just created we dont know it's data(origin, angles, model) yet, so we do the replacement by entfire which has mini delay
		ent.AddSpawnFlags(2) // this flag is necessary to prevent items and weapons from being picked up in case they spawn right inside player's bounding box.
		return
	}
	if (ent.GetClassname()=="weapon_357")
	{
		EntFireByHandle(ent,"RunScriptCode","GetReplace(self)") // since when entity is just created we dont know it's data(origin, angles, model) yet, so we do the replacement by entfire which has mini delay
		ent.AddSpawnFlags(2) // this flag is necessary to prevent items and weapons from being picked up in case they spawn right inside player's bounding box.
		return
	}
	if (ent.GetClassname()=="item_ammo_smg1")
	{
		EntFireByHandle(ent,"RunScriptCode","GetReplace(self)") // since when entity is just created we dont know it's data(origin, angles, model) yet, so we do the replacement by entfire which has mini delay
		ent.AddSpawnFlags(2) // this flag is necessary to prevent items and weapons from being picked up in case they spawn right inside player's bounding box.
		return
	}
	if (ent.GetClassname()=="weapon_frag")
	{
		EntFireByHandle(ent,"RunScriptCode","GetReplace(self)") // since when entity is just created we dont know it's data(origin, angles, model) yet, so we do the replacement by entfire which has mini delay
		ent.AddSpawnFlags(2) // this flag is necessary to prevent items and weapons from being picked up in case they spawn right inside player's bounding box.
		return
	}
	if (ent.GetClassname()=="item_battery")
	{
		EntFireByHandle(ent,"RunScriptCode","GetReplace(self)") // since when entity is just created we dont know it's data(origin, angles, model) yet, so we do the replacement by entfire which has mini delay
		ent.AddSpawnFlags(2) // this flag is necessary to prevent items and weapons from being picked up in case they spawn right inside player's bounding box.
		return
	}
	if (ent.GetClassname() in LIST_ITEMS)
	{
		EntFireByHandle(ent,"RunScriptCode","GetReplace(self)")
		ent.AddSpawnFlags(2)
		return
	}
	if (ent.GetClassname().find("npc_sw_")!=null)
	{
		EntFireByHandle(ent,"RunScriptCode","GetReplace(self)")
		ent.AddSpawnFlags(2)
		return
	}
}

::GetReplace <- function(ent)
{
	if (!ent) return
	if (!ent.IsValid()) return
	
	if (ent.GetClassname()=="item_healthvial")
	{
		//printl(ent.GetModelName())
		//printl(ent.GetOrigin())
		local rep=
		{
			model="models/healthvial.mdl"
			origin=ent.GetOrigin().x+" "+ent.GetOrigin().y+" "+ent.GetOrigin().z
			angles=ent.GetAngles().x+" "+ent.GetAngles().y+" "+ent.GetAngles().z
			vscripts="items/item.nut"
			ResponseContext="item:health_vial,count:1"
		}
		
		local replacement=SpawnEntityFromTable("prop_physics",rep)
		replacement.SetVelocity(ent.GetVelocity())
		ent.Destroy()
		return
	}
	if (ent.GetClassname()=="item_wine")
	{
		local i=(RandomInt(0,1)==1)?"wine_b":"wine_a"
	
		local itemtable=
		{
			model=LIST_ITEMS[i].model
			origin=ent.GetOrigin().ToKVString()
			angles=ent.GetAngles().ToKVString()
			vscripts="items/item.nut"
			ResponseContext="item:"+i+",count:1"
			//spawnflags=8
		}
		local LootItem=SpawnEntityFromTable("prop_physics",itemtable)
		//printl(ent.GetOrigin())
		ent.Destroy();
		return
	}
	
	
	if (ent.GetClassname()=="item_battery")
	{
		//printl(ent.GetModelName())
		//printl(ent.GetOrigin())
		local rep=
		{
			model="models/healthvial.mdl"
			origin=ent.GetOrigin().x+" "+ent.GetOrigin().y+" "+ent.GetOrigin().z
			angles=ent.GetAngles().x+" "+ent.GetAngles().y+" "+ent.GetAngles().z
			vscripts="items/item.nut"
			ResponseContext="item:health_vial,count:1"
		}
		
		local replacement=SpawnEntityFromTable("prop_physics",rep)
		replacement.SetVelocity(ent.GetVelocity())
		ent.Destroy()
		return
	}
	if (ent.GetClassname()=="item_ammo_ar2_altfire")
	{
		//printl(ent.GetModelName())
		//printl(ent.GetOrigin())
		local rep=
		{
			model="models/items/repairkit.mdl"
			origin=ent.GetOrigin().x+" "+ent.GetOrigin().y+" "+ent.GetOrigin().z
			angles=ent.GetAngles().x+" "+ent.GetAngles().y+" "+ent.GetAngles().z
			vscripts="items/item.nut"
			ResponseContext="item:item_wep_repair_kit,count:1"
		}
		
		local replacement=SpawnEntityFromTable("prop_physics",rep)
		replacement.SetVelocity(ent.GetVelocity())
		ent.Destroy()
		return
	}
	if (ent.GetClassname()=="item_healthkit")
	{
		//printl(ent.GetModelName())
		//printl(ent.GetOrigin())
		local rep=
		{
			model="models/items/healthkit.mdl"
			origin=ent.GetOrigin().x+" "+ent.GetOrigin().y+" "+ent.GetOrigin().z
			angles=ent.GetAngles().x+" "+ent.GetAngles().y+" "+ent.GetAngles().z
			vscripts="items/item.nut"
			ResponseContext="item:health_kit,count:1"
		}
		
		local replacement=SpawnEntityFromTable("prop_physics",rep)
		replacement.SetVelocity(ent.GetVelocity())
		ent.Destroy()
		return
	}
	if (ent.GetClassname()=="weapon_smg1"&&ent.GetOwner())
	{
		//printl(ent.GetModelName())
		//printl(ent.GetOrigin())
		local orig=ent.GetOrigin()+Vector(0,0,48)
		local ang=ent.GetOwner().GetAngles()
		local vel=Vector(RandomInt(-60,60),RandomInt(-60,60),RandomInt(-60,60))
		
		if (ent.GetOwner()) ent.GetOwner().AddSpawnFlags(8192);
		if (ent.GetOwner()) ent.GetOwner().GetOrCreatePrivateScriptScope().DropWeapon<-function()
		{
			if (!("clip" in this)) this.clip<-(45)
			
			orig=self.GetOrigin()+Vector(0,0,48)
		    ang=self.GetAngles()
		    vel=Vector(RandomInt(-60,60),RandomInt(-60,60),RandomInt(-60,60))
			
			local rep=
			{
				model="models/weapons/w_smg1.mdl"
				origin=orig.x+" "+orig.y+" "+orig.z
				angles=ang.x+" "+ang.y+" "+ang.z
				vscripts="items/item.nut"
				ResponseContext="item:weapon_mp7,count:1,clip:"+this.clip+",dur:"+RandomFloat(0.02,0.15)
			}
			
			local replacement=SpawnEntityFromTable("prop_physics",rep)
			replacement.SetVelocity(vel)
		}
		return
	}
	if (ent.GetClassname()=="weapon_pistol"&&ent.GetOwner())
	{
		//printl(ent.GetModelName())
		//printl(ent.GetOrigin())
		local orig=ent.GetOrigin()+Vector(0,0,48)
		local ang=ent.GetAngles()
		local vel=Vector(RandomInt(-60,60),RandomInt(-60,60),RandomInt(-60,60))
		
		if (ent.GetOwner()) ent.GetOwner().AddSpawnFlags(8192);
		if (ent.GetOwner()) ang=ent.GetOwner().GetAngles()
		if (ent.GetOwner()) ent.GetOwner().GetOrCreatePrivateScriptScope().DropWeapon<-function()
		{
			
			if (!("clip" in this)) this.clip<-18
			
			orig=self.GetOrigin()+Vector(0,0,48)
		    ang=self.GetAngles()
		    vel=Vector(RandomInt(-60,60),RandomInt(-60,60),RandomInt(-60,60))
			local rep=
			{
				model="models/weapons/w_pistol.mdl"
				origin=orig.x+" "+orig.y+" "+orig.z
				angles=ang.x+" "+ang.y+" "+ang.z
				vscripts="items/item.nut"
				ResponseContext="item:weapon_pistol,count:1,clip:"+this.clip+",dur:"+RandomFloat(0.02,0.15)
			}
			
			local replacement=SpawnEntityFromTable("prop_physics",rep)
			replacement.SetVelocity(vel)
		}
		return
	}
	if (ent.GetClassname()=="weapon_shotgun"&&ent.GetOwner())
	{
		//printl(ent.GetModelName())
		//printl(ent.GetOrigin())
		local orig=ent.GetOrigin()+Vector(0,0,48)
		local ang=ent.GetOwner().GetAngles()
		local vel=Vector(RandomInt(-60,60),RandomInt(-60,60),RandomInt(-60,60))
		
		if (ent.GetOwner()) ent.GetOwner().AddSpawnFlags(8192);
		if (ent.GetOwner()) ent.GetOwner().GetOrCreatePrivateScriptScope().DropWeapon<-function()
		{
			orig=self.GetOrigin()+Vector(0,0,48)
		    ang=self.GetAngles()
		    vel=Vector(RandomInt(-60,60),RandomInt(-60,60),RandomInt(-60,60))
			local rep=
			{
				model="models/weapons/w_shotgun.mdl"
				origin=orig.x+" "+orig.y+" "+orig.z
				angles=ang.x+" "+ang.y+" "+ang.z
				vscripts="items/item.nut"
				ResponseContext="item:weapon_shotgun,count:1,clip:"+this.clip+",dur:"+RandomFloat(0.02,0.15)
			}
			
			local replacement=SpawnEntityFromTable("prop_physics",rep)
			replacement.SetVelocity(vel)
		}
		return
	}
	if (ent.GetClassname()=="weapon_357"&&ent.GetOwner())
	{
		//printl(ent.GetModelName())
		//printl(ent.GetOrigin())
		local orig=ent.GetOrigin()+Vector(0,0,48)
		local ang=ent.GetOwner().GetAngles()
		local vel=Vector(RandomInt(-60,60),RandomInt(-60,60),RandomInt(-60,60))
		
		if (ent.GetOwner()) ent.GetOwner().AddSpawnFlags(8192);
		if (ent.GetOwner()) ent.GetOwner().GetOrCreatePrivateScriptScope().DropWeapon<-function()
		{
			orig=self.GetOrigin()+Vector(0,0,48)
		    ang=self.GetAngles()
		    vel=Vector(RandomInt(-60,60),RandomInt(-60,60),RandomInt(-60,60))
			local rep=
			{
				model="models/weapons/w_357.mdl"
				origin=orig.x+" "+orig.y+" "+orig.z
				angles=ang.x+" "+ang.y+" "+ang.z
				vscripts="items/item.nut"
				ResponseContext="item:weapon_357,count:1,clip:"+this.clip+",dur:"+RandomFloat(0.02,0.15)
			}
			
			local replacement=SpawnEntityFromTable("prop_physics",rep)
			replacement.SetVelocity(vel)
		}
		return
	}
	if (ent.GetClassname()=="weapon_frag")
	{
		//printl(ent.GetModelName())
		//printl(ent.GetOrigin())
		
		if (ent.GetOwner()) return;
		
		local rep=
		{
			model="models/weapons/w_grenade.mdl"
			origin=ent.GetOrigin().x+" "+ent.GetOrigin().y+" "+ent.GetOrigin().z
			angles=ent.GetAngles().x+" "+ent.GetAngles().y+" "+ent.GetAngles().z
			vscripts="items/item.nut"
			ResponseContext="item:weapon_frag,count:1"
		}
		
		local replacement=SpawnEntityFromTable("prop_physics",rep)
		replacement.SetVelocity(ent.GetVelocity())
		ent.Destroy()
		return
	}
	if (ent.GetClassname()=="item_ammo_smg1")
	{
		//printl(ent.GetModelName())
		//printl(ent.GetOrigin())
		
		local Is556=(ent.entindex()%2)==0
		
		local rep=
		{
			model=(Is556) ? "models/items/ammo_556.mdl" : "models/items/ammo_45.mdl"
			origin=ent.GetOrigin().x+" "+ent.GetOrigin().y+" "+ent.GetOrigin().z
			angles=ent.GetAngles().x+" "+ent.GetAngles().y+" "+ent.GetAngles().z
			vscripts="items/item.nut"
			ResponseContext="item:item_ammo_smg,count:"+RandomInt(5,25)
			ResponseContext=(Is556) ? ("item:item_ammo_556,count:"+RandomInt(5,25)) : ("item:item_ammo_45,count:"+RandomInt(5,25))
		}
		
		local replacement=SpawnEntityFromTable("prop_physics",rep)
		replacement.SetVelocity(ent.GetVelocity())
		ent.Destroy()
		return
	}
	
	if (ent.GetClassname() in LIST_ITEMS)
	{
		local iteminfo=LIST_ITEMS[ent.GetClassname()]
		
		if (ent.GetOwner()) 
		{	
			//printl("WEAPON HAS OWNER")
			ent.Destroy()
			return
		}
		
		local rep=
		{
			model=iteminfo.model
			origin=ent.GetOrigin().x+" "+ent.GetOrigin().y+" "+ent.GetOrigin().z
			angles=ent.GetAngles().x+" "+ent.GetAngles().y+" "+ent.GetAngles().z
			vscripts="items/item.nut"
			ResponseContext="item:"+ent.GetClassname()+",count:"+clamp(ent.GetKeyValue("max_health").tointeger(),1,iteminfo.maxstack)+",clip:"+max(0,ent.GetKeyValue("cycle").tointeger())
			spawnflags=ent.GetSpawnFlags()
		}
		
		if (ent.GetClassname().find("weapon")!=null) rep.ResponseContext="item:"+ent.GetClassname()+",count:"+clamp(ent.GetKeyValue("max_health").tointeger(),1,iteminfo.maxstack)+",clip:"+max(0,ent.GetKeyValue("cycle").tointeger())+",dur:"+RandomFloat(0.2,0.5)
		//local tabl={}
		//SaveEntityKVToTable(ent, tabl)
		//foreach(k,v in tabl) printl(k+": "+v)
		
		local replacement=SpawnEntityFromTable("prop_physics",rep)
		replacement.SetVelocity(ent.GetVelocity())
		ent.Destroy()
		return
	}
	
	if (ent.GetClassname().find("npc_sw_")!=null)
	{
		local ListName=ent.GetClassname().slice("npc_sw_".len()).toupper()
		if (!(ListName in LIST_ENEMIES)) return;
		
		local tabl={}
		tabl.squadname<-""
		SaveEntityKVToTable(ent, tabl)
		//foreach(k,v in tabl) printl(k+": "+v)
		
		
		local enemy={
			origin=ent.GetOrigin().ToKVString()
			angles=ent.GetAngles().ToKVString()
			squadname=tabl.parentname
			parentname=tabl.parentname
		}
		
		local enemyinfo=LIST_ENEMIES[ListName]
		foreach (k,v in enemyinfo)
		{
			enemy.rawset(k,enemyinfo[k])
		}
		
		enemyinfo.rawset("squadname",tabl.parentname)
		
		local enemyentity = SpawnEntityFromTable(enemyinfo.classname,enemyinfo)
		enemyentity.SetOrigin(ent.GetOrigin())
		enemyentity.SetAngles(ent.GetAngles())
		if ("model" in enemy) enemyentity.SetModel(enemyinfo.model)
		if ("maxhealth" in enemy) enemyentity.SetMaxHealth(enemy.maxhealth)
		if ("health" in enemy) enemyentity.SetHealth(enemy.health)
		enemyentity.GetOrCreatePrivateScriptScope().EnemyName<-ListName
		
		ent.Destroy()
		return
	}
}

IncludeScript("vs_math.nut")

function WorldPosToScreen(targetPos)
{
	local InterfaceFOV=Convars.GetFloat("fov_desired")	//1.17 multiplier is needed, since after enormous tests it turned out sam's func didn't really work with real fov values. That or aspect ratio is wrong.
	
	local aspectRatio = ScreenWidth().tofloat()/ScreenHeight().tofloat();

	local viewOrigin = MainViewOrigin();
	local viewAngles = MainViewAngles()
	local viewForward = MainViewForward()
	local viewRight = MainViewRight()
	local viewUp = MainViewUp()
	local fovx = VS.CalcFovX( InterfaceFOV, aspectRatio * (3.0/4.0) );

	local worldToScreen = VS.VMatrix();
	VS.WorldToScreenMatrix(
		worldToScreen,
		viewOrigin,
		viewForward,
		viewRight,
		viewUp,
		fovx,
		aspectRatio,
		8.0,
		MAX_COORD_FLOAT );
		
	local out=VS.WorldToScreen( targetPos, worldToScreen )
	return out*1
}
/*
function Talker(params)
{
	printl(this.self);
	local text=Localize.GetTokenAsUTF8(params.GetSoundName())
	text=split(text,">")[split(text,">").len()-1]
	text=split(text,"/")[split(text,"/").len()-1]
	NetMsg.Start("SendCC")
	NetMsg.WriteString(text)
	if (params.HasOrigin()) NetMsg.WriteVec3Coord(params.GetOrigin())
	else NetMsg.WriteVec3Coord(this.self.GetOrigin())
	NetMsg.Send(player,true)
}
*/

function OnEntityKilled(a)
{
	if (EntIndexToHScript(a.entindex_attacker)==player)
	{
		SW_TABLE.iPlayerKills++;
		
		        // === РАНГ: убийство ===
        local victim = EntIndexToHScript(a.entindex_killed);
        local baseGain = (EntIndexToHScript(a.entindex_killed).GetMaxHealth()/2.5).tointeger();
        
        SW_AddRank(baseGain);
        
        // Headshot
        if ("KilledByHeadshot" in victim.GetOrCreatePrivateScriptScope())
            SW_AddRank(15);
        
        // Быстрая серия
        if (Time() - SW_LAST_KILL_TIME < 3.0)
            SW_AddRank(15);
		
		if (Time() - SW_LAST_KILL_TIME < 1.0)
            SW_AddRank(10);
        
        // Полное HP
        if (player.GetHealth() >= PlayerMaxHealth)
            SW_AddRank(20);
        
        SW_LAST_KILL_TIME = Time();
		
		if (!AbilitiesActive&&!(Entities.FindByName(null,"PlayerModel"))) 
		{
			AddPlayerHeat(EntIndexToHScript(a.entindex_killed).GetMaxHealth()/10.0)
		}
		if (GetNamedEnt("stamina_system").GetScriptScope().RageActive)
		{
			SendToConsole("host_timescale 0.4")
			SendToConsole("mat_autoexposure_min 30")
			Entities.First().SetContextThink("RageSlowmo",function (_) 
			{ 
				SendToConsole("host_timescale 1")
				SendToConsole("mat_autoexposure_min 0.5")
			}.bindenv(this),0.2 )
		}
	}
	//printl(EntIndexToHScript(a.entindex_killed).GetHealth())
	//printl(a.damagebits)
	//printl("KilledByHeadshot" in EntIndexToHScript(a.entindex_killed).GetOrCreatePrivateScriptScope())
	
	local Chance=0
	
	if (a.damagebits==8194)
	{
		Chance=25
	}
	if (a.damagebits==4098)
	{
		Chance=25
	}
	if (a.damagebits==4096)
	{
		Chance=10
	}
	if ("KilledByHeadshot" in EntIndexToHScript(a.entindex_killed).GetOrCreatePrivateScriptScope())
	{
		Chance+=25
	}
	
	
	// Guaranteed drop on melee damage
	if (a.damagebits==128)
	{
		Chance=100
	}
	
	// Never drop on explosive damage
	if (a.damagebits==64)
	{
		Chance=0
	}
	
	//printl("Drop Chance: "+Chance+"%")
	
	///// Drop chances currently unused because they're more annoying. I guess just make them drop ammo more often instead of just ALWAYS weapons??? it worked in moddb demo.
	
	//if (RandomInt(0,100)<=Chance&&("DropWeapon" in EntIndexToHScript(a.entindex_killed).GetOrCreatePrivateScriptScope()))
	//{
	local Victim=EntIndexToHScript(a.entindex_killed).GetOrCreatePrivateScriptScope()
	if ("DropCustomWeapon" in Victim)
	{
		Victim.DropCustomWeapon()
	}
	else if ("DropWeapon" in Victim)
	{
		Victim.DropWeapon()
	}
	//}
}

function OnEntSpawned(ent)
{
	ent.ValidateScriptScope()
	ent.GetScriptScope().InputStopFollowingPlayer<-function()
	{
		ent.StopFollowingPlayer()
	}
	
}

//ListenToGameEvent("entity_killed",CheatDeath,"")
if (SERVER_DLL) ListenToGameEvent("player_spawn",OnSpawnedPlayer.bindenv(this),"");
if (SERVER_DLL) Hooks.Add(this,"OnEntityCreated",function (ent) {EntFireByHandle(ent,"SetDamageFilter","SW_DMG")},"healthh");
if (SERVER_DLL) Hooks.Add(this,"OnEntityCreated",function (ent) {InitCustomWeapon(ent)},"customweapon_init");

if (SERVER_DLL) Hooks.Add(this,"OnEntitySpawned",function (ent) {OnEntSpawned(ent)},"custom_init");

//if (SERVER_DLL) Hooks.Add(this,"OnEntitySpawned",SetPHealth,"healthh");
if (SERVER_DLL) ListenToGameEvent("entity_killed", OnEntityKilled, "RecordDeath")
//if (SERVER_DLL) Entities.First().SetContextThink("setheal",function(_) {SetPHealth()}.bindenv(this),1);
//if (SERVER_DLL) OnPostSpawn();

if (SERVER_DLL)
{
	NetMsg.Receive("GetArmor", function( player )
	{
		NetMsg.Start("GetArmor")
		NetMsg.WriteShort(player.GetArmor().tointeger())
		NetMsg.Send(player,true)
	} );	
	
	NetMsg.Receive("RequestAUXPower", function( player )
	{
		NetMsg.Start("RequestAUXPower")
		NetMsg.WriteFloat(player.GetAuxPower())
		NetMsg.WriteFloat((player.GetScriptScope().FlashLightEnergy/player.GetScriptScope().MaxFlashLightEnergy)*100.0)
		NetMsg.WriteBool(player.GetScriptScope().FlashLightState)
		NetMsg.Send(player,true)
	} );	
	
	local SpeechBubble=null
	
	local firsttime=false
	
	
	local HeatActionPrev=false;
	local RevivePrev=false;
	
	function Crosshair()
	{
		if (!firsttime) IncludeScript("use.nut");
		
		if (HeatActionReady())
		{
			if (!HeatActionPrev) 
			{
				NetMsg.Start("HeatActionReady")
				NetMsg.Send(player,true)
			}
			HeatActionPrev=true
		}
		else 
		{
			if (HeatActionPrev) 
			{
				NetMsg.Start("HeatActionUnReady")
				NetMsg.Send(player,true)
			}
			HeatActionPrev=false;
		}
		firsttime=true
		//local CrosshairTrace = TraceLineComplex(player.EyePosition(), player.EyePosition()+player.GetEyeForward()*90, player, MASK_SHOT, 0)
		
		local CrosshairEntity=FindUseEntity()
		
		if (CrosshairEntity&&("Downed" in CrosshairEntity.GetOrCreatePrivateScriptScope())&&CrosshairEntity.GetOrCreatePrivateScriptScope().Downed)
		{
			if (!RevivePrev)
			{
				NetMsg.Start("ReviveReady")
				NetMsg.Send(player,true)
			}
			
			RevivePrev=true
		}
		else
		{
			if (RevivePrev)
			{
				NetMsg.Start("ReviveUnReady")
				NetMsg.Send(player,true)
			}
			
			RevivePrev=false
		}
		
		if (CrosshairEntity) if (CrosshairEntity.GetContext("item").len()>1)
		{
			NetMsg.Start("CrosshairMark")
			NetMsg.WriteString(CrosshairEntity.GetContext("item"))
			NetMsg.WriteString(CrosshairEntity.GetModelName() ? CrosshairEntity.GetModelName() : "None")
			if (CrosshairEntity.GetContext("count").len()>0) NetMsg.WriteShort(CrosshairEntity.GetContext("count").tointeger())
			else NetMsg.WriteShort(1)
			NetMsg.WriteEntity(CrosshairEntity)
			NetMsg.WriteBool(false)
			NetMsg.Send(player,true)
			return 0
		}
			NetMsg.Start("CrosshairMark")
			if (CrosshairEntity) {
				NetMsg.WriteString(CrosshairEntity.GetClassname());
				NetMsg.WriteString(CrosshairEntity.GetModelName() ? CrosshairEntity.GetModelName() : "None")
				NetMsg.WriteEntity(CrosshairEntity);
				
				if (CrosshairEntity.IsNPC()&&CrosshairEntity.GetRelationship(player)==3) 
					NetMsg.WriteBool(true);
				else NetMsg.WriteBool(false);
				
				if (SW_DIALOGUE_NPCS.find(CrosshairEntity.entindex())!=null&&SpeechBubble==null)
				{
					SpeechBubble=SpawnEntityFromTable("env_sprite",{
						model="voice/icntlk_pl.vmt"
						scale=0.15
						rendermode=9
						HDRColorScale=0.35
						//renderamt=255
						renderfx=8
						origin=CrosshairEntity.EyePosition()+Vector(0,0,12)
					})
					SpeechBubble.SetParent(CrosshairEntity,"")
					printl("created speech bubble")
				}
				else
				{
					if (SpeechBubble&&SW_DIALOGUE_NPCS.find(CrosshairEntity.entindex())==null) 
					{
						SpeechBubble.Destroy()
						SpeechBubble=null
					}
				}
			}
			else
			{
				if (SpeechBubble) SpeechBubble.Destroy()
				SpeechBubble=null
				
				NetMsg.WriteString("None");
			}
			NetMsg.Send(player,true)
		return 0
	}
	Entities.First().SetContextThink("CrosshairMarker",function (_) { Crosshair();return 0}.bindenv(this),0.01 )
	
	Convars.RegisterCommand( "sw_ally", function(...)
	{
		if (vargv[1]) 
		{
			InitCompanion(vargv[1])
			return 
		}
	}.bindenv(this), "", 0 )
	
	Convars.RegisterCommand( "rage", function(...)
	{
		Rage()
	}.bindenv(this), "", 0 )
	
	Convars.RegisterCommand( "uma", function(...)
	{
		if ( vargv[1] == "100" ) 
		{
			GiveItem("weapon_pipe")
			GiveItem("weapon_pistol",1,18)
			GiveItem("health_kit")
			GiveItem("item_ammo_pistol",54)
			return 
		}
		if ( vargv[1] == "101" ) 
		{
			GiveItem("weapon_pipe")
			GiveItem("weapon_pistol",1,18)
			GiveItem("weapon_357",1,6)
			GiveItem("weapon_smg45",1,30)
			GiveItem("weapon_vector",1,30)
			GiveItem("weapon_m590",1,8)
			
			GiveItem("weapon_shotgun",1,8)
			GiveItem("weapon_mp7",1,45)
			GiveItem("weapon_m4a1",1,30)
			GiveItem("weapon_pistol",1,30)
			GiveItem("health_kit")
			AddPlayerMoney(5000)
			return 
		}
		if ( vargv[1] == "102" ) 
		{
			AddPlayerMoney(5000)
			AddPlayerXP(5000)
			return 
		}
		if ( vargv[1] == "103" ) 
		{
			SpawnItem("item_ammo_shotgun",20)
			SpawnItem("item_ammo_45",80)
			SpawnItem("item_ammo_556",120)
			SpawnItem("item_ammo_pistol",72)
			SpawnItem("item_ammo_357",18)
			return 
		}
		if ( vargv[1] == "104" ) 
		{
			foreach(skill in SKILLS)
				if (!skill.Unlocked) skill.ForceUnlock();
				
			return 
		}
	}, "", 0 )
	
	Convars.RegisterCommand( "unload_weapon", function(...)
	{
		if ("Weapon" in aPlayer&&aPlayer.Weapon.clip>0)
		{
			foreach (i,Cell in INVENTORY)
			{
				if (i>=72) break;
				
				if (Cell&&((typeof Cell)!="integer")&&Cell.WeaponInvID==aPlayer.Weapon.InvSlot)
				{
					Cell.UnloadWeapon(true)
					return;
				}
			}
		}
	}, "", 0 )
}