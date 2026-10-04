if (CLIENT_DLL)
{

local RANDS=RandomInt(0,999).tostring()
surface.CreateFont( "GameMenuSW",        // Name of this font entry (user-defined, can be anything)
{
	"name"            : "Mensura 3"    // Name of the font file
	"tall"            : 20        // Size of the text
	"weight"        : 100        // Amount of boldness to add
	//"blur"            : 1        // Amount of blur to add (optional)
    "antialias"     : true            // Enables font smoothing
	"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
} );
local GameMenuFont=surface.GetFont( "GameMenuSW", true )
surface.CreateFont( "GameMenuSW2",        // Name of this font entry (user-defined, can be anything)
{
	"name"            : "Mensura 3"    // Name of the font file
	"tall"            : 20        // Size of the text
	"weight"        : 800        // Amount of boldness to add
	//"blur"            : 1        // Amount of blur to add (optional)
    "antialias"     : true            // Enables font smoothing
	"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
} );
local GameMenuFont2=surface.GetFont( "GameMenuSW2", true )
surface.CreateFont( "GameMenuSWGlow",        // Name of this font entry (user-defined, can be anything)
{
	"name"            : "Mensura 3"    // Name of the font file
	"tall"            : 20        // Size of the text
	"weight"        : 800        // Amount of boldness to add
	"blur"            : 3        // Amount of blur to add (optional)
    "antialias"     : true            // Enables font smoothing
	"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
} );
local GameMenuFontGlow=surface.GetFont( "GameMenuSWGlow", true )


local MenuStartTime=Time()+0.35
local GameMenuTime=(-1);

local MenuX=YRES(45)
local MenuY=YRES(155)


class GameMenuButton
{
	pos=0
	text="Button"
	command=""
	button=null
	focused=false
	focustime=-1
	
	constructor(params)
	{
		pos=params.pos
		text=Localize.GetTokenAsUTF8(params.text)
		command=params.command
		
	}
	
	function Create()
	{
		button = vgui.CreatePanel("Panel", vgui.GetGameUIRootPanel(), "CustomMainMenuButton_"+text)
		button.SetSize(surface.GetTextWidth(GameMenuFont,text)+YRES(40),surface.GetFontTall(GameMenuFont))
		button.SetPos(MenuX,MenuY+surface.GetFontTall(GameMenuFont)*1.5*pos)
		button.SetKeyBoardInputEnabled(true)
		button.MakeReadyForUse()
		button.MakePopup()
		button.SetAlpha(0)
		
		button.SetCallback( "Paint", this.Draw.bindenv(this) )
		button.SetCallback( "OnCursorEntered", this.Focus.bindenv(this) )
		button.SetCallback( "OnCursorExited", this.UnFocus.bindenv(this) )
		button.SetCallback( "OnMousePressed", this.Press.bindenv(this) )
	}
	
	function Press(a)
	{
		if (a!=ButtonCode.MOUSE_LEFT) return;
		
		surface.PlaySound("ui/buttonclickrelease.wav")
		
		NetMsg.Start("SWMenuClick")
		NetMsg.WriteString(command)
		NetMsg.Send()
	}
	
	function Focus() 
	{
		surface.PlaySound("ui/buttonrollover.wav")
		focused=true;
		focustime=Time()
	}
	function UnFocus()
	{	
		focustime=Time()
		focused=false;
	}
	
	
	function Draw()
	{
		local FocusMultiplier=clamp(sqrt(Time()-focustime)*2,0,1)
		if (!focused) FocusMultiplier=1-FocusMultiplier;
		local FocusOffset=YRES(8)*FocusMultiplier
		
		surface.DrawColoredText(focused ? GameMenuFont2 : GameMenuFont,YRES(3)+FocusOffset+YRES(2),YRES(2),15,15,15,225-100*FocusMultiplier,text)
		surface.DrawColoredText(focused ? GameMenuFont2 : GameMenuFont,YRES(3)+FocusOffset,0,21,230,80+100*FocusMultiplier,255,text)
		
		button.SetAlpha(clamp((Time()-GameMenuTime-0.7)*200,0,255))
		Title.SetDrawColor(255,255,255,clamp((Time()-GameMenuTime-0.7)*200,0,255))
		
		if (FocusMultiplier>0)
		{
			surface.SetColor(21,230,80+20*FocusMultiplier,175*FocusMultiplier)
			surface.DrawOutlinedCircle(YRES(-8)+FocusOffset+YRES(3),surface.GetFontTall(GameMenuFont)/2,YRES(4),clamp((Time()-focustime)*4+2,1,3))
			
			surface.DrawColoredText(GameMenuFontGlow,YRES(3)+FocusOffset,0,21,230,80+100*FocusMultiplier,105*fabs(sin(Time()))*FocusMultiplier,text)
		}
		
	}

}

local ButtonTables=[]

ButtonTables.append(
{
	pos = 0
	text = "#GameUI_GameMenu_NewGame"
	command = "ent_fire stamina_system callscriptfunctionclient DisplayNewGamePanels"
})
ButtonTables.append(
{
	pos = 1
	text = "TRAINING"
	command = "ent_fire stamina_system callscriptfunctionclient DisplayTrainingPanels"
})
ButtonTables.append(
{
	pos = 3
	text = "#GameUI_GameMenu_LoadGame"
	command = "ent_fire stamina_system callscriptfunctionclient DisplayLoadPanels"
})
//ButtonTables.append(
//{
//	pos = 5
//	text = "#GameUI_GameMenu_Achievements"
//	command = "gamemenucommand OpenAchievementsDialog"
//})
ButtonTables.append(
{
	pos = 5
	text = "#GameUI_GameMenu_Options"
	command = "gamemenucommand OpenOptionsDialog"
})
ButtonTables.append(
{
	pos = 6
	text = "ADVANCED OPTIONS"
	command = "ent_fire stamina_system callscriptfunctionclient DisplayOptions"
})
ButtonTables.append(
{
	pos = 8
	text = "#GameUI_GameMenu_Quit"
	command = "gamemenucommand Quit"
})

local GameMenuItems=[]

foreach (button in ButtonTables) GameMenuItems.append(GameMenuButton(button))

surface.CreateFont( "TitleScreen",        // Name of this font entry (user-defined, can be anything)
{
	"name"            : "Mensura 3"    // Name of the font file
	"tall"            : 30        // Size of the text
	"weight"        : 0        // Amount of boldness to add
	//"blur"            : 1        // Amount of blur to add (optional)
	"additive"        : true        // Renders font by brightening pixels behind it (default for game_text)
    "antialias"     : true            // Enables font smoothing
    "dropshadow"     : true            // Adds a drop shadow to the font
	"italic"     : true            
	"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
} );
surface.CreateFont( "TitleScreenWide",        // Name of this font entry (user-defined, can be anything)
{
	"name"            : "Mensura 3"    // Name of the font file
	"tall"            : 30        // Size of the text
	"weight"        : 1000        // Amount of boldness to add
	//"blur"            : 1        // Amount of blur to add (optional)
	"italic"	: true
    "antialias"     : true            // Enables font smoothing
    "dropshadow"     : true            // Adds a drop shadow to the font         
	"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
} );
surface.CreateFont( "TitleScreenBlur",        // Name of this font entry (user-defined, can be anything)
{
	"name"            : "Mensura 3"    // Name of the font file
	"tall"            : 30        // Size of the text
	"weight"        : 0        // Amount of boldness to add
	"blur"            : 5        // Amount of blur to add (optional)
	"additive"        : true        // Renders font by brightening pixels behind it (default for game_text)
    "antialias"     : true            // Enables font smoothing
    "dropshadow"     : true            // Adds a drop shadow to the font
	"italic"     : true            
	"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
} );
local TitleFont=surface.GetFont( "TitleScreen", true )
local TitleFontWide=surface.GetFont( "TitleScreenWide", true )
local TitleFontBlur=surface.GetFont( "TitleScreenBlur", true )

printl("GAME MENU INITIALIZED ON CLIENT")
local Menu= vgui.CreatePanel("Panel", vgui.GetGameUIRootPanel(), "CustomMainMenu")
Menu.SetSize(ScreenWidth(),ScreenHeight())
Menu.SetKeyBoardInputEnabled(true)
Menu.MakeReadyForUse()
Menu.MakePopup()
Menu.SetCursor(CursorCode.dc_blank)

::Title<- vgui.CreatePanel("ImagePanel", Menu, "TitleSW")
Title.SetImage("vgui/logo/Title",false)
Title.MakeReadyForUse()
Title.SetVisible(true)
Title.SetDrawColor(255,255,255,255)
Title.SetShouldScaleImage(true)
Title.SetSize(YRES(540),YRES(135))
Title.SetPos(XRES(320)-Title.GetWide()/2-YRES(7), YRES(155))
Title.SetCursor(CursorCode.dc_blank)

Convars.SetFloat("mat_bloomscale",4000);


function PaintTitle()
{
	local ScreenBlur=1-clamp((Time()-MenuStartTime-1.2)/5.0,0,0.6)
	Convars.SetFloat("mat_screen_blur_override",ScreenBlur);
	
	if (Time()-MenuStartTime>3) Convars.SetFloat("mat_bloomscale",1);
	
	
	if (GameMenuTime+0.5<Time()&&GameMenuTime>0) 
	{
		Title.SetDrawColor(0,0,0,0)
		
		return
	}
	else
	{
		if (Time()-MenuStartTime<3.5)
		{
			Convars.SetFloat("cl_rumblescale",0.0)
		}
		else Convars.SetFloat("cl_rumblescale",1.0);
		
		

		local C=clamp((Time()-MenuStartTime)*100,0,255)
		
		local Glow=25+25*sin(Time()*1.5)
		local TitleTextAppear=clamp((Time()-MenuStartTime),0,1)
		local TitleTextAppear2=clamp((Time()-MenuStartTime-5.2),0,1)
		local TitleLogoAppear=pow(clamp((Time()-MenuStartTime-2.8)/3.0,0,1),2)
		
		if (GameMenuTime>0) 
		{
			TitleTextAppear=1;
			TitleTextAppear2=1;
			TitleLogoAppear=1;
		}
		
		Title.SetDrawColor(C,C-25-25*(cos(Time()*2)),C,TitleLogoAppear*255)
		
		if (Convars.GetInt("developer")!=1)
		{
			
			surface.SetColor(0,0,0,255-255*TitleTextAppear)
			surface.DrawFilledRect(0,0,ScreenWidth(),ScreenHeight())
			surface.DrawFilledRect(0,0,ScreenWidth(),ScreenHeight())
			surface.SetColor(0,0,0,255*TitleTextAppear2)
			
			
			local Margin=YRES(0)
			
			local IsPressed=(GameMenuTime>0).tointeger()
			local PressBlink=clamp(pow(fabs(sin((Time()-GameMenuTime)*6)),2),1-IsPressed,1)
			
			if (IsPressed==1) Glow=50;
			
			surface.DrawFilledRectFade(Margin,YRES(330),ScreenWidth()-Margin*2,surface.GetFontTall(TitleFontBlur)/2,255,0,false)
			surface.DrawFilledRectFade(Margin,YRES(330)+surface.GetFontTall(TitleFontBlur)/2,ScreenWidth()-Margin*2,surface.GetFontTall(TitleFontBlur)/2,0,255,false)
			
			surface.DrawFilledRectFade(Margin,YRES(330),ScreenWidth()/2-Margin,surface.GetFontTall(TitleFontBlur),255,0,true)
			surface.DrawFilledRectFade(Margin+ScreenWidth()/2-Margin,YRES(330),ScreenWidth()/2-Margin,surface.GetFontTall(TitleFontBlur),0,255,true)
			
			surface.DrawColoredText(TitleFontBlur,ScreenWidth()/2-surface.GetTextWidth(TitleFontBlur,"PRESS ANY KEY TO START")/2,YRES(330),35,255,65,Glow*TitleTextAppear2*PressBlink,"PRESS ANY KEY TO START")
			surface.DrawColoredText(TitleFont,ScreenWidth()/2-surface.GetTextWidth(TitleFont,"PRESS ANY KEY TO START")/2+YRES(2),YRES(332),15,15,15,TitleTextAppear2*(100+Glow*3)*PressBlink,"PRESS ANY KEY TO START")
			surface.DrawColoredText(TitleFont,ScreenWidth()/2-surface.GetTextWidth(TitleFont,"PRESS ANY KEY TO START")/2,YRES(330),35,255,65,TitleTextAppear2*(100+Glow*3)*PressBlink,"PRESS ANY KEY TO START")
			
		}
		
	}
}

function KeyPress(a)
{
	if (Time()<2.5) return;
	if (GameMenuTime>0) return;
	surface.PlaySound("common/launch_select1.wav")
	surface.PlaySound("ui/buttonclickrelease.wav")
	GameMenuTime=Time()
	
	NetMsg.Start("StartSWMenu")
	NetMsg.Send()
	
	Entities.First().SetContextThink("GameMenuCreate",function(_) 
	{
		Convars.SetFloat("mat_screen_blur_override",0.4);
	
		Convars.SetFloat("mat_bloomscale",1);
		
		Convars.SetFloat("cl_rumblescale",1.0);
		
		Menu.SetCursor(CursorCode.dc_arrow)
		Title.SetCursor(CursorCode.dc_arrow)
		
		Menu.Destroy()
		
		foreach (Button in GameMenuItems)
		{
			Button.Create()
		}
		
		Title= vgui.CreatePanel("ImagePanel", vgui.GetGameUIRootPanel(), "TitleSW")
		Title.SetImage("vgui/logo/MenuLogo",false)
		Title.MakeReadyForUse()
		Title.SetVisible(true)
		Title.SetDrawColor(255,255,255,255)
		Title.SetShouldScaleImage(true)
		Title.SetSize(YRES(300),YRES(75))
		Title.SetPos(MenuX-YRES(10),MenuY-YRES(120))
		
	}.bindenv(this),0.5)
	
}

Menu.SetCallback( "Paint", PaintTitle )
Menu.SetCallback( "OnKeyCodePressed", KeyPress )

function DoClick(a)
{
	 KeyPress(1)
}


Menu.SetCallback( "OnMousePressed", DoClick )
Menu.SetCallback( "OnMouseDoublePressed", DoClick )

}

