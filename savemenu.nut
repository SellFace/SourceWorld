bg_panel <- null;
s_panel <- null;
c_panel <- null;
o_panel <- null;

d_panel <- null;

local FirstTime=false

local DrawColoredTextCentered=function(font, x, y, r, g, b, a, text)
{
	surface.DrawColoredText(font, x-surface.GetTextWidth(font, text)/2, y-surface.GetFontTall(font)/2, r, g, b, a, text)
}
local DrawColoredTextNorth = function(font, x, y, r, g, b, a, text)
{
	surface.DrawColoredText(font, x-surface.GetTextWidth(font, text)/2, y, r, g, b, a, text)
}

local DrawOutlinedBox = function(b, x, y, w, t, ExSides=0,OverrideBorderColors=true,c1=[10,150,10],c2=[10,80,10])
{
	local border=b
	local wide=w
	local tall=t
	if (OverrideBorderColors) surface.SetColor(c1[0],c1[1],c1[2], 255)
	if (!(ExSides&8)) surface.DrawFilledRect( x, y, wide, border );	// TOP
	if (!(ExSides&4)) surface.DrawFilledRect( x, y, border, tall );	// LEFT
	if (OverrideBorderColors) surface.SetColor(c2[0],c2[1],c2[2], 255)
	if (!(ExSides&1)) surface.DrawFilledRect( x, y+tall-border, wide, border );	// BOTTOM
	if (!(ExSides&2)) surface.DrawFilledRect( x+wide-border, y, border, tall );	// RIGHT
}

// menu size 384x240 yres

local MenuSizeX=YRES(384)
local MenuSizeY=YRES(240)

local ListSizeX=YRES(360)
local ListSizeY=YRES(208)


surface.CreateFont( "SaveMenuTitle4",       
{
	"name"            : "Mensura 3"
	"tall"            : 14
	"weight"        : 1500
	//"blur"            : 1        
	"additive"        : false        
	"antialias"        : true  
   // "scanlines"     : 2            
   // "dropshadow"     : false       
	"proportional"     : true        
} );
local SaveMenuTitleFont=surface.GetFont( "SaveMenuTitle4", true )

surface.CreateFont( "SaveMenuBig2",       
{
	"name"            : "Mensura 3"
	"tall"            : 24
	"weight"        : 100
	//"blur"            : 1        
	"additive"        : false        
	"antialias"        : true  
   // "scanlines"     : 2            
   // "dropshadow"     : false       
	"proportional"     : true        
} );
local SaveMenuBigFont=surface.GetFont( "SaveMenuBig2", true )

surface.CreateFont( "SaveMenuBigGlow5",       
{
	"name"            : "Mensura 3"
	"tall"            : 24
	"weight"        : 200
	"blur"            : 2        
	"additive"        : false              
   // "dropshadow"     : false       
	"proportional"     : true        
} );
local SaveMenuBigGlowFont=surface.GetFont( "SaveMenuBigGlow5", true )

surface.CreateFont( "SaveMenuTitleGlow2",       
{
	"name"            : "Mensura 3"
	"tall"            : 14
	"weight"        : 1500
	"blur"            : 1        
	"additive"        : false        
    "scanlines"     : 2            
   // "dropshadow"     : false       
	"proportional"     : true        
} );
local SaveMenuTitleGlowFont=surface.GetFont( "SaveMenuTitleGlow2", true )

surface.CreateFont( "SaveMenuList5",       
{
	"name"            : "Mensura 3"
	"tall"            : 12
	"weight"        : 100
	//"blur"            : 1        
	"additive"        : false        
	"antialias"        : true       
   // "scanlines"     : 2            
  "dropshadow"     : true        
	"proportional"     : true        
} );
local SaveMenuListFont=surface.GetFont( "SaveMenuList5", true )

surface.CreateFont( "SaveMenuListSmall5",       
{
	"name"            : "Mensura 3"
	"tall"            : 9
	"weight"        : 300
	//"blur"            : 1        
	"additive"        : false        
	"antialias"        : true    
   // "scanlines"     : 2            
   // "dropshadow"     : false       
	"proportional"     : true        
} );
local SaveMenuListSmallFont=surface.GetFont( "SaveMenuListSmall5", true )

