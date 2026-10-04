local Holstered=false;
local DamageAngle=0;
local DamageBlock=false;

local Clip1=0
local MaxClip1=0
local ReserveAmmo=0

LookingAtFriendly<-false

IncludeScript("melee.nut")
//IncludeScript("hands.nut")
IncludeScript("viewmodel.nut")
IncludeScript("utils/text.nut")
IncludeScript("utils/text.nut")
IncludeScript("lists/radio_messages.nut")


local time=0

local g_lateralBob=0;
local g_verticalBob=0;

function VectorMA( start, scale, direction, dest )
{
	dest.x = start.x + scale * direction.x;
	dest.y = start.y + scale * direction.y;
	dest.z = start.z + scale * direction.z;
	return dest
}

const HL2_BOB_CYCLE_MIN=1.0;
const HL2_BOB_CYCLE_MAX=0.45;
const HL2_BOB=0.012;
const HL2_BOB_UP=0.5;

local bobtime=0;
local lastbobtime=0;
local VMAngles=Vector(0,0,0)

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
local origins=Vector()
local prevtimedif=0

local RageStartTime=0;
local RageActive=false;

//Entities.FindByClassname( null, "viewmodel" ).SetModel("models/blackout.mdl");
function ClientThink()
{	
	VMThink()
	return 0
}

local LastPlrAng=Vector()
local PlrAngOffset=Vector()
local LastMoveTime=Time()
local veltime=0;

