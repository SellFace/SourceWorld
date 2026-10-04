bg_panel <- null;
s_panel <- null;
c_panel <- null;
o_panel <- null;

d_panel <- null;

local FirstTime=false

// menu size 384x240 yres

::DisplaySavePanels<-function(IsLoading=false,canclose=true)
{
	resX<-ScreenWidth()
	local OpenTime=clock()
	
	
	
	if (IsLoading && s_panel && s_panel.IsValid() )
		return;
	
	if (!IsLoading && bg_panel && bg_panel.IsValid() )
		return;
	
	if (!IsLoading)
	{
		bg_panel = vgui.CreatePanel( "Panel", vgui.GetRootPanel(), "SavePanelBG" );
		bg_panel.MakeReadyForUse();

		bg_panel.SetPos( 0, 0  );
		bg_panel.SetSize( ScreenWidth(), ScreenHeight() );
		//bg_panel.SetMouseInputEnabled(true);
	}
	
	
	s_panel = vgui.CreatePanel( "Panel", (!IsLoading) ? bg_panel : vgui.GetRootPanel(), "SavePanel" );
	s_panel.MakeReadyForUse();
	//s_panel.SetPaintEnabled( false );
	s_panel.SetPaintBackgroundEnabled( true );
	s_panel.SetPaintBackgroundType( 2 );
	s_panel.SetPaintBorderEnabled( true );
	
	
	s_panel.SetBgColor( 6, 10, 20, 238 );
	s_panel.SetPos( XRES(100),YRES(140)  );
	s_panel.SetSize( ScreenWidth()-XRES(200), ScreenHeight()-YRES(280));
	s_panel.SetMouseInputEnabled(true);
	//s_panel.SetZPos(-50)
	
	// чтобы сделать рамочки как в вгуи мне, как дебилу, приходится использовать КНОПКИ пушто iframe забыть спросили и он не работает
	
	b_panel_bg <- vgui.CreatePanel( "Panel", s_panel, "SavePanel2" );
	b_panel_bg.MakeReadyForUse();
	b_panel_bg.SetPos( XRES(4)+1,YRES(16)+1  );
	b_panel_bg.SetSize(s_panel.GetWide()-XRES(8), s_panel.GetTall()-YRES(32));
	b_panel_bg.SetBgColor( 0,1,2,155 );
	b_panel <- vgui.CreatePanel( "Button", b_panel_bg, "SavePanel3" );
	b_panel.MakeReadyForUse();
	b_panel.SetPaintEnabled( true );
	b_panel.SetPaintBackgroundEnabled( true );
	b_panel.SetPaintBackgroundType( 0 );
	b_panel.SetPaintBorderEnabled( true );
	b_panel.SetButtonActivationType(2);
	b_panel.SetPos( 1,1  );
	b_panel.SetFgColor( 255,3,6,255 );
	b_panel.SetSize( b_panel_bg.GetWide()-2, b_panel_bg.GetTall()-2);
	s_panel.SetAlpha(0)
	
	
	s_panel.AddTickSignal(10);
	
	s_panel.SetCallback("OnTick", function() {
		
		if (!s_panel || !s_panel.IsValid() )
			return;
		
		
		s_panel.SetAlpha(clamp((clock()-OpenTime)*255*4,0,255))
		
		
		local openanim=clamp((clock()-OpenTime)*2,0,1)
		
		for (local i=0;i<6;i++)
		{
			local openanim=clamp((clock()-OpenTime-0.1*i)*2,0,1)
			slots[i].SetPos( YRES(16)-YRES(50)*(1-openanim),YRES(20)*(i+1)  );
		}
		
		if (resX == ScreenWidth()) {
			return
		}

		resX = ScreenWidth();
		printl("ResolutionChanged");
		if (IsLoading)
		{
			s_panel.Destroy();
			s_panel = null;
		}
		else
		{
			bg_panel.Destroy();
			bg_panel = null;
		}
		DisplaySavePanels(IsLoading)
	}.bindenv(this));

	labels<-[]
	
	label <- (vgui.CreatePanel( "Label", s_panel, "ExampleLabel3" ));
	label.MakeReadyForUse();
	label.SetPaintEnabled( true );
	label.SetPaintBackgroundEnabled( false );
	label.SetFgColor( 5, 175, 255, 255 );
	label.SetPos( 0,YRES(5) );
	label.SetSize(s_panel.GetWide(),YRES(16))
	label.SetPaintBorderEnabled( true );
	label.SetContentAlignment( Alignment.north );
	//label.SetFont( surface.GetFont( "Trader", true ) );
	label.SetText( "SAVE GAME" );
	if (IsLoading) label.SetText( "LOAD GAME" );
	label.SetFont( 21 );
	label.SetEnabled(true)
	label.SetVisible(true)
	
	slabel <- (vgui.CreatePanel( "Label", b_panel, "ExampleLabel4" ));
	slabel.MakeReadyForUse();
	slabel.SetPaintEnabled( true );
	slabel.SetPaintBackgroundEnabled( false );
	slabel.SetFgColor( 5, 175, 255, 255 );
	slabel.SetPos( YRES(216),YRES(20) );
	slabel.SetSize(b_panel.GetWide()/3-YRES(32), YRES(20)*6)
	slabel.SetPaintBorderEnabled( true );
	slabel.SetContentAlignment( Alignment.center );
	//label.SetFont( surface.GetFont( "Trader", true ) );
	slabel.SetText( "" );
	slabel.SetFont( 6 );
	slabel.SetEnabled(true)
	slabel.SetVisible(true)
	//s_panel.SetCallback( "Paint", Paint.bindenv(this) );
	if (IsLoading) s_panel.MakePopup();
	else bg_panel.MakePopup();
	//s_pClose.SetVisible( true );
	//s_pClose.SetPaintEnabled( true );
	//s_pClose.SetPaintBackgroundEnabled( false );
	
	s_pClose <- vgui.CreatePanel( "Button", s_panel, "Close" );
	s_pClose.SetPos(s_panel.GetWide()-s_pClose.GetTall(),s_pClose.GetTall()/4)
	s_pClose.SetPaintBorderEnabled( false );
	s_pClose.SetFont( surface.GetFont( "Marlett", false, "Tracker" ) );
	s_pClose.SetText( "r" );
	s_pClose.SetTextInset( 1, 0 );
	s_pClose.SetContentAlignment( Alignment.northwest );
	
	if (canclose) s_pClose.SetCallback( "DoClick", HideSavePanels.bindenv(this) );
	if (!canclose) s_pClose.SetCallback( "DoClick", function(...) {HideSavePanels();DisplayContinuePanels()}.bindenv(this) );
	
	slots<-[]
	Selection<--1
	
	s_pAction <- vgui.CreatePanel( "Button", s_panel, "Action" );
	s_pAction.SetSize(YRES(32), YRES(16))
	s_pAction.SetPos(b_panel.GetWide()/2-s_pAction.GetWide()/2,s_panel.GetTall()-s_pAction.GetTall()*3)
	s_pAction.SetPaintEnabled( true );
	s_pAction.SetPaintBackgroundEnabled( true );
	s_pAction.SetPaintBackgroundType( 1 );
	s_pAction.SetPaintBorderEnabled( true );
	s_pAction.SetBgColor( 220,3,6,255 );
	s_pAction.SetDepressedSound("ui/buttonrollover.wav");
	s_pAction.SetDepressedColor(80,80,80,255,80,80,80,255);
	s_pAction.SetVisible(false)
	//s_pAction.SetFont( surface.GetFont( "Marlett", false, "Tracker" ) );
	s_pAction.SetText( "SAVE" );
	if (IsLoading) s_pAction.SetText( "LOAD" );
	s_pAction.SetTextInset( 1, 0 );
	s_pAction.SetContentAlignment( Alignment.center );
	local lastclick=Time()
	s_pAction.SetCallback( "DoClick", function (...) {lastclick=Time();ClickSave(Selection)}.bindenv(this) );
	
	for (local i=0;i<6;i++)
	{
		slots.append(vgui.CreatePanel( "Button", b_panel, "SavePanel4" ));
		
		slots[i].MakeReadyForUse();
		slots[i].SetPaintEnabled( true );
		slots[i].SetPaintBackgroundEnabled( true );
		slots[i].SetPaintBackgroundType( 1 );
		slots[i].SetPaintBorderEnabled( true );
		slots[i].SetPos( YRES(16),YRES(20)*(i+1)  );
		slots[i].SetBgColor( 220,3,6,255 );
		slots[i].SetDepressedSound("ui/buttonrollover.wav");
		slots[i].SetSize( b_panel.GetWide()/3-YRES(32), YRES(16));
		slots[i].SetText("Save Slot "+i)
		slots[i].SetMouseInputEnabled(true);
		//slots[i].ForceDepressed(true);
	}
	
	local i=0
	while(i<6) {slots[i].SetCallback( "DoClick", function (a=i) {ClickSave(a)}.bindenv(this) );i++}
	if (!IsLoading) while(i<6) {slots[i].SetCallback( "OnMouseDoublePressed", function (a=i) {SaveSlot(a)}.bindenv(this) );i++}
	else while(i<6) {slots[i].SetCallback( "OnMouseDoublePressed", function (a=i) {LoadSlot(a)}.bindenv(this) );i++}
	
	function ClickSave(a)
	{
		if ((!IsLoading)&&a==Selection&&(Time()-lastclick)<0.4) {SaveSlot(a);return}
		if ((IsLoading)&&a==Selection&&(Time()-lastclick)<0.4) {LoadSlot(a);return}
		lastclick=Time()
		slots[a].SetText("> Save Slot "+a+" <")
		if (Selection>=0) slots[Selection].SetText("Save Slot "+Selection)
		Selection=a
	
		local SaveInfo=LoadPreviewData(a)
		if (!SaveInfo)
		{
			slabel.SetText("Empty Slot")
			if (IsLoading) s_pAction.SetVisible(false)
			else s_pAction.SetVisible(true);
			return
		}
		s_pAction.SetVisible(true)
		local LVL=(1+0.07*sqrt(SaveInfo.XP)).tointeger()
		
		switch(SaveInfo.Map)
		{
			case "demo_city":SaveInfo.Map="City";break;
			case "teleporting_room_v1":SaveInfo.Map="Underground Lab";break;
			case "weapons_range":SaveInfo.Map="Dev Map";break;
		}
		
		slabel.SetText(format("Time: %s\n\nMoney: $%d\n\nLevel: %d\n\nExperience: %d\n\nLocation: %s\n\n",SaveInfo.Time,SaveInfo.Money,LVL,SaveInfo.XP,SaveInfo.Map))
	}
	function SaveSlot(a)
	{
		NetMsg.Start("Save_a_game");
		NetMsg.WriteShort(a);
		NetMsg.Send();
		HideSavePanelsInstant()
		//Globals.GetCounter(Globals.GetIndex("PlaythroughID"),a)
		
	}
	function LoadSlot(a)
	{
		if (!FileExists("saves/savedata_"+a+".sav")) return
		NetMsg.Start("Load_a_save");
		NetMsg.WriteShort(a);
		NetMsg.Send();
		//Globals.GetCounter(Globals.GetIndex("PlaythroughID"),a)
		
	}
	if (!FirstTime&&GetMapName()=="maps/background.bsp") {printl("firsttimer! reloading panel");s_panel.Destroy();s_panel = null;FirstTime=true;DisplaySavePanels(true)};	//dirty hack which reloads the panel when opened first time in main menu to fix broken labels.
}

