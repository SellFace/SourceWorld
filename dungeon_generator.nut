// ============================================================
//  MAPGEN 3 — PROCEDURAL DUNGEON GENERATOR
//  Генерирует случайный данж, компилирует его и загружает.
// ============================================================

// ============================================================
//  МАТЕРИАЛЫ
// ============================================================

::MG_WALL_MATS <- [
    // Базовые и часто используемые
    "CONCRETE/CONCRETEWALL065B", "CONCRETE/CONCRETEWALL061A",
    "CONCRETE/CONCRETEWALL071B", "CONCRETE/CONCRETEWALL037A",
    // Разнообразие фактур и трещин
    "CONCRETE/CONCRETEWALL059C", "CONCRETE/CONCRETEWALL059E",
    "CONCRETE/CONCRETEWALL060C", "CONCRETE/CONCRETEWALL062A",
    "CONCRETE/CONCRETEWALL063A", "CONCRETE/CONCRETEWALL064A",
    "CONCRETE/CONCRETEWALL066A", "CONCRETE/CONCRETEWALL002B",
    "CONCRETE/CONCRETEWALL005A", "CONCRETE/CONCRETEWALL008B",
    "CONCRETE/CONCRETEWALL015C",
    "CONCRETE/CONCRETEWALL019A", "CONCRETE/CONCRETEWALL022A",
    "CONCRETE/CONCRETEWALL024A"
];

::MG_FLOOR_MATS <- [
    // Базовые
    "CONCRETE/CONCRETEFLOOR010A", "CONCRETE/CONCRETEFLOOR014A",
    "CONCRETE/CONCRETEFLOOR001A",
    // Текстуры с разными паттернами и износом
    "CONCRETE/CONCRETEFLOOR005A",
    "CONCRETE/CONCRETEFLOOR007A", "CONCRETE/CONCRETEFLOOR008A",
    "CONCRETE/CONCRETEFLOOR009A", "CONCRETE/CONCRETEFLOOR011A",
    "CONCRETE/CONCRETEFLOOR012A", "CONCRETE/CONCRETEFLOOR013A",
    "CONCRETE/CONCRETEFLOOR033A", "CONCRETE/CONCRETEFLOOR037A",
    "CONCRETE/CONCRETEFLOOR038B", "CONCRETE/CONCRETEFLOOR039A",
];

::MG_CEILING_MATS <- [
    "CONCRETE/CONCRETECEILING001A",
    "CONCRETE/CONCRETECEILING002A"
];

// ============================================================
//  КЛАССЫ
// ============================================================

class MapGenRoom
{
    ID = 0;
    Type = "generic";
    IsCorridor = false;   // <-- НОВОЕ: true, если это коридор
    X = 0; Y = 0; Z = 0;
    SizeX = 512; SizeY = 512; SizeZ = 128;
    WallMat = null;
    FloorMat = null;
    CeilingMat = null;
    Connections = [];
    Lights = [];
    Props = [];
    NPCs = [];
    Items = [];
    Triggers = [];

    constructor(id, type, x, y, z, sx, sy, sz)
    {
        ID = id; Type = type;
        IsCorridor = (type == "corridor");   // <-- авто-установка
        X = x; Y = y; Z = z;
        SizeX = sx; SizeY = sy; SizeZ = sz;
        Connections = []; Lights = []; Props = []; NPCs = []; Items = []; Triggers = [];
    }

    function GetMinX() { return X - SizeX / 2; }
    function GetMaxX() { return X + SizeX / 2; }
    function GetMinY() { return Y - SizeY / 2; }
    function GetMaxY() { return Y + SizeY / 2; }
    function GetMinZ() { return Z; }
    function GetMaxZ() { return Z + SizeZ; }

    function Overlaps(other, margin = 64)
    {
        if (GetMaxX() + margin < other.GetMinX()) return false;
        if (GetMinX() - margin > other.GetMaxX()) return false;
        if (GetMaxY() + margin < other.GetMinY()) return false;
        if (GetMinY() - margin > other.GetMaxY()) return false;
        return true;
    }
}

class MapGenConnection
{
    FromRoom = null;
    ToRoom = null;
    Direction = "north";
    Width = 96;
    Height = 96;
	OpeningCenterOffset = 0;

    constructor(from, to, dir, w = 96, h = 96)
    {
        FromRoom = from; ToRoom = to; Direction = dir;
        Width = w; Height = h;
    }
}

class MapGenLight
{
    X = 0; Y = 0; Z = 0;
    Brightness = "255 240 200 200";
    Radius = 320;
    Type = "light";

    constructor(x, y, z, brightness = "255 240 200 60", radius = 320, type = "light")
    {
        X = x; Y = y; Z = z;
        Brightness = brightness; Radius = radius; Type = type;
    }
}

class MapGenEntity
{
    Classname = "prop_physics";
    X = 0; Y = 0; Z = 0;
    Angles = "0 0 0";
    KeyValues = {};

    constructor(classname, x, y, z, angles = "0 0 0")
    {
        Classname = classname; X = x; Y = y; Z = z; Angles = angles;
        KeyValues = {};
    }
}

// ============================================================
//  УТИЛИТЫ
// ============================================================

::MG_RandInt <- function(min, max) { return RandomInt(min, max); }

::MG_MakeSide <- function(id, x1, y1, z1, x2, y2, z2, x3, y3, z3, material, uaxis = "[1 0 0 0] 0.25", vaxis = "[0 -1 0 0] 0.25")
{
    local vmf = "";
    vmf += "\tside\n\t{\n";
    vmf += "\t\t\"id\" \"" + id + "\"\n";
    vmf += "\t\t\"plane\" \"(" + x1 + " " + y1 + " " + z1 + ") (" + x2 + " " + y2 + " " + z2 + ") (" + x3 + " " + y3 + " " + z3 + ")\"\n";
    vmf += "\t\t\"material\" \"" + material + "\"\n";
    vmf += "\t\t\"uaxis\" \"" + uaxis + "\"\n";
    vmf += "\t\t\"vaxis\" \"" + vaxis + "\"\n";
    vmf += "\t\t\"rotation\" \"0\"\n";
    vmf += "\t\t\"lightmapscale\" \"16\"\n";
    vmf += "\t\t\"smoothing_groups\" \"0\"\n";
    vmf += "\t}\n";
    return vmf;
}

