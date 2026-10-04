IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("Weapon_F2000.Shoot")
self.PrecacheSoundScript("SW.Weapon.DrawRifle")

self.PrecacheSoundScript("Weapon_F2000.ZoomIn")
self.PrecacheSoundScript("Weapon_F2000.ZoomOut")

local weapon=null

function Think2(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_f2000") return 0.005
	weapon.Update()
	//printl("thinking")
	return 0.005
}
::aPlayer<-null
function InitWeapon(...)
{
	//IncludeScript("weapons/weapon_base.nut")
	aPlayer=player.GetOrCreatePrivateScriptScope()
	
	local WeaponInfo=
	{
		AmmoType="item_ammo_556"
		Model="models/weapons/v_f2000.mdl"
		Firerate=0.07
		RecoilMult=4
		InAccuracy=0.2
		AccuracyBonus=2
		Spread=0.2
		Damage=8
		Clip=30
		ShootSound="Weapon_F2000.Shoot"
		DrawSound="SW.Weapon.DrawRifle"
		Scoped=false
	}
	
	WeaponInfo.SecondaryAttack<-function(weapon)
	{
		local VM=player.GetViewModel(0)
		if (reloading&&Info.Scoped)
		{
			Info.Scoped=!Info.Scoped
			nextattack=Time()+0.2
			
			player.EmitSound("Weapon_F2000.Zoom"+((Info.Scoped) ? "In" : "Out"))
			
			NetMsg.Start("F2000Scope")
			NetMsg.WriteBool(Info.Scoped)
			NetMsg.Send(player,true)
			
			NetMsg.Start("F2000ScopeCrosshair")
			NetMsg.WriteBool(Info.Scoped)
			NetMsg.Send(player,true)
			
			if (Info.Scoped) PlayerWeaponSpeed=0.3;
			else PlayerWeaponSpeed=1;
			
			Spread=(Info.Scoped ? 0 : 0.2)
			firerate=(Info.Scoped ? 0.078 : 0.07)
			AccuracyBonus=(Info.Scoped ? 0.3 : 2)
			
			player.SetFOV((Info.Scoped==true ? 24 : Convars.GetInt("fov_desired")),0.15)
			
			if (Info.Scoped)
			{
				player.ViewPunch(Vector(-0.05,0,-0.1))
				ReduceShake=true;
			}
		}
		
		
		if (Info.Scoped) VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_IDLE")));
		if (Info.Scoped) VM.SetCycle(0);
		
		//printl(ReduceShake)
		
	
		if (player.GetButtons() & IN.ATTACK2&&(player.GetButtonLast() & IN.ATTACK2)&&Time()>nextattack)
		{
			Info.Scoped=!Info.Scoped
			nextattack=Time()+0.2
			
			//printl((Info.Scoped) ? "SCOPED" : "UNSCOPED")
			player.EmitSound("Weapon_F2000.Zoom"+((Info.Scoped) ? "In" : "Out"))
			
			NetMsg.Start("F2000Scope")
			NetMsg.WriteBool(Info.Scoped)
			NetMsg.Send(player,true)
			
			NetMsg.Start("F2000ScopeCrosshair")
			NetMsg.WriteBool(Info.Scoped)
			NetMsg.Send(player,true)
			
			if (Info.Scoped) PlayerWeaponSpeed=0.3;
			else PlayerWeaponSpeed=1;
			
			Spread=(Info.Scoped ? 0 : 0.2)
			firerate=(Info.Scoped ? 0.078 : 0.07)
			AccuracyBonus=(Info.Scoped ? 0.3 : 2)
			
			player.SetFOV((Info.Scoped==true ? 24 : Convars.GetInt("fov_desired")),0.15)
			
			if (Info.Scoped)
			{
				player.ViewPunch(Vector(-0.05,0,-0.1))
				ReduceShake=true;
			}
			else
			{
				player.ViewPunch(Vector(0.05,0,0.1))
				ReduceShake=false;
			}
			
		}
		
		Entities.First().SetContextThink("ResetScope",function(_)
		{
			if (Info.Scoped)
			{
				PlayerWeaponSpeed=1
				player.SetFOV(Convars.GetInt("fov_desired"),0)
				Info.Scoped=false
				
				NetMsg.Start("F2000Scope")
				NetMsg.WriteBool(Info.Scoped)
				NetMsg.Send(player,true)
				
				NetMsg.Start("F2000ScopeCrosshair")
				NetMsg.WriteBool(Info.Scoped)
				NetMsg.Send(player,true)
			}
			Spread=(Info.Scoped ? 0 : 0.2)
			firerate=(Info.Scoped ? 0.078 : 0.07)
			AccuracyBonus=(Info.Scoped ? 0.3 : 2)
			
		}.bindenv(this),0.01)
		
	}
	
	weapon=C_BaseWeapon("weapon_f2000",WeaponInfo)
	Init(weapon)
}
Entities.EnableEntityListening()
//Entities.First().SetContextThink(UniqueString("")+"M4A1",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}