surface.CreateFont( "SaveMenuMap2",       
{
	"name"            : "Mensura 7"
	"tall"            : 16
	"weight"        : 100
	//"blur"            : 1        
	"additive"        : false        
	"antialias"        : true    
   // "scanlines"     : 2            
   // "dropshadow"     : false       
	"proportional"     : true        
} );
local SaveMenuMapFont=surface.GetFont( "SaveMenuMap2", true )

surface.CreateFont( "SaveMenuMapGlow2",       
{
	"name"            : "Mensura 7"
	"tall"            : 16
	"weight"        : 100
	"blur"            : 2        
	"additive"        : false        
	"antialias"        : true    
    "scanlines"     : 2            
   // "dropshadow"     : false       
	"proportional"     : true        
} );
local SaveMenuMapGlowFont=surface.GetFont( "SaveMenuMapGlow2", true )

surface.CreateFont( "SaveMenuTime45",
{
	"name"            : "MxPlus HP 150 re."
	"tall"            : 16
	"weight"        : 3300
	//"blur"            : 1        
	"additive"        : false        
	//"antialias"        : true    
   // "scanlines"     : 2            
   // "dropshadow"     : false       
	"proportional"     : true     
} );
local SaveMenuTimeFont=surface.GetFont( "SaveMenuTime45", true )

surface.CreateFont( "SaveMenuTimeGlow45",
{
	"name"            : "MxPlus HP 150 re."
	"tall"            : 16
	"weight"        : 3300
	"blur"            : 2        
	"additive"        : false        
	//"antialias"        : true    
    "scanlines"     : 2            
   // "dropshadow"     : false       
	"proportional"     : true     
} );
local SaveMenuTimeGlowFont=surface.GetFont( "SaveMenuTimeGlow45", true )

function FixupLocation(save)
{
	switch(save.Map)
	{
		case "demo_city":save.Map="District 64";
		if ((split(save.Origin," ")[2]).tointeger()<(-1000)) save.Map="Restroom";break;
		case "teleporting_room_v1":save.Map="ReVerse Laboratory";break;
		case "weapons_range":save.Map="Dev Map";break;
	}
}

