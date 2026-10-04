local crouching=1.0

local LastWeapon=null
self.PrecacheSoundScript("SW.Weapon.Foley")
player.PrecacheSoundScript("common/noise.wav")

PrecacheParticleSystem("weapon_muzzle_flash_smoke_small2")

function OnPostSpawn()
{
	EntFire("viewmodel","SetModel","models/blackout.mdl",0.5)
}

function SelectRandomSequence(ent,activity)
{
	local Seqs=[]
	
	for (local i=0;i<64;i++)
	{
		if (ent.GetSequenceActivityName(i)==activity) Seqs.append(i);
	}
	
	if (Seqs.len==0) return 0;
	
	return Seqs[RandomInt(0,Seqs.len()-1)]
	
}

function AngleDif(a1,a2)
{
	local result=Vector(0,0,0)
	result.x=AngleDistance(a1.x,a2.x)
	result.y=AngleDiff(a1.y,a2.y)
	result.z=AngleDistance(a1.z,a2.z)
	return result
}

local PrevMainViewAngle=Vector()
local LoweredAngle=Vector()
local ClockTime=clock()



::GetWeaponFromInv<-function(a)
{
	foreach(i,item in INVENTORY)
	{
		if (item&&(typeof item)!="integer"&&item.WeaponInvID==a) return i;
	}
	
	foreach(i,item in INVENTORY)
	{
		if (item&&(typeof item)!="integer"&&item.WeaponInvID==aPlayer.ActiveWeaponSlot) return i;
	}
	
}