if (SERVER_DLL)
{
SendToConsoleServer("hideconsole")
// Stops pausing the menu when loaded into it while having console open.

local Cam=Entities.FindByName(null,"menucam")

local Start=Vector(1600,320,277)
local End=Vector(-1,320,87)
local EndAngle=Vector(-4,0,0)
local Speed=1



Entities.First().SetContextThink("TitleScreenStart",function(_) 
{
	Cam=Entities.FindByName(null,"menucam")
	
	if (Cam==null) return 0;
	Cam.PrecacheSoundScript("*#ui/gamestartup1.mp3")
	Cam.PrecacheSoundScript("*#ui/gamestartup2.mp3")
	Cam.EmitSound("*#ui/gamestartup1.mp3")
	Cam.SetOrigin(Start)
	//Cam.SetFov(20,0)
	EntFire("menucam","SetFOVRate",4,0.1)
	EntFire("menucam","SetFOV",180,0)
	EntFire("menucam","SetFOV",80,1)
	
	EntFire("tp_online3","PlaySound","",1.8)
	
	// This is important to make sure vanilla gameui fucks off and doesn't pause our custom main menu at the start
	// whether it be because player had console on, or because we forcefully went to main menu.
	SendToConsole("gameui_activate;gameui_hide;hideconsole;unpause")	
	
	EntFire("func_monitor","Kill")
	// Kill those to increase fps.

	return
},0)

NetMsg.Receive("StartSWMenu", function( player )
{
	Entities.First().SetContextThink("CamMove",function(_) 
	{
		End=Entities.FindByName(null,"menucam2").GetOrigin()
		EndAngle=Entities.FindByName(null,"menucam2").GetAngles()
		Speed=4.0
		EntFire("menucam","SetFOV",85,0.1)
		EntFire("menucam","SetParent","cheaple",5/Speed+0.5)
		EntFire("menucam","SetFOVRate",4/Speed,0)
		//SendToConsoleServer("stopsound")
		//SendToConsoleServer("play *#ui/gamestartup2.mp3")
		Cam.StopSound("*#ui/gamestartup1.mp3")
		Cam.EmitSound("*#ui/gamestartup2.mp3")
	},0.5)
} );

NetMsg.Receive("SWMenuClick", function( player )
{
	local cmd=NetMsg.ReadString()
	
	SendToConsoleServer(cmd)
} );

Entities.First().SetContextThink("TitleScreenCamera",function(_) 
{
	Cam.SetVelocity((End-Cam.GetOrigin())*clamp(Time()-2.5,0.5,1)*Speed)
	
	local distx=AngleDistance(EndAngle.x,Cam.GetAngles().x)
	local disty=AngleDistance(EndAngle.y,Cam.GetAngles().y)
	local distz=AngleDistance(EndAngle.z,Cam.GetAngles().z)
	
	Cam.SetAngularVelocity(distx*Speed,disty*Speed,distz*Speed)
	//printl(Cam.GetOrigin())
	//Cam.SetFov(RemapVal((End-Cam.GetOrigin()).Length(),0,(End-Start).Length(),80,20),IntervalPerTick())
	//Cam.SetFov(80,31)
	if ((End-Cam.GetOrigin()).Length()<1)
	{
		Cam.SetVelocity(Vector())
		return 0
	}
	
	return 0
	
},0)

}