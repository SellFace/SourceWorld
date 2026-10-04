// This VScript is supposed to running at player.
// For example, give it an input like "OnTrigger !player RunScriptFile externalflashlight.nut"
// This VScript is written for EZ2 map Mission Revenge by Gildunёха
// VScript made by HelloTimber, 20251111

//printl("boobs")

MyFlashLight <- null;
MyFlashLight2 <- null;
DisableFlashLight <- null;
FlashLightState <- false;
KeyReleased <- true;
EntFireByHandle(self, "CallScriptFunction", "OnStartRunning", 0.01);
self.PrecacheSoundScript("items/flashlight1.wav");
self.PrecacheSoundScript("items/flashlight2.wav");
LastTime <- Time();
LastMoveTime <- Time();
LastPlrAng <-  player.EyeAngles();
PlrAngOffset <- Vector(0, 0, 0);

// Choose the flashlight style you prefer. 0 for a flashlight fixed on player model's head, or 1 for a fixed flashlight at the view(classic style).
FlashLightStyle <- 1;

// Setting flashlight energy values here.
MaxFlashLightEnergy <- 30.00;
FlashLightBrightness <- 1.50;
EnergyDecreasingRate <- 0.01;
EnergyRegeneratingRate <- 0.04;
BrightnessDieDownRatio <- 5;
FlashLightOffsetRange <- 5;
OffsetMoveRate <- 0.1;
FlashLightOffsetWHrate <- 1.8;
FlashLightFOV <- 50;
FlashLightEnergy <- MaxFlashLightEnergy;
// There are 2 switches of some unique features:
DifferentFlashLightwithDifficulty <- false;
FlashLightMoveWithView <- true;

function OnStartRunning()
{
	// Bind a key to toggle the flashlght. +Score is an unused button in EZ2 singleplayer game.
	//SendToConsole("bind f +score");
	
	FlashLightSetByDifficulty();
	
	// Preventing have multiple flashlight entities in the map
	local theflashlighttest = Entities.FindByName(null, "playerflashlight");
	if(theflashlighttest != null)
		theflashlighttest.Destroy();
	if(theflashlighttest != null)
		theflashlighttest.Destroy();
	theflashlighttest = Entities.FindByName(null, "playernoflashlight");
	if(theflashlighttest != null)
		theflashlighttest.Destroy();
		
	// Spawning flashlight entities.
	// This is the flashlight.
	// This is a sound used for noticing how much energy the flashlight has.
    MyFlashLight = SpawnEntityFromTable("env_projectedtexture"
	{
		targetname = "playerflashlight"
		origin = player.GetOrigin()
		angles = player.GetAngles()
		lightfov = FlashLightFOV
		brightnessscale = FlashLightBrightness
		nearz = 1
		farz = 450
		lightcolor = "255 220 150 200"
		shadowatten = 0.35
		colortransitiontime = 0.0
		constant_attn = 2
		spawnflags=2
		//linear_attn = 0
	})
	MyFlashLight2 = SpawnEntityFromTable("env_projectedtexture"
	{
		targetname = "playerflashlight"
		origin = player.GetOrigin()
		angles = player.GetAngles()
		lightfov = 110
		brightnessscale = FlashLightBrightness*0.03
		nearz = 1
		farz = 300
		lightcolor = "255 220 150 200"
		shadowatten = 0
		colortransitiontime = 0.0
		constant_attn = 2
		spawnflags=2
		//linear_attn = 0
	})
	FlashLightSprite = SpawnEntityFromTable("env_sprite"
	{
		targetname = "playerflashlight"
		origin = player.GetOrigin()
		angles = player.GetAngles()
		model = "sprites/light_glow01.vmt"
		renderamt=200
		rendercolor="255 255 255"
		rendermode=9
		scale=0.15
		spawnflags=1
		GlowProxySize=2.0
	})
	
	
	DisableFlashLight = SpawnEntityFromTable("player_speedmod"
	{
		targetname = "playernoflashlight"
		origin = player.GetOrigin()
		angles = player.GetAngles()
		spawnflags = 0
	})
	EntFireByHandle(DisableFlashLight, "Enable", "", 0.00);
	SettingFlashLightStyle(FlashLightStyle);
}

