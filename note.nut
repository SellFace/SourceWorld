IncludeScript("utils/text.nut")
local o_panel=null

local NoteText="For anyone reading this, I hope you came from another world.<br><br>I have a MO disk which I've been using to record my research data. I think you'll be interested to see it.<br><br>It's been many years since I've contacted anyone, my previous crew just disappeared. I believe they were moved to another universe somehow.<br><br>Find me on the upper levels, I'll give you the disk.<br><br>I believe there's a long way ahead for you now, no matter what happens, don't give up like I did. Good luck, my friend."

OpenNote<-function()
{
	resX<-ScreenWidth()
	local OpenTime=clock()
	
	if ( o_panel && o_panel.IsValid() )
		return;
	
	o_panel = vgui.CreatePanel( "Panel", vgui.GetRootPanel(), "NotePanel" );
	o_panel.MakeReadyForUse();
	//o_panel.SetPaintEnabled( false );
	o_panel.SetPaintBackgroundEnabled( true );
	o_panel.SetPaintBackgroundType( 2 );
	o_panel.SetPaintBorderEnabled( true );
	
	
	o_panel.SetBgColor( 6, 10, 20, 253 );
	o_panel.SetSize( XRES(240), YRES(300));
	o_panel.SetPos( XRES(320)-o_panel.GetWide()/2, YRES(240)-o_panel.GetTall()/2 );
	o_panel.SetMouseInputEnabled(true);
	
	// чтобы сделать рамочки как в вгуи мне, как дебилу, приходится использовать КНОПКИ пушто iframe забыть спросили и он не работает
	
	b_panel_bg <- vgui.CreatePanel( "Panel", o_panel, "ConfirmPanel2" );
	b_panel_bg.MakeReadyForUse();
	b_panel_bg.SetPos( XRES(4),YRES(12)+1  );
	b_panel_bg.SetSize(o_panel.GetWide()-XRES(8), o_panel.GetTall()-YRES(40));
	b_panel_bg.SetBgColor( 0,1,2,155 );
	b_panel <- vgui.CreatePanel( "Button", b_panel_bg, "ConfirmPanel3" );
	b_panel.MakeReadyForUse();
	b_panel.SetPaintEnabled( true );
	b_panel.SetPaintBackgroundEnabled( true );
	b_panel.SetPaintBackgroundType( 0 );
	b_panel.SetPaintBorderEnabled( true );
	b_panel.SetButtonActivationType(2);
	b_panel.SetPos( 1,1  );
	b_panel.SetFgColor( 255,3,6,255 );
	b_panel.SetSize( b_panel_bg.GetWide()-2, b_panel_bg.GetTall()-2);
	o_panel.SetAlpha(0)
	
	
	o_panel.AddTickSignal(10);
	o_panel.SetCallback("OnTick", function() {
		o_panel.SetAlpha(clamp((clock()-OpenTime)*255*4,0,255))
		if (resX == ScreenWidth()) {
			return
		}

		resX = ScreenWidth();
		printl("ResolutionChanged");
		o_panel.Destroy();
		o_panel = null;
		DisplayOptions()
	}.bindenv(this));
	
	
	label <- (vgui.CreatePanel( "Label", o_panel, "ExampleLabel3" ));
	label.MakeReadyForUse();
	label.SetPaintEnabled( true );
	label.SetPaintBackgroundEnabled( false );
	label.SetFgColor( 5, 175, 255, 255 );
	label.SetPos( YRES(8),YRES(5) );
	label.SetSize(o_panel.GetWide(),o_panel.GetTall())
	label.SetPaintBorderEnabled( true );
	label.SetContentAlignment( Alignment.northwest );
	//label.SetFont( surface.GetFont( "Trader", true ) );
	label.SetText( "NOTE" );
	label.SetFont( 21 );
	label.SetEnabled(true)
	label.SetVisible(true)
	
	//slabel <- (vgui.CreatePanel( "Label", b_panel, "ExampleLabel4" ));
	//slabel.MakeReadyForUse();
	//slabel.SetFgColor( 5, 175, 255, 255 );
	//slabel.SetPos( 0,0 );
	//slabel.SetSize(b_panel.GetWide(), b_panel.GetTall()*0.5)
	//slabel.SetContentAlignment( Alignment.center );
	//slabel.SetText( "Are you sure you want to exit to main menu?" );
	//slabel.SetFont( 19 );
	//
	//slabel2 <- (vgui.CreatePanel( "Label", b_panel, "ExampleLabel4" ));
	//slabel2.MakeReadyForUse();
	//slabel2.SetFgColor( 5, 175, 255, 255 );
	//slabel2.SetPos( 0,surface.GetFontTall(19)+2 );
	//slabel2.SetSize(b_panel.GetWide(), b_panel.GetTall()*0.5)
	//slabel2.SetContentAlignment( Alignment.center );
	//slabel2.SetText( "All unsaved progress will be lost" );
	//slabel2.SetFont( 19 );
	
	o_panel.MakePopup();
	
	s_pClose <- vgui.CreatePanel( "Button", o_panel, "Close" );
	//s_pClose.SetVisible( true );
	//s_pClose.SetPaintEnabled( true );
	//s_pClose.SetPaintBackgroundEnabled( false );
	s_pClose.SetPos(o_panel.GetWide()-s_pClose.GetTall(),s_pClose.GetTall()/4)
	s_pClose.SetPaintBorderEnabled( false );
	s_pClose.SetFont( surface.GetFont( "Marlett", false, "Tracker" ) );
	s_pClose.SetText( "r" );
	s_pClose.SetTextInset( 1, 0 );
	s_pClose.SetContentAlignment( Alignment.northwest );
	s_pClose.SetCallback( "DoClick", HideNote.bindenv(this) );
	
	local dumbtext=GetTextInLines(19,b_panel_bg.GetWide()-YRES(32),NoteText,2024)
	
	function PaintCheck()
	{
		if (!s_pCheck||!s_pCheck.IsValid()) return;
		foreach (i,line in dumbtext)
		{
			surface.DrawColoredText(19,0,surface.GetFontTall(19)*i*1.4,25,185,255,255,line)
		}
		s_pCheck.SetSize(b_panel_bg.GetWide()-YRES(32),b_panel_bg.GetTall())
	}
	
	s_pCheck <- vgui.CreatePanel( "Panel", b_panel_bg, "Check" );
	//sCheckse.SetVisible( true );
	//sCheckse.SetPaintEnabled( true );
	//sCheckse.SetPaintBackgroundEnabled( false );
	s_pCheck.SetPos(YRES(16),YRES(16))
	s_pCheck.SetPaintBorderEnabled( false );
	//s_pCheck.SetFont( surface.GetFont( "Marlett", false, "Tracker" ) );
	//s_pCheck.SetText( "abcdefghijklmnopstu" );
	//s_pCheck.SetTextInset( 1, 0 );
	s_pCheck.SetCallback( "Paint", PaintCheck.bindenv(this) );
}

