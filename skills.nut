IncludeScript("utils/text.nut")

::SKILLS<-{}
::SKILLS_ORDER<-[]
class Skill
{
	Name=""
	Description=""
	X=0
	ExactX=0
	Y=0
	ExactY=0
	Unlocked=false
	Required=null
	Preview="vgui/"
	RequirementGlowTime=-10
	Color=Vector(0,0,0)
	UnlockTime=-10
	UnlockAction=null
	
	
	constructor(name,desc,x,y,c,required=null,previ=0,action=null) {
		Name=name
		Description=desc
		Preview="vgui/"+previ
		X=x
		Y=y
		Color=c
		Required=required
		RequirementGlowTime=Time()-10
		UnlockAction=action;
		if (CLIENT_DLL) {
		ExactX=x*YRES(48)+XRES(64)+YRES(56)
		ExactY=y*YRES(48)+YRES(48)+YRES(64)
		}
	}
	
	function Unlock()
	{
		if (Required)
		{
			if (!SKILLS[Required].Unlocked) return -1
		}
		if (PlayerSkillPoints<1) return -2;
		Unlocked=true
		UnlockTime=Time()
		if (SERVER_DLL) printl("SERVER: Unlocked "+Name)
		if (CLIENT_DLL) printl("CLIENT: Unlocked "+Name)
		if (UnlockAction) UnlockAction();
		return 1
	}
	
	function ForceUnlock()
	{
		Unlocked=true
		UnlockTime=Time()
		if (SERVER_DLL) printl("SERVER: Unlocked "+Name)
		if (CLIENT_DLL) printl("CLIENT: Unlocked "+Name)
		if (UnlockAction) UnlockAction();
		return 1
	}
	
	function CanUnlock()
	{
		if (Required)
		{
			if (!SKILLS[Required].Unlocked) return false
		}
		if (PlayerSkillPoints<1) return false;
		return true
	}
	
	function GetID()
	{
		foreach (k,s in SKILLS)
		{
			if (s==this) return k
		}
		return "nul"
	}
	function MarkRequirement()
	{
		RequirementGlowTime=Time()
	}
}

SKILLS.BulletTimeAbility<-Skill("Tachypsychia","When active (Z key by default), gradually slows down time along with you at cost of Heat, allowing you to react faster.\n",2,0,Vector(255, 25, 196),null,"slowmo1")
SKILLS.Kick<-Skill("Kicking","Gives you ability to kick things (X key by default)<br>Consumes stamina. Damage depends on speed.",0,0,Vector(255, 235, 16),null,"kick1")
SKILLS.Kick2<-Skill("God Leg","Kicking while jumping becomes deadly.<br><br>Combined with proper timing and speed, you can send your enemies flying.",0,1,Vector(255, 235, 16),"Kick","kick2")
//SKILLS.BulletTimeAbility2<-Skill("True BulletTime","You reload weapons in real time while\nBulletTime is active.",0,1,Vector(255, 25, 196),"BulletTimeAbility","slowmo2")
//SKILLS.AmmoCapacity<-Skill("Walking Arsenal","Doubles maximum ammo capacity.",2,1,Vector(255, 75, 15),"BulletTimeAbility3","ammo")
//SKILLS.BReloading<-Skill("Backpack Reloading","Holstered weapons reload on their own after 3 seconds.",2,2,Vector(255, 75, 15),"AmmoCapacity","reload")
SKILLS.BulletTimeAbility3<-Skill("Heat Capacity I","Increases your maximum Heat.",1,0,Vector(225, 10, 25),null,"heat1",function () {PlayerMaxHeat=85})
SKILLS.BulletTimeAbility5<-Skill("Thick Skin I","Slightly increases your maximum health.",3,0,Vector(35, 240, 25),null,"hp1",function () {ChangePlayerMaxHealth(110)})
SKILLS.BulletTimeAbility6<-Skill("Thick Skin II","Moderately increases your maximum health.",3,1,Vector(35, 240, 25),"BulletTimeAbility5","hp2",function () {ChangePlayerMaxHealth(125)})
SKILLS.BulletTimeAbility7<-Skill("Thick Skin III","Considerably increases your maximum health.<br><br>Jack is much tougher now.",3,2,Vector(35, 240, 25),"BulletTimeAbility6","hp2",function () {ChangePlayerMaxHealth(145)})
SKILLS.BulletTimeAbility4<-Skill("Heat Capacity II","Increases your maximum Heat even further.",1,1,Vector(225, 10, 25),"BulletTimeAbility3","heat2",function () {PlayerMaxHeat=120})
SKILLS.Dual<-Skill("Ambidextrous","Gives you ability to dual wield pistols<br><br>You can select 2 pistols by pressing their slot number keys at same time.",4,0,Vector(255, 60, 5),null,"ammo")

foreach (name, skill in SKILLS) SKILLS_ORDER.append(name)

SKILLS.StaminaRecovery<-Skill("Diaphragmatic Breathing","By using proper breathing technique, your stamina gets restored faster when standing still.",5,0,Vector(25, 165, 255),null,"slowmo3")
SKILLS_ORDER.append("StaminaRecovery")

SKILLS.HeatFinisher<-Skill("Heat Finisher","Finish off an enemy with a devastating melee attack by looking at them and pressing V.<br><br>Requires a filled Heat bar.",2,1,Vector(255, 25, 196),"BulletTimeAbility","heatfinisher")
SKILLS_ORDER.append("HeatFinisher")


Convars.RegisterConvar( "sourceworld_skills_use_orbs" "0", "0 sourceworld_skills_use_orbs", FCVAR_ARCHIVE )