function FlashLightSetByDifficulty()
{
	// Some difficulty related settings
	if(DifferentFlashLightwithDifficulty)
	{
		MaxFlashLightEnergy = 30.00 - (Convars.GetInt("skill")-1) * 5;
		EnergyRegeneratingRate = 0.04 - (Convars.GetInt("skill")-1) * 0.01;
		BrightnessDieDownRatio = 5 - (Convars.GetInt("skill")-1) * 1;
		FlashLightOffsetRange = 10 - (Convars.GetInt("skill")-1) * 2;
		OffsetMoveRate = 0.4 - (Convars.GetInt("skill")-1) * 0.1;
		FlashLightFOV = 90 - (Convars.GetInt("skill")-1) * 12;
		FlashLightEnergy = MaxFlashLightEnergy;
	}
}

function SettingFlashLightStyle(thevalue)
{
	// You can give player entity an input like "OnTrigger !player RunScriptCodeQuotable SettingFlashLightStyle(0)" to change the style of flashlight.
	FlashLightStyle = thevalue;
	switch(FlashLightStyle)
	{
		// Flashlight style 0, which makes flashlight fixed on playermodel's head.
		case 0:
		{
			EntFireByHandle(MyFlashLight, "SetParent", "!player", 0.05);
			EntFireByHandle(MyFlashLight, "SetParentAttachment", "forward", 0.10);
			EntFireByHandle(MyFlashLight2, "SetParent", "!player", 0.05);
			EntFireByHandle(MyFlashLight2, "SetParentAttachment", "forward", 0.10);
			break;
		}
		// Flashlight style 1, which makes flashlight fixed at view, the classic flashlight.
		case 1:
		{
			EntFireByHandle(MyFlashLight, "SetParent", "", 0.00);
			EntFireByHandle(MyFlashLight2, "SetParent", "", 0.00);
			break;
		}
	}
}

function ToggleFlashlight()
{
	self.EmitSound("items/flashlight"+(1+FlashLightState.tointeger())+".wav");
	
	if(!FlashLightState)
	{
		//EntFireByHandle(player.GetActiveWeapon(), "addeffects",4);
		EntFireByHandle(MyFlashLight, "TurnOn");
		EntFireByHandle(MyFlashLight2, "TurnOn");
		
		for(local i=0;i<10;i++)
		{
			EntFireByHandle(MyFlashLight, "fov",(i*FlashLightFOV)/(10.0),i*0.01);
			EntFireByHandle(MyFlashLight2, "fov",(i*110)/(10.0),i*0.01);
		}
		
		//EntFireByHandle(MyFlashLightSND, "PlaySound");
		FlashLightState = true;
	}
	else
	{
		//EntFireByHandle(player.GetActiveWeapon(), "removeeffects",4);
		EntFireByHandle(MyFlashLight, "TurnOff");
		EntFireByHandle(MyFlashLight2, "TurnOff");
		//EntFireByHandle(MyFlashLightSND, "StopSound");
		FlashLightState = false;
	}
}

Convars.RegisterCommand( "impulse", function(...)
{
	switch( vargv[1] )
	{
		// allow flashlight while player is not wearing suit
		case "100":
		{
			ToggleFlashlight()
			return false
		}
		
		case "101":
		{
			if (vargv.len()>2&&vargv[2].tolower()=="please")
			{
				GiveItem("weapon_pipe")
				GiveItem("weapon_pistol",1,18)
				GiveItem("weapon_357",1,6)
				GiveItem("weapon_m590",1,8)
				GiveItem("weapon_mp7",1,45)
				GiveItem("weapon_m4a1",1,30)
				GiveItem("health_kit")
				printl("finee, here you go")
			}
			else printl("nuh uh uh, you didn't say the magic word");
			return false;
		}
	}

	// allow any other impulse command
	return true

}.bindenv(this), "", 0 )

local lastvel=0;
local veltime=0;

local LastSpark=Time();

