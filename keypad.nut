
function Think()
{
	return 1
}

function Everything()
{
	const SIZE=350
	
	if ( CLIENT_DLL )
	{
		surface.CreateFont( "KPAD112",        // Name of this font entry (user-defined, can be anything)
		{
			"name"            : "MxPlus HP 150 re."    // Name of the font file
			"tall"            : 28        // Size of the text
			"weight"        : 300        // Amount of boldness to add
			//"blur"            : 1        // Amount of blur to add (optional)
			//"additive"        : true        // Renders font by brightening pixels behind it (default for game_text)
		    "antialias"     : true            // Enables font smoothing
		   // "dropshadow"     : false            // Adds a drop shadow to the font
			"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
		} );
		local Font1=surface.GetFont( "KPAD112", true )		
		
		surface.CreateFont( "KPAD22",        // Name of this font entry (user-defined, can be anything)
		{
			"name"            : "MxPlus HP 150 re."    // Name of the font file
			"tall"            : 8        // Size of the text
			"weight"        : 300        // Amount of boldness to add
			//"blur"            : 1        // Amount of blur to add (optional)
			"additive"        : true        // Renders font by brightening pixels behind it (default for game_text)
		    "antialias"     : true            // Enables font smoothing
		   // "dropshadow"     : false            // Adds a drop shadow to the font
			"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
		} );
		local Font3=surface.GetFont( "KPAD22", true )
		
		surface.CreateFont( "KPADS3",        // Name of this font entry (user-defined, can be anything)
		{
			"name"            : "MxPlus HP 150 re."    // Name of the font file
			"tall"            : 28        // Size of the text
			"weight"        : 300        // Amount of boldness to add
			"blur"            : 1        // Amount of blur to add (optional)
		    "antialias"     : true            // Enables font smoothing
		   // "dropshadow"     : false            // Adds a drop shadow to the font
			"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
		} );
		local Font2=surface.GetFont( "KPADS3", true )
		
		PASSWORDS<-{}
		
		PASSWORD <- null;
		PASSWORD = "0451"; 
		
		local Code=""
		
		local LastOpen=0;
		local LastFail=0;
		local LastPress=0;
		local LastKey=null;
		local LastKP=0;
		
		bg_panel <- null;
		m_panel <- null;
		buttons <- [];
		
		local ButtonSize=YRES(31)
		local HorGap=YRES(8.5)
		local VerGap=YRES(6)
		
		local LastHide=0;
		local Hiding=false;
		
		
		
		// File-backed material: load once per UI initialization, never during Paint.
		local KeypadTexture = surface.ValidateTexture("vgui/keypad", true, false, false);

		function Paint()
		{
			if ((Time()-LastPress)>0.1) LastKey=null;
			
			local mod=pow(RemapValClamped(Time()-LastKP,0,0.5,0,1),0.25)
			
			if (Hiding) mod=1-RemapValClamped(Time()-LastHide,0,0.1,0,1);
			
			
			m_panel.SetAlpha(mod*255)
			
			bg_panel.SetBgColor( 0, 0, 0, mod*220 );
			
			
			surface.SetColor(255,255,255,255)
			surface.SetTexture(KeypadTexture)
			
			surface.DrawTexturedRect(YRES(SIZE)*(1-mod)*0.5,YRES(SIZE)*(1-mod)*0.5,YRES(SIZE)*mod,YRES(SIZE)*mod)
			
			if ( Hiding&&((Time()-LastHide)>0.2)&&bg_panel && bg_panel.IsValid() )
			{
				bg_panel.Destroy();
				bg_panel = null;
				Hiding=false;
			}
			
			if (mod<0.99) return;
			
			surface.DrawColoredText(Font2,YRES(SIZE)/2-surface.GetTextWidth(Font2,"8888")/2,YRES(SIZE)*0.25-YRES(2),5,5,5,255,Code)
			surface.DrawColoredText(Font2,YRES(SIZE)/2-surface.GetTextWidth(Font2,"8888")/2,YRES(SIZE)*0.25-YRES(2),5,5,5,155,"----")
			surface.DrawColoredText(Font2,YRES(SIZE)/2-surface.GetTextWidth(Font2,"8888")/2,YRES(SIZE)*0.25,5,5,5,255,Code)
			surface.DrawColoredText(Font2,YRES(SIZE)/2-surface.GetTextWidth(Font2,"8888")/2,YRES(SIZE)*0.25,5,5,5,255,Code)
			surface.DrawColoredText(Font1,YRES(SIZE)/2-surface.GetTextWidth(Font1,"8888")/2,YRES(SIZE)*0.25,225,225,225,255,Code)
			
			if (Code.len()>0) 
				surface.DrawColoredText(Font2,YRES(SIZE)/2-surface.GetTextWidth(Font1,"8888")/2+surface.GetTextWidth(Font1,Code.slice(0,Code.len()-1)),YRES(SIZE)*0.25,255,255,255,255-255*Bias(clamp(Time()-LastPress,0,0.1)*10,0.2),Code.slice(Code.len()-1))
			
			if (Code==""&&(Time()-LastFail)<1)
			{
				surface.DrawColoredText(Font3,YRES(SIZE)/2-surface.GetTextWidth(Font3,"ACCESS DENIED")/2,YRES(SIZE)*0.27,225,5,5,255,"ACCESS DENIED")
			}
			
			else if (Code==""&&(Time()-LastOpen)<1)
			{
				surface.DrawColoredText(Font3,YRES(SIZE)/2-surface.GetTextWidth(Font3,"ACCESS GRANTED")/2,YRES(SIZE)*0.27,5,225,5,255,"ACCESS GRANTED")
			}
			
			
			surface.SetColor(25,11,11,205)
			surface.DrawFilledRect(YRES(SIZE)-YRES(95), YRES(35), YRES(15), YRES(15))


			for (local i=0;i<10;i++)
			{
				surface.SetColor(25,11,11,0)
				
				if (buttons[i].IsCursorOver())
				{
					LastKey=i
				}
				
				if (i==LastKey)
				{
					surface.SetColor(255,255,255,4+fabs(sin(Time()*2))*4)
					
					if ((Time()-LastPress)<0.1)
					{
						local m=Bias((Time()-LastPress)*10,0.2)
						
						surface.SetColor(5,5,5,175*m)
					}
				}
				
				
				if (i==9) i++;
				
				local x=(ButtonSize+HorGap)*(i%3)
				local y=(ButtonSize+VerGap)*(i/3)
				
				
				surface.DrawFilledRect(YRES(121)+x, YRES(143)+y, ButtonSize,ButtonSize)
			}
			
		}
		
		function CheckCode()
		{
			if (Code.len()>3&&(Time()-LastPress)>0.5)
			{
				//printl(correct_code+"   "+labeltext)
				if (Code==""+PASSWORD)
				{
					NetMsg.Start("correct");
					NetMsg.Send();
					LastOpen=Time();
					Code=""
				}
				else
				{
					NetMsg.Start("wrong");
					NetMsg.Send();
					LastFail=Time();
					Code=""
				}
			}
		}
		
		function DoClick(a)
		{
			if (Code.len()>3) return;
			
			a++
			if (a>9) a=0;
			
			surface.PlaySound("buttons/keypad_press.wav")
			//printl(a)
			Code=Code+a.tostring()
			LastPress=Time()
		}
		
		function KeyCode(a)
		{
			//printl(a)
			
			local i=null
			
			if ((a-1)<10&&(a-1)>=0) i=(a-2)
				
			
			if ((a-37)<10&&(a-37)>=0) i=(a-38)
				
			if (i==null) return;
				
			DoClick(i)
			
			if (i==-1) i=9;
			
			LastKey=i;
			
			//if (i==-1) i=10;
			//	
			//local x=(ButtonSize+HorGap)*(i%3)
			//local y=(ButtonSize+VerGap)*(i/3)
			//	
			//input.SetCursorPos(m_panel.GetXPos()+YRES(121)+x+ButtonSize/2, m_panel.GetYPos()+YRES(143)+y+ButtonSize/2)
				
			
		}
		
		function DisplayPanels()
		{
			if ( bg_panel && bg_panel.IsValid() )
				return;
				
			if ((Time()-LastOpen<2))
				return;
			
			Hiding=false;
			
			Code=""
			
			LastKP=Time()
			buttons=[]
			LastKey=null;
			
			bg_panel = vgui.CreatePanel( "Panel", vgui.GetClientDLLRootPanel(), "ExamplePanel" );
			bg_panel.MakeReadyForUse();
			bg_panel.SetBgColor( 0, 0, 0, 0 );
			bg_panel.SetPos( 0,0 );
			bg_panel.SetSize( ScreenWidth(),ScreenHeight() );
			//bg_panel.SetCallback( "Paint", PaintBG.bindenv(this) )
			//bg_panel.SetMouseInputEnabled(true);
			//bg_panel.MakePopup();
			//bg_panel.SetAlpha(0)
			

			m_panel = vgui.CreatePanel( "Panel", bg_panel, "ExamplePanel" );
			m_panel.MakeReadyForUse();
			m_panel.SetPaintEnabled( true );
			m_panel.SetPaintBackgroundEnabled( true );
			m_panel.SetPaintBackgroundType( 2 );
			m_panel.SetBgColor( 0, 0, 0, 0 );
			m_panel.SetPos( (ScreenWidth()/2)-YRES(SIZE)/2,(ScreenHeight()/2)-YRES(SIZE)/2 );
			m_panel.SetSize( YRES(SIZE),YRES(SIZE) );
			m_panel.SetCallback( "Paint", Paint.bindenv(this) )
			m_panel.SetCallback( "OnKeyCodePressed", KeyCode.bindenv(this) );
			m_panel.SetMouseInputEnabled(true);
			m_panel.MakePopup();
			m_panel.SetAlpha(0)
			
			local cross = vgui.CreatePanel( "Label", m_panel, "ExampleLabeel" );
			cross.MakeReadyForUse();
			cross.SetPaintEnabled( true );
			cross.SetPos( YRES(SIZE)-YRES(80)-YRES(15)/2-surface.GetTextWidth(12,"X")/2, YRES(50)-YRES(15)/2-surface.GetFontTall(12)/2 );
			cross.SetPaintBackgroundEnabled( false );
			cross.SetFgColor( 150, 0, 0, 255 );
			cross.SetFont( 12 );
			cross.SetText( "X" );
			
			local close = vgui.CreatePanel( "Button", m_panel, "ExampleButton" );
			close.SetPaintEnabled( true );
			close.SetPaintBorderEnabled( true );
			close.SetText("");
			close.SetContentAlignment(4);
			close.SetDefaultColor( 200, 0, 0, 255, 0, 0,0,0 );
			close.SetPos( YRES(SIZE)-YRES(95), YRES(35) );
			close.SetSize(YRES(15), YRES(15) );
			close.SetCallback( "DoClick", Close.bindenv(this) );
			
			m_panel.AddTickSignal(1);
			m_panel.SetCallback("OnTick", function() {
				CheckCode()
			}.bindenv(this));
			
			
			for (local i=0;i<10;i++)
			{
				if (i==9) i++;
				
				local x=(ButtonSize+HorGap)*(i%3)
				local y=(ButtonSize+VerGap)*(i/3)
				
				local c=i
				
				
				buttons.append(vgui.CreatePanel( "Button", m_panel, "ExampleButton" ))
				buttons[buttons.len()-1].SetPaintEnabled( true );
				buttons[buttons.len()-1].SetPaintBorderEnabled( false );
				buttons[buttons.len()-1].MoveToFront();
				buttons[buttons.len()-1].SetPos( YRES(121)+x, YRES(143)+y );
				buttons[buttons.len()-1].SetSize( ButtonSize,ButtonSize );
				buttons[buttons.len()-1].SetCallback( "DoClick", function (b=0) {DoClick(c)}.bindenv(this) );
			}
			
		}
		
		function Clear()
		{
			//labeltext="";
			//label.SetText( labeltext );
		}
		
		function Close()
		{
			HidePanels()
		}
		
		function HidePanels()
		{
			Hiding=true
			LastHide=Time();
		}

		surface.CreateFont( "examplefont",
		{
			name			= "Arial Black",
			tall			= 14,
			weight			= 400,
			antialias		= true,
			proportional	= false
		} );
		//DisplayPanels();
		
		NetMsg.Receive("SetKeypadCode", function()
		{
			PASSWORDS.rawset(NetMsg.ReadString(),NetMsg.ReadString())
		}.bindenv(this) );
		
		NetMsg.Receive("OpenKeypadCode", function()
		{
			DisplayPanels();
			PASSWORD=PASSWORDS[NetMsg.ReadString()]
		}.bindenv(this) );
		
		NetMsg.Receive("HideKeypadCode", function()
		{
			HidePanels();
		}.bindenv(this) );
	}

	if ( SERVER_DLL )
	{
		::CODES<-{}
		
		keypad_prop_name<-""
		
		NetMsg.Receive("wrong", function( player )
		{
			SendToConsole("play buttons/keypad_denied.wav");
		} );

		NetMsg.Receive("correct", function( player )
		{
			SendToConsole("play buttons/keypad_granted.wav");
			EntFire("keypad","runscriptcode","Hideme()",1.0);
			EntFire(keypad_prop_name,"fireuser1","",1.0)
		}.bindenv(this) );

	}

}