::MG_MakeBoxSolid <- function(id, minX, minY, minZ, maxX, maxY, maxZ, material)
{
    local vmf = "solid\n{\n";
    vmf += "\t\"id\" \"" + id + "\"\n";

    // Верх
    vmf += MG_MakeSide(id + 1,
        minX, maxY, maxZ, maxX, maxY, maxZ, maxX, minY, maxZ,
        material, "[1 0 0 0] 0.25", "[0 -1 0 0] 0.25");

    // Низ
    vmf += MG_MakeSide(id + 2,
        minX, minY, minZ, maxX, minY, minZ, maxX, maxY, minZ,
        material, "[1 0 0 0] 0.25", "[0 -1 0 0] 0.25");

    // Запад (X=minX)
    vmf += MG_MakeSide(id + 3,
        minX, maxY, maxZ, minX, minY, maxZ, minX, minY, minZ,
        material, "[0 1 0 0] 0.25", "[0 0 -1 0] 0.25");

    // Восток (X=maxX)
    vmf += MG_MakeSide(id + 4,
        maxX, maxY, minZ, maxX, minY, minZ, maxX, minY, maxZ,
        material, "[0 1 0 0] 0.25", "[0 0 -1 0] 0.25");

    // Север (Y=maxY)
    vmf += MG_MakeSide(id + 5,
        maxX, maxY, maxZ, minX, maxY, maxZ, minX, maxY, minZ,
        material, "[1 0 0 0] 0.25", "[0 0 -1 0] 0.25");

    // Юг (Y=minY)
    vmf += MG_MakeSide(id + 6,
        maxX, minY, minZ, minX, minY, minZ, minX, minY, maxZ,
        material, "[1 0 0 0] 0.25", "[0 0 -1 0] 0.25");

    vmf += "}\n";
    return vmf;
}

// Создать верхнюю часть проёма, втопленную в коридор
::MG_MakeOpeningTop <- function(brushId, wallAxis,
                                 opLeft, opRight, opTop, maxZ,
                                 fixedMin, fixedMax,
                                 overhang, corridorSide,
                                 material)
{
    local overMin, overMax;
    if (corridorSide > 0)
    {
        overMin = fixedMin;
        overMax = fixedMax + overhang;
    }
    else
    {
        overMin = fixedMin - overhang;
        overMax = fixedMax;
    }
    
    if (wallAxis == "x")
        return MG_MakeBoxSolid(brushId, opLeft, overMin, opTop, opRight, overMax, maxZ, material);
    else
        return MG_MakeBoxSolid(brushId, overMin, opLeft, opTop, overMax, opRight, maxZ, material);
}

// Создать стену с проёмом (4 браша вокруг отверстия)
// Ось стены: "x" — стена идёт по X (нормаль Y), "y" — стена идёт по Y (нормаль X)
::MG_MakeWallWithOpening <- function(brushId, wallAxis,
                                      minA, maxA, minZ, maxZ,
                                      fixedCoord, thickness,
                                      openingCenter, openingWidth, openingHeight,
                                      material,
                                      corridorSide = 1)   // +1 или -1
{
    local vmf = "";
    
    local opLeft  = openingCenter - openingWidth / 2;
    local opRight = openingCenter + openingWidth / 2;
    local opBottom = minZ;
    local opTop    = minZ + openingHeight;
    
    // Ограничиваем проём в пределах стены
    if (opLeft  < minA) opLeft  = minA;
    if (opRight > maxA) opRight = maxA;
    if (opTop   > maxZ) opTop   = maxZ;
    
    local fixedMin = fixedCoord;
    local fixedMax = fixedCoord + thickness;
    
    if (wallAxis == "x")
    {
        // Стена идёт по X, нормаль Y
        // Левая часть
        if (opLeft > minA)
            vmf += MG_MakeBoxSolid(brushId, minA, fixedMin, minZ, opLeft, fixedMax, maxZ, material);
        brushId += 10;
        
        // Правая часть
        if (opRight < maxA)
            vmf += MG_MakeBoxSolid(brushId, opRight, fixedMin, minZ, maxA, fixedMax, maxZ, material);
        brushId += 10;
        
        
        
        // Нижняя часть (под проёмом) — если проём не до пола
        if (opBottom > minZ)
            vmf += MG_MakeBoxSolid(brushId, opLeft, fixedMin, minZ, opRight, fixedMax, opBottom, material);
        brushId += 10;
    }
    else // "y"
    {
        // Стена идёт по Y, нормаль X
        if (opLeft > minA)
            vmf += MG_MakeBoxSolid(brushId, fixedMin, minA, minZ, fixedMax, opLeft, maxZ, material);
        brushId += 10;
        
        if (opRight < maxA)
            vmf += MG_MakeBoxSolid(brushId, fixedMin, opRight, minZ, fixedMax, maxA, maxZ, material);
        brushId += 10;
        
                // Верхняя часть
        if (opBottom > minZ)
            vmf += MG_MakeBoxSolid(brushId, fixedMin, opLeft, minZ, fixedMax, opRight, opBottom, material);
        brushId += 10;
    }
	
	if (opTop < maxZ&&((opLeft > minA)||(opRight < maxA)))
	{
		if (wallAxis == "x")
			vmf += MG_MakeBoxSolid(brushId, opLeft, fixedMin, opTop, opRight, fixedMax, maxZ, material);
		else
			vmf += MG_MakeBoxSolid(brushId, fixedMin, opLeft, opTop, fixedMax, opRight, maxZ, material);
		brushId += 10;
	}
    
    return { vmf = vmf, nextId = brushId };
}