if (SERVER_DLL)
{
	local LastSwitchTime=(-1);
	::SW_Player_LastInv<-1;
	::SW_Player_LastHolstered<-1;
	::SW_Player_RealLastInv<-(0);
	function SelectSlot(i,ShowHud=true)
	{	
		if (player.GetButtons() & IN.ALT1)
		{
			NetMsg.Start("QuickUseItem")
			NetMsg.WriteShort(i-1)
			NetMsg.Send(player,true)
			
			if (QUICK_USE_SLOTS[i-1]!=null)
			{
				LIST_QUEST_ITEMS[QUICK_USE_SLOTS[i-1]].UseItem()
			}
			else player.EmitSound("common/noise.wav");
			return
		}
		
		if (player.GetMoveType()==MOVETYPE_LADDER) return
		

		NetMsg.Start("WeaponSelectionShow")
		NetMsg.WriteShort(i-1)
		NetMsg.WriteBool(ShowHud)
		NetMsg.Send(player,true)
		
		i--;
		if (!("Weapons" in aPlayer)) return
		if (WEAPON_SLOTS[i]==null) return
		
		
		
		local WepInvID=WEAPON_SLOTS[i]
		
		//printl("trying select "+i)
		//printl("tryin against "+aPlayer.ActiveWeaponSlot)
		
		//if (aPlayer.ActiveWeaponSlot==WEAPON_SLOTS[i]&&Time()-LastSwitchTime>=0.2) {return}
		//LastSwitchTime=Time();
		
		
		//if ("Weapon" in aPlayer&&aPlayer.Weapon==aPlayer.Weapons[WepInvID]) return
		
		//printl("trying select")
		
		local SelectedWeapon=aPlayer.Weapons[WepInvID]
		local VM=null
		//NXPrint(20,255,80,80,true,1,"SELECTED "+SelectedWeapon.Name+"                              ")
		//printl("SELECTIONG WEAPON "+SelectedWeapon.Name)
		//printl("and i mean "+INVENTORY[GetWeaponFromInv(WepInvID)].Name)
		VM=player.GetViewModel(0)
		//player.GetActiveWeapon().SendWeaponAnim(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER")))
		
		local empty=""
		
		
		if ("Weapon" in aPlayer) empty=(aPlayer.Weapon.UseEmptyAnims ? "_EMPTY" : "");
		
		SW_Player_RealLastInv=SW_Player_LastInv
		SW_Player_LastInv=(i+1)
		if (aPlayer.ActiveWeaponSlot!=WEAPON_SLOTS[i])
		{
			VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER"+empty)))
			player.GetActiveWeapon().SetWeaponIdleTime(Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER"+empty))))
			player.GetActiveWeapon().EmitSound("SW.Weapon.Foley")
		}
		//player.GetActiveWeapon().SendWeaponAnim(VM.LookupActivity("ACT_VM_HOLSTER"))
		//printl("Time "+(Time()-LastSwitchTime))
		if (SKILLS.Dual.Unlocked&&aPlayer.DualWield[0]!=null&&("Dual" in aPlayer.Weapons[aPlayer.DualWield[0]])&&(aPlayer.Weapons[aPlayer.DualWield[0]].Dual) && Time()-LastSwitchTime<0.2&&aPlayer.DualWield[0]!=null && aPlayer.Weapons[aPlayer.DualWield[0]].Name==aPlayer.Weapons[WepInvID].Name&&aPlayer.DualWield[0]!=WepInvID) {Entities.First().SetContextThink("PlayerHolster",function (...)
		{
			VM.SetModel("models/blackout.mdl")
			player.GetActiveWeapon().SetWeaponIdleTime(VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER"))))
			VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER")))
			player.GetActiveWeapon().SetWeaponIdleTime(VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER"))))
			if (!("Weapon" in aPlayer)) aPlayer.Weapon<-SelectedWeapon;
			else aPlayer.Weapon=SelectedWeapon;
			aPlayer.ActiveWeaponSlot=WepInvID
			
			//printl("new is "+aPlayer.ActiveWeaponSlot)
				
				// Dual Wield enable
				aPlayer.DualWield[1]=WepInvID
				printl(format("Enabling dual wield for %s (%i) and %s (%i)!",aPlayer.Weapons[aPlayer.DualWield[0]].Name,aPlayer.DualWield[0],aPlayer.Weapons[aPlayer.DualWield[1]].Name,aPlayer.DualWield[1]))
				
				
				SelectedWeapon=null
				local SelectedWeaponID=null
				foreach(i,wep in aPlayer.Weapons)
				{
					if (wep&&aPlayer.Weapons[aPlayer.DualWield[0]].Dual&&wep.Name==aPlayer.Weapons[aPlayer.DualWield[0]].Dual) {SelectedWeapon=wep;SelectedWeaponID=i;break}
				}
				//NXPrint(20,255,80,80,true,1,"SELECTED DUAL "+SelectedWeapon.Name+"                              ")
				
				
				SelectedWeapon.clip=INVENTORY[GetWeaponFromInv(aPlayer.DualWield[0])].Clip
				SelectedWeapon.clip2=INVENTORY[GetWeaponFromInv(aPlayer.DualWield[1])].Clip
				
				VM=player.GetViewModel(0)
				VM.SetModel("models/blackout.mdl")
				player.GetActiveWeapon().SetWeaponIdleTime(Time()+0.5)
				VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER")))
				player.GetActiveWeapon().SetWeaponIdleTime(Time()+0.5)
				if (!("Weapon" in aPlayer)) aPlayer.Weapon<-SelectedWeapon;
				else aPlayer.Weapon=SelectedWeapon;
				aPlayer.ActiveWeaponSlot=SelectedWeaponID;
			
			
			//aPlayer.Weapons[WepInvID].clip=INVENTORY[GetWeaponFromInv(WepInvID)].Clip;
		}.bindenv(this),VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER"))));}
		else {Entities.First().SetContextThink("PlayerHolster",function (...)
		{
			if (aPlayer.ActiveWeaponSlot==WEAPON_SLOTS[i]) return;
			VM.SetModel("models/blackout.mdl")
			player.GetActiveWeapon().SetWeaponIdleTime(VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER"+empty))))
			VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER"+empty)))
			player.GetActiveWeapon().SetWeaponIdleTime(VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER"+empty))))
			if (!("Weapon" in aPlayer)) aPlayer.Weapon<-SelectedWeapon;
			else aPlayer.Weapon=SelectedWeapon;
			aPlayer.ActiveWeaponSlot=WepInvID
			
			//printl("new is "+aPlayer.ActiveWeaponSlot)
			
			aPlayer.DualWield=[WepInvID,null];
			
			
			aPlayer.Weapons[WepInvID].clip=INVENTORY[GetWeaponFromInv(WepInvID)].Clip;
		}.bindenv(this),VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER"+empty))));aPlayer.DualWield=[WepInvID,null];}
		LastSwitchTime=Time()
	}
	
	::SW_SetPlayerSpeed<-function (a)
	{
		return
		// Disabled, because too unreliable. Need a replacement.
		
		if (Convars.GetFloat("hl2_normspeed")/190.0==a) return;
		
		NXPrint(30,255,255,80,true,2,"CHANGED PLAYER MOVESPEED TO "+(a*100).tointeger()+"%                                                                                   ")
		
		Convars.SetFloat("hl2_normspeed",190*a)
		Convars.SetFloat("hl2_sprintspeed",320*a)
		Convars.SetFloat("sv_maxspeed",320*a)
		player.ForceButtons(IN.WALK)
		Entities.First().SetContextThink("UpdatePlayerMoveSpeed",function (...)
		{
			player.UnforceButtons(IN.WALK);return;
		},0.0001)
		Entities.First().SetContextThink("UpdatePlayerMoveSpeed",function (...)
		{
			player.UnforceButtons(IN.WALK);return;
		},0.01+IntervalPerTick())
	}
	
	function HolsterWeapon(NotifyClient=true)
	{
		if (!("Weapons" in aPlayer)) return
		if (!("Weapon" in aPlayer)) return
		

		local VM=null
		//NXPrint(20,255,80,80,true,1,"HOLSTERING"+"                              ")
		VM=player.GetViewModel(0)
		
		if (VM.GetSequence()==VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER"))) return;
		//player.GetActiveWeapon().SendWeaponAnim(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER")))
		if (aPlayer.ActiveWeaponSlot!=(-1))
		{
			VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER")))
			player.GetActiveWeapon().SetWeaponIdleTime(Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER"))))
			player.GetActiveWeapon().EmitSound("SW.Weapon.Foley")
			SW_Player_RealLastInv=SW_Player_LastInv
		}
		//player.GetActiveWeapon().SendWeaponAnim(VM.LookupActivity("ACT_VM_HOLSTER"))

		Entities.First().SetContextThink("PlayerHolster",function (...)
		{
			VM.SetModel("models/blackout.mdl")
			if (("Weapon" in aPlayer)) aPlayer.rawdelete("Weapon");
			aPlayer.ActiveWeaponSlot=-1
			
			SW_SetPlayerSpeed(1.1)
			

			NetMsg.Start("WeaponSelectionShow")
			NetMsg.WriteShort(-1)
			NetMsg.WriteBool(NotifyClient)
			NetMsg.Send(player,true)
			
			
			aPlayer.DualWield=[null,null];
		}.bindenv(this),VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER"))));
		LastSwitchTime=Time()
	}
}
if (CLIENT_DLL)
{
	NetMsg.Receive("WeaponSelectionShow", function()
	{
		
		local PrevLastWeaponSlot=LAST_WEAPON_SLOT
		local ReceivedSlot=NetMsg.ReadShort()
		
		local ShowOnHud=NetMsg.ReadBool()
		//printl(aPlayer.ActiveWeaponSlot)
		if (ReceivedSlot==(-1))
		{
			SW_HUDPlayerWeapon="";
			aPlayer.ActiveWeaponSlot=-1
			return;
		}
		if (WEAPON_SLOTS[ReceivedSlot]==null&&aPlayer.ActiveWeaponSlot!=(-1)) return;
		LAST_WEAPON_SLOT=ReceivedSlot
		
		aPlayer.ActiveWeaponSlot=WEAPON_SLOTS[LAST_WEAPON_SLOT];
		//printl("Time "+(Time()-LastSwitchTime))
		if (SKILLS.Dual.Unlocked&&("Dual" in aPlayer.Weapons[aPlayer.DualWield[0]]) && (aPlayer.Weapons[aPlayer.DualWield[0]].Dual!=null) && Time()-LastSwitchTime<0.2&&aPlayer.DualWield[0]!=null&&aPlayer.Weapons[aPlayer.DualWield[0]].Name==aPlayer.Weapons[WEAPON_SLOTS[LAST_WEAPON_SLOT]].Name&&aPlayer.DualWield[0]!=WEAPON_SLOTS[LAST_WEAPON_SLOT])
		{
			aPlayer.DualWield[1]=WEAPON_SLOTS[LAST_WEAPON_SLOT];
			// Dual Wield enable
			printl(format("(CLIENT) Enabling dual wield for %s (%i) and %s (%i)!",aPlayer.Weapons[aPlayer.DualWield[0]].Name,aPlayer.DualWield[0],aPlayer.Weapons[aPlayer.DualWield[1]].Name,aPlayer.DualWield[1]))
			local SelectedWeapon=null
			local SelectedWeaponID=null
			foreach(i,wep in aPlayer.Weapons)
			{
				if (wep&&aPlayer.Weapons[aPlayer.DualWield[0]].Dual&&wep.Name==aPlayer.Weapons[aPlayer.DualWield[0]].Dual) {SelectedWeapon=wep;SelectedWeaponID=i;break}
			}

			if (!("Weapon" in aPlayer)) aPlayer.Weapon<-SelectedWeapon;
			else aPlayer.Weapon=SelectedWeapon;
			aPlayer.ActiveWeaponSlot=SelectedWeaponID;
			LAST_WEAPON_SLOT=[PrevLastWeaponSlot,LAST_WEAPON_SLOT]
		}
		else 
		{
			if (!("Weapon" in aPlayer)) aPlayer.Weapon<-aPlayer.Weapons[aPlayer.ActiveWeaponSlot];
			else aPlayer.Weapon=aPlayer.Weapons[aPlayer.ActiveWeaponSlot];
			aPlayer.DualWield=[WEAPON_SLOTS[LAST_WEAPON_SLOT],null];
		}
		if (ShowOnHud) LastSwitchTime=Time();
		
		//aPlayer.ActiveWeaponSlot=LAST_WEAPON_SLOT
	}.bindenv(this) );
	NetMsg.Receive("UpdateActiveSlotOnClient", function()
	{
		local ReceivedSlot=NetMsg.ReadShort()
		aPlayer.ActiveWeaponSlot=ReceivedSlot;
	}.bindenv(this) );
	NetMsg.Receive("SyncInvClipOnClient", function()
	{
		local i=NetMsg.ReadShort()
		local clip=NetMsg.ReadShort()
		INVENTORY[i].Clip=clip;
		//printl(aPlayer.Weapons[INVENTORY[i].WeaponInvID])
		aPlayer.Weapons[INVENTORY[i].WeaponInvID]["clip"]=clip
	}.bindenv(this) )
}

if (SERVER_DLL)
{
	Convars.RegisterCommand( "slot1", function(_)
	{
		SelectSlot(1)
	}.bindenv(this), "", 0 );
	Convars.RegisterCommand( "slot2", function(_)
	{
		SelectSlot(2)
	}.bindenv(this), "", 0 );
	Convars.RegisterCommand( "slot3", function(_)
	{
		SelectSlot(3)
	}.bindenv(this), "", 0 );
	Convars.RegisterCommand( "slot4", function(_)
	{
		SelectSlot(4)
	}.bindenv(this), "", 0 );
	Convars.RegisterCommand( "slot5", function(_)
	{
		SelectSlot(5)
	}.bindenv(this), "", 0 );
	Convars.RegisterCommand( "slot6", function(_)
	{
		SelectSlot(6)
	}.bindenv(this), "", 0 );
	Convars.RegisterCommand( "slot10", function(_)
	{
		HolsterWeapon()
		SW_Player_LastInv=10;
		SW_Player_RealLastInv=10;
	}.bindenv(this), "", 0 );
	
	Convars.RegisterCommand( "temp_holster", function(_)
	{
		if (aPlayer.ActiveWeaponSlot==-1) return;
		SW_Player_LastHolstered=aPlayer.ActiveWeaponSlot+1
		//if (aPlayer.ActiveWeaponSlot>32) SW_Player_LastHolstered=((aPlayer.DualWield[0]+1)+""+(1+aPlayer.DualWield[1]))
		HolsterWeapon()
		printl("holstered "+SW_Player_LastHolstered)
		//SW_Player_LastInv=10;
		//SW_Player_RealLastInv=10;
	}.bindenv(this), "", 0 );
	
	Convars.RegisterCommand( "temp_unholster", function(_)
	{
		if (aPlayer.ActiveWeaponSlot!=-1) return;
		
		//if (SW_Player_LastHolstered.tostring().len()>1)
		//{
		//	SelectSlot(SW_Player_LastHolstered.slice(0,1).tointeger(),false)
		//	SelectSlot(SW_Player_LastHolstered.slice(1,2).tointeger(),false)
		//	
		//}
		SelectSlot(SW_Player_LastHolstered,false)
		printl("selecting "+SW_Player_LastHolstered)
	}.bindenv(this), "", 0 );
	Convars.RegisterCommand( "invnext", function(_)
	{
		if (!("Weapons" in aPlayer)) return
		local failsafe=0
		local WepSlots=[]	// From 0 to 5.
		foreach (i,s in WEAPON_SLOTS) if (s!=null) WepSlots.append(i)
		if (WepSlots.len()<2) return;
		local TargetSlot=SW_Player_LastInv+1
		//printl("start: "+TargetSlot)
		while (WepSlots.find(TargetSlot-1)==null&&failsafe<8)
		{
			TargetSlot++;
			printl("adding one. up to "+TargetSlot)
			
			if (TargetSlot>6) TargetSlot=0;
			failsafe++;
		}
		if (failsafe>=7) printl("failsafe!")
		//printl("end: "+TargetSlot)
		SelectSlot(TargetSlot)
	}.bindenv(this), "", 0 );
	Convars.RegisterCommand( "invprev", function(_)
	{
		if (!("Weapons" in aPlayer)) return
		local failsafe=0
		local WepSlots=[]	// From 0 to 5.
		foreach (i,s in WEAPON_SLOTS) if (s!=null) WepSlots.append(i)
		if (WepSlots.len()<2) return;
		local TargetSlot=SW_Player_LastInv-1
		//printl("start: "+TargetSlot)
		while (WepSlots.find(TargetSlot-1)==null&&failsafe<8)
		{
			TargetSlot--;
			printl("reducing one. down to "+TargetSlot)
			
			if (TargetSlot<0) TargetSlot=6;
			failsafe++;
		}
		if (failsafe>=7) printl("failsafe!")
		//printl("end: "+TargetSlot)
		SelectSlot(TargetSlot)
	}.bindenv(this), "", 0 );
	Convars.RegisterCommand( "lastinv", function(_)
	{
		if (!("Weapons" in aPlayer)) return
		if (SW_Player_RealLastInv>6) return

		SelectSlot(SW_Player_RealLastInv,false)
	}.bindenv(this), "", 0 );
}

if (!player.GetScriptScope())
{
	::aPlayer<-player.GetOrCreatePrivateScriptScope()
	::aPlayer.ActiveWeaponSlot<-0
	::aPlayer.DualWield<-[0,null]
	::aPlayer.WeaponsAllowed<-true
}

function Init(wep)
{
	if (!player) return;
	
	if (!("Weapon" in aPlayer))
	{
		::aPlayer.Weapon<-wep
		//if ("Weapons" in aPlayer) printl("CHANGING ACTIVE SLOT TO "+aPlayer.Weapons.find(null))
		if ("Weapons" in aPlayer) 
		{
			if (SERVER_DLL&&aPlayer.ActiveWeaponSlot==(-1))
			{
				NetMsg.Start("UpdateActiveSlotOnClient")
				
				local dualslot=wep.Name.find("pistol")!=null ? 35 : 34
				dualslot=wep.Name.find("glock")!=null ? 33 : dualslot
				
				NetMsg.WriteShort(wep.Name.find("dual")!=null ? dualslot : aPlayer.Weapons.find(null))
				NetMsg.Send(player,true)
				printl("sent! "+aPlayer.Weapons.find(null))
			}
			aPlayer.ActiveWeaponSlot=wep.Name.find("dual")!=null ? dualslot : aPlayer.Weapons.find(null);
		}
	}
	//printl("given a weapon "+wep.Name)
	if (!("ammo" in aPlayer)) aPlayer.ammo<-{};
	if (!("Weapons" in aPlayer)) 
	{
		aPlayer.Weapons<-array(36)	// Enough to account for player fitting 36 1x2 weapons into their inventory (knives for example).
		aPlayer.Weapons[0]=wep;
		wep.InvSlot=0
		aPlayer.ActiveWeaponSlot=0
	}
	else 
	{
		local dualslot=wep.Name.find("pistol")!=null ? 35 : 34
		dualslot=wep.Name.find("glock")!=null ? 33 : dualslot
		
		wep.InvSlot=wep.Name.find("dual")!=null ? dualslot : aPlayer.Weapons.find(null);
		aPlayer.Weapons[wep.Name.find("dual")!=null ? dualslot : aPlayer.Weapons.find(null)]=wep;	//find first free weapon inventory slot and place weapon there
	}
	//aPlayer.ammo[]<-AMMOTYPE
	
	if (!(wep.AMMOTYPE in aPlayer.ammo)) aPlayer.ammo[wep.AMMOTYPE]<-0
	
	//aPlayer.ammo["SMG"]+=180
	
	printl("-------------")
	printl(wep.Name+" INIT")
	printl("-------------")
	Entities.First().SetContextThink( "Update "+UniqueString(wep.Name), function(...) {wep.Update();return 0}.bindenv(this), 0 );
}
//ListenToGameEvent( "player_spawn", Init,"Init"+AMMOTYPE);
local panel=null


if (SERVER_DLL)
{
	NetMsg.Receive("GetPlayerWeapon", function( player )
	{
		NetMsg.Start("GetPlayerWeapon")
		if ("Weapon" in aPlayer)
		{
			NetMsg.WriteString(aPlayer.Weapon.Name)
			NetMsg.WriteFloat((Spread+0.1+(pow(aPlayer.Weapon.shotsfired,1.4)/1.5*(0.02*aPlayer.Weapon.RecoilMult*aPlayer.Weapon.InAccuracy*AccuracyBonus)))*5/(((player.GetFlags() & 3)==3).tointeger()+1.0)/player.GetFOV()*85)
		}
		else
		{
			NetMsg.WriteString("")
			NetMsg.WriteFloat(1000)
		}
		NetMsg.Send(player,true)
	} );
}



class C_BaseWeapon
{

//RegisterActivityConstants()

AMMOTYPE=""
Name=null
InvSlot=null
init=null
firerate=null
nextattack=0
nextreload=0
reloading=false
shotsfired=0
Spread=0
BaseSpread=0
accuracy=1
clip=null
clip2=0
maxclip=null
Model=null
Damage=null
RecoilMult=null
RecoverySpeed=0
RecoveryBonus=0
AccuracyBonus=1
ShootSound=null
ShootSound2=null
ReloadSound=null
PumpSound=null
PrimaryAttack=null
ForcePrimaryAttack=null
ReloadWeapon=null
InAccuracy=1
BaseInAccuracy=1
BulletsPerShot=1
ReloadsSingly=false
IsShotgun=false
BurstFire=false
ReloadState=0
NeedPump=false
NeedPump2=false
SecondaryAttack=null
DrawSound=null
Dual=null
SingleUse=false
Ready=false
ReadyTime=0
NextPing=0
UseEmptyAnims=false
SupportsEmptyAnims=false
Blocking=false
Jammed=false
LastJam=0
ReduceShake=false
ImpactOverride=null
TracerOverride=null

IdleOverride=""

AttackCost=0

Auto=true

AllowPrimaryAttack=true
AllowReload=true
AMMODISPLAYTYPE=""
LastIdleTime=0;

Info={}

//aPlayer=null
//ListenToGameEvent( "player_spawn", Init,"Init"+AMMOTYPE);

muzzleFlashTable = {
	brightnessscale = 2,
	farz = 850,
	lightcolor = "255 255 255 225",
	lightfov = 80,
	nearz = 10,
	spawnflags = 1,
	texturename = "effects/muzzleflash_light"
	colortransitiontime=100
}

muzzlelight = {
	_cone = 0,
	_inner_cone = 0,
	_light = "249 205 67 2200",
	brightness = 1,
	distance = 400
	pitch = -90,
	//spawnflags = 1,
	style=0
}

DecreaseDurability=function(amount)
{
	//amount*=2
	
	local id=((clip+clip2)%2!=1).tointeger()
	
	if (aPlayer.Weapon.Name.find("dual")==null) id=0;
	
	if (maxclip<=10) amount*=2;
	if (IsShotgun) amount*=4;
	if (Damage>15) amount*=3;
	if (Damage>35) amount*=3;
	if (Damage>55) amount*=2;
	if (Damage>75) amount*=2;
	
	INVENTORY[GetWeaponFromInv(aPlayer.DualWield[id])].Durability=max(0,INVENTORY[GetWeaponFromInv(aPlayer.DualWield[id])].Durability-amount);
	if (SERVER_DLL)
	{
		NetMsg.Start("ChangeDurabilityOnClient")
		NetMsg.WriteShort(GetWeaponFromInv(aPlayer.DualWield[id]))
		NetMsg.WriteShort(INVENTORY[GetWeaponFromInv(aPlayer.DualWield[id])].Durability)
		NetMsg.Send(player,true)
	}
}

ReloadWeapon=function()
{
	//printl("starting reload")
	if (AMMOTYPE=="item_ammo_none") return;
	if (SingleUse) return;
	local VM=player.GetViewModel(0)
	
	if (!Jammed)
	{
		if (!AllowReload) return;
		if (Entities.FindByName(null,"stamina_system").GetScriptScope().HasItemCount(LIST_ITEMS[AMMOTYPE].name)==0) {return}
	}
	if (Jammed&&ReloadsSingly)
	{
		NeedPump=true
		return;
	}
	//printl("reload in progress!")
	reloading=true
	ReloadState=0
	//shotsfired=0
	if (!ReloadsSingly)
	{
		if (Model.find("rif")==null&&Model.find("357")==null&&Model.find("m16")==null&&ReloadSound) player.EmitSound(ReloadSound)
		
		local ReloadSequence=VM.SelectWeightedSequence(VM.LookupActivity("ACT_VM_RELOAD"+(UseEmptyAnims ? "_EMPTY" : "")),1)
		
		VM.SetSequence(ReloadSequence)
		nextattack=Time()+VM.SequenceDuration(ReloadSequence)
		nextreload=Time()+VM.SequenceDuration(ReloadSequence)
	}
	else
	{
		//if (Model.find("rif")==null) player.EmitSound(ReloadSound)
		VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_SHOTGUN_RELOAD_START")))
		nextattack=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_SHOTGUN_RELOAD_START")))
		nextreload=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_SHOTGUN_RELOAD_START")))	
	}
	player.GetActiveWeapon().SetWeaponIdleTime(nextreload)
}

function SendPlayerWeaponChange()
{
	if (SERVER_DLL)
	{
	NetMsg.Start("GetPlayerWeapon")
	if ("Weapon" in aPlayer)
	{
		NetMsg.WriteString(aPlayer.Weapon.Name)
		if (aPlayer.Weapon.IsShotgun) NetMsg.WriteFloat(aPlayer.Weapon.InAccuracy);
		else NetMsg.WriteFloat((Spread+0.1+(pow(aPlayer.Weapon.shotsfired,1.4)/1.5*(0.02*aPlayer.Weapon.RecoilMult*aPlayer.Weapon.InAccuracy*aPlayer.Weapon.AccuracyBonus)))*5/(((player.GetFlags() & 3)==3).tointeger()+1.0)/player.GetFOV()*85);
	}
	else
	{
		NetMsg.WriteString("")
		NetMsg.WriteFloat(1000)
	}
	NetMsg.Send(player,true)
	}
}

function PlayerHasWeapon()
{
	aPlayer=player.GetOrCreatePrivateScriptScope()
	//if (!aPlayer) return false;
	if (!("Weapon" in aPlayer)) return false;
	
	//printl("comparing current slot with "+InvSlot)
	
	if (aPlayer.Weapon.Name==this.Name&&aPlayer.ActiveWeaponSlot==this.InvSlot) return true;
	return false
}

function GetViewPunch()
{
	return Vector(RandomFloat(-0.1,-0.2),RandomFloat(-0.05,0.05),0)
}
function CrazyRand(n,a)
{
	local sum=0
	for (local i=0;i<n;i++)
	{
		sum+=RandomFloat(-a,a)
	}
	return sum/n
}

function GetSpread(a)
{
	//return Vector(RandomFloat(-a,a),RandomFloat(-a,a),RandomFloat(-a,a))
	local b=CrazyRand(2,a)
	local c=CrazyRand(2,a)
	local d=CrazyRand(2,a)
	return Vector(b,c,d)
}
LastPress=false

function MuzzleFlash()
{
	//Used for scoped F2000
	
	local VM=player.GetViewModel(0)
	
	PrecacheParticleSystem("view_muzzle_pistols")
	
	DispatchParticleEffect("view_muzzle_pistols",player.EyePosition()+player.GetEyeForward()*30+player.GetEyeUp()*(-3),VectorAngles(player.GetAutoaimVector(AUTOAIM_SCALE_DEFAULT)),Entities.First())
}

function PrimaryAttack()
{
	//if (player.GetButtonPressed() & IN.ATTACK) printl("attacking! "+Time())
		
	local firerate=firerate/(1.0+GetNamedEnt("stamina_system").GetScriptScope().RageActive.tointeger()*0.3)+0.07*(!Auto).tointeger()-0.1*(IsShotgun&&GetNamedEnt("stamina_system").GetScriptScope().RageActive).tointeger()
	local Auto=Auto||GetNamedEnt("stamina_system").GetScriptScope().RageActive
	
	if (!AllowPrimaryAttack)
		return;
	//local VM=player.GetViewModel(0)
	//DispatchParticleEffect("view_muzzle_pistols",VM.GetAttachmentOrigin(1)+Vector(0,0,player.GetBoundingMaxs().z-8)+player.GetEyeForward()*3,VectorAngles(player.GetAutoaimVector(AUTOAIM_SCALE_DEFAULT)),player)
	
	if (ReloadsSingly&&reloading) return;
	local VM=player.GetViewModel(0)
	if (player.GetButtons() & IN.ATTACK&&nextattack<Time()&&(clip>0||clip2>0)&&(Auto||((!LastPress)&&(player.GetButtonLast() & IN.ATTACK))))
	{
		if (player.GetButtons() & IN.SPEED&&player.GetVelocity().Length2D()>200) return;
		
		//if (Spread>=0) shotsfired++;
		
		nextattack=Time()+firerate
		
		if (BurstFire&&((shotsfired.tointeger())%3==2)) nextattack=Time()+firerate*7.6
		
		
		//local id=((clip+clip2)%2!=1&&("dual" in aPlayer.Weapon.Name)).tointeger()
		local wepinvid=GetWeaponFromInv(aPlayer.DualWield[0])
		if (wepinvid==null) wepinvid=GetWeaponFromInv(aPlayer.ActiveWeaponSlot)
		local wepitem=INVENTORY[wepinvid]
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
		
		if (wepdur<0.03) InAccuracy=BaseInAccuracy*1.50;
		if (wepdur<0.02) InAccuracy=BaseInAccuracy*1.50*1.5;
		if (wepdur<0.01) InAccuracy=BaseInAccuracy*1.50*1.5*1.5;
		if (wepdur>=0.03) InAccuracy=BaseInAccuracy;
		
		
		if (ShootSound2!=null&&shotsfired>1) EmitSoundOn(ShootSound2,player);
		else EmitSoundOn(ShootSound,player);
		
		if ((player.GetFlags() & 3)==3) crouching=2.0;
		else crouching=1.0;
		accuracy=Spread+0.1+(pow(shotsfired,1.4)/1.5*(0.02*RecoilMult*InAccuracy*AccuracyBonus))/crouching
		accuracy=clamp(accuracy,0,999)
		//printl(accuracy)
		if (IsShotgun) accuracy=InAccuracy/3.0
		
		//VM.ResetSequenceInfo()
		local AttackSequence=VM.SelectWeightedSequence(VM.LookupActivity("ACT_VM_PRIMARYATTACK"),1)
		
		if (shotsfired>2&&VM.SelectWeightedSequence(VM.LookupActivity("ACT_VM_RECOIL1"),1)!=(-1))
			AttackSequence=VM.SelectWeightedSequence(VM.LookupActivity("ACT_VM_RECOIL1"),1);
			
		if (shotsfired>4&&VM.SelectWeightedSequence(VM.LookupActivity("ACT_VM_RECOIL2"),1)!=(-1))
			AttackSequence=VM.SelectWeightedSequence(VM.LookupActivity("ACT_VM_RECOIL2"),1);
			
		if (shotsfired>6&&VM.SelectWeightedSequence(VM.LookupActivity("ACT_VM_RECOIL3"),1)!=(-1))
			AttackSequence=VM.SelectWeightedSequence(VM.LookupActivity("ACT_VM_RECOIL3"),1);
			
		if (Name.find("dual"))
		{
			
			//printl(AttackSequence)
			if (((clip+clip2)%2==1||clip2<=0)&&clip>0)
			{
				//if (clip2>0) nextattack=Time()+firerate/2
				clip--
				AttackSequence=VM.LookupSequence("fire_r")
			}
			else 
			{
				if (clip>0) nextattack=Time()+firerate/2
				clip2--;
				AttackSequence=VM.LookupSequence("fire_l")
			}
		}
		else
		{
			clip--
		}
		
		if (Name.find("2000")&&Info.Scoped)
		{
			MuzzleFlash()
			printl("flash")
		}
		//player.DoMuzzleFlash()
		player.GetActiveWeapon().SendWeaponAnim(AttackSequence)
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
		VM.SetSequence(AttackSequence)
		player.GetActiveWeapon().SetWeaponIdleTime(Time()+VM.SequenceDuration(AttackSequence))
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
		
		
		local muzzlerate=(Auto ? firerate : firerate+0.1)
		
		EntFireByHandle(flashEnt, "setcolortransitiontime", 0.07,0.001)
		EntFireByHandle(flashEnt, "setbrightness", "0",0.001)
		EntFireByHandle(flashEnt, "Kill", "", min(muzzlerate * 0.5, 0.075)*2)
		EntFireByHandle(flashEnt2, "Kill", "", min(muzzlerate * 0.5, 0.075))
		local punch=Vector(RandomFloat(-0.1,-0.2),RandomFloat(-0.05,0.05),RandomFloat(-0.1,0.1)*Convars.GetInt("sw_shake"))
		
		
		//DispatchParticleEffect("muzzle_pistols",VM.GetAttachmentOrigin(attach),flashAngle,player)
		DispatchParticleEffect("view_muzzle_pistols",VM.GetAttachmentOrigin(1)+Vector(0,0,player.GetBoundingMaxs().z-8)+player.GetEyeForward()*3,VectorAngles(player.GetAutoaimVector(AUTOAIM_SCALE_DEFAULT)),Entities.First())
		
		if (!IsShotgun) player.ViewPunch(punch*(1+shotsfired/10*1.2)/crouching*RecoilMult/1.5);
		else player.ViewPunch(punch*RecoilMult);	
		
		
		
		if (!IsShotgun&&!ReduceShake) ShakePlayerScreen(200*RecoilMult,4*(punch*(1+clamp(shotsfired,0,10)/10*1.2)/crouching*RecoilMult/1.5).Length(),1.5*RecoilMult,(RecoilMult>40));
		else if (!ReduceShake) ShakePlayerScreen(200*RecoilMult,4*(punch*RecoilMult).Length(),1.5*RecoilMult,true);
		
		
		
		InsertAISound( SOUND_COMBAT, player.GetOrigin(), SOUNDENT_VOLUME_MACHINEGUN, 0.2, player, 0, null );
		
		
		local StartSpread=((IsShotgun) ? Vector(0.02,0.02,0.02) : Vector(0.03,0.03,0.03))


		local ran=rand()
		local info = CreateFireBulletsInfo(1, player.ShootPosition()+player.GetEyeForward()*10, player.GetAutoaimVector(AUTOAIM_SCALE_DEFAULT), StartSpread*accuracy, Damage, player)
		info.SetTracerFreq(1)
		info.SetDamageForceScale(Damage*0.33)
		info.SetAmmoType(3)
		info.SetDistance(5000)
		info.SetTracerFreq(0)
		

		local spred=info.GetSpread()
		info.SetSpread(Vector())
		
		for (local i=0;i<BulletsPerShot;i++)
		{
			local deg=RandomFloat(-PI,PI)
			local dist=RandomFloat(-1,1)
			info.SetDirShooting(player.GetAutoaimVector(AUTOAIM_SCALE_DEFAULT)+Vector(spred.x*sin(deg)*dist,spred.y*sin(deg)*dist,spred.z*cos(deg)*dist))
			
			player.GetActiveWeapon().FireBullets(info);
			
			local trace=TraceLineComplex(info.GetSource(), info.GetSource()+info.GetDirShooting()*5000,player,MASK_SHOT,0)
			
			
			local IsRight=1
			if (Name.find("dual"))
			{
				if (!(((clip+clip2)%2==0||clip2<=0)&&clip>0))
				{
					IsRight=-1
				}
			}
			
			
			local traceeffect="weapon_tracers"
			if (ImpactOverride)
			{
				DispatchEffect("AR2Impact",info.GetSource()+info.GetDirShooting()*5000*trace.Fraction(),VectorAngles(trace.Plane().normal))
			}
			if (TracerOverride)
			{
				traceeffect=TracerOverride;
			}
			local endpoint_name=UniqueString("ar1tracer")
			local EndPoint=SpawnEntityFromTable("info_target",{spawnflags=1,targetname=endpoint_name,origin=info.GetSource()+info.GetDirShooting()*5000*trace.Fraction()})
			
			local Tracer_t={
			effect_name=traceeffect//weapon_ar1_tracer
			start_active=1
			//cpoint0="!self"
			cpoint1=endpoint_name
			parentname=player.GetName()
			origin=(info.GetSource()+player.GetEyeRight()*12*(1-("Scoped" in Info&&Info.Scoped).tointeger())*IsRight-player.GetEyeUp()*6+player.GetEyeForward()*120+player.GetVelocity()*0.025).ToKVString()
			//origin=(muzzle+player.GetEyeRight()*0-player.GetEyeUp()*0+player.GetEyeForward()*10+player.GetVelocity()*0.015).ToKVString()
			}
			local Tracer = SpawnEntityFromTable("info_particle_system",Tracer_t)
			EntFireByHandle(Tracer,"DestroyImmediately","",1)
			EntFireByHandle(Tracer,"Kill","",1.1)
			EntFireByHandle(EndPoint,"Kill","",0.1)
			DestroyFireBulletsInfo(info)
		}

		DecreaseDurability(1)
		
		if (IsShotgun) NeedPump=true;
		
		shotsfired++;
		
		if (wepdur<0.02) shotsfired++;
		if (wepdur<0.03) nextattack+=firerate*0.25
		if (wepdur<0.015) nextattack+=firerate*0.25
	}
}

constructor(SysName,WeaponInfo)
{
	AMMOTYPE=WeaponInfo.AmmoType
	ShootSound=WeaponInfo.ShootSound
	//Model="models/weapons/v_smg1.mdl"
	Model=WeaponInfo.Model
	Name=SysName
	InvSlot=null
	Damage=WeaponInfo.Damage
	init=1
	firerate=WeaponInfo.Firerate
	nextattack=0
	nextreload=0
	reloading=false
	shotsfired=0
	accuracy=1
	clip=WeaponInfo.Clip
	maxclip=WeaponInfo.Clip
	InAccuracy=WeaponInfo.InAccuracy
	BaseInAccuracy=WeaponInfo.InAccuracy
	RecoilMult=WeaponInfo.RecoilMult
	
	AllowPrimaryAttack=true
	AllowReload=true
	AMMODISPLAYTYPE=AMMOTYPE
	ReduceShake=false;
	
	if ("DrawSound" in WeaponInfo) DrawSound=WeaponInfo.DrawSound
	if ("ReloadSound" in WeaponInfo) ReloadSound=WeaponInfo.ReloadSound
	if ("ShootSound2" in WeaponInfo) ShootSound2=WeaponInfo.ShootSound2
	if ("PumpSound" in WeaponInfo) PumpSound=WeaponInfo.PumpSound
	if ("ReloadsSingly" in WeaponInfo) ReloadsSingly=WeaponInfo.ReloadsSingly
	if ("SemiAuto" in WeaponInfo) Auto=(!WeaponInfo.SemiAuto)
	if ("BulletsPerShot" in WeaponInfo) BulletsPerShot=WeaponInfo.BulletsPerShot
	if ("IsShotgun" in WeaponInfo) IsShotgun=WeaponInfo.IsShotgun
	if ("BurstFire" in WeaponInfo) BurstFire=WeaponInfo.BurstFire
	if ("SecondaryAttack" in WeaponInfo) SecondaryAttack=WeaponInfo.SecondaryAttack
	if ("PrimaryAttack" in WeaponInfo) PrimaryAttack=WeaponInfo.PrimaryAttack
	if ("ForcePrimaryAttack" in WeaponInfo) ForcePrimaryAttack=WeaponInfo.ForcePrimaryAttack
	if ("Dual" in WeaponInfo) Dual=WeaponInfo.Dual
	if ("Spread" in WeaponInfo) Spread=WeaponInfo.Spread
	if ("Spread" in WeaponInfo) BaseSpread=WeaponInfo.Spread
	if ("RecoveryBonus" in WeaponInfo) RecoveryBonus=WeaponInfo.RecoveryBonus
	if ("AccuracyBonus" in WeaponInfo) AccuracyBonus=WeaponInfo.AccuracyBonus
	if ("RecoverySpeed" in WeaponInfo) RecoverySpeed=WeaponInfo.RecoverySpeed
	if ("AttackCost" in WeaponInfo) AttackCost=WeaponInfo.AttackCost
	if ("SingleUse" in WeaponInfo) SingleUse=WeaponInfo.SingleUse
	if ("UseEmptyAnims" in WeaponInfo) SupportsEmptyAnims=WeaponInfo.UseEmptyAnims
	if ("ImpactOverride" in WeaponInfo) ImpactOverride=WeaponInfo.ImpactOverride
	if ("TracerOverride" in WeaponInfo) TracerOverride=WeaponInfo.TracerOverride
	
	foreach (k,v in WeaponInfo)
	{
		if (!(k in this))
		{
			this.Info.rawset(k,v)
		}
	}

}

HoldingPropTime=-10;

function Update()
{
	if (!init) return;
	//printl("attempt1")
	if ("Weapon" in aPlayer) LastWeapon=null
	
	if (!PlayerHasWeapon()) return;
	//printl("attempt2")
	//printl("Updating slot "+InvSlot)
	if (player.GetHealth()<=0) return;
	if (aPlayer.Weapon!=this) return;
	
	if (SERVER_DLL&&GetPlayerHeldEntity(player))
	{
		HoldingPropTime=Time()
	}
	
	if (SERVER_DLL&&Time()-HoldingPropTime<0.1)
	{
		if (player.GetViewModel(0).GetModelName()==Model) player.GetViewModel(0).SetModel("models/blackout.mdl")
		return
	}
	
	//printl("attempt3")
	if (LastWeapon!=aPlayer.Weapon.Name)
	{
		SendPlayerWeaponChange()
	}
	LastWeapon=aPlayer.Weapon.Name
	
	//if (SERVER_DLL&&player.GetViewModel(0).GetSequence() == player.GetViewModel(0).SelectHeaviestSequence(player.GetViewModel(0).LookupActivity("ACT_VM_HOLSTER"))) return;
	
	if (Name.find("dual")==null) 
	{
		foreach (i,cell in INVENTORY)
		{
			if ("tech_name" in cell) if (SERVER_DLL&&cell.tech_name==aPlayer.Weapon.Name&&cell.WeaponInvID==aPlayer.ActiveWeaponSlot) 
			{
				if (cell.Clip!=clip)
				{
					NetMsg.Start("SyncInvClipOnClient")
					NetMsg.WriteShort(i)
					NetMsg.WriteShort(clip)
					NetMsg.Send(player,true)
					//printl("syncing")
				}
				cell.Clip=clip;
				break
			}
		}
	}
	else if (aPlayer.DualWield[0]!=null&&aPlayer.DualWield[1]!=null)
	{
		foreach (i,cell in INVENTORY)
		{
			if ("tech_name" in cell) if (SERVER_DLL&&cell.tech_name==aPlayer.Weapons[aPlayer.DualWield[0]].Name&&cell.WeaponInvID==aPlayer.DualWield[0]) 
			{
				if (cell.Clip!=clip)
				{
					NetMsg.Start("SyncInvClipOnClient")
					NetMsg.WriteShort(i)
					NetMsg.WriteShort(clip)
					NetMsg.Send(player,true)
					//printl("syncing")
					cell.Clip=clip;
				}
				
				break
			}
		}
		foreach (i,cell in INVENTORY)
		{
			if ("tech_name" in cell) if (SERVER_DLL&&cell.tech_name==aPlayer.Weapons[aPlayer.DualWield[1]].Name&&cell.WeaponInvID==aPlayer.DualWield[1]) 
			{
				if (cell.Clip!=clip2)
				{
					NetMsg.Start("SyncInvClipOnClient")
					NetMsg.WriteShort(i)
					NetMsg.WriteShort(clip2)
					NetMsg.Send(player,true)
					//printl("syncing")
					cell.Clip=clip2;
				}
				
				break
			}
		}
	}
	//printl("doing update for "+this.Name)
	
	if (CLIENT_DLL) return;
	//printl(aPlayer.Weapon)
	local VM=player.GetViewModel(0)
	
	if (!VM) {printl("no vm");return} 
	
	if (clip==0&&SupportsEmptyAnims&&!reloading) UseEmptyAnims=true;
	else UseEmptyAnims=false;
	
	if (UseEmptyAnims) IdleOverride=("ACT_VM_IDLE_EMPTY");
	else if (IdleOverride==("ACT_VM_IDLE_EMPTY")) IdleOverride="";
	
	if (VM.GetModelName()!=Model)
	{
		reloading=false
		VM.SetModel(Model);
		if (VM.GetSequence() != VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW"+(UseEmptyAnims ? "_EMPTY" : ""))))
		{
			player.GetActiveWeapon().SendWeaponAnim(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW"+(UseEmptyAnims ? "_EMPTY" : ""))))
			VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW"+(UseEmptyAnims ? "_EMPTY" : ""))))
		}
		//VM.SetPlaybackRate(2)
		nextattack=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW"+(UseEmptyAnims ? "_EMPTY" : ""))))
		nextreload=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW"+(UseEmptyAnims ? "_EMPTY" : ""))))
		player.GetActiveWeapon().SetWeaponIdleTime(nextreload)
		if (DrawSound&&!GetNamedEnt("Playermodel")) player.GetActiveWeapon().EmitSound(DrawSound)
		return
	}
	//player.GetActiveWeapon().SendWeaponAnim(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_IDLE")))
	//if (VM.GetSequence()!=VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_IDLE"))) VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_IDLE")));
	if (VM.GetSequence()==VM.LookupSequence("idle")&&Model.find("m4a1")!=null) VM.SetSequence(VM.LookupSequence("idle_unsil"))
	if (VM.GetSequence()==VM.LookupSequence("idle")&&SingleUse&&this.IdleOverride!="") VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity(this.IdleOverride)))
	//player.SetWeaponIdleTime(Time()+1)
	
	if (Model.find("mirror")!=null)
	{
		SendToConsole("cl_righthand 0")
		SendToConsole("viewmodel_fov 80")
	}
	else
	{
		SendToConsole("cl_righthand 1")
		SendToConsole("viewmodel_fov 70")
	}	
	//printl("doing updates for "+this)
	
	//NetMsg.Start("WeaponStatus")
	//NetMsg.WriteString(Name)
	//NetMsg.Send(player, true)
	if ((VM.GetSequence() == VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW"+(UseEmptyAnims ? "_EMPTY" : ""))))||(VM.GetSequence() == VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER"))))
	{
		//return 0.005
		VM.SetPlaybackRate(1)
	}
	else VM.SetPlaybackRate(1);
	
	if (VM.GetSequence() == VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_HOLSTER")))
	{
		reloading=false
		return
	}
	
	if (clip<=0&&clip2<=0&&!reloading&&(player.GetButtons() & IN.ATTACK)&&Time()>nextattack)
	{
		ReloadWeapon()
	}
	
	if (reloading&&nextreload<Time()&&!(ReloadsSingly))
	{
		if (Name.find("dual")==null)
		{
			local ammo_to_load=clamp(maxclip-clip,0,Entities.FindByName(null,"stamina_system").GetScriptScope().HasItemCount(LIST_ITEMS[AMMOTYPE].name))
			if (SERVER_DLL) Entities.FindByName(null,"stamina_system").GetScriptScope().RemoveItem(AMMOTYPE,ammo_to_load);
			clip+=ammo_to_load
		}
		else
		{
			local ammo_to_load=clamp(maxclip/2-clip,0,Entities.FindByName(null,"stamina_system").GetScriptScope().HasItemCount(LIST_ITEMS[AMMOTYPE].name))
			if (SERVER_DLL) Entities.FindByName(null,"stamina_system").GetScriptScope().RemoveItem(AMMOTYPE,ammo_to_load);
			clip+=ammo_to_load
			
			local ammo_to_load=clamp(maxclip/2-clip2,0,Entities.FindByName(null,"stamina_system").GetScriptScope().HasItemCount(LIST_ITEMS[AMMOTYPE].name))
			if (SERVER_DLL) Entities.FindByName(null,"stamina_system").GetScriptScope().RemoveItem(AMMOTYPE,ammo_to_load);
			clip2+=ammo_to_load
		}
		//printl("loaded in: "+ammo_to_load)
		//printl("clip after reload"+clip)
		//printl("reserve ammo after reload "+Entities.FindByName(null,"stamina_system").GetScriptScope().HasItemCount(LIST_ITEMS[AMMOTYPE].name))
		reloading=false
		Jammed=false
		//printl("finishing reload")
	}
	
	if (reloading&&nextreload<Time()&&ReloadsSingly)
	{
		switch(ReloadState)
		{
			case 0:
			{
				if (Model.find("rif")==null&&Model.find("357")==null) player.EmitSound(ReloadSound)
				
				//local ReloadSequence=SelectRandomSequence(VM,"ACT_VM_RELOAD")
				local ReloadSequence=VM.SelectWeightedSequence(VM.LookupActivity("ACT_VM_RELOAD"),1)

				
				//printl(ReloadSequence)
				player.GetActiveWeapon().SendWeaponAnim(ReloadSequence)
				VM.SetSequence(ReloadSequence)
				nextattack=Time()+VM.SequenceDuration(ReloadSequence)
				nextreload=Time()+VM.SequenceDuration(ReloadSequence)
				player.GetActiveWeapon().SetWeaponIdleTime(nextreload+0.1)
				
				local ammo_to_load=clamp(clamp(maxclip-clip,0,1),0,Entities.FindByName(null,"stamina_system").GetScriptScope().HasItemCount(LIST_ITEMS[AMMOTYPE].name))
				//aPlayer.ammo[AMMOTYPE]-=ammo_to_load
				if (SERVER_DLL) Entities.FindByName(null,"stamina_system").GetScriptScope().RemoveItem(AMMOTYPE,ammo_to_load);
				clip+=ammo_to_load
				
				ReloadState=1
				break;
			}
			case 1:
			{
				local ammo_to_load=clamp(clamp(maxclip-clip,0,1),0,Entities.FindByName(null,"stamina_system").GetScriptScope().HasItemCount(LIST_ITEMS[AMMOTYPE].name))
				//aPlayer.ammo[AMMOTYPE]-=ammo_to_load
				if (ammo_to_load==0||(player.GetButtons() & IN.ATTACK)||(player.GetButtons() & IN.ATTACK2&&clip>1)) ReloadState=2;
				else ReloadState=0;
				if (!(player.GetButtons() & IN.ATTACK)) break;
			}
			case 2:
			{
				VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_SHOTGUN_RELOAD_FINISH")))
				nextattack=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_SHOTGUN_RELOAD_FINISH")))
				nextreload=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_SHOTGUN_RELOAD_FINISH")))
				player.GetActiveWeapon().SetWeaponIdleTime(nextreload)
				ReloadState=3
				break;
			}
			case 3:
			{
				reloading=false
				break;
			}
		}
	}
	
	if (player.GetButtons() & IN.RELOAD&&((clip+clip2)<maxclip||Jammed)&&!reloading&&Time()>nextattack)
	{
		ReloadWeapon()
		return
	}
	
	if (player.GetButtons() & IN.ATTACK2 &&!(VM.GetSequence() == VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW"))))
	{
		//aPlayer.Weapon=aPlayer.Weapons[clamp(aPlayer.Weapons.find(Name)+1,0,aPlayer.Weapons.len()-1)]
		//if (aPlayer.Weapon==Name) aPlayer.Weapon=aPlayer.Weapons[0];
		//VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW")))
		//return
	}
	
	if (NeedPump&&(VM.GetSequence() == VM.SelectWeightedSequence(VM.LookupActivity("ACT_SHOTGUN_PUMP"),1)))
	{
		VM.SetPlaybackRate(1.25)
	}
	
	if (NeedPump2&&Time()>nextattack&&!reloading&&clip>0)
	{
		player.GetActiveWeapon().SendWeaponAnim(VM.SelectWeightedSequence(VM.LookupActivity("ACT_SHOTGUN_PUMP"),1))
		VM.SetSequence(VM.SelectWeightedSequence(VM.LookupActivity("ACT_SHOTGUN_PUMP"),1))
		player.EmitSound(PumpSound ? PumpSound : "Weapon_Shotgun.Special1")
		nextattack=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_SHOTGUN_PUMP")))/3
		nextreload=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_SHOTGUN_PUMP")))/3
		player.GetActiveWeapon().SetWeaponIdleTime(nextreload)
		NeedPump2=false
		NeedPump=true
		return 0
	}
	
	if (NeedPump&&Time()>nextattack&&!reloading&&clip>0)
	{
		player.GetActiveWeapon().SendWeaponAnim(VM.SelectWeightedSequence(VM.LookupActivity("ACT_SHOTGUN_PUMP"),1))
		VM.SetSequence(VM.SelectWeightedSequence(VM.LookupActivity("ACT_SHOTGUN_PUMP"),1))
		player.EmitSound(PumpSound ? PumpSound : "Weapon_Shotgun.Special1")
		nextattack=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_SHOTGUN_PUMP")))
		nextreload=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_SHOTGUN_PUMP")))
		player.GetActiveWeapon().SetWeaponIdleTime(nextreload)
		NeedPump=false
		Jammed=false
		return 0
	}
	
	//printl(aPlayer.Weapon.Name)
	
	PrimaryAttack.call(this)
	if (SecondaryAttack!=null) SecondaryAttack.call(this,this)
	
	LastPress=(player.GetButtonLast() & IN.ATTACK)
	
	if ((nextattack+firerate-RecoveryBonus<Time()||reloading)&&Auto)
	{
		shotsfired=clamp(shotsfired-1-RecoverySpeed,clamp(Spread,0,100),maxclip)
	}
	if (BurstFire&&(nextattack-Time()>0.1))
	{
		shotsfired=clamp(shotsfired-1-RecoverySpeed,clamp(Spread,0,100),maxclip)
	}
	if ((nextattack+firerate*2-RecoveryBonus<Time()||reloading)&&!Auto)
	{
		shotsfired=clamp(shotsfired-0.1-RecoverySpeed,clamp(Spread,0,100),maxclip)
	}

	if (AMMOTYPE!="item_ammo_none"&&SingleUse==false)
	{
		NetMsg.Start("SetAmmo")
		NetMsg.WriteLong(clip+clip2)
		NetMsg.WriteLong(maxclip)
		//NetMsg.WriteLong(aPlayer.ammo[AMMOTYPE])
		NetMsg.WriteLong(Entities.FindByName(null,"stamina_system").GetScriptScope().HasItemCount(LIST_ITEMS[AMMODISPLAYTYPE].name))
		NetMsg.Send(player, true)
	}
	
	if (AMMOTYPE!="item_ammo_none"&&SingleUse==true)
	{
		NetMsg.Start("SetAmmoSingle")
		NetMsg.WriteShort(Entities.FindByName(null,"stamina_system").GetScriptScope().HasItemCount(LIST_ITEMS[AMMODISPLAYTYPE].name))
		NetMsg.Send(player, true)
	}
	
	//NetMsg.WriteFloat(1+(shotsfired*0.1)+((10+player.GetVelocity().Length())/50)/crouching)
	//NetMsg.WriteShort(maxclip)
	//NetMsg.Send(player, true)

	
	if ((VM.GetSequenceActivityName(VM.GetSequence())=="ACT_VM_IDLE")||(VM.GetSequenceActivityName(VM.GetSequence())==this.IdleOverride)&&player.GetActiveWeapon().GetWeaponIdleTime()<Time())
	{
		//player.GetActiveWeapon().SendWeaponAnim(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_IDLE")))
		
		local IdleSequence=VM.SelectWeightedSequence(VM.LookupActivity((IdleOverride=="") ? "ACT_VM_IDLE" : IdleOverride),1)
		
		if (Time()>LastIdleTime) 
		{
			VM.SetSequence(IdleSequence);
			player.GetActiveWeapon().SetWeaponIdleTime(Time()+VM.SequenceDuration(IdleSequence))
			LastIdleTime=Time()+VM.SequenceDuration(IdleSequence)
		}
	}
	
	return 0.005
}

d=0
vm=null

panel=null
//Convars.RegisterConvar( "sourceworld_crosshair" "1", "Toggles crosshair for Sourceworld weapons", FCVAR_NONE )
}