OpenNote_R_Intro<-function()
{
	NoteText="For anyone reading this, I hope you came from another world.<br><br>I have an MO disk which I've been using to record my research data. I think you'll be interested to see it.<br><br>It's been many years since I've contacted anyone, my previous crew just disappeared. My theory is that they were moved to a parallel world.<br><br>Find me on the upper levels, I'll give you the disk.<br><br>I believe there's a long way ahead for you now, no matter what happens, don't give up like I did. Good luck, my friend."
	OpenNote()
}
OpenNote_R_Worlds<-function()
{
	NoteText="Last night I had a strange dream where I experienced same exact events that happened to me 5 years ago.<br><br>I've had my homebase attacked, barely escaped from death and then met my friends again. It almost felt like I was living for second time. Everything seemed familiar, but I never figured out it was a dream of things I already knew, up until I woke up.<br>And after I did, I was stuck here again, all alone.<br><br>I compared this dream with my actual memories and as it turned out. They mismatch.<br>The people I've met were the same, but not the things we did or experienced. Most importantly, it didn't even feel like a dream at all, I still experienced pain and everything.<br><br>I didn't sleep. I was in another world. I must seek answers."
	OpenNote()
}


function HideNote()
{
	local OpenTime=clock()
	if ( o_panel && o_panel.IsValid() )
	{
		o_panel.AddTickSignal(10);
		o_panel.SetCallback("OnTick", function() {
			o_panel.SetAlpha(clamp(255-(clock()-OpenTime)*255*5,0,255))
			if (clamp(255-(clock()-OpenTime)*255*5,0,255)<1)
			{
				o_panel.Destroy();
				o_panel = null;
			}
		}.bindenv(this));
	}
}