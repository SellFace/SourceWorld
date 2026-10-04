IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("Weapon_Shotgun.Special1")
self.PrecacheSoundScript("Weapon_Shotgun.Single")
self.PrecacheSoundScript("SW.Weapon.DrawRifle")

local weapon=null

function Think4(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_shotgun") return 0.005
	weapon.Update()
	return 0.005
}
::aPlayer<-null
function InitWeapon(...)
{
	//IncludeScript("weapons/weapon_base.nut")
	aPlayer=player.GetOrCreatePrivateScriptScope()
	local WeaponInfo=
	{
		AmmoType="item_ammo_shotgun"
		Model="models/weapons/v_shotgun.mdl"
		Firerate=0.25
		RecoilMult=10
		InAccuracy=10
		Damage=6
		BulletsPerShot=8
		IsShotgun=true
		Clip=8
		ShootSound="Weapon_Shotgun.Single"
		SemiAuto=false
		ReloadSound="Weapon_Shotgun.Reload"
		DrawSound="SW.Weapon.DrawRifle"
		ReloadsSingly=true
		
		
		SecondaryAttack=function(hnd)
		{
			//if (player.GetButtonPressed() & IN.ATTACK) printl("attacking! "+Time())
			if (ReloadsSingly&&reloading) return;
			local VM=player.GetViewModel(0)
			if (player.GetButtons() & IN.ATTACK2&&nextattack<Time()&&clip>1&&(Auto||((!LastPress)&&(player.GetButtonLast() & IN.ATTACK2))))
			{
				if (player.GetButtons() & IN.SPEED&&player.GetVelocity().Length2D()>200) return;
				
				local wepitem=INVENTORY[GetWeaponFromInv(aPlayer.DualWield[0])]
				local wepdur=(wepitem.Durability*1.0)/(wepitem.MaxDurability*1.0)
				local JamChance=(pow((0.2-wepdur*0.5),0.5)-0.31)*(15.0/maxclip)
				printl(JamChance)
				if (!Jammed&&wepdur<0.2&&(RandomFloat(0,1)<JamChance))
				{
					Jammed=true
					LastJam=Time()
				}
				if (Jammed)
				{
					player.EmitSound("Weapon_Shotgun.Empty")
					NetMsg.Start("WeaponTwitch");
					NetMsg.Send(player, true);
					nextattack=Time()+firerate
					NetMsg.Start("WeaponJam");
					NetMsg.Send(player, true);
					return
				}
				
				
				shotsfired++
				clip--
				player.EmitSound(ShootSound)

				accuracy=InAccuracy/3.0
				//VM.ResetSequenceInfo()
				//player.DoMuzzleFlash()
				player.GetActiveWeapon().SendWeaponAnim(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_PRIMARYATTACK")))
				/*
				if (shotsfired<3&&2==3)
				{
					if (VM.GetSequence() == VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_PRIMARYATTACK")) && VM.LookupActivity("ACT_VM_RECOIL1") != -1) {
					VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_RECOIL1")))
					}
					else {
						VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_PRIMARYATTACK")))
					}
				}
				else
				{
					if (VM.GetSequence() == VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_RECOIL2")) && VM.LookupActivity("ACT_VM_RECOIL3") != -1) {
					VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_PRIMARYATTACK_SILENCED")))
					}
					else {
						VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_PRIMARYATTACK")))
					}
				}*/
				VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_PRIMARYATTACK")))
				muzzleFlashTable.lightfov = RandomFloat(85, 100)
				local flashEnt = SpawnEntityFromTable("env_projectedtexture", muzzleFlashTable)
				local flashEnt2 = SpawnEntityFromTable("light_dynamic", muzzlelight)
				local attach=VM.LookupAttachment("muzzle")
				local muzzle=VM.GetAttachmentOrigin(attach)+Vector(0,0,player.GetBoundingMaxs().z-8)+player.GetEyeForward()*3
				EntFireByHandle(flashEnt2, "SetParent", "!player", 0)
				//debugoverlay.Text(muzzle,"shoot",0.5)
				flashEnt.SetOrigin(player.ShootPosition())
				flashEnt2.SetOrigin(player.ShootPosition()+player.GetEyeForward()*40)
				flashEnt2.SetOrigin(muzzle)
				local flashAngle = VectorAngles(player.GetAutoaimVector(AUTOAIM_SCALE_DEFAULT))
				flashAngle.z = RandomFloat(0, 360)
				flashEnt.SetAngles(flashAngle)
				EntFireByHandle(flashEnt, "Kill", "", min(firerate * 0.8, 0.025))
				EntFireByHandle(flashEnt2, "Kill", "", min(firerate * 5.9, 0.075))
				local punch=Vector(RandomFloat(-0.1,-0.2),RandomFloat(-0.05,0.05),0)
				if (!IsShotgun) player.ViewPunch(punch*(1+shotsfired/10*1.2)/crouching*RecoilMult/1.5);
				else player.ViewPunch(punch*RecoilMult*2);
				
				if (!IsShotgun) ShakePlayerScreen(200*RecoilMult,4*(punch*(1+shotsfired/10*1.2)/crouching*RecoilMult/1.5).Length(),1.5*RecoilMult);
				else ShakePlayerScreen(200*RecoilMult,4*(punch*RecoilMult).Length(),1.5*RecoilMult,true);


				local ran=rand()
				local info = CreateFireBulletsInfo(BulletsPerShot, player.ShootPosition()+player.GetEyeForward()*10, player.GetAutoaimVector(AUTOAIM_SCALE_DEFAULT), Vector(0.02,0.02,0.02)*accuracy, Damage, player)
				info.SetTracerFreq(1)
				info.SetAmmoType(3)
				info.SetDistance(5000)
				player.GetActiveWeapon().FireBullets(info);
				DecreaseDurability(1)
				DestroyFireBulletsInfo(info)
				
				Entities.First().SetContextThink("DelayedAttackSHTGN",function(_)
				{
					local wepitem=INVENTORY[GetWeaponFromInv(aPlayer.DualWield[0])]
					local wepdur=(wepitem.Durability*1.0)/(wepitem.MaxDurability*1.0)
					local JamChance=(pow((0.2-wepdur*0.5),0.5)-0.31)*(15.0/maxclip)
					printl(JamChance)
					if (!Jammed&&wepdur<0.2&&(RandomFloat(0,1)<JamChance))
					{
						Jammed=true
						LastJam=Time()
					}
					if (Jammed)
					{
						player.EmitSound("Weapon_Shotgun.Empty")
						NetMsg.Start("WeaponTwitch");
						NetMsg.Send(player, true);
						nextattack=Time()+firerate
						NetMsg.Start("WeaponJam");
						NetMsg.Send(player, true);
						return
					}
				
				
					shotsfired++
					clip--
					player.EmitSound(ShootSound)

					accuracy=InAccuracy/3.0
					//VM.ResetSequenceInfo()
					//player.DoMuzzleFlash()
					player.GetActiveWeapon().SendWeaponAnim(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_SECONDARYATTACK")))
					/*
					if (shotsfired<3&&2==3)
					{
						if (VM.GetSequence() == VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_PRIMARYATTACK")) && VM.LookupActivity("ACT_VM_RECOIL1") != -1) {
						VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_RECOIL1")))
						}
						else {
							VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_PRIMARYATTACK")))
						}
					}
					else
					{
						if (VM.GetSequence() == VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_RECOIL2")) && VM.LookupActivity("ACT_VM_RECOIL3") != -1) {
						VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_PRIMARYATTACK_SILENCED")))
						}
						else {
							VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_PRIMARYATTACK")))
						}
					}*/
					VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_SECONDARYATTACK")))
					muzzleFlashTable.lightfov = RandomFloat(85, 100)
					local flashEnt = SpawnEntityFromTable("env_projectedtexture", muzzleFlashTable)
					local flashEnt2 = SpawnEntityFromTable("light_dynamic", muzzlelight)
					local attach=VM.LookupAttachment("muzzle")
					local muzzle=VM.GetAttachmentOrigin(attach)+Vector(0,0,player.GetBoundingMaxs().z-8)+player.GetEyeForward()*3
					EntFireByHandle(flashEnt2, "SetParent", "!player", 0)
					//debugoverlay.Text(muzzle,"shoot",0.5)
					flashEnt.SetOrigin(player.ShootPosition())
					flashEnt2.SetOrigin(player.ShootPosition()+player.GetEyeForward()*40)
					flashEnt2.SetOrigin(muzzle)
					local flashAngle = VectorAngles(player.GetAutoaimVector(AUTOAIM_SCALE_DEFAULT))
					flashAngle.z = RandomFloat(0, 360)
					flashEnt.SetAngles(flashAngle)
					EntFireByHandle(flashEnt, "Kill", "", min(firerate * 0.8, 0.025))
					EntFireByHandle(flashEnt2, "Kill", "", min(firerate * 5.9, 0.075))
					local punch=Vector(RandomFloat(-0.1,-0.2),RandomFloat(-0.05,0.05),0)
					if (!IsShotgun) player.ViewPunch(punch*(1+shotsfired/10*1.2)/crouching*RecoilMult/1.5);
					else player.ViewPunch(punch*RecoilMult*2);
					
					if (!IsShotgun) ShakePlayerScreen(200*RecoilMult,4*(punch*(1+shotsfired/10*1.2)/crouching*RecoilMult/1.5).Length(),1.5*RecoilMult);
					else ShakePlayerScreen(200*RecoilMult,4*(punch*RecoilMult).Length(),1.5*RecoilMult,true);


					local ran=rand()
					local info = CreateFireBulletsInfo(BulletsPerShot, player.ShootPosition()+player.GetEyeForward()*10, player.GetAutoaimVector(AUTOAIM_SCALE_DEFAULT), Vector(0.02,0.02,0.02)*accuracy, Damage, player)
					info.SetTracerFreq(1)
					info.SetAmmoType(3)
					info.SetDistance(5000)
					player.GetActiveWeapon().FireBullets(info);
					DestroyFireBulletsInfo(info)
					nextattack=Time()+firerate*2
					//printl("what. double?")
					DecreaseDurability(1)
					NeedPump2=true;
					return
				}.bindenv(hnd),0.1);
				nextattack=Time()+firerate*2
			}
		}
		
	}
	
	weapon=C_BaseWeapon("weapon_shotgun",WeaponInfo)
	Init(weapon)
}
Entities.EnableEntityListening()
Entities.First().SetContextThink(UniqueString("")+"SHOTGUN",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}