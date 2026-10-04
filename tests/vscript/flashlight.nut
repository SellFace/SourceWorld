// SourceWorld flashlight tests. Engine calls are mocked; no renderer is started.
local entities = [];
local events = [];
local spawnIndex = 0;
local failSpawn = -1;
local now = 1.0;
local alive = true;

function check(condition, message)
{
    if (!condition) throw message;
}
function Vector(x, y, z) { return { x = x, y = y, z = z }; }
function clamp(value, low, high) { return value < low ? low : (value > high ? high : value); }
Time <- function() { return now; };

class Entity
{
    valid = true;
    name = null;
    classname = null;
    values = null;
    constructor(kind, data) { classname = kind; name = data.targetname; values = data; }
    function IsValid() { return valid; }
    function IsAlive() { return alive; }
    function Destroy() { check(valid, "entity destroyed twice"); valid = false; }
    function GetOrigin() { return Vector(0, 0, 0); }
    function GetAngles() { return Vector(0, 0, 0); }
    function EyeAngles() { return Vector(0, 0, 0); }
    function PrecacheSoundScript(_) {}
    function EmitSound(_) {}
}
player <- Entity("player", { targetname = "player" });
self <- player;
Entities <- {
    FindByName = function(cursor, name) {
        // Emulate a removal that invalidates the search cursor immediately.
        if (cursor) check(cursor.IsValid(), "lookup with destroyed cursor");
        local start = cursor ? entities.find(cursor) + 1 : 0;
        for (local i = start; i < entities.len(); ++i)
            if (entities[i].valid && entities[i].name == name) return entities[i];
        return null;
    }
};
SpawnEntityFromTable <- function(kind, values) {
    if (spawnIndex++ == failSpawn) return null;
    local entity = Entity(kind, values);
    entities.append(entity);
    return entity;
};
EntFireByHandle <- function(entity, input, value = "", delay = 0.0) {
    check(entity != null && entity.IsValid(), "input sent to missing entity");
    events.append({ entity = entity, input = input, value = value, delay = delay });
};
Convars <- { RegisterCommand = function(...) {}, GetInt = function(_) { return 2; } };

function liveCount(list)
{
    local count = 0;
    foreach (entity in list) if (entity.IsValid()) ++count;
    return count;
}

dofile("flash.nut");
// Input/update can run before the deferred initialization callback.
events.clear();
ToggleFlashlight();
PlayerRunCommand();
check(events.len() == 0, "input before initialization");

// Remove all leftovers and keep unrelated entities alive on each restart.
local unrelated = Entity("env_projectedtexture", { targetname = "other_light" });
entities.append(unrelated);
for (local i = 0; i < 3; ++i)
    entities.append(Entity("env_projectedtexture", { targetname = "playerflashlight" }));
for (local i = 0; i < 20; ++i)
{
    OnStartRunning();
    check(liveCount(entities) == 5, "flashlight entities accumulated");
    check(unrelated.IsValid(), "unrelated light removed");
    check(!FlashLightState, "restart left flashlight on");
    ToggleFlashlight();
}

// Every spawned and animated FOV must be valid, including configuration bounds.
foreach (configuredFOV in [-100.0, 0.0, 50.0, 500.0])
{
    FlashLightFOV = configuredFOV;
    OnStartRunning();
    check(MyFlashLight.values.lightfov > 0 && MyFlashLight.values.lightfov < 180, "invalid spawn FOV");
    events.clear();
    ToggleFlashlight();
    local count = 0;
    local finalMain = null;
    local finalFill = null;
    foreach (event in events)
    {
        if (event.input != "fov") continue;
        ++count;
        check(event.value > 0 && event.value < 180, "degenerate projection FOV");
        check(event.delay >= 0 && event.delay <= 0.091, "animation timing changed");
        if (event.entity == MyFlashLight) finalMain = event.value;
        else finalFill = event.value;
    }
    check(count == 20, "incomplete FOV animation");
    check(finalMain == FlashLightFOV && finalFill == 110, "animation missed target FOV");
    ToggleFlashlight();
    check(!FlashLightState, "toggle did not turn off");
}

// A partial spawn must release every successful allocation.
for (local failure = 0; failure < 4; ++failure)
{
    failSpawn = failure;
    spawnIndex = 0;
    OnStartRunning();
    check(liveCount(entities) == 1, "partial spawn leaked resources");
    check(MyFlashLight == null && MyFlashLight2 == null && FlashLightSprite == null && DisableFlashLight == null,
          "partial spawn retained handles");
    events.clear();
    ToggleFlashlight();
    SettingFlashLightStyle(1);
    PlayerRunCommand();
    check(events.len() == 0, "input after failed spawn");
}
failSpawn = -1;
OnStartRunning();
alive = false;
events.clear();
ToggleFlashlight();
check(events.len() == 0, "dead player enabled flashlight");
alive = true;
MyFlashLight2.Destroy();
events.clear();
ToggleFlashlight();
PlayerRunCommand();
check(events.len() == 0, "input sent after external entity removal");
print("PASS: flashlight lifecycle, spawn failures, FOV animation and invalid handles\n");
