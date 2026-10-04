
if ( IsClient() )
{
	IncludeScript("utils/text.nut")
	
	printl("dialog client init")
	Dialogue_MainP <- null;
	local sizex=YRES(256)
	local Text=""
	local TextToDisplay=""
	
	Dialogue_Name <- null;
	
	Dialogue_Data <- null;
	Text_Data <- null;
	Choices <- null;
	CharNames <- null;
	Contexts<- null;
	Actions<- null;
	
	CutsceneMode <- false;
	
	function CreatePlayerNPC()
	{
		NetMsg.Start("CreatePlayerNPC")
		NetMsg.Send()
	}
	
	function SwitchCamera(actor,actor2)
	{
		if (!actor) return;
		NetMsg.Start("SwitchCamera")
		NetMsg.WriteEntity(actor)
		NetMsg.WriteString(actor2)
		NetMsg.Send()
	}
	function SwitchCameraSimple()
	{
		NetMsg.Start("SwitchCameraSimple")
		NetMsg.Send()
	}
	function SwitchCameraType(type)
	{
		NetMsg.Start("SwitchCameraType")
		NetMsg.WriteString(type)
		NetMsg.Send()
	}
	
	function RunActionOnServer(id)
	{
		NetMsg.Start("ActionFromDialogue")
		NetMsg.WriteShort(id)
		NetMsg.Send()
	}
	
	function PlayDialogue(name)
	{
		Text=""
		TextToDisplay=""
		
		Dialogue_Name=name;
		
		CutsceneMode=false;
	
		Dialogue_Data = FileToKeyValues( "dialogue/"+name+".txt" );
		
		if (name.find("c_")==0) CutsceneMode=true;
		
		Text_Data = Dialogue_Data.FindOrCreateKey("Text");
		Choices = Dialogue_Data.FindOrCreateKey("Choices");
		CharNames = Dialogue_Data.FindOrCreateKey("Actors");
		
		Actions={};
		
		local KVActions=null;
		if (CutsceneMode) KVActions = Dialogue_Data.FindOrCreateKey("Actions");
		if (CutsceneMode) KVActions.SubKeysToTable(Actions);
		
	
		TextToDisplay=Text_Data.GetKeyString("1");
		//CreatePlayerNPC()
		DialogueRNG<-[RandomInt(0,100),RandomInt(0,100),RandomInt(0,100),RandomInt(0,100)]
		
		// We store player health in this variable at dialogue start.
		// because getting player health directly mid-dialogue is not reliable because there can be regen status effect active or bleeding.
		JackHealth<-player.GetHealth()
	}
	
	function PlayGesture(actor,gesture)
	{
		if (!actor) return;
		NetMsg.Start("Gesture")
		NetMsg.WriteEntity(actor)
		NetMsg.WriteString(gesture)
		NetMsg.Send()
	}
	
	function SetExpression(actor,exp)
	{
		if (!actor) return;
		NetMsg.Start("DialogueExpression")
		NetMsg.WriteEntity(actor)
		NetMsg.WriteString(exp)
		NetMsg.Send()
	}

	function SetLookTarget(actor,actor2="PlayerModel")
	{
		if (!actor) return;
		NetMsg.Start("SetLookTarget")
		NetMsg.WriteEntity(actor)
		NetMsg.WriteString(actor2)
		NetMsg.Send()
		printl(actor+"looks at"+Entities.FindByName(null,actor2))
	}
	
	function SaySound(actor,sound)
	{
		if (!actor) return;
		NetMsg.Start("SaySound")
		NetMsg.WriteEntity(actor)
		NetMsg.WriteString(sound)
		NetMsg.Send()
	}
	
	local LastLSTime=0
	function Speak(actor)
	{
		if ((LastLSTime+2)>Time()) return;
		if (!actor) return;
		NetMsg.Start("Speak")
		NetMsg.WriteEntity(actor)
		NetMsg.Send()
		LastLSTime=Time()
	}
	
	function StopSpeak(actor)
	{
		if (!actor) return;
		NetMsg.Start("StopSpeak")
		NetMsg.WriteEntity(actor)
		LastLSTime=Time()-3
		NetMsg.Send()
	}
	function TagFind()
	{
		if (!Text.find("<")) return null
		return TextToDisplay.slice(Text.find("<")+1,TextToDisplay.find(">"))
	}
	function TagParser(command)
	{
		if (Text.len()==TextToDisplay.find("<"+command+":")) 
		{
			local parameter=TextToDisplay.slice(Text.len()+2+command.len(),TextToDisplay.find(">"));
			return parameter
		}
		if (Text.len()==TextToDisplay.find("<"+command)) 
		{
			local parameter=TextToDisplay.slice(Text.len()+1+command.len(),TextToDisplay.find(">"));
			return 1
		}
		else return null;
	}
	
	function TagClean()
	{
		TextToDisplay=TextToDisplay.slice(0,Text.len())+TextToDisplay.slice(TextToDisplay.find(">")+1);
	}
	
	function TagCleanAll()
	{
		while(TextToDisplay.find(">")!= null)
		{
			TextToDisplay=TextToDisplay.slice(0,TextToDisplay.find("<"))+TextToDisplay.slice(TextToDisplay.find(">")+1);
		}
	}
	
	function GetTaglessText(TextToClean=TextToDisplay)
	{
		while(TextToClean.find(">")!= null)
		{
			TextToClean=TextToClean.slice(0,TextToClean.find("<"))+TextToClean.slice(TextToClean.find(">")+1);
		}
		return TextToClean
	}
	
	function DisplayPanels()
	{
		if ( Dialogue_MainP && Dialogue_MainP.IsValid() )
			return;
		
		Dialogue_MainP = vgui.CreatePanel( "Panel", vgui.GetClientDLLRootPanel(), "DialoguePanel2" );
		Dialogue_MainP.MakeReadyForUse();
		Dialogue_MainP.SetPaintBackgroundType( 2 );
		Dialogue_MainP.SetBgColor( 0, 0, 0, 0 );
		Dialogue_MainP.SetPos( 0,0 );
		Dialogue_MainP.SetSize( ScreenWidth(), ScreenHeight() );
		Dialogue_MainP.SetCallback( "Paint", Draw.bindenv(this) );
		Dialogue_MainP.SetCallback( "OnKeyCodePressed", KeyPress.bindenv(this) );
		Dialogue_MainP.SetZPos(50)
		Dialogue_MainP.MakePopup();
		Dialogue_MainP.SetMouseInputEnabled(false);

		surface.CreateFont( "examplefont",
		{
			name			= "Arial Black",
			tall			= 14,
			weight			= 500,
			antialias		= true,
			proportional	= false
		} );
		
		//SetHudElementVisible("CHudFlashlight",false)
		//SetHudElementVisible("CHudHealth",false)
		//SetHudElementVisible("CHudAmmo",false)
		//SetHudElementVisible("CHudBattery",false)
		//SetHudElementVisible("CHudSuitPower",false)
	}
	
	local actor=""
	local actorname=""
	local i=1
	local CleanText=false
	local ActorName_Localized=""
	local ChoiceTable=[]
	local Selection=-1
	
	local CloseDialogue=false;
	
	Interval<-0.03
	NextLineDelay<-2
	StopDialogue<-false
	ChoiceActive<-false
	LastChoiceActive<-false
	ChoiceTime<-0
	Auto<-false
	
	function ProcessTag(actor)
	{
			if (TagParser("skip")!=null) 
			{
				TagClean()
				return 0.03
				
				
				printl("SKIP TAG")
				i++;
				NextLineDelay=0
				TextToDisplay="";
				CleanText=true;
				StopSpeak(actor);
				return 0.03
			}
			if (TagParser("pause")!=null) 
			{
				StopSpeak(actor);
				local pause = TagParser("pause")
				TagClean()
				return pause.tofloat()/4
			}
			if (TagParser("fade")!=null) 
			{
				NetMsg.Start("FadeFromDialogue")
				NetMsg.Send()
				TagClean()
				return 0
			}
			if (TagParser("entfire")!=null) 
			{
				NetMsg.Start("EntFireFromDialogue")
				NetMsg.WriteString(TagParser("entfire"))
				NetMsg.Send()
				TagClean()
				return 0
			}
			if (TagParser("choice")!=null) 
			{
				StopSpeak(actor);
				local choice = TagParser("choice")
				TagClean()
				ChoiceActive=true
				local ChoiceTempTable={}
				local ChoiceTempTableUnsorted={}
				Choices.FindOrCreateKey(choice).SubKeysToTable(ChoiceTempTable);
				foreach (id,choice in ChoiceTempTable) 
				{
					local ChoiceActor=Entities.FindByName(null,"dialogue_manager")
					//printl(ChoiceActor)
					if (id.find("&")!=null) if (Contexts.find(id.slice(id.find("&")+1))==null&&(id.slice(id.find("&")+1,id.find("&")+2)!="!"||Contexts.find(id.slice(id.find("&")+2)))) continue
					
					if (id.find("@")!=null) if (!(compilestring("return "+id.slice(id.find("@")+1)).call(this))) continue
					ChoiceTempTableUnsorted.rawset(id,choice);
				}
				for (local i=1;i<32;i++) 
				{
					foreach (id,choice in ChoiceTempTableUnsorted)
					{
						if (choice.slice(0,1)=="#") choice=Localize.GetTokenAsUTF8(choice.slice(1))
						
						if (id.find("&")!=null&&id.slice(0,id.find("&"))==i.tostring()) ChoiceTable.append(choice);
						else if (id.find("@")!=null&&id.slice(0,id.find("@"))==i.tostring()) ChoiceTable.append(choice);
						else if (id==i.tostring()) ChoiceTable.append(choice);
					}
				}
				//printl(ChoiceTable)
				//printl(ChoiceTable.len())
				return 0.03
			}
			if (TagParser("hudsound")!=null) 
			{
				surface.PlaySound(TagParser("hudsound")+".wav");
				TagClean()
				return 0.08
			}
			if (TagParser("sound")!=null) 
			{
				SaySound(actor,TagParser("sound"));
				TagClean()
				return 0.08
			}
			if (TagParser("stopdialogue")!=null) 
			{
				NetMsg.Start("ForceDialogueExit")
				NetMsg.Send()
				i=100
				return 0.08
			}
			if (TagParser("g")!=null) 
			{
				PlayGesture(actor,TagParser("g"));
				TagClean()
				return 0.08
			}
			if (TagParser("e")!=null) 
			{
				SetExpression(actor,TagParser("e"));
				TagClean()
				return 0.08
			}
			if (TagParser("lookat")!=null) 
			{
				local params=TagParser("lookat")
				
				if (params.find("|"))
				{
						local camtype=params.slice(params.find("|")+1)
						SwitchCameraType(camtype)
						params=params.slice(0,params.find("|"))
				}
				
				SwitchCamera(actor,params);
				SetLookTarget(actor,params);
				TagClean()
				return 0
			}
			
			if (TagParser("look")!=null) 
			{
				SetLookTarget(actor,TagParser("look"));
				TagClean()
				return 0
			}
			
			if (TagParser("camtype")!=null) 
			{
				SwitchCameraType(TagParser("camtype"));
				SwitchCameraSimple();
				TagClean()
				return 0
			}
		return null
	}
	
	// Text which is within ( ) should have different sound and we don't want lips moving.
	local ThoughtsMode=false
	
	local TalkSound=true;
	
	function ClientThink()
	{
		if (!Dialogue_MainP||(StopDialogue&&!Auto)||ChoiceActive) {return}
		local TextTable={}
		Text_Data.SubKeysToTable(TextTable)
		
		
		while (i<=TextTable.len()*2)
		{
			if (CutsceneMode&&("0" in Actions)&&Actions["0"].find("|")!=null)
			{
				local cmd=null
				
				local ID="0"
				cmd=Actions[ID].slice(0,Actions[ID].find("|"))
				while (cmd.find("@")) cmd=cmd.slice(0,cmd.find("@"))+"\""+cmd.slice(cmd.find("@")+1)
					
				compilestring(cmd).call(this)
				RunActionOnServer(ID.tointeger())
			
				// make delay at cutscene start for actions to work.
				local ActionZero=Actions["0"]
				Actions.rawdelete("0")
				
				return ActionZero.slice(ActionZero.find("|")+1).tofloat()
			}
			local Key=null;local TextLine=null
			
			local minnum=i+1;
			local nextminnum=i+1;
			
			
			local SearchContext=true
			while (SearchContext)
			{
				SearchContext=false
				foreach (k,t in TextTable) 
				{
					local context=null
					local condition=null
					
					local num=k.slice(k.find("_")+1)
					if (num.find("_")!=null) num=num.slice(num.find("_")+1)
					
					if (num.find("&")!=null) 
					{
						context=num.slice(num.find("&")+1)
						num=num.slice(0,num.find("&"))
					}
					if (context&&( (context.slice(0,1)=="!") ? (Contexts.find(context.slice(1))!=null) : (Contexts.find(context)==null)))
					{
						TextTable.rawdelete(k)
						SearchContext=true
						break
					}
					
					if (num.find("@")!=null) 
					{
						condition=num.slice(num.find("@")+1)
						num=num.slice(0,num.find("@"))
					}
					if (condition&&!(compilestring("return "+condition).call(this)))
					{
						//printl(context)
						TextTable.rawdelete(k)
						SearchContext=true
						break
					}
				}
			}
			
			// This is absolutely disgusting. The purpose of thing below is to make sure the next selected textline has id that goes right after previous one.
			// formerly it worked only with integers. Like changing from line 4 to line 5, but it didn't work with for example line 4.1.
			// Since i want to have context-based or just random textlines, i need to add support for float IDs so that lines 4 and 5 can have many extra random lines in between them.
			foreach (k,t in TextTable) 
			{
				local num=k.slice(k.find("_")+1)
			
				if (num.find("_")!=null) num=num.slice(num.find("_")+1)
				if ((num.tofloat()-i.tofloat())>1) continue;
				if (num.tofloat()<=i) continue;
				if (num.tofloat()<=minnum) {nextminnum=minnum;minnum=num.tofloat();}
			}
			
			foreach (k,t in TextTable) 
			{
				local num=k.slice(k.find("_")+1)
			
				if (num.find("_")!=null) num=num.slice(num.find("_")+1)
				if (num.tofloat()!=i) continue;
				//printl("NUM! "+num+" and nextminmun "+minnum)
				
				Key=k;
				TextLine=t
				if (TextLine.slice(0,1)=="#") TextLine=Localize.GetTokenAsUTF8(TextLine.slice(1))
			}
			if (Key==null) break;
			if (TextToDisplay=="") {NextLineDelay=2;TextToDisplay=TextLine};
			actorname=Key.slice(0,Key.find(i.tostring())-1)
			local actor=Entities.FindByName(null,actorname)
			if (actorname=="player") actor=Entities.FindByName(null,"PlayerModel");
			ActorName_Localized=CharNames.GetKeyString(actorname);
			//printl("mins!")
			//printl(minnum)
			//printl(nextminnum)
			if (CleanText) {ThoughtsMode=false;Text="";CleanText=false;printl("Next text is "+TextToDisplay.len());Interval=0.03}
			//printl(fabs(LLen(Text)-LLen(TextToDisplay)))
			//printl(Text)
			//printl(TextToDisplay)
			if (LLen(Text)==LLen(TextToDisplay)||TextToDisplay==null) {i=clamp(minnum,i,i+1);TextToDisplay="";CleanText=true;StopSpeak(actor);StopDialogue=true;return Auto.tointeger()*2}
			//if (TextToDisplay[Text.len()].tochar()=="#") {TextToDisplay=TextToDisplay.slice(0,Text.len())+TextToDisplay.slice(Text.len()+1);return 0.25}
			TagEvent<-ProcessTag(actor)
			if (TagEvent!=null&&TagEvent!=0) return TagEvent;
			if (TagEvent==0) continue;
			
			if (TextToDisplay[Text.len()].tochar()=="(") 
				ThoughtsMode=true;
			
			if (!ThoughtsMode&&TextToDisplay[Text.len()].tochar()!=" "&&TextToDisplay[Text.len()].tochar()!=".") {Speak(actor)}
			
			if (!ThoughtsMode&&TextToDisplay[Text.len()].tochar()!=" "&&TalkSound==false) {TalkSound=true;surface.PlaySound((actor.GetName().find("Nina")!=null) ? "common/noise_f.wav" : "common/noise.wav")}
			else if (!ThoughtsMode&&TextToDisplay[Text.len()].tochar()!=" "&&TalkSound==true) {TalkSound=false}
			
			if (TextToDisplay[Text.len()].tochar()==")") 
				ThoughtsMode=false;
			
			local lastchar=Text.len()
			
			for (local i=0;i<UTF8Bytes(TextToDisplay,lastchar);i++)
			{
				Text+=TextToDisplay[Text.len()].tochar()
			}
			//printl(Text)
			
			return Interval
		}
		if (!CloseDialogue) 
		{
			NetMsg.Start("MoveCameraBack")
			NetMsg.Send()
		}
		CloseDialogue=true;
		Selection=-1
		//HidePanels();
		return 0.07
	}
	
	surface.CreateFont( "DialogMain9",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Trebuchet MS"    // Name of the font file
        "tall"            : 18      // Size of the text
        "weight"        : 500       // Amount of boldness to add
        //"blur"            : 3        // Amount of blur to add (optional)
        //"additive"        : true        // Renders font by brightening pixels behind it (default for game_text)
        "antialias"     : false           // Enables font smoothing
       // "dropshadow"     : true            // Adds a drop shadow to the font
        "proportional"     : true          // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );
	surface.CreateFont( "DialogShadow3",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Trebuchet MS"    // Name of the font file
        "tall"            : 18       // Size of the text
        "weight"        : 500       // Amount of boldness to add
        "blur"            : 1       // Amount of blur to add (optional)
        "antialias"     : false            // Enables font smoothing
        //"dropshadow"     : true            // Adds a drop shadow to the font
        "proportional"     : true           // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );
	surface.CreateFont( "DialogMisc10",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Trebuchet MS"    // Name of the font file
        "tall"            : 16       // Size of the text
        "weight"        : 700       // Amount of boldness to add
        "antialias"     : false            // Enables font smoothing
        //"dropshadow"     : true            // Adds a drop shadow to the font
        "proportional"     : true           // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );
	surface.CreateFont( "DialogMisc10S",        // Name of this font entry (user-defined, can be anything)
    {
        "name"            : "Trebuchet MS"    // Name of the font file
        "tall"            : 16       // Size of the text
        "weight"        : 800       // Amount of boldness to add
        "antialias"     : true           // Enables font smoothing
        "blur"            : 1       // Amount of blur to add (optional)
        //"dropshadow"     : true            // Adds a drop shadow to the font
        "proportional"     : true           // Proportional to resolution; Must be enabled for game_text, disabled for vgui_text_display
    } );
	
	
	local name="Male01"
	local first=null
	
	function DrawOutlinedBox(b,s,x,y)
	{
		local border=b
		local size=s
		surface.DrawFilledRect( x, y,size,border );
		surface.DrawFilledRect( x, y+border,border,size-border );
		surface.DrawFilledRect( x+border, y+size-border,size-border,border );
		surface.DrawFilledRect( x+size-border, y+border,border,size-border*2 );
	}
	AutoSwitched<-Time()
	local Line2Start=70
	local Line3Start=Line2Start+70
	
	local PrevText="........"
	
	local TextLines=GetTextInLines(surface.GetFont( "DialogMain9", true ),sizex*1.9,GetTaglessText(TextToDisplay),Text.len())
	
	local H=0
	
	function Draw()
	{
		if (Text.len()<2)
		{
			Line2Start=70
			Line3Start=Line2Start+70
		}
		if (first==null) H=0;
		if (first==null) first=Time();
		
		if (!CloseDialogue) 
			H=clamp(H+100*FrameTime(),0,100);
	
		surface.SetColor( 0, 0, 0, 255 );
		//surface.DrawFilledRect( ScreenWidth()/2-sizex/2, ScreenHeight()-sizey*1.2, sizex, sizey );
		if (CloseDialogue==true&&(Time()-first)>2) 
			first=Time();
		if (CloseDialogue==true) 
		{
			H=clamp(H-100*FrameTime(),0,100)
			if (H<1) 
			{
				HidePanels();
				return
			}
		}
		
		if (!CutsceneMode)
		{
			surface.DrawFilledRect( 0, 0, ScreenWidth(), YRES(H*0.9) );
			surface.DrawFilledRect( 0, YRES(480)-YRES(H*0.9), ScreenWidth(), YRES(H) );
		}
		local TaglessText=GetTaglessText(TextToDisplay)
		
		if (Text!=PrevText)
		{
			TextLines=GetTextInLines(surface.GetFont( "DialogMain9", true ),sizex*1.9,TaglessText,LLen(Text));
			if (TaglessText==""&&Text!="")
				TextLines=GetTextInLines(surface.GetFont( "DialogMain9", true ),sizex*1.9,Text,LLen(Text));;
			PrevText=Text;
		}
		//printl("Tagless text "+TaglessText)
		if (TaglessText.len()>70) while (TaglessText[Line2Start].tochar()!=" ") Line2Start--;
		Line3Start=Line2Start+70
		if (TaglessText.len()>Line2Start+70) while (TaglessText[Line3Start].tochar()!=" ") Line3Start--;
		
		Line1<-Text.slice(0,clamp(Line2Start,0,Text.len()));
		
		local Line2="";
		local Line3="";
		if (Text.len()>Line2Start) Line2=Text.slice(Line2Start+1,clamp(Line3Start,0,Text.len()));
		
		if (Text.len()>Line3Start) Line3=Text.slice(Line3Start+1);
		
		
		//H*=-YRES(1)
		//H-=YRES(111)
		//surface.DrawColoredTextRect(surface.GetFont( "DSh", true ), ScreenWidth()/2-sizex/2+15, ScreenHeight()-sizey*1.2+45, sizex-50,sizey,2,111,255,255, Text)
		//surface.DrawColoredTextRect(surface.GetFont( "Di", true ), ScreenWidth()/2-sizex/2+15, ScreenHeight()-sizey*1.2+45, sizex-50,sizey,200,200,200,240, Text)
		local color=250-fabs(sin(Time()))*110
		local color2=250-fabs(cos(Time()))*110
		
		//printl(TextToDisplay)
		//printl("current text: "+Text)
		//printl("current taglesstext: "+TextToDisplay)
		
		foreach (i,Line in TextLines)
		{
			if (CutsceneMode)
			{
				surface.DrawColoredText(surface.GetFont( "DialogMain9", true ), ScreenWidth()/2-sizex+15+YRES(1), YRES(480)-YRES(H*0.9)+YRES(15)+i*surface.GetFontTall(surface.GetFont( "DialogMain9", true ))+YRES(1), 20,20,20,255, Line)
				surface.DrawColoredText(surface.GetFont( "DialogMain9", true ), ScreenWidth()/2-sizex+15-YRES(1), YRES(480)-YRES(H*0.9)+YRES(15)+i*surface.GetFontTall(surface.GetFont( "DialogMain9", true ))-YRES(1), 20,20,20,255, Line)
				surface.DrawColoredText(surface.GetFont( "DialogMain9", true ), ScreenWidth()/2-sizex+15+YRES(1), YRES(480)-YRES(H*0.9)+YRES(15)+i*surface.GetFontTall(surface.GetFont( "DialogMain9", true ))-YRES(1), 20,20,20,255, Line)
				surface.DrawColoredText(surface.GetFont( "DialogMain9", true ), ScreenWidth()/2-sizex+15-YRES(1), YRES(480)-YRES(H*0.9)+YRES(15)+i*surface.GetFontTall(surface.GetFont( "DialogMain9", true ))+YRES(1), 20,20,20,255, Line)
			}
			
			
			surface.DrawColoredText(surface.GetFont( "DialogMain9", true ), ScreenWidth()/2-sizex+15+2, YRES(480)-YRES(H*0.9)+YRES(15)+i*surface.GetFontTall(surface.GetFont( "DialogMain9", true )), 0,color,color2,20, Line)
			surface.DrawColoredText(surface.GetFont( "DialogMain9", true ), ScreenWidth()/2-sizex+15, YRES(480)-YRES(H*0.9)+YRES(15)+i*surface.GetFontTall(surface.GetFont( "DialogMain9", true )), 200,200,200,255, Line)
		}
		
		if (Text!="")
		{
			surface.DrawColoredText(surface.GetFont( "DialogMisc10", true ), ScreenWidth()/2-sizex+8, YRES(480)-YRES(H*0.9)+YRES(2), 200,200,200,200, ActorName_Localized)
			surface.DrawColoredText(surface.GetFont( "DialogMisc10", true ), ScreenWidth()/2-sizex+10, YRES(480)-YRES(H*0.9)+YRES(2), 0,140,250,20, ActorName_Localized)
		}
		if ((TextToDisplay==""||TextToDisplay==Text)&&!ChoiceActive&&(!(CutsceneMode&&Text=="")))
		{
			local Etall=surface.GetFontTall(surface.GetFont( "DialogMisc10", true ))/2
			local EWidth=surface.GetTextWidth(surface.GetFont( "DialogMisc10", true ),"E")/2
			surface.DrawColoredText(surface.GetFont( "DialogMisc10", true ), ScreenWidth()/2+sizex+YRES(6+8)-EWidth,YRES(480)-YRES(H*0.9)+YRES(13+8)-Etall, 0,140,250,100+155*fabs(sin(Time()*2)), "E")
			surface.SetColor( 25,25,26,100+155*fabs(sin(Time()*2)) );
			DrawOutlinedBox(YRES(2),YRES(25-5),ScreenWidth()/2+sizex+YRES(4),YRES(480)-YRES(H*0.9)+YRES(11))
			surface.SetColor( 50,50,52,100+155*fabs(sin(Time()*2)) );
			DrawOutlinedBox(YRES(2),YRES(21-5),ScreenWidth()/2+sizex+YRES(6),YRES(480)-YRES(H*0.9)+YRES(13))
		}
		if ((Time()-AutoSwitched)<2)
		{
			surface.DrawColoredText(surface.GetFont( "DialogMisc10", true ), ScreenWidth()/2+sizex/2+YRES(42), YRES(480)-YRES(H*0.9)+YRES(15), 0,140,250,255-127.5*(Time()-AutoSwitched), "Auto Mode "+(Auto ? "on" : "off")+"...")
		}
		l<-1
		//printl(ChoiceTable.len())
		
		local MaxChoiceWidth=0
		foreach (va in ChoiceTable)
		{
			//if (va.slice(0,1)=="#") va=Localize.GetTokenAsUTF8(va.slice(1))
			
			if (surface.GetTextWidth(surface.GetFont( "DialogMisc10", true ),"0. "+va.slice(0,va.find("|")))>MaxChoiceWidth)
			{
				MaxChoiceWidth=surface.GetTextWidth(surface.GetFont( "DialogMisc10", true ),"0. "+va.slice(0,va.find("|")))
			}
		}
		
		if (LastChoiceActive==false&&ChoiceActive)
			ChoiceTime=Time();
		
		foreach (va in ChoiceTable)
		{	
			local v=va
			
			//if (v.slice(0,1)=="#") v=Localize.GetTokenAsUTF8(v.slice(1))
		
			local AnimMod=Gain(clamp((Time()-ChoiceTime)*1.5,0,1),0.95)
			if (clamp((Time()-ChoiceTime)*1.5,0,1)<0.5)
				AnimMod=Gain(clamp((Time()-ChoiceTime)*1.5,0,1),0.5);
			
			if (Selection!=(-1)) 
				AnimMod=1;

		
			local Gap=(surface.GetFontTall(surface.GetFont( "DialogMisc10", true ))+YRES(2))*((ChoiceTable.len()-l)+1)
			local Y=-YRES(H*1.25)-Gap
			local X=-MaxChoiceWidth-YRES(30)+(MaxChoiceWidth+YRES(50))*AnimMod
			
			//foreach (ke,va in ChoiceTable) {if (ke.find(""+l)==null) continue;k=ke;v=va}
			//printl(k.slice(k.len()-1))
			if (l==1)
			{
				surface.SetColor( 0,0,0, 255);
				local Xtra=YRES(25)
			
				surface.DrawFilledRect(X-Xtra,YRES(480)+Y-Xtra,MaxChoiceWidth+Xtra*3,Gap+Xtra*2)
				
				local DBorder=YRES(2)
				
				surface.SetColor( 0,20,100, 155);
				
				surface.DrawOutlinedRect(X-Xtra,YRES(480)+Y-Xtra,MaxChoiceWidth+Xtra*3,Gap+Xtra*2,DBorder*3)
				
				surface.SetColor( 0,160,230, 155);
				
				surface.DrawOutlinedRect(X-Xtra+DBorder,YRES(480)+Y-Xtra+DBorder,MaxChoiceWidth+Xtra*3-DBorder*2,Gap+Xtra*2-DBorder*2,DBorder)
				
			}
			surface.SetColor( 0,160,255, 205*(Selection+1==l).tointeger() );
			surface.DrawOutlinedCircle( X-YRES(10), YRES(480)+Y+surface.GetFontTall(surface.GetFont( "DialogMisc10", true ))/2, YRES(7), 3 );
			
			
			surface.DrawColoredText(surface.GetFont( "DialogMisc10S", true ), X, YRES(480)+Y, 20,110,255,255*(Selection+1==l).tointeger(), l+". "+v.slice(0,v.find("|")))
			surface.DrawColoredText(surface.GetFont( "DialogMisc10", true ), X, YRES(480)+Y, 0,140,250,255, l+". "+v.slice(0,v.find("|")))
			surface.DrawColoredText(surface.GetFont( "DialogMisc10", true ), X, YRES(480)+Y, 40,210,255,255*(Selection+1==l).tointeger(), l+". "+v.slice(0,v.find("|")))
			l++
		}
		LastChoiceActive=ChoiceActive
	}
	function SetDialogueText(displaytext,givenname)
	{
		//printl("Text set to none!")
		dtext=displaytext
		Text=""
		extra=0
		name=givenname
	}
	
	function DialogueCmd(cmd)
	{
		param<-(cmd.slice(cmd.find(":")+1))
		cmd=(cmd.slice(0,cmd.find(":")))
		
		switch(cmd)
		{
			case "goto":
			{
				ChoiceTable=[]
				ChoiceActive=false
				StopDialogue=false
				i=param.tointeger();
				NextLineDelay=0
				TextToDisplay="";
				CleanText=true;
				StopSpeak(actor);
				//ClientThink()
				break
			}
			case "entfire":
			{
				NetMsg.Start("EntFireFromDialogue")
				NetMsg.WriteString(param)
				NetMsg.Send()
				
				ChoiceTable=[]
				ChoiceActive=false
				//StopDialogue=false
				//NextLineDelay=0
				Text="";
				ActorName_Localized="";
				StopDialogue=true;
				//i++;
				break
			}
		}
	}
	
	local DelayActive=false;
	
	function KeyPress(key)
	{
		if (CutsceneMode&&i==1&&TextToDisplay=="") return;
		
		local cmd=null
		
		//printl(key)
		if (input.ButtonCodeToString(key)=="e"&&!ChoiceActive)
		{
			//printl("TEXT "+Text)
			//printl("TEXTTODISPLAY "+TextToDisplay)
			if (TextToDisplay==""||TextToDisplay==Text)
			{
				//printl(Actions)
				//foreach (k,v in Actions) printl(k+" "+v)
				if (CutsceneMode&&Actions&&((i-1).tostring() in Actions)&&Actions[(i-1).tostring()].find("|")!=null&&StopDialogue)
				{
					//printl(Actions[(i-1).tostring()])
					local ID=(i-1).tostring()
					cmd=Actions[ID].slice(0,Actions[ID].find("|"))
					while (cmd.find("@")) cmd=cmd.slice(0,cmd.find("@"))+"\""+cmd.slice(cmd.find("@")+1)
						
					RunActionOnServer(i-1)
					
					printl("Adding delay "+ID)
					
					if (!DelayActive) Entities.First().SetContextThink("DialogueDelay",function (...) {StopDialogue=false;DelayActive=false;}.bindenv(this),0.1+Actions[ID].slice(Actions[ID].find("|")+1).tofloat());
					DelayActive=true
				}
				else 
				{
					if (!DelayActive) Entities.First().SetContextThink("DialogueDelay",function (...) {StopDialogue=false;DelayActive=false}.bindenv(this),0.001);
					DelayActive=true
				}
				//Auto=false
				//ClientThink()
				//return
			}
			else surface.PlaySound("ui/buttonrollover.wav");
			failsafe<-0
			if (TextToDisplay.find("<")) Text=Text+TextToDisplay.slice(Text.len(),TextToDisplay.find("<")+1);
			while (TagFind()&&failsafe<20)
			{
				//printl("find "+TagFind())
				Text=Text.slice(0,Text.len()-1)
				printl(ProcessTag(Entities.FindByName(null,actorname)))
				failsafe++
				if (failsafe>15) printl("FAILSAFE")
				if (TextToDisplay.find("<")) Text=Text+TextToDisplay.slice(Text.len(),TextToDisplay.find("<")+1);
			}
			
			TagCleanAll()
			Text=TextToDisplay
			if (!Auto) ClientThink();
			//Interval=0
			if (cmd) printl(cmd)
			if (cmd) compilestring(cmd).call(this)
		}
		else if (key==16)
		{
			printl("Auto Mode "+!Auto)
			Auto=!Auto
			StopDialogue=false
			AutoSwitched=Time()
		}
		else if (key==90||key==29)
		{
			Selection=((Selection+1)+((Selection+1)<0).tointeger()*ChoiceTable.len())%ChoiceTable.len()
			surface.PlaySound("ui/buttonrollover.wav")
		}
		else if (key==88||key==33)
		{
			Selection=((Selection-1)+((Selection-1)<0).tointeger()*ChoiceTable.len())%ChoiceTable.len()
			surface.PlaySound("ui/buttonrollover.wav")
		}
		else if ((key==64||key==15)&&ChoiceActive)
		{
			if (Selection<0) {Selection=0;return}
			
			printl("Selected "+ChoiceTable[(Selection)])
			surface.PlaySound("ui/buttonrollover.wav")
			Cmds<-split(ChoiceTable[(Selection)],"|")
			for(local i=1;i<Cmds.len();i++)
			{
				DialogueCmd(Cmds[i])
			}
			//DialogueCmd(ChoiceTable[""+(Selection+1)].slice(ChoiceTable[""+(Selection+1)].find("|")+1))
		}
		else if (key>1&&key<(ChoiceTable.len()+2)&&ChoiceActive)
		{
			Selection=key-2
			
			printl("Selected "+ChoiceTable[(Selection)])
			surface.PlaySound("ui/buttonrollover.wav")
			Cmds<-split(ChoiceTable[(Selection)],"|")
			for(local i=1;i<Cmds.len();i++)
			{
				DialogueCmd(Cmds[i])
			}
			//DialogueCmd(ChoiceTable[""+(Selection+1)].slice(ChoiceTable[""+(Selection+1)].find("|")+1))
		}
		//printl(Selection)
	}
	
	function HidePanels()
	{
		if ( Dialogue_MainP && Dialogue_MainP.IsValid() )
		{
			Dialogue_MainP.SetCallback( "OnKeyCodePressed", function(...){} );
			Dialogue_MainP.Destroy();
			//SetHudElementVisible("CHudFlashlight",true)
			//SetHudElementVisible("CHudHealth",true)
			//SetHudElementVisible("CHudAmmo",true)
			//SetHudElementVisible("CHudBattery",true)
			//SetHudElementVisible("CHudSuitPower",true)
			Dialogue_MainP = null
			first=null
			
			actor=""
			actorname=""
			i=1
			CleanText=false
			ActorName_Localized=""
			
			CloseDialogue=false
			NetMsg.Start("StopDialogue")
			NetMsg.WriteString(Dialogue_Name)
			NetMsg.Send()
		}
	}
	
	NetMsg.Receive("OpenDialogue", function()
	{
		if (InvP&&InvP.IsValid())
		{
			OpenInventory()
		}
	
		if ( Dialogue_MainP && input.IsButtonDown(23) ) { HidePanels() }
		else {
		
			Dialogue_MainP = null
			first=null
			
			actor=""
			actorname=""
			i=1
			CleanText=false
			ActorName_Localized=""
			
			CloseDialogue=false

			DisplayPanels();
		}
		PlayDialogue(NetMsg.ReadString())
		Contexts=NetMsg.ReadString();
	}.bindenv(this) );
	
	NetMsg.Receive("ContinueDialogue", function()
	{
		ChoiceTable=[]
		ChoiceActive=false
		i++
		StopDialogue=false
		NextLineDelay=0
		TextToDisplay="";
		CleanText=true;
		StopSpeak(actor);
	}.bindenv(this) );

	NetMsg.Receive("HideDialogue", function()
	{
		HidePanels();
	}.bindenv(this) );
	
	//DisplayPanels();
}

if ( IsServer() )
{
	IncludeScript("swfm/cameraman.nut")
	
	printl("dialog init")
	
	local LastForceExitedDialogueTime=(-10);
	
	local CutsceneMode=false;
	
	local Captions=Convars.GetInt("closecaption")
	
	//Entities.FindByName(null,"player_actor").PrecacheSoundScript("npc_vortigaunt.vques01")
	
	//EntFireByHandle(self,"AddOutput","ClientThink 1",0)
	local actor=Entities.FindByName(null,"player_actor")
	Entities.First().PrecacheSoundScript("npc_vortigaunt.vques06")
	Entities.First().PrecacheSoundScript("npc_vortigaunt.vques02")
	Entities.First().PrecacheSoundScript("npc_vortigaunt.vques04")
	Entities.First().PrecacheSoundScript("npc_vortigaunt.vques07")
	Entities.First().PrecacheSoundScript("odessa.nlo_cheer03")
	Entities.First().PrecacheSoundScript("a_bbb")
	Entities.First().PrecacheSoundScript("PlayerPunch")
	PrecacheModel("models/player.mdl")
	//actor.SpeakAutoGeneratedScene("vo/npc/male01/question02.wav",1);
	
	local came=Entities.FindByName(null,"testcam")
	
	local LastExpression=0;
	//local posa=came.GetOrigin()
	
	NetMsg.Receive("Speak", function(player)
	{
		local actor=NetMsg.ReadEntity();
		switch (RandomInt(1,3))
		{
			case 1: EmitSoundOn("npc_vortigaunt.vques04",actor);break;	//yes, these have to be made silent(volume 0) in soundscripts. robust, but a working way of imitated moving lips.
			case 2: EmitSoundOn("npc_vortigaunt.vques02",actor);break;
			case 3: EmitSoundOn("npc_vortigaunt.vques06",actor);break;
		}
		//if (actor.GetClassname().find("npc")!=null) actor.AddLookTarget(player,1,10.3,0);
		if (Time()-LastExpression>3)
			EntFireByHandle(actor,"setexpressionoverride","scenes/Expressions/citizenidle.vcd",0);
	});
	function Precache()
	{
		//PrecacheModel("models/player.mdl.mdl", true)
	}
	function CreatePlayerNPC()
	{
		if (Entities.FindByName(null,"PlayerModel")) return;
		local weapon=player.GetActiveWeapon() ? player.GetActiveWeapon().GetClassname():""
		local playertable={
			model="models/player.mdl"
			targetname="PlayerModel"
			origin=player.GetOrigin().x+" "+player.GetOrigin().y+" "+(player.GetOrigin().z+990)
			angles="0 "+player.GetAngles().y+" 0"
			additionalequipment=weapon
			spawnflags=1048576+16384+1024
			SpawnWithStartScripting=1
			rendermode=1
			citizentype=4
			OnDeath="dialogue_manager:callscriptfunctionclient:HidePanels:0:1"
			OnDeath="player:SetHealth:-200:0.1:1"
			OnDeath="!self:kill::0:1"
		}
		local npc=SpawnEntityFromTable("npc_citizen",playertable);
		EntFireByHandle(npc,"AddOutput","OnDeath dialogue_manager:callscriptfunctionclient:HidePanels:0:1",0)
		EntFireByHandle(npc,"AddOutput","OnDeath dialogue_manager:callscriptfunctionclient:HidePanels:0:1",0)
		EntFireByHandle(npc,"AddOutput","OnDeath player:SetHealth:-200:0.1:1",0)
		EntFireByHandle(npc,"AddOutput","OnDeath !self:kill:0:0:1",0)
		EntFire("PlayerModel","AddOutput","OnDeath dialogue_manager:callscriptfunctionclient:HidePanels:0:1",0)
		//npc.SetCollisionGroup(18)
		npc.SetOrigin(player.GetOrigin())
	}
	
	
	// Gives angles to make thing at pos1 point to pos2.
	function PointAt(pos1,pos2)
	{
		return VectorAngles(pos2-pos1)
	}
	
	function MoveTo(ent,pos,ang,stylish=false)
	{
		Entities.First().SetContextThink("SmoothMovement",function (_)
		{return null},0)
		if (ent==null) return null;
		if (!"GetOrigin" in ent) return null;
		
		ent.SetAngles(Vector(AngleNormalize(ent.GetAngles().x),AngleNormalize(ent.GetAngles().y),AngleNormalize(ent.GetAngles().z)))
		ang=(Vector(AngleNormalize(ang.x),AngleNormalize(ang.y),AngleNormalize(ang.z)))
		
		dist<-(pos-ent.GetOrigin()).Length()
		ent.SetVelocity(pos-ent.GetOrigin())
		anglesvel<-ang-ent.GetAngles()
		
		printl("start "+ang.x)

		if (ang.x>180) ang.x-=360
		if (ang.x<(-180)) ang.x+=360
		
		//if ((ang.y-ent.GetAngles().y)>180) anglesvel=anglesvel-Vector(0,360,0)
		//if ((ang.y-ent.GetAngles().y)<(-180)) anglesvel=anglesvel+Vector(0,360,0)
		if (anglesvel.y>180) anglesvel.y-=360
		if (anglesvel.y<(-180)) anglesvel.y+=360
		
		if (anglesvel.x>180) anglesvel.x-=360
		if (anglesvel.x<(-180)) anglesvel.x+=360
		printl("end "+ang.x)
		printl("end "+anglesvel.x)
		name<-ent.GetName()
		Entities.First().SetContextThink("SmoothMovement",function (_)
		{
		
			if (Entities.FindByName(null,name)==null) return null
			local path=clamp((pos-ent.GetOrigin()).Length()/dist,0,1)
			path=sqrt(path)
			path=sqrt(path)
			
			local PlayerChar=Entities.FindByName(null,"PlayerModel")
			if (PlayerChar==null) return null
			
			//printl("distance "+(Entities.FindByName(null,"PlayerModel").GetAttachmentOrigin(PlayerChar.LookupAttachment("eyes"))-ent.GetOrigin()).Length())
			
			local modelAlpha=RemapVal((PlayerChar.GetOrigin()+Vector(0,0,66.5)-ent.GetOrigin()).Length(),6,12,0,255)
			modelAlpha=clamp(modelAlpha,0,255)
			
			if (PlayerChar) PlayerChar.SetRenderAlpha(modelAlpha);
			//if (Entities.FindByName(null,"PlayerModel_weapon")) {Entities.FindByName(null,"PlayerModel_weapon").SetRenderMode(1);Entities.FindByName(null,"PlayerModel_weapon").SetRenderAlpha(255/362.0*clamp((pow((PlayerChar.EyePosition()-ent.GetOrigin()).Length(),2)),0,362));}

			ent.SetAngles(Vector(AngleNormalize(ent.GetAngles().x),AngleNormalize(ent.GetAngles().y),AngleNormalize(ent.GetAngles().z)))
			ang=(Vector(AngleNormalize(ang.x),AngleNormalize(ang.y),AngleNormalize(ang.z)))

			ent.SetVelocity((pos-ent.GetOrigin())*path*6)
			//if (PlayerChar) if ((PlayerChar.GetAttachmentOrigin(PlayerChar.LookupAttachment("eyes"))-ent.GetOrigin()).Length()<18&&stylish) PlayerChar.SetRenderAlpha(0)
			anglesvel<-ang-ent.GetAngles()
			if (anglesvel.y>180) anglesvel.y-=360
			if (anglesvel.y<(-180)) anglesvel.y+=360
			
			if (anglesvel.x>180) anglesvel.x-=360
			if (anglesvel.x<(-180)) anglesvel.x+=360
			
			anglesvel*=path*6
			if (stylish) path=sqrt(path);
			if (stylish) path=sqrt(path);
			if (stylish) anglesvel*=1.8;

			if (!stylish||path<clamp(50/dist,0.96,1)) ent.SetAngularVelocity(anglesvel.x,anglesvel.y,anglesvel.z);
			return 0.03
		}.bindenv(this),0.03)
	}
	
	
	local SideDist=11
	local BackDist=24
	local MidPoint=0.5
	function SwitchCameraType(type)
	{
		if (typeof type=="string"&&type.len()>3)
		{
			Params<-split(type," ")
			SideDist=Params[0].tointeger();
			BackDist=Params[1].tointeger();
			MidPoint=Params[2].tofloat();
			return;
		}
		local type=type.tointeger()
		switch(type)
		{
		case 0: SideDist=11;BackDist=24;MidPoint=0.5;break
		case 1: SideDist=11;BackDist=24;MidPoint=0.5;break
		case 2: SideDist=12;BackDist=17;MidPoint=0.6;break
		case 3: SideDist=0;BackDist=-20;MidPoint=1;break
		case 4: SideDist=30;BackDist=35;MidPoint=0.3;break
		case 5: SideDist=30;BackDist=45;MidPoint=0.8;break
		case 6: SideDist=15;BackDist=-20;MidPoint=1;break
		case 7: SideDist=75;BackDist=25;MidPoint=0.4;break
		}
		printl("camtype "+type)
	}
	
	
	LastActor<-Entities.FindByName(null,"PlayerModel")
	//LastActor2<-Entities.FindByName(null,"candle")
	LastActor2<-Entities.FindByName(null,"PlayerModel")
	local first=false
	
	function SwitchCamera(actor=LastActor,actor2=Entities.FindByName(null,"PlayerModel"))
	{
		if (CutsceneMode) return;
		
		if (!LastActor) LastActor=Entities.FindByName(null,"PlayerModel")
		if (!LastActor2) LastActor2=Entities.FindByName(null,"PlayerModel")
		
		if (actor2==null) actor2=LastActor2;
		if (actor==null) actor=LastActor;
		Entities.First().SetContextThink("SmoothMovement",function (_)
		{return null},0)
		
		// Entities.FindByName(null,"trader").LookupBone("ValveBiped.Bip01_Head1")
		
		LastActor=actor
		LastActor2=actor2
		//printl(actor)
		//printl(actor)//bone location. difference from getorigin
		//printl(actor2)
		
		if (!actor||!actor.IsValid()) actor=Entities.FindByClassname(null,"npc_citizen");
		if (!actor2||!actor2.IsValid()) actor2=Entities.FindByClassname(null,"npc_citizen");
		//if (!actor2.IsValid()) return;
		
		local actor_offset=Vector(0,0,64)
		if (actor instanceof CBaseEntity)
		{
			eyes<-actor.LookupAttachment("eyes")
			eyeorigin<-actor.GetAttachmentOrigin(eyes)
			//printl("EYE DIFFERENCE FOR "+actor.GetName()+" "+(eyeorigin-actor.GetOrigin()))
			actor_offset=(eyeorigin-actor.GetOrigin())-Vector(0,0,4)
		}
		
		local actor2_offset=Vector(0,0,64)
		if (actor2.IsValid()&&Entities.FindByName(null,"PlayerModel"))
		{
			eyes2<-actor2.LookupAttachment("eyes")
			eyeorigin2<-actor2.GetAttachmentOrigin(eyes2)
			//printl("EYE DIFFERENCE FOR "+actor2.GetName()+" "+(eyeorigin2-actor2.GetOrigin()))
			actor2_offset=(eyeorigin2-actor2.GetOrigin())-Vector(0,0,4)
			actor2_offset.x=0;
			actor2_offset.y=0;
		}
		first=true
		local direction=actor2.GetOrigin()+actor2_offset-actor.GetOrigin()-actor_offset
		direction.z=0
		local direction90=(-direction).Cross(Vector(0,0,1))
		if (actor2.GetName()!="PlayerModel") direction90=-direction90
		local origin=actor2.GetOrigin()+actor2_offset+direction.Normalized()*BackDist-direction90.Normalized()*SideDist+Vector(0,0,6)
		if (actor2.GetClassname().find("npc_")==null) origin-=Vector(0,0,64);
		
		local PointToFace=(actor.GetOrigin()*MidPoint+actor2.GetOrigin()*(1-MidPoint))+(actor2_offset+actor_offset)/2.0+Vector(0,0,-64*(actor2.GetClassname().find("npc_")==null).tointeger())
		
		local angles=PointAt(origin,PointToFace)
		
		printl("camera "+TraceLine(origin,origin+Vector(0,0,1),player))
		local modificator=0.9
		local Fails=0
		printl(TraceLineComplex(origin,actor2.EyePosition(),actor2, MASK_SOLID, 1).DidHit())
		debugoverlay.Line(origin,origin+Vector(0,0,4),255,0,0,true,15)
		while (TraceLineComplex(origin,actor2.EyePosition(),actor2, MASK_SOLID, 1).DidHit()&&Fails<100)
		{
			printl("camera hit something")
			Fails++
			
			SwitchCameraType(RandomInt(0,7))
			
			if (Fails>10) SideDist=-SideDist;
			
			origin=actor2.GetOrigin()+actor2_offset+direction.Normalized()*BackDist-direction90.Normalized()*SideDist+Vector(0,0,6)
			if (actor2.GetClassname().find("npc_")==null) origin-=Vector(0,0,64);
			PointToFace=(actor.GetOrigin()*MidPoint+actor2.GetOrigin()*(1-MidPoint))+(actor2_offset+actor_offset)/2.0+Vector(0,0,-64*(actor2.GetClassname().find("npc_")==null).tointeger())
			angles=PointAt(origin,PointToFace)
		}
		
		
		if (Entities.FindByName(null,"PlayerCamera")!=null)
		{
			//MoveTo(Entities.FindByName(null,"PlayerCamera"),origin,angles)
			Entities.FindByName(null,"PlayerCamera").SetOrigin(origin)
			Entities.FindByName(null,"PlayerCamera").SetAngles(angles)
			Entities.FindByName(null,"PlayerCamera").SetVelocity(Vector(0,0,0))
			Entities.FindByName(null,"PlayerCamera").SetAngularVelocity(0,0,0)
			Entities.FindByName(null,"PlayerCamera").SetOrigin(origin)
			Entities.FindByName(null,"PlayerCamera").SetAngles(angles)
			
			player.SetOrigin(Vector(0,0,actor.GetOrigin().z)+Vector(0,0,16))
			EntFireByHandle(Entities.FindByName(null,"PlayerCamera"),"Enable","",0)
			return
		}
		
		local cameratable={
			targetname="PlayerCamera"
			origin=player.EyePosition().x+" "+player.EyePosition().y+" "+player.EyePosition().z
			angles=player.EyeAngles().x+" "+player.EyeAngles().y+" "+player.EyeAngles().z
			spawnflags=4+8+32+128
			fov=50
			fov_rate=0
		}
		local camera=SpawnEntityFromTable("point_viewcontrol",cameratable);
		
		MoveTo(Entities.FindByName(null,"PlayerCamera"),origin,angles)
		//EntFireByHandle(camera,"Enable","",0.1)
		player.SetMoveType(MOVETYPE_NOCLIP)
		player.SetOrigin(Vector(0,0,actor.GetOrigin().z)+Vector(0,0,16))
		
		
		
		
		EntFireByHandle(camera,"Enable","",0)
	}
	
	Convars.RegisterCommand( "dialog", function(...)
	{
		SwitchCameraType(vargv[1]+" "+vargv[2]+" "+vargv[3])
		SwitchCamera()
		//SideDist=vargv[1]
		//BackDist=vargv[2]
		//MidPoint=vargv[3]
		//SwitchCamera()
	}.bindenv(this), "ey", FCVAR_NONE );
	
	NetMsg.Receive("CreatePlayerNPC", function(player)
	{
		CreatePlayerNPC()
	}.bindenv(this));
	
	NetMsg.Receive("ForceDialogueExit", function(player)
	{
		LastForceExitedDialogueTime=Time()	//This is gonna prevent player from immediately starting another dialogue by spamming E button which breaks things.
	}.bindenv(this));
	
	NetMsg.Receive("MoveCameraBack", function(player)
	{
		EntFire("PlayerCamera","SetFOV",Convars.GetFloat("fov_desired"),0)
		MoveTo(Entities.FindByName(null,"PlayerCamera"),Entities.FindByName(null,"PlayerModel").GetOrigin()+Vector(0,0,64+2.5),Entities.FindByName(null,"PlayerModel").EyeAngles(),true)
		
		if (CutsceneMode) SW_MoveCamera(Entities.FindByName(null,"PlayerModel").GetOrigin()+Vector(0,0,66),Entities.FindByName(null,"PlayerModel").EyeAngles(),0.8)
		if (CutsceneMode) EntFire("swfm_camera","SetFOV",Convars.GetFloat("fov_desired"),0);	
	}.bindenv(this));
	
	NetMsg.Receive("StopDialogue", function(player)
	{
		local title=NetMsg.ReadString()
		
		Hooks.Call("DialogueEnd_"+title,null)
		Hooks.Remove("DialogueEnd_"+title,"1")
		
		if (CutsceneMode) EntFireByHandle(cam,"Disable")
		if (CutsceneMode) EntFireByHandle(cam,"Kill")
		
		EntFire("PlayerCamera","Disable","",0)
		EntFire("PlayerCamera","kill","",0)
		if (!Entities.FindByName(null,"PlayerModel")) SendToConsole("hurtme 999")
		player.SetAngles(Entities.FindByName(null,"PlayerModel").GetAngles())
		orig<-Entities.FindByName(null,"PlayerModel").GetOrigin()
		eyeorig<-Entities.FindByName(null,"PlayerModel").EyePosition()
		Entities.FindByName(null,"PlayerModel").Destroy()
		player.SetOrigin(orig+Vector(0,0,2.5))
		player.SetMoveType(MOVETYPE_WALK)
		SendToConsole("sourceworld_hud 0")
		player.GetViewModel(0).SetModel("models/blackout.mdl")
		if (SW_AMBIENT.find("dialo")!=null) EntFire("dialogue_stop","trigger","",0)
		
		SendToConsole("closecaption "+Captions)
	}.bindenv(this));
	
	NetMsg.Receive("SwitchCamera", function(player)
	{
		local actor=NetMsg.ReadEntity()
		local actor2=Entities.FindByName(null,NetMsg.ReadString())
		Entities.First().SetContextThink("SwitchCameraDelayed",function(...){SwitchCamera(actor,actor2)}.bindenv(this),0.02)
		EntFire("PlayerCamera","SetFOV","40",0.02)
	}.bindenv(this));
	
	NetMsg.Receive("SwitchCameraSimple", function(player)
	{
		Entities.First().SetContextThink("SwitchCameraDelayed",function(...){SwitchCamera()}.bindenv(this),0.02)
		EntFire("PlayerCamera","SetFOV","40",0.02)
	}.bindenv(this));
	
	NetMsg.Receive("SwitchCameraType", function(player)
	{
		SwitchCameraType(NetMsg.ReadString())
	}.bindenv(this));
	
	NetMsg.Receive("Gesture", function(player)
	{
		local actor=NetMsg.ReadEntity();
		local gesture=NetMsg.ReadString();
		if (actor==null) return;
		actor.AddGestureSequence(gesture,true)
	});
	
	NetMsg.Receive("DialogueExpression", function(player)
	{
		local actor=NetMsg.ReadEntity();
		local exp=NetMsg.ReadString();
		
		switch(exp)
		{
			case "angry":exp="barneycombat.vcd";break;
			case "serious":exp="barneyalert.vcd";break;
			case "surprised":exp="citizen_normal_combat_01.vcd";break;
			case "sad":exp="citizen_scared_idle_01.vcd";break;
			case "scared":exp="citizen_scared_alert_01.vcd";break;
			case "normal":exp="citizen_normal_idle_01.vcd";break;
		}
		
		if (actor==null) return;
		EntFireByHandle(actor,"setexpressionoverride","",0)
		EntFireByHandle(actor,"setexpressionoverride","scenes/Expressions/"+exp,0.01)
		LastExpression=Time();
	});
	
	NetMsg.Receive("EntFireFromDialogue", function(player)
	{
		local params=split(NetMsg.ReadString(),",");
		EntFire(params[0],params[1],params[2],params[3].tofloat())
	});
	NetMsg.Receive("FadeFromDialogue", function(player)
	{
		SendToConsole("fadeout 1")
	});
	
	local Actions={}
	
	local LastActionID=null
	
	NetMsg.Receive("ActionFromDialogue", function(player)
	{
		local id=NetMsg.ReadShort()
		
		// Don't run same action on server two times in a row.
		if (id==LastActionID) return;
		
		LastActionID=id
		local cmd=Actions[id.tostring()].slice(0,Actions[id.tostring()].find("|"))
		while (cmd.find("@")) cmd=cmd.slice(0,cmd.find("@"))+"\""+cmd.slice(cmd.find("@")+1)
		
		compilestring(cmd).call(this)
	});
	
	function NPCTurnTo(npc,ent)
	{
		if (npc.GetSequenceName(npc.GetSequence()).find("sit")!=null)
			return;
		local origin=ent.GetOrigin()
		local direction=VectorAngles(ent.GetOrigin()-npc.GetOrigin())
		local scripttable={
			origin=origin.x+" "+origin.y+" "+origin.z
			angles=direction.x+" "+direction.y+" "+direction.z
			spawnflags=32
			m_fMoveTo=5
			m_iszEntity=npc.GetName()
		}
		local sequence=SpawnEntityFromTable("scripted_sequence",scripttable);
		EntFireByHandle(sequence,"BeginSequence","",0)
		EntFireByHandle(sequence,"Kill","",1.5)
	}
	
	NetMsg.Receive("SetLookTarget", function(player)
	{
		local actor=NetMsg.ReadEntity();
		if (actor==null) return;
		local actor2=Entities.FindByName(null,NetMsg.ReadString());
		printl(actor+" looks at "+actor2)
		actor.AddLookTarget(actor2,0.5,41,0);
		if (actor2.GetClassname().find("npc_")!=null) actor2.AddLookTarget(actor,0.5,41,0);
		NPCTurnTo(actor,actor2)
		if (actor2.GetClassname().find("npc_")!=null) NPCTurnTo(actor2,actor)
	}.bindenv(this));
	
	NetMsg.Receive("SaySound", function(player)
	{
		self.EmitSound("npc_vortigaunt.vques06")
		local actor=NetMsg.ReadEntity();
		local sound=NetMsg.ReadString();
		local snd=EmitSound_t()
		self.SetOrigin(actor.GetOrigin()+Vector(0,0,64))
		snd.SetOrigin(actor.GetOrigin())
		//snd.SetChannel(0)
		//snd.SetFlags(0)
		snd.SetSoundLevel(SNDLVL_NORM)
		snd.SetSoundName(sound)
		snd.SetSoundTime(0)
		//snd.SetSpeakerEntity(0)
		snd.SetVolume(1)
		EmitSoundParamsOn(snd,self)
	}.bindenv(this));
	
	NetMsg.Receive("StopSpeak", function(player)
	{
		local actor=NetMsg.ReadEntity();
		if (!actor) return
		EmitSoundOn("npc_vortigaunt.vques07",actor)
		if (actor.GetClassname().find("npc")!=null) actor.StopSound("npc_vortigaunt.vques07")
	});
	
	function Map(name)	//Server
	{
		if (!player.IsAlive())
			return;
		
		
		if ((Time()-LastForceExitedDialogueTime)<3)
			return;
		
		CutsceneMode=false;
		
		CreatePlayerNPC()
		
		//SendToConsole("gameui_allowescapetoshow")
		NetMsg.Start("OpenDialogue");
		NetMsg.WriteString(name)
		local contexts=""
		for (local i=0;i<self.GetContextCount();i++)
		{
			contexts+=self.GetContextIndex(i).name+","
		}
		NetMsg.WriteString(contexts)
		NetMsg.Send(player, true);
		SendToConsole("sourceworld_hud 2")
		Captions=Convars.GetInt("closecaption")
		SendToConsole("closecaption 0")
		
		if (name.find("c_")==0) CutsceneMode=true;
		
		Actions={}
		local KVActions=null;
		if (CutsceneMode) KVActions = FileToKeyValues( "dialogue/"+name+".txt" ).FindOrCreateKey("Actions");
		if (CutsceneMode) KVActions.SubKeysToTable(Actions);
		
		Entities.First().SetContextThink("DialogueCamFix",function(...){
			if (!GetNamedEnt("PlayerCamera"))
			{
				printl("Camera was going to broke! But we got it fixed, men!")
				SwitchCamera(GetNamedEnt("PlayerModel"),GetNamedEnt("PlayerModel"))
			}
			return
		}.bindenv(this),0.25)
	}
	
	
	// Dialogue Types
	
	function Dialog(title,npcname="",type=TALK.INSTANT,infinite=false)
	{
		if (npcname=="")
		{
			Hooks.Call("Dialogue_"+title,null)
			Hooks.Remove("Dialogue_"+title,"1")
			Map(title)
			return
		}
		
		//printl("creating dialogue")
		local NPC=Entities.FindByName(null,npcname)
		if (!NPC)
		{
			error("Tried to add dialogue to non-existing NPC "+npcname)
			return
		}
		if (type==TALK.INSTANT)
		{
			EntFireByHandle(NPC,"FireUser1")
			Hooks.Call("Dialogue_"+title,null)
			Hooks.Remove("Dialogue_"+title,"1")
			Map(title)
			return
		}
		if (type==TALK.USE)
		{
			//NPC.AddOutput("OnPlayerUse", "dialogue_manager", "RunScriptCodeQuotable", "Map(''"+title+"'')", 0,1)
			
			local dialogue_manager=self.GetScriptScope()
			//printl("Adding Use output")
			SW_DIALOGUE_NPCS.append(NPC.entindex())
			
			NPC.GetOrCreatePrivateScriptScope().InputUse<-function(...)
			{	
				//printl("PlayerUse");
				EntFireByHandle(NPC,"FireUser1")
				dialogue_manager.Map(title);
				
				Hooks.Call("Dialogue_"+title,null)
				
				if (!infinite) 
				{
					Hooks.Remove("Dialogue_"+title,"1")
					
					NPC.GetOrCreatePrivateScriptScope().rawdelete("InputUse")
					SW_DIALOGUE_NPCS.remove(SW_DIALOGUE_NPCS.find(NPC.entindex()))
				}
			}
		}
		
		if (type==TALK.APPROACH||type>2)
		{
			//NPC.AddOutput("OnPlayerUse", "dialogue_manager", "RunScriptCodeQuotable", "Map(''"+title+"'')", 0,1)
			
			local dialogue_manager=self.GetScriptScope()
			//printl("Adding Approach Thinker output")
			
			Entities.First().SetContextThink("DialogueApproach_"+NPC.entindex(),function(...)
			{
				//printl((player.GetOrigin()-NPC.GetOrigin()).Length()+" "+NPC.IsEntVisible(player))
				if (NPC.IsEntVisible(player)&&(player.GetOrigin()-NPC.GetOrigin()).Length()<((type==TALK.APPROACH) ? 150 : type))
				{
					//printl("PlayerApproach");
					Hooks.Call("Dialogue_"+title,null)
					Hooks.Remove("Dialogue_"+title,"1")
					EntFireByHandle(NPC,"FireUser1")
					dialogue_manager.Map(title);
					
					NPC.StopFollowingPlayer()
					
					return
				}
				else return 0.25;
			}.bindenv(this),0)
		}
	}
	::SW_RemoveDialog<-function(title,NPCName)
	{
		local NPC=GetNamedEnt(NPCName)
	
		Hooks.Remove("Dialogue_"+title,"1")

		if (!NPC)
		{
			error("Tried to remove dialogue of non-existing NPC "+NPCName)
			return
		}
		
		NPC.GetOrCreatePrivateScriptScope().rawdelete("InputUse")
		SW_DIALOGUE_NPCS.remove(SW_DIALOGUE_NPCS.find(NPC.entindex()))
		return;
	}
	
	::SW_AddDialog<-Dialog.bindenv(this)
	::InputAddDialogue<-function()
	{
		local options=split(parameter," ")
		options[2]=compilestring("return "+options[2]).call(this)
		SW_AddDialog(options[0],options[1],options[2],(options.len()>3) ? options[3] : false)
	}

	function Hideme()
	{
		NetMsg.Start("HideDialogue");
		NetMsg.Send(player, true);
	}
	
	
	Convars.RegisterCommand( "testdialogue", function(_)
	{
		Map()
	}.bindenv(this), "", FCVAR_CLIENTDLL );
	
	local posa=null
}
function Think()
{
	local pleer=Entities.FindByName(null,"PlayerModel")
	if (pleer)
	{
		if (pleer.GetSequence()==755) pleer.SetSequence(762)
	}
	return 0.02
}