::MG_MakeEntity <- function(classname, x, y, z, angles = "0 0 0", keyvalues = {})
{
    local vmf = "entity\n{\n";
    vmf += "\t\"classname\" \"" + classname + "\"\n";
    vmf += "\t\"origin\" \"" + x.tointeger() + " " + y.tointeger() + " " + z.tointeger() + "\"\n";
    if (angles != "0 0 0") vmf += "\t\"angles\" \"" + angles + "\"\n";

    foreach (k, v in keyvalues)
        vmf += "\t\"" + k + "\" \"" + v + "\"\n";

    vmf += "}\n";
    return vmf;
}

// ============================================================
//  ГЕНЕРАЦИЯ КОМНАТ
// ============================================================

::MG_CreateRandomRoom <- function(id, type, x, y, z, forcedSX = null, forcedSY = null, forcedSZ = null)
{
    local sx, sy, sz;

    // Если все три размера заданы — используем их
    if (forcedSX != null && forcedSY != null && forcedSZ != null)
    {
        sx = forcedSX;
        sy = forcedSY;
        sz = forcedSZ;
    }
    else
    {
        // Иначе — генерируем случайные по типу
        switch (type)
        {
            case "start":
                sx = MG_RandInt(256, 512);
                sy = MG_RandInt(256, 512);
                sz = 128;
                break;
            case "hub":
                sx = MG_RandInt(512, 768);
                sy = MG_RandInt(512, 768);
                sz = 128;
                break;
            case "boss":
                sx = MG_RandInt(768, 1024);
                sy = MG_RandInt(768, 1024);
                sz = 128;
                break;
            case "dead_end":
                sx = MG_RandInt(128, 384);
                sy = MG_RandInt(128, 384);
                sz = 128;
                break;
            case "corridor":
                // Коридор — узкий и длинный
                if (MG_RandInt(0, 1) == 0)
                {
                    sx = MG_RandInt(96, 128);   // узкий по X
                    sy = MG_RandInt(384, 768);  // длинный по Y
                }
                else
                {
                    sx = MG_RandInt(384, 768);  // длинный по X
                    sy = MG_RandInt(96, 128);   // узкий по Y
                }
                sz = 128;
                break;
            default: // "generic"
                sx = MG_RandInt(128, 512);
                sy = MG_RandInt(128, 512);
                sz = 128;
        }
    }

    return MapGenRoom(id, type, x, y, z, sx, sy, sz);
}

// ============================================================
//  РАССТАНОВКА СВЕТА
// ============================================================

::MG_PlaceRoomLights <- function(room)
{
    // Коридоры — только один свет в центре
    if (room.Type == "corridor")
    {
		if (MG_RandInt(1, 16)==1) return;
        room.Lights.append(MapGenLight(
            room.X, room.Y, room.Z + room.SizeZ - 24,
            "255 240 200 10", 220));
        return;
    }

	if (MG_RandInt(1, 16)==1) return;

    // Потолочные светильники — 1..3 штуки в случайных местах
    local lightCount = MG_RandInt(1, 1);
    for (local i = 0; i < lightCount; i++)
    {
		
	
        local lx = room.X + MG_RandInt(-room.SizeX / 3, room.SizeX / 3);
        local ly = room.Y + MG_RandInt(-room.SizeY / 3, room.SizeY / 3);
        local lz = room.Z + room.SizeZ - 16;

        // Случайный оттенок
        local colorRoll = MG_RandInt(0, 100);
        local brightness;
        if (colorRoll < 60)
            brightness = "255 240 200 " + MG_RandInt(10, 50);      // тёплый белый
        else if (colorRoll < 85)
            brightness = "200 220 255 " + MG_RandInt(10, 70);      // холодный белый
        else
            brightness = "255 180 120 " + MG_RandInt(10, 40);      // оранжевый

        room.Lights.append(MapGenLight(lx, ly, lz, brightness, 280));
    }

    // Редкий "аварийный" свет — красный, в углу
    if (MG_RandInt(0, 100) < 20)
    {
        local ex = room.X + (MG_RandInt(0, 1) == 0 ? -1 : 1) * (room.SizeX / 2 - 32);
        local ey = room.Y + (MG_RandInt(0, 1) == 0 ? -1 : 1) * (room.SizeY / 2 - 32);
        room.Lights.append(MapGenLight(ex, ey, room.Z + 40, "255 40 40 30", 160));
    }
}

// ============================================================
//  РАССТАНОВКА ПРОПОВ
// ============================================================

// ============================================================
//  РАССТАНОВКА ПРОПОВ (адаптировано из prop_spawning_old.nut)
// ============================================================

// Проверка пересечения двух AABB (в мировых координатах)
::MG_DoAABBsOverlap <- function(x1, y1, z1, sx1, sy1, sz1,
                                x2, y2, z2, sx2, sy2, sz2)
{
    local min1X = x1 - sx1 / 2; local max1X = x1 + sx1 / 2;
    local min1Y = y1 - sy1 / 2; local max1Y = y1 + sy1 / 2;
    local min1Z = z1;           local max1Z = z1 + sz1;

    local min2X = x2 - sx2 / 2; local max2X = x2 + sx2 / 2;
    local min2Y = y2 - sy2 / 2; local max2Y = y2 + sy2 / 2;
    local min2Z = z2;           local max2Z = z2 + sz2;

    if (max1X < min2X) return false;
    if (min1X > max2X) return false;
    if (max1Y < min2Y) return false;
    if (min1Y > max2Y) return false;
    if (max1Z < min2Z) return false;
    if (min1Z > max2Z) return false;
    return true;
}