::DisplaySavePanels<-function(IsLoading=false,canclose=true)
{
	local OpenTime=clock()
	
	local AlphaMod=clamp((clock()-OpenTime)*2,0,1)
	
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
	s_panel.SetPaintBackgroundEnabled( true );
	s_panel.SetPaintBackgroundType( 2 );
	s_panel.SetPaintBorderEnabled( true );
	
	
	s_panel.SetBgColor( 6, 10, 20, 248 );
	s_panel.SetSize( MenuSizeX,MenuSizeY+YRES(6)  );
	s_panel.SetPos( ScreenWidth()/2-MenuSizeX/2, ScreenHeight()/2-MenuSizeY/2);
	s_panel.SetMouseInputEnabled(true);
	
	b_panel_bg <- vgui.CreatePanel( "Panel", s_panel, "SavePanel2" );
	b_panel_bg.MakeReadyForUse();
	b_panel_bg.SetPos( s_panel.GetWide()/2-ListSizeX/2, MenuSizeY/2-ListSizeY/2+YRES(10)  );
	b_panel_bg.SetSize(ListSizeX, ListSizeY);
	b_panel_bg.SetBgColor( 0,0,0,255 );
	
	
	local CurX=XRES(320)
	local CurY=YRES(240)
	local FocusSave=(-1);
	local SelectedSave=(-1);
	
	local InPanel=true
	local SliderActive=false;

	function Cursor(x, y)
	{	
		CurX=x
		CurY=y
	}
	
	function Cursor2(x, y)
	{	
		CurX=x-b_panel_bg.GetXPos()
		
		CurY=y-b_panel_bg.GetYPos()
		//printl(CurY)
	}
	
	
	//b_panel_bg.SetCallback( "OnKeyCodePressed", function(a){DoExit(a);MapMove(a)}.bindenv(this) );
	//b_panel_bg.SetCallback( "OnKeyCodeReleased", MapMoveStop.bindenv(this) );
	b_panel_bg.SetCallback( "OnCursorMoved", Cursor.bindenv(this) );
	s_panel.SetCallback( "OnCursorMoved", Cursor2.bindenv(this) );
	b_panel_bg.SetCallback( "OnCursorExited", function(...){InPanel=false;}.bindenv(this) );
	//s_panel.SetCallback( "OnCursorExited", function(...){SliderActive=false}.bindenv(this) );
	b_panel_bg.SetCallback( "OnCursorEntered", function(...){InPanel=true}.bindenv(this) );
	
	s_pClose <- vgui.CreatePanel( "Button", s_panel, "Close" );
	s_pClose.SetPos(s_panel.GetWide()-s_pClose.GetTall(),s_pClose.GetTall()/4)
	s_pClose.SetPaintBorderEnabled( false );
	s_pClose.SetFont( surface.GetFont( "Marlett", false, "Tracker" ) );
	s_pClose.SetText( "r" );
	s_pClose.SetTextInset( 1, 0 );
	s_pClose.SetContentAlignment( Alignment.northwest );
	
	if (canclose) s_pClose.SetCallback( "DoClick", HideSavePanels.bindenv(this) );
	if (!canclose) s_pClose.SetCallback( "DoClick", function(...) {HideSavePanels();DisplayContinuePanels()}.bindenv(this) );
	
	if (IsLoading) s_panel.MakePopup();
	else bg_panel.MakePopup();
	
	b_panel_bg.SetAlpha(0)
	s_panel.SetAlpha(0)
	
	function PaintPanel()
	{
		//printl(CurY)
		
		AlphaMod=clamp((clock()-OpenTime)*2,0,1)
		local AlphaMod2=clamp((clock()-OpenTime)*10,0,1)
		
		if ((clock()-OpenTime)<=0.5)
		{
			b_panel_bg.SetAlpha(255*AlphaMod)
			s_panel.SetAlpha(255*AlphaMod2)
		}
		surface.DrawColoredText(SaveMenuTitleGlowFont,MenuSizeX/2-surface.GetTextWidth(SaveMenuTitleGlowFont,IsLoading ? "LOAD GAME" : "SAVE GAME")/2+2,YRES(7)+2,5, 175, 255, 15,IsLoading ? "LOAD GAME" : "SAVE GAME")
		surface.DrawColoredText(SaveMenuTitleFont,MenuSizeX/2-surface.GetTextWidth(SaveMenuTitleFont,IsLoading ? "LOAD GAME" : "SAVE GAME")/2,YRES(7),5, 175, 255, 255,IsLoading ? "LOAD GAME" : "SAVE GAME")
	}
	s_panel.SetCallback( "Paint", PaintPanel.bindenv(this) );
	
	
	local SaveID=0
	local Saves=[]
	while (LoadPreviewData(SaveID)!=false)
	{
		Saves.append(LoadPreviewData(SaveID))
		FixupLocation(Saves[SaveID])
		SaveID++
	}
	
	function RemoveSave(id=-1)
	{
		PlayID<-id
		StringToFile("saves/savedata_"+PlayID+".sav","")
		PlayID++
		while (FileExists("saves/savedata_"+PlayID+".sav"))
		{
			if (!IsSaveEmpty(PlayID)) KeyValuesToFile("saves/savedata_"+(PlayID-1)+".sav",FileToKeyValues("saves/savedata_"+PlayID+".sav"))
			else StringToFile("saves/savedata_"+(PlayID-1)+".sav","")
			PlayID++
		}
		
		if (FileExists("saves/savedata_"+PlayID+".sav")) 
			StringToFile("saves/savedata_"+PlayID+".sav","");
	}
	
	function UpdateSaveList()
	{
		SaveID=0
		Saves=[]
		while (LoadPreviewData(SaveID)!=false)
		{
			Saves.append(LoadPreviewData(SaveID))
			FixupLocation(Saves[SaveID])
			SaveID++
		}
	}
	
	
	
	local ListBorder=clamp(YRES(1)/2.0,1,64)
	
	
	local ListMargin=YRES(2)
	
	local SaveWidth=YRES(340)
	local SaveHeight=YRES(50)
	local SaveGap=YRES(8)
	
	
	local ScrollY=0
	
	function DoScroll(a)
	{	
		if (a<0) ScrollY=clamp(ScrollY+YRES(20)*a,-clamp((SaveHeight+SaveGap)*(Saves.len()-3.5+(!IsLoading).tointeger()), 0, 99999),0 )
		if (a>0) ScrollY=clamp(ScrollY+YRES(20)*a,-clamp((SaveHeight+SaveGap)*(Saves.len()-3.5+(!IsLoading).tointeger()), 0, 99999),0 )
	}
	
	b_panel_bg.SetCallback( "OnMouseWheeled", DoScroll.bindenv(this) );
	s_panel.SetCallback( "OnMouseWheeled", DoScroll.bindenv(this) );
	
	local Distance=ScrollY.tofloat()/(SaveHeight+SaveGap)/(3.5)
	local Scale=3.5/(Saves.len()+(!IsLoading).tointeger())

	local SliderY=0;
	
	local Removal=false;
	
	local RemovalActive=false;
	
	function DoClick(a)
	{
		//printl("PRESSED")
		
		if (a!=ButtonCode.MOUSE_LEFT&&(!RemovalActive)) return;
		
		if (CurX>(ListSizeX-YRES(6))&&CurY>Distance*(ListSizeY*(-Scale))&&CurY<(Distance*(ListSizeY*(-Scale))+ListSizeY*Scale)&&InPanel)
		{
			SliderActive=true
			SliderY=CurY+Distance*(ListSizeY*(Scale))
		}
		else SliderActive=false;
		
		
		if (FocusSave==Saves.len()) 
		{
			SaveSlot(Saves.len())
			
			SaveID=0
			Saves=[]
			while (LoadPreviewData(SaveID)!=false)
			{
				Saves.append(LoadPreviewData(SaveID))
				FixupLocation(Saves[SaveID])
				SaveID++
			}
			return
		}
		
		if (SelectedSave==FocusSave&&FocusSave!=(-1)&&(!Removal)&&(!RemovalActive))
		{
			if (IsLoading) LoadSlot(SelectedSave)
			else
				SaveSlot(SelectedSave);
			return
		}
		
		if (SelectedSave==FocusSave&&FocusSave!=(-1)&&RemovalActive&&(a==ButtonCode.MOUSE_RIGHT))
		{
			RemovalActive=false;
			surface.PlaySound("common/deselect.wav")
			printl("REMOVING SAVE "+SelectedSave)
			RemoveSave(SelectedSave)
			SelectedSave=-1;
			
			UpdateSaveList()
			return;
		}
		
		
		//printl(FocusSave)
		if (SelectedSave!=FocusSave)
		{
			RemovalActive=false
			SelectedSave=FocusSave;
				
			if (SelectedSave!=-1&&(!Removal)) surface.PlaySound("common/noise2.wav")
			else if (SelectedSave!=-1&&Removal) 
			{
				surface.PlaySound("common/launch_deny2.wav")
				RemovalActive=true
			}
			else surface.PlaySound("common/radiotalk.wav")
				
			if (IsLoading&&(player.GetHealth()<=0||GetMapName().find("background")!=null)&&(!Removal)&&SelectedSave!=(-1)) LoadSlot(SelectedSave);
		}
	}
	
	function DoRelease(a)
	{
		SliderActive=false
		//printl("RELEASED")
	}
	
	b_panel_bg.SetCallback( "OnMousePressed", DoClick.bindenv(this) );
	b_panel_bg.SetCallback( "OnMouseDoublePressed", DoClick.bindenv(this) );
	b_panel_bg.SetCallback( "OnMouseReleased", DoRelease.bindenv(this) );
	s_panel.SetCallback( "OnMousePressed", DoClick.bindenv(this) );
	s_panel.SetCallback( "OnMouseDoublePressed", DoClick.bindenv(this) );
	s_panel.SetCallback( "OnMouseReleased", DoRelease.bindenv(this) );
	
	local Highlighted=false;
	
	
	function PaintList()
	{
		
		//printl(Scale)
		//printl(Distance)
		if (SliderActive) ScrollY=clamp((-CurY+SliderY)/Scale,-(SaveHeight+SaveGap)*(Saves.len()+(!IsLoading).tointeger()-3.5),0)
		
		local NewSaveOffset=IsLoading ? 0 : (SaveHeight+SaveGap)
		NewSaveOffset+=ScrollY;
		
		FocusSave=-1
		
		//printl(NewSaveOffset)
		if (!IsLoading)
		{
			local ListSizeX=ListSizeX-YRES(6)
			
			local SaveX=ListSizeX/2-SaveWidth/2-SaveWidth*1.1*Bias(1-clamp((clock()-OpenTime)*2,0,1),0.15)
			
			local SaveY=ScrollY+SaveGap
			
			//printl(CurY)
			
			if (CurX>SaveX&&CurX<(SaveX+SaveWidth)&&CurY>SaveY&&CurY<(SaveY+SaveHeight)&&InPanel)
			{
				if (!Highlighted) surface.PlaySound("common/noise.wav");
				FocusSave=SaveID
				Highlighted=true
			}
			
			surface.SetColor(0,134,244,255)
			if (FocusSave==SaveID)
				DrawOutlinedBox(ListBorder*2, SaveX,SaveY,SaveWidth,SaveHeight, 0,true,[0,142,255], [0,94,166])
			else
				DrawOutlinedBox(ListBorder, SaveX,SaveY,SaveWidth,SaveHeight, 0,true,[0,134,244], [0,78,137])
			
			
			
			local Symb=""
			if (Time()-Time().tointeger()<1) Symb="+"
			if (Time()-Time().tointeger()<0.75) Symb="-"
			if (Time()-Time().tointeger()<0.5) Symb="+"
			if (Time()-Time().tointeger()<0.25) Symb="-"
			
			if (FocusSave==SaveID)
			{
				DrawColoredTextCentered(SaveMenuBigGlowFont,SaveX+SaveWidth/2,SaveY+SaveHeight/2,0, 134, 244, 75,Symb+" CREATE NEW SAVE "+Symb)
				DrawColoredTextCentered(SaveMenuBigFont,SaveX+SaveWidth/2,SaveY+SaveHeight/2,0, 134, 244, 255,Symb+" CREATE NEW SAVE "+Symb)
			}
			else
				DrawColoredTextCentered(SaveMenuBigFont,SaveX+SaveWidth/2,SaveY+SaveHeight/2,0, 134, 244, 255,"- CREATE NEW SAVE -")
			
		}
		
		
		//
		//	SLIDER
		//
		if ((Saves.len()+(!IsLoading).tointeger())>3)
		{
			Distance=ScrollY.tofloat()/(SaveHeight+SaveGap)/(3.5)
			Scale=3.5/(Saves.len()+(!IsLoading).tointeger())
			
			if (SliderActive)
			{
				surface.SetColor(0,155,255,255)
				surface.DrawFilledRect(ListSizeX-YRES(6),Distance*(ListSizeY*(-Scale)),YRES(6),ListSizeY*Scale)
				DrawOutlinedBox(ListBorder*3, ListSizeX-YRES(6),Distance*(ListSizeY*(-Scale)),YRES(6),ListSizeY*Scale, 0,true,[0,87,155],[0,134,244])
			}
			else
			{
				surface.SetColor(0,100,211,255)
				if (CurX>(ListSizeX-YRES(6))&&CurY>Distance*(ListSizeY*(-Scale))&&CurY<(Distance*(ListSizeY*(-Scale))+ListSizeY*Scale)&&InPanel) surface.SetColor(0,114,224,255)
				surface.DrawFilledRect(ListSizeX-YRES(6),Distance*(ListSizeY*(-Scale)),YRES(6),ListSizeY*Scale)
				DrawOutlinedBox(ListBorder*3, ListSizeX-YRES(6),Distance*(ListSizeY*(-Scale)),YRES(6),ListSizeY*Scale, 0,true,[0,134,244],[0,87,155])
			}
		}
		
		if (Saves.len()==0&&IsLoading)
			DrawColoredTextCentered(SaveMenuTitleFont,ListSizeX/2,ListSizeY/2,112,112,112, 255,"No save games to display.");
		
		for (SaveID=0;SaveID<Saves.len();SaveID++)
		{
			local ListSizeX=ListSizeX-YRES(6)
			
			local YOffset=(SaveHeight+SaveGap)*(Saves.len()-1-SaveID)+NewSaveOffset;
			
			local SaveX=ListSizeX/2-SaveWidth/2-SaveWidth*1.1*Bias(1-clamp((clock()-OpenTime)*2-(Saves.len()-SaveID)*0.15,0,1),0.15)
			
			
			local SaveY=SaveGap+YOffset
			
			if (CurX>SaveX&&CurX<(SaveX+SaveWidth)&&CurY>SaveY&&CurY<(SaveY+SaveHeight)&&InPanel)
			{
				if (!Highlighted) surface.PlaySound("common/noise.wav");
				FocusSave=SaveID
				Highlighted=true
			}
			
			local SelectionMod=(SelectedSave==SaveID) ? 0.01 : 1
			
			surface.SetColor(0,21,47,(FocusSave==SaveID) ? 175*SelectionMod : 105*SelectionMod)
			surface.DrawFilledRect(SaveX,SaveY,SaveWidth,ListMargin*2+YRES(13))
			
			surface.SetColor(0,134,244,255*SelectionMod)
			//surface.DrawOutlinedRect(SaveX,SaveY,SaveWidth,SaveHeight,ListBorder)
			
			if (FocusSave==SaveID)
				DrawOutlinedBox(ListBorder*2, SaveX,SaveY,SaveWidth,SaveHeight, 0,true,[0,142,255], [0,94,166])
			else
				DrawOutlinedBox(ListBorder, SaveX,SaveY,SaveWidth,SaveHeight, 0,true,[0,134,244], [0,78,137])
			
			
			
			//surface.DrawOutlinedRect(SaveX+ListMargin,SaveY+ListMargin,YRES(21),YRES(13),ListBorder)
			if (FocusSave==SaveID) DrawOutlinedBox(ListBorder, SaveX+ListMargin,SaveY+ListMargin,YRES(21),YRES(13), 0,true,[0,155,255],[0,92,166])
			else DrawOutlinedBox(ListBorder, SaveX+ListMargin,SaveY+ListMargin,YRES(21),YRES(13), 0,true,[0,134,244],[0,78,137])
			
			
			if (FocusSave==SaveID)
			{
				DrawColoredTextCentered(SaveMenuListFont,SaveX+ListMargin+YRES(21)/2,SaveY+ListMargin+(YRES(13)/2.0+0.5),0, 134,244, 255,SaveID.tostring())
				DrawColoredTextCentered(SaveMenuListFont,SaveX+ListMargin+YRES(110),SaveY+ListMargin+(YRES(13)/2.0+0.5),0, 134,244, 255*SelectionMod,"LOCATION")
				DrawColoredTextCentered(SaveMenuListFont,SaveX+ListMargin+YRES(273),SaveY+ListMargin+(YRES(13)/2.0+0.5),0, 134,244, 255*SelectionMod,"PLAYTIME")
			}
			else
			{
				DrawColoredTextCentered(SaveMenuListFont,SaveX+ListMargin+YRES(21)/2,SaveY+ListMargin+(YRES(13)/2.0+0.5),0, 106, 188, 255,SaveID.tostring())
				DrawColoredTextCentered(SaveMenuListFont,SaveX+ListMargin+YRES(110),SaveY+ListMargin+(YRES(13)/2.0+0.5),0, 106, 188, 255*SelectionMod,"LOCATION")
				DrawColoredTextCentered(SaveMenuListFont,SaveX+ListMargin+YRES(273),SaveY+ListMargin+(YRES(13)/2.0+0.5),0, 106, 188, 255*SelectionMod,"PLAYTIME")
			}
			
			
			surface.DrawColoredText(SaveMenuListSmallFont,SaveX+ListMargin,SaveY+SaveHeight-ListMargin-surface.GetFontTall(SaveMenuListSmallFont),0, 79, 145, 255*SelectionMod,Saves[SaveID].Time.slice(0,10)+" - "+Saves[SaveID].Time.slice(11,16))
			
			
			if (FocusSave==SaveID) 
			{
				DrawColoredTextNorth(SaveMenuMapGlowFont,SaveX+ListMargin+YRES(110),SaveY+ListMargin*3+YRES(13),0, 144, 255, 65*SelectionMod,Saves[SaveID].Map)
				DrawColoredTextNorth(SaveMenuMapFont,SaveX+ListMargin+YRES(110),SaveY+ListMargin*3+YRES(13),0, 155, 255, 255*SelectionMod,Saves[SaveID].Map)
			}
			else DrawColoredTextNorth(SaveMenuMapFont,SaveX+ListMargin+YRES(110),SaveY+ListMargin*3+YRES(13),0, 134, 244, 255*SelectionMod,Saves[SaveID].Map)
			
		
			local PlaytimeText=""
			local playtime=Saves[SaveID].PlayTime.tointeger()
			local secs=playtime%60
			local mins=(playtime/60)%60
			local hours=playtime/3600
			
			PlaytimeText=format("%.2i:%.2i:%.2i",hours,mins,secs)
		
			if (FocusSave==SaveID) 
			{	
				DrawColoredTextNorth(SaveMenuTimeGlowFont,SaveX+ListMargin+YRES(273),SaveY+ListMargin*3+YRES(13),0, 144, 255, 65*SelectionMod,PlaytimeText)
				DrawColoredTextNorth(SaveMenuTimeFont,SaveX+ListMargin+YRES(273),SaveY+ListMargin*3+YRES(13),0, 155, 255, 255*SelectionMod,PlaytimeText)
				local marlett=surface.GetFont( "Marlett", false, "Tracker" )
				
				if (CurX>SaveX+SaveWidth-surface.GetTextWidth(marlett,"r")-ListMargin&&CurX<(SaveX+SaveWidth)&&CurY>SaveY&&CurY<(SaveY+ListMargin+surface.GetFontTall(marlett))&&InPanel)
				{
					surface.DrawColoredText(marlett,SaveX+SaveWidth-surface.GetTextWidth(marlett,"r")-ListMargin,SaveY+ListMargin, 255, 28, 25, 255*SelectionMod, "r");
					Removal=true
				}
				else 
				{
					surface.DrawColoredText(marlett,SaveX+SaveWidth-surface.GetTextWidth(marlett,"r")-ListMargin,SaveY+ListMargin, 0, 155, 255, 255*SelectionMod, "r");
					Removal=false
				}
				
			}
			else DrawColoredTextNorth(SaveMenuTimeFont,SaveX+ListMargin+YRES(273),SaveY+ListMargin*3+YRES(13),0, 134, 244, 255*SelectionMod,PlaytimeText)
				
			
			local SaveTexture=surface.ValidateTexture("vgui/resource/save", true, false, false)
			surface.SetTexture(SaveTexture)
			
			if (FocusSave==SaveID) surface.SetColor(0,48,96,255*SelectionMod)
			else surface.SetColor(0,24,48,255*SelectionMod)
			
			surface.DrawTexturedRect(SaveX+ListMargin+YRES(21)/2-YRES(20)/2,SaveY+ListMargin*2+YRES(13),YRES(20),YRES(20))
			
			
			if (SelectedSave==SaveID&&(!RemovalActive))
			{
				if (!IsLoading)
				{
					DrawColoredTextCentered(SaveMenuBigGlowFont,SaveX+SaveWidth/2,SaveY+SaveHeight/2,112,177,255, 155*fabs(sin(clock()*4)),"Overwrite?")
					DrawColoredTextCentered(SaveMenuBigFont,SaveX+SaveWidth/2,SaveY+SaveHeight/2,222,222,222, 255,"Overwrite?")
				}
				if (IsLoading&&player.GetHealth()>0&&GetMapName().find("background")==null)
				{
					DrawColoredTextCentered(SaveMenuTitleGlowFont,SaveX+SaveWidth/2,SaveY+SaveHeight/2-surface.GetFontTall(SaveMenuTitleFont)/2,112,177,255, 255*fabs(sin(clock()*4)),"Load this save?")
					DrawColoredTextCentered(SaveMenuTitleGlowFont,SaveX+SaveWidth/2,SaveY+SaveHeight/2+surface.GetFontTall(SaveMenuTitleFont)/2,112,177,255, 255*fabs(sin(clock()*4)),"All unsaved progress will be lost")
					
					DrawColoredTextCentered(SaveMenuTitleFont,SaveX+SaveWidth/2,SaveY+SaveHeight/2-surface.GetFontTall(SaveMenuTitleFont)/2,222,222,222, 255,"Load this save?")
					DrawColoredTextCentered(SaveMenuTitleFont,SaveX+SaveWidth/2,SaveY+SaveHeight/2+surface.GetFontTall(SaveMenuTitleFont)/2,222,222,222, 255,"All unsaved progress will be lost")
				}
			}
			else if (SelectedSave==SaveID&&RemovalActive)
			{
				DrawColoredTextCentered(SaveMenuTitleGlowFont,SaveX+SaveWidth/2,SaveY+SaveHeight/2-surface.GetFontTall(SaveMenuTitleFont),255,2,2, 255*fabs(sin(clock()*6)),"DELETE this save?")
				DrawColoredTextCentered(SaveMenuTitleGlowFont,SaveX+SaveWidth/2,SaveY+SaveHeight/2,255,2,2, 255*fabs(sin(clock()*6)),"This action cannot be undone")
				DrawColoredTextCentered(SaveMenuTitleGlowFont,SaveX+SaveWidth/2,SaveY+SaveHeight/2+surface.GetFontTall(SaveMenuTitleFont),255,2,2, 255*fabs(sin(clock()*6)),"Right Click to confirm")
				
				DrawColoredTextCentered(SaveMenuTitleFont,SaveX+SaveWidth/2,SaveY+SaveHeight/2-surface.GetFontTall(SaveMenuTitleFont),222,72,72, 255,"DELETE this save?")
				DrawColoredTextCentered(SaveMenuTitleFont,SaveX+SaveWidth/2,SaveY+SaveHeight/2,222,72,72, 255,"This action cannot be undone")
				DrawColoredTextCentered(SaveMenuTitleFont,SaveX+SaveWidth/2,SaveY+SaveHeight/2+surface.GetFontTall(SaveMenuTitleFont),222,72,72, 255,"Right Click to confirm")
			}
			
		}			
		
		
		// BOTTOM FADE
		if  (ScrollY!=(-clamp((SaveHeight+SaveGap)*(Saves.len()-3.5+(!IsLoading).tointeger()), 0, 99999)))
		{
		surface.SetColor(0,5,11,255)
		surface.DrawFilledRectFade(0,ListSizeY-YRES(21),ListSizeX,YRES(21),0,255,false)
		surface.DrawFilledRectFade(0,ListSizeY-YRES(21),ListSizeX,YRES(21),0,255,false)
		}
		
		
		// TOP FADE
		if  (ScrollY!=0)
		{
			surface.SetColor(0,5,11,255)
			surface.DrawFilledRectFade(0,0,ListSizeX,YRES(21),255,0,false)
			surface.DrawFilledRectFade(0,0,ListSizeX,YRES(21),255,0,false)
		}
		
		surface.SetColor(0,56,102,255)
		surface.DrawFilledRect(ListSizeX-ListBorder,0,ListBorder,ListSizeY-ListBorder)
		surface.DrawFilledRect(0,ListSizeY-ListBorder,ListSizeX-ListBorder,ListBorder)
		
		surface.SetColor(32,37,40,255)
		surface.DrawFilledRect(0,0,ListBorder,ListSizeY)
		surface.DrawFilledRect(0,0,ListSizeX,ListBorder)
		
		if (FocusSave==-1) Highlighted=false;
		
	}
	b_panel_bg.SetCallback( "Paint", PaintList.bindenv(this) );
	
	
	function SaveSlot(a)
	{
		NetMsg.Start("Save_a_game");
		NetMsg.WriteShort(a);
		NetMsg.Send();
		HideSavePanels()
		
		BigNotifications.append( [Time(), "Game Saved...", Vector(0,205,0),4,1.5] )
		if (BigNotifications.len()>3) BigNotifications.remove(0);
		
		//Globals.GetCounter(Globals.GetIndex("PlaythroughID"),a)
		
	}
	function LoadSlot(a)
	{
		if (!FileExists("saves/savedata_"+a+".sav")) return
		if (FileToString("saves/savedata_"+a+".sav")==null) return
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
			bg_panel.SetAlpha(clamp(255-(clock()-OpenTime)*255*3,0,255))
			if (clamp(255-(clock()-OpenTime)*255*3,0,255)<1)
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
			s_panel.SetAlpha(clamp(255-(clock()-OpenTime)*3*255,0,255))
			if (clamp(255-(clock()-OpenTime)*3*255,0,255)<1)
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