function PlayerRunCommand()
{
	
	if(LastTime == Time())
	{
		return;
	}
	LastTime = Time();
	
	local OffsetValue = player.GetLocalAngles() - LastPlrAng;
	if(OffsetValue.y >= 180)
		OffsetValue = Vector(OffsetValue.x,OffsetValue.y-360.00,OffsetValue.z)
	if(OffsetValue.y <= -180)
		OffsetValue = Vector(OffsetValue.x,OffsetValue.y+360.00,OffsetValue.z)
	PlrAngOffset = PlrAngOffset+ OffsetValue * OffsetMoveRate;
	PlrAngOffset*=(clamp(1-(Time()-LastMoveTime)*0.5,0,1))
	
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
	if ((LastPlrAng-player.GetLocalAngles()).Length()>1) LastMoveTime=Time();
	
	// If player is dead, automatically turn it off the flashlight and can't turn it on.
	if(!player.IsAlive())
	{
		EntFireByHandle(MyFlashLight, "TurnOff");
		EntFireByHandle(MyFlashLight2, "TurnOff");
		FlashLightState = false;
		return;
	}
	
	// Flashlight style 1, which makes flashlight fixed at view, the classic flashlight.
	if(FlashLightStyle == 1&&MyFlashLight)
	{
		local vel=player.GetVelocity().Length()*0.1
		vel=sqrt(vel)+0.9
		veltime+=IntervalPerTick()*vel*1.5
		local bob=Vector(fabs(sin(veltime)+0.2)*vel*0.4,cos(veltime*0.8)*vel*0.3,sin(Time()*0.5)*5+cos(veltime)*vel*0.5)
		
		
		//MyFlashLight.SetLocalOrigin(player.EyePosition()+Vector(0,0,-8)-player.GetEyeForward()*12);
		//MyFlashLight.SetLocalAngles(player.GetLocalAngles()-(player.GetLocalAngles()-player.EyeAngles())+PlrAngOffset+bob);
		//MyFlashLight2.SetLocalOrigin(player.EyePosition()+Vector(0,0,-8)-player.GetEyeForward()*12);
		//MyFlashLight2.SetLocalAngles(player.GetLocalAngles()-(player.GetLocalAngles()-player.EyeAngles())+PlrAngOffset+bob);
		
		
		//printl(player.GetLocalAngles()-player.EyeAngles())
		
		//MyFlashLight.SetLocalAngles(player.GetLocalAngles());
		//MyFlashLight2.SetLocalAngles(player.GetLocalAngles());
		
		//MyFlashLight.SetLocalAngles(player.GetLocalAngles()-(player.GetLocalAngles()-player.EyeAngles()));
		//MyFlashLight2.SetLocalAngles(player.GetLocalAngles()-(player.GetLocalAngles()-player.EyeAngles()));
		
		LastPlrAng = player.GetLocalAngles();
		
		if (vel>lastvel) lastvel+=min(vel-lastvel,1)
		if (vel<=lastvel) lastvel-=min(lastvel-vel,1)
	}

	if(FlashLightState)
	{
		FlashLightEnergy = FlashLightEnergy - EnergyDecreasingRate;
		
		//printl(FlashLightEnergy)
		
		if (FlashLightEnergy<2.1&&Time()-LastSpark>0)
		{	
			LastSpark=Time()+RandomFloat(FlashLightEnergy*0.1+0.2,FlashLightEnergy+0.2)
			GetNamedEnt("stamina_system").GetScriptScope().PlaySoundAtPlayer("ambient/energy/spark"+RandomInt(1,6)+".wav",0.05)
		}
		
		local rng=(2+RandomFloat(0.9,1.1))/3.0
		
		if(FlashLightEnergy > FlashLightBrightness*BrightnessDieDownRatio)
		{
			
			EntFireByHandle(MyFlashLight, "SetBrightness", FlashLightBrightness*rng);
			rng=(2+RandomFloat(0.9,1.1))/3.0
			EntFireByHandle(MyFlashLight2, "SetBrightness", FlashLightBrightness*0.03*rng);
		}
		if(FlashLightEnergy <= FlashLightBrightness*BrightnessDieDownRatio)
		{
			EntFireByHandle(MyFlashLight, "SetBrightness", (rng*FlashLightEnergy)/(BrightnessDieDownRatio*(1+(RandomFloat(0,FlashLightBrightness*FlashLightBrightness*2)>FlashLightEnergy+2).tointeger()*2)));
			EntFireByHandle(MyFlashLight2, "SetBrightness", (rng*0.03*FlashLightEnergy)/(BrightnessDieDownRatio*(1+(RandomFloat(0,FlashLightBrightness*FlashLightBrightness*2)>FlashLightEnergy+2).tointeger()*2)));
		}
		if(FlashLightEnergy <= 0.01)
		{
			EntFireByHandle(MyFlashLight, "TurnOff");
			EntFireByHandle(MyFlashLight2, "TurnOff");
			FlashLightState = false;
		}
	}
	else
	{
		if(FlashLightEnergy < MaxFlashLightEnergy)
		{
			FlashLightEnergy = FlashLightEnergy + EnergyRegeneratingRate;
		}
	}
}