::MG_PlaceRoomProps <- function(room)
{
	return
    if (room.IsCorridor) return;

    local tileSize = 128;
    local margin = 20;
    local wallDist = 25;

    local minX = room.GetMinX() + margin;
    local maxX = room.GetMaxX() - margin;
    local minY = room.GetMinY() + margin;
    local maxY = room.GetMaxY() - margin;
    local floorZ = room.Z;

    local placedProps = [];

    local tileX = minX;
    while (tileX < maxX)
    {
        local tileY = minY;
        while (tileY < maxY)
        {
            local tMinX = tileX;
            local tMaxX = min(tileX + tileSize, maxX);
            local tMinY = tileY;
            local tMaxY = min(tileY + tileSize, maxY);

            if (1)
            {
                local propIdx = MG_RandInt(0, LIST_PROPS.len() - 1);
                local prop = LIST_PROPS[propIdx];

                local isWall = ("requires_wall" in prop) && prop.requires_wall;
                local isMassive = ("massive" in prop) && prop.massive;

                local sizeX = ("size" in prop) ? prop.size.x : 32;
                local sizeY = ("size" in prop) ? prop.size.y : 32;
                local sizeZ = ("size" in prop) ? prop.size.z : 32;
                local offX = ("offset" in prop) ? prop.offset.x : 0;
                local offY = ("offset" in prop) ? prop.offset.y : 0;
                local offZ = ("offset" in prop) ? prop.offset.z : 0;

                local px, py, pz, angle;

                if (isWall || isMassive)
                {
                    local wallSide = MG_RandInt(0, 3);
                    local halfX = sizeX / 2;
                    local halfY = sizeY / 2;

                    if (wallSide == 0) // North
                    {
                        px = MG_RandInt(tMinX + halfX, tMaxX - halfX);
                        py = maxY - wallDist - halfY;
                        angle = 270;
                    }
                    else if (wallSide == 1) // South
                    {
                        px = MG_RandInt(tMinX + halfX, tMaxX - halfX);
                        py = minY + wallDist + halfY;
                        angle = 90;
                    }
                    else if (wallSide == 2) // East
                    {
                        px = maxX - wallDist - halfX;
                        py = MG_RandInt(tMinY + halfY, tMaxY - halfY);
                        angle = 180;
                    }
                    else // West
                    {
                        px = minX + wallDist + halfX;
                        py = MG_RandInt(tMinY + halfY, tMaxY - halfY);
                        angle = 0;
                    }
                }
                else
                {
                    if (tMaxX - tMinX < sizeX + 16) { tileY += tileSize; continue; }
                    if (tMaxY - tMinY < sizeY + 16) { tileY += tileSize; continue; }

                    px = MG_RandInt(tMinX + sizeX / 2, tMaxX - sizeX / 2);
                    py = MG_RandInt(tMinY + sizeY / 2, tMaxY - sizeY / 2);

                    if ("alignment" in prop)
                    {
                        if (prop.alignment == 0) angle = MG_RandInt(0, 359);
                        else if (prop.alignment == 1) angle = MG_RandInt(0, 3) * 90 + MG_RandInt(-10, 10);
                        else if (prop.alignment == 2) angle = MG_RandInt(0, 3) * 90;
                    }
                    else angle = MG_RandInt(0, 359);
                }

                // Применяем offset полностью
                px += offX;
                py += offY;
                pz = floorZ + offZ;

                if ("angle_offset" in prop) angle += prop.angle_offset;
                if (("extra_yaw" in prop) && prop.extra_yaw != 0) angle += prop.extra_yaw;

                // === Проверка коллизий с уже поставленными ===
                local collision = false;
                foreach (other in placedProps)
                {
                    if (MG_DoAABBsOverlap(px, py, pz, sizeX, sizeY, sizeZ,
                                          other.X, other.Y, other.Z, other.SX, other.SY, other.SZ))
                    {
                        collision = true;
                        break;
                    }
                }
                if (collision) { tileY += tileSize; continue; }

                // === Проверка коллизий с брашами ===
                // Нижняя точка — на полу, верхняя — на высоте sizeZ
                local hullMin = Vector(px - sizeX / 2, py - sizeY / 2, pz + 1);
                local hullMax = Vector(px + sizeX / 2, py + sizeY / 2, pz + sizeZ - 1);
                local trace = TraceHullComplex(hullMin, hullMax, Vector(), Vector(), Entities.First(), MASK_SOLID, 0);
                if (trace.DidHit()) { tileY += tileSize; continue; }

                local classname = "prop_physics";
                if (("static_only" in prop) && prop.static_only)
                    classname = "prop_static";

                local propEnt = MapGenEntity(classname, px, py, pz, "0 " + angle + " 0");
                propEnt.KeyValues["model"] <- prop.model;

                if (("max_skin" in prop) && prop.max_skin > 0)
                    propEnt.KeyValues["skin"] <- MG_RandInt(0, prop.max_skin).tostring();

                propEnt.KeyValues["solid"] <- "6";

                if (("vertical" in prop) && prop.vertical)
                    propEnt.Angles = "90 " + angle + " 0";

                local colorR = 245 + MG_RandInt(0, 10);
                local colorG = 245 + MG_RandInt(0, 10);
                local colorB = 245 + MG_RandInt(0, 10);
                propEnt.KeyValues["rendercolor"] <- colorR + " " + colorG + " " + colorB;

                room.Props.append(propEnt);

                placedProps.append({
                    X = px, Y = py, Z = pz,
                    SX = sizeX, SY = sizeY, SZ = sizeZ
                });
            }

            tileY += tileSize;
        }
        tileX += tileSize;
    }
}