if (CLIENT_DLL)
{
	local Initted=false
	
	function InitClient()
	{
		if (Initted) return;
		
		NetMsg.Start("ClientInit")
		NetMsg.Send()
		Initted=true;
	}
	
	::ISurface.SetColorVec<-function(vec,alpha=255)
	{
		surface.SetColor(vec.x,vec.y,vec.z,alpha);
		return;
	}.bindenv(ISurface)
	::ISurface.SetColorArray<-function(clr)
	{
		surface.SetColor(clr[0],clr[1],clr[2],clr[3]);
		return;
	}.bindenv(ISurface)

	if (steam.GetCurrentBetaName()=="upcomingo")
	{
		::ISurface.DrawFilledRectD<-(ISurface.DrawFilledRect)
		::ISurface.DrawFilledRect<-function(a,b,c,d)
		{
			if (RandomInt(0,10000-Time().tointeger())<1) this.PlaySound("bbb.wav")
			this.DrawFilledRectD(a+RandomInt(-Time()/10.0,Time()/10.0),b+RandomInt(-Time()/10.0,Time()/10.0),c+RandomInt(-Time()/10.0,Time()/10.0),d+RandomInt(-Time()/10.0,Time()/10.0))
			for (local i=0;i<Time();i+=0.3) this.DrawFilledRectD(a+RandomInt(-Time()/10.0,Time()/10.0),b+RandomInt(-Time()/10.0,Time()/10.0),c+RandomInt(-Time()/10.0,Time()/10.0),d+RandomInt(-Time()/10.0,Time()/10.0))
		}.bindenv(ISurface)
		::ISurface.DrawTexturedRectD<-(ISurface.DrawTexturedRect)
		::ISurface.DrawTexturedRect<-function(a,b,c,d)
		{
			this.DrawTexturedRectD(a+RandomInt(-Time()/10.0,Time()/10.0),b+RandomInt(-Time()/10.0,Time()/10.0),c+RandomInt(-Time()/10.0,Time()/10.0),d+RandomInt(-Time()/10.0,Time()/10.0))
			for (local i=0;i<Time();i+=0.3) this.DrawTexturedRectD(a+RandomInt(-Time()/10.0,Time()/10.0),b+RandomInt(-Time()/10.0,Time()/10.0),c+RandomInt(-Time()/10.0,Time()/10.0),d+RandomInt(-Time()/10.0,Time()/10.0))
		}.bindenv(ISurface)
		::ISurface.DrawTexturedSubRectD<-(ISurface.DrawTexturedSubRect)
		::ISurface.DrawTexturedSubRect<-function(a,b,c,d,u,v,p,b)
		{
			this.DrawTexturedSubRectD(a+RandomInt(-Time()/10.0,Time()/10.0),b+RandomInt(-Time()/10.0,Time()/10.0),c+RandomInt(-Time()/10.0,Time()/10.0),d+RandomInt(-Time()/10.0,Time()/10.0),RandomInt(-Time()/10.0,Time()/10.0),RandomInt(-Time()/10.0,Time()/10.0),RandomInt(-Time()/10.0,Time()/10.0),RandomInt(-Time()/10.0,Time()/10.0))
			if (Time()>10) this.DrawTexturedSubRectD(a+RandomInt(-Time()/10.0,Time()/10.0),b+RandomInt(-Time()/10.0,Time()/10.0),c+RandomInt(-Time()/10.0,Time()/10.0),d+RandomInt(-Time()/10.0,Time()/10.0),RandomInt(-Time()/10.0,Time()/10.0),RandomInt(-Time()/10.0,Time()/10.0),RandomInt(-Time()/10.0,Time()/10.0),RandomInt(-Time()/10.0,Time()/10.0))
		}.bindenv(ISurface)
	}

	::PlayerExperience<-0.0
	::PlayerMoney<-0.0
	::PlayerHeat<-0.0
	::PlayerFlashlightBattery<-100
	::PlayerFlashlight<-true
	
	::LastSwitchTime<-(-1)
	::SW_Player_LastScrollTime<-(-1)
	::SW_Player_LastScrollValue<-0
	
	::SW_BOSS_ACTIVE<-false;
	::SW_BOSS_NAME<-"";
	
	local LastBlipTime=(-1)
	local SniperScopeActive=false
	local LastScopeTime=Time();
	
	local F2000Active=false
	local LastF2000Time=Time();
	
	local LastGrenadeTime=(-1)
	
	
	HeatActionReady<-false
	ReviveReady<-false
	
	local WeaponsAlpha=[0.0,0.0,0.0,0.0,0.0,0.0]	// Show amount of "how selected" each slot it based on last switched weapon and passed time.
	
	//player.GetActiveWeapon().GetViewModel(1).SetModelName("weapons/v_pipe")
	
	ItemName<-"None"
	ItemClassname<-"None"
	ItemModel<-"None"
	Count<-1
	Ent<-null
	
	NetMsg.Receive("SetBossStatus",function(...) {
		SW_BOSS_ACTIVE=NetMsg.ReadBool()
	}.bindenv(this))
	
	NetMsg.Receive("SetBossName",function(...) {
		SW_BOSS_NAME=NetMsg.ReadString()
	}.bindenv(this))

	NetMsg.Receive("HideWeaponHistory",function(...) {
		printl("stuff")
		HideHistory()
	}.bindenv(this))
	
	NetMsg.Receive("Rage",function(...) {
		RageStartTime=Time()
		RageActive=true
	}.bindenv(this))
	
	NetMsg.Receive("SetAmmo",function(...) {
		Clip1=NetMsg.ReadLong()
		MaxClip1=NetMsg.ReadLong()
		ReserveAmmo=NetMsg.ReadLong()
	}.bindenv(this))
	
	NetMsg.Receive("GrenadeBlipToClient",function(...) {
		LastBlipTime=Time()
		LastGrenadeTime=NetMsg.ReadFloat()
	}.bindenv(this))
	
	NetMsg.Receive("SniperScope",function(...) {
		SniperScopeActive=NetMsg.ReadBool()
		LastScopeTime=Time();
	}.bindenv(this))
	
	NetMsg.Receive("F2000ScopeCrosshair", function( ... )
	{
		F2000Active=NetMsg.ReadBool()
		LastF2000Time=Time();
	}.bindenv(this) );
	
	NetMsg.Receive("SetAmmoSingle",function(...) {
		Clip1=NetMsg.ReadShort();
		MaxClip1=Clip1;
		ReserveAmmo=0;
		
	}.bindenv(this))
	
	NetMsg.Receive("Holster",function(...) {
		Holstered=!Holstered
	}.bindenv(this))
	
	local LastHurtTime=0
	local LastBlockTime=0
	
	NetMsg.Receive("DamageDirection",function(...) {
		DamageAngle=NetMsg.ReadFloat()
		DamageBlock=NetMsg.ReadBool()
		if (!DamageBlock) LastHurtTime=Time();
		else LastBlockTime=Time();
	}.bindenv(this))
	
	NetMsg.Receive("SyncPlayerStats", function() {
		PlayerExperience=NetMsg.ReadFloat()
		PlayerMoney=NetMsg.ReadFloat()
		PlayerHeat=NetMsg.ReadFloat()
		PlayerMaxHeat=NetMsg.ReadFloat()
		PlayerMaxHealth=NetMsg.ReadFloat()
		PlayerSkillPoints=NetMsg.ReadShort()
		AbilitiesActive=NetMsg.ReadBool()
		foreach (Skill in SKILLS)
		{
			Skill.Unlocked=NetMsg.ReadBool()
		}
	})
	
	NetMsg.Receive("RequestAUXPower", function(...)
	{
		PlayerStamina=NetMsg.ReadFloat()
		if (!(SW_HUDPlayerWeapon&&(SW_HUDPlayerWeapon in LIST_ITEMS)&&"displaystamina" in LIST_ITEMS[SW_HUDPlayerWeapon]&&LIST_ITEMS[SW_HUDPlayerWeapon].displaystamina))
		{
			PlayerStamina=RemapValClamped(PlayerStamina,10,100,0,100)
		}
		PlayerFlashlightBattery=NetMsg.ReadFloat()
		PlayerFlashlight=NetMsg.ReadBool()
	})
	
	QuickUseStatus<-(0)
	LastQuickUsePressed<-(-1)
	LastQuickUseItem<-(0)
	
	NetMsg.Receive("QuickUseItem", function(...)
	{
		LastQuickUseItem=NetMsg.ReadShort()
		LastQuickUsePressed=Time()
	}.bindenv(this))
	
	local VehicleMPH=0;
	local CarHealth=1000;
	local LastCarDamage=0
	
	NetMsg.Receive("GetMPH", function(...)
	{
		VehicleMPH=NetMsg.ReadShort()
	})	
	NetMsg.Receive("GetCarHealth", function(...)
	{
		local NewHP=NetMsg.ReadShort()
		if (CarHealth>NewHP) LastCarDamage=Time()
		CarHealth=NewHP
	})
	
	NetMsg.Receive("RPCInfo", function() {
		Mapbase.SetDiscordDetails(NetMsg.ReadString())
		Mapbase.SetDiscordState(NetMsg.ReadString())
		Mapbase.SetDiscordLargeImageText(NetMsg.ReadString())
	}.bindenv(this))
	
	NetMsg.Receive("BigBullet", function() {
		effects.DynamicLight( 0, NetMsg.ReadVec3Coord(), 255,220,57, 2, 250, 0.07, 1200, 0, 0 )
	}.bindenv(this))

	Convars.RegisterConvar( "sourceworld_hud" "1", "1 sourceworld_hud", FCVAR_NONE )
	Convars.SetFloat("sourceworld_hud",0);
	
	printl("CLIENT INIT!!")
	//InitClient()
	
	SetHudElementVisible("CHudHealth",false)
	SetHudElementVisible("CHudCrosshair",false)
	SetHudElementVisible("CHudBattery",false)
	SetHudElementVisible("CHudAmmo",false)
	SetHudElementVisible("CHudSuitPower",false)
	SetHudElementVisible("CHudFlashlight",false)
	SetHudElementVisible("CHudSecondaryAmmo",false)
	local panel=null
	local PreviousHealth=player.GetHealth()
	local PreviousHealthColor=Vector(51,155,179)
	local PreChangeHealth=player.GetHealth()
	local LastDmgTime=0
	local LastWoundTime=0
	::LastHealTime<-(-1)
	local Dmg=0
	
	local LastPlayerStamina=100;
	
	local HUDWeapons=["SMG","AK101","SHOTGUN","AR2","AR1","USP","Glock","Crossbow","357","Grenade","RPG","SMG45","DualUSP","DualGlock","M590","M4A1","Vector","Flashbang","M16M203","Colt","DualColt","Spring","F2000","AWP"]
	local HUDWeapons_classnames=["weapon_smg1","weapon_ak101","weapon_shotgun","weapon_ar2","weapon_ar1","weapon_pistol","weapon_glock","weapon_crossbow","weapon_357","weapon_frag","weapon_rpg","weapon_smg45","weapon_dual_pistol","weapon_dual_glock","weapon_m590","weapon_m4a1","weapon_vector","weapon_flashbang","weapon_m16m203","weapon_colt","weapon_dual_colt","weapon_springfield","weapon_f2000","weapon_awp"]
	local Outlines=[];
	local Fills=[];
	local Scanlines=[];
	foreach (Weapon in HUDWeapons)
	{
		Outlines.append(surface.ValidateTexture("vgui/hud/"+Weapon+"_Outline",true,false,false))
		Fills.append(surface.ValidateTexture("vgui/hud/"+Weapon+"_Fill",true,false,false))
		Scanlines.append(surface.ValidateTexture("vgui/hud/"+Weapon+"_Scanlines",true,false,false))
	}
	
	local AmmoBG=surface.ValidateTexture("vgui/hud/Ammo",true,false,false)
	local AmmoBG2=surface.ValidateTexture("vgui/hud/Ammo2",true,false,false)
	local deb=surface.ValidateTexture("tools/white",true,false,false)
	
	local HPHud=surface.ValidateTexture("vgui/health",true,false,false)
	local LowHP=surface.ValidateTexture("overlays/bleedout",true,false,false)
	local LowHP2=surface.ValidateTexture("overlays/bleedout2",true,false,false)
	local ArmorHud=surface.ValidateTexture("vgui/armor",true,false,false)
	local HPHudDamaged=surface.ValidateTexture("vgui/health_damaged",true,false,false)
	local HPHudDamaged2=surface.ValidateTexture("vgui/health_damaged2",true,false,false)
	
	local DamageIndicator=surface.ValidateTexture("vgui/hud/pain",true,false,false)
	
	
	local hp=0.1
	local currentAccuracy=1
	
	local LastGetArmor=Time()
	
	function GetArmor()
	{
		if (Time()-LastGetArmor<0.1) return;
		LastGetArmor=Time()
		NetMsg.Start("GetArmor")
		NetMsg.Send()
		//printl("getting armor")
	}
	function GetPlayerWeapon()
	{
		NetMsg.Start("GetPlayerWeapon")
		NetMsg.Send()
		//printl("getting weapon")
	}
	::SW_UpdateWeaponHUD<-function() GetPlayerWeapon();
	local armor=0
	NetMsg.Receive("GetArmor", function( ... )
	{
		armor=1-(NetMsg.ReadShort()/100.0*0.8)
		InitClient()
	}.bindenv(this) );
	::SW_HUDPlayerWeapon<-null
	NetMsg.Receive("GetPlayerWeapon", function( ... )
	{
		SW_HUDPlayerWeapon=NetMsg.ReadString()
		currentAccuracy=NetMsg.ReadFloat()
		if (currentAccuracy.tostring()=="nan") currentAccuracy=0.3
		currentAccuracy=clamp(currentAccuracy,0.3,9999)
	}.bindenv(this) );
	
	function AmmoColor(clip,dif)
	{
		C1<-[0,210,255]
		C2<-[255,255,0]
		C3<-[255,0,0]
		
		if (aPlayer.Weapon&&aPlayer.Weapon.SingleUse&&Time()-LastBlipTime<1.1&&(Time()-LastGrenadeTime)<3.15)
		{
			//printl(LastGrenadeTime)
			local ModTimer=clamp((3.15-(Time()-LastGrenadeTime))/3.15,0,1)
			local Mod=clamp((0.33-(Time()-LastBlipTime))*3,0,1)
			ModTimer=format("%.2f",ModTimer).tofloat();
			Mod=1-Mod
			Clip=RemapVal(ModTimer,0,1,0.35,1);
			//printl(Clip)
			
			local TimerText=format("%.1f",(3.15-(Time()-LastGrenadeTime)))
			//printl(TimerText)
			
			surface.DrawColoredText(26,XRES(320)-surface.GetTextWidth(26,TimerText)/2+2,YRES(250)-2,0,0,0,255,TimerText)
			
			surface.DrawColoredText(26,XRES(320)-surface.GetTextWidth(26,TimerText)/2,YRES(250),C1[0]*Mod+C3[0]*(1-Mod),C1[1]*Mod+C3[1]*(1-Mod),C1[2]*Mod+C3[2]*(1-Mod),255,TimerText)
			
			//surface.DrawLine(XRES(320)-YRES(10)*(3.15-(Time()-LastGrenadeTime)),YRES(260),XRES(320)+YRES(10)*(3.15-(Time()-LastGrenadeTime)),YRES(260))
			
			return [C1[0]*Mod+C3[0]*(1-Mod),C1[1]*Mod+C3[1]*(1-Mod),C1[2]*Mod+C3[2]*(1-Mod)]
		}
		
		if ((Time()-WeaponJamTime)<1)
		{
			local Mod=clamp((0.33-(Time()-WeaponJamTime))*3,0,1)
			Mod=1-Mod
			
			local RX=YRES(RandomInt(-1,1))*(1-Mod)
			local RY=YRES(RandomInt(-1,1))*(1-Mod)
			
			surface.DrawColoredText(26,RX+XRES(320)-surface.GetTextWidth(26,"The weapon has jammed. You need to reload.")/2+2,RY+YRES(262)-2,0,0,0,255,"The weapon has jammed. You need to reload.")
			surface.DrawColoredText(26,RX+XRES(320)-surface.GetTextWidth(26,"The weapon has jammed. You need to reload.")/2,RY+YRES(262),C1[0]*Mod+C3[0]*(1-Mod),C1[1]*Mod+C3[1]*(1-Mod),C1[2]*Mod+C3[2]*(1-Mod),255,"The weapon has jammed. You need to reload.")
		}
		
		dif=RemapVal(dif,0,255,1,2)
		if (SW_HUDPlayerWeapon=="weapon_pistol") clip=RemapVal(clip,0.25,0.8,0.08,0.95);
		if (SW_HUDPlayerWeapon=="weapon_glock") clip=RemapVal(clip,0.2,0.85,0.08,0.95);
		if (SW_HUDPlayerWeapon=="weapon_colt") clip=RemapVal(clip,0.2,0.85,0.08,0.95);
		if (SW_HUDPlayerWeapon=="weapon_dual_pistol") clip=RemapVal(clip,0.25,0.8,0.11+0.01,0.95);
		if (SW_HUDPlayerWeapon=="weapon_dual_colt") clip=RemapVal(clip,0.25,0.8,0.11+0.01,0.95);
		if (SW_HUDPlayerWeapon=="weapon_dual_glock") clip=RemapVal(clip,0.2,0.85,0.12,0.95);
		if (player.GetActiveWeapon().GetClassname()=="weapon_rpg") return [0,175,255];
		//if (player.GetActiveWeapon().GetClassname()=="weapon_357") clip=RemapVal(clip,0.25,0.8,0.08,0.95);
		clip=RemapVal(clip,0.09,0.95,0,1)
		
		T1<-0.5
		
		if (clip<=T1)
		{
			return [RemapVal(1-clip,0,0.49,C2[0],C3[0]),RemapVal(1-clip,0,0.49,C2[1],C3[1]),RemapVal(1-clip,0,0.49,C2[2],C3[2])]
		}
		else return [RemapVal(1-clip,0.5,1,C1[0],C2[0]),RemapVal(1-clip,0.5,1,C1[1],C2[1]),RemapVal(1-clip,0.5,1,C1[2],C2[2])]
		
	}
	
	for (local i=0;i<20;i++)
	{
		surface.CreateFont( "Caption"+i,        // Name of this font entry (user-defined, can be anything)
		{
			"name"            : "Trebuchet MS"    // Name of the font file
			"tall"            : 10+i       // Size of the text
			"weight"        : 500        // Amount of boldness to add
			"antialias"     : true            // Enables font smoothing
			"dropshadow"     : true           // Adds a drop shadow to the font
			"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
		} );
	}
	
	surface.CreateFont( "BigNums",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Mensura 7"    // Name of the font file
        "tall"            : 50        // Size of the text
        "weight"        : 500        // Amount of boldness to add
        "antialias"     : true            // Enables font smoothing
        "dropshadow"     : true           // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );
	surface.CreateFont( "BigNumsS",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Mensura 7"    // Name of the font file
        "tall"            : 50        // Size of the text
        "weight"        : 500        // Amount of boldness to add
        "antialias"     : true            // Enables font smoothing
        "blur"            : 3        // Amount of blur to add (optional)
		"scanlines"	:	2
        "dropshadow"     : true           // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );
	
	surface.CreateFont( "A",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Mensura 7"    // Name of the font file
        "tall"            : 40        // Size of the text
        "weight"        : 500        // Amount of boldness to add
        "antialias"     : true            // Enables font smoothing
        "dropshadow"     : true           // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );
	surface.CreateFont( "Smol",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Mensura 7"    // Name of the font file
        "tall"            : 20        // Size of the text
        "weight"        : 500        // Amount of boldness to add
        //"blur"            : 1        // Amount of blur to add (optional)
        "antialias"     : true            // Enables font smoothing
        "dropshadow"     : true           // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );
	
	surface.CreateFont( "VerySmol",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Mensura 7"    // Name of the font file
        "tall"            : 10        // Size of the text
        "weight"        : 500        // Amount of boldness to add
        //"blur"            : 1        // Amount of blur to add (optional)
        "antialias"     : true            // Enables font smoothing
        "dropshadow"     : true           // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );
	
	surface.CreateFont( "Ass",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Mensura 7"    // Name of the font file
        "tall"            : 40        // Size of the text
        "weight"        : 500        // Amount of boldness to add
        "antialias"     : true            // Enables font smoothing
        "blur"            : 3        // Amount of blur to add (optional)
		"scanlines"	:	2
        "dropshadow"     : true           // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );
	surface.CreateFont( "Smolss",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Mensura 7"    // Name of the font file
        "tall"            : 20        // Size of the text
        "weight"        : 500        // Amount of boldness to add
        "blur"            : 3        // Amount of blur to add (optional)
		"scanlines"	:	2
        "antialias"     : true            // Enables font smoothing
        "dropshadow"     : true           // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );
	surface.CreateFont( "VerySmolShadow",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Mensura 7"    // Name of the font file
        "tall"            : 10        // Size of the text
        "weight"        : 500        // Amount of boldness to add
        "blur"            : 3        // Amount of blur to add (optional)
		"scanlines"	:	2
        "antialias"     : true            // Enables font smoothing
        "dropshadow"     : true           // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );
	
	surface.CreateFont( "SmolIcons",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "HalfLife2"    // Name of the font file
        "tall"            : 20        // Size of the text
        "weight"        : 500        // Amount of boldness to add
        "antialias"     : true            // Enables font smoothing
        "dropshadow"     : true           // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );
	
	surface.CreateFont( "WeaponSelector13",      
    {
        "name"            : "Verdana"  
        "tall"            : 12        
        "weight"        : 700       
        //"blur"            : 1                      
        "antialias"     : true
        "proportional"     : true        
    } );
	local SelectorFont=surface.GetFont("WeaponSelector13",true)
	surface.CreateFont( "WeaponSelectorGlow13",      
    {
        "name"            : "Verdana"  
        "tall"            : 12        
        "weight"        : 700       
        "blur"            : 2                      
        "antialias"     : true
        "proportional"     : true        
    } );
	local SelectorFontGlow=surface.GetFont("WeaponSelectorGlow13",true)
	surface.CreateFont( "WeaponSelectorSmall15",      
    {
        "name"            : "Verdana"  
        "tall"            : 8        
        "weight"        : 600      
        //"blur"            : 1                      
        "antialias"     : true
        "proportional"     : true        
    } );
	local SelectorFontSmall=surface.GetFont("WeaponSelectorSmall15",true)
	
	
	surface.CreateFont( "WeaponSelectorAmmo5",      
    {
        "name"            : "Mensura 7"  
        "tall"            : 12        
        "weight"        : 0       
        //"blur"            : 1                      
        "antialias"     : true
        "proportional"     : true        
    } );
	local SelectorAmmoFont=surface.GetFont("WeaponSelectorAmmo5",true)
	surface.CreateFont( "WeaponSelectorAmmoSmall5",      
    {
        "name"            : "Mensura 7"  
        "tall"            : 8       
        "weight"        : 0      
        //"blur"            : 1                      
        "antialias"     : true
        "proportional"     : true        
    } );
	local SelectorAmmoFontSmall=surface.GetFont("WeaponSelectorAmmoSmall5",true)
	
	surface.CreateFont( "RadioFont48",        // Name of this font entry (user-defined, can be anything)
	{
		"name"            : "Trebuchet MS"    // Name of the font file
		"tall"            : 10       // Size of the text
		"weight"        : 600        // Amount of boldness to add
		//"blur"            : 1        // Amount of blur to add (optional)
		"antialias"     : false           // Enables font smoothing
		"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
	} );
	
	surface.CreateFont( "SmallNotification11",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Verdana"    // Name of the font file
        "tall"            : 8      // Size of the text
        "weight"        : 2000        // Amount of boldness to add
        //"blur"            : 1        // Amount of blur to add (optional)
		"dropshadow"     : true            // Adds a drop shadow to the font
        "outline"     : true            // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );
	
	local SmallNotificationFont=surface.GetFont("SmallNotification11",true)
	
	surface.CreateFont( "BigNotification",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "MxPlus HP 150 re."    // Name of the font file
        "tall"            : 22      // Size of the text
        "weight"        : 2000        // Amount of boldness to add
        //"blur"            : 1        // Amount of blur to add (optional)
		"dropshadow"     : true            // Adds a drop shadow to the font
        "outline"     : true            // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
        "custom"     : true
    } );
	surface.CreateFont( "BigNotificationBlur",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "MxPlus HP 150 re."    // Name of the font file
        "tall"            : 22      // Size of the text
        "weight"        : 2000        // Amount of boldness to add
        "blur"            : 1        // Amount of blur to add (optional)
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
		"custom"     : true
    } );
	
	local BigNotificationFont=surface.GetFont("BigNotification",true)
	local BigNotificationBlurFont=surface.GetFont("BigNotificationBlur",true)
	
	surface.CreateFont( "BigNotificationAlt2",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Mensura 7"    // Name of the font file
        "tall"            : 25      // Size of the text
        "weight"        : 2000        // Amount of boldness to add
        //"blur"            : 1        // Amount of blur to add (optional)
		"dropshadow"     : true            // Adds a drop shadow to the font
        "antialias"     : true
        "outline"     : true            // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
        "custom"     : true
    } );
	surface.CreateFont( "BigNotificationAltBlur2",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Mensura 7"    // Name of the font file
        "tall"            : 25      // Size of the text
        "weight"        : 2000        // Amount of boldness to add
        "antialias"     : true
        "blur"            : 1        // Amount of blur to add (optional)
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
		"custom"     : true
    } );
	
	local BigNotificationAltFont=surface.GetFont("BigNotificationAlt2",true)
	local BigNotificationAltBlurFont=surface.GetFont("BigNotificationAltBlur2",true)
	
	surface.CreateFont( "GameOver2",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Pelkistettya todellisuutta"    // Name of the font file
        "tall"            : 35      // Size of the text
        "weight"        : 200        // Amount of boldness to add
        //"blur"            : 1        // Amount of blur to add (optional)
		"dropshadow"     : true            // Adds a drop shadow to the font
        "antialias"     : true
        "outline"     : true            // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
        "custom"     : true
    } );
	surface.CreateFont( "GameOverBold2",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Pelkistettya todellisuutta"    // Name of the font file
        "tall"            : 38      // Size of the text
        "weight"        : 2000        // Amount of boldness to add
        //"blur"            : 1        // Amount of blur to add (optional)
		"dropshadow"     : true            // Adds a drop shadow to the font
        "antialias"     : true
        "outline"     : true            // Adds a drop shadow to the font
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
        "custom"     : true
    } );
	surface.CreateFont( "GameOverBig3",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Pelkistettya todellisuutta"    // Name of the font file
        "tall"            : 55      // Size of the text
        "weight"        : 2000        // Amount of boldness to add
        "antialias"     : true
        "proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
		"custom"     : true
    } );
	
	local GameOverFont=surface.GetFont("GameOver2",true)
	local GameOverBigFont=surface.GetFont("GameOverBig3",true)
	local GameOverBoldFont=surface.GetFont("GameOverBold2",true)
	
	
	
	LastShoot<-Time()
	LastAmmo<-30
	LastAmmoMax<-30
	
	local LastMoney=::PlayerMoney
	::LastMoneyChange<-Time()
	local LastHeat=::PlayerHeat
	
	local PlayerDeathTime=-10;
	local PlayerFadeTime=-10;
	RNGs<-[]
	
	local olddedtext=""
	local DeathSoundPlayed=false
	local DeathSound2Played=false
	local DeathSound3Played=false
	local DeathMusicPlayed=false
	
	local lastpos=Vector(0,0,0)
	local lastcc=""
	
	
	
	local BossHP=1.0
	local PrevBossHP=1.0
	local BossLastDmg=0
	
	NetMsg.Receive("BossHP",function(...) {
		local NewBossHP=NetMsg.ReadFloat()
		if (NewBossHP<BossHP) BossLastDmg=Time();
		
		BossHP=NewBossHP
	}.bindenv(this))
	
	NetMsg.Receive("SWCaption",function(...) {
		local text=NetMsg.ReadString()
		local actor=NetMsg.ReadString()
		foreach (i,c in SW_CAPTIONS)
		{
			if (c[1]==actor){
				SW_CAPTIONS.remove(i)
				//SW_CAPTIONS.append([text,actor,Time()])
				continue
			}
		//	if (c[1]==actor) return
		}
		SW_CAPTIONS.append([text,actor,Time()])
	}.bindenv(this))
	
	::HintText<-""
	::HintTime<-(-10)
	WeaponJamTime<-(-10);
	
	
	//consist of [time,text]
	::SmallNotifications<-[]
	::BigNotifications<-[]
	
	CompanionDowned<-[]
	
	
	NetMsg.Receive("SWHint",function(...) {
		HintText=NetMsg.ReadString()
		HintTime=Time()
	}.bindenv(this))
	
	NetMsg.Receive("WeaponJam",function(...) {
		WeaponJamTime=Time()
	}.bindenv(this))
	
	NetMsg.Receive("SWSmallNotification",function(...) {
		SmallNotifications.append( [Time(), NetMsg.ReadString(), Vector(NetMsg.ReadByte(),NetMsg.ReadByte(),NetMsg.ReadByte())] )
	}.bindenv(this))
	
	NetMsg.Receive("SWBigNotification",function(...) {
		BigNotifications.append( [Time(), NetMsg.ReadString(), Vector(NetMsg.ReadByte(),NetMsg.ReadByte(),NetMsg.ReadByte()),NetMsg.ReadFloat(),NetMsg.ReadFloat()] )
	}.bindenv(this))
	
	NetMsg.Receive("CompanionDowned",function(...) {
		CompanionDowned.append( [Time(), NetMsg.ReadString(), NetMsg.ReadVec3Coord()] )
	}.bindenv(this))
	
	NetMsg.Receive("CompanionRevived",function(...) {
		local name=NetMsg.ReadString()
		local pos=NetMsg.ReadVec3Coord()
		
		if (CompanionDowned[0][1]==name)
		{
			CompanionDowned.remove(0)
			return
		}
		if (CompanionDowned[1][1]==name)
		{
			CompanionDowned.remove(1)
			return
		}
	}.bindenv(this))
	
	local RadioPrevText=""
	
	local RadioTime=(-10)
	local RadioID=null	// id points to a predefined radio message
	local RadioStarted=false;	// this bool used mostly for sound.
	local RadioContinue=false;	// used to determine whether we start the radio message or continue from previous one.
	
	NetMsg.Receive("SWRadio",function(...) {
		RadioID=NetMsg.ReadShort()
		RadioContinue=NetMsg.ReadBool()
		RadioTime=Time()
		RadioStarted=false
	}.bindenv(this))
	
	local cubes=[]
	::HeartBeat<-Time()
	
	
	function cross(a, b) {
		return a[0]*b[1] - a[1]*b[0];
	}

	function orient(a, b, c) {
		return cross([b[0]-a[0],b[1]-a[1]], [c[0]-a[0],c[1]-a[1]]);
	}

	function LineInter(a, b, c, d) {
		local oa = orient(c,d,a); 
		local ob = orient(c,d,b);            
		local oc = orient(a,b,c);            
		local od = orient(a,b,d);      
		// Proper intersection exists if opposite signs  
		return ((oa*ob < 0) && (oc*od < 0));
	}
	function DotDistance(a,b)
	{
		return sqrt( (a[0]-b[0])*(a[0]-b[0]) + (a[1]-b[1])*(a[1]-b[1]) )
	}
	function SqrDotDistance(a,b)
	{
		return (a[0]-b[0])*(a[0]-b[0]) + (a[1]-b[1])*(a[1]-b[1])
	}
	
	::Points<-[]
	local NumPoints=50;
	
	Points.append([320,240])
	
	::Lines<-[]
	local LinesBad=[]
	local Exclusions=array(NumPoints)
	local LinesReady=false
	
	local blackness=surface.ValidateTexture("console/background_widescreen",true,false,false)
	local pov=surface.ValidateTexture("player_pov",true,false,false)
	
	function MakePoints()
	{
		
		if (Points.len()>=NumPoints) LinesReady=true;
		if (Points.len()>=NumPoints) return;
		LinesReady=false
		local PointFailed=false
		local id=SWRandInt(0,Points.len()-1)
		while (Exclusions[id]&&Exclusions[id]>4) id=SWRandInt(0,Points.len()-1);
		local p=Points[SWRandInt(0,Points.len()-1)]
		local Angles=SWRandInt(0,359)
		local Radius=SWRandInt(20,40)
		
		local NewPoint = [p[0]+cos(Angles*DEG2RAD)*Radius,p[1]+sin(Angles*DEG2RAD)*Radius] 
		for (local i=0;i<Points.len();i++)
		{
			local DistX=Points[i][0]-NewPoint[0]
			local DistY=Points[i][1]-NewPoint[1]
			if ( ( DistX*DistX + DistY*DistY  ) < 20 || NewPoint[0]<0 || NewPoint[0]>640 || NewPoint[1]<0 || NewPoint[1]>480 )
			{
				PointFailed=true;
				break
			}
		}
		foreach (Line in Lines)
		{
			if (PointFailed) break;
			if (DotDistance(Line[0],NewPoint)>40) continue;
			if (DotDistance(Line[1],NewPoint)>40) continue;
			
			local Dist=DotDistance(Line[1],Line[0])
			local Dist1=DotDistance(NewPoint,Line[0])
			local Dist2=DotDistance(NewPoint,Line[1])
			if (Dist+Dist*RemapVal(DotDistance(Points[0],NewPoint),1,40,0.2,1)>(Dist1+Dist2))
			{
				PointFailed=true
				//ConnectBed=true
				break
			}
		}
		if (!PointFailed) 
		{
			Points.append(NewPoint);
			if (Exclusions[id]==null) Exclusions[id]=0;
			Exclusions[id]++
			return;
		}
		else MakePoints();
		
	}
	
	/*
	local c = [0,0]
	foreach (p in Points) {
		c[0]+=p[0];
		c[1]+=p[1];
	}

	c[0]/=Points.len();
	c[1]/=Points.len();
	
	Points.sort(function(p1, p2) {
		local dx1 = p1[0]-c[0];
		local dy1 = p1[1]-c[1];
		local a1 = atan2(dy1, dx1);

		local dx2 = p2[0]-c[0];
		local dy2 = p2[1]-c[1];
		local a2 = atan2(dy2, dx2);

		//If angles are the same, sort by length
		if (a1==a2){
			local d1 = dx1*dx1 + dy1*dy1;
			local d2 = dx2*dx2 + dy2*dy2;

			if (d1>d2) return -1;
			if (d1<d2) return 1;
			else return 0;
		}

		//otherwise sort by angle
		if (a1>a2) return -1;
		if (a1<a2) return 1;
		else return 0;
	})*/
	
	function CalculateLines()
	{
		//printl(Points.len())
		if (Points.len()<2) return;
		if (LinesReady) return;
		local ConnectFailed=true
		local i=Points.len()-1
		foreach (i2,p in Points)
		{
			//if (DotDistance(Points[0],Points[i])>250) continue;
			//if (DotDistance(Points[0],Points[i2])>250) continue;
			if (i2>i) continue;
			if (i2==i) continue;
			//if (i2<i-3) continue;
			
			local Connect=true
			local ConnectBed=false
			local Dist=DotDistance(p,Points[i])
			if (Dist<=40+RemapVal(DotDistance(Points[0],Points[i2]),1,650,0,40))
			{
				foreach (Line in Lines)
				{
					if (DotDistance(Line[0],Points[i])>40&&DotDistance(Line[1],Points[i])>40) continue;
					if (DotDistance(Line[0],Points[i2])>40&&DotDistance(Line[1],Points[i2])>40) continue;
					if (LineInter(Line[0], Line[1], Points[i], Points[i2]))
					{
						Connect=false
						break
					}
				}
				foreach (i3,Po in Points)
				{
					if (!Connect) break;
					if (i3==i2||i3==i) continue;
					if (DotDistance(Po,p)>40) continue;
					
					local Dist1=DotDistance(Po,p)
					local Dist2=DotDistance(Po,Points[i])
					if (Dist+Dist*RemapVal(DotDistance(Points[0],Po),1,320,0.2,1)>(Dist1+Dist2))
					{
						Connect=false
						//ConnectBed=true
						break
					}
				}
				foreach (Line in Lines)
				{
					if (Line[0]==Points[i]&&Line[1]==Points[i2]||Line[1]==Points[i]&&Line[0]==Points[i2])
					{
						Connect=false
						break
					}
				}
				if (Connect==true) {Lines.append([Points[i], Points[i2]]);ConnectFailed=false;}
				
			}
		}
		if (ConnectFailed) Points.remove(i);
	}
	
	Convars.RegisterCommand( "reset_multiverse", function(...)
	{
		Points=[[320,240]]
		Lines=[]
		LinesBad=[]
		Exclusions=array(NumPoints)
		LinesReady=false
	}.bindenv(this), "ey", FCVAR_NONE );
	
	local Glowies={}
	local HEART=0;
	
	local LastScopeSpeed=0;
	
	function Paint()
	{
		if (RNGs.len()<1) RNGs.append(0);
		if (RNGs.len()<2000) for (local i=1;i<1280;i++)
		{
			RNGs.append(clamp(fabs(RNGs[i-1]+RandomFloat(-0.01,0.01)),0,0.08))
		}
		if (RNGs.len()<2000) for (local i=0;i<2280;i++)
		{
			RNGs.append(-RandomFloat(-0.5,0)*RandomFloat(-0.5,0))
		}
		local Timevar=clamp(Time()/4.0-0.25,0,1)
		
		local Scale=(1 - pow(1 - Timevar, 4))*3.6
		
		
		if (!player) return;
		local GlowSprite=surface.ValidateTexture("vgui/glow",true,false,false)
		for (local i=0;i<Points.len();i++)
		{
			break
			surface.SetColor(255,255,255,255*RemapVal(DotDistance(Points[0],Points[i]),0,1000,1,0))
			if (i==0) surface.SetColor(25,255,25,255);

			surface.SetTexture(GlowSprite)
			surface.DrawTexturedRectRotated(Points[i][0]-20,Points[i][1]-20,40,40,Time()*14+Points[i][0]%30+Points[i][1]%30)
			
			
		}
		//printl(Lines.len())
		foreach (Line in Lines)
		{
			break
			surface.SetColor(255,255,255,155*RemapVal(DotDistance(Points[0],Line[0]),0,1100,1,0))
			if (Line[0]==Points[0]||Line[1]==Points[0]) surface.SetColor(25,255,25,255);
			surface.DrawLine(Line[0][0], Line[0][1], Line[1][0], Line[1][1])
		}
		if (Entities.FindByName(null,"SW_RT")&&InvP)
		{
			local rtpos=Entities.FindByName(null,"SW_RT").GetOrigin()+Vector(7,0,6)
			
			effects.DynamicLight(0,rtpos,25,25,25,10,9,2,0,0,1)
		}
		//ViewmodelThink()
		if (player.GetHealth()<=0) 
		{
			SniperScopeActive=false
			
			if (InvP&&InvP.IsValid())
			{
				OpenInventory()
			}
		
			if (!DeathMusicPlayed&&(PlayerDeathTime+0.2)<Time())
			{
				//surface.PlaySound("ui/theend.wav")
				player.EmitSound("#*music/deaththeme.mp3")
				DeathMusicPlayed=true
			}
			if (PlayerDeathTime<0) 
			{
				PlayerDeathTime=Time();
				if (RNGs.len()<2000) for (local i=0;i<640;i++)
				{
					RNGs.append(-RandomFloat(-0.5,0)*RandomFloat(-0.5,0))
				}
			}
			if ((Time()-PlayerDeathTime)>2.5&&!DeathSound2Played) {
				//surface.PlaySound("ambient/atmosphere/cave_hit"+RandomInt(1,6)+".wav")
				DeathSound2Played=true
			}
			local Scale=clamp((Time()-PlayerDeathTime)/2,0,8)
			if (Scale<3.5) for (local i=0;i<641;i++)
			{
				surface.SetColor(85-clamp(Scale*400,0,85),0,0,255)
				//surface.DrawFilledRect(XRES(i),0,XRES(2),YRES(480)*(pow(Scale/1.3,1+RNGs[i+1600]/7.0-RNGs[i+320]/15.0)-1.5-(RNGs[i]))-YRES(240)+YRES(1)*fabs(320-i))
				//surface.DrawFilledRect(XRES(i),YRES(480)-YRES(480)*(pow(Scale/1.3,1+RNGs[i+1280]/7.0-RNGs[i+320]/15.0)-1.5-(RNGs[i]))+YRES(240)-YRES(1)*fabs(320-i),XRES(2),YRES(480)*8)
				local h2=YRES(480)*(pow(Scale*0.8,1+RNGs[i+640+1600]/13.0-RNGs[i+320+1600]/15.0)-1.5-(RNGs[i+1600]))-YRES(240)+YRES(1)*fabs(320-i)
				h2=clamp(h2,0,YRES(240))
				surface.DrawFilledRect(XRES(i-1),0,XRES(2),h2)
				local r=YRES(RandomInt(0,10)+clamp(Scale*20,0,255))+YRES(1)*fabs(320-i)
				surface.DrawFilledRectFade(XRES(i-1),h2,XRES(2),r,clamp(Scale*300,0,255),0,false)
				local h=YRES(480)-YRES(480)*(pow(Scale*0.8,1+RNGs[i+640+1600]/13.0-RNGs[i+320+1600]/15.0)-1.5-(RNGs[i+1600]))+YRES(240)-YRES(1)*fabs(320-i)
				h=clamp(h,YRES(240),YRES(480))
				surface.DrawFilledRect(XRES(i-1),h,XRES(2),YRES(480)-h+2)
				
				surface.DrawFilledRectFade(XRES(i-1),h-r,XRES(2),r,0,clamp(Scale*300,0,255),false)

			}
			else
			{
				surface.SetColor(0,0,0,255)
				surface.DrawFilledRect(0,0,XRES(640),YRES(480))
			}
			
			// LOCALIZATION NOTE: Making writings with foreign language is very complicated due to way their strings work. here are snippets to use later for making localization support.
			/*
			foreach (i,c in gamover)
			{
				if (c==(-48)||c==(-47)) gamover=gamover.slice(0,i)+gamover.slice(i+1,gamover.len())
			}
			DeadTextFull.slice(0,i+1*(DeadTextFull[i-1]==(-48)||DeadTextFull[i-1]==(-47)).tointeger())
			*/
			
			local GameOverText=Localize.GetTokenAsUTF8("SW_GAMEOVER")
			
			local DeadTextFull=GameOverText+" "
			local dedtext=""
			for (local i=1;i<LLen(DeadTextFull);i+=1)
			{
				local ei=i
				if (LSlice(DeadTextFull,0,i).find(" ")!=null) ei--;
				if (Scale-3.1>ei*0.07-pow(0.02*i,2)-0.1&&(LSlice(DeadTextFull,i-1,i)!=" ")) dedtext=LSlice(DeadTextFull,0,i)
			}
			if (olddedtext!=dedtext) surface.PlaySound("ui/menu_focus_creepy.wav")
				
			olddedtext=dedtext
			if (GameOverText==olddedtext&&!DeathSoundPlayed) {
				surface.PlaySound("ambient/intro/endscreenhits.wav")
				DeathSoundPlayed=true
			}
			if ((Time()-PlayerDeathTime)>8&&!DeathSound3Played) {
				surface.PlaySound("#*music/limbo.mp3")
				if (RandomInt(1,4)==1) surface.PlaySound("ambience/ambience7_twow.wav");
				DeathSound3Played=true
			}
			if (Scale>3.1)
			{
				for (local i=0;i<LLen(dedtext);i++)
				{
					local rndmv=clamp(0.2-(Scale-3.1-i*0.07-pow(0.02*i,2)),0,100)*40
					
					//RED TEXT
					surface.DrawColoredText(GameOverBigFont,XRES(320)-surface.GetTextWidth(GameOverBigFont,DeadTextFull)/2+RandomInt(-rndmv/3.0,rndmv/3.0),YRES(240)+RandomInt(-rndmv*2,rndmv*2)-surface.GetFontTall(GameOverBigFont)/4,105,0,0,rndmv/2+rndmv*18*DeathSoundPlayed.tointeger(),dedtext);
					
					//WHITE TEXT
					surface.DrawColoredText(DeathSoundPlayed ? GameOverBoldFont : GameOverFont,XRES(320)-surface.GetTextWidth(DeathSoundPlayed ? GameOverBoldFont : GameOverFont,DeadTextFull)/2-(i>(LLen(GameOverText))).tointeger()*20+RandomInt(-rndmv,rndmv),YRES(240)-20+RandomInt(-rndmv,rndmv),255,255-DeathSoundPlayed.tointeger()*22,255-DeathSoundPlayed.tointeger()*22,255-clamp(Scale*120/2-60,0,255),dedtext);
					//surface.DrawColoredText(41,XRES(320)-DeadTextFull.len()*10+i*20+RandomInt(-rndmv,rndmv),YRES(240)-20+RandomInt(-rndmv,rndmv),255,255,255,255,dedtext.slice(i,i+1));
			
				}
			}
			
			return;
		}
		
		NetMsg.Receive("SendCC",function(...) {
		lastcc=NetMsg.ReadString()
		lastpos=NetMsg.ReadVec3Coord()
		}.bindenv(this))
		
		if (SniperScopeActive)
		{
			//printl((PrevMainViewOrigin()-MainViewOrigin()).Length()/FrameTime())
			
			local speed=(PrevMainViewOrigin()-MainViewOrigin()).Length()/FrameTime()
			speed=clamp(speed,0,200)
			
			if (LastScopeSpeed<speed) LastScopeSpeed=min(LastScopeSpeed+5000*FrameTime(),speed)
			if (LastScopeSpeed>speed) LastScopeSpeed=max(LastScopeSpeed-220*FrameTime(),speed)
			
			local offsetx=YRES(sin(Time()*2)*LastScopeSpeed*0.07)
			local offsety=YRES(-cos(Time()*4)*LastScopeSpeed*0.07)
			
			offsety+=YRES(pow(clamp(0.25-Time()+LastScopeTime,0,0.25),2)*400)
			offsetx+=YRES(pow(clamp(0.25-Time()+LastScopeTime,0,0.25),2)*200)
			
			
			surface.SetColor(255,255,255,255)
			
			surface.SetTexture(surface.ValidateTexture("sprites/scope_arc",true,false,false))
			
			surface.DrawTexturedSubRect(ScreenWidth()/2-ScreenHeight()/2+offsetx,YRES(-4)+offsety,ScreenWidth()/2+offsetx,ScreenHeight()/2+offsety,0,0,-1,-1)
			surface.DrawTexturedSubRect(ScreenWidth()/2+offsetx,YRES(-4)+offsety,ScreenWidth()/2+ScreenHeight()/2+offsetx,ScreenHeight()/2+offsety,0,0,1,-1)
			
			surface.DrawTexturedSubRect(ScreenWidth()/2-ScreenHeight()/2+offsetx,ScreenHeight()/2+offsety,ScreenWidth()/2+offsetx,ScreenHeight()+offsety,0,0,-1,1)
			surface.DrawTexturedSubRect(ScreenWidth()/2+offsetx,ScreenHeight()/2+offsety,ScreenWidth()/2+ScreenHeight()/2+offsetx,ScreenHeight()+offsety,0,0,1,1)
			
			surface.SetColor(0,0,0,255)
			
			surface.DrawLine(offsetx,YRES(240)+offsety,XRES(640)+offsetx,YRES(240)+offsety)
			surface.DrawLine(offsetx,YRES(240)+1+offsety,XRES(640)+offsetx,YRES(240)+1+offsety)
			surface.DrawLine(offsetx,YRES(240)-1+offsety,XRES(640)+offsetx,YRES(240)-1+offsety)
			
			
			surface.DrawLine(XRES(320)+offsetx,offsety,XRES(320)+offsetx,YRES(480)+offsety)
			surface.DrawLine(XRES(320)+1+offsetx,offsety,XRES(320)+1+offsetx,YRES(480)+offsety)
			surface.DrawLine(XRES(320)-1+offsetx,offsety,XRES(320)-1+offsetx,YRES(480)+offsety)
			
			surface.SetColor(255,255,255,255)
			if (aPlayer.Weapon&&aPlayer.Weapon.Name=="weapon_awp") surface.SetTexture(surface.ValidateTexture("sprites/scope_arc2_awp",true,false,false))
			else surface.SetTexture(surface.ValidateTexture("sprites/scope_arc2",true,false,false))
		
			if (aPlayer.Weapon&&aPlayer.Weapon.Name=="weapon_awp")
			{
				surface.SetColor(255,255,255,255)
				surface.DrawTexturedSubRect(ScreenWidth()/2-ScreenHeight()/2+offsetx,YRES(-4)+offsety,ScreenWidth()/2+ScreenHeight()/2+offsetx,ScreenHeight()+offsety,0,0,1,1);
			}
			else
			{
				surface.DrawTexturedSubRect(ScreenWidth()/2-ScreenHeight()/2+offsetx,YRES(-4)+offsety,ScreenWidth()/2+offsetx,ScreenHeight()/2+offsety,0,0,-1,-1)
				surface.DrawTexturedSubRect(ScreenWidth()/2+offsetx,YRES(-4)+offsety,ScreenWidth()/2+ScreenHeight()/2+offsetx,ScreenHeight()/2+offsety,0,0,1,-1)
				
				surface.DrawTexturedSubRect(ScreenWidth()/2-ScreenHeight()/2+offsetx-YRES(2),ScreenHeight()/2+offsety-YRES(2),ScreenWidth()/2+offsetx,ScreenHeight()+offsety,0,0,-1,1)
				surface.DrawTexturedSubRect(ScreenWidth()/2+offsetx,ScreenHeight()/2+offsety,ScreenWidth()/2+ScreenHeight()/2+offsetx,ScreenHeight()+offsety,0,0,1,1)
			}
			
			surface.SetColor(0,0,0,255)
			surface.DrawFilledRect(-YRES(500),0,ScreenWidth()/2-ScreenHeight()/2+YRES(4)+offsetx+YRES(500),ScreenHeight())
			surface.DrawFilledRect(ScreenWidth()/2+ScreenHeight()/2-YRES(6)+offsetx,offsety-YRES(500),ScreenWidth()/2,ScreenHeight()+YRES(500)*2)
			
			surface.DrawFilledRect(offsetx,ScreenHeight()+offsety,ScreenWidth(),YRES(500))
			surface.DrawFilledRect(offsetx,offsety-YRES(500),ScreenWidth(),YRES(500))
			
		}
		
		
		local PlayerHP=player.GetHealth()*1.0/PlayerMaxHealth/0.3
		
		if (Time()-LastWoundTime<1)
		{
			surface.SetTexture(LowHP)
			surface.SetColor(255,255,255, clamp(255-(Time()-LastWoundTime)*330,0,75))
			surface.DrawTexturedSubRect(0,0,ScreenWidth(),ScreenHeight(),0,0,1,1)
			surface.SetTexture(LowHP2)
			surface.DrawTexturedSubRect(0,0,ScreenWidth(),ScreenHeight(),0,0,1,1)
			//printl(PreviousHealth-player.GetHealth())
		}
		
		if (PlayerStamina<10&&(Time()-HeartBeat)>(0.6+(PlayerStamina)*0.02)) 
		{
			if (PlayerStamina>5) surface.PlaySound("player/heartbeatloop3.wav");
			else surface.PlaySound("player/heartbeatloop2.wav");
			HeartBeat=Time()
			//printl("HeartBeat!")
		}
		
		if (player.GetHealth()<30)
		{
			surface.SetTexture(LowHP)
			surface.SetColor(255,255,255, (1-PlayerHP)*fabs(sin(Time()*2))*20+50*(1-PlayerHP))
			local MoveMod=(sin(Time())+1)*YRES(5)+(PlayerHP*YRES(60))
			surface.DrawTexturedSubRect(0-MoveMod,0-MoveMod,ScreenWidth()+MoveMod,ScreenHeight()+MoveMod,0,0,1,1)
			surface.SetTexture(LowHP2)
			surface.DrawTexturedSubRect(0-MoveMod,0-MoveMod,ScreenWidth()+MoveMod,ScreenHeight()+MoveMod,0,0,1,1)
			//printl(PreviousHealth-player.GetHealth())
			
			if ((Time()-HeartBeat)>(0.6+player.GetHealth()*0.02-0.6/clamp(Time()-LastHurtTime,2,10))) 
			{
				if (player.GetHealth()>25) surface.PlaySound("player/heartbeatloop3.wav");
				else if (player.GetHealth()>15) surface.PlaySound("player/heartbeatloop3.wav");
				else if (player.GetHealth()>10) surface.PlaySound("player/heartbeatloop2.wav");
				else surface.PlaySound("player/heartbeatloop.wav");
				HeartBeat=Time()
				//printl("HeartBeat!")
			}
			
			surface.SetColor(45-30*(PlayerHP), 8, 8, 85*(1-PlayerHP)+10*pow(HEART,0.25))
			surface.DrawFilledRectFade(0,0,ScreenWidth(),ScreenHeight()/2,255,0,false)
			surface.DrawFilledRectFade(0,ScreenHeight()/2,ScreenWidth(),ScreenHeight()/2,0,255,false)
			surface.DrawFilledRectFade(0,0,ScreenWidth()/2,ScreenHeight(),255,0,true)
			surface.DrawFilledRectFade(ScreenWidth()/2,0,ScreenWidth()/2,ScreenHeight(),0,255,true)
		}
		
		if (Time()-LastHealTime<1)
		{
			local mod=clamp(pow(1-(Time()-LastHealTime),2),0.3,1)
			surface.SetColor(0,155,0,255*pow(mod-0.3,2))
			surface.DrawFilledRectFade(0,ScreenHeight()*(1-mod/4),ScreenWidth(),ScreenHeight()*mod/4,0,clamp(255*mod,0,255),false)
		}
		
		if (RageActive)
		{
			if ((Time()-HeartBeat)>0.44&&(Time()-RageStartTime)>1) HeartBeat=Time()
				
			if ((Time()-RageStartTime)>15) RageActive=false;
			
			local mod=clamp(Time()-RageStartTime-1,0,1)
			if ((Time()-RageStartTime)>14)
				mod=1-clamp(Time()-RageStartTime-14.5,0,1);
			if ((Time()-RageStartTime)>14.75)
				mod=1-clamp((Time()-RageStartTime-14.75)*4,0,1);
			
			local modpulse=clamp((Time()-RageStartTime-1)*3,0,1)-clamp((Time()-RageStartTime-2)*3,0,1)
			
			printl(HEART)
			

			
			surface.SetColor(255,175-50*HEART,75-20*HEART,30*RandomFloat(2.2,2.5)*mod+(80*modpulse).tointeger())
			surface.SetTexture(surface.ValidateTexture("player_pov",true,false,false))
			local Xtra=YRES(RandomInt(0,10))*mod
			surface.DrawTexturedRect(Xtra*sin(RandomFloat(0,10))-Xtra,Xtra*cos(RandomFloat(0,10))-Xtra,XRES(640)+2*Xtra,YRES(480)+2*Xtra)
			surface.DrawTexturedRect(Xtra*sin(RandomFloat(0,10))-Xtra,Xtra*cos(RandomFloat(0,10))-Xtra,XRES(640)+2*Xtra,YRES(480)+2*Xtra)
			
			surface.SetColor(255,155-15*HEART,55-6*HEART,155*mod+(80*modpulse).tointeger())
			surface.SetTexture(surface.ValidateTexture("effects/advisoreffect/advisorblast1",true,false,false))
			
			
			Xtra=YRES(150)
			surface.DrawTexturedRect(-Xtra,-Xtra,XRES(640)+2*Xtra,YRES(480)+2*Xtra)
			
		}
		
		DrawScreenOverlays()
		
		/*
		local tests=array(100)
		for (local i=0;i<100;i++) tests[i]=0;
		
		for (local i=1;i<=10000;i++)
		{
			local rng=abs((RandomInt(1,33)+RandomInt(1,33)+RandomInt(1,34)))+sin(Time())*50
			if (rng!=clamp(rng,1,100)) continue
			tests[rng-1]=tests[rng-1]+0.5
		}
		for (local i=0;i<100;i++)
		{
			surface.SetColor(255,255,255,255)
			local height=tests[i]
			surface.DrawFilledRect(XRES(200+i),YRES(200+(100-height)),XRES(1),YRES(height))
		}
		*/
		
		/*
		local size=YRES(10)
		for (local i=0;i<cubes.len();i++)
		{
			local x=YRES(cubes[i][0])
			local y=YRES(cubes[i][1])
			surface.SetColor(0,0,0,255)
			surface.DrawFilledRect(x,y,size/2,size/2)
			surface.DrawFilledRect(x+size/2,y+size/2,size/2,size/2)
			surface.SetColor(255,0,255,255)
			surface.DrawFilledRect(x,y+size/2,size/2,size/2)
			surface.DrawFilledRect(x+size/2,y,size/2,size/2)
		}
		while (Time()*930-300>cubes.len()&&cubes.len()<(120*73+1))
		{
			local side=RandomInt(0,1)==1
			local x=0
			local y=0
			if (side)
			{
				x=(RandomInt(0,88)/5+RandomInt(0,88)/5+RandomInt(0,88)/5+RandomInt(0,88)/5+RandomInt(0,88)/5+40)*10
				y=RandomInt(0,48)*10
			}
			else
			{
				x=RandomInt(0,88)*10
				y=(RandomInt(0,48)/5+RandomInt(0,48)/5+RandomInt(0,48)/5+RandomInt(0,48)/5+RandomInt(0,48)/5+24)*10
			}
			
			
			
			if (x>880) x=x-880;
			if (y>488) y=y-488;
			while (cubes.find([x,y]))
			{
				if (side)
				{
					x=(RandomInt(0,88)/5+RandomInt(0,88)/5+RandomInt(0,88)/5+RandomInt(0,88)/5+RandomInt(0,88)/5+40)*10
					y=RandomInt(0,48)*10
				}
				else
				{
					x=RandomInt(0,88)*10
					y=(RandomInt(0,48)/5+RandomInt(0,48)/5+RandomInt(0,48)/5+RandomInt(0,48)/5+RandomInt(0,48)/5+24)*10
				}
			}
			if (x>880) x=x-880;
			if (y>480) y=y-480;
			cubes.append([x,y])
		}
		*/
		
		foreach (i,caption in SW_CAPTIONS)
		{
			
			if ((caption[2]+LLen(caption[0])/10.0+2)<Time()) {SW_CAPTIONS.remove(i); continue}
			if ((SW_AMBIENT.find("combat")!=null)&&(caption[2]+LLen(caption[0])/10.0)<Time()) {SW_CAPTIONS.remove(i); continue}
			if (!("IsValid" in Entities.FindByName(null,caption[1]))) continue;
			
			local guy=WorldPosToScreen(Entities.FindByName(null,caption[1]).EyePosition()+Vector(0,0,2))
			local Dist=(Entities.FindByName(null,caption[1]).EyePosition()-player.EyePosition()).Length()/32.0
			Dist=20-clamp(Dist,1,20).tointeger()
			
			local captionfont=surface.GetFont( "Caption"+Dist, true )
			local text=caption[0]
			text=LSlice(text,0,clamp((40*(Time()-caption[2])).tointeger(),0,LLen(text)))
			if (guy.z<1) surface.DrawColoredText(captionfont,guy.x*ScreenWidth()-surface.GetTextWidth(captionfont,caption[0])/2,guy.y*ScreenHeight()-surface.GetFontTall(captionfont),2,2,2,225,caption[0]);
			if (guy.z<1) surface.DrawColoredText(captionfont,guy.x*ScreenWidth()-surface.GetTextWidth(captionfont,caption[0])/2,guy.y*ScreenHeight()-surface.GetFontTall(captionfont),2,2,2,255,text);
			if (guy.z<1) surface.DrawColoredText(captionfont,guy.x*ScreenWidth()-surface.GetTextWidth(captionfont,caption[0])/2-2,guy.y*ScreenHeight()-surface.GetFontTall(captionfont),222,222,222,255,text);
		}
		
		foreach (cross in CompanionDowned)
		{
			if (!cross) continue;
			
			if ((cross[2]-player.GetOrigin()).Length()<64) continue
			
			local pos=WorldPosToScreen(cross[2])
			
			if (pos.z>1) continue;
			
			//printl(pos.z)
			
			local size=YRES(40+5*cos(Time()))
			surface.SetTexture(surface.ValidateTexture("particle/particle_heal_cross_1",true,false,false))
			
			local BlinkMod=1
			if ((Time().tointeger()%2)==0&&((Time()-0.5)<Time().tointeger()))
				BlinkMod=cos(((Time()-Time().tointeger())*4)*PI)
			
			if ((Time()-cross[0])<2)
				surface.SetColor(255,30,30,255*((Time()*10).tointeger()%2))
			else
				surface.SetColor(255,30,30,55+200*BlinkMod)
			
			surface.DrawTexturedRect(pos.x*ScreenWidth()-size/2,pos.y*ScreenHeight()-size/2,size,size)
			
		}
		
		
		local SmallNotificationGap=0
		foreach(i,Notification in SmallNotifications)
		{
			local notetime=Notification[0]
			local notetext=Notification[1]
			local notecolor=Vector(Notification[2].x,Notification[2].y,Notification[2].z)
			
			local FadeTime=1.0
			local PopupTime=0.15
			local Duration=3.5+FadeTime
			local TimeLeft=Duration-(Time()-notetime)
			
			local alpha=clamp(notetime+PopupTime-Time(),0,PopupTime)/PopupTime*255
			alpha=255-alpha
			
			local y=YRES(420)-YRES(5)*(clamp(notetime+PopupTime-Time(),0,PopupTime)/PopupTime)-SmallNotificationGap
			
			y+=(1-clamp(TimeLeft-FadeTime,0,FadeTime)/FadeTime)*surface.GetFontTall(SmallNotificationFont)
			
			alpha*=clamp(TimeLeft-FadeTime,0,FadeTime)/FadeTime
			
			local alphacolor=(alpha.tofloat()/255.0)

			notecolor.x=notecolor.x*alphacolor+(255-notecolor.x)*(1-alphacolor)
			notecolor.y=notecolor.y*alphacolor+(255-notecolor.y)*(1-alphacolor)
			notecolor.z=notecolor.z*alphacolor+(255-notecolor.z)*(1-alphacolor)
			
			surface.DrawColoredText(SmallNotificationFont,YRES(140)+2,y+2,0,0,0,alpha,notetext)
			surface.DrawColoredText(SmallNotificationFont,YRES(140),y,notecolor.x,notecolor.y,notecolor.z,alpha*0.8,notetext)
			
			if (TimeLeft<=0)
			{
				SmallNotifications.remove(i)
				i--
				continue
			}
			SmallNotificationGap+=surface.GetFontTall(SmallNotificationFont)+(YRES(420)-SmallNotificationGap-y)
		}
		
				// ============================================
		//  QUEST NOTIFICATIONS (сверху справа, в одну строку)
		// ============================================
		local QuestNotifFont = surface.GetFont("KeyHint5", true);   // мелкий шрифт
		QuestNotifFont = 98
		if (!QuestNotifFont) QuestNotifFont = SmallNotificationFont;
		
		local QuestNotifGap = 0;
		local QuestNotifBaseY = YRES(20);       // сверху
		local QuestNotifRightMargin = XRES(20);
		
		// Страховочная сортировка по приоритету
		SW_QUEST_NOTIFS.sort(function(a, b) {
			if (a.Priority != b.Priority) return a.Priority - b.Priority;
			if (a.StartTime != b.StartTime) return (a.StartTime < b.StartTime) ? -1 : 1;
			return 0;
		});
		
		foreach (i, notif in SW_QUEST_NOTIFS)
		{
			if (!notif) { SW_QUEST_NOTIFS.remove(i); i--; continue; }
			
			local elapsed = Time() - notif.StartTime;
			if (elapsed > notif.Duration)
			{
				SW_QUEST_NOTIFS.remove(i);
				i--;
				continue;
			}
			
			// === Плавное появление / исчезновение ===
			local alpha = 255;
			if (elapsed < 0.25) alpha = 255 * (elapsed / 0.25);
			else if (elapsed > notif.Duration - 0.5)
				alpha = 255 * (1 - (elapsed - (notif.Duration - 0.5)) / 0.5);
			alpha = clamp(alpha, 0, 255);
			
			local alpha2 = 255;
			if (elapsed < 0.25) alpha2 = 255 * (elapsed / 0.25);
			else if (elapsed > 1 - 0.5)
				alpha2 = 255 * (1 - (elapsed - (1 - 0.5)) / 0.5);
			alpha2 = clamp(alpha2, 0, 255);
			
			// === Печатная машинка ===
			local printProgress = clamp(elapsed / 0.4, 0, 1);
			
			// Собираем полный текст: "HEADER: Name"
			local fullHeader = notif.Header + ": ";
			local fullText = fullHeader + notif.Name;
			
			local fullLength = LLen(fullText);
			local visibleChars = (fullLength * printProgress).tointeger();
			local visibleText = LSlice(fullText, 0, visibleChars);
			
			// Сколько символов видно из header'а
			local headerLen = LLen(fullHeader);
			local visibleHeader = visibleText;
			local visibleName = "";
			
			if (visibleChars > headerLen)
			{
				// Header полностью виден, часть имени тоже
				visibleHeader = fullHeader;
				local nameChars = visibleChars - headerLen;
				visibleName = LSlice(notif.Name, 0, nameChars);
			}
			
			// === Позиция (справа сверху) ===
			local textW = surface.GetTextWidth(QuestNotifFont, fullText);
			local x = ScreenWidth() - textW - QuestNotifRightMargin;
			local y = QuestNotifBaseY + QuestNotifGap;
			
			// === Фон ===
			local bgPadX = YRES(4);
			local bgPadY = YRES(2);
			surface.SetColor(0, 0, 0, alpha * 0.4);
			surface.DrawFilledRect(x - bgPadX, y - bgPadY,
				textW + bgPadX * 2,
				surface.GetFontTall(QuestNotifFont) + bgPadY * 2);
			
			// === Тень (для всей строки) ===
			surface.DrawColoredText(QuestNotifFont, x + YRES(1), y + YRES(1), 0, 52, 0, alpha, visibleText);
			
			// === Header — цветной ===
			surface.DrawColoredText(QuestNotifFont+2, x + YRES(2), y + YRES(2),
				notif.Color[0], notif.Color[1], notif.Color[2], alpha2, visibleHeader);
			
			surface.DrawColoredText(QuestNotifFont, x, y,
				notif.Color[0], notif.Color[1], notif.Color[2], alpha, visibleHeader);
			
			// === Name — белый ===
			local nameX = x + surface.GetTextWidth(QuestNotifFont, visibleHeader);
			surface.DrawColoredText(QuestNotifFont, nameX, y,
				245, 245, 245, alpha, visibleName);
			
			// === Мигающий курсор ===
			if (printProgress < 1.0 && (Time() * 8).tointeger() % 2 == 0)
			{
				local cursorX = x + surface.GetTextWidth(QuestNotifFont, visibleText);
				surface.DrawColoredText(QuestNotifFont, cursorX, y,
					255, 255, 255, alpha, "_");
			}
			
			QuestNotifGap += surface.GetFontTall(QuestNotifFont) + YRES(6);
		}
		
		local BigNotificationGap=0
		foreach(i,Notification in BigNotifications)
		{
			local notetime=Notification[0]
			local notetext=Notification[1]
			local notecolor=Vector(Notification[2].x,Notification[2].y,Notification[2].z)
			
			local notedur=13
			if (Notification.len()>=4) notedur=Notification[3];
			
			
			local FadeTime=4.0
			if (Notification.len()==5) FadeTime=Notification[4];
			local PopupTime=0.05
			local Duration=notedur+FadeTime
			local TimeLeft=Duration-(Time()-notetime)
			
			local font=BigNotificationFont
			local fonts=BigNotificationBlurFont
			
			
			if ((notecolor-Vector(255,255,255)).Length()<1)
			{
				font=BigNotificationAltFont
				fonts=BigNotificationAltBlurFont
				PopupTime=0.2
			}
			
			local alpha=clamp(notetime+PopupTime-Time(),0,PopupTime)/PopupTime*255
			
			local glowalpha=clamp(notetime+2-Time(),0,1)*255
			
			alpha=255-alpha
			
			local y=YRES(120)-YRES(5)*(clamp(notetime+PopupTime-Time(),0,PopupTime)/PopupTime)-BigNotificationGap
			
			if ((notecolor-Vector(255,255,255)).Length()<1)
				y+=YRES(180)
			
			
			y+=(1-clamp(TimeLeft-FadeTime,0,FadeTime)/FadeTime)*surface.GetFontTall(font)
			
			alpha*=clamp(TimeLeft-FadeTime,0,FadeTime)/FadeTime
			
			local alphacolor=(alpha.tofloat()/255.0)

			notecolor.x=notecolor.x*alphacolor+(255-notecolor.x)*(1-alphacolor)
			notecolor.y=notecolor.y*alphacolor+(255-notecolor.y)*(1-alphacolor)
			notecolor.z=notecolor.z*alphacolor+(255-notecolor.z)*(1-alphacolor)
			
			surface.DrawColoredText(font,XRES(320)-surface.GetTextWidth(font,notetext)/2+YRES(3)*cos(Time()*2),y+YRES(3)*sin(Time()),notecolor.x*0.1,notecolor.y*0.1,notecolor.z*0.1,alpha,notetext)
			surface.DrawColoredText(font,XRES(320)-surface.GetTextWidth(font,notetext)/2+YRES(2)*cos(Time()*2),y+YRES(2)*sin(Time()),notecolor.x*0.3,notecolor.y*0.3,notecolor.z*0.3,alpha,notetext)
			surface.DrawColoredText(font,XRES(320)-surface.GetTextWidth(font,notetext)/2,y,notecolor.x,notecolor.y,notecolor.z,alpha*0.8,notetext)
			
			surface.DrawColoredText(fonts,XRES(320)-surface.GetTextWidth(fonts,notetext)/2,y,notecolor.x,notecolor.y,notecolor.z,glowalpha,notetext)
			
			if (TimeLeft<=0)
			{
				BigNotifications.remove(i)
				i--
				continue
			}
			BigNotificationGap-=surface.GetFontTall(font)*2+(YRES(120)-BigNotificationGap-y)
		}
		
		if ((HintTime+8)>Time())
		{
			local hintmargin=YRES(10)
			surface.SetColor(15,15,15, 255*clamp(HintTime+8-Time(),0,1))
			surface.DrawFilledRect(XRES(20)-hintmargin,YRES(20)-hintmargin/2,surface.GetTextWidth(98,HintText)+hintmargin*2,surface.GetFontTall(98)+hintmargin)
			
			surface.SetColor(2,2,225,255*clamp(HintTime+0.5-Time(),0,0.3))
			surface.SetColor(2,225,255,255*clamp(HintTime+0.3-Time(),0,0.1))
			surface.DrawFilledRect(XRES(20)-hintmargin,YRES(20)-hintmargin/2,surface.GetTextWidth(98,HintText)+hintmargin*2,surface.GetFontTall(98)+hintmargin)
			surface.DrawFilledRect(XRES(20)-hintmargin,YRES(20)-hintmargin/2,surface.GetTextWidth(98,HintText)+hintmargin*2,surface.GetFontTall(98)+hintmargin)
			
			
			surface.DrawColoredText(98,XRES(20)-2,YRES(20)-2,12,172,255,15*clamp(HintTime+8-Time(),0,1),HintText);
			surface.DrawColoredText(98,XRES(20)-1,YRES(20)-1,12,255,125,15*clamp(HintTime+8-Time(),0,1),HintText);
			surface.DrawColoredText(100,XRES(20)+3*cos(10*Time()),YRES(20)+3*sin(10*Time()),12,115,255,255*clamp(HintTime+0.5-Time(),0,0.3),HintText);
			surface.DrawColoredText(98,XRES(20),YRES(20),212,212,255,255*clamp(HintTime+8-Time(),0,1),HintText);
			surface.DrawColoredText(100,XRES(20)+sin(10*Time()),YRES(20)+cos(10*Time()),12,255,115,255*clamp(HintTime+0.5-Time(),0,0.3),HintText);
		
			surface.DrawColoredText(100,XRES(20)+3*cos(10*Time()),YRES(20)+3*sin(10*Time()),12,115,255,255*clamp(HintTime+0.5-Time(),0,0.3),HintText);
			surface.DrawColoredText(100,XRES(20)+sin(10*Time()),YRES(20)+cos(10*Time()),12,255,115,255*clamp(HintTime+0.5-Time(),0,0.3),HintText);
			surface.DrawColoredText(100,XRES(20)+3*cos(10*Time()),YRES(20)+3*sin(10*Time()),12,115,255,255*clamp(HintTime+0.5-Time(),0,0.3),HintText);
			surface.DrawColoredText(98,XRES(20)+sin(10*Time()),YRES(20)+cos(10*Time()),12,255,115,255*clamp(HintTime+0.5-Time(),0,0.3),HintText);
			surface.DrawColoredText(98,XRES(20)+3*cos(10*Time()),YRES(20)+3*sin(10*Time()),12,115,255,255*clamp(HintTime+0.5-Time(),0,0.3),HintText);
			surface.DrawColoredText(98,XRES(20)+sin(10*Time()),YRES(20)+cos(10*Time()),12,255,115,255*clamp(HintTime+0.5-Time(),0,0.3),HintText);
		}
		
		if (RadioID!=null&&Convars.GetFloat("sourceworld_hud")!=2)
		{
		
			local delay=1.5
		
			if (RadioTime+delay>=Time()&&!RadioStarted)	
			{
				RadioStarted=true
				if (!RadioContinue) surface.PlaySound("ambient/levels/prison/radio_random13.wav");
				else surface.PlaySound("ambient/levels/prison/radio_random"+RandomInt(7,9)+".wav");
				RadioPrevText=0
			}
			
			local startanim=clamp((Time()-RadioTime)*(Time()-RadioTime),0,1)
			
			if (RadioContinue) 
			{
				delay=0.5
				startanim=1;
			}
			local sizex=YRES(280)*startanim
			local sizey=YRES(90)*startanim
			
			local RadioText=SW_RADIO_MSG[RadioID][1]
			local RadioPortrait=SW_RADIO_MSG[RadioID][0]
			
			function DrawTexturedSubRectAlt(x,y,w,h,u1,u2,v1,v2)
			{
				surface.DrawTexturedSubRect(x,y,x+w,y+h,u1,u2,v1,v2)
			}
			
			local randportraitoffset=sin(Time())/70.0
			local randportraitoffset2=cos(Time())/70.0
			
			local ex_y=0
			
			if (Time()-LastSwitchTime<3.5) ex_y=YRES(80)
			if (Time()-HintTime<7.5) ex_y+=YRES(40)
			
			
			surface.SetColor(255-233*startanim,180-158*startanim,22,230)
			surface.DrawFilledRect(XRES(30)-sizex/2.0+YRES(130),YRES(25)+ex_y,sizex,sizey)
			surface.SetColor(255-243*startanim,180-168*startanim,12,255)
			DrawOutlinedBoxAlt(YRES(3),XRES(30)-sizex/2.0+YRES(130),YRES(25)+ex_y,sizex,sizey)
			
			surface.SetColor(255-243*startanim,180-168*startanim,12,155)
			DrawOutlinedBoxAlt(YRES(6),XRES(30)-sizex/2.0+YRES(130),YRES(25)+ex_y,sizex,sizey)
			
			surface.SetColor(255-243*startanim,180-168*startanim,12,225)
			surface.DrawFilledRect(XRES(30)-sizex/2.0+YRES(130)+YRES(5),YRES(25)+YRES(5)+ex_y,sizey-YRES(10),sizey-YRES(10))
			
			surface.SetTexture(surface.ValidateTexture("vgui/radio/instructor",true,false,false))
			
			surface.SetColor(255-RandomInt(0,20),255-RandomInt(0,20),255-RandomInt(0,20),255-RandomInt(0,20))
			DrawTexturedSubRectAlt(XRES(30)-sizex/2.0+YRES(130)+YRES(5),YRES(25)+YRES(5)+ex_y,sizey-YRES(10),sizey-YRES(10),randportraitoffset,randportraitoffset2,randportraitoffset+1,randportraitoffset2+1)
			
			surface.SetTexture(surface.ValidateTexture("vgui/radio/noise",true,false,false))
			
			
			surface.SetColor(75,75,75,164)
			local randoffset=RandomFloat(0,10)
			local randoffset2=RandomFloat(0,10)
			DrawTexturedSubRectAlt(XRES(30)-sizex/2.0+YRES(130)+YRES(5),YRES(25)+YRES(5)+ex_y,sizey-YRES(10),sizey-YRES(10),randoffset,randoffset2,randoffset+1,randoffset2+1)
			
			randoffset=RandomFloat(0,10)
			randoffset2=RandomFloat(0,10)
			DrawTexturedSubRectAlt(XRES(30)-sizex/2.0+YRES(130)+YRES(5),YRES(25)+YRES(5)+ex_y,sizey-YRES(10),sizey-YRES(10),randoffset,randoffset2,randoffset+1,randoffset2+1)
			randoffset=RandomFloat(0,10)
			randoffset2=RandomFloat(0,10)
			surface.SetColor(115,105,95,164)
			DrawTexturedSubRectAlt(XRES(30)-sizex/2.0+YRES(130)+YRES(5),YRES(25)+YRES(5)+ex_y,sizey-YRES(10),sizey-YRES(10),randoffset,randoffset2,randoffset+1,randoffset2+1)
			
			
			
			surface.SetColor(5,5,5,255)
			DrawOutlinedBoxAlt(YRES(2),XRES(30)-sizex/2.0+YRES(130)+YRES(5),YRES(25)+YRES(5)+ex_y,sizey-YRES(10),sizey-YRES(10))
			
			local textwrite=clamp((Time()-RadioTime-delay)/LLen(RadioText)*30,0,1)
			
			local RadioFont=surface.GetFont( "RadioFont48", true )
			
			local RadioLines=GetTextInLines(RadioFont,YRES(180),RadioText,textwrite*LLen(RadioText))
			
			local RadioTotalText=(LLen(RadioText)*textwrite).tointeger()
			
			if (RadioTime+delay<=Time()) foreach(i,Line in RadioLines)
			{
				surface.DrawColoredText(RadioFont,XRES(30)+YRES(80)+2,ex_y+YRES(35)+i*surface.GetFontTall(RadioFont)*1.05+2,0,0,0,255,Line);
				surface.DrawColoredText(RadioFont,XRES(30)+YRES(80),ex_y+YRES(35)+i*surface.GetFontTall(RadioFont)*1.05,255,255,255,255,Line);
			}
			
			if (RadioTotalText!=LLen(RadioText)&&RadioPrevText<RadioTotalText&&RadioText[RadioTotalText]!=' '&&RadioText[RadioTotalText]!='.'&&RadioText[RadioTotalText]!=',') 
			{
				if (RadioTotalText%2==1) surface.PlaySound("common/radiotalk.wav");
				RadioPrevText=LLen(RadioText)*textwrite
			}
			
		}
		
		
		if ((Time()-LastMoneyChange)<4&&Time()>5) surface.DrawColoredText(52,XRES(640)-surface.GetTextWidth(52,"$"+LastMoney+"   ")+YRES(2),YRES(90)+YRES(2),0,15,0,255-127.5*clamp(Time()-LastMoneyChange-1,0,2),"$"+LastMoney);
		if ((Time()-LastMoneyChange)<4&&Time()>5) surface.DrawColoredText(52,XRES(640)-surface.GetTextWidth(52,"$"+LastMoney+"   "),YRES(90),20,255,20,255-127.5*clamp(Time()-LastMoneyChange-1,0,2),"$"+LastMoney);
		if (PlayerMoney>LastMoney) LastMoney+=clamp(((PlayerMoney-LastMoney)/10).tointeger(),1,500);
		if (PlayerMoney<LastMoney) LastMoney-=clamp((abs(PlayerMoney-LastMoney)/10).tointeger(),1,500);
		if (PlayerMoney!=LastMoney) {
			surface.PlaySound("common/null.wav");
			LastMoneyChange=Time()
		}
		
		if (player.GetCollisionGroup()==10&&GetMapName().find("teleporting_room_v1")==null&&GetMapName().find("weapons_range")==null&&GetMapName().find("sw_reclamation")==null)
		{
			surface.SetTexture(AmmoBG2)
			surface.SetColor(255,255,255,55)
			surface.DrawTexturedRect(XRES(640)-YRES(190),YRES(320),YRES(190),YRES(150))
			
			surface.SetColor(45,85,255,253*clamp(VehicleMPH/50.0,0,1))
			surface.DrawTexturedRect(XRES(640)-YRES(190),YRES(320),YRES(190),YRES(150))
			
			surface.DrawColoredText(surface.GetFont( "Smolss", true ),XRES(640)-YRES(90),YRES(442),0,175/4,255/4,255,"mph")
			surface.DrawColoredText(surface.GetFont( "Smol", true ),XRES(640)-YRES(90),YRES(442),0,175,255,255,"mph")
			
			local SpeednY=YRES(442)+surface.GetFontTall(surface.GetFont( "Smol", true ))-surface.GetFontTall(surface.GetFont( "BigNums", true ))
			
			surface.DrawColoredText(surface.GetFont( "BigNums", true ),XRES(640)-YRES(155),SpeednY,0,175,255,255,VehicleMPH.tostring())
			surface.DrawColoredText(surface.GetFont( "BigNumsS", true ),XRES(640)-YRES(155),SpeednY,0,175/4,255/4,255,VehicleMPH.tostring())
			surface.DrawColoredText(surface.GetFont( "BigNumsS", true ),XRES(640)-YRES(155),SpeednY,0,175/4,255/4,255,VehicleMPH.tostring())
			surface.DrawColoredText(surface.GetFont( "BigNums", true ),XRES(640)-YRES(155),SpeednY,0,175,255,255,VehicleMPH.tostring())
			surface.DrawColoredText(surface.GetFont( "BigNumsS", true ),XRES(640)-YRES(155),SpeednY,0,175,255,255*clamp((VehicleMPH-20)/50.0,0,1)-255*clamp((VehicleMPH-55)/25.0,0,1),VehicleMPH.tostring())
			surface.DrawColoredText(surface.GetFont( "BigNumsS", true ),XRES(640)-YRES(155),SpeednY,255,100,45,255*clamp((VehicleMPH-55)/25.0,0,1),VehicleMPH.tostring())
			
			
			
			local dmgmod=RemapValClamped(0.1-(Time()-LastCarDamage),0,0.1,0,1)
			
			local offsetx=sin(Time()*8)*YRES(2)*dmgmod
			local offsety=cos(Time()*8)*YRES(2)*dmgmod
			
			surface.SetColor(45+20*dmgmod,45+20*dmgmod,45+20*dmgmod,245)
			surface.DrawOutlinedRect(YRES(10)-YRES(2)+offsetx,YRES(420)-YRES(2)+offsety,YRES(100)+YRES(4),YRES(15)+YRES(4),YRES(2))
			
			
			surface.SetColor(25,255,25,65+90*dmgmod)
			if (CarHealth<750) surface.SetColor(255,255,25,65+90*dmgmod)
			if (CarHealth<500) surface.SetColor(255,145,25,65+90*dmgmod)
			if (CarHealth<250) surface.SetColor(255,25,25,100+65*sin(Time()*8)+90*dmgmod)
			
			surface.DrawFilledRect(YRES(10)+offsetx,YRES(420)+offsety,YRES(100)*CarHealth/1000.0,YRES(15))
			
			
			if ((Time()-LastHurtTime)<0.5||(Time()-LastBlockTime)<0.5)
			{
				local dmgalpha=DamageBlock ? 165 : clamp(255*Dmg,0,255)
				
				if (!(abs(DamageAngle)%360>60&&abs(DamageAngle)%360<300)) dmgalpha*=0.05
				
				surface.SetColor(255,255*DamageBlock.tointeger(),255*DamageBlock.tointeger(), clamp(pow(1-Time()+LastHurtTime,10),0,1)*dmgalpha)
				if (DamageBlock) surface.SetColor(255,255*DamageBlock.tointeger(),255*DamageBlock.tointeger(), clamp(pow(1-Time()+LastBlockTime,10),0,1)*dmgalpha);
				surface.SetTexture(DamageIndicator)
				
				//printl("Damage "+Dmg)
				
				surface.DrawTexturedRectRotated(ScreenWidth()/2-YRES(100)-cos((DamageAngle-90)/180.0*PI)*YRES(50),ScreenHeight()/2-YRES(100)+sin(((DamageAngle-90)/180.0*PI))*YRES(50),YRES(100)*2,YRES(100)*2,DamageAngle-180)
				surface.DrawTexturedRectRotated(ScreenWidth()/2-YRES(100)-cos((DamageAngle-90)/180.0*PI)*YRES(50),ScreenHeight()/2-YRES(100)+sin(((DamageAngle-90)/180.0*PI))*YRES(50),YRES(100)*2,YRES(100)*2,DamageAngle-180)
				
				surface.SetColor(255,255*DamageBlock.tointeger(),255*DamageBlock.tointeger(), clamp(pow(1-Time()+LastHurtTime,15),0,1)*dmgalpha)
				surface.DrawTexturedRectRotated(ScreenWidth()/2-YRES(100)-cos((DamageAngle-90)/180.0*PI)*YRES(50),ScreenHeight()/2-YRES(100)+sin(((DamageAngle-90)/180.0*PI))*YRES(50),YRES(100)*2,YRES(100)*2,DamageAngle-180)
				surface.DrawTexturedRectRotated(ScreenWidth()/2-YRES(100)-cos((DamageAngle-90)/180.0*PI)*YRES(50),ScreenHeight()/2-YRES(100)+sin(((DamageAngle-90)/180.0*PI))*YRES(50),YRES(100)*2,YRES(100)*2,DamageAngle-180)
			}
			
			
		}
		
		NetMsg.Start("RequestAUXPower")
		NetMsg.Send()
		
		if (Convars.GetFloat("sourceworld_hud")==2||(player&&player.GetCollisionGroup()==10)) 
		{
			
			if (Scale<3.5) for (local i=0;i<640;i+=2)
			{
				surface.SetColor(0,0,0,255)
				
				//local DistMod=XRES(abs(320-i))/2.0
				local DistMod=0
				//surface.DrawFilledRect(XRES(i),0,XRES(2),DistMod+YRES(480)-YRES(480)*(Scale-1.5-(RNGs[i]/2)))
				surface.SetColor(133,133,133,255)
				//local rngmod=RNGs[i]/4.0
				local rngmod=pow(RNGs[i+10]+1,14)
				local offset=clamp((-YRES(480))+clamp(DistMod+YRES(480)+YRES(480)*(Scale-1.5-(rngmod/4.0)),0,9999),0,ScreenHeight())
				
				surface.SetTexture(blackness)
				//if (i==0) surface.DrawTexturedRect(0,0,ScreenWidth(),ScreenHeight());
				
				local onepixel=((XRES(2)*320==XRES(640)) ? 0 : 1)
				
				surface.DrawTexturedSubRect(XRES(i), offset, XRES(i)+XRES(2)+onepixel, YRES(480)+offset,RemapVal(i.tofloat(),0,640,0,1),0,RemapVal(i.tofloat()+2,0,640,0,1),1)
				//surface.SetColor(255,255,255,5)
				//surface.SetTexture(pov)
				//surface.DrawTexturedSubRect(XRES(i), offset-YRES(480), XRES(i)+XRES(2), offset,RemapVal(i.tofloat(),0,640,0,1),0,RemapVal(i.tofloat()+2,0,640,0,1),1)

			}
			
			return;
		}
		local size=YRES(130)
		local WeaponName="None"
		//GetPlayerWeapon()
		WeaponName=SW_HUDPlayerWeapon;
		if (player.GetActiveWeapon()&&Convars.GetBool("crosshair")&&WeaponName&&WeaponName.len()>0&&!SniperScopeActive)
		{
			if (F2000Active||(Time()-LastF2000Time)<=0.1)
			{
				surface.SetColor(255,255,255,clamp((Time()-LastF2000Time)*1000,0,255))
				
				surface.SetTexture(surface.ValidateTexture("sprites/blur_arc",true,false,false))
				
				surface.DrawTexturedSubRect(0-YRES(4),YRES(-4),ScreenWidth()/2,ScreenHeight()/2,0,0,-1,-1)
				surface.DrawTexturedSubRect(ScreenWidth()/2,YRES(-4),ScreenWidth(),ScreenHeight()/2,0,0,1,-1)
				
				surface.DrawTexturedSubRect(0-YRES(4),ScreenHeight()/2,ScreenWidth()/2,ScreenHeight(),0,0,-1,1)
				surface.DrawTexturedSubRect(ScreenWidth()/2,ScreenHeight()/2,ScreenWidth(),ScreenHeight(),0,0,1,1)
				
				surface.SetTexture(surface.ValidateTexture("sprites/blur_arc2",true,false,false))
				
				surface.DrawTexturedSubRect(0-YRES(4),YRES(-4),ScreenWidth()/2,ScreenHeight()/2,0,0,-1,-1)
				surface.DrawTexturedSubRect(ScreenWidth()/2,YRES(-4),ScreenWidth(),ScreenHeight()/2,0,0,1,-1)
				
				surface.DrawTexturedSubRect(0-YRES(4),ScreenHeight()/2,ScreenWidth()/2,ScreenHeight(),0,0,-1,1)
				surface.DrawTexturedSubRect(ScreenWidth()/2,ScreenHeight()/2,ScreenWidth(),ScreenHeight(),0,0,1,1)
			}
			
			local thickness=2
			local width=XRES(3)
			
			if (F2000Active) thickness=4
			if (F2000Active) width=XRES(15)
			if (F2000Active&&(Time()-LastF2000Time)<=0.17) thickness=0
			
			local circlealpha=RemapValClamped(currentAccuracy*YRES(2.5),YRES(30),YRES(50),255,0)
			
			//surface.SetColor(0, 153/5, 255/5,circlealpha)
			//surface.DrawOutlinedCircle(XRES(320),YRES(240),currentAccuracy*YRES(2.5)+width/2,circlealpha)
			//surface.SetColor(10, 10, 10,circlealpha)
			//surface.DrawOutlinedCircle(XRES(320),YRES(240),currentAccuracy*YRES(2.5)+width/2+1,circlealpha)
				
				
			surface.SetColor(0, 153, 255, circlealpha)
			if (F2000Active&&(Time()-LastF2000Time)>0.17) surface.SetColor(255, 0, 0, circlealpha*0.8)
			
			//if (currentAccuracy>13) currentAccuracy=0.7;
			
			surface.DrawFilledRect((XRES(320)-currentAccuracy*YRES(2.5) - width),YRES(240)-thickness/2,width,thickness)
			surface.DrawFilledRect((XRES(320)+currentAccuracy*YRES(2.5))+thickness/2,YRES(240)-thickness/2,width,thickness)
			if (!(F2000Active&&(Time()-LastF2000Time)>0.17)) surface.DrawFilledRect(XRES(320)-thickness/2,YRES(240)-currentAccuracy*YRES(2.5) - width,thickness,width)
			surface.DrawFilledRect(XRES(320)-thickness/2,YRES(240)+currentAccuracy*YRES(2.5)+thickness/2,thickness,width)
			
			//surface.DrawFilledRect(XRES(320)-thickness/2,YRES(240)-thickness/2,thickness,thickness)
			
			surface.SetColor(0, 153*0.5, 255*0.5, circlealpha)
			if (F2000Active&&(Time()-LastF2000Time)>0.17) surface.SetColor(177, 0, 0, circlealpha)
			
			surface.DrawFilledRectFade((XRES(320)-currentAccuracy*YRES(2.5) - width),YRES(240)-thickness/2,width,thickness,255,0,true)
			surface.DrawFilledRectFade((XRES(320)+currentAccuracy*YRES(2.5))+thickness/2,YRES(240)-thickness/2,width,thickness,0,255,true)
			if (!(F2000Active&&(Time()-LastF2000Time)>0.17)) surface.DrawFilledRectFade(XRES(320)-thickness/2,YRES(240)-currentAccuracy*YRES(2.5) - width,thickness,width,255,0,false)
			surface.DrawFilledRectFade(XRES(320)-thickness/2,YRES(240)+currentAccuracy*YRES(2.5)+thickness/2,thickness,width,0,255,false)
		}
		
		function DrawOutlinedBoxAlt(b,x,y,w,t)
		{
			local border=b
			local wide=w
			local tall=t
			surface.DrawFilledRect( x, y,wide,border );
			surface.DrawFilledRect( x, y+border,border,tall-border );
			surface.DrawFilledRect( x+border, y+tall-border,wide-border,border );
			surface.DrawFilledRect( x+wide-border, y+border,border,tall-border*2 );
		}
		
		////////////////////////////
		//	WEAPON SELECTION HUD  //
		////////////////////////////
		
		if (Time()-LastSwitchTime<4) foreach (i,a in WeaponsAlpha)
		{
			local ScrollMod=(Time()-SW_Player_LastScrollTime>0.2) ? 1 : 4
			if (i==LAST_WEAPON_SLOT||(((typeof LAST_WEAPON_SLOT)=="array")&&LAST_WEAPON_SLOT.find(i)!=null))
			{
				local diff=WeaponsAlpha[i]-clamp(pow(WeaponsAlpha[i],0.95),0.01,1)
				WeaponsAlpha[i]=clamp(WeaponsAlpha[i]-diff*FrameTime()*220*ScrollMod,0.01,1)
				//printl(WeaponsAlpha[i])
			}
			else WeaponsAlpha[i]=clamp(WeaponsAlpha[i]-0.03*FrameTime()*220*ScrollMod,0.01,1);
			if (input.GetAnalogValue(AnalogCode.MOUSE_WHEEL)!=SW_Player_LastScrollValue)
			{
				SW_Player_LastScrollTime=Time()
			}
			
			SW_Player_LastScrollValue=input.GetAnalogValue(AnalogCode.MOUSE_WHEEL)
			
		}
		
		local SelAl=clamp(3-(Time()-LastSwitchTime),0.0,1.0)
		
		if (Time()-LastSwitchTime<4&&("Weapons" in aPlayer))
		{
			local X=XRES(120)
			local SelectedSlot=[]	// Array of currently active weapon slots 1-6;
			if ((typeof LAST_WEAPON_SLOT)=="array") SelectedSlot.extend(LAST_WEAPON_SLOT)
			else SelectedSlot=[LAST_WEAPON_SLOT]
			
			local SizeX=YRES(60)*1.2
			local SizeY=YRES(45)*1.2
			local S_SizeX=YRES(90)*1.2
			local S_SizeY=YRES(60)*1.2
			local Gap=0
			local IconColor=Vector(12,175,255)
			
			foreach (i,swep in WEAPON_SLOTS)
			{
				if (swep==null) {X+=SizeX.tointeger();;continue};
				local wep=aPlayer.Weapons[swep]
				if (wep==null) {X+=SizeX.tointeger();;continue};
				
				local IsSelected=(SelectedSlot.find(i)!=null)
				local IsDual=(SelectedSlot.len()>1)
				
				local WepName=LIST_ITEMS[wep.Name].name
				if ("shortname" in LIST_ITEMS[wep.Name]) WepName=LIST_ITEMS[wep.Name].shortname;
				local AmmoReserve=""
				if (wep.AMMOTYPE!="item_ammo_none") AmmoReserve=Entities.FindByName(null,"stamina_system").GetScriptScope().HasItemCount(LIST_ITEMS[wep.AMMOTYPE].name).tostring();
				local Icon1=surface.ValidateTexture("vgui/hud/"+LIST_ITEMS[wep.Name].hudicon+"_Outline",true,false,false)
				local Icon2=surface.ValidateTexture("vgui/hud/"+LIST_ITEMS[wep.Name].hudicon+"_Fill",true,false,false)
				
				local Mult=WeaponsAlpha[i]
				local SizeXNormal=SizeX
				local SizeX=SizeX+(S_SizeX-SizeX)*Mult
				local SizeY=SizeY+(S_SizeY-SizeY)*Mult
				
				//surface.SetColor(0,0,0,(100-100*Mult)*SelAl)
				//surface.DrawFilledRect(X,YRES(20),SizeX,SizeY)
				surface.SetColor(0,0,0,255*SelAl)
				surface.DrawFilledRectFade(X,YRES(20),SizeX,SizeY,0,25+230*Mult,false)
				//surface.SetColor(10,10,10,255)
				//surface.SetTexture(surface.ValidateTexture("vgui/hud/corner",true,false,false))
				//surface.DrawTexturedRect(X,YRES(20),SizeX,SizeY)
				
				IconColor=Vector(12,175,255)
				if (IsSelected) IconColor=Vector(40,205,255)
				if (IsDual&&IsSelected) IconColor=Vector(255,255,55)
				if ((wep.clip+"/"+AmmoReserve)=="0/0"&&IsSelected) IconColor=Vector(215+40*sin(Time()*15),25,25)
				if ((wep.clip+"/"+AmmoReserve)=="0/0"&&!IsSelected) IconColor=Vector(215,25,25)
				
				local TextFont=(Mult>0.5) ? SelectorFont : SelectorFontSmall
				local TextAmmoFont=(Mult>0.5) ? SelectorAmmoFont : SelectorAmmoFontSmall
				
				surface.DrawColoredText(TextFont,X+SizeX/2-surface.GetTextWidth(TextFont,WepName)/2+YRES(1),YRES(23),IconColor.x/10,IconColor.y/10,IconColor.z/10,255*SelAl,WepName);
				surface.DrawColoredText(TextFont,X+SizeX/2-surface.GetTextWidth(TextFont,WepName)/2,YRES(22),IconColor.x,IconColor.y,IconColor.z,255*SelAl,WepName);
				
				if (Mult>0.5) surface.DrawColoredText(SelectorFontGlow,X+SizeX/2-surface.GetTextWidth(SelectorFontGlow,WepName)/2,YRES(22),IconColor.x,IconColor.y,IconColor.z,175*(Mult-0.5)*2*SelAl,WepName);
				
				
				
				surface.DrawColoredText(22,X+YRES(5)+YRES(1),YRES(20)+YRES(1),IconColor.x/10,IconColor.y/10,IconColor.z/10,255*SelAl,(i+1).tostring());
				surface.DrawColoredText(22,X+YRES(5),YRES(20),IconColor.x,IconColor.y,IconColor.z,255*SelAl,(i+1).tostring());
				
				
				surface.SetTexture(Icon2)
				
				local IconSizeX=clamp(SizeX*(Mult+0.5),SizeX,SizeX*1.5)
				local IconSizeY=clamp(SizeY*(Mult+0.5),SizeY,SizeY*1.5)
				local IconMult=1-clamp(Mult,0.01,1)
				
				local IconXdif=(SizeX-IconSizeY)/2
				
				surface.SetColor(0,0,0,(255-255*IconMult)*SelAl)
				surface.DrawTexturedSubRect(X+IconXdif+3,YRES(20)+SizeY/2-IconSizeY/2+3,X+IconSizeY+IconXdif+3,YRES(20)+SizeY/2+IconSizeY/2+3,0,0,1,1)
				surface.DrawTexturedSubRect(X+IconXdif+2,YRES(20)+SizeY/2-IconSizeY/2+2,X+IconSizeY+IconXdif+2,YRES(20)+SizeY/2+IconSizeY/2+2,0,0,1,1)
				surface.DrawTexturedSubRect(X+IconXdif+1,YRES(20)+SizeY/2-IconSizeY/2+1,X+IconSizeY+IconXdif+1,YRES(20)+SizeY/2+IconSizeY/2+1,0,0,1,1)
				surface.SetTexture(Icon2)
				
				surface.SetColor(IconColor.x*(1-IconMult),IconColor.y*(1-IconMult),IconColor.z*(1-IconMult),(205+50*(1-IconMult))*SelAl)
				
				surface.DrawTexturedSubRect(X+IconXdif,YRES(20)+SizeY/2-IconSizeY/2,X+IconSizeY+IconXdif,YRES(20)+SizeY/2+IconSizeY/2,0,0,1,1)
				
				//surface.DrawTexturedSubRect(X+IconXdif,YRES(20)+SizeY/2-IconSizeY/2,X+IconSizeY+IconXdif,YRES(20)+SizeY/2+IconSizeY/2,0,0,1,1)
				
				surface.SetColor(IconColor.x*IconMult,IconColor.y*IconMult,IconColor.z*IconMult,255*SelAl)
				surface.SetTexture(Icon1)
				surface.DrawTexturedSubRect(X+IconXdif,YRES(20)+SizeY/2-IconSizeY/2,X+IconSizeY+IconXdif,YRES(20)+SizeY/2+IconSizeY/2,0,0,1,1)
				
				if (wep.AMMOTYPE!="item_ammo_none"&&!wep.SingleUse) surface.DrawColoredText(TextAmmoFont,X+YRES(5)+1,YRES(20)+SizeY-YRES(5)-surface.GetFontTall(TextAmmoFont)+1,0,0,0,255*SelAl,wep.clip+"/"+AmmoReserve);
				if (wep.AMMOTYPE!="item_ammo_none"&&!wep.SingleUse) surface.DrawColoredText(TextAmmoFont,X+YRES(5),YRES(20)+SizeY-YRES(5)-surface.GetFontTall(TextAmmoFont),IconColor.x,IconColor.y,IconColor.z,255*SelAl,wep.clip+"/"+AmmoReserve);
				
				if (wep.AMMOTYPE!="item_ammo_none"&&wep.SingleUse) surface.DrawColoredText(TextAmmoFont,X+YRES(5)+1,YRES(20)+SizeY-YRES(5)-surface.GetFontTall(TextAmmoFont)+1,0,0,0,255*SelAl,AmmoReserve);
				if (wep.AMMOTYPE!="item_ammo_none"&&wep.SingleUse) surface.DrawColoredText(TextAmmoFont,X+YRES(5),YRES(20)+SizeY-YRES(5)-surface.GetFontTall(TextAmmoFont),IconColor.x,IconColor.y,IconColor.z,255*SelAl,AmmoReserve);
				
				
				
				X+=SizeX.tointeger();
			}
		
		}
		
		while (Glowies.len()>0) foreach (i,g in Glowies)
		{
			GlowObjectManager.Unregister(g)
			Glowies.rawdelete(i)
		}
		
		local QuickUseFadeTime=0.3
		local QuickUseBlinkTime=0.15
		
		local HoldingALT=(input.LookupBinding("+alt1")&&input.IsButtonDown(input.StringToButtonCode(input.LookupBinding("+alt1"))))
		
		if (!HoldingALT) QuickUseStatus=max(0,QuickUseStatus-FrameTime());
		
		if (HoldingALT||QuickUseStatus>0)
		{
			if (HoldingALT&&QuickUseStatus==0) surface.PlaySound("ui/buttonrollover.wav")
			if (HoldingALT&&QuickUseStatus<QuickUseFadeTime) QuickUseStatus=min(QuickUseFadeTime,QuickUseStatus+FrameTime());

			
			local QU_alpha=HoldingALT ? Bias(QuickUseStatus/QuickUseFadeTime,0.9) : Bias(QuickUseStatus/QuickUseFadeTime,0.2)
			QU_alpha=clamp(QU_alpha,0,1)
			
			
			local ent=null
			
			local color2=Vector(0,170,255)
			local color1=Vector(60,255,100)
			
			local mult=(Time()-Time().tointeger())
			if (Time().tointeger()%2==1) mult=1-mult
			local color=color1*(1-mult)+color2*mult
			
			local alphamod=1
			
			// OBJECT GLOW
			while(ent=Entities.FindByClassname(ent,"*"))
			{
				if (Ent&&ent==Ent&&ItemName!="None") continue;
				if (((ent.GetOrigin()-player.GetCenter()).Length()>200)) continue;
				if (!(ent.GetEffects()&256)) continue;
				
				//printl(NetProps.GetPropString(ent,"m_ModelName"))
				if (ent.GetHealth()==4096) color2=Vector(255,190,5);
				
				alphamod=RemapValClamped((ent.GetOrigin()-player.GetCenter()).Length(),35,70,0.7,1)
				if (alphamod==1) alphamod=RemapValClamped((ent.GetOrigin()-player.GetCenter()).Length(),160,200,1,0.3)
				
				if (!(ent.entindex() in Glowies)) Glowies.rawset(ent.entindex(),GlowObjectManager.Register(ent,color.x,color.y,color.z,(90*mult+150)*alphamod,false,true));
			}
		
		
			local Cell=YRES(48)*QU_alpha
			local ATLAS_TEXTURE=surface.ValidateTexture("vgui/inventory/item_atlas",true,false,false)
			local ATLAS_SIZE=16.0
			for (local i=0;i<4;i++)
			{
			
				local Bound=QUICK_USE_SLOTS[i]!=null
				local Item=QUICK_USE_SLOTS[i]!=null
				local Available=false
				if (Bound&&Item) Available=true;
				
				local CenterX=XRES(320)
				local OffsetX=(-Cell*2+Cell*i+YRES(2)*i)*QU_alpha
				local CenterY=YRES(400)+YRES(80)*(1-QU_alpha)
			
				surface.SetColor(5,20,30,155*QU_alpha)
				surface.DrawFilledRect(CenterX+OffsetX,CenterY,Cell,Cell)
				
				surface.SetColor(255,255,255,255*QU_alpha)
				if (Available)
				{
					local item=LIST_QUEST_ITEMS[QUICK_USE_SLOTS[i]]
					
					local IconX=item.icon[0]/ATLAS_SIZE;
					local IconY=item.icon[1]/ATLAS_SIZE;
					local IconSizeX=item.sizey
					local IconSizeY=item.sizey
					local IconUV_X=IconSizeX/min(item.sizex,item.sizey)*1.0
					local IconUV_Y=IconSizeY/min(item.sizex,item.sizey)*1.0
					
					surface.SetColor( 255,255,255,(200+55*fabs(sin(Time()*4)))*QU_alpha );
					local Scale=min(IconSizeX,IconSizeY)*1.0/max(IconSizeX,IconSizeY)*1.0
					local ItemOffsetX=(IconSizeX>IconSizeY) ? 0 : (Cell-Cell*Scale)/2
					local OffsetY=(IconSizeX<IconSizeY) ? 0 : (Cell-Cell*Scale)/2
					surface.SetTexture(ATLAS_TEXTURE)
					surface.DrawTexturedSubRect(OffsetX+CenterX+ItemOffsetX, CenterY+OffsetY, OffsetX+CenterX+ItemOffsetX+Cell*IconUV_X*Scale, CenterY+Cell*IconUV_Y*Scale+OffsetY, IconX, IconY,IconX+IconSizeX/ATLAS_SIZE,IconY+IconSizeY/ATLAS_SIZE)
				}
				
				surface.SetColor(30+cos(Time()*4+1)*8,120+sin(Time()*4+2)*10,170+sin(Time()*4)*20,155*(Available).tointeger()*QU_alpha)
				
				surface.SetTexture(surface.ValidateTexture("vgui/hud/gradient",true,false,false))
				surface.DrawTexturedRectRotated(CenterX+OffsetX,CenterY,Cell,Cell,180)
				//surface.DrawFilledRectFade(CenterX+OffsetX,CenterY+Cell/2,Cell,Cell/2,0,50,false)
				
				
				surface.SetColor(30,120,170,255*QU_alpha)
				surface.SetTexture(surface.ValidateTexture("vgui/zoom",true,false,false))
				surface.DrawTexturedRect(CenterX+OffsetX,CenterY,Cell,Cell)
				
				if (i==LastQuickUseItem)
				{
					local quickusemod=(QuickUseBlinkTime-(Time()-LastQuickUsePressed))/QuickUseBlinkTime
					quickusemod=clamp(quickusemod,0,1)
					surface.SetColor(30,160,250,(55+200*Available.tointeger())*QU_alpha*quickusemod)
					surface.DrawFilledRect(CenterX+OffsetX,CenterY,Cell,Cell)
					
				}
				
				surface.SetColor(30,120,170,255*QU_alpha)
				DrawOutlinedBoxAlt(YRES(2),CenterX+OffsetX,CenterY,Cell,Cell)
				surface.SetColor(10,50,80,255*QU_alpha)
				DrawOutlinedBoxAlt(YRES(2)/2,CenterX+OffsetX,CenterY,Cell,Cell)
				
				
				
				surface.DrawColoredText(SelectorFont,CenterX+OffsetX+YRES(4),CenterY+YRES(2),30,120,170,255*QU_alpha,(i+1).tostring())
			}
		}
		
		////////////////////////////
		////   QUICK USE HUD    ////
		////////////////////////////
		
		////////////////////////////
		////////////////////////////
		////////////////////////////
		
		
		if (WeaponName&&WeaponName!="weapon_crowbar"&&WeaponName!="weapon_pipe"&&WeaponName!="weapon_tomahawk"&&WeaponName!="weapon_sword"&&WeaponName!="weapon_shield"&&WeaponName!="None"&&WeaponName!=""&&Holstered!=true&&("Weapon" in aPlayer)&&!Entities.FindByName(null,"PlayerModel"))
		{
			Ammo<-Clip1
			Ammo2<-player.GetActiveWeapon().Clip2()
			AmmoMax<-MaxClip1
			//printl(Ammo+" "+AmmoMax)
			surface.SetTexture(AmmoBG)
			surface.SetColor(255,255,255,255)
			surface.DrawTexturedRect(XRES(640)-YRES(180),YRES(297),YRES(180),YRES(180))
			
			
			
			Clip<-Ammo*1.0/AmmoMax
			Clip=RemapVal(Clip,0,1,0.08,0.95)
			if (player.GetActiveWeapon().GetClassname()=="weapon_ar2") Clip=RemapVal(Clip,0.08,0.95,0.05,0.95);
			if (player.GetActiveWeapon().GetClassname()=="weapon_rpg") Clip=RemapVal(Clip,0.08,0.95,0.05,0.99);
			if (WeaponName=="weapon_pistol") Clip=RemapVal(Clip,0.08,0.95,0.25,0.8);
			if (WeaponName=="weapon_glock") Clip=RemapVal(Clip,0.08,0.95,0.2,0.85);
			if (WeaponName=="weapon_colt") Clip=RemapVal(Clip,0.08,0.95,0.2,0.85);
			if (WeaponName=="weapon_dual_pistol") Clip=RemapVal(Clip,0.08,0.95,0.2,0.8);
			if (WeaponName=="weapon_dual_colt") Clip=RemapVal(Clip,0.08,0.95,0.2,0.8);
			if (WeaponName=="weapon_dual_glock") Clip=RemapVal(Clip,0.08,0.95,0.2,0.85);
			//if (player.GetActiveWeapon().GetClassname()=="weapon_frag") Clip=RemapVal(Clip,0.08,0.95,0.25,0.8);
			//if (player.GetActiveWeapon().GetClassname()=="weapon_357") Clip=RemapVal(Clip,0.08,0.95,0.25,0.8);
			
			//printl(player.GetActiveWeapon().Clip1()+"/"+player.GetActiveWeapon().GetDefaultClip1())
			//printl(Clip)
			
			//surface.SetTexture(SMGFill)
			if (Ammo<LastAmmo&&AmmoMax==LastAmmoMax) LastShoot=Time();
			LastAmmo=Ammo;
			LastAmmoMax=AmmoMax
			
			Difference<-clamp(255-pow((Time()-LastShoot),0.5)*255,0,255)
			Difference2<-clamp(255-pow((Time()-LastShoot+0.95),4)*255,0,255)
			
			//surface.SetTexture(SMGFill)
			//surface.SetTexture(deb)
			
			startx<-XRES(640)-YRES(150)-YRES(7)
			endx<-XRES(640)-YRES(7)
			/*
			gap<-YRES(1);
			wide<-YRES(5)
			fill_x1<-0
			for (local i=1;i<=30;i++)
			{
				x1<-RemapVal(i,1,30,gap+startx,endx+gap)
				if ((RemapVal(i,1,30,1,AmmoMax+1)>=((1-Clip)*(AmmoMax+1)))&&fill_x1==0) fill_x1=x1;
				x2<-RemapVal(i,1,30,startx+wide,endx+wide)
				u1<-RemapVal(x1,startx,endx,0.0,1.0)
				u2<-RemapVal(x2,startx,endx,0.0,1.0)
				printl(u1+" "+u2)
				surface.SetColor(AmmoColor(Clip,255)[0],AmmoColor(Clip,255)[1],AmmoColor(Clip,255)[2], Difference)
				if (RemapVal(i,1,30,1,AmmoMax+1)>=((1-Clip)*(AmmoMax+1))) surface.DrawTexturedSubRect(x1,YRES(480)-YRES(150),x2,YRES(480),u1,0,u2,1);
				surface.SetColor(AmmoColor(Clip,255)[0],AmmoColor(Clip,255)[1],AmmoColor(Clip,255)[2], Difference2)
				if (RemapVal(i,1,30,1,AmmoMax+1)>=((1-Clip)*(AmmoMax+1))) surface.DrawTexturedSubRect(x1,YRES(480)-YRES(150),x2,YRES(480),u1,0,u2,1);
			}
			*/
			//GetPlayerWeapon()
			//printl(SW_HUDPlayerWeapon)
			//printl(player.GetActiveWeapon().GetModelName())
			//printl(player.GetActiveWeapon().GetName())
			if (HUDWeapons_classnames.find(SW_HUDPlayerWeapon)) surface.SetTexture(Fills[HUDWeapons_classnames.find(SW_HUDPlayerWeapon)]);
			else surface.SetTexture(Fills[0]);;
			surface.SetColor(AmmoColor(Clip,Difference2)[0],AmmoColor(Clip,Difference2)[1],AmmoColor(Clip,Difference2)[2], (255-Difference))
			Clip=RemapVal(Clip,0.08,0.95,0.05,0.96)
			//dif<-startx+YRES(150)*(1-Clip)-fill_x1
			surface.DrawTexturedSubRect(startx+YRES(150)*(1-Clip),YRES(485)-YRES(150),endx,YRES(485),(1-Clip),0,1,1);
		
			surface.SetColor(AmmoColor(Clip,255)[0],AmmoColor(Clip,255)[1],AmmoColor(Clip,255)[2], Difference2*2)
			//surface.DrawTexturedSubRect(startx+YRES(150)*(1-Clip),YRES(480)-YRES(150),endx,YRES(480),(1-Clip),0,1,1);
			if (HUDWeapons_classnames.find(SW_HUDPlayerWeapon)) surface.SetTexture(Scanlines[HUDWeapons_classnames.find(SW_HUDPlayerWeapon)]);
			else surface.SetTexture(Scanlines[0]);;
			surface.SetColor(AmmoColor(Clip,Difference2)[0],AmmoColor(Clip,Difference2)[1],AmmoColor(Clip,Difference2)[2], Difference)
			
			surface.DrawTexturedSubRect(startx+YRES(150)*(1-Clip),YRES(485)-YRES(150),endx,YRES(485),(1-Clip),0,1,1);
			surface.SetColor(AmmoColor(Clip,Difference2)[0],AmmoColor(Clip,Difference2)[1],AmmoColor(Clip,Difference2)[2], Difference2)
			surface.DrawTexturedSubRect(startx+YRES(150)*(1-Clip),YRES(485)-YRES(150),endx,YRES(485),(1-Clip),0,1,1);
			surface.DrawTexturedSubRect(startx+YRES(150)*(1-Clip),YRES(485)-YRES(150),endx,YRES(485),(1-Clip),0,1,1);
			surface.DrawTexturedSubRect(startx+YRES(150)*(1-Clip),YRES(485)-YRES(150),endx,YRES(485),(1-Clip),0,1,1);
			surface.DrawTexturedSubRect(startx+YRES(150)*(1-Clip),YRES(485)-YRES(150),endx,YRES(485),(1-Clip),0,1,1);
			surface.DrawTexturedSubRect(startx+YRES(150)*(1-Clip),YRES(485)-YRES(150),endx,YRES(485),(1-Clip),0,1,1);
			surface.DrawTexturedSubRect(startx+YRES(150)*(1-Clip),YRES(485)-YRES(150),endx,YRES(485),(1-Clip),0,1,1);
			
			//surface.SetColor(AmmoColor(Clip,255)[0],AmmoColor(Clip,255)[1],AmmoColor(Clip,255)[2], Difference2)
			//surface.DrawTexturedSubRect(startx+YRES(150)*(1-Clip),YRES(460)-YRES(150),endx,YRES(460),(1-Clip),0,1,1);
			if (HUDWeapons_classnames.find(SW_HUDPlayerWeapon)) surface.SetTexture(Outlines[HUDWeapons_classnames.find(SW_HUDPlayerWeapon)]);
			else surface.SetTexture(Outlines[0]);;
			surface.SetColor(RemapVal(clamp(Ammo,0.01,AmmoMax/10.0),0,AmmoMax/10.0,255,0),5,5, 255)
			
			surface.DrawTexturedRect(startx,YRES(485)-YRES(150),YRES(150),YRES(150))
			//if (WeaponName.find("dual")!=null) surface.DrawTexturedRect(startx+YRES(5),YRES(485)-YRES(145),YRES(150),YRES(150))
			
			surface.SetColor(0,180,250,(RemapVal(clamp(Ammo,0.01,AmmoMax/10.0),0,AmmoMax/10.0,255,0),5,5, 255/6-RemapVal(clamp(Ammo,0.01,AmmoMax/10.0),0,AmmoMax/10.0,255,0)/6))
			
			if (aPlayer.Weapon&&aPlayer.Weapon.SingleUse&&Time()-LastBlipTime<1.5)
			{
				//printl(LastGrenadeTime)
				local Mod=clamp((0.33-(Time()-LastBlipTime))*3,0,1)
				local ModTimer=clamp((3.15-(Time()-LastGrenadeTime))/3.15,0,1)
				Mod=1-Mod
				surface.SetColor(C1[0]*Mod+C3[0]*(1-Mod),C1[1]*Mod+C3[1]*(1-Mod),C1[2]*Mod+C3[2]*(1-Mod),255)
			}
			
			surface.DrawTexturedSubRect(startx,YRES(485)-YRES(150),endx-YRES(150)*(Clip),YRES(485),0,0,(1-Clip),1);
			//if (WeaponName.find("dual")!=null) surface.DrawTexturedSubRect(startx-YRES(5),YRES(485)-YRES(145),endx-YRES(150)*(Clip),YRES(485),0,0,(1-Clip),1);
			
			surface.SetColor(AmmoColor(Clip,Difference2)[0],AmmoColor(Clip,Difference2)[1],AmmoColor(Clip,Difference2)[2], Difference2)
			surface.DrawTexturedRect(startx,YRES(485)-YRES(150),YRES(150),YRES(150))
			surface.DrawTexturedRect(startx,YRES(485)-YRES(150),YRES(150),YRES(150))
			//if (WeaponName.find("dual")!=null) surface.DrawTexturedRect(startx+YRES(5),YRES(485)-YRES(145),YRES(150),YRES(150))
			//if (WeaponName.find("dual")!=null) surface.DrawTexturedRect(startx+YRES(5),YRES(485)-YRES(145),YRES(150),YRES(150))
			//surface.SetColor(0,170,250,(RemapVal(clamp(Ammo,0.01,AmmoMax/10.0),0,AmmoMax/10.0,255,0),5,5, 255)-200)
			//surface.DrawTexturedSubRect(startx,YRES(485)-YRES(150),endx-YRES(150)*(Clip),YRES(485),0,0,(1-Clip),1);
			surface.SetColor(AmmoColor(Clip,Difference2)[0],AmmoColor(Clip,Difference2)[1],AmmoColor(Clip,Difference2)[2], Difference2)
			surface.DrawTexturedSubRect(startx,YRES(485)-YRES(150),endx-YRES(150)*(Clip),YRES(485),0,0,(1-Clip),1);
			//if (WeaponName.find("dual")!=null) surface.DrawTexturedSubRect(startx-YRES(5),YRES(485)-YRES(145),endx-YRES(150)*(Clip),YRES(485),0,0,(1-Clip),1);
			
			local AmmoReserveX=XRES(640)-YRES(80)
			
			
			if (player.GetActiveWeapon().GetClassname()!="weapon_frag"&&player.GetActiveWeapon().GetClassname()!="weapon_rpg") {
				
			if (ReserveAmmo>0)
			{
				surface.DrawColoredText(surface.GetFont( "Smol", true ),AmmoReserveX+YRES(2),YRES(442),5,5,5,125,ReserveAmmo.tostring())			
				surface.DrawColoredText(surface.GetFont( "Smolss", true ),AmmoReserveX,YRES(442),25,225,255,25,ReserveAmmo.tostring())
				surface.DrawColoredText(surface.GetFont( "Smolss", true ),AmmoReserveX,YRES(439),25,25,25,255,ReserveAmmo.tostring())
				surface.DrawColoredText(surface.GetFont( "Smol", true ),AmmoReserveX,YRES(442),0,175,255,255,ReserveAmmo.tostring())
			}
			local AmmoOffset=surface.GetTextWidth(surface.GetFont( "A", true ),"1111".slice(0,Ammo.tostring().len()))
			
			local AmmoX=XRES(640)-YRES(105)
			
			if (Ammo>0)
			{
				surface.DrawColoredText(surface.GetFont( "A", true ),AmmoX+YRES(2)-AmmoOffset,YRES(425),5,5,5,125,Ammo.tostring())
				surface.DrawColoredText(surface.GetFont( "Ass", true ),AmmoX-AmmoOffset,YRES(425),25,225,255,25,Ammo.tostring())
				surface.DrawColoredText(surface.GetFont( "Ass", true ),AmmoX-AmmoOffset,YRES(423),25,25,25,255,Ammo.tostring())
				surface.DrawColoredText(surface.GetFont( "Ass", true ),AmmoX-AmmoOffset,YRES(423),25,25,25,255,Ammo.tostring())
				surface.DrawColoredText(surface.GetFont( "A", true ),AmmoX-AmmoOffset,YRES(425),0,175,255,255,Ammo.tostring())
			}
			else
			{
				surface.DrawColoredText(surface.GetFont( "A", true ),AmmoX+YRES(2)-AmmoOffset,YRES(425),5,5,5,125,Ammo.tostring())
				surface.DrawColoredText(surface.GetFont( "Ass", true ),AmmoX-AmmoOffset,YRES(425),255,75-70*sin(Time()*6),75-70*sin(Time()*6),25,Ammo.tostring())
				surface.DrawColoredText(surface.GetFont( "Ass", true ),AmmoX-AmmoOffset,YRES(423),25,25,25,255,Ammo.tostring())
				surface.DrawColoredText(surface.GetFont( "Ass", true ),AmmoX-AmmoOffset,YRES(423),25,25,25,255,Ammo.tostring())
				surface.DrawColoredText(surface.GetFont( "A", true ),AmmoX-AmmoOffset,YRES(425),205-25*sin(Time()*6),75-70*sin(Time()*6),75-70*sin(Time()*6),255,Ammo.tostring())
			}
			local Ammo2=player.GetAmmoCount(player.GetActiveWeapon().GetSecondaryAmmoType())
			
			local AmmoTall=surface.GetFontTall(surface.GetFont( "A", true ))+YRES(6)
			local AmmoWidth=surface.GetTextWidth(surface.GetFont( "A", true ),"35")/2+surface.GetTextWidth(surface.GetFont( "VerySmol", true ),Ammo2.tostring())
			
			
			if (Ammo2>0)
			{
				surface.DrawColoredText(surface.GetFont( "VerySmol", true ),AmmoX+YRES(2)-XRES(10)+YRES(38),YRES(415)+AmmoTall,5,5,5,125,"x"+Ammo2.tostring())
				surface.DrawColoredText(surface.GetFont( "VerySmolShadow", true ),AmmoX-XRES(10)+YRES(38),YRES(415)+AmmoTall,15,255,122,25,"x"+Ammo2.tostring())
				surface.DrawColoredText(surface.GetFont( "VerySmolShadow", true ),AmmoX-XRES(10)+YRES(38),YRES(413)+AmmoTall,25,25,25,255,"x"+Ammo2.tostring())
				surface.DrawColoredText(surface.GetFont( "VerySmolShadow", true ),AmmoX-XRES(10)*(Ammo.tostring().len()-1)+YRES(38),YRES(413)+AmmoTall,25,25,25,255,"x"+Ammo2.tostring())
				surface.DrawColoredText(surface.GetFont( "VerySmol", true ),AmmoX-XRES(10)+YRES(38),YRES(415)+AmmoTall,15,255,122,255,"x"+Ammo2.tostring())
			}
			
			}
			if (player.GetActiveWeapon().GetClassname()=="weapon_frag"||player.GetActiveWeapon().GetClassname()=="weapon_rpg") {
				surface.DrawColoredText(surface.GetFont( "A", true ),AmmoX+YRES(12),YRES(430),5,5,5,125,ReserveAmmo.tostring())			
				surface.DrawColoredText(surface.GetFont( "Ass", true ),AmmoX+YRES(10),YRES(430),25,225,255,25,ReserveAmmo.tostring())
				surface.DrawColoredText(surface.GetFont( "Ass", true ),AmmoX+YRES(10),YRES(431),25,25,25,255,ReserveAmmo.tostring())
				surface.DrawColoredText(surface.GetFont( "A", true ),AmmoX+YRES(10),YRES(430),0,175,255,255,ReserveAmmo.tostring())
			}
			
			local AmmoWidth=surface.GetTextWidth(surface.GetFont( "A", true ),"35")/2+surface.GetTextWidth(surface.GetFont( "VerySmol", true ),Ammo2.tostring())
			
			local ammosymbol=""
			local ammosymbol2=""
			agap<-0;
			local Ammo2=player.GetAmmoCount(player.GetActiveWeapon().GetSecondaryAmmoType())
			//switch (player.GetActiveWeapon().GetClassname())
			//{
			//	case "weapon_crossbow":ammosymbol="w";agap=XRES(5);break
			//	case "weapon_pistol":ammosymbol="p";break
			//	case "weapon_shotgun":ammosymbol="s";break
			//	case "weapon_357":ammosymbol="q";agap=XRES(1);break
			//	case "weapon_ar2":ammosymbol="u";ammosymbol2="z";break
			//	case "weapon_smg1":ammosymbol="r";ammosymbol2="t";agap=XRES(3);break
			//	case "weapon_rpg":ammosymbol="x";agap=XRES(5);break
			//}
			//surface.DrawColoredText(59,XRES(616)-XRES(10)-agap,YRES(435),5,5,5,125,ammosymbol)
			//surface.DrawColoredText(59,XRES(614)-XRES(10)-agap,YRES(437),0,175,255,255,ammosymbol)
			
			local AmmoTallPrimary=surface.GetFontTall(surface.GetFont( "A", true ))
			local AmmoTall=surface.GetFontTall(surface.GetFont( "A", true ))/5.0
			/*
			if (Ammo2>0)
			{
				surface.DrawColoredText(surface.GetFont( "SmolIcons", true ),XRES(545)-XRES(10)+AmmoWidth-YRES(8),YRES(415)+AmmoTallPrimary,5,5,5,125,ammosymbol2)
				surface.DrawColoredText(surface.GetFont( "SmolIcons", true ),XRES(545)-XRES(10)+AmmoWidth-YRES(8),YRES(417)+AmmoTallPrimary,15,255,122,255,ammosymbol2)
			}
			*/
		}
		
		
		//surface.SetTexture(AmmoBG)
		//surface.SetColor(255,255,255,255)
		//surface.DrawTexturedSubRect(YRES(10),YRES(480)-YRES(100),YRES(100),YRES(470),1,0,0,1)
		
		
		
		/*for (local i=1;i<=clamp(122-pow(Time()*2,1),0,count+1);i+=1)
		{
			angle<-(360/count*i)*PI/180
			dangle<-angle/i
			surface.SetColor(255/i,255,255, 255/i)
			//surface.DrawLine(XRES(320),YRES(240),XRES(320)+cos(angle)*100,YRES(240)+sin(angle)*100)
			for (local radius=1;radius<=10;radius+=1)
			{
				surface.DrawLine(XRES(320)+cos(angle)*(100+radius),YRES(240)+sin(angle)*(100+radius),XRES(320)+cos(angle+dangle)*(100+radius),YRES(240)+sin(angle+dangle)*(100+radius))
			}
		}*/
		
		

		local hp_player=player.GetHealth()*1.0/PlayerMaxHealth*1.0
		
		if (!Initted) GetArmor();
		
		
		if (hp<hp_player) hp=min(hp+0.1,hp_player);
		if (hp>hp_player) hp=max(hp_player,hp-0.002);
		
		//////////////////////////
		//  FLASHLIGHT DISPLAY  //
		//////////////////////////
		
		local MainColor=Vector(15,180,255)
		local PowerColor=Vector(255,240,25)
		
		local L=YRES(1)
		
		local FlashX=YRES(135)
		local FlashY=YRES(460)
		
		local FlashLen=YRES(10)
		
		
		Entities.First().SetContextThink("flashlightspin",function(...)
		{
			if (FrameTime()==0) return 0.0
			
			FlashLightOffsetRange <- 5;
			OffsetMoveRate <- 0.1;
			FlashLightOffsetWHrate <- 1.8;
			
			local OffsetValue = MainViewAngles() - LastPlrAng;
			if(OffsetValue.y > 180)
				OffsetValue = Vector(OffsetValue.x,OffsetValue.y-360.00,OffsetValue.z)
			if(OffsetValue.y < -180)
				OffsetValue = Vector(OffsetValue.x,OffsetValue.y+360.00,OffsetValue.z)
			PlrAngOffset = PlrAngOffset+ OffsetValue * OffsetMoveRate;
			PlrAngOffset*=(clamp(1-(Time()-LastMoveTime)*0.5*66*FrameTime(),0,1))
			
			if(PlrAngOffset.x > FlashLightOffsetRange)
				PlrAngOffset = Vector(FlashLightOffsetRange, PlrAngOffset.y, PlrAngOffset.z);
			if(PlrAngOffset.x < -FlashLightOffsetRange)
				PlrAngOffset = Vector(-FlashLightOffsetRange, PlrAngOffset.y, PlrAngOffset.z);
			if(PlrAngOffset.y > FlashLightOffsetRange*FlashLightOffsetWHrate)
				PlrAngOffset = Vector(PlrAngOffset.x, FlashLightOffsetRange*FlashLightOffsetWHrate, PlrAngOffset.z);
			if(PlrAngOffset.y < -FlashLightOffsetRange*FlashLightOffsetWHrate)
				PlrAngOffset = Vector(PlrAngOffset.x, -FlashLightOffsetRange*FlashLightOffsetWHrate, PlrAngOffset.z);
			if(PlrAngOffset.z > FlashLightOffsetRange)
				PlrAngOffset = Vector(PlrAngOffset.x, PlrAngOffset.y, FlashLightOffsetRange);
			if(PlrAngOffset.z < -FlashLightOffsetRange)
				PlrAngOffset = Vector(PlrAngOffset.x, PlrAngOffset.y, -FlashLightOffsetRange);
			if ((LastPlrAng-MainViewAngles()).Length()>1) LastMoveTime=Time();
			
			local MyFlashLight=Entities.FindByName(null,"playerflashlight")
			local MyFlashLight2=Entities.FindByName(MyFlashLight,"playerflashlight")
			local MyFlashLightSprite=null
			
			if (!MyFlashLight) return 0.0
			if (!MyFlashLight2) return 0.0
				
			//local vel=player.GetVelocity().Length()*0.1
			
			local vel=(MainViewOrigin()-PrevMainViewOrigin()).Length()/FrameTime()*0.1
			
			vel=sqrt(vel)+0.9
			veltime+=FrameTime()*vel*1.5
			local bob=Vector(fabs(sin(veltime)+0.2)*vel*0.4,cos(veltime*0.8)*vel*0.3,sin(Time()*0.5)*5+cos(veltime)*vel*0.5)
			
			bob=VMBobAngles+Vector(-0.5,-1,0)
			
			//printl(bob)
			
			
			MyFlashLight.SetLocalOrigin(MainViewOrigin()+Vector(0,0,-8)-MainViewForward()*12);
			//MyFlashLight.SetTransmitState(8)
			MyFlashLight.SetLocalAngles(MainViewAngles()+PlrAngOffset+bob);
			MyFlashLight2.SetLocalOrigin(MainViewOrigin()+Vector(0,0,-8)-MainViewForward()*12);
			MyFlashLight2.SetLocalAngles(MainViewAngles()+PlrAngOffset+bob);
			
			while (MyFlashLightSprite=Entities.FindByName(MyFlashLightSprite,"playerflashlight"))
			{
				if (MyFlashLightSprite.GetClassname()=="env_sprite")
				{
					MyFlashLightSprite.SetRenderAlpha(0)
					break
				}
			}
			
			if (Entities.FindByName(null,"PlayerModel"))
			{
				//printl(PlayerFlashlight)
				local ply=Entities.FindByName(null,"PlayerModel")
				local attach=ply.LookupAttachment("chest")
				local p=ply.GetAttachmentOrigin(attach)
				local a=ply.GetAttachmentAngles(attach)
				
				MyFlashLight.SetLocalOrigin(p);
				MyFlashLight.SetLocalAngles(a);

				MyFlashLightSprite.SetLocalOrigin(p+AngleVectors(a)*5+AngleVectors(a+Vector(0,-90,0))*3+AngleVectors(a+Vector(-90,0,0))*3);
				MyFlashLightSprite.SetLocalAngles(a);
				if (PlayerFlashlight) MyFlashLightSprite.SetRenderAlpha(200)
				else MyFlashLightSprite.SetRenderAlpha(0)
			}
			
			
			LastPlrAng = MainViewAngles()
			
			return 0.0
		},0.0)
		
		local flashmod=RemapValClamped(PlayerFlashlightBattery,0,20,0.25,1)
		
		if (PlayerFlashlightBattery<100)
		{
			surface.SetColorVec(MainColor,155+100*PlayerFlashlight.tointeger())
			surface.DrawFilledRect(FlashX,FlashY,L,YRES(4))
			surface.DrawFilledRect(FlashX+YRES(14)+YRES(4)+L*2,FlashY-L,L,YRES(4)+L*2)
			surface.DrawFilledRect(FlashX+L,FlashY-L,YRES(14),L)
			surface.DrawFilledRect(FlashX+L+YRES(14),FlashY-L*2,YRES(5),L)
			surface.DrawFilledRect(FlashX+L,FlashY+YRES(4),YRES(14),L)
			surface.DrawFilledRect(FlashX+L+YRES(14),FlashY+YRES(4)+L,YRES(5),L)
			
			surface.SetColorVec(PowerColor,155+100*PlayerFlashlight.tointeger())
			if (PlayerFlashlight&&!(PlayerFlashlightBattery<10&&RandomFloat(0,10-PlayerFlashlightBattery)>2)) for (local i=0;i<7;i++)
			{
				
					local y=sin(((Time()*2)-i*0.35))
					local x=cos(((Time()*2)-i*0.35))
					surface.SetColorVec(PowerColor,clamp(255*flashmod-i*29+x*50,0,255))
					surface.DrawLine(FlashX+L+YRES(14)+YRES(5)+L, FlashY+YRES(4)/2.0+(YRES(4)/2.0+L)*y, FlashX+L+YRES(14)+YRES(5)+FlashLen+x*L, FlashY+YRES(4)/2.0+(YRES(7)/2.0+L)*y)
			}
			
			for(local i=0;i<6;i++)
			{
				local Thick=YRES(2)
				local BarFill=RemapValClamped(PlayerFlashlightBattery,16.66*i,16.66*(i+1),0,1)
				
				
				surface.SetColorVec(PowerColor*0.1,155+100*PlayerFlashlight.tointeger())
				surface.DrawFilledRect(FlashX+L*2+Thick*i,(FlashY+L+0.5).tointeger(),Thick/2.0,((YRES(4)-L*2)+0.5).tointeger())
				
				if (PlayerFlashlightBattery<16.66*2) PowerColor.y=0
				if (PlayerFlashlightBattery<16.66*2) PowerColor.z=0
				
				surface.SetColorVec(PowerColor,155+100*PlayerFlashlight.tointeger())
				surface.DrawFilledRect(FlashX+L*2+Thick*i,(FlashY+L+(YRES(4)-L*2)*(1.0-BarFill)+0.5).tointeger(),Thick/2.0,((YRES(4)-L*2)*BarFill+0.5).tointeger())
			}
		}
		//////////////////////////
		
		if (!("SW_CL_StaminaFullTime" in getroottable()))
			::SW_CL_StaminaFullTime<-(-1);
		if (!("SW_CL_StaminaDisplayTime" in getroottable()))
			::SW_CL_StaminaDisplayTime<-(-1);
		if (!("SW_CL_StaminaOut" in getroottable()))
			::SW_CL_StaminaOut<-0;
		
		
			
		if (PlayerStamina<10) SW_CL_StaminaOut=clamp(SW_CL_StaminaOut+FrameTime()*10,0,1);
		else SW_CL_StaminaOut=clamp(SW_CL_StaminaOut-FrameTime()*10,0,1);
		
		if (PlayerStamina!=LastPlayerStamina) SW_CL_StaminaFullTime=Time();
		else SW_CL_StaminaDisplayTime=Time();
		
		
		if (PlayerStamina!=100) LastPlayerStamina+=(PlayerStamina-LastPlayerStamina)*FrameTime()*5
		else LastPlayerStamina=PlayerStamina
		
		///////////////////////
		//  STAMINA DISPLAY  //
		///////////////////////
		
		local AlphaMod=1
		
		if (PlayerStamina<100) AlphaMod=pow(clamp((Time()-SW_CL_StaminaDisplayTime)*2,0,1),0.5);
		else AlphaMod=1-clamp((Time()-SW_CL_StaminaFullTime)*3,0,1);
		
		
		local AUXWidth=YRES(175)
		local AUXThickness=YRES(6)
		
		local AUX_Y=YRES(460)
		
		local v_thick=((YRES(20)*(1-PlayerStamina/10.0)+0.5)*SW_CL_StaminaOut).tointeger()
		
		if (SW_HUDPlayerWeapon&&(SW_HUDPlayerWeapon in LIST_ITEMS)&&"displaystamina" in LIST_ITEMS[SW_HUDPlayerWeapon]&&LIST_ITEMS[SW_HUDPlayerWeapon].displaystamina)
		{
			AUXWidth=YRES(175)
			AUXThickness=YRES(7)
			AUX_Y=YRES(350)
			AUXThickness*=AlphaMod;
			AlphaMod=clamp(AlphaMod,0,0.8)
		}
		else 
		{
			AUXThickness*=AlphaMod;
			AlphaMod=clamp(AlphaMod,0,0.6);
		}
		
		if (PlayerStamina<10)
		{
			surface.SetColor(0,0,0,255)
			surface.DrawFilledRectFade(0,0,v_thick,YRES(480),255,0,true)
			surface.DrawFilledRectFade(0,0,XRES(640),v_thick,255,0,false)
			surface.DrawFilledRectFade(XRES(640)-v_thick,0,v_thick,YRES(480),0,255,true)
			surface.DrawFilledRectFade(0,YRES(480)-v_thick,XRES(640),v_thick,0,255,false)
		}
		
		
		local MainColor=Vector(15,180,255)
		local MainColorRed=Vector(235,35,35)
		
		local DrainColor=Vector(215,230,255)
		
		local ColorMod=RemapValClamped(PlayerStamina,15,35,0,1)
		local StaminaColor=MainColor*(ColorMod)+MainColorRed*(1-ColorMod)
		
		

		surface.SetColorVec(StaminaColor*0.25,195*AlphaMod)
		surface.DrawFilledRect(XRES(320)-AUXWidth/2,AUX_Y,AUXWidth,AUXThickness)
		
		surface.SetColorVec(DrainColor,255*AlphaMod)
		surface.DrawFilledRectFade(XRES(320)-AUXWidth/2+AUXWidth*PlayerStamina/100.0,AUX_Y,AUXWidth*(LastPlayerStamina-PlayerStamina)/100.0,AUXThickness,230-125*ColorMod,10,true)
		
		surface.SetColor(0,0,0,135*AlphaMod)
		for (local i=5;i<100;i+=5)
		{
			surface.DrawFilledRect(XRES(320)-AUXWidth/2+AUXWidth*(0.01*i)-YRES(2)/2,AUX_Y,YRES(2),AUXThickness)
		}
		
		surface.SetColorVec(StaminaColor,255*AlphaMod)
		surface.DrawFilledRect(XRES(320)-AUXWidth/2,AUX_Y,AUXWidth*PlayerStamina/100.0,AUXThickness)
		
		surface.SetColor(0,0,0,215*pow(AlphaMod,0.25))
		surface.DrawOutlinedRect(XRES(320)-AUXWidth/2,AUX_Y,AUXWidth,AUXThickness,YRES(2))
		surface.SetColor(0,0,0,255*pow(AlphaMod,0.25))
		surface.DrawOutlinedRect(XRES(320)-AUXWidth/2,AUX_Y,AUXWidth,AUXThickness,YRES(1))
		
		
		local DrainScale=sqrt(abs(PlayerStamina-LastPlayerStamina))/2.0
		
		local PlayerStamina=clamp(PlayerStamina,1,100)
		
		surface.SetColorVec(StaminaColor,255*AlphaMod*DrainScale)
		surface.SetTexture(surface.ValidateTexture("vgui/glow",true,false,false))
		surface.DrawTexturedRect(XRES(320)-AUXWidth/2+AUXWidth*PlayerStamina/100.0-YRES(9)/2,AUX_Y+AUXThickness/2.0-AUXThickness*DrainScale*1.5,YRES(9),AUXThickness*3*DrainScale)
		surface.DrawTexturedRect(XRES(320)-AUXWidth/2+AUXWidth*PlayerStamina/100.0-YRES(9)/2,AUX_Y+AUXThickness/2.0-AUXThickness*DrainScale*1.5,YRES(9),AUXThickness*3*DrainScale)
		
		//////////////////////////
		
		//
		// HEALTH
		//
		
		local HP=hp_player
		//HP=(Time()*0.2-(Time()*0.2).tointeger())
		
		
		surface.SetColor(0,0,0,255)
		surface.DrawFilledRectFade(YRES(10),YRES(480)-YRES(93),YRES(80),YRES(80),0,230,false)
		
		
		
		local IHP=1-HP
		
		local HP_R=RemapVal(HP,0,1,0.2,1)//+0.004*sin(Time()*2)
		//local HP_R=RemapVal(HP,0,1,0,0.8)//+0.004*sin(Time()*2)
		
		local dmg=1
		
		local HP_C_Desired=Vector(51,155,179)
		if (HP<0.6) 
		{
			HP_C_Desired=Vector(190,180,30)
		}
		if (HP<0.4)
		{
			HP_C_Desired=Vector(255,100,0)
		}
		if (HP<0.2) 
		{
			HP_C_Desired=Vector(255,0,0)
		}
		
		
		if (HP<0.5) 
		{
			dmg=2
		}
		if (HP<0.3)
		{
			dmg=3
		}
		if (HP<0.1) 
		{
			dmg=4
		}
		local bpm=130.0
			
		local period = 100.0 / bpm
		local phase = (clamp(Time()-HeartBeat+0.25,0,1) % period) / period
		
		local p1 = pow(sin(PI * phase), 10) 
		if ((phase < 0.5)) p1=0
		local p2 = 0.5 * pow(sin(PI * (phase - 0.2)), 10)
		if (((0.2 < phase)&&(phase < 0.5))) p2=0;
		
		HEART=max(p1, p2)
		
		//surface.SetColor(255,255,255,255)
		//surface.DrawFilledRect(0,0,YRES(100)*HEART,YRES(40))
		
		//printl(HEART)
		
		if (RageActive) IHP=max(IHP,0.9)
			
		
		if (PreviousHealthColor.x<HP_C_Desired.x) PreviousHealthColor.x=min(PreviousHealthColor.x+4,HP_C_Desired.x)
		if (PreviousHealthColor.x>HP_C_Desired.x) PreviousHealthColor.x=max(PreviousHealthColor.x-4,HP_C_Desired.x)
		if (PreviousHealthColor.y<HP_C_Desired.y) PreviousHealthColor.y=min(PreviousHealthColor.y+4,HP_C_Desired.y)
		if (PreviousHealthColor.y>HP_C_Desired.y) PreviousHealthColor.y=max(PreviousHealthColor.y-4,HP_C_Desired.y)
		if (PreviousHealthColor.z<HP_C_Desired.z) PreviousHealthColor.z=min(PreviousHealthColor.z+4,HP_C_Desired.z)
		if (PreviousHealthColor.z>HP_C_Desired.z) PreviousHealthColor.z=max(PreviousHealthColor.z-4,HP_C_Desired.z)
			
		
			
		local HP_C=PreviousHealthColor
		//surface.DrawColoredText(2,YRES(95),YRES(455),25,100,255,255,(HP*100).tointeger().tostring()+"%")
		//printl(hp_player-hp)
		local xoffset=YRES(RandomInt(-5,5))*sqrt(fabs(hp_player-hp))+YRES(10)
		local yoffset=YRES(RandomInt(-5,5))*sqrt(fabs(hp_player-hp))+YRES(20)
		
		surface.SetTexture(surface.ValidateTexture("vgui/health/health",true,false,false))
		surface.SetColor(HP_C.x,HP_C.y,HP_C.z, 255)
		
		surface.DrawTexturedSubRect(xoffset,YRES(480)-size-yoffset,xoffset+size,YRES(480)-yoffset-size*(1-HP_R),0,0,1,HP_R)
		//surface.DrawTexturedSubRect(xoffset,YRES(480)-size-yoffset+size*(1-HP_R),xoffset+size,YRES(480)-yoffset,0,1-HP_R,1,1)
		
		xoffset=YRES(RandomInt(-5,5))*sqrt(fabs(hp_player-hp))+YRES(10)
		yoffset=YRES(RandomInt(-5,5))*sqrt(fabs(hp_player-hp))+YRES(20)
		
		surface.SetTexture(surface.ValidateTexture("vgui/health/health_glow",true,false,false))
		surface.SetColor(HP_C.x,HP_C.y,HP_C.z, 155*IHP*IHP)
		
		surface.DrawTexturedSubRect(xoffset,YRES(480)-size-yoffset,xoffset+size,YRES(480)-yoffset-size*(1-HP_R),0,0,1,HP_R)
		//surface.DrawTexturedSubRect(xoffset,YRES(480)-size-yoffset+size*(1-HP_R),xoffset+size,YRES(480)-yoffset,0,1-HP_R,1,1)
		
		xoffset=YRES(RandomInt(-5,5))*sqrt(fabs(hp_player-hp))+YRES(10)
		yoffset=YRES(RandomInt(-5,5))*sqrt(fabs(hp_player-hp))+YRES(20)
		
		surface.SetColor(HP_C.x,HP_C.y,HP_C.z, HEART*255*pow(IHP,4))
		
		surface.DrawTexturedSubRect(xoffset,YRES(480)-size-yoffset,xoffset+size,YRES(480)-yoffset-size*(1-HP_R),0,0,1,HP_R)

		surface.SetColor(HP_C.x,HP_C.y,HP_C.z, HEART*200*pow(IHP,10)+14)
		surface.DrawTexturedSubRect(xoffset,YRES(480)-size-yoffset,xoffset+size,YRES(480)-yoffset,0,0,1,1)
		
		xoffset=YRES(RandomInt(-5,5))*sqrt(fabs(hp_player-hp))+YRES(10)
		yoffset=YRES(RandomInt(-5,5))*sqrt(fabs(hp_player-hp))+YRES(20)
		
		if (Time()-LastHurtTime<0.12)
		{
			surface.SetColor(255,25,25, (1-(Time()-LastHurtTime)*10)*255)
			surface.DrawTexturedSubRect(xoffset,YRES(480)-size-yoffset,xoffset+size,YRES(480)-yoffset,0,0,1,1)
		}
		
		surface.SetTexture(surface.ValidateTexture("vgui/health/health_damage"+dmg,true,false,false))
		surface.SetColor(125,125,125, 255)
		
		surface.DrawTexturedSubRect(xoffset,YRES(480)-size*(1-HP_R)-yoffset,xoffset+size,YRES(480)-yoffset,0,HP_R,1,1)
		//surface.DrawTexturedSubRect(xoffset,YRES(480)-size-yoffset,xoffset+size,YRES(480)-yoffset-size+size*(1-HP_R),0,0,1,1-HP_R)
		
		
		local y=YRES(480)-size*(1-HP_R)*RandomFloat(0,1)-YRES(20)
		local x=RandomInt(YRES(15),YRES(10)+size/2-YRES(20))
		local wide=YRES(RandomInt(5,25))
		if (pow(RandomFloat(0,1),0.25)<IHP)
		{
			surface.DrawLine(x,y,x+wide,y)
			surface.DrawLine(x,y+1,x+wide,y+1)
		}
		if (pow(RandomFloat(0,1),0.25)<IHP*IHP) surface.DrawLine(x,y+2,x+wide,y+2)
		
		/*
		
		surface.SetTexture(HPHud)
		surface.SetColor(255,255,255, 255)
		surface.DrawTexturedRect(30,panel.GetTall()-size*1.2,size,size)
		
		//local hp=fabs(sin(Time()))
		if (player.GetHealth()>PlayerMaxHealth)
		{
			local hp=0.8-(hp-0.8)
			surface.SetTexture(ArmorHud)
			surface.SetColor(255,125,0, 255)
			surface.DrawTexturedSubRect(30,panel.GetTall()-size*1.2+size*(hp+0.2),size+30,size+panel.GetTall()-size*1.2,0,0.2+hp,1,1)
			surface.DrawTexturedSubRect(30,panel.GetTall()-size*1.2+size*(hp+0.2),size+30,size+panel.GetTall()-size*1.2,0,0.2+hp,1,1)
			surface.DrawTexturedSubRect(30,panel.GetTall()-size*1.2+size*(hp+0.2),size+30,size+panel.GetTall()-size*1.2,0,0.2+hp,1,1)
		}
		
		surface.SetTexture(HPHudDamaged2)
		surface.SetColor(195,195,195, 210)
		surface.DrawTexturedSubRect(30,panel.GetTall()-size*1.2+size*(hp+0.2),size+30,size+panel.GetTall()-size*1.2,0,0.2+hp,1,1)
		surface.DrawTexturedSubRect(30,panel.GetTall()-size*1.2+size*(hp_player+0.2),size+30,size+panel.GetTall()-size*1.2,0,0.2+hp_player,1,1)
		surface.DrawTexturedSubRect(30,panel.GetTall()-size*1.2+size*(hp_player+0.2),size+30,size+panel.GetTall()-size*1.2,0,0.2+hp_player,1,1)
		
		surface.SetColor(5,5,5, 210)
		surface.SetTexture(HPHudDamaged)
		surface.DrawTexturedSubRect(30,panel.GetTall()-size*1.2+size*(hp+0.2),size+30,size+panel.GetTall()-size*1.2,0,0.2+hp,1,1)
		surface.DrawTexturedSubRect(30,panel.GetTall()-size*1.2+size*(hp_player+0.2),size+30,size+panel.GetTall()-size*1.2,0,0.2+hp_player,1,1)
		surface.DrawTexturedSubRect(30,panel.GetTall()-size*1.2+size*(hp_player+0.2),size+30,size+panel.GetTall()-size*1.2,0,0.2+hp_player,1,1)
		surface.DrawTexturedSubRect(30,panel.GetTall()-size*1.2+size*(hp_player+0.2),size+30,size+panel.GetTall()-size*1.2,0,0.2+hp_player,1,1)
		if ((Time()-LastDmgTime)<0.3)
		{
			surface.SetColor(255,255,255, 255-((Time()-LastDmgTime)*3*255)%255)
			surface.DrawTexturedSubRect(30,panel.GetTall()-size*1.2+size*(0),size+30,size+panel.GetTall()-size*1.2,0,0,1,1)
			surface.DrawTexturedSubRect(30,panel.GetTall()-size*1.2+size*(0),size+30,size+panel.GetTall()-size*1.2,0,0,1,1)
		}
		
		if ((Time()-LastHurtTime)<0.3)
		{
			local dmgalpha=DamageBlock ? 165 : 240
			surface.SetColor(255,255*DamageBlock.tointeger(),255*DamageBlock.tointeger(), dmgalpha-((Time()-LastHurtTime)*3*dmgalpha)%dmgalpha)
			surface.SetTexture(DamageIndicator)
			//printl(abs(DamageAngle)%360>90&&abs(DamageAngle)%360>270)
			if (abs(DamageAngle)%360>90&&abs(DamageAngle)%360<270) surface.DrawTexturedRectRotated(ScreenWidth()/2-YRES(140)-cos((DamageAngle-90)/180.0*PI)*YRES(140),ScreenHeight()/2-YRES(140)+sin(((DamageAngle-90)/180.0*PI))*YRES(140),YRES(140)*2,YRES(140)*2,DamageAngle-180)
		}
		
		surface.SetTexture(ArmorHud)
		surface.SetColor(255,255,255, 255)
		surface.DrawTexturedSubRect(30,panel.GetTall()-size*1.2+size*(armor),size+30,size+panel.GetTall()-size*1.2,0,armor,1,1)
		surface.DrawTexturedSubRect(30,panel.GetTall()-size*1.2+size*(armor),size+30,size+panel.GetTall()-size*1.2,0,armor,1,1)
		if ((Time()-LastDmgTime)<0.3)
		{
			surface.SetColor(255,14,2, 255-((Time()-LastDmgTime)*3*255)%255)
			surface.DrawTexturedSubRect(30,panel.GetTall()-size*1.2+size*(0),size+30,size+panel.GetTall()-size*1.2,0,0,1,1)
			surface.DrawTexturedSubRect(30,panel.GetTall()-size*1.2+size*(0),size+30,size+panel.GetTall()-size*1.2,0,0,1,1)
		}
		
		*/
		
		// PLAYER DAMAGE INDICATOR
		if ((Time()-LastHurtTime)<Dmg||(Time()-LastBlockTime)<Dmg)
		{
			local DamageAngle=DamageAngle-MainViewAngles().y
			
			local dmgalpha=DamageBlock ? 165 : clamp(255*Dmg+40,0,255)
			
			if (!(abs(DamageAngle)%360>60&&abs(DamageAngle)%360<300)) dmgalpha*=0.05
			
			surface.SetColor(255,255*DamageBlock.tointeger(),255*DamageBlock.tointeger(), clamp(pow(-Time()+LastHurtTime+Dmg,10),0,1)*dmgalpha)
			if (DamageBlock) surface.SetColor(255,255*DamageBlock.tointeger(),255*DamageBlock.tointeger(), clamp(pow(-Time()+LastBlockTime+Dmg,10),0,1)*dmgalpha);
			surface.SetTexture(DamageIndicator)
			
			local offx=YRES(dmgalpha*RandomFloat(-0.02,0.02)*Dmg)
			local offy=YRES(dmgalpha*RandomFloat(-0.02,0.02)*Dmg)
			
			local size=YRES(100)*clamp(Dmg,1,2)
			
			//printl("Damage "+Dmg)
			
			surface.DrawTexturedRectRotated(offx+ScreenWidth()/2-size-cos((DamageAngle-90)/180.0*PI)*size*0.5,offy+ScreenHeight()/2-size+sin(((DamageAngle-90)/180.0*PI))*size*0.5,size*2,size*2,DamageAngle-180)
			surface.DrawTexturedRectRotated(offx+ScreenWidth()/2-size-cos((DamageAngle-90)/180.0*PI)*size*0.5,offy+ScreenHeight()/2-size+sin(((DamageAngle-90)/180.0*PI))*size*0.5,size*2,size*2,DamageAngle-180)
			
			surface.SetColor(255,255*DamageBlock.tointeger(),255*DamageBlock.tointeger(), clamp(pow(1-Time()+LastHurtTime,15),0,1)*dmgalpha)
			surface.DrawTexturedRectRotated(offx+ScreenWidth()/2-size-cos((DamageAngle-90)/180.0*PI)*size*0.5,offy+ScreenHeight()/2-size+sin(((DamageAngle-90)/180.0*PI))*size*0.5,size*2,size*2,DamageAngle-180)
			surface.DrawTexturedRectRotated(offx+ScreenWidth()/2-size-cos((DamageAngle-90)/180.0*PI)*size*0.5,offy+ScreenHeight()/2-size+sin(((DamageAngle-90)/180.0*PI))*size*0.5,size*2,size*2,DamageAngle-180)
		}
		
		///////////////

		local xoffset=YRES(4)
		local yoffset=-YRES(220)
		local margin=2
		local Level=((1+0.07*sqrt(PlayerExperience)).tointeger()).tostring()
		//PlayerExperience+=*Level.tointeger()
		local NeedXP=pow(((Level.tointeger())*(1/0.07)),2).tointeger()-pow(((Level.tointeger()-1)*(1/0.07)),2).tointeger()
		local RealNeedXP=pow(((Level.tointeger())*(1/0.07)),2).tointeger()-PlayerExperience
		//surface.DrawColoredText(95,XRES(14)-XRES(2)*Level.len(),YRES(456),0, 140, 200,255,PlayerExperience.tostring()+"   need "+RealNeedXP)
		//surface.DrawColoredText(35,XRES(10)-XRES(5)*Level.len(),YRES(456),255, 48, 48,255,player.GetHealth().tostring())
		local PlayerExperience=((PlayerExperience-pow(((Level.tointeger()-1)*(1/0.07)),2).tointeger())%NeedXP).tointeger()
		surface.SetColor(20, 20, 20, 255)
		//surface.DrawFilledRect(XRES(10),YRES(467),XRES(1)*60*0.75+YRES(margin)*2,YRES(2+margin*2))
		
		local xpfade=125*fabs(sin(Time()*3))
		
		local XP_X=YRES(13)
		
		local XP_Width=YRES(60)
		
		/*
		
		surface.DrawFilledRectFade(XP_X-YRES(margin),YRES(467),XP_Width+YRES(margin)*2,YRES(2+margin*2)/2,0,255,false)
		surface.DrawFilledRectFade(XP_X-YRES(margin),YRES(467),XP_Width+YRES(margin)*2,YRES(2+margin*2)/2,0,255,false)
		surface.DrawFilledRectFade(XP_X-YRES(margin),YRES(467)+YRES(2+margin*2)/2,XP_Width+YRES(margin)*2,YRES(2+margin*2)/2,255,0,false)
		surface.DrawFilledRectFade(XP_X-YRES(margin),YRES(467)+YRES(2+margin*2)/2,XP_Width+YRES(margin)*2,YRES(2+margin*2)/2,255,0,false)
		//surface.SetColor(90, 215, 90, 255)
		//surface.DrawFilledRectFade(XP_X,YRES(469),(XP_Width/NeedXP),YRES(2),255,255,true)
		//surface.SetColor(22, 160, 215, 255)                                                                    
		//surface.DrawFilledRectFade(XP_X,YRES(469),(XP_Width/NeedXP)/2,YRES(2),255-xpfade,0,true)
		//surface.DrawFilledRectFade(XP_X,YRES(469),(XP_Width/NeedXP)/2,YRES(2),255-xpfade,0,true)
		//surface.DrawFilledRectFade(XP_X+(XP_Width/NeedXP)/2,YRES(469),(XP_Width/NeedXP)/2,YRES(2),0,255-xpfade,true)
		//surface.DrawFilledRectFade(XP_X+(XP_Width/NeedXP)/2,YRES(469),(XP_Width/NeedXP)/2,YRES(2),0,255-xpfade,true)
		
		surface.SetColor(22, 160, 215, (255-xpfade*2)*PlayerExperience/(NeedXP)*0.25)
		surface.DrawFilledRect(XP_X+YRES(PlayerExperience*(60.0/NeedXP)/2),YRES(469),YRES(PlayerExperience*(60.0/NeedXP)/2),YRES(2))
		surface.SetColor(10, 211, 10, 255)                                                                    
		surface.DrawFilledRectFade(XP_X,YRES(469),YRES(PlayerExperience*(60.0/NeedXP)/2),YRES(2),0,255,true)
		surface.DrawFilledRectFade(XP_X+YRES(PlayerExperience*(60.0/NeedXP)/2),YRES(469),YRES(PlayerExperience*(60.0/NeedXP)/2),YRES(2),255,0,true)
		
		surface.DrawColoredText(55,XP_X+(XP_Width)/2-surface.GetTextWidth(55,Level)/2+2,YRES(467)+1,0, 0, 0,255,Level)
		surface.DrawColoredText(55,XP_X+(XP_Width)/2-surface.GetTextWidth(55,Level)/2+1,YRES(467)+1,0, 0, 0,255,Level)
		surface.DrawColoredText(55,XP_X+(XP_Width)/2-surface.GetTextWidth(55,Level)/2-2,YRES(467)+1,0, 0, 0,255,Level)
		surface.DrawColoredText(55,XP_X+(XP_Width)/2-surface.GetTextWidth(55,Level)/2-1,YRES(467)+1,0, 0, 0,255,Level)
		surface.DrawColoredText(55,XP_X+(XP_Width)/2-surface.GetTextWidth(55,Level)/2+2,YRES(467)+2,0, 0, 0,255,Level)
		surface.DrawColoredText(55,XP_X+(XP_Width)/2-surface.GetTextWidth(55,Level)/2+1,YRES(467)+2,0, 0, 0,255,Level)
		surface.DrawColoredText(55,XP_X+(XP_Width)/2-surface.GetTextWidth(55,Level)/2-2,YRES(467)+2,0, 0, 0,255,Level)
		surface.DrawColoredText(55,XP_X+(XP_Width)/2-surface.GetTextWidth(55,Level)/2-1,YRES(467)+2,0, 0, 0,255,Level)
		surface.DrawColoredText(55,XP_X+(XP_Width)/2-surface.GetTextWidth(55,Level)/2,YRES(467),40, 220, 60,255,Level)
		
		*/
		
		if (PlayerHeat>LastHeat) LastHeat+=clamp(2*(PlayerHeat-LastHeat).tointeger()*(PlayerMaxHeat+2-PlayerHeat+LastHeat)+0.5,1,(PlayerHeat-LastHeat))/10;
		if (PlayerHeat<LastHeat) LastHeat+=clamp(2*(PlayerHeat-LastHeat).tointeger()*(PlayerMaxHeat+2-PlayerHeat+LastHeat)-0.5,0,(PlayerHeat-LastHeat))/5;
		
		
		/*
		surface.SetColor(20, 20, 20, 255)
		surface.DrawFilledRect(YRES(78)-YRES(margin),YRES(465-margin)-YRES(75)*(PlayerMaxHeat/100.0),YRES(2+margin*2),YRES(1*100*0.75)*(PlayerMaxHeat/100.0)+YRES(margin*2))
		surface.SetColor(2, 2, 2, 255)
		surface.DrawFilledRect(YRES(78),YRES(465)-YRES(75)*(PlayerMaxHeat/100.0),YRES(2),YRES(75)*(PlayerMaxHeat/100.0))
		surface.SetColor(200, 70, 70, 255)
		surface.DrawFilledRectFade(YRES(78),YRES(465)-YRES(1*LastHeat*0.75),YRES(2),YRES(1*LastHeat*0.75),0,255,false)
		surface.SetColor(255, 15, 15, 255)
		surface.DrawFilledRectFade(YRES(78),YRES(465)-YRES(1*LastHeat*0.75),YRES(2),YRES(1*LastHeat*0.75),255,0,false)
		
		surface.SetColor(20, 20, 20, 225)
		for (local i=1;i<7*(PlayerMaxHeat/100.0)-2*(PlayerMaxHeat/100.0-1);i++)
		{
			if (YRES(465)-YRES(75)*(PlayerMaxHeat/100.0)+YRES(i*77/6-margin)<YRES(425)) surface.DrawFilledRect(YRES(78)-YRES(margin),YRES(465)-YRES(75)*(PlayerMaxHeat/100.0)+YRES(i*77/6-margin),YRES(2+margin*2),YRES(margin))
		}
		
		if (AbilitiesActive)
		{
			surface.SetColor(255, 15, 15, 50+205*fabs(sin(Time()*6)))
			surface.DrawFilledRectFade(YRES(78)+YRES(1),YRES(75)+YRES(390)-YRES(1*LastHeat*0.75),YRES(4),YRES(1*LastHeat*0.75),PlayerMaxHeat-0.65*PlayerHeat,0,true)
			surface.DrawFilledRectFade(YRES(78)-YRES(3),YRES(75)+YRES(390)-YRES(1*LastHeat*0.75),YRES(4),YRES(1*LastHeat*0.75),0,PlayerMaxHeat-0.65*PlayerHeat,true)
		}
		
		if (PlayerHeat>=50)
		{
			surface.SetColor(255, 15, 15, 60+125*fabs(sin(Time()*6)))
			surface.DrawFilledRectFade(YRES(78)+YRES(1),YRES(75)+YRES(390)-YRES(1*LastHeat*0.75),YRES(4),YRES(1*LastHeat*0.75),PlayerMaxHeat-0.65*PlayerHeat,0,true)
			surface.DrawFilledRectFade(YRES(78)-YRES(3),YRES(75)+YRES(390)-YRES(1*LastHeat*0.75),YRES(4),YRES(1*LastHeat*0.75),0,PlayerMaxHeat-0.65*PlayerHeat,true)
		}
		*/
		
		
		//surface.DrawFilledRectFade(YRES(10),YRES(480)-YRES(90),YRES(80),YRES(80),0,230,false)
		
		local HeatX=YRES(10)
		local HeatY=YRES(480)-YRES(13)
		
		local HeatHeight=YRES(1)*6
		
		local HT=(LastHeat/PlayerMaxHeat.tofloat())
		local HTP=(LastHeat/100.0)
		
		local HeatWide=YRES(80)
		local HeatFillHeight=HeatWide*HT
		
		surface.SetTexture(surface.ValidateTexture("vgui/dashed_fill",true,false,false))
		
		local Squares=(HeatFillHeight)/(HeatHeight)
		
		surface.SetColor(200,0,0,255)
		surface.DrawTexturedSubRect(HeatX,HeatY-HeatHeight,HeatX+HeatFillHeight,HeatY,0,0,Squares,1)
		surface.SetColor(64,64,64,255)
		surface.DrawOutlinedRect(HeatX,HeatY-HeatHeight,HeatWide,HeatHeight,YRES(1))
		
		if (HeatFillHeight>0)
		{
			surface.SetColor(255,0,0,55)
			surface.SetTexture(surface.ValidateTexture("vgui/glow_square",true,false,false))
			
			local t=Time()/2.0
			
			surface.DrawTexturedSubRect(HeatX,HeatY-HeatHeight+YRES(1),HeatX+HeatFillHeight,HeatY-YRES(1),t*Squares/3.0,0,t*Squares/3.0+Squares/3.0,1)
			
			surface.SetColor(255,0,0,150+100*fabs(sin(Time())))
			surface.DrawTexturedSubRect(HeatX-YRES(8)*HT,HeatY-HeatHeight-YRES(2),HeatX+HeatFillHeight+YRES(8)*HT,HeatY+YRES(2),0,0,1,1)
			
			
			surface.DrawColoredText(55,HeatX+HeatWide+YRES(1),HeatY-HeatHeight-YRES(1)*2,25,20,20,255,format("%3.i%%",(HTP+0.005)*100))
			surface.DrawColoredText(55,HeatX+HeatWide+YRES(1),HeatY-HeatHeight-YRES(1)*2,25,20,20,255,format("%3.i%%",(HTP+0.005)*100))
			surface.DrawColoredText(55,HeatX+HeatWide,HeatY-HeatHeight-YRES(1),255,20,20,255,format("%3.i%%",(HTP+0.005)*100))
		}
		
		if (PreChangeHealth>player.GetHealth())
		{
			LastDmgTime=Time()
			Dmg=(PreChangeHealth-player.GetHealth())/10.0
		}
		if (PreChangeHealth>player.GetHealth())
		{
			LastHurtTime=Time()
		}
		
		if (PreviousHealth-player.GetHealth()>40)
		{
			LastWoundTime=Time()
		}
		
		if ((Time()-LastDmgTime)<0.3)
		{
			xoffset=5+RandomFloat(-Dmg,Dmg)*fabs(LastDmgTime+0.3-Time())
			yoffset=-440+RandomFloat(-Dmg,Dmg)*fabs(LastDmgTime+0.3-Time())
		}
		
		if (Scale<3.5) for (local i=0;i<640;i+=2)
		{
			surface.SetColor(0,0,0,255)
			
			//local DistMod=XRES(abs(320-i))/2.0
			local DistMod=0
			//surface.DrawFilledRect(XRES(i),0,XRES(2),DistMod+YRES(480)-YRES(480)*(Scale-1.5-(RNGs[i]/2)))
			surface.SetColor(133,133,133,255)
			//local rngmod=RNGs[i]/4.0
			local rngmod=pow(RNGs[i+10]+1,14)
			local offset=clamp((-YRES(480))+clamp(DistMod+YRES(480)+YRES(480)*(Scale-1.5-(rngmod/4.0)),0,9999),0,ScreenHeight())
			
			surface.SetTexture(blackness)
			//if (i==0) surface.DrawTexturedRect(0,0,ScreenWidth(),ScreenHeight());
			
			local onepixel=((XRES(2)*320==XRES(640)) ? 0 : 1)
			
			surface.DrawTexturedSubRect(XRES(i), offset, XRES(i)+XRES(2)+onepixel, YRES(480)+offset,RemapVal(i.tofloat(),0,640,0,1),0,RemapVal(i.tofloat()+2,0,640,0,1),1)
			//surface.SetColor(255,255,255,5)
			//surface.SetTexture(pov)
			//surface.DrawTexturedSubRect(XRES(i), offset-YRES(480), XRES(i)+XRES(2), offset,RemapVal(i.tofloat(),0,640,0,1),0,RemapVal(i.tofloat()+2,0,640,0,1),1)

		}
		
		PreChangeHealth=player.GetHealth()
		
		local Difference=(player.GetHealth()-PreviousHealth)/(10)
		PreviousHealth+=Difference/20*(0.8/pow(1.01,Difference))*10
		
		local back=null
		NetMsg.Receive("FadeScreen",function(...) {
			
			PlayerFadeTime=Time()
			
			local a= vgui.CreatePanel("Panel", vgui.GetClientDLLRootPanel(), "Screen3")
			back= vgui.CreatePanel("ImagePanel", vgui.GetClientDLLRootPanel(), "Screen2")
			back.SetImage("console/background_widescreen",false)
			back.MakeReadyForUse()
			back.SetVisible(true)
			back.SetPos(XRES(0), YRES(0))
			back.SetSize(XRES(640),YRES(480))
			back.SetDrawColor(133,133,133,0)
			back.SetShouldScaleImage(true)

			a.SetCallback( "OnTick", function()
			{
				if ((Time()-PlayerFadeTime)>=0.5) back.SetDrawColor(133,133,133,255);
			}.bindenv(this) )
			a.AddTickSignal(1)
			
		}.bindenv(this))
		
		//if (back&&(Time()-PlayerFadeTime)>=0.1) back.SetVisible(true);
		
		if ((Time()-PlayerFadeTime)<0.5&&(Time()-PlayerFadeTime)>=0)
		{
			for (local i=0;i<640;i+=2)
			{
				local Timevar=Time()-PlayerFadeTime
		
				local Scale=((1 - Timevar)*2.8)
				
				surface.SetColor(0,0,0,255)
				
				//local DistMod=XRES(abs(320-i))/2.0
				local DistMod=0
				//surface.DrawFilledRect(XRES(i),0,XRES(2),DistMod+YRES(480)-YRES(480)*(Scale-1.5-(RNGs[i]/2)))
				surface.SetColor(133,133,133,255)
				//local rngmod=RNGs[i]/4.0
				local rngmod=pow(RNGs[i+10]+1,14)
				local offset=clamp((-YRES(480))+clamp(DistMod+YRES(480)+YRES(480)*(Scale-1.5-(rngmod/4.0)),0,9999),0,ScreenHeight())
				
				surface.SetTexture(blackness)
				//if (i==0) surface.DrawTexturedRect(0,0,ScreenWidth(),ScreenHeight());
				
				local onepixel=((XRES(2)*320==XRES(640)) ? 0 : 1)
				
				surface.DrawTexturedSubRect(XRES(i), -offset, XRES(i)+XRES(2)+onepixel, YRES(480)-offset,RemapVal(i.tofloat(),0,640,0,1),0,RemapVal(i.tofloat()+2,0,640,0,1),1)
				//surface.SetColor(255,255,255,5)
				//surface.SetTexture(pov)
				//surface.DrawTexturedSubRect(XRES(i), offset-YRES(480), XRES(i)+XRES(2), offset,RemapVal(i.tofloat(),0,640,0,1),0,RemapVal(i.tofloat()+2,0,640,0,1),1)
				
			}
		}
		
		if (HeatActionReady)
		{
			surface.SetColor(255,255,255,255)
			surface.SetTexture(surface.ValidateTexture("vgui/hud/gameinstructor_iconsheet2",true,false,false))
			
			local KeyHintFont=surface.GetFont( "KeyHint5", true )
			
			local x=XRES(500)
			local y=YRES(100)
			
			local xoffset=surface.GetTextWidth(BigNotificationBlurFont,"Finisher")+YRES(8)
			local yoffset=(-YRES(24)/2+surface.GetFontTall(BigNotificationBlurFont)/2.0)
			
			surface.DrawTexturedSubRect(x+xoffset,y+yoffset,x+xoffset+YRES(24),y+yoffset+YRES(24),0.25,0.25,0.5,0.5)
			surface.DrawColoredText(KeyHintFont,x+xoffset+YRES(24)/2.0-surface.GetTextWidth(KeyHintFont,"V")/2.0,y+yoffset+YRES(24)/2.0-surface.GetFontTall(KeyHintFont)/2.0,25,185,255,255,"V")
			     
			surface.DrawColoredText(BigNotificationFont,x,y,40, 180, 255,255,"Finisher")
			surface.DrawColoredText(BigNotificationBlurFont,x,y,255, 30, 25,255*sin(Time()*8),"Finisher")
			surface.DrawColoredText(BigNotificationBlurFont,x,y,255, 2, 2,255*cos(Time()*8),"Finisher")
		}
		
		if (ReviveReady)
		{
			surface.SetColor(255,255,255,255)
			surface.SetTexture(surface.ValidateTexture("vgui/hud/gameinstructor_iconsheet2",true,false,false))
			
			local KeyHintFont=surface.GetFont( "KeyHint5", true )
			
			local x=XRES(500)
			local y=YRES(100)
			
			local xoffset=surface.GetTextWidth(BigNotificationBlurFont,"Revive")+YRES(8)
			local yoffset=(-YRES(24)/2+surface.GetFontTall(BigNotificationBlurFont)/2.0)
			
			surface.DrawTexturedSubRect(x+xoffset,y+yoffset,x+xoffset+YRES(24),y+yoffset+YRES(24),0.25,0.25,0.5,0.5)
			surface.DrawColoredText(KeyHintFont,x+xoffset+YRES(24)/2.0-surface.GetTextWidth(KeyHintFont,"E")/2.0,y+yoffset+YRES(24)/2.0-surface.GetFontTall(KeyHintFont)/2.0,25,185,255,255,"E")
			     
			surface.DrawColoredText(BigNotificationFont,x,y,40, 180, 255,255,"Revive")
			surface.DrawColoredText(BigNotificationBlurFont,x,y,255, 30, 25,255*sin(Time()*8),"Revive")
			surface.DrawColoredText(BigNotificationBlurFont,x,y,255, 2, 2,255*cos(Time()*8),"Revive")
		}
		
		/*
		local tex="Localization is scary, but now I can write text normally."
		tex="Локализация это страшно, но теперь я умею писать текст нормально."
		tex="Lokalisering är skrämmande, men nu kan jag skriva text normalt."
		tex="Ο εντοπισμός είναι τρομακτικός, αλλά τώρα μπορώ να γράψω κανονικά κείμενο."
		tex="本地化很可怕，但现在我可以正常书写文字了。"
		tex="ローカライズは怖いけど、今は普通に文章が書ける。"
		tex="로컬라이제이션은 무서운 일이지만 이제 정상적으로 텍스트를 쓸 수 있습니다."
		local endpoint=(Time()*15*GetTextLengthMult(tex)).tointeger()%tex.len()+1

		
		
		local trueendpoint=0
		for ( local i = 0; i < endpoint; )
		{
			local bytes = UTF8Bytes( tex, i );
			i += bytes;
			trueendpoint += bytes;
		}
		*/
		
		//
		// STATUS EFFECTS
		//
		
		DrawStatusEffects()
		
		
		
		//printl(GetTextLengthMult(tex))
		
		//surface.DrawColoredText(35,XRES(320)-surface.GetTextWidth(35,tex)/2+3,YRES(240)-surface.GetFontTall(35)+3,5,5,5,255,tex.slice(0,trueendpoint))
		//surface.DrawColoredText(35,XRES(320)-surface.GetTextWidth(35,tex)/2,YRES(240)-surface.GetFontTall(35),255,255,255,255,tex.slice(0,trueendpoint))
		//surface.DrawColoredText(35,YRES(50),YRES(50),255,255,255,255,tex)
		
		
		Scale=(Time()-PlayerDeathTime)*3
		if (PlayerDeathTime>0) for (local i=0;i<640;i++)
		{
			surface.SetColor(0,0,0,255)
			surface.DrawFilledRect(XRES(i),0,XRES(2),YRES(480)*(pow(Scale,1+RNGs[i+1640]/2.0-RNGs[i+320+1000]/6.0)-0.2-(RNGs[i+1000])))
		}
		if ("BombTime" in getroottable()) if (BombTime!=null)
		{
			local Timeleft=(BombTime-Time()+0.3)
			if (Timeleft<2.2) PlayerFalling()
			local sec=Timeleft%60
			local mins=Timeleft/60
			
			local BombFont=surface.GetFont( "A", true )
			local BombFontS=surface.GetFont( "Ass", true )
			local BombFontSmall=surface.GetFont( "Smol", true )
			local BombFontSmallS=surface.GetFont( "Smolss", true )
			
			local MainTimerWidthHalf=surface.GetTextWidth(BombFont,"3:00")/2
			
			local MilliSecWidth=surface.GetTextWidth(BombFontSmall,".99")
			
			
			surface.SetColor(0,0,0,255)
			surface.DrawFilledRectFade(XRES(320)-MainTimerWidthHalf-MilliSecWidth/2-YRES(20),YRES(65),YRES(40)+MainTimerWidthHalf*2+MilliSecWidth,surface.GetFontTall(BombFont)/2,255,0,false)
			surface.DrawFilledRectFade(XRES(320)-MainTimerWidthHalf-MilliSecWidth/2-YRES(20),YRES(65),YRES(40)+MainTimerWidthHalf*2+MilliSecWidth,surface.GetFontTall(BombFont),155,0,true)
			surface.DrawFilledRectFade(XRES(320)-MainTimerWidthHalf-MilliSecWidth/2-YRES(20),YRES(65),YRES(40)+MainTimerWidthHalf*2+MilliSecWidth,surface.GetFontTall(BombFont),0,155,true)
			surface.DrawFilledRectFade(XRES(320)-MainTimerWidthHalf-MilliSecWidth/2-YRES(20),YRES(65)+surface.GetFontTall(BombFont)/2,YRES(40)+MainTimerWidthHalf*2+MilliSecWidth,surface.GetFontTall(BombFont)/2,0,255,false)
			
			surface.DrawColoredText(BombFont,XRES(320)-MainTimerWidthHalf-MilliSecWidth/2,YRES(65),255, 30, 20,255,format("%d:%.2d",mins,sec))
			surface.DrawColoredText(BombFontS,XRES(320)-MainTimerWidthHalf-MilliSecWidth/2,YRES(65),255, 30, 20,55,format("%d:%.2d",mins,sec))
			
			local MainTimerRealWidth=surface.GetTextWidth(BombFont,format("%d:%.2d",mins,sec))
			local MilliSecOffset=(surface.GetFontTall(BombFont)-surface.GetFontTall(BombFontSmall))*0.9
			
			surface.DrawColoredText(BombFontSmall,XRES(320)-MainTimerWidthHalf+MainTimerRealWidth-MilliSecWidth/2,YRES(65)+MilliSecOffset,255, 30, 20,155,format(".%.2d",(Timeleft-Timeleft.tointeger())*100))
			surface.DrawColoredText(BombFontSmallS,XRES(320)-MainTimerWidthHalf+MainTimerRealWidth-MilliSecWidth/2,YRES(65)+MilliSecOffset,255, 30, 20,25,format(".%.2d",(Timeleft-Timeleft.tointeger())*100))
		}
		if (SW_BOSS_ACTIVE) 
		{
			local Difference=BossHP-PrevBossHP
			if (Time()-BossLastDmg>0.25) PrevBossHP+=Difference/50*(0.8/pow(1.01,Difference))
		}
		if (SW_BOSS_ACTIVE&&BossHP>0)
		{
			local hp=Gain(BossHP,0.4)
			local prevhp=Gain(PrevBossHP,0.4)
			// YES, Boss healthbars aren't exactly accurate and let me tell you how they work.
			// Healthbar drains more depending on whether boss' hp is close to being 0% or 100%.
			// Meaning that at the start and at the end of bossfight it's gonna trick player into thinking they do more damage, whereas in the middle of bossfight it's less damage shown.
			// This is supposed to trick the player into thinking that the boss will be easier judging by their damage feedback at the start. And at the same time it's gonna be "visibly" easier to finish boss at the end.
			
			local width=XRES(120)
			local height=YRES(6)
			local ypos=YRES(115)
			local xpos=XRES(320)
			local border=YRES(3)
			
			local dmgmod=RemapValClamped(0.1-(Time()-BossLastDmg)*0.7,0,0.1,0,1)
			
			xpos+=YRES(RandomInt(-(prevhp-hp)*40,(prevhp-hp)*40))
			ypos+=YRES(RandomInt(-(prevhp-hp)*40,(prevhp-hp)*40))
			
			//printl(hp)
			surface.SetColor(10+20*dmgmod, 10+20*dmgmod, 10+20*dmgmod, 190)
			if (BossHP<=0.1) surface.SetColor(10+30*fabs(sin(Time()*3))+16*dmgmod, 10+10*dmgmod, 10+10*dmgmod, 180);
			surface.DrawFilledRect(xpos-width*0.5-border*0.5,ypos-border*0.5,width+border,height+border)
			surface.DrawFilledRect(xpos-width*0.5,ypos,width,height)
			surface.SetColor(255, 235, 235, 255)
			surface.DrawFilledRect(xpos-width*prevhp*0.5,ypos,width*prevhp,height)
			surface.SetColor(240, 215, 215, 255)
			surface.DrawFilledRectFade(xpos-width*prevhp*0.5,ypos,width*prevhp,height,0,255,false)
			surface.SetColor(100, 14, 0, 255)
			surface.DrawFilledRect(xpos-width*hp*0.5,ypos,width*hp,height)
			
			
			surface.SetColor(255, 31, 14, 225)
			
			local mod1=255*dmgmod
			local mod2=255
			
			surface.DrawFilledRectFade(xpos-width*hp*0.5,ypos,width*hp,height/2,mod1,mod2,false)
			surface.DrawFilledRectFade(xpos-width*hp*0.5,ypos+height/2,width*hp,height/2,mod2,mod1,false)
			
			
			surface.DrawColoredText(surface.GetFont( "Smolss", true ),XRES(322)-surface.GetTextWidth(surface.GetFont( "Smol", true ),SW_BOSS_NAME)/2,ypos-surface.GetFontTall(surface.GetFont( "Smol", true )),5,5,5,125,SW_BOSS_NAME)			
			surface.DrawColoredText(surface.GetFont( "Smolss", true ),XRES(320)-surface.GetTextWidth(surface.GetFont( "Smol", true ),SW_BOSS_NAME)/2,ypos-surface.GetFontTall(surface.GetFont( "Smol", true )),255,225,255,25,SW_BOSS_NAME)
			surface.DrawColoredText(surface.GetFont( "Smol", true ),XRES(320)-surface.GetTextWidth(surface.GetFont( "Smol", true ),SW_BOSS_NAME)/2,ypos-YRES(3)-surface.GetFontTall(surface.GetFont( "Smol", true )),225,225,225,255,SW_BOSS_NAME)
		}
		
		if (Convars.GetFloat("sourceworld_hud")!=3) return;
		
		surface.SetColor(40, 40, 40, 80)
		if (player.GetHealth()<=25) surface.SetColor(40+100*fabs(sin(Time()*6)), 40, 40, 80);
		surface.DrawFilledRect(XRES(20+xoffset),YRES(460+yoffset),XRES(1)*100,15)
		surface.SetColor(255, 23, 23, 255)
		surface.DrawFilledRect(XRES(20+xoffset),YRES(460+yoffset),XRES(1)*PreviousHealth,15)
		surface.SetColor(200, 15, 15, 255)
		surface.DrawFilledRect(XRES(20+xoffset),YRES(460+yoffset),XRES(1)*PreviousHealth,13)
		surface.SetColor(85, 28, 0, 255)
		surface.DrawFilledRect(XRES(20+xoffset),YRES(460+yoffset),XRES(1)*player.GetHealth(),15)
		surface.SetColor(255, 123, 0, 255)
		surface.DrawFilledRect(XRES(20+xoffset),YRES(460+yoffset),XRES(1)*player.GetHealth(),13)
		surface.SetColor(255, 11, 14, 225)
		surface.DrawFilledRectFade(XRES(20+xoffset),YRES(460+yoffset),XRES(1)*player.GetHealth(),13,0,255,false)
		if ((Time()-LastDmgTime)<2)
		{
			surface.SetColor(255, 23, 23, 1/(Time()-LastDmgTime)/player.GetHealth()*300)
			function DrawDamageGlow(Mod)
			{
				
				surface.DrawFilledRectFade(XRES(20+xoffset)+XRES(1)*PreviousHealth-Mod/2,YRES(460+yoffset),Mod,15,0,111+Mod,true)
				surface.DrawFilledRectFade(XRES(20+xoffset)+XRES(1)*PreviousHealth+Mod/2,YRES(460+yoffset),Mod,15,111+Mod,0,true)
				
				surface.DrawFilledRectFade(XRES(20+xoffset)+XRES(1)*PreviousHealth,YRES(460+yoffset)-10,Mod,25,0,281+Mod,false)
			}

			DrawDamageGlow(1)
			DrawDamageGlow(2)
			DrawDamageGlow(3)
			DrawDamageGlow(4)
			DrawDamageGlow(5)
			DrawDamageGlow(6)
			DrawDamageGlow(7)
			DrawDamageGlow(8)	//даже блять не спрашивайте. мне эта неиспользуемая хуйня самому не нравится но удалять лень 
			DrawDamageGlow(9)
			DrawDamageGlow(10)
			DrawDamageGlow(11)
			DrawDamageGlow(12)
			DrawDamageGlow(13)
			DrawDamageGlow(14)
			DrawDamageGlow(15)
			surface.SetColor(255, 23, 23, 5/(Time()-LastDmgTime))
			surface.DrawFilledRectFade(XRES(20+xoffset),YRES(460+yoffset)-15,XRES(1)*PreviousHealth/5,15,0,65,false)
			
		}
		
	}
	
	panel = vgui.CreatePanel("Panel", vgui.GetClientDLLRootPanel(), "Screen")
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
	panel.SetCallback( "OnTick", function(){if (SW_PLAYTHROUGH_SEED==(-1)) return 10;MakePoints();CalculateLines();}.bindenv(this) )
	panel.AddTickSignal(5);
	
	
	RotateVector<-function(A,B,RotatedByAngle=Vector()){local m=matrix3x4_t();AngleMatrix(B,Vector(0,0,0),m);return VectorRotate(A,m)}
	
	function RagModelToName(model,classname)
	{
		if (!model) return ""
		if (model.find("combine")&&model.find("soldier")) return "Dead Combine Soldier"
		if (model.find("police")) return "Dead Civil Protection"
		if (model.find("zombie")) return "Dead Zombie"
		if (model.find("headcrab")) return "Dead Headcrab"
		if (model.find("manhack")) return "Broken Manhack"
		if (model.find("cardboard")&&model.find("box")) return "Broken Cardboard Box"
		
		return "Corpse";
	}
	
	function ModelToName(model,classname)
	{
		if (!model) return ""
	
		if (model.find("reciever")) return "Reciever"
		if (model.find("keyboard")) return "Keyboard"
		if (model.find("stool")) return "Chair"
		if (model.find("chunk")||model.find("shard")||model.find("gib")) return "Debris"
		if (model.find("wood")&&model.find("crate")) return "Wooden Crate"
		if (model.find("metal")&&model.find("crate")) return "Metal Crate"
		if (model.find("cardboard")&&model.find("box")) return "Cardboard Box"
		if (model.find("/box")) return "Box"
		if (model.find("binder")) return "Binder"
		if (model.find("bottle")) return "Bottle"
		if (model.find("radio")) return "Radio"
		if (model.find("computer")&&model.find("case")) return "Computer Case"
		if (model.find("harddrive0")) return "Computer Case"
		if (model.find("chair")) return "Chair"
		if (model.find("dresser")) return "Dresser"
		if (model.find("filecabinet")) return "File Cabinet"
		if (model.find("mug")) return "Mug"
		if (model.find("popcan")) return "Can"
		if (model.find("jar")) return "Jar"
		if (model.find("shelf")&&model.find("metal")) return "Metal Shelf"
		if (model.find("shelf")) return "Shelf"
		if (model.find("shelves")) return "Shelves"
		if (model.find("pallet")) return "Pallet"
		if (model.find("drawer")) return "Drawer"
		if (model.find("clipboard")) return "Clipboard"
		if (model.find("console")) return "Console"
		if (model.find("monitor")) return "Monitor"
		if (model.find("newspaper")) return "Newspaper"
		if (model.find("cone")) return "Cone"
		if (model.find("ammo_can")) return "Ammunition Crate"
		if (model.find("huladoll")) return "Hula Doll"
		if (model.find("cactus")) return "Cactus"
		if (model.find("bin0")) return "Bin"
		if (model.find("carton")) return "Carton"
		if (model.find("bucket")) return "Bucket"
		if (model.find("table")) return "Table"
		if (model.find("desk")) return "Desk"
		if (model.find("combine")&&model.find("soldier")) return "Combine Soldier Corpse"
		if (model.find("zombie")) return "Zombie Corpse"
		if (model.find("headcrab")) return "Headcrab Corpse"
		if (model.find("boot")) return "Boot"
		if (model.find("explosi")) return "Explosive Barrel"
		if (model.find("oild")) return "Barrel"
		if (model.find("barrel")) return "Barrel"
		if (model.find("phone")) return "Phone"
		if (model.find("cart")) return "Cart"
		if (model.find("button")) return "Button"
		if (model.find("junk")) return "Junk"
		if (model.find("tv_plasma")) return "Plasma TV"
		if (model.find("plant0")) return "Plant"
		if (model.find("padlock001a")) return "Padlock"
		if (model.find("padlock001b")) return "Broken Padlock"
		if (model.find("snowman_hat")) return "Richard's Hat"
		if (model.find("trash")) return "Trash"
		if (model.find("board")) return "Board"
		if (model.find("plank")) return "Plank"
		if (model.find("health_charger")) return "Health Charger"
		if (model.find("male_06")) return "Vlad"
		if (model.find("male_05")) return "Won"
		if (model.find("male_08")) return "Bartender"
		if (model.find("save.mdl")) return "Save"
		if (model.find("c4")) return ((Time()*10).tointeger()%2==1) ? "A BOMB!" : "A BOMB "
		
		return classname;
	}
	
	function GlitchText(text)
	{
		for (local i=0;i<text.len();i++)
		{
			if (RandomInt(1,3)==1) text=text.slice(0,i)+RandomInt(33,64).tochar()+text.slice(i+1)
		}
		return text
	}
	
	function Crosshair()
	{
		if (Convars.GetInt("sourceworld_hud")==2) return;
		
		if (ItemName=="None") return;
		if (Entities.FindByName(null,"PlayerModel")) return;
		if (!("IsValid" in Ent)) return;
		if (!Ent.IsValid()) return;
		if (!player||player.GetHealth()<=0||player.GetCollisionGroup()==10) return
		//printl(Ent.GetClassname())
		if (ItemClassname=="prop_dynamic") return
		if (ItemName==null||(ItemName[0].tochar().toupper()!=ItemName[0].tochar())) switch (ItemClassname)
		{
			case "func_button":ItemName="Button";break;
			case "prop_door_rotating":ItemName="Door";break;
			case "func_door_rotating":ItemName="Door";break;
			case "func_door":ItemName="Door";break;
			case "func_movelinear":ItemName="Elevator";break;
			case "func_brush":return;
			case "func_breakable":return;
			case "prop_ragdoll":ItemName="Corpse";break;
			case "npc_combine_s":ItemName=ItemModel.find("gordon") ? SW_BOSS_NAME : (ItemModel.find("hecu") ? "HECU Grunt" : "Combine Soldier");break;
			case "npc_metropolice":ItemName=ItemModel.find("district") ? "District Security" : "Combine Civil Protection";break;
			case "npc_headcrab":ItemName="Headcrab";break;
			case "npc_headcrab_fast":ItemName="Fast Headcrab";break;
			case "npc_headcrab_black":ItemName="Poison Headcrab";break;
			case "npc_zombie":ItemName="Zombie";break;
			case "npc_manhack":ItemName="Manhack";break;
			case "npc_monk":ItemName="Tony";break;
			case "npc_turret_floor":ItemName="Combine Turret";break;
			case "npc_tripmine":ItemName="Tripmine";break;
			case "combine_mine":ItemName="Combine Mine";break;
			case "npc_zombine":ItemName="Combine Soldier Zombie";break; // No funny for you >:(
			case "npc_poisonzombie":ItemName="Poison Zombie";break;
			case "npc_fastzombie":ItemName="Fast Zombie";break;
			case "item_item_crate":ItemName="Supply Crate";break;
			case "func_reflective_glass":return
			case "beam":return
		}
		
		if (ItemModel.find("corrupt")!=null)
		{
			if (ItemModel.find("agent")!=null)
			ItemName=GlitchText("Corruptor Agent")
		}

		if (ItemName.find("prop")!=null||(ItemName[0].tochar().toupper()!=ItemName[0].tochar()))
		{
			ItemName=ModelToName(ItemModel,ItemClassname)
		}
		if (ItemName=="Corpse") ItemName=RagModelToName(ItemModel,ItemClassname);
		if (ItemName=="prop_interactable") ItemName="Interactable"
		
		
		local Center=WorldPosToScreen(Ent.GetOrigin())
		local Corners=[]
		
		local BBMins=Ent.GetBoundingMins()
		local BBMaxs=Ent.GetBoundingMaxs()
		
		Corners.append( WorldPosToScreen(Ent.GetOrigin()+RotateVector(BBMins,Ent.GetAngles())) )
		Corners.append( WorldPosToScreen(Ent.GetOrigin()+RotateVector(BBMins-Vector(BBMins.x,0,0)*2,Ent.GetAngles())) )
		Corners.append( WorldPosToScreen(Ent.GetOrigin()+RotateVector(BBMins-Vector(0,BBMins.y,0)*2,Ent.GetAngles())) )
		Corners.append( WorldPosToScreen(Ent.GetOrigin()+RotateVector(BBMins-Vector(BBMins.x,BBMins.y,0)*2,Ent.GetAngles())) )
		Corners.append( WorldPosToScreen(Ent.GetOrigin()+RotateVector(BBMaxs,Ent.GetAngles())) )
		Corners.append( WorldPosToScreen(Ent.GetOrigin()+RotateVector(BBMaxs-Vector(BBMaxs.x,0,0)*2,Ent.GetAngles())) )
		Corners.append( WorldPosToScreen(Ent.GetOrigin()+RotateVector(BBMaxs-Vector(0,BBMaxs.y,0)*2,Ent.GetAngles())) )
		Corners.append( WorldPosToScreen(Ent.GetOrigin()+RotateVector(BBMaxs-Vector(BBMaxs.x,BBMaxs.y,0)*2,Ent.GetAngles())) )
		
		local MinX=99999
		local MaxX=0
		local MinY=99999
		local MaxY=0
		
		foreach (Corner in Corners)
		{
			if (Corner.x<MinX) MinX=Corner.x
			if (Corner.x>MaxX) MaxX=Corner.x
			if (Corner.y<MinY) MinY=Corner.y
			if (Corner.y>MaxY) MaxY=Corner.y
		}
		
		
		local Rnd=sin((Time()*8).tointeger()/2.0)*YRES(2)
		
		surface.SetColor(25,25,25,185)
		
		MinX*=ScreenWidth()
		MaxX*=ScreenWidth()
		MinY*=ScreenHeight()
		MaxY*=ScreenHeight()
		

		MinX-=YRES(2)
		MaxX+=YRES(2)
		MinY-=YRES(2)
		MaxY+=YRES(2)
		
		local OGMinX=MinX
		local OGMaxX=MaxX
		local OGMinY=MinY
		local OGMaxY=MaxY
		
		MinX=clamp(MinX,YRES(80),ScreenWidth()-YRES(80))
		MaxX=clamp(MaxX,YRES(80),ScreenWidth()-YRES(80))
		MinY=clamp(MinY,YRES(30),ScreenHeight()-YRES(10))
		MaxY=clamp(MaxY,YRES(30),ScreenHeight()-YRES(10))
		
		if (OGMinX!=MinX&&OGMinY!=MinY&&OGMaxX!=MaxX&&OGMaxY!=MaxY) return;
		
		local CSizeX=(MaxX-MinX)
		local CSizeY=(MaxY-MinY)
		
		local ATLAS_SIZE=16.0
		local ATLAS_TEXTURE=surface.ValidateTexture("vgui/inventory/item_atlas",true,false,false)
	
		if (ItemClassname in LIST_QUEST_ITEMS)
		{
			ItemName=LIST_QUEST_ITEMS[ItemClassname].name
			
			local item=LIST_QUEST_ITEMS[ItemClassname]
			local Cell=MaxY-MinY
			
			MinX=MinX+(MaxX-MinX)/2-Cell/2
			MinY=MinY+(MaxY-MinY)/2-Cell/2
			
			MaxX=MinX+Cell+YRES(4)
			MaxY=MinY+Cell+YRES(4)
					
			local IconX=item.icon[0]/ATLAS_SIZE;
			local IconY=item.icon[1]/ATLAS_SIZE;
			local IconSizeX=item.sizey
			local IconSizeY=item.sizey
			local IconUV_X=IconSizeX/min(item.sizex,item.sizey)*1.0
			local IconUV_Y=IconSizeY/min(item.sizex,item.sizey)*1.0
			
			surface.SetColor( 255,255,255,255);
			local Scale=min(IconSizeX,IconSizeY)*1.0/max(IconSizeX,IconSizeY)*1.0
			local OffsetX=(IconSizeX>IconSizeY) ? 0 : (Cell-Cell*Scale)/2
			local OffsetY=(IconSizeX<IconSizeY) ? 0 : (Cell-Cell*Scale)/2
			surface.SetTexture(ATLAS_TEXTURE)
			
			local timevar=cos(Time()*2)
			
			local offs=fabs(timevar)*Cell/2
			
			surface.SetColor( 105+150*fabs(timevar),105+150*fabs(timevar),105+150*fabs(timevar),255);
			
			if (timevar>0) surface.DrawTexturedSubRect(MinX+YRES(2)+OffsetX-offs+Cell/2, MinY+OffsetY, OffsetX-Cell/2+offs+MinX+YRES(2)+Cell*IconUV_X*Scale, MinY+Cell*IconUV_Y*Scale+OffsetY, IconX, IconY,IconX+IconSizeX/ATLAS_SIZE,IconY+IconSizeY/ATLAS_SIZE)
				
			if (timevar<=0) surface.DrawTexturedSubRect(MinX+YRES(2)+OffsetX-offs+Cell/2, MinY+OffsetY, OffsetX-Cell/2+offs+MinX+YRES(2)+Cell*IconUV_X*Scale, MinY+Cell*IconUV_Y*Scale+OffsetY, IconX+IconSizeX/ATLAS_SIZE, IconY,IconX,IconY+IconSizeY/ATLAS_SIZE)
			
			surface.SetColor(25,25,25,185)
		}
		
		local QuickUse=false
		if (input.LookupBinding("+alt1")&&input.IsButtonDown(input.StringToButtonCode(input.LookupBinding("+alt1")))) QuickUse=true;
		
		if (Count==1) surface.DrawFilledRect(MinX,MinY-surface.GetFontTall(171)-YRES(4),surface.GetTextWidth(171,ItemName)+YRES(4),surface.GetFontTall(171)+YRES(4))
		else surface.DrawFilledRect(MinX,MinY-surface.GetFontTall(171)-YRES(4),surface.GetTextWidth(171,ItemName+" x"+Count)+YRES(4),surface.GetFontTall(171)+YRES(4))
		
		if (Count==1) surface.DrawColoredText(171,MinX+YRES(2)-1,MinY-surface.GetFontTall(171)-YRES(2)-1,2,2,2,255,ItemName)
		else surface.DrawColoredText(171,MinX+YRES(2)-1,MinY-surface.GetFontTall(171)-YRES(2)-1,2,2,2,255,ItemName+" x"+Count)
		
		if (Count==1) surface.DrawColoredText(171,MinX+YRES(2),MinY-surface.GetFontTall(171)-YRES(2),25,225,255,255,ItemName)
		else surface.DrawColoredText(171,MinX+YRES(2),MinY-surface.GetFontTall(171)-YRES(2),25,225,255,255,ItemName+" x"+Count)
	
		surface.SetColor(0,0,0,235)
		
		
	
		if (Count==1) DrawOutlinedBoxAlt(YRES(1),MinX,MinY-surface.GetFontTall(171)-YRES(4),surface.GetTextWidth(171,ItemName)+YRES(4),surface.GetFontTall(171)+YRES(4))
		else DrawOutlinedBoxAlt(YRES(1),MinX,MinY-surface.GetFontTall(171)-YRES(4),surface.GetTextWidth(171,ItemName+" x"+Count)+YRES(4),surface.GetFontTall(171)+YRES(4))
			
		
		if (QuickUse&&(ItemClassname in LIST_ITEMS)&&("ammoitem" in LIST_ITEMS[ItemClassname]))
		{
			//Quick Unload
			
			surface.SetColor(65,65,25,185)
			
			local offsety=surface.GetFontTall(171)+YRES(4)
			local offsetx=surface.GetFontTall(171)+YRES(4)
			
			offsety=-((surface.GetFontTall(171)+YRES(2))/2+(MaxY-MinY)/2)
			offsetx=-(-(surface.GetTextWidth(171,"UNLOAD")+YRES(4))/2+(MaxX-MinX)/2)
			
			surface.DrawFilledRect(MinX-offsetx,MinY-surface.GetFontTall(171)-YRES(4)-offsety,surface.GetTextWidth(171,"UNLOAD")+YRES(4),surface.GetFontTall(171)+YRES(4))
			
			surface.DrawColoredText(171,MinX+YRES(2)-1-offsetx,MinY-surface.GetFontTall(171)-YRES(2)-1-offsety,2,2,2,255,"UNLOAD")
			
			surface.DrawColoredText(171,MinX+YRES(2)-offsetx,MinY-surface.GetFontTall(171)-YRES(2)-offsety,225,225,55,255,"UNLOAD")
			
			surface.SetColor(0,0,0,235)
			
			DrawOutlinedBoxAlt(YRES(1),MinX-offsetx,MinY-surface.GetFontTall(171)-YRES(4)-offsety,surface.GetTextWidth(171,"UNLOAD")+YRES(4),surface.GetFontTall(171)+YRES(4))
		}
		
		if (QuickUse&&(ItemClassname in LIST_ITEMS)&&("Use" in LIST_ITEMS[ItemClassname]))
		{
			//Quick Unload
			
			surface.SetColor(25,65,25,185)
			
			local offsety=surface.GetFontTall(171)+YRES(4)
			local offsetx=surface.GetFontTall(171)+YRES(4)
			
			offsety=-((surface.GetFontTall(171)+YRES(2))/2+(MaxY-MinY)/2)
			offsetx=-(-(surface.GetTextWidth(171,"USE")+YRES(4))/2+(MaxX-MinX)/2)
			
			surface.DrawFilledRect(MinX-offsetx,MinY-surface.GetFontTall(171)-YRES(4)-offsety,surface.GetTextWidth(171,"USE")+YRES(4),surface.GetFontTall(171)+YRES(4))
			
			surface.DrawColoredText(171,MinX+YRES(2)-1-offsetx,MinY-surface.GetFontTall(171)-YRES(2)-1-offsety,2,2,2,255,"USE")
			
			surface.DrawColoredText(171,MinX+YRES(2)-offsetx,MinY-surface.GetFontTall(171)-YRES(2)-offsety,25,225,55,255,"USE")
			
			surface.SetColor(0,0,0,235)
			
			DrawOutlinedBoxAlt(YRES(1),MinX-offsetx,MinY-surface.GetFontTall(171)-YRES(4)-offsety,surface.GetTextWidth(171,"USE")+YRES(4),surface.GetFontTall(171)+YRES(4))
		}
	
	
		local LineLen=clamp(YRES(18),1,min(CSizeX,CSizeY)/3.5)
		local LineThick=YRES(1)
		//surface.DrawFilledRect(Center.x,Center.y,10,10)
		
		surface.SetColor(5,5,5,10)
		surface.DrawFilledRect(MinX,MinY,CSizeX,CSizeY)
		
		
		MinX-=-fabs(Rnd)
		MaxX+=-fabs(Rnd)
		MinY-=-fabs(Rnd)
		MaxY+=-fabs(Rnd)
		
		
		surface.SetColor(25,225,255,120)
		
		if (QuickUse&&(ItemClassname in LIST_ITEMS)&&("Use" in LIST_ITEMS[ItemClassname])) surface.SetColor(25,225,255,55)
		if (QuickUse&&(ItemClassname in LIST_ITEMS)&&("ammoitem" in LIST_ITEMS[ItemClassname])) surface.SetColor(25,225,255,55)
		
		surface.DrawFilledRect(MinX,MinY,LineLen,LineThick)
		surface.DrawFilledRect(MinX,MinY,LineThick,LineLen)
		
		surface.DrawFilledRect(MinX,MaxY-LineLen,LineThick,LineLen)
		surface.DrawFilledRect(MinX,MaxY-LineThick,LineLen,LineThick)
		
		surface.DrawFilledRect(MaxX-LineLen,MinY,LineLen,LineThick)
		surface.DrawFilledRect(MaxX-LineThick,MinY,LineThick,LineLen)
		
		surface.DrawFilledRect(MaxX-LineThick,MaxY-LineLen,LineThick,LineLen)
		surface.DrawFilledRect(MaxX-LineLen,MaxY-LineThick,LineLen,LineThick)
		
		if (QuickUse&&(ItemClassname in LIST_ITEMS)&&("Use" in LIST_ITEMS[ItemClassname]))
		{
			surface.SetColor(25,225,25,120)
			
			LineThick=LineThick*2
			LineLen=LineLen-YRES(1)*2
			
			surface.DrawFilledRect(MinX+LineThick,MinY+LineThick,LineLen,LineThick)
			surface.DrawFilledRect(MinX+LineThick,MinY+LineThick,LineThick,LineLen)
			
			surface.DrawFilledRect(MinX+LineThick,MaxY-LineLen-LineThick,LineThick,LineLen)
			surface.DrawFilledRect(MinX+LineThick,MaxY-LineThick*2,LineLen,LineThick)
			
			surface.DrawFilledRect(MaxX-LineLen-LineThick,MinY+LineThick,LineLen,LineThick)
			surface.DrawFilledRect(MaxX-LineThick*2,MinY+LineThick,LineThick,LineLen)
			
			surface.DrawFilledRect(MaxX-LineThick*2,MaxY-LineLen-LineThick,LineThick,LineLen)
			surface.DrawFilledRect(MaxX-LineLen-LineThick,MaxY-LineThick*2,LineLen,LineThick)
		}
		
		if (QuickUse&&(ItemClassname in LIST_ITEMS)&&("ammoitem" in LIST_ITEMS[ItemClassname]))
		{
			surface.SetColor(255,225,25,120)
			
			LineThick=LineThick*2
			LineLen=LineLen-YRES(1)*2
			
			surface.DrawFilledRect(MinX+LineThick,MinY+LineThick,LineLen,LineThick)
			surface.DrawFilledRect(MinX+LineThick,MinY+LineThick,LineThick,LineLen)
			
			surface.DrawFilledRect(MinX+LineThick,MaxY-LineLen-LineThick,LineThick,LineLen)
			surface.DrawFilledRect(MinX+LineThick,MaxY-LineThick*2,LineLen,LineThick)
			
			surface.DrawFilledRect(MaxX-LineLen-LineThick,MinY+LineThick,LineLen,LineThick)
			surface.DrawFilledRect(MaxX-LineThick*2,MinY+LineThick,LineThick,LineLen)
			
			surface.DrawFilledRect(MaxX-LineThick*2,MaxY-LineLen-LineThick,LineThick,LineLen)
			surface.DrawFilledRect(MaxX-LineLen-LineThick,MaxY-LineThick*2,LineLen,LineThick)
		}
		
		
		surface.SetColor(255,55,0,255)
		foreach (Corner in Corners)
		{
			//surface.DrawFilledRect(Corner.x*ScreenWidth()-10,Corner.y*ScreenHeight()-10,20,20)
		}
		
		
	}
	
	
	panel.SetCallback( "PaintBackground", Crosshair.bindenv(this) )
	
}

function Muffle()
{
		params.SetSpecialDSP(55)
		params.SetOrigin(self.GetCenter())
		//params.SetFlags(2)
		//printl(params.GetOrigin())
		return
}
function UnMuffle()
{
		//params.SetSpecialDSP(30)
		//printl("unmuffling")
		return
}

function ReplaceFootstep(params)
{	
	//printl(params.GetSoundName())
	
	if (params.GetSoundName().find("Foot")!=null) 
	{
		params.SetSoundName("npc/concrete"+(params.GetSoundName().find("eft")!=null ? RandomInt(3,4) : RandomInt(1,2))+".wav")
		params.SetSoundLevel(80)
		params.SetVolume(params.GetSoundName().find("Run")!=null ? 1 : 0.5)
		params.SetOrigin(self.GetOrigin())
		
	}
}


if (CLIENT_DLL)
{
		
	NetMsg.Receive("CrosshairMark",function(...) {
		LookingAtFriendly=false
		local Item=NetMsg.ReadString()
		ItemClassname=Item
		ItemModel=NetMsg.ReadString()
		if (Item=="None") {ItemName="None";return;}
		if (!(Item in LIST_ITEMS)&&(!(Item in LIST_QUEST_ITEMS))) {Ent=NetMsg.ReadEntity();LookingAtFriendly=NetMsg.ReadBool();Count=1;ItemName=(("GetName" in Ent && Ent.GetName().len()>0) ? Ent.GetName() : Item);return;}
		
		if (Item in LIST_ITEMS) 
			ItemName=LIST_ITEMS[Item].name
		else
			ItemName=LIST_QUEST_ITEMS[Item].name
		
		Count=NetMsg.ReadShort()
		Ent=NetMsg.ReadEntity()
		LookingAtFriendly=NetMsg.ReadBool()
		
		//if (Ent&&Ent.IsValid()&&Ent.GetModelName().find("human")!=null)
		//{
		//	printl("Looking at friendly")
		//}
		
	}.bindenv(this))
	
	NetMsg.Receive("HeatActionReady",function(...) {
		HeatActionReady=true
	}.bindenv(this))
	
	NetMsg.Receive("GetPlayerCameraAngles",function(...) {
		NetMsg.Start("GetPlayerCameraAngles")
		NetMsg.WriteVec3Coord(MainViewAngles())
		NetMsg.Send()
	}.bindenv(this))
	
	NetMsg.Receive("HeatActionUnReady",function(...) {
		HeatActionReady=false
	}.bindenv(this))
	
	NetMsg.Receive("ReviveReady",function(...) {
		ReviveReady=true
	}.bindenv(this))
	
	NetMsg.Receive("ReviveUnReady",function(...) {
		ReviveReady=false
	}.bindenv(this))
	
	NetMsg.Receive("EMITSOUND_CL",function(...) {
		local npc=NetMsg.ReadEntity()
		local enabled=NetMsg.ReadBool()
		//printl("received "+enabled)
		npc.GetOrCreatePrivateScriptScope().ModifyEmitSoundParams<-((enabled) ? UnMuffle : Muffle.bindenv(npc.GetOrCreatePrivateScriptScope()))
		
	}.bindenv(this))
	
	NetMsg.Receive("CHANGE_FOOTSTEPS",function(...) {
		local npc=NetMsg.ReadEntity()
		if (!npc) return;
		
		if ("ModifyFootsteps" in npc.GetOrCreatePrivateScriptScope()) return;
		//printl("received "+enabled)
		printl("REPLACING FOOTSTEPS")
		
		npc.GetOrCreatePrivateScriptScope().ModifyFootsteps<-(ReplaceFootstep.bindenv(npc.GetOrCreatePrivateScriptScope()))
		
		Hooks.Add(npc.GetOrCreatePrivateScriptScope(),"ModifyEmitSoundParams",ReplaceFootstep.bindenv(this),"ModifyFootsteps"+npc.entindex());
		
	}.bindenv(this))
//Entities.First().SetContextThink("CrosshairMarker",function (_) { Crosshair();return 0}.bindenv(this),0.01 )
}