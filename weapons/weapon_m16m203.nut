IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("SW.Weapon.DrawRifle")
self.PrecacheSoundScript("Weapon_M16A2_M203.Draw")
self.PrecacheSoundScript("Weapon_M16A2_M203.Bolt")
self.PrecacheSoundScript("Weapon_M16A2_M203.BoltHit")
self.PrecacheSoundScript("Weapon_M16A2_M203.ClipIn")
self.PrecacheSoundScript("Weapon_M16A2_M203.ClipOut")
self.PrecacheSoundScript("Weapon_M16A2_M203.Single")
self.PrecacheSoundScript("Weapon_M16A2_M203.Single2")

self.PrecacheSoundScript("Weapon_M16A2_M203.Launcher")

local weapon=null

function Think2(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_m16m203") return 0.005
	weapon.Update()
	//printl("thinking")
	return 0.005
}
::aPlayer<-null

local grenadelight = {
	_cone = 0,
	_inner_cone = 0,
	_light = "249 205 67 2200",
	brightness = 2,
	distance = 100
	pitch = -90,
	//spawnflags = 1,
	style=0
}

function InitWeapon(...)
{
	//IncludeScript("weapons/weapon_base.nut")
	aPlayer=player.GetOrCreatePrivateScriptScope()
	
	local WeaponInfo=
	{
		AmmoType="item_ammo_556"
		Model="models/weapons/v_m16a2_m203.mdl"
		Firerate=0.065
		BurstFire=true
		RecoilMult=5
		Spread=0.1
		RecoverySpeed=-0.75
		InAccuracy=1.5
		Damage=7
		Clip=30
		ShootSound="Weapon_M16A2_M203.Single"
		ShootSound2="Weapon_M16A2_M203.Single2"
		DrawSound="SW.Weapon.DrawRifle"
	}
	
	WeaponInfo.SecondaryAttack<-function(weapon)
	{
		local VM=player.GetViewModel(0)
		
		player.GetActiveWeapon().GetOrCreatePrivateScriptScope().WeaponIdle<-function()
		{
			if (("Weapon" in aPlayer)&&aPlayer.Weapon==this&&SingleUse&&(VM.GetSequenceActivityName(VM.GetSequence())!="ACT_VM_LOWERED_TO_IDLE")&&(VM.GetSequenceActivityName(VM.GetSequence())!="ACT_VM_SECONDARYATTACK")&&(VM.GetSequenceActivityName(VM.GetSequence())!="ACT_VM_HOLSTER")&&(VM.GetSequenceActivityName(VM.GetSequence())!="ACT_VM_DRAW"))
			{
				VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity(IdleOverride)))
				return
				//printl(IdleOverride)
			}
			
			if (("Weapon" in aPlayer)&&aPlayer.Weapon==this&&SingleUse&&IdleOverride!="") return;
			
			return true
		}.bindenv(this)
	
		if (player.GetButtons() & IN.ATTACK2&&(player.GetButtonLast() & IN.ATTACK2)&&Time()>nextattack)
		{
			SingleUse=!SingleUse
			AllowPrimaryAttack=(!SingleUse)
			nextattack=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_LOWERED_TO_IDLE")));
			AMMODISPLAYTYPE=(SingleUse) ? "item_ammo_grenade" : AMMOTYPE;
			
		
			printl("Firemode set to "+((SingleUse) ? "Grenades" : "Bullets"))
			player.EmitSound("SW.Weapon.Foley")
			
			if (SingleUse)
			{
				weapon.IdleOverride="ACT_VM_IDLE_LOWERED"
				//player.GetActiveWeapon().SendWeaponAnim(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_IDLE_TO_LOWERED")))
				//VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_IDLE_TO_LOWERED")))
				
				player.GetActiveWeapon().SendWeaponAnim(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_LOWERED_TO_IDLE")))
				VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_LOWERED_TO_IDLE")))
				player.GetActiveWeapon().SetWeaponIdleTime(Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_LOWERED_TO_IDLE"))))
				player.ViewPunch(Vector(-0.05,0,-0.1))
				nextattack=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_LOWERED_TO_IDLE")))
			}
			else
			{
				weapon.IdleOverride=""
				//player.GetActiveWeapon().SendWeaponAnim(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_LOWERED_TO_IDLE")))
				//VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_LOWERED_TO_IDLE")))
				
				player.GetActiveWeapon().SendWeaponAnim(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_IDLE_TO_LOWERED")))
				VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_IDLE_TO_LOWERED")))
				player.GetActiveWeapon().SetWeaponIdleTime(Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_IDLE_TO_LOWERED"))))
				player.ViewPunch(Vector(0.05,0,0.1))
				nextattack=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_IDLE_TO_LOWERED")))
			}
			
		}
		
		if (player.GetButtons() & IN.ATTACK&&(player.GetButtonLast() & IN.ATTACK)&&Time()>nextattack&&SingleUse&&(Entities.FindByName(null,"stamina_system").GetScriptScope().HasItemCount(LIST_ITEMS["item_ammo_grenade"].name)>0))
		{
			local GrenadeTable=
			{
				origin=(player.EyePosition()+player.GetEyeForward()*16+player.GetEyeRight()*3+player.GetEyeUp()*(-3)).ToKVString()
				angles=(player.EyeAngles()).ToKVString()
			}
			local Grenade=SpawnEntityFromTable("grenade_ar2",GrenadeTable)
			
			local TrailTable=
			{
				origin=(player.EyePosition()+player.GetEyeForward()*16+player.GetEyeRight()+player.GetEyeUp()*(-2)).ToKVString()
				angles=(player.EyeAngles()).ToKVString()
				lifetime=0.5
				startwidth=2
				endwidth=0.1
				spritename="sprites/smoke.vmt"
				rendermode=5
				rendercolor="95 90 40"
			}
			Grenade.AcceptInput("SetDamage","80",null,null)
			Grenade.AcceptInput("AddOutput","radius 250",null,null)
			Grenade.SetOwner(player)
			
			local GrenadeLight = SpawnEntityFromTable("light_dynamic", grenadelight)
		
			GrenadeLight.FollowEntity(Grenade,false)
			GrenadeLight.SetLocalOrigin(Vector(10,0,4))
			
			local Trail=SpawnEntityFromTable("env_spritetrail",TrailTable)
			Trail.FollowEntity(Grenade,false)
			player.EmitSound("Weapon_M16A2_M203.Launcher")
			
			//Grenade.GetPhysicsObject().ApplyForceCenter((player.GetEyeForward()*1000+player.GetEyeUp()*170)*Grenade.GetPhysicsObject().GetMass())
			//Grenade.ApplyLocalAngularVelocityImpulse(Vector(-300,600,550))
			Grenade.SetVelocity(player.GetEyeForward()*900+player.GetEyeUp()*70)
			
			Entities.FindByName(null,"stamina_system").GetScriptScope().RemoveItem("item_ammo_grenade",1);
			
			player.GetActiveWeapon().SendWeaponAnim(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_SECONDARYATTACK")))
			VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_SECONDARYATTACK")))
			player.ViewPunch(Vector(-5,0,0))
			
			player.GetActiveWeapon().SetWeaponIdleTime(Time()+0.5+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_SECONDARYATTACK"))))
			
			nextattack=Time()+1.4;
			
		}
	
	}
	
	weapon=C_BaseWeapon("weapon_m16m203",WeaponInfo)
	Init(weapon)
}
Entities.EnableEntityListening()
//Entities.First().SetContextThink(UniqueString("")+"M16M203",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}