// Создать VMF-энтити врага из LIST_ENEMIES
::MG_MakeEnemyEntity <- function(enemyKey, x, y, z, yaw)
{
    local enemyDef = LIST_ENEMIES[enemyKey];
    local classname = enemyDef.classname;

    local kv = {};

    // Копируем только "простые" keyvalues (строки, числа)
    foreach (k, v in enemyDef)
    {
        // Пропускаем служебные поля
        if (k == "classname") continue;
        if (k == "hull") continue;
        if (k == "faction") continue;
        if (k == "cost") continue;
        if (k == "weight") continue;
        if (k == "min_difficulty") continue;
        if (k == "max_difficulty") continue;
        if (k == "extra_think") continue;
        if (k == "sound_modify") continue;
        if (k == "OnDamaged") continue;
        if (k == "Include") continue;   // Include — это скриптовая директива, не keyvalue

        // Всё остальное — в keyvalues
        kv[k] <- v.tostring();
    }

    // Убеждаемся, что vscripts и thinkfunction на месте
    if (!("vscripts" in kv))
        kv["vscripts"] <- "enemies/base_enemy.nut";
    if (!("thinkfunction" in kv))
        kv["thinkfunction"] <- "Think";

    // Спавним через MG_MakeEntity
    return MG_MakeEntity(classname, x, y, z, "0 " + yaw + " 0", kv);
}

::MG_PlaceRoomEnemies <- function(room, enemyList)
{
    if (room.IsCorridor) return;
    if (room.Type == "start") return;

    local enemyCount = 0;
    switch (room.Type)
    {
        case "boss":     enemyCount = MG_RandInt(3, 6); break;
        case "hub":      enemyCount = MG_RandInt(2, 4); break;
        case "dead_end": enemyCount = MG_RandInt(1, 2); break;
        default:         enemyCount = MG_RandInt(0, 3);
    }

    for (local i = 0; i < enemyCount; i++)
    {
        local ex = room.X + MG_RandInt(-room.SizeX / 2 + 64, room.SizeX / 2 - 64);
        local ey = room.Y + MG_RandInt(-room.SizeY / 2 + 64, room.SizeY / 2 - 64);
        local ez = room.Z + 16;
        local yaw = MG_RandInt(0, 359);

        local enemyKey = enemyList[MG_RandInt(0, enemyList.len() - 1)];
        local enemyDef = LIST_ENEMIES[enemyKey];

        local npc = MapGenEntity(enemyDef.classname, ex, ey, ez, "0 " + yaw + " 0");

        // Копируем keyvalues из LIST_ENEMIES
        foreach (k, v in enemyDef)
        {
            if (k == "classname") continue;
            if (k == "hull") continue;
            if (k == "faction") continue;
            if (k == "cost") continue;
            if (k == "weight") continue;
            if (k == "min_difficulty") continue;
            if (k == "max_difficulty") continue;
            if (k == "extra_think") continue;
            if (k == "sound_modify") continue;
            if (k == "OnDamaged") continue;
            if (k == "Include") continue;

            npc.KeyValues[k] <- v.tostring();
        }
		
		if ("ResponseContext" in npc.KeyValues) npc.KeyValues["ResponseContext"] <- npc.KeyValues["ResponseContext"]+",EnemyName:" + enemyKey;
		else npc.KeyValues["ResponseContext"] <- "EnemyName:" + enemyKey;

        if (!("vscripts" in npc.KeyValues))
            npc.KeyValues["vscripts"] <- "enemies/base_enemy.nut";
        if (!("thinkfunction" in npc.KeyValues))
            npc.KeyValues["thinkfunction"] <- "Think";

        room.NPCs.append(npc);
    }
}

// ============================================================
//  РАССТАНОВКА НАВИГАЦИОННЫХ УЗЛОВ
// ============================================================

::MG_PlaceRoomNodes <- function(room)
{
    // Шаг сетки — 128 юнитов
    local step = 72;

    // Отступ от стен — 48 юнитов (чтобы узлы не были в стенах)
    local margin = 32;

    // Границы, где можно ставить узлы
    local minX = room.GetMinX() + margin;
    local maxX = room.GetMaxX() - margin;
    local minY = room.GetMinY() + margin;
    local maxY = room.GetMaxY() - margin;
    local z = room.Z + 16;   // чуть выше пола

    if (maxX <= minX || maxY <= minY) return;

    // Идём сеткой
    local x = minX;
    while (x <= maxX)
    {
        local y = minY;
        while (y <= maxY)
        {
            local node = MapGenEntity("info_node", x, y, z, "0 0 0");
            node.KeyValues["spawnflags"] <- "0";
            room.NPCs.append(node);   // используем NPCs для сущностей без NPC-логики

            y += step;
        }
        x += step;
    }
}

// ============================================================
//  ГЕНЕРАЦИЯ ДАНЖА
// ============================================================

