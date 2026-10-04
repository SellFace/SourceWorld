if (CLIENT_DLL)
{
	PhonePanel<-null
	PhoneTime<-0
	PhoneClosing<-false
	
	AllPortalSpots<-[null,null,null,null]
	PortalSpots<-array(0)
	CenterSpot<-null
	PortalID<-null
	
	local PortalAnimTime=0;
	
	local PortalOpen=false
	local PortalOpen2=false
	
	
	local Calling=false;
	local CallTime=0;
	local CallAction=function(){};
	
	local LastPortalSound=0;
	
	local OpenedMail=null;
	
	surface.CreateFont( "PhoneBold2",        // Name of this font entry (user-defined, can be anything)
	{
		"name"            : "Consolas"    // Name of the font file
		"tall"            : 12       // Size of the text
		"weight"        : 600        // Amount of boldness to add
		//"blur"            : 1        // Amount of blur to add (optional)
		"antialias"     : false           // Enables font smoothing
		"dropshadow"     : true           // Enables font smoothing
		"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
	} );
	local PhoneBoldFont=surface.GetFont( "PhoneBold2", true )
	
	surface.CreateFont( "PhoneSmall2",        // Name of this font entry (user-defined, can be anything)
	{
		"name"            : "Consolas"    // Name of the font file
		"tall"            : 10       // Size of the text
		"weight"        : 0        // Amount of boldness to add
		//"blur"            : 1        // Amount of blur to add (optional)
		"antialias"     : false           // Enables font smoothing
		"dropshadow"     : true           // Enables font smoothing
		"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
	} );
	local PhoneSmallFont=surface.GetFont( "PhoneSmall2", true )
	
	surface.CreateFont( "PhoneReg",        // Name of this font entry (user-defined, can be anything)
	{
		"name"            : "Consolas"    // Name of the font file
		"tall"            : 12       // Size of the text
		"weight"        : 0        // Amount of boldness to add
		//"blur"            : 1        // Amount of blur to add (optional)
		"antialias"     : false           // Enables font smoothing
		"dropshadow"     : true           // Enables font smoothing
		"proportional"     : true            // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
	} );
	local PhoneRegFont=surface.GetFont( "PhoneReg", true )
	
	NetMsg.Receive("OpenPhone", function() {
		PhoneMenu()
	}.bindenv(this))
	
	function DayName(d)
	{
		switch(d)
		{
			case 1:return "Mon"
			case 2:return "Tue"
			case 3:return "Wed"
			case 4:return "Thu"
			case 5:return "Fri"
			case 6:return "Sat"
			case 0:return "Sun"
		}
	}
	function MonthName(m)
	{
		switch(m)
		{
			case 0:return "January"
			case 1:return "February"
			case 2:return "March"
			case 3:return "April"
			case 4:return "May"
			case 5:return "June"
			case 6:return "July"
			case 7:return "August"
			case 8:return "September"
			case 9:return "October"
			case 10:return "November"
			case 11:return "December"
		}
	}
	
	local size=YRES(350)
	
	function DrawDashLine(x2, y2, x1, y1,gap=12,wid=5)	//12 3
	{
		local Timer=(Time()*2-Time().tointeger()*2)
		//local Timer=0
		Timer=-(Timer*4).tointeger()/4.0
		for (local i=gap;i<DotDistance([x1, y1], [x2, y2])-wid-gap*Timer-(gap-wid)+gap;i+=gap)
		{
			local distx=x2-x1;
			local disty=y2-y1;
			local angle=atan2(disty, distx);
			surface.DrawLine(clamp(x1+(i+gap*Timer)*cos(angle),min(x1,x2),max(x1,x2)), clamp(y1+(i+gap*Timer)*sin(angle),min(y1,y2),max(y1,y2)), clamp(x1+(i+wid+gap*Timer)*cos(angle),min(x1,x2),max(x1,x2)), clamp(y1+(i+wid+gap*Timer)*sin(angle),min(y1,y2),max(y1,y2)))
		}
	}
	
	local MakeCall = function(action)
	{
		Calling=true
		CallTime=Time()+3
		CallAction=action
		surface.PlaySound("phone/dial.wav")
	}
		
	local XRE = function(x)
	{
		return RemapVal(x,0,300,ScreenWidth()-size-YRES(70)+size*0.297,ScreenWidth()-size-YRES(70)+size-size*0.301).tointeger()
	}
	local YRE = function(y)
	{
		return RemapVal(y,0,500,ScreenHeight()-size+YRES(1)+size*0.177,ScreenHeight()-size+YRES(1)+size-size*0.149).tointeger()
	}
	
	local XS = function(x)
	{
		return XRE(x)-XRE(0)
	}
	local YS = function(y)
	{
		return YRE(y)-YRE(0)
	}
	
	local PhoneButtons=[];
	
	local PhoneScreen="Home"
	
	class PhoneButton
	{
		Name="none"
		Active=false
		X=0
		Y=0
		ID=0
		Selected=false;
		OnPress=null
		Paint=null
		PaintSelected=null

		constructor(name, x, y) {
			Name=name
			X=x
			Y=y
			PhoneButtons.append(this)
			ID=PhoneButtons.len()-1
		}
		
		Paint=function()
		{
			
		}
		
		PaintSelected=function()
		{
			
		}
		
		OnPress=function()
		{
			
		}
	}
	
	class PhoneTab extends PhoneButton
	{
		DisplayText=""
		IconX=0
		IconY=0
		
		function Paint()
		{
			local IconSize=YRE(70)-YRE(0)
		
			surface.SetTexture(surface.ValidateTexture("vgui/phone/icons",true,false,false))
			surface.DrawTexturedSubRect(X-IconSize/2,Y-IconSize/2,X+IconSize/2,Y+IconSize/2,IconX,IconY,IconX+0.5,IconY+0.5)
			surface.DrawColoredText(PhoneRegFont,X-surface.GetTextWidth(PhoneRegFont,DisplayText)/2+YRES(1),Y+IconSize/2+YRES(1),0,0,0,255,DisplayText)
			surface.DrawColoredText(PhoneRegFont,X-surface.GetTextWidth(PhoneRegFont,DisplayText)/2,Y+IconSize/2,255,255,255,255,DisplayText)
		}
		
		function PaintSelected()
		{
			local IconSize=YRE(70)-YRE(0)
		
			surface.SetTexture(surface.ValidateTexture("vgui/phone/icons_s",true,false,false))
			surface.DrawTexturedSubRect(X-IconSize/2,Y-IconSize/2,X+IconSize/2,Y+IconSize/2,IconX,IconY,IconX+0.5,IconY+0.5)
			surface.DrawColoredText(PhoneBoldFont,X-surface.GetTextWidth(PhoneBoldFont,DisplayText)/2+YRES(1),Y+IconSize/2+YRES(1),120,120,120,255,DisplayText)
			surface.DrawColoredText(PhoneBoldFont,X-surface.GetTextWidth(PhoneBoldFont,DisplayText)/2,Y+IconSize/2,255,255,255,255,DisplayText)
		}
	}
	
	class PhoneFriend extends PhoneButton
	{
		FriendName=""
		
		function Paint()
		{
			
			
			surface.DrawColoredText(PhoneBoldFont,X-surface.GetTextWidth(PhoneBoldFont,FriendName)/2,Y+YS(6),0,0,0,255,FriendName)
			surface.DrawColoredText(PhoneBoldFont,X-surface.GetTextWidth(PhoneBoldFont,FriendName)/2,Y+YS(5),255,255,255,255,FriendName)
			
			surface.SetColor(0,74,127,255)
			surface.DrawOutlinedRect(X-XS(250)/2,Y,XS(250),YS(80),YS(2))
			
			local Status=1;
			if (SW_COMPANIONS.find(FriendName)!=null||SW_COMPANIONS.find(FriendName.tolower())!=null) Status=2;
			local StatusText=""
			local StatusC=Vector(0,0,0)
			switch(Status)
			{
				case 0:StatusText="Unavailable";StatusC=Vector(255,5,5);break
				case 1:StatusText="Available";StatusC=Vector(5,255,5);break
				case 2:StatusText="In Party";StatusC=Vector(255,255,5);break
			}
			
			surface.DrawColoredText(PhoneSmallFont,X-surface.GetTextWidth(PhoneSmallFont,StatusText)/2,Y+surface.GetFontTall(PhoneBoldFont)+YS(3),StatusC.x,StatusC.y,StatusC.z,255,StatusText)
			
			
			if (Status==1) surface.DrawColoredText(PhoneSmallFont,X-surface.GetTextWidth(PhoneSmallFont,"Call")/2,Y+surface.GetFontTall(PhoneBoldFont)*2,0,148,255,55,"Call");
		}
		
		function PaintSelected()
		{
			surface.DrawColoredText(PhoneBoldFont,X-surface.GetTextWidth(PhoneBoldFont,FriendName)/2,Y+YS(6),0,0,0,255,FriendName)
			surface.DrawColoredText(PhoneBoldFont,X-surface.GetTextWidth(PhoneBoldFont,FriendName)/2,Y+YS(5),255,255,255,255,FriendName)
			
			surface.SetColor(0,74,127,255)
			surface.DrawOutlinedRect(X-XS(250)/2,Y,XS(250),YS(80),YS(3))
			surface.SetColor(0,157,255,255)
			surface.DrawOutlinedRect(X-XS(250)/2,Y,XS(250),YS(80),YS(2))
			
			local Status=1;
			if (SW_COMPANIONS.find(FriendName)!=null||SW_COMPANIONS.find(FriendName.tolower())!=null) Status=2;
			local StatusText=""
			local StatusC=Vector(0,0,0)
			switch(Status)
			{
				case 0:StatusText="Unavailable";StatusC=Vector(255,5,5);break
				case 1:StatusText="Available";StatusC=Vector(5,255,5);break
				case 2:StatusText="In Party";StatusC=Vector(255,255,5);break
			}
			
			surface.DrawColoredText(PhoneSmallFont,X-surface.GetTextWidth(PhoneSmallFont,StatusText)/2,Y+surface.GetFontTall(PhoneBoldFont)+YS(3),StatusC.x,StatusC.y,StatusC.z,255,StatusText)
			
			if (Status==1) 
			{
				surface.DrawColoredText(PhoneSmallFont,X-surface.GetTextWidth(PhoneSmallFont,"Call")/2,Y+surface.GetFontTall(PhoneBoldFont)*2,30,178,255,255,"Call")
				surface.SetColor(0,157,255,255)
				surface.DrawFilledRect(X-surface.GetTextWidth(PhoneSmallFont," Call ")/2,Y+surface.GetFontTall(PhoneBoldFont)*2+surface.GetFontTall(PhoneSmallFont)-YS(2),surface.GetTextWidth(PhoneSmallFont," Call "),YS(2))
			}
		}
	}
	
	local MailTexture=surface.ValidateTexture("vgui/terminal/mail", true, false, false)
	
	local PhoneMail = class extends PhoneButton
	{
		Title=""
		Msg=null
		Text=""
		
		function Paint()
		{
			surface.DrawColoredText(22,X+YS(5),Y+YS(2),0,0,0,255,Title)
			if (Msg.Status==1)
			surface.DrawColoredText(22,X+YS(4),Y+YS(1),245, 245, 200,255,Title);
			else
			surface.DrawColoredText(22,X+YS(4),Y+YS(1),215,215,215,255,Title);	
		
			surface.SetTexture(MailTexture)
			if (Msg.Status==1) surface.SetColor(245, 245, 100, 255)
			else surface.SetColor(210, 210, 210, 255)
			
			surface.DrawTexturedSubRect(X-XS(23),Y,X-XS(23)+YS(30),Y+YS(30),0+(0.51)*(Msg.Status==2).tointeger(),0,0.5+(0.51)*(Msg.Status==2).tointeger(),0.5)
		}
		
		function PaintSelected()
		{
			if (Msg.Status==1)
			surface.SetColor(245, 245, 200,255);
			else
			surface.SetColor(215,215,215,255);
			//surface.DrawFilledRect(X+YS(2),Y+YS(2),XS(280)-YS(4),surface.GetFontTall(22))
			surface.DrawFilledRect(X+YS(2),Y+YS(2),surface.GetTextWidth(22,this.Title)+YS(4),surface.GetFontTall(22))
			//surface.DrawColoredText(22,X+YS(1),Y+YS(1),0,0,0,255,FriendName)
			surface.DrawColoredText(22,X+YS(4),Y+YS(1),0,0,0,255,Title)
			
			surface.SetTexture(MailTexture)
			if (Msg.Status==1) surface.SetColor(245, 245, 100, 255)
			else surface.SetColor(210, 210, 210, 255)
			
			surface.DrawTexturedSubRect(X-XS(23),Y,X-XS(23)+YS(30),Y+YS(30),0+(0.51)*(Msg.Status==2).tointeger(),0,0.5+(0.51)*(Msg.Status==2).tointeger(),0.5)
		}
	}
	
	local DeactivateAllButtons=function()
	{
		foreach (Button in PhoneButtons) Button.Active=false;
	}
	
	local SwitchScreen=function(name)
	{
		PhoneScreen=name;
		switch (name)
		{
			case "Home":
				DeactivateAllButtons()
				PhoneButtons[0].Active=true
				PhoneButtons[1].Active=true
				PhoneButtons[2].Active=true
				PhoneButtons[3].Active=true
				break;
			case "Contacts":
				DeactivateAllButtons()
				PhoneButtons[4].Active=true
				PhoneButtons[5].Active=true
				break;
			case "Portal":
				DeactivateAllButtons()
				PhoneButtons[4].Active=true
				break;
			case "Messages":
				DeactivateAllButtons()
				PhoneButtons[4].Active=true
				foreach (B in PhoneButtons)
				{
					if (B instanceof PhoneMail)
					{
						B.Active=true;
					}
				}
				
				break;
			case "Mail":
				DeactivateAllButtons()
				PhoneButtons[6].Active=true
				
				break;
		}
	}
	
	local B = PhoneTab("Contacts",XRE(75),YRE(235))
	B.IconX=0
	B.IconY=0
	B.DisplayText=B.Name
	B.Active=true
	B.OnPress=function(){SwitchScreen("Contacts");surface.PlaySound("phone/deck_ui_navigation.wav");}
	
	B = PhoneTab("Messages",XRE(225),YRE(235))
	B.IconX=0.5
	B.IconY=0
	B.DisplayText=B.Name
	B.Active=true
	B.OnPress=function(){SwitchScreen("Messages");surface.PlaySound("phone/deck_ui_navigation.wav");}
	
	B = PhoneTab("Portal",XRE(75),YRE(385))
	B.IconX=0
	B.IconY=0.5
	B.DisplayText=B.Name
	B.Active=true
	B.OnPress=function(){SwitchScreen("Portal");surface.PlaySound("phone/deck_ui_navigation.wav");}
	
	B = PhoneTab("Settings",XRE(225),YRE(385))
	B.IconX=0.5
	B.IconY=0.5
	B.DisplayText=B.Name
	B.Active=true
	
	B = PhoneButton("Back",XRE(15),YRE(445))
	B.Paint=function()
	{
		surface.SetColor(155,155,155,255)
		//surface.DrawOutlinedRect(X,Y,surface.GetTextWidth(22,"Back")+YS(8),surface.GetFontTall(22)+YS(4),YS(2))
		
		local FrameX=XRE(0)
		local FrameY=YRE(0)
		local FrameHeight=YS(500)	// REMINDER. phone dimensions is 500x300
		local FrameWide=XS(300)
		
		local brdr=YS(12)
		
		local MainWide=FrameWide-YS(2)*2
		
		surface.SetColor(0,133,229,255)
		
		surface.DrawOutlinedRect(X,Y-brdr,MainWide-brdr*2,surface.GetFontTall(81)+brdr*2,YS(2))
		
		surface.DrawColoredText(PhoneRegFont,X+MainWide/2-surface.GetTextWidth(PhoneRegFont,"BACK")/2-brdr,Y+YS(2),25,155,255,255,"BACK")
	}
	B.PaintSelected=function()
	{
		surface.SetColor(155,155,155,255)
		//surface.DrawOutlinedRect(X,Y,surface.GetTextWidth(22,"Back")+YS(8),surface.GetFontTall(22)+YS(4),YS(2))
		
		local FrameX=XRE(0)
		local FrameY=YRE(0)
		local FrameHeight=YS(500)	// REMINDER. phone dimensions is 500x300
		local FrameWide=XS(300)
		
		local brdr=YS(12)
		
		local MainWide=FrameWide-YS(2)*2
		
		surface.SetColor(0,133,229,255)
		
		surface.SetColor(65,193,255,255)
		surface.DrawOutlinedRect(X,Y-brdr,MainWide-brdr*2,surface.GetFontTall(81)+brdr*2,YS(2))
		surface.SetColor(0,133,229,255)
		surface.DrawOutlinedRect(X+YS(4),Y-brdr+YS(4),MainWide-brdr*2-YS(8),surface.GetFontTall(81)+brdr*2-YS(8),YS(2))
		
		surface.DrawColoredText(PhoneBoldFont,X+MainWide/2-surface.GetTextWidth(PhoneBoldFont,"BACK")/2-brdr,Y+YS(2),85,223,255,255,"BACK")
	}
	B.OnPress=function(){SwitchScreen("Home");surface.PlaySound("phone/deck_ui_misc_01.wav");}
	
	B = PhoneFriend("F1",XRE(150),YRE(65))
	B.FriendName="Richard"
	B.OnPress=function(){
		
		if (SW_COMPANIONS.find(FriendName)!=null||SW_COMPANIONS.find(FriendName.tolower())!=null)
		{
			surface.PlaySound("phone/deck_ui_bumper_end_02.wav")
			return;
		}
		MakeCall(function()
		{ 
			SW_COMPANIONS[SW_COMPANIONS.find(null)]=this.FriendName;
			NetMsg.Start("InitCompanion")
			NetMsg.WriteString(this.FriendName)
			NetMsg.Send()
		}.bindenv(this))
	}
	
	B = PhoneButton("Back",XRE(20),YRE(460))
	B.Paint=function()
	{
		surface.SetColor(155,155,155,255)
		//surface.DrawOutlinedRect(X,Y,surface.GetTextWidth(22,"Back")+YS(8),surface.GetFontTall(22)+YS(4),YS(2))
		surface.DrawColoredText(22,X+YS(4),Y+YS(2),195,195,195,255,"Back")
	}
	B.PaintSelected=function()
	{
		surface.SetColor(255,255,255,255)
		surface.DrawFilledRect(X,Y+surface.GetFontTall(22),surface.GetTextWidth(22,"Back")+YS(8),YS(2))
		surface.DrawColoredText(22,X+YS(4),Y+YS(2),255,255,255,255,"Back")
	}
	B.OnPress=function(){OpenedMail=null;SwitchScreen("Messages");surface.PlaySound("phone/deck_ui_misc_01.wav");}
	
	local FoundSpots=[]
	
	B = PhoneButton("PortalSendData",XRE(15),YRE(200))
	B.Paint=function()
	{
		surface.SetColor(155,155,155,255)
		//surface.DrawOutlinedRect(X,Y,surface.GetTextWidth(22,"Back")+YS(8),surface.GetFontTall(22)+YS(4),YS(2))
		
		local FrameX=XRE(0)
		local FrameY=YRE(0)
		local FrameHeight=YS(500)	// REMINDER. phone dimensions is 500x300
		local FrameWide=XS(300)
		
		local brdr=YS(12)
		
		local MainWide=FrameWide-YS(2)*2
		
		surface.SetColor(0,133,229,255)
		
		surface.DrawOutlinedRect(X+YS(20),Y-brdr,MainWide-brdr*2-YS(40),surface.GetFontTall(81)+brdr*2,YS(2))
		
		surface.DrawColoredText(PhoneRegFont,X+MainWide/2-surface.GetTextWidth(PhoneRegFont,"SEND SPOT DATA")/2-brdr,Y+YS(2),25,155,255,255,"SEND SPOT DATA")
	}
	B.PaintSelected=function()
	{
		surface.SetColor(155,155,155,255)
		//surface.DrawOutlinedRect(X,Y,surface.GetTextWidth(22,"Back")+YS(8),surface.GetFontTall(22)+YS(4),YS(2))
		
		local FrameX=XRE(0)
		local FrameY=YRE(0)
		local FrameHeight=YS(500)	// REMINDER. phone dimensions is 500x300
		local FrameWide=XS(300)
		
		local brdr=YS(12)
		
		local MainWide=FrameWide-YS(2)*2
		
		surface.SetColor(0,133,229,255)
		
		surface.SetColor(65,193,255,255)
		surface.DrawOutlinedRect(X+YS(20),Y-brdr,MainWide-brdr*2-YS(40),surface.GetFontTall(81)+brdr*2,YS(2))
		surface.SetColor(0,133,229,255)
		surface.DrawOutlinedRect(X+YS(4)+YS(20),Y-brdr+YS(4),MainWide-brdr*2-YS(8)-YS(40),surface.GetFontTall(81)+brdr*2-YS(8),YS(2))
		
		surface.DrawColoredText(PhoneBoldFont,X+MainWide/2-surface.GetTextWidth(PhoneBoldFont,"SEND SPOT DATA")/2-brdr,Y+YS(2),85,223,255,255,"SEND SPOT DATA")
	}
	B.OnPress=function(){surface.PlaySound("phone/send_data.wav");PortalSpots.remove(PortalID);PhoneButtons[7].Active=false}.bindenv(this)
	
	local cursor=(-1);
	
	function PhonePaint()
	{
		local cyc=clamp(((Time()-PhoneTime)*50),0,21)
		
		if (PhoneClosing) cyc=21-cyc;
		
		if (cyc<=0&&PhoneClosing)
		{
			PhonePanel.Destroy()
			PhonePanel=null;
			
			PhoneClosing=false;
			NetMsg.Start("ClosePhone");
			NetMsg.Send();
			return;
		}
		
		Convars.SetInt("spec_freeze_distance_min",cyc)
		
		local MailTexture=surface.ValidateTexture("vgui/terminal/mail", true, false, false)
		
		surface.SetColor(205,205,205,255)
		
		local vecbob=Vector(0,0,0)
		
		surface.SetTexture(surface.ValidateTexture(cyc==21 ? "vgui/phone/phone" : "vgui/phone/phone_draw",true,false,false))
		
		local SWidth=XRE(300)-XRE(0)+1
		local SHeight=YRE(500)-YRE(0)+1
		
		surface.DrawTexturedRect(ScreenWidth()-size-YRES(70)+vecbob.x,ScreenHeight()-size+vecbob.y+YRES(1),size,size)
		
		if (cyc<21) return;
		
		if (PhoneScreen=="Home")
		{
			surface.SetColor(255,255,255,255)
			surface.SetTexture(surface.ValidateTexture("vgui/phone/wallpaper1",true,false,false))
			surface.DrawTexturedRect(XRE(0),YRE(0),SHeight,SHeight)
			
			local timetext=date().hour+":"+format("%02i",date().min)
			
			local TimeFont=24
			
			surface.DrawColoredText(TimeFont,XRE(150)-surface.GetTextWidth(TimeFont,timetext)/2,YRE(30),255,255,255,255,timetext)
			
			surface.DrawColoredText(TimeFont-2,XRE(150)-surface.GetTextWidth(TimeFont-2,DayName(date().wday)+", "+date().day+" "+MonthName(date().month))/2,YRE(110),255,255,255,255,DayName(date().wday)+", "+date().day+" "+MonthName(date().month))
		}
		if (PhoneScreen=="Contacts")
		{
			surface.SetColor(55,55,55,255)
			surface.SetTexture(surface.ValidateTexture("vgui/phone/wallpaper1",true,false,false))
			surface.DrawTexturedRect(XRE(0),YRE(0),SHeight,SHeight)
			surface.DrawColoredText(96,XRE(3),YRE(3),255,255,255,2,"CONTACTS")
			surface.DrawColoredText(96,XRE(5),YRE(3),255,255,255,2,"CONTACTS")
			
			local FrameX=XRE(20)
			local FrameY=YRE(60)
			local FrameHeight=YS(400)
			local FrameWide=XS(260)
			
			surface.SetColor(0,0,0,155)
			surface.DrawFilledRect(FrameX,FrameY,FrameWide,FrameHeight)
			surface.SetColor(0,74,127,255)
			surface.DrawOutlinedRect(FrameX,FrameY,FrameWide,FrameHeight,YS(2))
			surface.SetColor(0,133,229,255)
			surface.DrawOutlinedRect(FrameX+YS(2),FrameY+YS(2),FrameWide-YS(2)*2,FrameHeight-YS(2)*2,YS(2))
		}
		if (PhoneScreen=="Portal")
		{
			surface.SetColor(25,25,25,255)
			surface.SetTexture(surface.ValidateTexture("vgui/phone/wallpaper1",true,false,false))
			surface.DrawTexturedRect(XRE(0),YRE(0),SHeight,SHeight)
			//surface.DrawColoredText(96,XRE(3),YRE(3),255,255,255,2,"PORTAL")
			//surface.DrawColoredText(96,XRE(5),YRE(3),255,255,255,2,"PORTAL")
			
			local FrameX=XRE(0)
			local FrameY=YRE(0)
			local FrameHeight=YS(500)	// REMINDER. phone dimensions is 500x300
			local FrameWide=XS(300)
			
			local brdr=YS(12)
			
			local MainWide=FrameWide-YS(2)*2
			
			local TitleHeight=YS(90)
			local TitleTextX=FrameX+YS(2)+brdr+XS(15)
			local TitleTextY=FrameY+YS(2)+TitleHeight/2-surface.GetFontTall(81)/2
			
			surface.SetColor(0,133,229,255)
			surface.DrawOutlinedRect(FrameX+YS(2)+brdr,FrameY+YS(2)+brdr,FrameWide-YS(2)*2-brdr*2,TitleHeight-YS(2)*2-brdr*2,YS(2))
			surface.SetColor(0,133*0.7,229*0.7,255)
			surface.DrawOutlinedRect(FrameX+YS(2)*3+brdr,FrameY+YS(2)*3+brdr,FrameWide-YS(2)*6-brdr*2,TitleHeight-YS(2)*6-brdr*2,YS(2))
			
			surface.SetColor(0,133,229,255)
			
			local timetext=date().hour+":"+format("%02i",date().min)
			
			local TimeFont=PhoneRegFont
			
			surface.DrawColoredText(PhoneRegFont,TitleTextX,TitleTextY,25,155,255,255,"PORTAL")
			surface.DrawColoredText(PhoneRegFont,FrameX+FrameWide-(YS(2)+brdr+XS(15))-surface.GetTextWidth(PhoneRegFont,timetext),TitleTextY,255,255,255,255,timetext)
			
			
			surface.DrawOutlinedRect(FrameX+YS(2)+brdr,FrameY+YS(82)+brdr,MainWide-brdr*2,MainWide*0.75-brdr*2,YS(2))
			
			if (AllPortalSpots[0]!=null)
			{
				foreach (i,Spot in AllPortalSpots)
				{
					if (i==3) break;
					
					surface.DrawColoredText(PhoneRegFont,TitleTextX,FrameY+MainWide+YS(4)+(YS(4)+surface.GetFontTall(PhoneRegFont))*i,25,155,255,255,"SPOT "+(i+1)+" :")
					if (PortalSpots.find(Spot)!=null) 
						surface.DrawColoredText(PhoneRegFont,TitleTextX+surface.GetTextWidth(PhoneRegFont,"SPOT "+(i+1)+" : "),FrameY+MainWide+YS(4)+(YS(4)+surface.GetFontTall(PhoneRegFont))*i,45,45,45,255,"NOT FOUND")
					else
						surface.DrawColoredText(PhoneRegFont,TitleTextX+surface.GetTextWidth(PhoneRegFont,"SPOT "+(i+1)+" : "),FrameY+MainWide+YS(4)+(YS(4)+surface.GetFontTall(PhoneRegFont))*i,45,255,45,255,"SENT")
				}
				surface.DrawColoredText(PhoneRegFont,TitleTextX,FrameY+MainWide+YS(4)+(YS(4)+surface.GetFontTall(PhoneRegFont))*3,25,155,255,255,"PORTAL :")
				
				if (PortalAnimTime!=0&&Time()-PortalAnimTime>15)  surface.DrawColoredText(PhoneRegFont,TitleTextX+surface.GetTextWidth(PhoneRegFont,"PORTAL : "),FrameY+MainWide+YS(4)+(YS(4)+surface.GetFontTall(PhoneRegFont))*3,45,255,45,255,"READY")
				else if (PortalAnimTime!=0&&Time()-PortalAnimTime>10)  surface.DrawColoredText(PhoneRegFont,TitleTextX+surface.GetTextWidth(PhoneRegFont,"PORTAL : "),FrameY+MainWide+YS(4)+(YS(4)+surface.GetFontTall(PhoneRegFont))*3,255,255,45,255,"OPENING")
				else  surface.DrawColoredText(PhoneRegFont,TitleTextX+surface.GetTextWidth(PhoneRegFont,"PORTAL : "),FrameY+MainWide+YS(4)+(YS(4)+surface.GetFontTall(PhoneRegFont))*3,45,45,45,255,"NONE")
				
				PortalID=0;
				
				if (PortalSpots.len()>0)
				{
					local pleer=Vector(MainViewOrigin().x,-MainViewOrigin().y,MainViewOrigin().z)
					
					local ClosestPos=Vector(PortalSpots[PortalID].x,PortalSpots[PortalID].y,PortalSpots[PortalID].z)
					if (PortalSpots.len()>1&&pleer.DistTo(PortalSpots[1])<pleer.DistTo(PortalSpots[PortalID])) PortalID=1;
					if (PortalSpots.len()>2&&pleer.DistTo(PortalSpots[2])<pleer.DistTo(PortalSpots[PortalID])) PortalID=2;
					ClosestPos=Vector(PortalSpots[PortalID].x,PortalSpots[PortalID].y,PortalSpots[PortalID].z)
					ClosestPos.y=-ClosestPos.y
					
					local Dist=MainViewOrigin().DistTo(ClosestPos)
					//Dist=format("%.1f Meters",Dist/40.0)
					
					local Focus=RemapValClamped(Dist,80,1200,100,0)
					
					//local DistText=format("Focus %i%%",Focus)
					
					//surface.DrawColoredText(22,XRE(150)-surface.GetTextWidth(22,"Nearest Portal Spot")/2,YRE(150),25,195,255,255,"Nearest Portal Spot")
					
					if ((Time()-LastPortalSound)>(1-Focus*0.008))
					{
						if (Focus<25) surface.PlaySound("phone/portallow.wav")
						else if (Focus<75) surface.PlaySound("phone/portalmid.wav")
						else if (Focus<100) surface.PlaySound("phone/portalhigh.wav")
						else surface.PlaySound("phone/portalfull.wav")
						LastPortalSound=Time()
						if (Focus==100) LastPortalSound=Time()+0.5
						if (Focus==100) PhoneButtons[7].Active=true
					}
					
					//if (Focus<100) surface.DrawColoredText(23,XRE(150)-surface.GetTextWidth(23,DistText)/2,YRE(175),25,195,255,255,DistText)
					//else surface.DrawColoredText(23,XRE(150)-surface.GetTextWidth(23,DistText)/2,YRE(175),75+10*sin(Time()*12),255,75+10*sin(Time()*12),150+105*fabs(sin(Time()*8)),DistText)
					
					local Dir=VectorAngles(ClosestPos-MainViewOrigin()).y-MainViewAngles().y
					
					local Error=Dist/100.0
					local Twitch=3*sin(Time()*15/sqrt(Error))*cos(Time()*47/sqrt(Error))+sin(Time()*83/sqrt(Error))
					if (Focus<75) Dir+=Twitch*Error;
					//printl(255-abs(Twitch*Error))
					local arrow=YS(70)
					if (Focus<75) surface.SetColor(25,195,255,255-fabs(Twitch*Dist))
					else surface.SetColor(25,195,255,255-fabs(Twitch))
					surface.SetTexture(surface.ValidateTexture("vgui/hud/icon_arrow_up",true,false,false))
					if (Focus<100) PhoneButtons[7].Active=false;
					if (Focus<100) surface.DrawColoredText(PhoneRegFont,TitleTextX,FrameY+MainWide*0.4+YS(4)+(YS(4)+surface.GetFontTall(PhoneRegFont))*3,25,155,255,255,"DIRECTION :");
					if (Focus<100&&(Time()-LastPortalSound)<0.2) 
					{
						surface.DrawTexturedRectRotated(TitleTextX+surface.GetTextWidth(PhoneRegFont,"DIRECTION :"+" "),YRE(190),arrow,arrow,Dir)
					}
					surface.DrawColoredText(PhoneRegFont,TitleTextX,FrameY+MainWide*0.1+YS(4)+(YS(4)+surface.GetFontTall(PhoneRegFont))*3,25,155,255,255,"SIGNAL :")
						
					surface.SetColor(0,133,229,255)
					surface.DrawOutlinedRect(TitleTextX+surface.GetTextWidth(PhoneRegFont,"SIGNAL :"+" "),FrameY+MainWide*0.1+YS(4)+(YS(4)+surface.GetFontTall(PhoneRegFont))*3,brdr*10,surface.GetFontTall(PhoneRegFont),YS(2))
					surface.SetColor(0,3+Focus,155+Focus,255)
					if (Focus==100) surface.SetColor(25,255-100*fabs(cos(Time()*6)),25,255)
					surface.DrawFilledRect(TitleTextX+surface.GetTextWidth(PhoneRegFont,"SIGNAL :"+" ")+YS(4),FrameY+MainWide*0.1+YS(4)+(YS(4)+surface.GetFontTall(PhoneRegFont))*3+YS(4),Focus*0.01*(brdr*10-YS(8))-YS(RandomFloat(0,Focus==100 ? 0 : 3)),surface.GetFontTall(PhoneRegFont)-YS(8))
				}
				
				else
				{
					if (PortalAnimTime==0) 
					{
						surface.PlaySound("phone/triangle.wav")
						PortalAnimTime=Time()
						
						PortalOpen=true
						NetMsg.Start("OpenExitPortal")
						NetMsg.Send()
					}
					
					local SPortals=[Vector(AllPortalSpots[0].x,AllPortalSpots[0].y),Vector(AllPortalSpots[1].x,AllPortalSpots[1].y),Vector(AllPortalSpots[2].x,AllPortalSpots[2].y),Vector(AllPortalSpots[3].x,AllPortalSpots[3].y)];
				
					local Centroid=(SPortals[0]*0.333+SPortals[1]*0.333+SPortals[2]*0.333);
					
					local maxdist=999999
					for(local i=0;i<3;i++)
					{
						SPortals[i].z=0;
						
						if (maxdist>SPortals[i].DistTo(Centroid)) maxdist=SPortals[i].DistTo(Centroid)
						SPortals[i]=SPortals[i]-Centroid
					}
					
					SPortals[3]=SPortals[3]-Centroid
					
					for(local i=0;i<4;i++)
					{
						SPortals[i].x/=maxdist
						SPortals[i].y/=maxdist
					}
					
					for(local i=0;i<3;i++)
					{
						if (Time()-PortalAnimTime<i+1) continue;
						
						local radius=MainWide*0.25
						
						local x=FrameX+YS(2)+brdr+radius*SPortals[i].x+MainWide*0.5
						local y=FrameY+YS(50)+MainWide*0.4+brdr+radius*SPortals[i].y
						
						local flash=clamp(1-sqrt((Time()-PortalAnimTime)-(i+1)),0,1)
						surface.SetColor(25,255,25,255*flash)
						surface.DrawOutlinedCircle(x,y,YS(20)*(1-flash),32)
						
						
						surface.SetColor(25,220,25,255)
						surface.DrawOutlinedCircle(x,y,YS(2),32)
						surface.DrawOutlinedCircle(x,y,YS(1),32)
						

						
						local nextid=i+1;
						if (nextid==3) nextid=0;
						
						
						
						local dif_center=Vector(x-(FrameX+YS(2)+brdr+radius*SPortals[3].x+MainWide*0.5),y-(FrameY+YS(50)+MainWide*0.4+brdr+radius*SPortals[3].y))
						local dif=Vector(x-(FrameX+YS(2)+brdr+radius*SPortals[nextid].x+MainWide*0.5),y-(FrameY+YS(50)+MainWide*0.4+brdr+radius*SPortals[nextid].y))
						
						
						local prog=clamp(Time()-PortalAnimTime-(i*1.2+1+3),0,1.2)/1.2
						local prog_c=clamp(Time()-PortalAnimTime-(3.6+1+3),0,2.4)/2.4
						
						DrawDashLine(x,y,x-dif.x*prog,y-dif.y*prog)
						
						surface.SetColor(75,160,255,255)
						surface.DrawLine(x,y,x-dif_center.x*prog_c,y-dif_center.y*prog_c)
						
						if (Time()-PortalAnimTime>10&&Time()-PortalAnimTime<11)
						{
							local shrink=sqrt(1-clamp((Time()-PortalAnimTime-10),0,1))
							
							surface.SetColor(85,205,125,25*shrink)
							surface.DrawFilledRect(FrameX+YS(2)+brdr,FrameY+YS(82)+brdr,MainWide-brdr*2,MainWide*0.75-brdr*2)
						}
						
						if (Time()-PortalAnimTime>10.5&&Time()-PortalAnimTime<15)
						{
							local shrink=sqrt(1-clamp((Time()-PortalAnimTime-13.3),0.2,1))
							
							surface.SetColor(85,255,85,255)
							surface.DrawOutlinedCircle(x-dif_center.x,y-dif_center.y,shrink*YS(RandomFloat(0,(Time()-PortalAnimTime-10.5)*10))*2,6)
							surface.DrawOutlinedCircle(x-dif_center.x,y-dif_center.y,shrink*YS(RandomFloat(0,(Time()-PortalAnimTime-10.5)*10))*2,RandomInt(2,10))
						}
						
						if (Time()-PortalAnimTime>15)
						{
							
							surface.SetColor(233,255,235,255)
							surface.DrawOutlinedCircle(x-dif_center.x,y-dif_center.y,YS(1)*2,6)
							surface.DrawOutlinedCircle(x-dif_center.x,y-dif_center.y,YS(2)*2,6)
							surface.SetColor(50,175,255,255)
							surface.DrawOutlinedCircle(x-dif_center.x,y-dif_center.y,YS(3)*2,6)
							surface.DrawOutlinedCircle(x-dif_center.x,y-dif_center.y,YS(4)*2,6)
							surface.DrawOutlinedCircle(x-dif_center.x,y-dif_center.y,YS(5)*2,6)
							surface.SetColor(85,255,85,255)
							surface.DrawOutlinedCircle(x-dif_center.x,y-dif_center.y,YS(6)*2,6)
							surface.DrawOutlinedCircle(x-dif_center.x,y-dif_center.y,YS(7)*2,6)
						}
					}
				}
			}
			else
			{
				surface.DrawColoredText(PhoneRegFont,XRE(150)-surface.GetTextWidth(PhoneRegFont,"Unavailable")/2,FrameY+YS(82)+MainWide*0.4-surface.GetFontTall(PhoneRegFont)/2,255,35,35,255,"Unavailable")
			}
		}
		if (PhoneScreen=="Messages")
		{
			surface.SetColor(55,55,55,255)
			surface.SetTexture(surface.ValidateTexture("vgui/phone/wallpaper1",true,false,false))
			surface.DrawTexturedRect(XRE(0),YRE(0),SHeight,SHeight)
			surface.DrawColoredText(96,XRE(3),YRE(3),255,255,255,2,"MESSAGES")
			surface.DrawColoredText(96,XRE(5),YRE(3),255,255,255,2,"MESSAGES")
			
			
			foreach (Name in SW_MAILS_LIST)
			{
				local Msg=SW_MAILS[Name]
				if (Msg.Status==0) continue;	//skip mails with status NONE
				local MailName=Name
				local i=SW_MAILS_LIST.find(MailName)+1
				
				local MailButton=null
				
				foreach (B in PhoneButtons)
				{
					if ((B instanceof PhoneMail)&&B.Name==MailName)
					{
						MailButton=B;
						break;
					}
				}
				
				if (!MailButton)
				{
					//printl("created "+MailName)
					//TextLinks.rawset(MailName,TextLink(PCFontSmall,XC+XC+MailGap,YC*3.5+YC*3/2.0-surface.GetFontTall(PCFontSmall)/2.0, 119, 255, 110, 255, Msg.Title))
					
					local B = PhoneMail(MailName,XRE(30),YRE(30)+YS(25)*i)
					B.Title=Msg.Title
					B.Msg=SW_MAILS[Name]
					B.Text=Msg.TextInLines=GetTextInLines(33,XS(280),SW_MAILS[MailName].Text,1024)
					B.Active=true
					B.OnPress=function(){OpenedMail=this.Msg;this.Msg.ReadMail();SwitchScreen("Mail");surface.PlaySound("phone/deck_ui_navigation.wav");}
					
					//B.OnPress=function(){SwitchScreen("Contacts");surface.PlaySound("phone/deck_ui_navigation.wav");}
					/*
					if (SW_MAILS[MailName].Status==2)
					{
						TextLinks[MailName].Color=[180,180,180,255]
						TextLinks[MailName].ColorHover=[205,205,205,255]
					}
					TextLinks[MailName].PressAction=function()
					{
						printl(MailName)
						printl(SW_MAILS[MailName].Title)
						SW_MAILS[MailName].ReadMail()
						OpenedMail=MailName
						OpenMailTime=Time()
						TextLinks[MailName].Color=[180,180,180,255]
						TextLinks[MailName].ColorHover=[205,205,205,255]
						SW_MAILS[MailName].TextInLines=GetTextInLines(PCFontVerySmall,XC*27,SW_MAILS[MailName].Text,1024)
					}.bindenv(this)
					*/
				}
				//TextLinks[MailName].y = YC*i*3.5+YC*3/2.0-surface.GetFontTall(PCFontSmall)/2.0
			
				// This is the spot where i was obliterated by my OCD because some icon kept getting 1-2 pixels offset compared to the other one.
				// And the texture wasn't even at fault here, because the shift was so small that the texture's 64x64 size wasn't enough for image adjustments to fix this crap.
				// So I just use a 0.51 offset instead of logical 0.5 meaning that unread icon actually starts at 51% of original texture's X axis. Or something along those lines.
				// Result is plausible
				
				//surface.SetColor(30, 230, 30, 255)
				//DrawOutlinedBox( Brdr, XC+XC,YC*i*3.5,XC*32,YC*3, 0,false );
				//TextLinks[MailName].Draw()
				
			}
		}
		if (PhoneScreen=="Mail")
		{
			surface.SetColor(55,55,55,255)
			surface.SetTexture(surface.ValidateTexture("vgui/phone/wallpaper1",true,false,false))
			surface.DrawTexturedRect(XRE(0),YRE(0),SHeight,SHeight)
			//surface.DrawColoredText(96,XRE(3),YRE(3),255,255,255,2,"MESSAGES")
			//surface.DrawColoredText(96,XRE(5),YRE(3),255,255,255,2,"MESSAGES")
			
			//DrawOutlinedBoxTitle(Brdr*2,XC*36,YC,XC*30,YC*43,SW_MAILS[OpenedMail].Title)
			surface.DrawColoredText(95,XRE(5),YRE(3),255,255,255,2,OpenedMail.Title)
			
			//surface.SetColor(30, 230, 30, 35)
			//surface.DrawFilledRect(x,y+YC*8.5,XC*28,YC*0.2)
			
			local text = format("From: %s",OpenedMail.Sender)
			
			local x=XRE(10)
			local y=YRE(30)
			
			local font=33
			
			surface.DrawColoredText(font, x, y, 180, 215, 180, 255, text.slice(0,text.find(": ")+2))
			surface.DrawColoredText(font, x+surface.GetTextWidth(font,text.slice(0,text.find(": ")+2)), y+(surface.GetFontTall(font)-surface.GetFontTall(font))+1, 119, 255, 110, 255, text.slice(text.find(": ")+2))
			
			
			text = "To: Jack Lunin"
			y+=surface.GetFontTall(font)
			
			surface.DrawColoredText(font, x, y, 180, 215, 180, 255, text.slice(0,text.find(": ")+2))
			surface.DrawColoredText(font, x+surface.GetTextWidth(font,text.slice(0,text.find(": ")+2)), y+(surface.GetFontTall(font)-surface.GetFontTall(font))+1, 119, 255, 110, 255, text.slice(text.find(": ")+2))
			
			local MailDate=OpenedMail.DateReceived
			
			text = format("Date: %s",DayName(MailDate.wday)+", "+MailDate.day+" "+MonthName(MailDate.month)+" 2074 "+format("%.2i:%.2i",MailDate.hour,MailDate.min))
			y+=surface.GetFontTall(font)
			
			surface.DrawColoredText(font, x, y, 180, 215, 180, 255, text.slice(0,text.find(": ")+2))
			surface.DrawColoredText(font, x+surface.GetTextWidth(font,text.slice(0,text.find(": ")+2)), y+(surface.GetFontTall(font)-surface.GetFontTall(font))+1, 119, 255, 110, 255, text.slice(text.find(": ")+2))
			
			text = format("Subject: %s",OpenedMail.Title)
			y+=surface.GetFontTall(font)
			
			surface.DrawColoredText(font, x, y, 180, 215, 180, 255, text.slice(0,text.find(": ")+2))
			surface.DrawColoredText(font, x+surface.GetTextWidth(font,text.slice(0,text.find(": ")+2)), y+(surface.GetFontTall(font)-surface.GetFontTall(font))+1, 119, 255, 110, 255, text.slice(text.find(": ")+2))
			
			foreach (i,Line in OpenedMail.TextInLines)
			surface.DrawColoredText(font, x, y+YS(35)+i*surface.GetFontTall(font)*1.25, 199, 255, 199, 255, Line)
		}
		
		local IconSize=YRE(70)-YRE(0)
		
		foreach (Button in PhoneButtons)
		{
			if (Button.Active)
			{
				if (cursor==Button.ID) Button.PaintSelected();
				else Button.Paint();
			}
		}
		
		if (Calling)
		{
			surface.SetColor(25,25,25,255)
			surface.DrawFilledRect(XRE(10),YRE(150),XS(280),YS(200))
			
			surface.SetColor(255,95,95,255)
			surface.DrawOutlinedRect(XRE(10),YRE(150),XS(280),YS(200),YS(5))
			
			local dots=""
			if ((Time()%1.0)>0.25) dots=dots+"."
			if ((Time()%1.0)>0.5) dots=dots+"."
			if ((Time()%1.0)>0.75) dots=dots+"."
			
			surface.DrawColoredText(23,XRE(150)-surface.GetTextWidth(23,"Calling.")/2,YRE(250)-surface.GetFontTall(22),255,95,95,255,"Calling"+dots)
			
			if (Time()>CallTime)
			{
				CallAction()
				Calling=false;
			}
		}
		
		if (player.GetHealth()<20)
		{
			surface.SetColor(255,255,255,255)
			surface.SetTexture(surface.ValidateTexture("vgui/phone/crack",true,false,false))
			surface.DrawTexturedRect(XRE(0),YRE(0),SHeight,SHeight)
		}
		
	}
	
	function PhonePress(a)
	{
		if (Calling) return; //can't put away phone midcall
		
		
		if (a==input.StringToButtonCode(input.LookupBinding("phone"))) 
		{
			PhoneMenu();
			return
		}

		if (cursor==-1||PhoneButtons[cursor].Active==false)
		{
			for (local i=0;i<PhoneButtons.len();i++)
			if (PhoneButtons[i].Active) 
			{
				cursor=PhoneButtons[i].ID;
				surface.PlaySound("phone/deck_ui_typing.wav");
				return
			}
			// Select first active button if nothing was selected beforehand
		}
		
		local CurButton=PhoneButtons[cursor]
		
		local StartX=CurButton.X
		local StartY=CurButton.Y
		
		local Target=cursor
		local Dist=10000
			
		if (a==ButtonCode.KEY_W)
		{
			foreach (b in PhoneButtons)
			if (b.Active&&b.ID!=cursor)
			{
				if (b.Y<StartY&&(fabs(StartX-b.X)+fabs(StartY-b.Y)*0.1)<Dist)
				{
					Target=b.ID
					Dist=(fabs(StartX-b.X)+fabs(StartY-b.Y)*0.1)
				}
			}
			if (cursor!=Target) surface.PlaySound("phone/deck_ui_typing.wav");
			cursor=Target
			return;
		}
		
		if (a==ButtonCode.KEY_S)
		{
			foreach (b in PhoneButtons)
			if (b.Active&&b.ID!=cursor)
			{
				if (b.Y>StartY&&(fabs(StartX-b.X)+fabs(StartY-b.Y)*0.1)<Dist)
				{
					Target=b.ID
					Dist=(fabs(StartX-b.X)+fabs(StartY-b.Y)*0.1)
				}
			}
			if (cursor!=Target) surface.PlaySound("phone/deck_ui_typing.wav");
			cursor=Target
			return;
		}
		
		if (a==ButtonCode.KEY_D)
		{
			foreach (b in PhoneButtons)
			if (b.Active&&b.ID!=cursor)
			{
				if (b.X>StartX&&(fabs(StartX-b.X)*0.1+fabs(StartY-b.Y))<Dist)
				{
					Target=b.ID
					Dist=(fabs(StartX-b.X)*0.1+fabs(StartY-b.Y))
				}
			}
			if (cursor!=Target) surface.PlaySound("phone/deck_ui_typing.wav");
			cursor=Target
			return;
		}
		
		if (a==ButtonCode.KEY_A)
		{
			foreach (b in PhoneButtons)
			if (b.Active&&b.ID!=cursor)
			{
				if (b.X<StartX&&(fabs(StartX-b.X)*0.1+fabs(StartY-b.Y))<Dist)
				{
					Target=b.ID
					Dist=(fabs(StartX-b.X)*0.1+fabs(StartY-b.Y))
				}
			}
			if (cursor!=Target) surface.PlaySound("phone/deck_ui_typing.wav");
			cursor=Target
			return;
		}
			
		if (a==ButtonCode.KEY_E)
		{
			CurButton.OnPress()
		}
	}
	
	function PhoneMenu()
	{
		if (Time()-PhoneTime<0.5) return;
		
		if (!PhonePanel||(!PhonePanel.IsValid())&&!PhoneClosing)
		{
			PhonePanel = vgui.CreatePanel("Panel", vgui.GetClientDLLRootPanel(), "PhoneScreen")
			PhonePanel.SetCursor(CursorCode.dc_blank)
			PhonePanel.MakeReadyForUse()
			PhonePanel.SetVisible(true)
			PhonePanel.SetPos(XRES(0), YRES(0))
			PhonePanel.SetSize(XRES(640),YRES(480))
			PhonePanel.SetPaintEnabled(true)
			//PhonePanel.SetKeyBoardInputEnabled(false)
			PhonePanel.SetCallback( "Paint", PhonePaint.bindenv(this) );
			PhonePanel.SetCallback( "OnKeyCodePressed", PhonePress.bindenv(this) );
			PhonePanel.MakePopup()
			PhoneTime=Time();
			PhoneClosing=false;
			surface.PlaySound("phone/deck_ui_switch_toggle_on.wav")
			
		}
		else
		{
			//PhonePanel.Destroy()
			//PhonePanel=null;
			
			//NetMsg.Start("ClosePhone");
			//NetMsg.Send();
			
			surface.PlaySound("phone/deck_ui_switch_toggle_off.wav")
			
			PhoneTime=Time()
			PhoneClosing=true
		}
	}
	
	NetMsg.Receive("PortalSpot", function() {
		local i=NetMsg.ReadByte()
		AllPortalSpots[i]=NetMsg.ReadVec3Coord()
		if (i!=3) {PortalSpots=clone AllPortalSpots;PortalSpots.remove(3)}
	}.bindenv(this))
	
}





if (SERVER_DLL)
{
	::SW_PHONE_OPEN<-false;
	
	function PhoneMenu()
	{
		if (!player.IsAlive()) return;
	
		if (!SW_PHONE_OPEN)
		{
			SendToConsole("temp_holster")
			NetMsg.Start("OpenPhone");
			NetMsg.Send(player, true);
			SW_PHONE_OPEN=true
		}
		else
		{
			SendToConsole("lastinv")
			NetMsg.Start("OpenPhone");
			NetMsg.Send(player, true);
			SW_PHONE_OPEN=false
		}
	}
	
	NetMsg.Receive("ClosePhone", function(player) {
		SendToConsole("lastinv")
		SW_PHONE_OPEN=false
	}.bindenv(this))
	
	Convars.RegisterCommand( "phone", function(_)
	{
		PhoneMenu()
	}.bindenv(this), "", FCVAR_CLIENTDLL );
}