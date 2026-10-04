IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("SW.Weapon.DrawGrenade")

local weapon=null

function Think3(...)
{
	if (!weapon) return
	if ("Weapon" in aPlayer) if (aPlayer.Weapon.Name!="weapon_frag") return 0.005
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
		AmmoType="weapon_frag"
		Model="models/weapons/v_grenade.mdl"
		Firerate=0.3
		RecoilMult=5
		InAccuracy=1
		Damage=5
		Clip=18
		ShootSound="Weapon_Pistol.Single"
		SemiAuto=true
		ReloadSound="Weapon_Pistol.Reload"
		DrawSound="SW.Weapon.DrawGrenade"
		SingleUse=true
		
		RecoveryBonus=0
		
		PrimaryAttack=function()
		{
			local VM=player.GetViewModel(0)
		
			//printl(ReadyTime)
			clip=Entities.FindByName(null,"stamina_system").GetScriptScope().HasItemCount(this.AMMOTYPE);
			
			if (VM.GetSequence()!=(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_PULLBACK_HIGH")))&&VM.GetSequence()!=(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_PULLBACK_LOW"))))
			{
				Ready=false
			}
			
			if (Ready&&NextPing<Time())
			{
				player.GetActiveWeapon().EmitSound("Grenade.Blip")
				
				NetMsg.Start("GrenadeBlipToClient")
				NetMsg.WriteFloat(ReadyTime)
				NetMsg.Send(player,true)
				
				local Delay=(3.15-(Time()-ReadyTime))<=1 ? 0.33 : 1
				//Delay=clamp(Delay,0.1,1)
				NextPing=Time()+Delay
			}
			
			if (Ready&&ReadyTime+3.15<Time())
			{
				player.GetActiveWeapon().SetWeaponIdleTime(Time()+0.5)
				//VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW")))
				
				RecoveryBonus=1
				Ready=false
				
				NetMsg.Start("GrenadeBlipToClient")
				NetMsg.WriteFloat(-1)
				NetMsg.Send(player,true)
				
				printl("Grenade throw")
				nextattack=Time()+1
				local GrenadeTable=
				{
					origin=(player.EyePosition()+player.GetEyeForward()*16+player.GetEyeRight()*2+player.GetEyeUp()*(-8)).ToKVString()
					angles=(player.EyeAngles()-Vector(-70,15,15)).ToKVString()
				}
				local Grenade=SpawnEntityFromTable("npc_grenade_frag",GrenadeTable)
				Grenade.SetOwner(player)
				
				EntFireByHandle(Grenade,"SetTimer",0)
				
				Entities.FindByName(null,"stamina_system").GetScriptScope().RemoveItem(this.AMMOTYPE,1);			
			}
			
			if (VM.GetSequence()==VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW")))
			{
				RecoveryBonus=0
			}
			
			if (RecoveryBonus&&Time()>=player.GetActiveWeapon().GetWeaponIdleTime())
			{
				VM.SetModel("models/blackout.mdl")
				RecoveryBonus=0
				Ready=false
			}
			
			if (player.GetButtons() & IN.ATTACK&&(player.GetButtonLast() & IN.ATTACK)&&Time()>nextattack)
			{
				VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_PULLBACK_HIGH")))
				player.GetActiveWeapon().SetWeaponIdleTime(Time()+0.25)
				if (!Ready)
				{
					ReadyTime=Time()
					Ready=true
					NextPing=Time()+0.15
				}
				return
			}
			else if (Ready&&Time()>ReadyTime+0.15&&!(VM.GetSequence()==VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_PULLBACK_LOW"))))
			{
				VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_THROW")))
				player.GetActiveWeapon().SetWeaponIdleTime(Time()+0.45)
				//VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW")))
				
				RecoveryBonus=1
				Ready=false
				
				
				NetMsg.Start("GrenadeBlipToClient")
				NetMsg.WriteFloat(-1)
				NetMsg.Send(player,true)
				
				printl("Grenade throw")
				nextattack=Time()+1
				local GrenadeTable=
				{
					origin=(player.EyePosition()+player.GetEyeForward()*16+player.GetEyeRight()*2+player.GetEyeUp()*(-8)).ToKVString()
					angles=(player.EyeAngles()-Vector(-70,15,15)).ToKVString()
				}
				local Grenade=SpawnEntityFromTable("npc_grenade_frag",GrenadeTable)
				Grenade.SetOwner(player)
				
				Grenade.GetPhysicsObject().ApplyForceCenter((player.GetEyeForward()*1000+player.GetEyeUp()*170)*Grenade.GetPhysicsObject().GetMass())
				Grenade.ApplyLocalAngularVelocityImpulse(Vector(-300,600,550))
				
				EntFireByHandle(Grenade,"SetTimer",3.15-(Time()-ReadyTime))
				
				Entities.FindByName(null,"stamina_system").GetScriptScope().RemoveItem(this.AMMOTYPE,1);
				return
			}
			
			if (player.GetButtons() & IN.ATTACK2&&(player.GetButtonLast() & IN.ATTACK2)&&Time()>nextattack)
			{
				VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_PULLBACK_LOW")))
				player.GetActiveWeapon().SetWeaponIdleTime(Time()+0.25)
				if (!Ready)
				{
					ReadyTime=Time()
					Ready=true
					NextPing=Time()+0.15
				}
				return
			}
			else if (Ready&&Time()>ReadyTime+0.15)
			{
				VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_SECONDARYATTACK")))
				player.GetActiveWeapon().SetWeaponIdleTime(Time()+0.45)
				//VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW")))
				
				RecoveryBonus=1
				Ready=false
				
				
				NetMsg.Start("GrenadeBlipToClient")
				NetMsg.WriteFloat(-1)
				NetMsg.Send(player,true)
				
				printl("Grenade throw")
				nextattack=Time()+1
				local GrenadeTable=
				{
					origin=(player.EyePosition()+player.GetEyeForward()*16+player.GetEyeRight()*2+player.GetEyeUp()*(-16)).ToKVString()
					angles=(player.EyeAngles()-Vector(-70,15,15)).ToKVString()
				}
				local Grenade=SpawnEntityFromTable("npc_grenade_frag",GrenadeTable)
				Grenade.SetOwner(player)
				
				Grenade.GetPhysicsObject().ApplyForceCenter((player.GetEyeForward()*250+player.GetEyeUp()*150)*Grenade.GetPhysicsObject().GetMass())
				Grenade.ApplyLocalAngularVelocityImpulse(Vector(-140,-300,150))
				EntFireByHandle(Grenade,"SetTimer",3.15-(Time()-ReadyTime))
				
				Entities.FindByName(null,"stamina_system").GetScriptScope().RemoveItem(this.AMMOTYPE,1);
			}
		}
		
	}
	
	weapon=C_BaseWeapon("weapon_frag",WeaponInfo)
	Init(weapon)
}
Entities.EnableEntityListening()
Entities.First().SetContextThink("FRAG",function(_) {weapon.Update();return 0.005}.bindenv(this),0.005)
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
if (player)
{
	InitWeapon()
}