::MG_GenerateDungeon <- function(seed, roomCount = 8)
{
	local allFactions = [];
    foreach (k, v in LIST_ENEMIES)
    {
        if (k == "WON") continue;   // босса не берём
        if (!("faction" in v)) continue;
        if (allFactions.find(v.faction) == null)
            allFactions.append(v.faction);
    }

    local chosenFaction = "combine";   // дефолт
    if (allFactions.len() > 0)
        chosenFaction = allFactions[MG_RandInt(0, allFactions.len() - 1)];

    printl("[MAPGEN] Chosen faction: " + chosenFaction);

    // Собираем список врагов ТОЛЬКО этой фракции
    local factionEnemies = [];
    foreach (k, v in LIST_ENEMIES)
    {
        if (k == "WON") continue;
        if (!("faction" in v)) continue;
        if (v.faction != chosenFaction) continue;
        factionEnemies.append(k);
    }
    if (factionEnemies.len() == 0)
    {
        // fallback — если у фракции нет врагов
        foreach (k, v in LIST_ENEMIES)
        {
            if (k == "WON") continue;
            factionEnemies.append(k);
        }
    }

    printl("[MAPGEN] Enemies for this run: " + factionEnemies.len());
	
    local rooms = [];
    local id = 0;

    // Стартовая комната в центре
    local startRoom = MG_CreateRandomRoom(id, "start", 0, 0, 0);
    MG_PlaceRoomLights(startRoom);
    MG_PlaceRoomProps(startRoom);
    MG_PlaceRoomNodes(startRoom);
    rooms.append(startRoom);
    id++;

    local directions = ["north", "south", "east", "west"];

    local attempts = 0;
    local maxAttempts = 200;

    while (rooms.len() < roomCount && attempts < maxAttempts)
    {
        attempts++;

        local parent = rooms[MG_RandInt(0, rooms.len() - 1)];
        local dir = directions[MG_RandInt(0, directions.len() - 1)];

        local gap = 256;

        // Тип комнаты
        local type = "generic";
        local roll = MG_RandInt(0, 100);
        if (roll < 15) type = "hub";
        else if (roll < 25) type = "dead_end";
        if (rooms.len() == roomCount - 1) type = "boss";

        // Временная комната для размеров
        local tempRoom = MG_CreateRandomRoom(id, type, 0, 0, 0);
        local sx = tempRoom.SizeX;
        local sy = tempRoom.SizeY;
        local sz = tempRoom.SizeZ;

        // Позиция новой комнаты (выровнена по оси проёма)
        local newX = parent.X;
        local newY = parent.Y;
        local newZ = parent.Z;
        if (dir == "north") newY = parent.GetMaxY() + gap + sy / 2;
        else if (dir == "south") newY = parent.GetMinY() - gap - sy / 2;
        else if (dir == "east")  newX = parent.GetMaxX() + gap + sx / 2;
        else if (dir == "west")  newX = parent.GetMinX() - gap - sx / 2;

        local newRoom = MG_CreateRandomRoom(id, type, newX, newY, newZ, sx, sy, sz);

        // Проверка пересечений
        local overlaps = false;
        foreach (r in rooms)
        {
            if (newRoom.Overlaps(r, 128)) { overlaps = true; break; }
        }
        if (overlaps) continue;

        // === Случайное смещение проёма ===
        local openingWidth = 96;
        local offsetWorld = 0;

        if (dir == "north" || dir == "south")
        {
            // Проём по X
            local halfParentX = parent.SizeX / 2 - openingWidth / 2;
            local halfNewX = newRoom.SizeX / 2 - openingWidth / 2;
            local maxShift = min(halfParentX, halfNewX);
            if (maxShift < 0) maxShift = 0;
            offsetWorld = MG_RandInt(-maxShift, maxShift);
        }
        else // east / west
        {
            // Проём по Y
            local halfParentY = parent.SizeY / 2 - openingWidth / 2;
            local halfNewY = newRoom.SizeY / 2 - openingWidth / 2;
            local maxShift = min(halfParentY, halfNewY);
            if (maxShift < 0) maxShift = 0;
            offsetWorld = MG_RandInt(-maxShift, maxShift);
        }

        // === Коридор (сдвинут вместе с проёмом) ===
        local corrX, corrY, corrZ;
        local corrSizeX, corrSizeY, corrSizeZ = 128;
        local corridorWidth = 96;

        if (dir == "north" || dir == "south")
        {
            local corrMinY, corrMaxY;
            if (dir == "north")
            {
                corrMinY = parent.GetMaxY();
                corrMaxY = newRoom.GetMinY();
            }
            else // south
            {
                corrMinY = newRoom.GetMaxY();
                corrMaxY = parent.GetMinY();
            }

            corrY = (corrMinY + corrMaxY) / 2;
            corrSizeY = corrMaxY - corrMinY;
            corrX = parent.X + offsetWorld;   // сдвиг вместе с проёмом
            corrSizeX = corridorWidth;
        }
        else // east / west
        {
            local corrMinX, corrMaxX;
            if (dir == "east")
            {
                corrMinX = parent.GetMaxX();
                corrMaxX = newRoom.GetMinX();
            }
            else // west
            {
                corrMinX = newRoom.GetMaxX();
                corrMaxX = parent.GetMinX();
            }

            corrX = (corrMinX + corrMaxX) / 2;
            corrSizeX = corrMaxX - corrMinX;
            corrY = parent.Y + offsetWorld;   // сдвиг вместе с проёмом
            corrSizeY = corridorWidth;
        }
        corrZ = parent.Z;

        local corridor = MapGenRoom(id, "corridor",
            corrX.tointeger(), corrY.tointeger(), corrZ,
            corrSizeX.tointeger(), corrSizeY.tointeger(), corrSizeZ);
        MG_PlaceRoomLights(corridor);
        MG_PlaceRoomProps(corridor);

		MG_PlaceRoomNodes(corridor);


        // === Соединения через коридор ===
        local oppDir = (dir == "north") ? "south" :
                       (dir == "south") ? "north" :
                       (dir == "east")  ? "west"  : "east";

        // parent <-> corridor
        local c1 = MapGenConnection(parent, corridor, dir, 96, 96);
        c1.OpeningCenterOffset = offsetWorld;
        parent.Connections.append(c1);

        local c2 = MapGenConnection(corridor, parent, oppDir, 96, 96);
        c2.OpeningCenterOffset = -offsetWorld;   // для коридора — противоположное
        corridor.Connections.append(c2);

        // corridor <-> newRoom
        local c3 = MapGenConnection(corridor, newRoom, dir, 96, 96);
        c3.OpeningCenterOffset = -offsetWorld;   // для коридора — противоположное
        corridor.Connections.append(c3);

        local c4 = MapGenConnection(newRoom, corridor, oppDir, 96, 96);
        c4.OpeningCenterOffset = offsetWorld;
        newRoom.Connections.append(c4);

        // Коридор в список комнат
        rooms.append(corridor);
        id++;

        // Освещение и пропы новой комнаты
        MG_PlaceRoomLights(newRoom);
        MG_PlaceRoomProps(newRoom);
        MG_PlaceRoomEnemies(newRoom,factionEnemies)
		

		MG_PlaceRoomNodes(newRoom);

        rooms.append(newRoom);
        id++;
    }

    printl("[MAPGEN] Generated " + rooms.len() + " rooms (seed " + seed + ")");
    return rooms;
}

