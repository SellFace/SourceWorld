// я спиздил свой старый скрипт из ЛАДа и пожалел об этом. ну и хуйню я тогда высрал. но самое худшее было только впереди с этими дебильными транзишенами.

function GenerateCode()
{
	if ( SERVER_DLL )
	{
		local code = RandomInt(1000000,9999999); 
		Globals.AddGlobal("PASSWORD", "resident_evil_test", 1);
		local password_id = Globals.GetIndex("PASSWORD");
		if (Globals.GetCounter(password_id) == 0)
		{
			Globals.SetCounter(password_id, code);
			EntFire("monitor_code","SetMessage",""+code,0);
		}
		NetMsg.Start("Code");
		NetMsg.WriteShort(Globals.GetCounter(password_id));
		NetMsg.Send(player, true);
	}
}


::BombTime<-Time()+162

function Think()
{
	if (BombTime==null) return 999;
	EntFire("bomb_tick","trigger")
	local b=BombTime-2
	SW_MUSIC_OVERRIDE="chirkashnitsa"
	EntFire("m_trigger","disable",0)
	EntFire("lab_exit","lock",0)
	//printl((b-Time())/70)
	if (BombTime<Time()-0.5) EntFire("bomb_explode","trigger",0.2)
	if (BombTime>Time()+500) {self.Destroy()} 
	local ent=null
	if (BombTime<Time()-0.5) while (ent=Entities.FindByClassname(ent,"prop*")) Entities.First().SetContextThink("bobm"+RandomInt(0,100),function (a,ora=ent.GetOrigin()) {Entities.FindByName(null,"bomb_exp").SetOrigin(ora);Entities.FindByName(null,"bomb_exp").AcceptInput("Explode","",null,null)}.bindenv(this),RandomFloat(0,8))
	return clamp((b+10-Time())/70,0.01,1.5)
}
function Everything()
{
if ( CLIENT_DLL )
{
	m_panel <- null;
	label <- null;
	image <- null;
	local LastClick=Time()
	local LastWrong=Time()
	local LastCorrect=Time()
	
	local RightSound=false
	local right_digit=0
	local number="0"
	local text=""
	
	function DoClick(num)
	{
		//if (BombTime>Time()+500) return
		if (num!=null) labeltext=labeltext+num.tostring();
		if (num!=null) image.SetPos( 0,5 );
		if (num!=null) LastClick=Time()
		
		CheckCode(labeltext);
		
		if (image.GetYPos()>0) image.SetPos( 0,image.GetYPos()-1 );
		
		local remaining=8-labeltext.len()
		if (remaining==0) return
		//printl(correct_code)
		//printl(labeltext)
		text=labeltext
		right_digit=0
		if (remaining>0&&correct_code.tostring().slice(8-remaining,clamp(labeltext.len()+1,0,7)).len()>0) right_digit=correct_code.tostring().slice(8-remaining,clamp(labeltext.len()+1,0,7)).tointeger()
		number=((Time()*(3+labeltext.len()))%10).tointeger().tostring()
		//printl(labeltext.len()+1)
		if (correct_code.tostring().slice(8-remaining,labeltext.len()+1).tostring()==number.tostring()||(correct_code.tostring().slice(8-remaining,labeltext.len()+1).tostring()==(number.tointeger()-1).tostring())&&correct_code.tostring().slice(8-remaining,clamp(labeltext.len()+1,0,7)).len()>0)
		{
			number=(((Time())*(3+labeltext.len()))%10).tointeger().tostring()
			if (correct_code.tostring().slice(8-remaining,labeltext.len()+1).tostring()==(number.tointeger()-1).tostring()) number=right_digit;
			//printl(right_digit)
			
			if (!RightSound) surface.PlaySound("hl1/fvox/buzz.wav")
			RightSound=true
		}
		else RightSound=false;
		if (correct_code.tostring().slice(labeltext.len(),labeltext.len()+1)!=number) text=text+(number)
		else text=text+number
		for (local i=0;i<remaining-2;i++) text=text+"*"
		label.SetText( text );
		if (BombTime<Time()+0.2) HidePanels()
		//printl(correct_code)
	}
	
	function Paint()
	{
		surface.SetColor(255,255,255,255)
		surface.SetTexture(surface.ValidateTexture("keypad",true,true,true))
		surface.DrawTexturedRect(0,0,512,512)
		foreach( i,dig in text)
		{
			local dist=RemapVal(min(abs(right_digit.tointeger()-number.tointeger()),10-max(right_digit.tointeger(),number.tointeger())+min(right_digit.tointeger(),number.tointeger())),0,9,255,10)
			
			if (Time()-LastWrong>=0.5&&Time()-LastCorrect>=1)
			{
			
				if (i!=labeltext.len()) 
					surface.DrawColoredText(32,8+m_panel.GetTall()/2-surface.GetTextWidth(32,"88888888")/2+surface.GetTextWidth(32,"88888888")/7*i,m_panel.GetTall()/4-surface.GetFontTall(32),255,2,2,255,text.slice(i,i+1));
				else if (right_digit.tostring()!=text.slice(i,i+1)) 
				surface.DrawColoredText(32,8+m_panel.GetTall()/2-surface.GetTextWidth(32,"88888888")/2+surface.GetTextWidth(32,"88888888")/7*i,m_panel.GetTall()/4-surface.GetFontTall(32),255,2,2,dist,text.slice(i,i+1));
				else surface.DrawColoredText(32,8+m_panel.GetTall()/2-surface.GetTextWidth(32,"88888888")/2+surface.GetTextWidth(32,"88888888")/7*i,m_panel.GetTall()/4-surface.GetFontTall(32),2,255,2,dist,text.slice(i,i+1));;
				//printl(text.slice(i,i+1))
			}
			else
			{
				if (Time()-LastWrong<0.5) surface.DrawColoredText(32,8+m_panel.GetTall()/2-surface.GetTextWidth(32,"INCORRECT")/2,m_panel.GetTall()/4-surface.GetFontTall(32),255,2,2,255,"INCORRECT");
				else surface.DrawColoredText(32,8+m_panel.GetTall()/2-surface.GetTextWidth(32,"CORRECT")/2,m_panel.GetTall()/4-surface.GetFontTall(32),2,255,2,255,"CORRECT");
			}
		}
	}
	
	function DisplayPanels()
	{
		if ( m_panel && m_panel.IsValid() )
			return;
			
		if (BombTime==null)
			return;

		m_panel = vgui.CreatePanel( "Panel", vgui.GetClientDLLRootPanel(), "ExamplePanel" );
		m_panel.MakeReadyForUse();
		m_panel.SetPaintEnabled( true );
		m_panel.SetPaintBackgroundEnabled( true );
		m_panel.SetPaintBackgroundType( 2 );
		m_panel.SetBgColor( 0, 0, 0, 0 );
		m_panel.SetPos( (ScreenWidth()/2)-256,(ScreenHeight()/2)-200 );
		m_panel.SetSize( 512,512 );
		m_panel.SetCallback( "Paint", Paint.bindenv(this) )
		m_panel.SetMouseInputEnabled(true);
		m_panel.MakePopup();
		

		image = vgui.CreatePanel( "ImagePanel", m_panel, "ExampleImage" );
		image.MakeReadyForUse();
		image.SetImage("keypad", false);
		image.SetSize( 512,512 );
		image.SetPos( 0,0 );
		image.SetAlpha( 0 );
		image.MoveToFront();

		label = vgui.CreatePanel( "Label", image, "ExampleLabel" );
		label.MakeReadyForUse();
		label.SetPaintEnabled( true );
		label.SetPaintBackgroundEnabled( false );
		label.SetFgColor( 255, 2, 2, 0 );
		label.SetPos( 8,-8 );
		label.SetSize(m_panel.GetTall(), m_panel.GetTall()/2 );
		label.SetContentAlignment( Alignment.center );
		label.SetFont( 32 );
		label.SetText( "" );
		labeltext <- ""
		
		local button = vgui.CreatePanel( "Button", image, "ExampleButton" );
		button.SetPaintEnabled( true );
		button.SetPaintBorderEnabled( false );
		button.SetDepressedSound("click.wav");
		button.MoveToFront();
		button.SetPos( 512*0.253, 512*0.445  );
		button.SetSize( 512*0.105, 512*0.116 );
		button.SetCallback( "DoClick", function (b=1) {DoClick(b)}.bindenv(this) );
		
		local button2 = vgui.CreatePanel( "Button", image, "ExampleButton" );
		button2.SetPaintEnabled( true );
		button2.SetPaintBorderEnabled( false );
		button2.SetDepressedSound("click.wav");
		button2.MoveToFront();
		button2.SetPos( 512*(0.253+0.106*1), 512*0.445  );
		button2.SetSize( 512*0.105, 512*0.116 );
		button2.SetCallback( "DoClick", function (b=2) {DoClick(b)}.bindenv(this) );

		local button3 = vgui.CreatePanel( "Button", image, "ExampleButton" );
		button3.SetPaintEnabled( true );
		button3.SetPaintBorderEnabled( false );
		button3.SetDepressedSound("click.wav");
		button3.MoveToFront();
		button3.SetPos( 512*(0.253+0.106*2), 512*0.445  );
		button3.SetSize( 512*0.105, 512*0.116 );
		button3.SetCallback( "DoClick", function (b=3) {DoClick(b)}.bindenv(this) );
		
		local button4 = vgui.CreatePanel( "Button", image, "ExampleButton" );
		button4.SetPaintEnabled( true );
		button4.SetPaintBorderEnabled( false );
		button4.SetDepressedSound("click.wav");
		button4.MoveToFront();
		button4.SetPos( 512*(0.253+0.106*3), 512*0.445  );
		button4.SetSize( 512*0.105, 512*0.116 );
		button4.SetCallback( "DoClick", function (b=4) {DoClick(b)}.bindenv(this) );
		
		local button5 = vgui.CreatePanel( "Button", image, "ExampleButton" );
		button5.SetPaintEnabled( true );
		button5.SetPaintBorderEnabled( false );
		button5.SetDepressedSound("click.wav");
		button5.MoveToFront();
		button5.SetPos( 512*(0.253+0.106*4), 512*0.445  );
		button5.SetSize( 512*0.105, 512*0.116 );
		button5.SetCallback( "DoClick", function (b=5) {DoClick(b)}.bindenv(this) );

		local button6 = vgui.CreatePanel( "Button", image, "ExampleButton" );
		button6.SetPaintEnabled( true );
		button6.SetPaintBorderEnabled( false );
		button6.SetDepressedSound("click.wav");
		button6.MoveToFront();
		button6.SetPos( 512*(0.253+0.106*0), 512*0.575  );
		button6.SetSize( 512*0.105, 512*0.116 );
		button6.SetCallback( "DoClick", function (b=6) {DoClick(b)}.bindenv(this) );
		
		local button7 = vgui.CreatePanel( "Button", image, "ExampleButton" );
		button7.SetPaintEnabled( true );
		button7.SetPaintBorderEnabled( false );
		button7.SetDepressedSound("click.wav");
		button7.MoveToFront();
		button7.SetPos( 512*(0.253+0.106*1), 512*0.575  );
		button7.SetSize( 512*0.105, 512*0.116 );
		button7.SetCallback( "DoClick", function (b=7) {DoClick(b)}.bindenv(this) );
		
		local button8 = vgui.CreatePanel( "Button", image, "ExampleButton" );
		button8.SetPaintEnabled( true );
		button8.SetPaintBorderEnabled( false );
		button8.SetDepressedSound("click.wav");
		button8.MoveToFront();
		button8.SetPos( 512*(0.253+0.106*2), 512*0.575  );
		button8.SetSize( 512*0.105, 512*0.116 );
		button8.SetCallback( "DoClick", function (b=8) {DoClick(b)}.bindenv(this) );

		local button9 = vgui.CreatePanel( "Button", image, "ExampleButton" );
		button9.SetPaintEnabled( true );
		button9.SetPaintBorderEnabled( false );
		button9.SetDepressedSound("click.wav");
		button9.MoveToFront();
		button9.SetPos( 512*(0.253+0.106*3), 512*0.575  );
		button9.SetSize( 512*0.105, 512*0.116 );
		button9.SetCallback( "DoClick", function (b=9) {DoClick(b)}.bindenv(this) );
		
		local button0 = vgui.CreatePanel( "Button", image, "ExampleButton" );
		button0.SetPaintEnabled( true );
		button0.SetPaintBorderEnabled( false );
		button0.SetDepressedSound("click.wav");
		button0.MoveToFront();
		button0.SetPos( 512*(0.253+0.106*4), 512*0.575  );
		button0.SetSize( 512*0.105, 512*0.116 );
		button0.SetCallback( "DoClick", function (b=0) {DoClick(b)}.bindenv(this) );
		
		/*
		local buttonclear = vgui.CreatePanel( "Button", image, "ExampleButton" );
		buttonclear.SetPaintEnabled( true );
		buttonclear.SetPaintBorderEnabled( false );
		buttonclear.SetDepressedSound("click.wav");
		buttonclear.MoveToFront();
		buttonclear.SetPos( 77*2.15, 157*2.15 );
		buttonclear.SetSize(m_panel.GetTall()/8.5, m_panel.GetTall()/8.5 );
		buttonclear.SetCallback( "DoClick", Clear.bindenv(this) );
		*/
		
		local cross = vgui.CreatePanel( "Label", m_panel, "ExampleLabeel" );
		cross.MakeReadyForUse();
		cross.SetPaintEnabled( true );
		cross.SetPos( 208*2.15, 1*2.15 );
		cross.SetPaintBackgroundEnabled( false );
		cross.SetFgColor( 150, 0, 0, 255 );
		cross.SetFont( 12 );
		cross.SetText( "X" );
		
		local close = vgui.CreatePanel( "Button", m_panel, "ExampleButton" );
		close.SetPaintEnabled( true );
		close.SetPaintBorderEnabled( false );
		close.SetText("");
		close.SetContentAlignment(4);
		close.SetDefaultColor( 200, 0, 0, 255, 0, 0,0,0 );
		close.SetPos( 204*2.15, 0 );
		close.SetSize(m_panel.GetTall()/17, m_panel.GetTall()/17 );
		close.SetCallback( "DoClick", Close.bindenv(this) );
		
		m_panel.AddTickSignal(15);
		m_panel.SetCallback("OnTick", function() {
			DoClick(null)
		}.bindenv(this));
		
	}
	
	correct_code <- RandomInt(1000000,9999999);
	
	last_check<-Time()
	
	function CheckCode( code )
	{
		if (Time()-last_check<1) return
		last_check=Time()
		if (code.len()>6)
		{
			//printl(correct_code+"   "+labeltext)
			if (code==""+correct_code)
			{
				NetMsg.Start("correct");
				label.SetFgColor( 0, 250, 0, 0 );
				//label.SetText("CORRECT");
				//labeltext="CORRECT"
				BombTime=null
				NetMsg.Send();
				SW_MUSIC_OVERRIDE="shinjuku"
				LastCorrect=Time()
				LastWrong=0
				SW_EVENTS["bomb"].Pass()
			}
			else
			{
				NetMsg.Start("wrong");
				//BombTime-=10
				label.SetFgColor( 250, 0, 0, 0 );
				//label.SetText("WRONG");
				labeltext=""
				label.SetText( labeltext );
				LastWrong=Time()
				NetMsg.Send();
			}
		}
		else
		{
			if (code.len()>0&&code.len()<2&&code!=(correct_code.tostring().slice(0,code.len())))
			{
				NetMsg.Start("wrong");
				//BombTime-=10
				label.SetFgColor( 250, 0, 0, 0 );
				//label.SetText("WRONG");
				labeltext=""
				label.SetText( labeltext );
				LastWrong=Time()
				
				NetMsg.Send();
			}
		}
	}
	
	function Clear()
	{
		labeltext="";
		label.SetText( labeltext );
	}
	
	function Close()
	{
		HidePanels()
	}
	
	function HidePanels()
	{
		if ( m_panel && m_panel.IsValid() )
		{
			m_panel.Destroy();
			m_panel = null;
		}
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
	
	NetMsg.Receive("OpenKeypad", function()
	{
		DisplayPanels();
	}.bindenv(this) );
	
	NetMsg.Receive("HideKeypad", function()
	{
		HidePanels();
	}.bindenv(this) );
}
if ( SERVER_DLL )
{
	PASSWORD <- null;
	PASSWORD = RandomInt(1000,9999); 
	
	NetMsg.Receive("wrong", function( player )
	{
		SendToConsole("play buttons/button8.wav");
		//EntFire("bomb","runscriptcode","Hideme()",0.3);
		//BombTime-=10
	} );
	NetMsg.Receive("RequestCode", function( player )
	{
		NetMsg.Start("TheCode");
		NetMsg.WriteShort(Globals.GetCounter(Globals.GetIndex("PASSWORD")));
		NetMsg.Send(player, true);
	} );
	NetMsg.Receive("correct", function( player )
	{
		if (BombTime!=null)
		{
			SendToConsole("play weapons/c4/c4_disarm.wav");
			EntFire("bomb","runscriptcode","Hideme()",1.0);
			SW_MUSIC_OVERRIDE="shinjuku"
			//EntFire("m_trigger","enable",0)
			EntFire("lab_exit","unlock",0)
			EntFire("bomb_defuse","trigger",0)
			SW_EVENTS["bomb"].Pass()
		}
		BombTime=null
	} );
	EntFire("password_entry_server","runscriptcode","GenerateCode();",1.0);

}
function Init()
{
	SendToConsole("script_execute_client password");
	SendToConsole("script_execute password");
}
}

Everything();
GenerateCode();

local FirstOpen=false
function Keypad()
{
	if (BombTime==null)
		return;
	NetMsg.Start("OpenKeypad");
	NetMsg.Send(player, true);
	//if (!FirstOpen) {Entities.First().SetContextThink("BombHint",function(...){SWHint("You don't know the code. But display shows a digit flashing between 0 and 9... except one number is hidden.")},1)};
	//please for the sake of god be enough for people to understand how to defuse the bomb and that the flashing numbers aren't there for nothing.
	FirstOpen=true
}

Hooks.Add( this, "OnRestore", GenerateCode, "Password" );
function Hideme()
{
	NetMsg.Start("HideKeypad");
	NetMsg.Send(player, true);
}
Hooks.Add( this, "OnRestore", Everything, "Password" );