::BulletTimeSpeed<-0.66

	
::BulletTime<-function()
{
	//printl(SKILLS.BulletTimeAbility.Unlocked)
	
	//	FIX ME FIX ME FIX ME
	//
	//
	//	STOP CHANGINE PLAYER'S COLLISION GROUP
	//	IT BUGS THE PROP_DOORS IN MAPGEN
	//
	//
	
	
	if (Entities.FindByName(null,"bt_cc")==null)
	{
		CC_T<-{targetname="bt_cc",filename="sw_death.raw",minfalloff=-1,maxfalloff=-1,fadeInDuration=0.05,StartDisabled=1,fadeOutDuration=0.05}
		CC<-SpawnEntityFromTable("color_correction",CC_T)
	}
	BulletTimeSpeed<-0.66
	if (!SKILLS.BulletTimeAbility.Unlocked) return;
	if (AbilitiesActive)
	{
		printl("stop")
		EntFireByHandle(CC,"disable")
			Convars.SetFloat("mat_bloom_scalefactor_scalar",1)
			EntFireByHandle(player,"setcollisiongroup","5",0)
			EntFireByHandle(player,"setcollisiongroup","5",0.5)
			AbilitiesActive=false
			Convars.SetFloat("host_pitchscale",1)
			SendToConsole("mat_local_contrast_scale_override 0")
			player.GetViewModel(0).StopSound("BulletTime.Loop")
			player.GetViewModel(0).EmitSound("BulletTime.Stop")
			player.GetViewModel(0).StopSound("BulletTime.Loop")
			
			Convars.SetFloat("mat_autoexposure_min",70.5)
			Convars.SetFloat("mat_depth_blur_strength_override",0)
			player.SetFOV(Convars.GetFloat("fov_desired")+2,0.05)
			Entities.First().SetContextThink("BulletTimeS",function(_) {Convars.SetFloat("mat_autoexposure_min",0.5);player.SetFOV(Convars.GetFloat("fov_desired"),0.15)}.bindenv(this),0.05)
	
			
			SendToConsole("host_timescale 1")
			player.GetActiveWeapon().SetPlaybackRate(1)
			Entities.First().SetContextThink("BulletTime2",function(_) {}.bindenv(this),0)
			SyncPlayerStats();
			return 0.01
	}
	
	EffectTable<-{
	targetname="bt_effect",
	type=0
	}
	
	ScrFX<-Entities.FindByName(null,"bt_effect")
	
	if (!ScrFX) ScrFX<-SpawnEntityFromTable("env_screeneffect",EffectTable);
	EntFireByHandle(ScrFX,"StartEffect",2,0)
	EntFireByHandle(ScrFX,"StopEffect",0.2,0)
	
	if (PlayerHeat<17) 
	{
		printl("LOW HEAT")
		return
	}
	SyncPlayerStats()
	SendToConsole("host_timescale 1")
	SendToConsole("mat_local_contrast_scale_override -0.08")
	SendToConsole("host_pitchscale 1")
	//player.GetViewModel(0).EmitSound("BulletTime.Start")
	player.GetViewModel(0).EmitSound("BulletTime.Loop")
	player.GetViewModel(0).EmitSound("BulletTime.Loop")
	Convars.SetFloat("mat_autoexposure_min",200.5)
	Convars.SetFloat("mat_bloom_scalefactor_scalar",3)
	
	EntFireByHandle(CC,"Enable")
	
	player.SetFOV(91,0.05)
	Entities.First().SetContextThink("BulletTimeS",function(_) {Convars.SetFloat("mat_autoexposure_min",0.5);player.SetFOV(Convars.GetFloat("fov_desired"),0.15)}.bindenv(this),0.05)
	
	if (Convars.GetFloat("host_pitchscale")==1) SendToConsole("host_pitchscale 0.8")
	SendToConsole("host_timescale 0.3")
	Entities.First().SetContextThink("BulletTime",function(_) 
	{ 
		if (!AbilitiesActive) return
		if (PlayerHeat<=0) 
		{	
			//printl("stop2")
			EntFireByHandle(player,"setcollisiongroup","5",0)
			EntFireByHandle(player,"setcollisiongroup","5",0.5)
			AbilitiesActive=false
			SyncPlayerStats();
			player.GetViewModel(0).EmitSound("BulletTime.Stop")
			
			Convars.SetFloat("mat_autoexposure_min",70.5)
			Convars.SetFloat("mat_bloom_scalefactor_scalar",3)
			SendToConsole("mat_local_contrast_scale_override 0")
			player.SetFOV(Convars.GetFloat("fov_desired")+2,0.05)
			Entities.First().SetContextThink("BulletTimeS",function(_) {Convars.SetFloat("mat_autoexposure_min",0.5);player.SetFOV(Convars.GetFloat("fov_desired"),0.15)}.bindenv(this),0.05)
	
			
			//player.GetViewModel(0).StopSound("BulletTime.Loop")
			SendToConsole("host_timescale 1")
			Convars.SetFloat("mat_depth_blur_strength_override",0)
			EntFireByHandle(CC,"disable")
			Entities.First().SetContextThink("BulletTime",function() {}.bindenv(this),0)
			return 0.01
		}	
		if (PlayerHeat<0) return;
		//printl("boobs");
		SyncPlayerStats();
		//SendToConsole("host_timescale 1")
		//player.GetViewModel(0).EmitSound("BulletTime.Loop")
		if (Convars.GetFloat("host_pitchscale")==1) Convars.SetFloat("host_pitchscale",0.8)
		//SendToConsole("host_timescale 0.3")
		return 0.5
	}.bindenv(this),0.5)
	Entities.First().SetContextThink("BulletTime2",function(_) 
	{ 
		if (!AbilitiesActive) return
		PlayerHeat-=0.33;
		SyncPlayerStats();
		//printl(PlayerHeat)
		if (PlayerHeat<=0) 
		{	
			//printl("stop")
			Convars.SetFloat("mat_bloom_scalefactor_scalar",1)
			EntFireByHandle(player,"setcollisiongroup","5",0)
			AbilitiesActive=false
			Convars.SetFloat("host_pitchscale",1)
			player.GetViewModel(0).StopSound("BulletTime.Loop")
			player.GetViewModel(0).EmitSound("BulletTime.Stop")
			SendToConsole("host_timescale 1")
			EntFireByHandle(CC,"disable")
			
			Convars.SetFloat("mat_autoexposure_min",70.5)
			SendToConsole("mat_local_contrast_scale_override 0")
			//Convars.SetFloat("mat_bloom_scalefactor_scalar",3)
			player.SetFOV(Convars.GetFloat("fov_desired")+2,0.05)
			Entities.First().SetContextThink("BulletTimeS",function(_) {Convars.SetFloat("mat_autoexposure_min",0.5);player.SetFOV(Convars.GetFloat("fov_desired"),0.15)}.bindenv(this),0.05)
			Convars.SetFloat("mat_depth_blur_strength_override",0)
			
			player.GetActiveWeapon().SetPlaybackRate(1)
			
			Entities.First().SetContextThink("BulletTime2",function() {}.bindenv(this),0)
			return 0.01
		}	
		
		Convars.SetFloat("mat_depth_blur_strength_override",0+(0.5-clamp(PlayerHeat/20.0,0,0.5)))
		
		if ((0.5-clamp(PlayerHeat/20.0,0,0.5))>0.1)
		{
			EntFireByHandle(ScrFX,"StartEffect",2,0)
			EntFireByHandle(ScrFX,"StopEffect",0.2,0)
		}
		
		EntFireByHandle(player.GetActiveWeapon(),"changevariable","m_bNeedPump false",0)
		EntFireByHandle(player,"setcollisiongroup","14",0+RandomFloat(0,0.2))
		//printl(2+6*SKILLS["BulletTimeDodge"].Unlocked.tointeger())
		if (RandomInt(0,10)>(2)) EntFireByHandle(player,"setcollisiongroup","5",0.3+RandomFloat(0,0.2))
		if (player.GetActiveWeapon().GetSequenceName(player.GetActiveWeapon().GetSequence()).find("pump")!=null) 
		{
			printl("pumping")
			EntFireByHandle(player.GetActiveWeapon(),"changevariable","m_bNeedPump false",0)
			EntFireByHandle(player,"changevariable","m_flNextAttack "+(Time()+player.GetActiveWeapon().GetFireRate()*BulletTimeSpeed)/4,0.02)
			EntFireByHandle(player,"changevariable","m_flNextPrimaryAttack "+(Time()+player.GetActiveWeapon().GetFireRate()*BulletTimeSpeed)/4,0.02)
		}
		EntFireByHandle(player.GetActiveWeapon(),"changevariable","m_flSoonestPrimaryAttack "+(Time()+player.GetActiveWeapon().GetFireRate()/3*BulletTimeSpeed-0.05))
		//player.GetViewModel(0).SetPlaybackRate(1/BulletTimeSpeed)
		//printl(player.GetActiveWeapon().GetSequenceName(player.GetActiveWeapon().GetSequence())+"primary! "+player.GetActiveWeapon().NextPrimaryAttack())
		//printl("cycle! "+player.GetViewModel(0).GetCycle())
		//player.GetActiveWeapon().SetPlaybackRate(1/BulletTimeSpeed)
		
		NotShotgunReload<-(player.GetActiveWeapon().GetSequenceName(player.GetActiveWeapon().GetSequence()).find("reload1")==null)&&(player.GetActiveWeapon().GetSequenceName(player.GetActiveWeapon().GetSequence()).find("reload3")==null)&&(player.GetActiveWeapon().GetSequenceName(player.GetActiveWeapon().GetSequence()).find("reload2")==null)
		
		//if (NotShotgunReload&&player.GetActiveWeapon().GetSequenceName(player.GetActiveWeapon().GetSequence()).find("eload")!=null) player.GetActiveWeapon().SetNextSecondaryAttack(clamp(player.GetActiveWeapon().NextSecondaryAttack(),Time()-11,Time()+player.GetActiveWeapon().GetViewModelSequenceDuration()*BulletTimeSpeed));
		//else player.GetActiveWeapon().SetNextSecondaryAttack(clamp(player.GetActiveWeapon().NextSecondaryAttack(),Time()-11,Time()+player.GetActiveWeapon().GetFireRate()*BulletTimeSpeed));
		//if (NotShotgunReload&&player.GetActiveWeapon().GetSequenceName(player.GetActiveWeapon().GetSequence()).find("eload")!=null) player.GetActiveWeapon().SetNextPrimaryAttack(clamp(player.GetActiveWeapon().NextPrimaryAttack(),Time()-11,Time()+player.GetActiveWeapon().GetViewModelSequenceDuration()*BulletTimeSpeed));
		//else player.GetActiveWeapon().SetNextPrimaryAttack(clamp(player.GetActiveWeapon().NextPrimaryAttack(),Time()-11,Time()+player.GetActiveWeapon().GetFireRate()*BulletTimeSpeed));
		//player.SetPlaybackRate(1/BulletTimeSpeed)
		//if  (NotShotgunReload&&player.GetActiveWeapon().GetSequenceName(player.GetActiveWeapon().GetSequence()).find("eload")!=null&&player.GetViewModel(0).GetCycle()>0.99) {player.GetActiveWeapon().SetSequence(0);EntFireByHandle(player,"changevariable","m_flNextAttack "+player.GetActiveWeapon().NextSecondaryAttack());
		//printl("BOOOO")
		//}
		//printl("primary after! "+player.GetActiveWeapon().NextPrimaryAttack())
		//printl("sec after! "+player.GetActiveWeapon().NextSecondaryAttack())
		//printl("idle after! "+player.GetActiveWeapon().GetWeaponIdleTime())
		//printl("  "+Time())
		if (PlayerHeat>0) return 0.001;
	}.bindenv(this),0.01)
	AbilitiesActive=true
}