// ============================================================
//  СБОРКА VMF
// ============================================================

::MG_BuildVMF <- function(rooms)
{
    local vmf = "versioninfo\n{\n";
    vmf += "\t\"editorversion\" \"400\"\n";
    vmf += "\t\"editorbuild\" \"7544\"\n";
    vmf += "\t\"mapversion\" \"446\"\n";
    vmf += "\t\"formatversion\" \"100\"\n";
    vmf += "\t\"prefab\" \"0\"\n";
    vmf += "}\n";

    vmf += "world\n{\n";
    vmf += "\t\"id\" \"1\"\n";
    vmf += "\t\"mapversion\" \"446\"\n";
    vmf += "\t\"classname\" \"worldspawn\"\n";
    vmf += "\t\"skyname\" \"sky_day01_01\"\n";
    vmf += "\t\"lightmapscale\" \"16\"\n";

    // === Браши ===
    local brushId = 1000;

    foreach (room in rooms)
    {
        local minX = room.GetMinX().tointeger();
        local maxX = room.GetMaxX().tointeger();
        local minY = room.GetMinY().tointeger();
        local maxY = room.GetMaxY().tointeger();
        local minZ = room.GetMinZ().tointeger();
        local maxZ = room.GetMaxZ().tointeger();

        local wallMat = MG_WALL_MATS[MG_RandInt(0,MG_WALL_MATS.len()-1)];
        local floorMat = MG_FLOOR_MATS[MG_RandInt(0,MG_FLOOR_MATS.len()-1)];
        local ceilMat = MG_CEILING_MATS[MG_RandInt(0,MG_CEILING_MATS.len()-1)];

        local thickness = 16;

        // ПОЛ (низ)
        vmf += MG_MakeBoxSolid(brushId, minX, minY, minZ - thickness, maxX, maxY, minZ, floorMat);
        brushId += 10;

               // ПОТОЛОК (верх)
        vmf += MG_MakeBoxSolid(brushId, minX, minY, maxZ, maxX, maxY, maxZ + thickness, ceilMat);
        brushId += 10;

        // === КОРИДОРЫ: все стены цельные, без проёмов ===
        if (room.IsCorridor)
        {
            // Север
			if ((maxY-minY)<(maxX-minX))
			{
            vmf += MG_MakeBoxSolid(brushId, minX+thickness, maxY, minZ, maxX-thickness, maxY + thickness, maxZ, wallMat);
            brushId += 10;
            
			// Юг
            vmf += MG_MakeBoxSolid(brushId, minX+thickness, minY - thickness, minZ, maxX-thickness, minY, maxZ, wallMat);
            brushId += 10;
			}
			else
			{
            // Восток
            vmf += MG_MakeBoxSolid(brushId, maxX, minY+thickness, minZ, maxX + thickness, maxY-thickness, maxZ, wallMat);
            brushId += 10;
            // Запад
            vmf += MG_MakeBoxSolid(brushId, minX - thickness, minY+thickness, minZ, minX, maxY-thickness, maxZ, wallMat);
            brushId += 10;
			}
            continue;   // переходим к следующей комнате
        }

        // === СТЕНЫ (с проверкой соединений) ===
        local doorHeight = 96;
        
        // Собираем соединения по направлениям
        local connNorth = null, connSouth = null, connEast = null, connWest = null;
        foreach (conn in room.Connections)
        {
            if (conn.Direction == "north") connNorth = conn;
            else if (conn.Direction == "south") connSouth = conn;
            else if (conn.Direction == "east")  connEast = conn;
            else if (conn.Direction == "west")  connWest = conn;
        }
        
        // СЕВЕР (Y = maxY)
        if (connNorth != null)
        {
            local openingCenterX = room.X + connNorth.OpeningCenterOffset;
            local res = MG_MakeWallWithOpening(brushId, "x",
				minX, maxX, minZ, maxZ,
				maxY, thickness,
				openingCenterX, connNorth.Width, doorHeight,
				wallMat, 1);   // +1 — коридор снаружи (Y > maxY)
            vmf += res.vmf;
            brushId = res.nextId;
        }
        else
        {
            vmf += MG_MakeBoxSolid(brushId, minX, maxY, minZ, maxX, maxY + thickness, maxZ, wallMat);
            brushId += 10;
        }
        
        // ЮГ (Y = minY)
        if (connSouth != null)
        {
            local openingCenterX = room.X + connSouth.OpeningCenterOffset;
            local res = MG_MakeWallWithOpening(brushId, "x",
				minX, maxX, minZ, maxZ,
				minY - thickness, thickness,
				openingCenterX, connSouth.Width, doorHeight,
				wallMat, -1);   // -1 — коридор снаружи (Y < minY - thickness)
            vmf += res.vmf;
            brushId = res.nextId;
        }
        else
        {
            vmf += MG_MakeBoxSolid(brushId, minX, minY - thickness, minZ, maxX, minY, maxZ, wallMat);
            brushId += 10;
        }
        
        // ВОСТОК (X = maxX)
        if (connEast != null)
        {
            local openingCenterY = room.Y + connEast.OpeningCenterOffset;
            local res = MG_MakeWallWithOpening(brushId, "y",
				minY, maxY, minZ, maxZ,
				maxX, thickness,
				openingCenterY, connEast.Width, doorHeight,
				wallMat, 1);   // +1
            vmf += res.vmf;
            brushId = res.nextId;
        }
        else
        {
            vmf += MG_MakeBoxSolid(brushId, maxX, minY, minZ, maxX + thickness, maxY, maxZ, wallMat);
            brushId += 10;
        }
        
        // ЗАПАД (X = minX)
        if (connWest != null)
        {
            local openingCenterY = room.Y + connWest.OpeningCenterOffset;
            local res = MG_MakeWallWithOpening(brushId, "y",
				minY, maxY, minZ, maxZ,
				minX - thickness, thickness,
				openingCenterY, connWest.Width, doorHeight,
				wallMat, -1);   // -1
            vmf += res.vmf;
            brushId = res.nextId;
        }
        else
        {
            vmf += MG_MakeBoxSolid(brushId, minX - thickness, minY, minZ, minX, maxY, maxZ, wallMat);
            brushId += 10;
        }
    }

    vmf += "}\n";   // конец world

    // === Entities ===
    foreach (room in rooms)
    {
        // Свет
        foreach (light in room.Lights)
        {
            local kv = {};
            kv["_light"] <- light.Brightness;              // "R G B intensity"
            kv["_lightHDR"] <- "-1 -1 -1 1";               // по умолчанию — как _light
            kv["_lightscaleHDR"] <- "1";
            kv["_quadratic_attn"] <- "1";
            kv["style"] <- "0";
            kv["_constant_attn"] <- "0";
            kv["_distance"] <- light.Radius.tostring();    // радиус
            kv["_fifty_percent_distance"] <- "0";
            kv["_hardfalloff"] <- "0";
            kv["_linear_attn"] <- "0";
            kv["trap_cost"] <- "0";
            kv["random_group_case"] <- "0";
            kv["_zero_percent_distance"] <- "0";
            kv["spawnflags"] <- "0";
            vmf += MG_MakeEntity(light.Type, light.X, light.Y, light.Z, "0 0 0", kv);
        }

        // Пропы
        foreach (prop in room.Props)
            vmf += MG_MakeEntity(prop.Classname, prop.X, prop.Y, prop.Z, prop.Angles, prop.KeyValues);

        // NPC
        foreach (npc in room.NPCs)
            vmf += MG_MakeEntity(npc.Classname, npc.X, npc.Y, npc.Z, npc.Angles, npc.KeyValues);

        // Items
        foreach (item in room.Items)
            vmf += MG_MakeEntity(item.Classname, item.X, item.Y, item.Z, item.Angles, item.KeyValues);
    }

    // info_player_start в стартовой комнате
    local startRoom = rooms[0];
    vmf += MG_MakeEntity("info_player_start", startRoom.X, startRoom.Y, startRoom.Z + 16, "0 0 0", {});

    return vmf;
}

