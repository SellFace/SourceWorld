IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("SW.Weapon.DrawRifle")
self.PrecacheSoundScript("Weapon_Springfield.SinglShotReload")
self.PrecacheSoundScript("Weapon_Springfield.Shoot")
self.PrecacheSoundScript("Weapon_SniperRifle.Special1")
self.PrecacheSoundScript("Weapon_SniperRifle.Special2")

local weapon=null

function Think3(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_springfield") return 0.005
	weapon.Update()
	return 0.005
}
//::aPlayer<-null
function InitWeapon(...)
{
	//IncludeScript("weapons/weapon_base.nut")
	aPlayer=player.GetOrCreatePrivateScriptScope()
	local WeaponInfo=
	{
		AmmoType="item_ammo_308"
		Model="models/weapons/v_springfield.mdl"
		Firerate=1.5
		RecoilMult=40
		InAccuracy=0.05
		Damage=50
		Clip=5
		ShootSound="Weapon_Springfield.Shoot"
		SemiAuto=true
		RecoveryBonus=10
		AccuracyBonus=130	//actually this changes how inaccurate it gets after each shot. the bigger number is more inaccuracy
		Spread=1
		RecoverySpeed=-0.09
		Scoped=false
		
		SecondaryAttack=function(hnd)
		{			
			//if (player.GetButtonPressed() & IN.ATTACK) printl("attacking! "+Time())		
			if (reloading) return
			local VM=player.GetViewModel(0)
			
			local AttackSequence=VM.SelectWeightedSequence(VM.LookupActivity("ACT_VM_PRIMARYATTACK"),1)
			
			if (VM.GetSequence()==AttackSequence)
			{
				local cycle=VM.GetCycle()
				if (cycle>0.3&&cycle<0.35) player.ViewPunch(Vector(0,0,-1)*0.8/((!Info.Scoped).tointeger()*2+1))
				if (cycle>0.5&&cycle<0.55) player.ViewPunch(Vector(0,0,1.5)*0.8/((!Info.Scoped).tointeger()*2+1))
			}
			
			
			if (player.GetButtons() & IN.ATTACK2&&(nextattack+0.2)<Time()&&(Auto||((!LastPress)&&(player.GetButtonLast() & IN.ATTACK2))))
			{
				if (player.GetButtons() & IN.SPEED&&player.GetVelocity().Length2D()>200) return;
				
				local wepitem=INVENTORY[GetWeaponFromInv(aPlayer.DualWield[0])]
				local wepdur=(wepitem.Durability*1.0)/(wepitem.MaxDurability*1.0)
				local JamChance=(pow((0.2-wepdur*0.5),0.5)-0.31)*(15.0/maxclip)
				
				
				Info.Scoped=!Info.Scoped
				
				printl(Info.Scoped)
				
				player.GetActiveWeapon().EmitSound("Weapon_SniperRifle.Special1")
				
				if (Info.Scoped) player.SetFOV(25,0);
				if (!Info.Scoped) player.SetFOV(Convars.GetInt("fov_desired")-10,0);
				
				NetMsg.Start("WeaponTwitch");
				NetMsg.Send(player, true);
				
				player.SetFOV((Info.Scoped==true ? 15 : Convars.GetInt("fov_desired")),0.15)
				Spread=(Info.Scoped ? -10 : 1)
				RecoilMult=(Info.Scoped ? 15 : 40)
				
				if (Info.Scoped) PlayerWeaponSpeed=0.2;
				else PlayerWeaponSpeed=1;
				
				NetMsg.Start("SniperScope")
				NetMsg.WriteBool(Info.Scoped)
				NetMsg.Send(player,true)
				
				player.ViewPunch(Vector(0.3,0,0.3))
				
				nextattack=Time()+0.15
			}
			
			if (Info.Scoped)
			{
				local crouch=((player.GetFlags() & 3)==3).tointeger()
				if ((player.GetButtons() & IN.SPEED) && player.GetAuxPower()>20&&!(player.GetFlags() & FL_DUCKING)) crouch+=4;
				if (player.GetAuxPower()<25) crouch=RemapVal(player.GetAuxPower(),0,25,-0.99,0);
				player.ViewPunch(Vector(cos(Time()*2),sin(Time()),0)*(0.009+player.GetVelocity().Length()/7000.0)/(crouch+1.0))
			}
			
			
			Entities.First().SetContextThink("ResetScope",function(_)
			{
				if (Info.Scoped)
				{
					PlayerWeaponSpeed=1
					player.SetFOV(Convars.GetInt("fov_desired"),0)
					Info.Scoped=false
					Spread=1
					RecoilMult=40
					
					NetMsg.Start("SniperScope")
					NetMsg.WriteBool(false)
					NetMsg.Send(player,true)
				}
			}.bindenv(this),0.01)
			
		}
		
		
	}
	
	weapon=C_BaseWeapon("weapon_springfield",WeaponInfo)
	Init(weapon)
}
Entities.EnableEntityListening()
Entities.First().SetContextThink(UniqueString("")+"SPRING",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}