::DisplayLoadPanels<-function(canclose=true) {DisplaySavePanels(true,canclose)}

function HideSavePanels()
{
	local OpenTime=clock()
	if ( bg_panel && bg_panel.IsValid() )
	{
		bg_panel.AddTickSignal(10);
		bg_panel.SetCallback("OnTick", function() {
			bg_panel.SetAlpha(clamp(255-(clock()-OpenTime)*255*5,0,255))
			if (clamp(255-(clock()-OpenTime)*255*5,0,255)<1)
			{
				bg_panel.Destroy();
				bg_panel = null;
				NetMsg.Start("SaveSpin");
				NetMsg.Send();
			}
		}.bindenv(this));
		return
	}
	if ( s_panel && s_panel.IsValid() )
	{
		s_panel.AddTickSignal(10);
		s_panel.SetCallback("OnTick", function() {
			s_panel.SetAlpha(clamp(255-(clock()-OpenTime)*255*5,0,255))
			if (clamp(255-(clock()-OpenTime)*255*5,0,255)<1)
			{
				s_panel.Destroy();
				s_panel = null;
				
				NetMsg.Start("SaveSpin");
				NetMsg.Send();
			}
		}.bindenv(this));
	}
}
function HideSavePanelsInstant()
{
	if ( bg_panel && bg_panel.IsValid() )
	{
		bg_panel.Destroy();
		bg_panel = null;
		NetMsg.Start("SaveSpin");
			NetMsg.Send();
		return
	}
	if ( s_panel && s_panel.IsValid() )
	{
		s_panel.Destroy();
		s_panel = null;
		NetMsg.Start("SaveSpin");
		NetMsg.Send();
	}
}