Everything();
function Keypad()
{
	NetMsg.Start("OpenKeypadCode");
	NetMsg.WriteString(caller.GetName())
	NetMsg.Send(player, true);
	keypad_prop_name=caller.GetName()
}

const a=75
const b=74
const m=65537
rng<-null

::RNG<-function()
{
	local seed=date().sec.tostring()+date().min.tostring()+date().hour.tostring()+((clock()*100)%1000).tostring()
	if (rng==null) rng=seed.tointeger();
	rng=(rng*a+b)%m
	//printl(rng)
	return rng
}

if (GetNamedEnt("RANDOM_CASE"))
{
	local cases=0
	while (GetNamedEnt("RANDOM_CASE").GetKeyValue("Case0"+(cases+1)).len()>0) cases++;
	EntFire("RANDOM_CASE","FireOutput","OnCase0"+(1+abs(RNG())%cases))
}

function InputSetCode()
{
	RandomInt(1,100)
	RandomInt(1,100)
	
	
	NetMsg.Start("SetKeypadCode");
	if (parameter.tolower()=="random") parameter=format("%.4i",abs(RNG()%10000))
	keypad_prop_name=caller.GetName()
	NetMsg.WriteString(keypad_prop_name)
	NetMsg.WriteString(parameter)
	NetMsg.Send(player, true);
	CODES.rawset(keypad_prop_name,parameter)
	EntFire(keypad_prop_name+"_text","SetMessage",parameter)
	printl(keypad_prop_name+" set code to "+parameter)
	
	if (GetNamedEnt(keypad_prop_name+"_decals"))
	{
		
		local target=null
		local targets=[]
		while (target=Entities.FindByName(target,keypad_prop_name+"_decals")) targets.append(target)
			
		target=targets[(abs(RNG())%targets.len())]
		
		for (local i=0;i<4;i++)
		{
			local decalorigin=target.GetOrigin()+AngleVectors(target.GetAngles()+Vector(0,90,0))*16*i
			
			local digit=parameter.slice(i,i+1)
			
			local decal=SpawnEntityFromTable("infodecal",{origin=decalorigin.ToKVString(),texture="decals/infnum"+digit+".vmt"})
			EntFireByHandle(decal,"Use")
		}
	}
}

function Hideme()
{
	NetMsg.Start("HideKeypadCode");
	NetMsg.Send(player, true);
}