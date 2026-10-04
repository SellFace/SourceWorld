IncludeScript("weapons/weapon_base.nut")
self.PrecacheSoundScript("Weapon_SMG45.Single")
local weapon=null



function Update(...)
{
	if (!weapon) return
	weapon.Update()
	return 0.005
}
::aPlayer<-null
function InitWeapon(...)
{
	IncludeScript("weapons/weapon_base.nut")
	aPlayer=player.GetOrCreatePrivateScriptScope()
	weapon=C_BaseWeapon("weapon_smg45","SMG","models/weapons/v_smg45.mdl",0.085,0.9,30,6,"Weapon_SMG45.Single")
	Init(weapon)
}
Entities.EnableEntityListening()
ListenToGameEvent( "player_spawn", InitWeapon,"Init2");
//Entities.First().SetContextThink("Update",Update,0)
/*
RegisterActivityConstants()

local VECTOR_CONE_2DEGREES = VECTOR_CONE_2DEGREES;
local AMMOTYPE="MP7"
local init=null
function Init(...)
{
	aPlayer<-player.GetOrCreatePrivateScriptScope()
	if (!("Weapon" in aPlayer))
	{
		aPlayer.Weapon<-"weapon_mp7"
	}
	aPlayer.Weapon<-"weapon_mp7"
	if (!("ammo" in aPlayer)) aPlayer.ammo<-{AMMOTYPE=0};
	//aPlayer.ammo[]<-AMMOTYPE
	aPlayer.ammo[AMMOTYPE]<-60
	init=1
	
	printl("-------------")
	printl("MP7 INIT")
	printl("-------------")
}

ListenToGameEvent( "player_spawn", Init,"Init"+AMMOTYPE);

local muzzleFlashTable = {
	brightnessscale = 2,
	farz = 850,
	lightcolor = "255 255 255 225",
	lightfov = 80,
	nearz = 10,
	spawnflags = 1,
	texturename = "effects/muzzleflash_light"
}

local muzzlelight = {
	_cone = 0,
	_inner_cone = 0,
	_light = "249 205 67 2200",
	brightness = 1,
	distance = 200
	pitch = -90,
	//spawnflags = 1,
	style=1
}

//VM.SetModel("models/weapons/v_mp5k.mdl");
local firerate=0.065
local nextattack=0
local nextreload=0
local reloading=false
local shotsfired=0
local accuracy=1
clip<-30
function PlayerHasWeapon()
{
	//if (!aPlayer) return false;
	if (!("Weapon" in aPlayer)) return false;
	if (aPlayer.Weapon=="weapon_mp7") return true;
	else return false
}
function Update()
{
	local ammo=Entities.FindByNameWithin(null,"ammo_smg",player.GetOrigin(),48)
	if (ammo)
	{
		ammo.GetOrCreatePrivateScriptScope().TakeAmmo()
		if (CLIENT_DLL) msg="Picked up ammo!";
	}

	if (!init) return;
	if (!PlayerHasWeapon()) return;
	local VM=player.GetViewModel(0)
	if (!VM) {printl("no vm");return} 
	if (VM.GetModelName()!="models/weapons/v_smg1.mdl")
	{
		VM.SetModel("models/weapons/v_smg1.mdl");
		VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW")))
		nextattack=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW")))
		nextreload=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW")))
		player.GetActiveWeapon().SetWeaponIdleTime(nextreload)
		player.EmitSound("weapon.ImpactSoft")
	}
	function ReloadWeapon()
	{
		if (!aPlayer.ammo[AMMOTYPE]) {return}
		reloading=true
		//shotsfired=0
		player.EmitSound("Weapon_SMG1.NPC_Reload")
		VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_RELOAD")))
		nextattack=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_RELOAD")))
		nextreload=Time()+VM.SequenceDuration(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_RELOAD")))
		player.GetActiveWeapon().SetWeaponIdleTime(nextreload)
	}
	if (clip<=0&&!reloading)
	{
		ReloadWeapon()
	}
	if (reloading&&nextreload<Time())
	{
		local ammo_to_load=clamp(30-clip,0,aPlayer.ammo[AMMOTYPE])
		aPlayer.ammo[AMMOTYPE]-=ammo_to_load
		clip+=ammo_to_load
		reloading=false
	}
	if (player.GetButtons() & IN.RELOAD&&clip<30&&!reloading)
	{
		ReloadWeapon()
		return
	}
	if (player.GetButtons() & IN.ATTACK2 &&!(VM.GetSequence() == VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW"))))
	{
		aPlayer.Weapon="weapon_mp5k"
		//VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_DRAW")))
		return
	}
	if (player.GetButtons() & IN.ATTACK&&nextattack<Time()&&clip>0)
	{
		shotsfired++
		clip--
		nextattack=Time()+firerate
		player.EmitSound("Weapon_SMG1.Single")
		local crouching=1
		if ((player.GetFlags() & 2)==2) crouching=2;
		else crouching=1;
		accuracy=1+(shotsfired*0.16)+((10+player.GetVelocity().Length())/45)/crouching
		local info = CreateFireBulletsInfo(1, player.ShootPosition(), player.GetAutoaimVector(AUTOAIM_SCALE_DEFAULT), VECTOR_CONE_1DEGREES*accuracy, 5, player)
		info.SetTracerFreq(1)
		info.SetAmmoType(3)
		info.SetDistance(5000)
		player.GetActiveWeapon().FireBullets(info)
		DestroyFireBulletsInfo(info)
		
		
		if (shotsfired<3)
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
			VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_RECOIL3")))
			}
			else {
				VM.SetSequence(VM.SelectHeaviestSequence(VM.LookupActivity("ACT_VM_RECOIL2")))
			}
		}
		
		muzzleFlashTable.lightfov = RandomFloat(85, 100)
		local flashEnt = SpawnEntityFromTable("env_projectedtexture", muzzleFlashTable)
		local flashEnt2 = SpawnEntityFromTable("light_dynamic", muzzlelight)
		flashEnt.SetOrigin(player.ShootPosition())
		flashEnt2.SetOrigin(player.EyePosition()+player.GetEyeForward()*40)
		local flashAngle = VectorAngles(player.GetAutoaimVector(AUTOAIM_SCALE_DEFAULT))
		flashAngle.z = RandomFloat(0, 360)
		flashEnt.SetAngles(flashAngle)
		EntFireByHandle(flashEnt, "Kill", "", min(firerate * 0.8, 0.05))
		EntFireByHandle(flashEnt2, "Kill", "", min(firerate * 5.9, 0.15))
		local punch=Vector(RandomFloat(-0.1,-0.2),RandomFloat(-0.05,0.05),0)
		player.ViewPunch(punch+punch*(1+shotsfired*1.2)/crouching)
	}
	if (nextattack+firerate*2<Time()||reloading)
	{
		shotsfired=clamp(shotsfired-2,0,30)
	}
	NetMsg.Start("SetAmmo")
	NetMsg.WriteLong(clip)
	NetMsg.WriteLong(aPlayer.ammo[AMMOTYPE])
	local crouching=1
	if ((player.GetFlags() & 2)==2) crouching=2;
	NetMsg.WriteFloat(1+(shotsfired*0.1)+((10+player.GetVelocity().Length())/50)/crouching)
	NetMsg.Send(player, true)
	NetMsg.Start("WeaponStatus")
	NetMsg.WriteString("weapon_mp5k")
	NetMsg.Send(player, true)
	return 0.005
}
//Entities.First().SetContextThink( "ViewModelCollision", null, 0.0 );
local origins=Vector(0,0,0)
local reald=0
function ClientThink()
{
	if (SERVER_DLL) return;
	local vm = Entities.FindByClassname( null, "viewmodel" );

	local d=((player.GetLocalOrigin()-origins).Length()*100).tointeger()/100.0
	origins=player.GetOrigin()
	d=clamp(d,0,1.4)
	
	//printl(reald)
	
	if (d>reald) reald+=0.01;
	if (d<reald) reald-=0.01;
	//reald=(reald*100).tointeger()/100.0
	//if (d<50){return}
	if ( vm )
	{
		local a=sin(Time()*2)/3*reald*2
		local b=sin(Time()*7)/2*reald*5
		vm.SetLocalOrigin(vm.GetLocalOrigin()+Vector(0,0,a))
		vm.SetLocalAngles(vm.GetLocalAngles()+Vector(a/2+b/6,a*2/2,b/3+a*3));
	}
	return 0.0
}
if (CLIENT_DLL)
{
	local weapon=null
	local clip=30
	local currentAccuracy=2
	SetHudElementVisible("CHudFlashlight",false)
	panel <-null
	surface.CreateFont( "AmmoTextFont",
	{
		"name"			: "HalfLife2"
		"tall"			: 25
		"weight"		: 300
		"antialias" 	: true
		"dropshadow" 	: false
		"additive"		: true
		"proportional" 	: true
	} );
	surface.CreateFont( "AmmoNumberFont",
	{
		"name"			: "HalfLife2"
		"tall"			: 32
		"weight"		: 880
		"additive"		: true
		"antialias" 	: true
		"dropshadow" 	: false
		"proportional" 	: true
	} );
	local DisplayAmmo=0
	function DrawText(text)
	{	
		printl(text)
		local timestart=Time()
		local TimeEndDraw=Time()+2
		local TimeEnd=Time()+5
		local drawtext=text.slice(0,RemapVal(Time(),timestart,TimeEndDraw,0,text.len()).tointeger())
		surface.DrawColoredText(22, XRES(320), YRES(460), 0, 153, 255, 200, text)
	}
	function Paint()
	{
		if (!weapon) return;
		surface.SetColor(0, 0, 0, 76)
		/*surface.DrawColoredText(99, XRES(295), YRES(440), 255, 220, 0, 100, "r")
		//surface.DrawColoredText(surface.GetFont("AmmoTextFont", false), XRES(560), YRES(455), 255, 220, 0, 100, "r")
		if (clip>5) surface.DrawColoredText(surface.GetFont("AmmoNumberFont", true), XRES(315), YRES(435), 255, 220, 0, 100, clip.tostring());
		else surface.DrawColoredText(surface.GetFont("AmmoNumberFont", true), XRES(315), YRES(435), 255, 40, 5, 100, clip.tostring());
		
		
		for (local i=0;i<30;i++)
		{
			local mult=1
			if (i>clip-1) surface.DrawColoredText(surface.GetFont("AmmoTextFont",true), XRES(600), YRES(440-5.3*i), 25, 25, 25, 200, "r");
			else surface.DrawColoredText(surface.GetFont("AmmoTextFont",true), XRES(600), YRES(440-5.3*i), 0, 153*mult, 255*mult, 200, "r")
		}
		//local DisplayAmmo=0
		//if (aPlayer.ammo!=null) {DisplayAmmo=aPlayer.ammo}
		surface.DrawColoredText(19, XRES(598.5), YRES(460), 0, 153, 255, 200, "AMMO "+DisplayAmmo)
		surface.SetColor(0, 153, 255, 255)
		surface.DrawFilledRect((XRES(320)-currentAccuracy*5 - XRES(3)),YRES(240)-1,XRES(3),2)
		surface.DrawFilledRect((XRES(320)+currentAccuracy*5),YRES(240)-1,XRES(3),2)
		surface.DrawFilledRect(XRES(320)-1,YRES(240)-currentAccuracy*5 - XRES(3),2,XRES(3))
		surface.DrawFilledRect(XRES(320)-1,YRES(240)+currentAccuracy*5,2,XRES(3))
		
	}
	
	NetMsg.Receive("SetAmmo", function() {
		clip = NetMsg.ReadLong()
		DisplayAmmo = NetMsg.ReadLong()
		currentAccuracy = NetMsg.ReadFloat()
	})
	NetMsg.Receive("WeaponStatus", function() {
		weapon = NetMsg.ReadString()
	})
	panel = vgui.CreatePanel("Panel", vgui.GetRootPanel(), "Screen")
	panel.MakeReadyForUse()
	panel.SetVisible(true)
	panel.SetPos(XRES(0), YRES(0))
	panel.SetSize(XRES(640),YRES(480))
	panel.SetPaintEnabled(true)
	panel.SetFgColor( 0, 0, 0, 0 )
	panel.SetBgColor( 0, 0, 0, 0 )
	panel.SetZPos(0)
	//panel.SetPaintBackgroundEnabled(true)
	//panel.SetPaintBackgroundType(2)
	panel.SetCallback( "Paint", Paint.bindenv(this) )
}

*/