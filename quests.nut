// quests.nut — Меню квестов

::QUESTS_MAIN <- []
::QUESTS_SIDE <- []
::QUESTS_MISSION <- []

::QUEST_SELECTED <- -1
::QUEST_SELECTED_TAB <- 0

function QuestSort(a,b)
{
	if (a.IsCompleted&&!b.IsCompleted) return 1;
	if (!a.IsCompleted&&b.IsCompleted) return -1;
	return 0;
}

::GetQuestID<-function(id)
{
	for (local i=0;i<QUESTS_MAIN.len();i++)
	{
		if (QUESTS_MAIN[i].ID==id) return i
	}
	for (local i=0;i<QUESTS_SIDE.len();i++)
	{
		if (QUESTS_SIDE[i].ID==id) return i
	}
	for (local i=0;i<QUESTS_MISSION.len();i++)
	{
		if (QUESTS_MISSION[i].ID==id) return i
	}
	return 0;
}

class Quest
{
	ID = ""
    Name = ""
    Type = ""
    Location = ""
    Goal = ""
    Desc = ""
    IsCompleted = false
    Progress = null
    
    // === Анимация ===
    AppearTime = -10.0     // когда квест появился (для fade-in)
    CompleteTime = -10.0   // когда завершился (для анимации перечёркивания)
    IsNew = false          // флаг "нового" квеста (красная точка)
    NewBlinkEnd = -10.0    // до какого времени мигать

    constructor(id, name, type, location, goal, desc)
    {
		ID = id
        Name = name
        Type = type
        Location = location
        Goal = goal
        Desc = desc
        Progress = []
        AppearTime = Time()
    }
	
	function QuestSort(a,b)
	{
		if (a.IsCompleted&&!b.IsCompleted) return 1;
		if (!a.IsCompleted&&b.IsCompleted) return -1;
		return 0;
	}

    function AddProgress(text) { Progress.append(text) }
    function UpdateGoal(text) { Goal = text }
    
    function Complete()
    {
        IsCompleted = true
        CompleteTime = Time()
        IsNew = false
        QUESTS_MAIN.sort(QuestSort)
        QUESTS_SIDE.sort(QuestSort)
        QUESTS_MISSION.sort(QuestSort)
    }
    
    function MarkAsNew()
    {
        IsNew = true
        NewBlinkEnd = Time() + 5.0   // мигать 5 секунд
        AppearTime = Time()
    }
}

::AddMainQuest    <- function(q) { QUESTS_MAIN.append(q);QUESTS_MAIN.sort(QuestSort) }
::AddSideQuest    <- function(q) { QUESTS_SIDE.append(q);QUESTS_SIDE.sort(QuestSort) }
::AddMissionQuest <- function(q) { QUESTS_MISSION.append(q);QUESTS_MISSION.sort(QuestSort) }