if (CLIENT_DLL)
{
    // === ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ВКЛАДКИ SKILLS ===
    SKILLS_Selected       <- null        // текущий выбранный навык
    SKILLS_Unlocking      <- false       // идёт ли удержание ЛКМ для разблокировки
    SKILLS_UnlockingTime  <- -10
    SKILLS_LastUnlockTime <- -10
    SKILLS_SPGlowTime     <- -10
    SKILLS_CurX           <- XRES(320)
    SKILLS_CurY           <- YRES(240)
    SKILLS_HoverTime      <- -10
	SKILLS_STime          <- 0

        // Шрифты, аналогичные инвентарю и квестам
    local SkillFont1 = surface.GetFont("Smol", true)          // заголовки
    local SkillFontS = surface.GetFont("Smolss", true)    // тень заголовков
    local SkillFont2 = surface.GetFont("VerySmol", true) // описание
    local SkillFontBig = surface.GetFont("StatusEffectName8", true) // Skill Points

    local OrbTexture          = surface.ValidateTexture("vgui/orb", true, false, false)
    local OrbUnlockedTexture  = surface.ValidateTexture("vgui/glow", true, false, false)
    local GlowSprite          = surface.ValidateTexture("vgui/glow", true, false, false)
    local Slowmo              = surface.ValidateTexture("vgui/slowmo1", true, false, false)

    if (Convars.GetBool("sourceworld_skills_use_orbs"))
        OrbUnlockedTexture = surface.ValidateTexture("vgui/orb_unlocked", true, false, false)

    SKILLS_DrawMenu <- function(Cell, CurX, CurY, TitleFont, TitleFontS, StatusFont, StatusFont4, FRAME_X, FRAME_Y, FRAME_WIDE, FRAME_HEIGHT, TitleHeight)
    {
        // Обновляем текстуры (могут меняться из-за конвара)
        if (Convars.GetBool("sourceworld_skills_use_orbs"))
            OrbUnlockedTexture = surface.ValidateTexture("vgui/orb_unlocked", true, false, false)
        else
            OrbUnlockedTexture = surface.ValidateTexture("vgui/glow", true, false, false)

        local PadX = YRES(6)
        local PadTop = TitleHeight + YRES(6)
        local PadBottom = YRES(4)
        local ContentX = FRAME_X + PadX
        local ContentY = FRAME_Y + PadTop
        local ContentW = FRAME_WIDE - PadX * 2
        local ContentH = FRAME_HEIGHT - PadTop - PadBottom

        local TreeW = ContentW * 0.6
        local InfoW = ContentW - TreeW - YRES(6)
        local InfoX = ContentX + TreeW + YRES(6)

        local marginX = ContentX + YRES(4)
        local marginY = ContentY + YRES(4)

        // === ФОН ===
        // Базовая заливка — как в инвентаре (5, 15, 23)
        surface.SetColor(5, 15, 23, 255)
        surface.DrawFilledRect(ContentX, ContentY, ContentW, ContentH)

        // Мягкий градиент: тёмный верх → светлый низ (голубоватый)
        surface.SetColor(0, 0, 0, 255)
        surface.DrawFilledRectFade(ContentX, ContentY, ContentW, ContentH * 0.6, 100, 0, false)
        surface.SetColor(0, 50, 90, 50)
        surface.DrawFilledRectFade(ContentX, ContentY + ContentH * 0.4, ContentW, ContentH * 0.6, 0, 100, false)

        // Боковая виньетка
        local Border = YRES(80)
        surface.SetColor(0, 0, 0, 100)
        surface.DrawFilledRectFade(ContentX, ContentY, Border, ContentH, 160, 0, true)
        surface.DrawFilledRectFade(ContentX + ContentW - Border, ContentY, Border, ContentH, 0, 160, true)

        // === ПЛАВАЮЩИЕ ТОЧКИ ПО ФОНУ ===
        surface.SetColor(0, 160, 250, 2)
        local bgfx = sqrt(fabs(sin(clamp(Time() - SKILLS_LastUnlockTime, 0, 1.1))))
        for (local x = ContentX + XRES(10); x < ContentX + ContentW - XRES(2); x += XRES(12))
        {
            for (local y = ContentY + YRES(14); y < ContentY + ContentH - YRES(4); y += XRES(12))
            {
                surface.DrawOutlinedCircle(x, y, bgfx * YRES(17), 4)
            }
        }

        // === СКАН-ЛИНИИ (эстетика инвентаря) ===
        surface.SetColor(0, 0, 0, 60)
        for (local y = ContentY; y < ContentY + ContentH; y += YRES(4))
        {
           surface.DrawFilledRect(ContentX, y, ContentW, YRES(1))
        }


        // Тонкая внутренняя рамка панели
        surface.SetColor(0, 60, 110, 180)
        surface.DrawOutlinedRect(ContentX, ContentY, ContentW, ContentH, YRES(1))

                // === ДЕРЕВО ===
        // Более тёмная заливка
        surface.SetColor(2, 8, 14, 255)
        surface.DrawFilledRect(ContentX + YRES(2), ContentY + YRES(2), TreeW - YRES(4), ContentH - YRES(4))

        // Анимированные волны (горизонтальные полосы с медленным смещением)
        for (local i = 0; i < 16; i++)
        {
            local waveY = ContentY + YRES(2) + ((i * ContentH / 16.0) + sin(Time() * 0.4 + i * 0.7) * YRES(8))
            local alpha = 15 + 10 * sin(Time() * 0.6 + i)
            surface.SetColor(0+i, 60+i, 100+i, alpha*0.2)
            surface.DrawFilledRect(ContentX + YRES(2), waveY, TreeW - YRES(4), YRES(2))
        }

        // Медленно движущийся радиальный градиент (цвет навыка)
        if (SKILLS_Selected)
        {
            local glowCX = marginX + SKILLS_Selected.X * YRES(48) + YRES(24)
            local glowCY = marginY + SKILLS_Selected.Y * YRES(48) + YRES(24)
            for (local layer = 6; layer >= 0; layer--)
            {
                local size = XRES(30) + layer * XRES(20) + sin(Time() * 1.2 + layer) * XRES(4)
                local alpha = 8 - layer
                if (alpha < 0) alpha = 0
                surface.SetColor(
                    clamp(SKILLS_Selected.Color.x * 0.15, 0, 255),
                    clamp(SKILLS_Selected.Color.y * 0.15, 0, 255),
                    clamp(SKILLS_Selected.Color.z * 0.15, 0, 255),
                    alpha * 4)
                surface.DrawOutlinedCircle(glowCX, glowCY, size, 16)
            }
        }

        // Верхний мягкий градиент
        surface.SetColor(0, 40, 70, 40)
        surface.DrawFilledRectFade(ContentX + YRES(2), ContentY + YRES(2),
            TreeW - YRES(4), ContentH * 0.4, 100, 0, false)

        // Рамка дерева
        surface.SetColor(0, 60, 110, 220)
        surface.DrawOutlinedRect(ContentX, ContentY, TreeW, ContentH, YRES(1))

        // Уголки дерева — акцент (голубые, как в инвентаре)
        local cornerLen = YRES(8)
        surface.SetColor(0, 190, 255, 220)
        // TL
        surface.DrawFilledRect(ContentX, ContentY, cornerLen, YRES(1))
        surface.DrawFilledRect(ContentX, ContentY, YRES(1), cornerLen)
        // TR
        surface.DrawFilledRect(ContentX + TreeW - cornerLen, ContentY, cornerLen, YRES(1))
        surface.DrawFilledRect(ContentX + TreeW - YRES(1), ContentY, YRES(1), cornerLen)
        // BL
        surface.DrawFilledRect(ContentX, ContentY + ContentH - YRES(1), cornerLen, YRES(1))
        surface.DrawFilledRect(ContentX, ContentY + ContentH - cornerLen, YRES(1), cornerLen)
        // BR
        surface.DrawFilledRect(ContentX + TreeW - cornerLen, ContentY + ContentH - YRES(1), cornerLen, YRES(1))
        surface.DrawFilledRect(ContentX + TreeW - YRES(1), ContentY + ContentH - cornerLen, YRES(1), cornerLen)

        // === ЗАВИСИМОСТИ ===
        foreach (Skill in SKILLS)
        {
            if (!Skill.Required) continue
            local SkillX = marginX + Skill.X * YRES(48)
            local SkillY = marginY + Skill.Y * YRES(48)
            local ReqX = marginX + SKILLS[Skill.Required].X * YRES(48)
            local ReqY = marginY + SKILLS[Skill.Required].Y * YRES(48)

            surface.SetColor(Skill.Color.x, Skill.Color.y, Skill.Color.z, 55)
			
			if (!SKILLS[Skill.Required].Unlocked) surface.SetColor(Skill.Color.x, Skill.Color.y, Skill.Color.z, 1)
			
            if ((Time() - Skill.RequirementGlowTime) < 1 && (Time() * 14).tointeger() % 2 < 1)
                surface.SetColor(250, 20, 15, 255)

            // Толстые линии связи
            surface.DrawLine(SkillX + YRES(24), SkillY + YRES(24), ReqX + YRES(24), ReqY + YRES(24))
            for (local i = 1; i < 3; i++)
            {
                surface.DrawLine(SkillX + YRES(24) + i, SkillY + YRES(24), ReqX + YRES(24), ReqY + YRES(24))
                surface.DrawLine(SkillX + YRES(24) - i, SkillY + YRES(24), ReqX + YRES(24), ReqY + YRES(24))
                surface.DrawLine(SkillX + YRES(24), SkillY + YRES(24) + i, ReqX + YRES(24), ReqY + YRES(24))
                surface.DrawLine(SkillX + YRES(24), SkillY + YRES(24) - i, ReqX + YRES(24), ReqY + YRES(24))
            }

            // Пульсация вокруг требуемого навыка
            for (local i = 1; i < 20 - (Time() - Skill.RequirementGlowTime) * 40; i++)
            {
                surface.DrawOutlinedCircle(ReqX + YRES(24), ReqY + YRES(24), XRES(10), 66)
                surface.DrawLine(SkillX + YRES(24), SkillY + YRES(24), ReqX + YRES(24) + i, ReqY + YRES(24))
                surface.DrawLine(SkillX + YRES(24), SkillY + YRES(24), ReqX + YRES(24) - i, ReqY + YRES(24))
                surface.DrawLine(SkillX + YRES(24), SkillY + YRES(24), ReqX + YRES(24), ReqY + YRES(24) + i)
                surface.DrawLine(SkillX + YRES(24), SkillY + YRES(24), ReqX + YRES(24), ReqY + YRES(24) - i)
            }

            // Орбы зависимостей
            surface.SetColor(0, 0, 0, 255)
            surface.SetTexture(OrbTexture)
            if (Skill.Unlocked) surface.SetTexture(OrbUnlockedTexture)
            surface.DrawTexturedRect(SkillX + YRES(24) - XRES(8), SkillY + YRES(24) - XRES(8), XRES(16), XRES(16))
            if (SKILLS[Skill.Required].Unlocked) surface.SetTexture(OrbUnlockedTexture)
            surface.DrawTexturedRect(ReqX + YRES(24) - XRES(8), ReqY + YRES(24) - XRES(8), XRES(16), XRES(16))
        }

        // === ОРБЫ НАВЫКОВ ===
        foreach (Skill in SKILLS)
        {
            local SkillX = marginX + Skill.X * YRES(48)
            local SkillY = marginY + Skill.Y * YRES(48)
            local ColorReductor = (1 + 1 * (!Skill.Unlocked).tointeger())
			
			local CanUpgrade = (PlayerSkillPoints > 0)
            if (Skill.Required) CanUpgrade = (PlayerSkillPoints > 0 && SKILLS[Skill.Required].Unlocked)

			ColorReductor = (1 + 5 * (!CanUpgrade).tointeger())
			
			if (Skill.Unlocked) ColorReductor = 1;

            surface.SetTexture(OrbTexture)
            if (Skill.Unlocked) surface.SetTexture(OrbUnlockedTexture)
            surface.SetColor(Skill.Color.x / ColorReductor, Skill.Color.y / ColorReductor, Skill.Color.z / ColorReductor,
                200 + 55 * fabs(sin(Time() * 1.5)))

            if (Skill.Unlocked)
                surface.DrawTexturedRectRotated(SkillX + YRES(24) - XRES(9), SkillY + YRES(24) - XRES(9),
                    XRES(18), XRES(18), Time() * 20 * (!Convars.GetBool("sourceworld_skills_use_orbs")).tointeger())
            else
                surface.DrawTexturedRect(SkillX + YRES(24) - XRES(9), SkillY + YRES(24) - XRES(9), XRES(18), XRES(18))

                        // Glow при недавнем анлоке — только если навык был разблокирован в последние 2 секунды
            // UnlockTime == -10 у неразблокированных, поэтому timeSinceUnlock > 10 — фильтр ниже
            local timeSinceUnlock = Time() - Skill.UnlockTime
            if (Skill.Unlocked && timeSinceUnlock >= 0 && timeSinceUnlock < 2.0)
            {
                surface.SetTexture(GlowSprite)
                local Size
                if (timeSinceUnlock > 0.1)
                    Size = XRES(128) - clamp((timeSinceUnlock - 0.1) * XRES(128), 0, XRES(128))
                else
                    Size = XRES(32) + 4 * clamp(timeSinceUnlock * XRES(128), 0, XRES(128))

                surface.SetColor(Skill.Color.x, Skill.Color.y, Skill.Color.z, 200)
                surface.DrawTexturedRectRotated(SkillX + YRES(24) - Size/2, SkillY + YRES(24) - Size/2, Size, Size, Time() * 1440)
            }

            // Постоянное лёгкое свечение — только у разблокированных
            if (Skill.Unlocked)
            {
                surface.SetTexture(GlowSprite)
                surface.SetColor(Skill.Color.x / ColorReductor, Skill.Color.y / ColorReductor, Skill.Color.z / ColorReductor,
                    13 + 6 * fabs(sin(Time() * 1.5)))
                local Size = XRES(128)
                surface.DrawTexturedRectRotated(SkillX + YRES(24) - Size/2, SkillY + YRES(24) - Size/2, Size, Size, Time() * 20)
            }

            // Волновой эффект при разблокировке
            if (Skill==SKILLS_Selected&&SKILLS_Unlocking && (Time() - SKILLS_UnlockingTime) < 1.5)
            {
                for (local i = 1; i < (Time() - SKILLS_UnlockingTime) * 11; i += 0.2)
                {
                    surface.SetColor(10 * (Time() - SKILLS_UnlockingTime),
                        40 + clamp(5 + (pow(i, 2) - 4 * (Time() - SKILLS_UnlockingTime)) * 3, 0, 215),
                        clamp(130 - (i - 4 * (Time() - SKILLS_UnlockingTime)) * 3, 0, 255), 255)
                    if (i < 13)
                    {
                        surface.DrawOutlinedCircle(SkillX + YRES(24), SkillY + YRES(24), XRES(8) * i / 10, 4)
                        surface.DrawOutlinedCircle(SkillX + YRES(24), SkillY + YRES(24), XRES(8) * i / 10 + 1, 4)
                        surface.DrawOutlinedCircle(SkillX + YRES(24), SkillY + YRES(24), XRES(8) * i / 10 - 1, 4)
                    }
                    if (i > 8)
                    {
                        surface.DrawOutlinedCircle(SkillX + YRES(24), SkillY + YRES(24), XRES(8) * i / 10, 5)
                        surface.DrawOutlinedCircle(SkillX + YRES(24) + 1, SkillY + YRES(24) + 1, XRES(8) * i / 10, 5)
                        surface.DrawOutlinedCircle(SkillX + YRES(24) - 1, SkillY + YRES(24) - 1, XRES(8) * i / 10, 5)
                    }
                }
            }

            // Кольца
            local CanUpgrade = (PlayerSkillPoints > 0)
            if (Skill.Required) CanUpgrade = (PlayerSkillPoints > 0 && SKILLS[Skill.Required].Unlocked)
            local CanUpgradeF = CanUpgrade.tointeger() / 3.0

            surface.SetColor(Skill.Color.x, Skill.Color.y, Skill.Color.z,
                (100 * fabs(sin(Time())) + 155) * Skill.Unlocked.tointeger())
            surface.DrawOutlinedCircle(SkillX + YRES(24), SkillY + YRES(24), XRES(14), 5)
            surface.DrawOutlinedCircle(SkillX + YRES(24), SkillY + YRES(24), XRES(14) + 1, 5)

            surface.SetColor(Skill.Color.x, Skill.Color.y, Skill.Color.z,
                CanUpgradeF * 80 * fabs(cos(Time() - 1.2)) + 100 * Skill.Unlocked.tointeger())
            surface.DrawOutlinedCircle(SkillX + YRES(24), SkillY + YRES(24), XRES(14), 66)
            surface.DrawOutlinedCircle(SkillX + YRES(24), SkillY + YRES(24), XRES(14) + 1, 66)

            surface.SetColor((Skill.Color.x + 150)/6, (Skill.Color.y + 150)/6, (Skill.Color.z + 150)/6, 65)
            if (Skill.Unlocked)
                surface.SetColor((Skill.Color.x + 150)/2, (Skill.Color.y + 150)/2, (Skill.Color.z + 150)/2, 125)
            surface.DrawOutlinedCircle(SkillX + YRES(24), SkillY + YRES(24), XRES(10), 66)
            surface.DrawOutlinedCircle(SkillX + YRES(24), SkillY + YRES(24), XRES(10) + 1, 66)
        }

        // === ИНФО-ПАНЕЛЬ ===
        local InfoY = ContentY
        local InfoH = ContentH

        // Цвет панели — производный от цвета навыка
        local panelR, panelG, panelB
        local borderR, borderG, borderB
        if (SKILLS_Selected)
        {
            // Базовая панель — очень тёмная версия цвета навыка
            panelR = SKILLS_Selected.Color.x * 0.06
            panelG = SKILLS_Selected.Color.y * 0.06
            panelB = SKILLS_Selected.Color.z * 0.06
            // Рамка — насыщенный, но не ядовитый цвет
            borderR = clamp(SKILLS_Selected.Color.x * 0.7, 0, 255)
            borderG = clamp(SKILLS_Selected.Color.y * 0.7, 0, 255)
            borderB = clamp(SKILLS_Selected.Color.z * 0.7, 0, 255)
        }
        else
        {
            panelR = 0; panelG = 10; panelB = 22
            borderR = 0; borderG = 60; borderB = 100
        }

        surface.SetColor(panelR, panelG, panelB, 255)
        surface.DrawFilledRect(InfoX, InfoY, InfoW, InfoH)
		        // Градиентное свечение по бокам (цвет навыка)
        if (SKILLS_Selected)
        {
            local glowR = clamp(SKILLS_Selected.Color.x * 0.05, 0, 55)
            local glowG = clamp(SKILLS_Selected.Color.y * 0.05, 0, 55)
            local glowB = clamp(SKILLS_Selected.Color.z * 0.05, 0, 55)
			
			if (SKILLS_Selected.Unlocked)
			{
				glowR = clamp(SKILLS_Selected.Color.x * 0.2, 0, 175)
				glowG = clamp(SKILLS_Selected.Color.y * 0.2, 0, 175)
				glowB = clamp(SKILLS_Selected.Color.z * 0.2, 0, 175)
			}

            // Левый край: от цвета к прозрачному
            surface.SetColor(glowR, glowG, glowB, 255)
            surface.DrawFilledRectFade(InfoX, InfoY, YRES(40), InfoH, 120, 0, true)

            // Правый край: от прозрачного к цвету
            surface.SetColor(glowR, glowG, glowB, 255)
            surface.DrawFilledRectFade(InfoX + InfoW - YRES(40), InfoY, YRES(40), InfoH, 0, 120, true)

        }

               // Мигающие "полосы" при выбранном и разблокированном навыке
        if (SKILLS_Selected && SKILLS_Selected.Unlocked)
        {
            surface.SetColor(
                clamp(SKILLS_Selected.Color.x * 0.7, 0, 255),
                clamp(SKILLS_Selected.Color.y * 0.7, 0, 255),
                clamp(SKILLS_Selected.Color.z * 0.7, 0, 255),
                105 + 150 * SKILLS_Selected.Unlocked.tointeger())
            for (local x = InfoX + YRES(8); x < InfoX + InfoW - YRES(4); x += XRES(36))
            {
                for (local y = InfoY + YRES(4); y < InfoY + InfoH - YRES(4); y += XRES(6))
                {
                    local off = ((sqrt(y) * (7 + Time() / 3)) % 3.7) * XRES(10)
                    surface.DrawFilledRect(x + off, y,
                        clamp(XRES(4), 0, InfoX + InfoW - x - off), 2)
                }
            }
        }

        // Дополнительные диагональные штрихи (параллельные, для плотности)
        if (SKILLS_Selected && SKILLS_Selected.Unlocked)
        {
            surface.SetColor(
                clamp(SKILLS_Selected.Color.x * 0.4, 0, 255),
                clamp(SKILLS_Selected.Color.y * 0.4, 0, 255),
                clamp(SKILLS_Selected.Color.z * 0.4, 0, 255),
                25)
            for (local x = InfoX + YRES(8); x < InfoX + InfoW - YRES(4); x += XRES(24))
            {
                for (local y = InfoY + YRES(4); y < InfoY + InfoH - YRES(4); y += XRES(8))
                {
                    local off = ((sqrt(y + 3) * (7 + Time() / 3)) % 3.7) * XRES(8)
                    surface.DrawFilledRect(x + off, y,
                        clamp(XRES(2), 0, InfoX + InfoW - x - off), 1)
                }
            }
        }

        // Рамка инфо-панели — цвет навыка
        surface.SetColor(borderR, borderG, borderB, 255)
        surface.DrawOutlinedRect(InfoX, InfoY, InfoW, InfoH, YRES(1))

                // === ЗАГОЛОВКИ-ПОЛОСЫ ===
        surface.SetColor(borderR, borderG, borderB, 14)
        surface.DrawFilledRect(InfoX + YRES(4), InfoY + YRES(40), InfoW - YRES(8), YRES(2))
        surface.DrawFilledRect(InfoX + YRES(4), InfoY + YRES(40) + XRES(4), InfoW - YRES(8), YRES(2))
        surface.DrawFilledRect(InfoX + YRES(4), InfoY + YRES(140), InfoW - YRES(8), YRES(2))
        surface.DrawFilledRect(InfoX + YRES(4), InfoY + YRES(140) + XRES(4), InfoW - YRES(8), YRES(2))

        local spText = "Skill Points: " + PlayerSkillPoints
        local spColor = [190, 255, 170]
        if (SKILLS_Selected && SKILLS_Selected.Unlocked)
        {
            spColor = [clamp(190 + SKILLS_Selected.Color.x, 0, 255),
                       clamp(190 + SKILLS_Selected.Color.y, 0, 255),
                       clamp(190 + SKILLS_Selected.Color.z, 0, 255)]
        }
        else if (SKILLS_Selected)
        {
            spColor = [clamp(SKILLS_Selected.Color.x * 0.2+200, 0, 255),
                       clamp(SKILLS_Selected.Color.y * 0.2+200, 0, 255),
                       clamp(SKILLS_Selected.Color.z * 0.2+200, 0, 255)]
        }

        if ((Time() - SKILLS_SPGlowTime) > 1)
        {
            surface.DrawColoredText(SkillFont1, InfoX + YRES(8), ContentY + YRES(8),
                spColor[0], spColor[1], spColor[2], 255, spText)
        }
        else if ((Time() * 14).tointeger() % 2 < 1)
        {
            surface.DrawColoredText(SkillFont1, InfoX + YRES(8) + RandomInt(-2, 2), ContentY + YRES(8) + RandomInt(-2, 2),
                255, 15, 10, 255, spText)
        }
        else
        {
            surface.DrawColoredText(SkillFont1, InfoX + YRES(8) + RandomInt(-2, 2), ContentY + YRES(8) + RandomInt(-2, 2),
                255, 15, 10, 255, spText + "<")
        }

        // === ИНФО О НАВЫКЕ ===
        if (SKILLS_Selected)
        {
            // Цвет всегда соответствует навыку, но для неразблокированного — тусклее
            local nameColor
            if (SKILLS_Selected.Unlocked)
            {
                nameColor = [clamp(190 + SKILLS_Selected.Color.x, 0, 255),
                             clamp(190 + SKILLS_Selected.Color.y, 0, 255),
                             clamp(190 + SKILLS_Selected.Color.z, 0, 255)]
            }
            else
            {
                nameColor = [clamp(40 + SKILLS_Selected.Color.x*0.6, 0, 255),
                             clamp(40 + SKILLS_Selected.Color.y*0.6, 0, 255),
                             clamp(40 + SKILLS_Selected.Color.z*0.6, 0, 255)]
            }

            surface.DrawColoredText(SkillFontS, InfoX + YRES(9), InfoY + YRES(55), 0, 0, 0, 240, SKILLS_Selected.Name)
            surface.DrawColoredText(SkillFont1, InfoX + YRES(8), InfoY + YRES(54),
                nameColor[0], nameColor[1], nameColor[2], 255, SKILLS_Selected.Name)

            local dy = InfoY + YRES(80)
            local descMaxW = InfoW - YRES(20)   // ширина панели минус отступы
            local lineH = surface.GetFontTall(SkillFont2) + YRES(4)
            local descLines = GetTextInLines(SkillFont2, descMaxW, SKILLS_Selected.Description, SKILLS_Selected.Description.len())

            local lineIdx = 0
            foreach (text in descLines)
            {
                // Тень
                surface.DrawColoredText(SkillFont2, InfoX + YRES(9), dy + lineIdx * lineH + YRES(1),
                    0, 0, 0, 200, text)
                // Текст
                surface.DrawColoredText(SkillFont2, InfoX + YRES(8), dy + lineIdx * lineH,
                    nameColor[0], nameColor[1], nameColor[2], 255, text)
                lineIdx++
            }

                        // === ПРЕВЬЮ (внизу инфо-панели) ===
            local previewH = YRES(140)
            local previewW = InfoW - YRES(16)
            local previewX = InfoX + YRES(8)
            local previewY = ContentY + ContentH - previewH - YRES(8)

            local previewTex = surface.ValidateTexture(SKILLS_Selected.Preview, true, false, false)

            if (previewTex)
            {
                if (SKILLS_Selected.Unlocked)
                {
                    // ============================
                    // РАЗБЛОКИРОВАНО: живое превью
                    // ============================

                    // 1) Медленный parallax-сдвиг картинки (двигаем по горизонтали)
                    local parallaxX = sin(Time() * 0.3) * YRES(4)
                    local parallaxY = cos(Time() * 0.4) * YRES(2)

                    // surface.SetColor(255, 255, 255, 255)
                    surface.SetColor(SKILLS_Selected.Color.x,SKILLS_Selected.Color.y,SKILLS_Selected.Color.z, 255)
                    surface.SetTexture(previewTex)
                    surface.DrawTexturedRect(previewX + parallaxX, previewY + parallaxY,
                        previewW, previewH)

                    // 2) Тёмная виньетка по краям (объём)
                    surface.SetColor(0, 0, 0, 140)
                    surface.DrawFilledRectFade(previewX, previewY, previewW, YRES(18), 255, 0, false)
                    surface.DrawFilledRectFade(previewX, previewY + previewH - YRES(18),
                        previewW, YRES(18), 0, 255, false)
                    surface.DrawFilledRectFade(previewX, previewY, YRES(24), previewH, 200, 0, true)
                    surface.DrawFilledRectFade(previewX + previewW - YRES(24), previewY,
                        YRES(24), previewH, 0, 200, true)

                    // 3) Диагональный блик (медленно проезжает по превью, обрезается по границам)
                    local shinePos = (Time() * 0.4) % 1.6 - 0.3   // от -0.3 до 1.3
                    local shineW = YRES(70)
                    local shineCX = previewX + shinePos * previewW   // центр блика
                    local shineLeft = shineCX - shineW
                    local shineRight = shineCX + shineW

                    // Клиппинг по границам превью
                    local clipLeft = previewX
                    local clipRight = previewX + previewW

                    // Левая половина блика (от 0 alpha к 100)
                    local leftStart = shineLeft
                    local leftEnd = min(shineCX, clipRight)
                    if (leftStart < clipLeft) leftStart = clipLeft

                    if (leftStart < leftEnd)
                    {
                        // Рассчитываем, какая часть градиента видна
                        local t0 = (leftStart - shineLeft).tofloat() / (shineCX - shineLeft)
                        local t1 = (leftEnd - shineLeft).tofloat() / (shineCX - shineLeft)
                        local a0 = (0 + 200 * t0).tointeger()
                        local a1 = (0 + 200 * t1).tointeger()

                        surface.SetColor(5, 5, 5, 255)
                        surface.DrawFilledRectFade(leftStart, previewY, leftEnd - leftStart, previewH,
                            a0, a1, true)
                    }

                    // Правая половина блика (от 100 alpha к 0)
                    local rightStart = max(shineCX, clipLeft)
                    local rightEnd = shineRight
                    if (rightEnd > clipRight) rightEnd = clipRight

                    if (rightStart < rightEnd)
                    {
                        local t0 = (rightStart - shineCX).tofloat() / (shineRight - shineCX)
                        local t1 = (rightEnd - shineCX).tofloat() / (shineRight - shineCX)
                        local a0 = (200 - 200 * t0).tointeger()
                        local a1 = (200 - 200 * t1).tointeger()

                        surface.SetColor(5, 5, 5, 255)
                        surface.DrawFilledRectFade(rightStart, previewY, rightEnd - rightStart, previewH,
                            a0, a1, true)
                    }

                    // 4) Пульсация яркости в цвете навыка
                    local pulseAlpha = 20 + 25 * fabs(sin(Time() * 1.3))
                    surface.SetColor(
                        clamp(SKILLS_Selected.Color.x * 0.3, 0, 255),
                        clamp(SKILLS_Selected.Color.y * 0.3, 0, 255),
                        clamp(SKILLS_Selected.Color.z * 0.3, 0, 255),
                        pulseAlpha)
                    surface.DrawFilledRect(previewX, previewY, previewW, previewH)

                    // 5) Вертикальные "помехи" в цвете навыка (быстро проезжают)
                    if (RandomInt(0, 230) == 0)
                    {
                        local glitchY = previewY + RandomInt(0, previewH - YRES(4))
                        local glitchH = RandomInt(YRES(1), YRES(4))
                        local glitchOff = RandomInt(-YRES(10), YRES(10))
                        surface.SetColor(
                            clamp(SKILLS_Selected.Color.x * 0.9, 0, 255),
                            clamp(SKILLS_Selected.Color.y * 0.9, 0, 255),
                            clamp(SKILLS_Selected.Color.z * 0.9, 0, 255),
                            180)
                        surface.DrawFilledRect(previewX + glitchOff, glitchY, previewW, glitchH)
                    }

                    // 6) Тонкие горизонтальные скан-линии поверх
                    surface.SetColor(250, 250, 250, 2*fabs(sin((Time()*3)))+0)
                    for (local sy = previewY; sy < previewY + previewH; sy += YRES(3))
                    {
                        surface.DrawFilledRect(previewX, sy, previewW, YRES(1))
                    }

                    // 7) Пульсирующая рамка в цвете навыка
                    local framePulse = 0.6 + 0.4 * fabs(sin(Time() * 1.5))
                    surface.SetColor(
                        clamp(SKILLS_Selected.Color.x * framePulse, 0, 255),
                        clamp(SKILLS_Selected.Color.y * framePulse, 0, 255),
                        clamp(SKILLS_Selected.Color.z * framePulse, 0, 255),
                        255)
                    surface.DrawOutlinedRect(previewX, previewY, previewW, previewH, YRES(2))
                }
                else
                {
                    // ============================
                    // ЗАБЛОКИРОВАНО: битый сигнал
                    // ============================

                    // 1) Лёгкое дрожание картинки
                    local shakeX = RandomFloat(-1, 1) * YRES(1.5)
                    local shakeY = RandomFloat(-1, 1) * YRES(1)

					surface.SetColor(75,30,30, 255)
                    surface.SetTexture(previewTex)
                    surface.DrawTexturedRect(previewX + shakeX, previewY + shakeY,
                        previewW, previewH)

                    // 2) Затемнение
                    surface.SetColor(0, 0, 0, 190)
                    surface.DrawFilledRect(previewX, previewY, previewW, previewH)

                    // 3) Шум
                    surface.SetColor(35, 40, 55, 130)
                    surface.SetTexture(surface.ValidateTexture("vgui/radio/noise", true, false, false))
                    local offset = RandomFloat(0, 2)
                    surface.DrawTexturedSubRect(previewX, previewY,
                        previewX + previewW, previewY + previewH,
                        offset, offset, 1.2 + offset, 1 + offset)

                    // 4) Глитч-полосы (раз в ~секунду)
                    if ((Time() * 1.2).tointeger() % 2 == 0 && RandomInt(0, 3) == 0)
                    {
                        for (local g = 0; g < RandomInt(1, 4); g++)
                        {
                            local gy = previewY + RandomInt(0, previewH - YRES(6))
                            local gh = RandomInt(YRES(2), YRES(6))
                            local gx = RandomInt(-YRES(8), YRES(8))
                            surface.SetColor(RandomInt(100, 255), RandomInt(0, SKILLS_Selected.Color.y*0.5), RandomInt(0, SKILLS_Selected.Color.z*0.5), 180)
                            surface.DrawFilledRect(previewX + gx, gy, previewW, gh)
                        }
                    }

                    // 5) Скан-линии (плотнее, чем у разблокированного)
                    surface.SetColor(0, 0, 0, 70)
                    for (local sy = previewY; sy < previewY + previewH; sy += YRES(2))
                    {
                        surface.DrawFilledRect(previewX, sy, previewW, YRES(1))
                    }

                    // 6) Замок (как раньше)
                    surface.SetColor(255, 255, 255, 255)
                    local locksize = XRES(14)
                    surface.SetTexture(surface.ValidateTexture("vgui/resource/icon_ifm_track_synched", true, false, false))
                    surface.DrawTexturedRect(
                        previewX + previewW/2 - locksize/2,
                        previewY + previewH/2 - locksize/2 - YRES(8),
                        locksize, locksize)

                    // 7) Текст LOCKED
                    local lockTxt = "LOCKED"
                    local lockColor = (Time() * 3).tointeger() % 2 == 0 ? [255, 60, 60] : [0,0,0]
                    surface.DrawColoredText(SkillFont2,
                        previewX + previewW/2 - surface.GetTextWidth(SkillFont2, lockTxt)/2 + YRES(1),
                        previewY + previewH/2 + locksize/2 - YRES(2) + YRES(1),
                        0, 0, 0, 255, lockTxt)
                    surface.DrawColoredText(SkillFont2,
                        previewX + previewW/2 - surface.GetTextWidth(SkillFont2, lockTxt)/2,
                        previewY + previewH/2 + locksize/2 - YRES(2),
                        lockColor[0], lockColor[1], lockColor[2], 255, lockTxt)

                    // 8) Рамка — тускло-красная, мигает
                    local framePulse = (Time() * 2).tointeger() % 2 == 0 ? 0.5 : 0.8
                    surface.SetColor(180 * framePulse, 40 * framePulse, 40 * framePulse, 220)
                    surface.DrawOutlinedRect(previewX, previewY, previewW, previewH, YRES(2))
                }
            }
        }
        else
        {
            local midX = InfoX + InfoW/2 - surface.GetTextWidth(SkillFont1, "Select a skill")/2
            local midY = ContentY + ContentH/2 - surface.GetFontTall(SkillFont1)/2
            surface.DrawColoredText(SkillFont1, midX, midY, 50, 80, 110, 255, "Select a skill")
        }

        // === ЖЁЛТЫЙ ПЛАВАЮЩИЙ КУРСОР ===
        // Плавно летит к выбранному навыку, если он выбран; иначе — к курсору мыши.
        local targetX, targetY
        if (SKILLS_Selected)
        {
            targetX = marginX + SKILLS_Selected.X * YRES(48) + YRES(24)
            targetY = marginY + SKILLS_Selected.Y * YRES(48) + YRES(24)
        }
        else
        {
            targetX = CurX
            targetY = CurY
        }

        local distX = fabs(SKILLS_CurX - targetX)
        local distY = fabs(SKILLS_CurY - targetY)

        if (sqrt(pow(distX, 2) + pow(distY, 2)) > 50) SKILLS_STime += 24
        if (SKILLS_CurX != targetX) SKILLS_CurX += distX / 5 * (2 * (SKILLS_CurX < targetX).tointeger() - 1)
        if (SKILLS_CurY != targetY) SKILLS_CurY += distY / 5 * (2 * (SKILLS_CurY < targetY).tointeger() - 1)

        if (SKILLS_STime > 0&&SKILLS_Selected) SKILLS_STime -= 8
        if (SKILLS_STime < 0) SKILLS_STime = 0
        if (SKILLS_STime > 100) SKILLS_STime = 100

        // Цвет курсора
        surface.SetColor(250, 250, 15, 240)
        if (SKILLS_Selected && !SKILLS_Selected.Unlocked) surface.SetColor(250, 250, 15, 50 + 205)
			
		if (SKILLS_CurY<InfoY+YRES(13)) surface.SetColor(250, 250, 15, 0)

        // Кольцо курсора (пульсация через SKILLS_STime)
        for (local i = 1; i < 3; i += 0.5)
        {
            surface.DrawOutlinedCircle(SKILLS_CurX, SKILLS_CurY,
                YRES(14 + 0.4 * sin(Time() * 5) - i), 4 + SKILLS_STime / 10)
        }

        // === "ABILITY ACQUIRED!" ===
        if ((Time() - SKILLS_LastUnlockTime) < 2)
        {
            local Duration = (Time() - SKILLS_LastUnlockTime) / 2
            local txt = "Ability Acquired!"
            local w = surface.GetTextWidth(SkillFont1, txt)
            surface.SetColor(0, 0, 0, 255 - pow(Duration, 3) * 255)
            surface.DrawFilledRect(XRES(320) - w/2 - YRES(10),
                YRES(15) * (pow(Duration, 0.3) - 0.5) + YRES(230), w + YRES(20), YRES(40))
            surface.SetColor(50, 90, 70, 255 - pow(Duration, 3) * 255)
            DrawOutlinedBox(YRES(1), w + YRES(20), YRES(40),
                XRES(320) - w/2 - YRES(10), YRES(15) * (pow(Duration, 0.3) - 0.5) + YRES(230))
            surface.SetTexture(GlowSprite)
            surface.SetColor(255, 255, 30, 155 - pow(Duration, 3) * 155)
            surface.DrawTexturedRectRotated(
                XRES(320) - w/2 + YRES(15) * (pow(Duration, 0.3)),
                YRES(15) * (pow(Duration, 0.3)) + YRES(240),
                w - YRES(15) * (pow(Duration, 0.3)), XRES(20), 0)
            surface.DrawColoredText(SkillFont1, XRES(320) - w/2,
                YRES(15) * (pow(Duration, 0.3)) + YRES(235),
                255, 255, 30, 255 - pow(Duration, 3) * 255, txt)
        }
    }
    // === HOVER ===
    SKILLS_HandleHover <- function(CurX, CurY, Cell, FRAME_X, FRAME_Y, FRAME_WIDE, FRAME_HEIGHT, TitleHeight)
    {
        local PadX = YRES(6)
        local PadTop = TitleHeight + YRES(6)
        local ContentX = FRAME_X + PadX
        local ContentY = FRAME_Y + PadTop
        local marginX = ContentX + YRES(4)
        local marginY = ContentY + YRES(4)

        local found = null
        foreach (Skill in SKILLS)
        {
            local SkillX = marginX + Skill.X * YRES(48) + YRES(24)
            local SkillY = marginY + Skill.Y * YRES(48) + YRES(24)
            if (sqrt(pow(CurX - SkillX, 2) + pow(CurY - SkillY, 2)) < XRES(25))
            {
                found = Skill
                break
            }
        }

        if (found != SKILLS_Selected)
        {
            SKILLS_Selected = found
            if (found) surface.PlaySound("ui/menu_focus.wav")
        }
    }

    // === CLICK ===
    SKILLS_HandleClick <- function(a)
    {
        if (!SKILLS_Selected) return false
        if (SKILLS_Selected.Unlocked) return false
        if (a != 15 && a != 107) return false
        SKILLS_Unlocking = !SKILLS_Unlocking
        if (SKILLS_Unlocking)
        {
            SKILLS_UnlockingTime = Time()
            if (!SKILLS_Selected.CanUnlock()) return true
            surface.PlaySound("ui/skill_unlocking.wav")
        }
        return true
    }

    // === RELEASE ===
    SKILLS_HandleRelease <- function(a)
    {
        if (!SKILLS_Selected) return false
        if (SKILLS_Selected.Unlocked) return false
        if (a != 15 && a != 107) return false
        SKILLS_Unlocking = false
        surface.PlaySound("common/null.wav")
        return true
    }

    // === THINK ===
    SKILLS_ClientThink <- function()
    {
        local Preventer = false
        if (SKILLS_Selected) if (!SKILLS_Selected.CanUnlock()) Preventer = true

        if (SKILLS_Unlocking && ((Time() - SKILLS_UnlockingTime) > 1.5 || Preventer))
        {
            SKILLS_Unlocking = false
            SKILLS_UnlockingTime = Time()

            if (SKILLS_Selected.Unlock() == -1)
            {
                surface.PlaySound("ui/beep_error01.wav")
                if (SKILLS_Selected.Required) SKILLS_Selected.MarkRequirement()
                return
            }
            if (SKILLS_Selected.Unlock() == -2)
            {
                surface.PlaySound("ui/beep_error01.wav")
                SKILLS_SPGlowTime = Time()
                return
            }

            NetMsg.Start("UnlockAbility")
            NetMsg.WriteString(SKILLS_Selected.GetID())
            NetMsg.Send()

            surface.PlaySound("ui/skill_unlocked.wav")
            PlayerSkillPoints--
            SKILLS_LastUnlockTime = Time()
        }
    }
}

if (SERVER_DLL)
{
	NetMsg.Receive("UnlockAbility", function( player )
	{
		ability<-NetMsg.ReadString()
		SKILLS[ability].Unlock()
		PlayerSkillPoints--
		//printl("SERVER: Unlocked "+ability)
	} );
	
	NetMsg.Receive("ShowHint", function( player )
	{
		SWHint(NetMsg.ReadString())
	} );

}