// ============================================================
//  РАНДОМИЗАЦИЯ МАТЕРИАЛОВ
// ============================================================

::MG_RandomizeVMF <- function()
{
    local inFile  = "mapgen_level_base.vmf";
    local outFile = "mapgen_level.vmf";

    local content = FileToString(inFile);
    if (content == null || content.len() == 0)
    {
        printl("[VMF] Cannot read " + inFile);
        return false;
    }

    local wallMapping  = {};
    local floorMapping = {};

    local lines = split(content, "\n");
    local result = "";

    foreach (line in lines)
    {
        local matPos = line.find("\"material\"");
        if (matPos == null) { result += line + "\n"; continue; }

        local afterKey = matPos + 10;
        local q1 = line.find("\"", afterKey);
        if (q1 == null) { result += line + "\n"; continue; }
        local q2 = line.find("\"", q1 + 1);
        if (q2 == null) { result += line + "\n"; continue; }

        local oldMat = line.slice(q1 + 1, q2);
        local newMat = null;

        if (oldMat.find("WALL") != null)
        {
            if (!(oldMat in wallMapping))
                wallMapping[oldMat] <- MG_WALL_MATS[MG_RandInt(0, MG_WALL_MATS.len() - 1)];
            newMat = wallMapping[oldMat];
        }
        else if (oldMat.find("FLOOR") != null)
        {
            if (!(oldMat in floorMapping))
                floorMapping[oldMat] <- MG_FLOOR_MATS[MG_RandInt(0, MG_FLOOR_MATS.len() - 1)];
            newMat = floorMapping[oldMat];
        }
        else
        {
            result += line + "\n";
            continue;
        }

        result += line.slice(0, q1 + 1) + newMat + line.slice(q2) + "\n";
    }

    StringToFile(outFile, result);
    printl("[VMF] Wall variants: " + wallMapping.len() + ", Floor variants: " + floorMapping.len());
    return true;
}

// ============================================================
//  ГЛАВНАЯ ФУНКЦИЯ
// ============================================================

::MG_GenerateAndCompile <- function(seed, roomCount = 8)
{
    printl("[MAPGEN] === Starting MapGen 3 ===");
    printl("[MAPGEN] Seed: " + seed + ", Rooms: " + roomCount);

    // 1. Генерация
    local rooms = MG_GenerateDungeon(seed, roomCount);

    // 2. Сборка VMF
    local vmf = MG_BuildVMF(rooms);
    StringToFile("mapgen_level_base.vmf", vmf);
    printl("[MAPGEN] VMF written to mapgen_level_base.vmf");

    // 3. Рандомизация материалов
    MG_RandomizeVMF();

    // 4. Компиляция
    SW_RunCompiler();

    // 5. Отслеживание
    Entities.First().SetContextThink("MG_CompileWatcher", function(_)
    {
        local status = SW_GetCompileStatus();

        if (status == 1)
        {
            return 0.2;
        }

        if (status == 2)
        {
            printl("[MAPGEN] Compilation done! Loading map...");
            SendToConsole("changelevel mapgen_level");
            return;
        }

        if (status == -1)
        {
            printl("[MAPGEN] Compilation FAILED.");
            return;
        }
    }.bindenv(this), 0.2);
}

MG_GenerateAndCompile(RandomInt(1,999999),30)