if (CLIENT_DLL)
{
	::SW_ShowQuestNotification <- function(questName, action)
	{
		local header = "";
		local color = [0, 180, 255];
		
		switch (action)
		{
			case "NEW":
				header = "NEW QUEST";
				color = [0, 200, 255];
				break;
			case "UPDATE":
				header = "QUEST UPDATED";
				color = [200, 180, 50];
				break;
			case "COMPLETE":
				header = "QUEST COMPLETE";
				color = [50, 255, 100];
				break;
			case "FAIL":
				header = "QUEST FAILED";
				color = [255, 50, 50];
				break;
		}

		SW_HUD_QuestNotify(header, questName, color, action);
	}
	
	::SW_QUEST_NOTIFS <- [];

	::SW_HUD_QuestNotify <- function(header, questName, color, action = "NEW")
	{
		local priority = 2;
		if (action == "COMPLETE" || action == "FAIL") priority = 0;
		else if (action == "UPDATE") priority = 1;
		
		local batchTime = Time();
		
		SW_QUEST_NOTIFS.append({
			Header = header,        // "NEW QUEST" / "QUEST COMPLETE" / ...
			Name = questName,       // название квеста
			Color = color,          // цвет для header
			StartTime = batchTime,
			Duration = 3.0,
			Priority = priority
		});
		
		SW_QUEST_NOTIFS.sort(function(a, b) {
			if (a.Priority != b.Priority) return a.Priority - b.Priority;
			if (a.StartTime != b.StartTime) return (a.StartTime < b.StartTime) ? -1 : 1;
			return 0;
		});
	}
	
	NetMsg.Receive("SW_QuestRestore", function()
	{
		local id = NetMsg.ReadString();
		local action = NetMsg.ReadString();
		
		//printl("Got quest info on client. ID "+id+" ; action "+action)
		
		if (!(id in SW_QUESTS)) return;
		
		local def = SW_QUESTS[id];
		local list = null;
		
		if (def.Type == "MAIN") list = QUESTS_MAIN;
		else if (def.Type == "SIDE") list = QUESTS_SIDE;
		else if (def.Type == "MISSION") list = QUESTS_MISSION;
		if (list == null) return;
		
		// Ищем квест в списке
		local found = null;
		foreach (q in list) if (q.ID == id) { found = q; break; }
		
		
		switch (action)
		{
			case "NEW":
				if (found == null)
				{
					local newQ = Quest(id, def.Name, def.Type, def.Location, def.Goal, def.Desc);
					list.append(newQ);
				}
				//surface.PlaySound("ui/quest_new.wav");
				break;
			
			case "COMPLETE":
				if (found == null)
				{
					local newQ = Quest(id, def.Name, def.Type, def.Location, def.Goal, def.Desc);
					newQ.IsCompleted = true;
					list.append(newQ);
				}
				if (found != null) found.IsCompleted = true;
				//surface.PlaySound("ui/quest_complete.wav");
				break;
			
			case "FAIL":
				if (found != null) found.IsCompleted = true;   // или отдельный флаг
				//surface.PlaySound("ui/quest_fail.wav");
				break;
		}
		
		printl("[QUEST-CLIENT-RESTORE] " + action + ": " + def.Name);
		
		list.sort(QuestSort);
		
		
	}.bindenv(this));
	
	NetMsg.Receive("SW_QuestNotify", function()
	{
		local id = NetMsg.ReadString();
		local action = NetMsg.ReadString();
		
		//printl("Got quest info on client. ID "+id+" ; action "+action)
		
		if (!(id in SW_QUESTS)) return;
		
		local def = SW_QUESTS[id];
		local list = null;
		
		if (def.Type == "MAIN") list = QUESTS_MAIN;
		else if (def.Type == "SIDE") list = QUESTS_SIDE;
		else if (def.Type == "MISSION") list = QUESTS_MISSION;
		if (list == null) return;
		
		// Ищем квест в списке
		local found = null;
		foreach (q in list) if (q.ID == id) { found = q; break; }
		
		switch (action)
		{
			case "NEW":
				if (found == null)
				{
					local newQ = Quest(id, def.Name, def.Type, def.Location, def.Goal, def.Desc);
					list.append(newQ);
				}
				surface.PlaySound("ui/quest_new.wav");
				break;
			
			case "COMPLETE":
				if (found != null) found.IsCompleted = true;
				surface.PlaySound("ui/quest_complete.wav");
				break;
			
			case "FAIL":
				if (found != null) found.IsCompleted = true;   // или отдельный флаг
				surface.PlaySound("ui/quest_fail.wav");
				break;
		}
		
		SW_ShowQuestNotification(def.Name,action)
		
		printl("[QUEST-CLIENT] " + action + ": " + def.Name);
		
		list.sort(QuestSort);
	}.bindenv(this));
}

function InitQuests()
{
    // === MAIN ===
    // Основной квест: принять миссию в терминале и пройти её.
	/*
	local q2 = Quest("bomb","Bomb", "MAIN",
        "ReVerse Laboratory",
        "Find the bomb and defuse it",
        "A bomb has been found in the lab.")
    AddMainQuest(q2)
	q2.Complete()
	
    local q1 = Quest("reclamation","MISSION \"Reclamation\"", "MAIN",
        "ReVerse Laboratory",
        "Use the terminal to accept the mission",
        "The terminal in the ReVerse lab lists available missions. Accept the one you want to run, then travel through the Green Gates to complete it.")
    q1.AddProgress("Open the terminal in the ReVerse lab")
    AddMainQuest(q1)

    // === MISSION ===
    // Единственный миссионный квест: найти Безымянного, чтобы забрать у него квест.
	
	local q2 = Quest("reclamation_1","Find the Nameless One", "MISSION",
        "Abandoned Complex",
        "Find the Nameless One and take the MO disk",
        "The Nameless One sent a signal. Find him in the abandoned complex and retrieve the data he carries.")
	
    q2.AddProgress("He appears to be dead. At least I got the disk")
    AddMissionQuest(q2)
	*/
}

//QUESTS_MISSION[GetQuestID("reclamation_1")].Complete()
::AddExitQuest<-function(...)
{
	AddMissionQuest(Quest("mission_exit","Return to homebase", "MISSION",
        "Current Mission",
        "Use phone to open the exit portal.",
        "Use Portal menu of your phone to find 3 signal spots, then send their data to the laboratory. After doing so, an exit portal will open in between those signals."))
}

::FinishMission<-function(...)
{
	return;
	printl("finishing mission")
	foreach (i,q in QUESTS_MISSION) QUESTS_MISSION[i].Complete()
	AddExitQuest()
}

InitQuests()

// === Отрисовка меню квестов (внутри рамки инвентаря) ===
::DrawQuestsMenu <- function(Cell, CurX, CurY, TitleFont, TitleFontS, StatusFont, StatusFont4, FRAME_X, FRAME_Y, FRAME_WIDE, FRAME_HEIGHT, TitleHeight)
{
    // Фон
    surface.SetColor( 0, 8, 16, 255 )
    surface.DrawFilledRect( FRAME_X + YRES(2), FRAME_Y + TitleHeight + YRES(2), FRAME_WIDE - YRES(4), FRAME_HEIGHT - TitleHeight - YRES(4) )

    local PadX = YRES(6)
    local PadTop = TitleHeight + YRES(6)
    local PadBottom = YRES(4)
    local ColumnGap = YRES(4)

    local ContentX = FRAME_X + PadX
    local ContentY = FRAME_Y + PadTop
    local ContentW = FRAME_WIDE - PadX * 2
    local ContentH = FRAME_HEIGHT - PadTop - PadBottom

    local DetailH = YRES(140)
    local HeaderH = YRES(14)
    local cardH = YRES(22)

    local ListTop = ContentY
    local ListBottom = ContentY + ContentH - DetailH - YRES(6)

    // === ФОРМИРУЕМ СПИСОК КОЛОНОК В ЗАВИСИМОСТИ ОТ SW_ACTIVE_MISSION ===
    local ColsData = []
    if (SW_ACTIVE_MISSION != null)
    {
        // MISSION — первым, потом MAIN, потом SIDE
        ColsData.append({ name = "MISSION", list = QUESTS_MISSION, color = [255, 170, 0] })
        ColsData.append({ name = "MAIN",    list = QUESTS_MAIN,    color = [0, 191, 255] })
        ColsData.append({ name = "SIDE",    list = QUESTS_SIDE,    color = [0, 255, 136] })
    }
    else
    {
        // Только MAIN и SIDE, на всю ширину
        ColsData.append({ name = "MAIN", list = QUESTS_MAIN, color = [0, 191, 255] })
        ColsData.append({ name = "SIDE", list = QUESTS_SIDE, color = [0, 255, 136] })
    }

    local ColCount = ColsData.len()
    local ColumnWidth = (ContentW - ColumnGap * (ColCount - 1)) / ColCount

    for (local c = 0; c < ColCount; c++)
    {
        local cx = ContentX + c * (ColumnWidth + ColumnGap)
        local col = ColsData[c]
        local rgb = col.color

        // Фон колонки
        surface.SetColor(rgb[0] * 0.04, rgb[1] * 0.04, rgb[2] * 0.04, 255)
        surface.DrawFilledRect(cx, ListTop, ColumnWidth, ListBottom - ListTop)

        // Рамка колонки
        surface.SetColor(rgb[0] * 0.5, rgb[1] * 0.5, rgb[2] * 0.5, 255)
        surface.DrawOutlinedRect(cx, ListTop, ColumnWidth, ListBottom - ListTop, YRES(1))

        // Заголовок
        surface.SetColor(rgb[0] * 0.15, rgb[1] * 0.15, rgb[2] * 0.15, 255)
        surface.DrawFilledRect(cx, ListTop, ColumnWidth, HeaderH)
        surface.SetColor(rgb[0], rgb[1], rgb[2], 255)
        surface.DrawOutlinedRect(cx, ListTop, ColumnWidth, HeaderH, YRES(1))

        local htx = cx + YRES(4)
        local hty = ListTop + HeaderH/2 - surface.GetFontTall(TitleFontS)/2
        surface.DrawColoredText(TitleFontS, htx + YRES(1), hty + YRES(1), 0, 0, 0, 255, col.name)
        surface.DrawColoredText(TitleFont,  htx, hty, rgb[0], rgb[1], rgb[2], 255, col.name)

        // Список квестов
        local qy = ListTop + HeaderH + YRES(3)

        for (local q = 0; q < col.list.len(); q++)
        {
            if (qy + cardH > ListBottom) break

            local quest = col.list[q]
            local isCompleted = quest.IsCompleted
            local isSel = (QUEST_SELECTED_TAB == c && QUEST_SELECTED == q)
            local isHover = (CurX > cx && CurX < cx + ColumnWidth && CurY > qy && CurY < qy + cardH)

            // === ФОН ===
            local bgR, bgG, bgB
            if (isCompleted)
            {
                // Завершённые — очень тёмный фон, вне зависимости от категории
                bgR = 4; bgG = 8; bgB = 6
            }
            else
            {
                bgR = rgb[0] * 0.05
                bgG = rgb[1] * 0.05
                bgB = rgb[2] * 0.05

                if (isSel) { bgR = rgb[0] * 0.3; bgG = rgb[1] * 0.3; bgB = rgb[2] * 0.3 }
                else if (isHover) { bgR = rgb[0] * 0.15; bgG = rgb[1] * 0.15; bgB = rgb[2] * 0.15 }
            }
			
			// === Анимация появления ===
			local timeSinceAppear = Time() - quest.AppearTime;
			local appearAlpha = 1.0;
			local appearOffset = 0;

			if (timeSinceAppear < 0.4)
			{
				appearAlpha = clamp(timeSinceAppear / 0.4, 0, 1);
				appearOffset = (1.0 - appearAlpha) * YRES(12);  // сдвиг слева
			}
			else if (timeSinceAppear < 1.2)
			{
				// Лёгкое "дыхание" после появления
				appearAlpha = 1.0;
			}

            surface.SetColor(bgR, bgG, bgB, 255 * appearAlpha)
			surface.DrawFilledRect(cx + YRES(2) + appearOffset, qy, ColumnWidth - YRES(4), cardH)

            // === РАМКА ===
			local frameThickness = YRES(1)
			if (isCompleted)
			{
				surface.SetColor(rgb[0] * 0.15, rgb[1] * 0.15, rgb[2] * 0.15, 255)
				if (isSel) surface.SetColor(rgb[0] * 0.3, rgb[1] * 0.3, rgb[2] * 0.3, 255)
			}
			else if (isSel)
			{
				// Пульсация выбранного
				local pulse = 0.7 + 0.3 * fabs(sin(Time() * 2.5))
				surface.SetColor(rgb[0] * pulse, rgb[1] * pulse, rgb[2] * pulse, 255)
				frameThickness = YRES(2)   // чуть толще
			}
			else
			{
				surface.SetColor(rgb[0] * 0.35, rgb[1] * 0.35, rgb[2] * 0.35, 255)
			}
			surface.DrawOutlinedRect(cx + YRES(2), qy, ColumnWidth - YRES(4), cardH, frameThickness)

            // === ИКОНКА ===
			local iconColor = isCompleted ? [74, 255, 74] : rgb
			local icon = isCompleted ? "v" : ">"

			// Пульсация иконки
			local iconOffset = 0
			local iconAlpha = 255
			if (!isCompleted)
			{
				iconOffset = sin(Time() * 3) * YRES(1)   // лёгкое движение влево-вправо
				iconAlpha = 180 + 75 * fabs(sin(Time() * 2))
			}
			else
			{
				// "v" чуть пульсирует по альфе
				iconAlpha = 200 + 55 * fabs(sin(Time() * 1.5))
			}

			surface.DrawColoredText(StatusFont4, cx + YRES(4) + iconOffset, qy + cardH/2 - surface.GetFontTall(StatusFont4)/2,
				iconColor[0], iconColor[1], iconColor[2], iconAlpha, icon)
				
				
			// === Индикатор "нового" квеста ===
			if (quest.IsNew && Time() < quest.NewBlinkEnd)
			{
				local blinkAlpha = 150 + 105 * fabs(sin(Time() * 4))
				local dotSize = YRES(4)
				surface.SetColor(255, 60, 60, blinkAlpha)
				surface.DrawFilledRect(cx + ColumnWidth - YRES(8), qy + YRES(4), dotSize, dotSize)
			}

            // === НАЗВАНИЕ ===
            local nameX = cx + YRES(12)
            local nameY = qy + YRES(2)
            local nameColor = isCompleted ? [130, 130, 130] : [255, 255, 255]

            surface.DrawColoredText(StatusFont, nameX, nameY,
                nameColor[0], nameColor[1], nameColor[2], 255, quest.Name)

            // Перечёркивание названия для завершённых
            if (isCompleted)
            {
                local textW = surface.GetTextWidth(StatusFont, quest.Name)
                local textH = surface.GetFontTall(StatusFont)
                local lineY = nameY + textH / 2
                surface.SetColor(130, 130, 130, 255)
                surface.DrawFilledRect(nameX, lineY, textW, YRES(1))
            }

            // === ПОДСКАЗКА (Goal) ===
            local goalColor = isCompleted ? [50, 50, 50] : [rgb[0] * (0.7+0.3*(isSel||isHover).tointeger()), rgb[1] * (0.7+0.3*(isSel||isHover).tointeger()), rgb[2] * (0.7+0.3*(isSel||isHover).tointeger())]
            surface.DrawColoredText(StatusFont4, cx + YRES(12), qy + YRES(2) + surface.GetFontTall(StatusFont),
                goalColor[0], goalColor[1], goalColor[2], 255, quest.Goal)

            qy += cardH + YRES(2)
        }
    }

    // === ПАНЕЛЬ ДЕТАЛЕЙ ===
    local DetailY = ContentY + ContentH - DetailH
    local DetailX = ContentX
    local DetailW = ContentW

        local activeCol = ColsData[QUEST_SELECTED_TAB]
    local ac = activeCol.color
    local catName = activeCol.name

    // === Цвета зависят от состояния квеста ===
    local isCompletedQuest = (QUEST_SELECTED >= 0 && QUEST_SELECTED < activeCol.list.len() && activeCol.list[QUEST_SELECTED].IsCompleted)

    local bgR, bgG, bgB
    local frameR, frameG, frameB

    if (isCompletedQuest)
    {
        // Завершённый — приглушённый
        // Обычный — по типу
        bgR = 0; bgG = 15*0.5; bgB = 25*0.5
        if (catName == "SIDE") { bgR = 0; bgG = 20*0.5; bgB = 10*0.5 }
        else if (catName == "MISSION") { bgR = 25*0.5; bgG = 18*0.5; bgB = 0 }
        frameR = ac[0]*0.5; frameG = ac[1]*0.5; frameB = ac[2]*0.5
    }
    else
    {
        // Обычный — по типу
        bgR = 0; bgG = 15; bgB = 25
        if (catName == "SIDE") { bgR = 0; bgG = 20; bgB = 10 }
        else if (catName == "MISSION") { bgR = 25; bgG = 18; bgB = 0 }
        frameR = ac[0]; frameG = ac[1]; frameB = ac[2]
    }

    // Фон панели
    surface.SetColor(bgR, bgG, bgB, 255)
    surface.DrawFilledRect(DetailX, DetailY, DetailW, DetailH)

    // Рамка панели
    surface.SetColor(frameR, frameG, frameB, 255)
    surface.DrawOutlinedRect(DetailX, DetailY, DetailW, DetailH, YRES(2))

    if (QUEST_SELECTED >= 0 && QUEST_SELECTED < activeCol.list.len())
    {
        local q = activeCol.list[QUEST_SELECTED]

        // === Название ===
        if (isCompletedQuest)
        {
			local stampFont = surface.GetFont("VerySmol", true)
			if (!stampFont) stampFont = TitleFontS
			local stampText = "COMPLETED"
			local stampW = surface.GetTextWidth(stampFont, stampText)
			local stampX = DetailX + YRES(17) + surface.GetTextWidth(TitleFont, activeCol.list[QUEST_SELECTED].Name)
			local stampY = DetailY + YRES(4)

			// Полупрозрачная плашка
			surface.SetColor(frameR, frameG, frameB, 180)
			surface.DrawFilledRect(stampX - YRES(4), stampY - YRES(1), stampW + YRES(8), surface.GetFontTall(stampFont) + YRES(2))

			// Текст
			surface.DrawColoredText(stampFont, stampX + YRES(1), stampY + YRES(1), 0, 0, 0, 255, stampText)
			surface.DrawColoredText(stampFont, stampX, stampY, ac[0], ac[1], ac[2], 255, stampText)
			
			
			
            // Приглушённое серо-зелёное, перечёркнутое
            surface.DrawColoredText(TitleFontS, DetailX + YRES(7), DetailY + YRES(4), 0, 0, 0, 255, q.Name)
            surface.DrawColoredText(TitleFont,  DetailX + YRES(6), DetailY + YRES(3), ac[0]*0.5, ac[1]*0.5, ac[2]*0.5, 255, q.Name)

            // Перечёркивание
            local textW = surface.GetTextWidth(TitleFont, q.Name)
            local textH = surface.GetFontTall(TitleFont)
            surface.SetColor(ac[0], ac[1], ac[2], 255)
            surface.DrawFilledRect(DetailX + YRES(6), DetailY + YRES(3) + textH / 2, textW, YRES(1))
        }
        else
        {
            surface.DrawColoredText(TitleFontS, DetailX + YRES(7), DetailY + YRES(4), 0, 0, 0, 255, q.Name)
            surface.DrawColoredText(TitleFont,  DetailX + YRES(6), DetailY + YRES(3), ac[0], ac[1], ac[2], 255, q.Name)
			
			// === Блик по заголовку ===
			local titleW = surface.GetTextWidth(TitleFont, q.Name)
			local shinePos = (Time() * 0.6) % 1.4 - 0.2   // от -0.2 до 1.2
			local shineX = DetailX + YRES(6) + shinePos * titleW
			local shineW = YRES(20)
			
			// Блик — светлый прямоугольник с fade по краям
			local clipLeft = DetailX + YRES(6)
			local clipRight = DetailX + YRES(6) + titleW
			
			local sStart = max(shineX - shineW/2, clipLeft)
			local sEnd = min(shineX + shineW/2, clipRight)
			
			if (sStart < sEnd)
			{
				surface.SetColor(255, 255, 255, 20)
				surface.DrawFilledRectFade(sStart, DetailY + YRES(3), (sEnd - sStart) * 0.5,
					surface.GetFontTall(TitleFont), 0, 50, true)
				surface.SetColor(255, 255, 255, 20)
				surface.DrawFilledRectFade(sStart + (sEnd - sStart) * 0.5, DetailY + YRES(3),
					(sEnd - sStart) * 0.5, surface.GetFontTall(TitleFont), 50, 0, true)
			}
        }

        // Разделитель
        surface.SetColor(frameR * 0.5, frameG * 0.5, frameB * 0.5, 255)
        surface.DrawFilledRect(DetailX + YRES(4), DetailY + YRES(16), DetailW - YRES(8), YRES(1))

        // === ЛЕВАЯ КОЛОНКА: Location + Goal ===
        local textColor = isCompletedQuest ? [130, 130, 130] : [255, 255, 255]
        local labelColor = isCompletedQuest ? [60, 70, 100] : [100, 150, 180]

        local ty = DetailY + YRES(22)

        // Location
        surface.DrawColoredText(StatusFont4, DetailX + YRES(6), ty, labelColor[0], labelColor[1], labelColor[2], 255, "Location")
        surface.DrawColoredText(StatusFont,  DetailX + YRES(60), ty, textColor[0], textColor[1], textColor[2], 255, q.Location)
        
        if (isCompletedQuest)
        {
            local textW = surface.GetTextWidth(StatusFont, q.Location)
            local textH = surface.GetFontTall(StatusFont)
            surface.SetColor(textColor[0], textColor[1], textColor[2], 255)
            surface.DrawFilledRect(DetailX + YRES(60), ty + textH / 2, textW, YRES(1))
        }
        
        ty += surface.GetFontTall(StatusFont) + YRES(2)

        // Goal
        surface.DrawColoredText(StatusFont4, DetailX + YRES(6), ty, labelColor[0], labelColor[1], labelColor[2], 255, "Goal")
        
        local goalFont = StatusFont
        local goalX = DetailX + YRES(60)
        local goalMaxW = (DetailW / 2) - YRES(60) - YRES(8)
        local goalLines = GetTextInLines(goalFont, goalMaxW, q.Goal, q.Goal.len())
        
        foreach (line in goalLines)
        {
            surface.DrawColoredText(goalFont, goalX, ty, textColor[0], textColor[1], textColor[2], 255, line)
            
            if (isCompletedQuest)
            {
                local textW = surface.GetTextWidth(goalFont, line)
                local textH = surface.GetFontTall(goalFont)
                surface.SetColor(textColor[0], textColor[1], textColor[2], 255)
                surface.DrawFilledRect(goalX, ty + textH / 2, textW, YRES(1))
            }
            
            ty += surface.GetFontTall(goalFont) + YRES(1)
        }

        // === ПРАВАЯ КОЛОНКА: Progress (только для активных) ===
        if (!isCompletedQuest && q.Progress && q.Progress.len() > 0)
        {
            local rx = DetailX + DetailW / 2 + YRES(4)
            local ry = DetailY + YRES(22)
            local lineH = surface.GetFontTall(StatusFont4) + YRES(1)

            surface.DrawColoredText(StatusFont4, rx, ry, ac[0], ac[1], ac[2], 255, "Information:")
            ry += lineH
            foreach (line in q.Progress)
            {
                if (ry + lineH > DetailY + DetailH - YRES(2)) break
                surface.DrawColoredText(StatusFont4, rx + YRES(4), ry, ac[0]*0.7, ac[1]*0.7, ac[2]*0.7, 255, "> " + line)
                ry += lineH
            }
        }

        // === ОПИСАНИЕ ===
        local descTop = DetailY + YRES(65)

        if (descTop + YRES(20) < DetailY + DetailH)
        {
            surface.SetColor(frameR * 0.5, frameG * 0.5, frameB * 0.5, 255)
            surface.DrawFilledRect(DetailX + YRES(4), descTop - YRES(2), DetailW - YRES(8), YRES(1))

            surface.DrawColoredText(StatusFont4, DetailX + YRES(6), descTop + YRES(2), labelColor[0], labelColor[1], labelColor[2], 255, "DESC:")

            local descFont = surface.GetFont("InventoryTrait4", true)
            if (!descFont) descFont = StatusFont

            local descTextX = DetailX + YRES(10)
            local descMaxW = DetailW - YRES(40)
            local descLines = GetTextInLines(descFont, descMaxW, q.Desc, q.Desc.len())

            local dy = descTop + YRES(12)
            foreach (line in descLines)
            {
                if (dy + surface.GetFontTall(descFont) > DetailY + DetailH - YRES(2)) break
                surface.DrawColoredText(descFont, descTextX, dy, textColor[0], textColor[1], textColor[2], 255, line)
                dy += surface.GetFontTall(descFont) + YRES(1)
            }
        }
    }
    else
    {
        local midX = DetailX + DetailW/2 - surface.GetTextWidth(TitleFontS, "Select a quest")/2
        local midY = DetailY + DetailH/2 - surface.GetFontTall(TitleFontS)/2
        surface.DrawColoredText(TitleFont, midX, midY, 50, 80, 110, 255, "Select a quest")
    }
}
// === Клик по квесту ===
::HandleQuestClick <- function(CurX, CurY, Cell, FRAME_X, FRAME_Y, FRAME_WIDE, FRAME_HEIGHT, TitleHeight)
{
    local PadX = YRES(6)
    local PadTop = TitleHeight + YRES(6)
    local PadBottom = YRES(4)
    local ColumnGap = YRES(4)

    local ContentX = FRAME_X + PadX
    local ContentY = FRAME_Y + PadTop
    local ContentW = FRAME_WIDE - PadX * 2
    local ContentH = FRAME_HEIGHT - PadTop - PadBottom

    local DetailH = YRES(140)
    local HeaderH = YRES(14)
    local cardH = YRES(22)

    local ListTop = ContentY
    local ListBottom = ContentY + ContentH - DetailH - YRES(6)

    // Та же логика, что и в DrawQuestsMenu
    local ColsData = []
    if (SW_ACTIVE_MISSION != null)
    {
        ColsData.append({ list = QUESTS_MISSION })
        ColsData.append({ list = QUESTS_MAIN })
        ColsData.append({ list = QUESTS_SIDE })
    }
    else
    {
        ColsData.append({ list = QUESTS_MAIN })
        ColsData.append({ list = QUESTS_SIDE })
    }

    local ColCount = ColsData.len()
    local ColumnWidth = (ContentW - ColumnGap * (ColCount - 1)) / ColCount

    for (local c = 0; c < ColCount; c++)
    {
        local cx = ContentX + c * (ColumnWidth + ColumnGap)
        local qy = ListTop + HeaderH + YRES(3)

        for (local q = 0; q < ColsData[c].list.len(); q++)
        {
            if (qy + cardH > ListBottom) break

            if (CurX > cx + YRES(2) && CurX < cx + ColumnWidth - YRES(2) && CurY > qy && CurY < qy + cardH)
            {
				if (QUEST_SELECTED != q || QUEST_SELECTED_TAB != c)
                {
                    surface.PlaySound("ui/quest_info.wav")
                }
                QUEST_SELECTED = q
                QUEST_SELECTED_TAB = c
                return true
            }
            qy += cardH + YRES(2)
        }
    }
    return false
}