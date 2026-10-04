// Exercise the actual client flashlight update with renderer-facing mocks.
class Vector
{
    x = 0; y = 0; z = 0;
    constructor(a, b, c) { x = a; y = b; z = c; }
    function _add(v) { return Vector(x + v.x, y + v.y, z + v.z); }
    function _sub(v) { return Vector(x - v.x, y - v.y, z - v.z); }
    function _mul(n) { return Vector(x * n, y * n, z * n); }
    function Length() { return sqrt(x*x + y*y + z*z); }
}
function MainViewOrigin() { return Vector(1, 2, 3); }
function PrevMainViewOrigin() { return Vector(1, 2, 3); }
function MainViewAngles() { return Vector(0, 0, 0); }
function MainViewForward() { return Vector(1, 0, 0); }
function AngleVectors(_) { return Vector(1, 0, 0); }
function FrameTime() { return 0.016; }
function Time() { return 1.0; }
VMBobAngles <- Vector(0, 0, 0);
PlrAngOffset <- Vector(0, 0, 0);
PlayerFlashlight <- true;
veltime <- 0.0;

class Entity
{
    kind = null;
    moves = 0;
    alpha = null;
    attachment = 1;
    attachmentReads = 0;
    constructor(classname) { kind = classname; }
    function GetClassname() { return kind; }
    function SetLocalOrigin(_) { ++moves; }
    function SetLocalAngles(_) {}
    function SetRenderAlpha(value) { assert(kind == "env_sprite"); alpha = value; }
    function LookupAttachment(_) { return attachment; }
    function GetAttachmentOrigin(index) {
        assert(index > 0);
        ++attachmentReads;
        return Vector(4, 5, 6);
    }
    function GetAttachmentAngles(index) { assert(index > 0); return Vector(0, 0, 0); }
}
local first = Entity("env_projectedtexture");
local second = Entity("env_projectedtexture");
local sprite = Entity("env_sprite");
local unrelated = Entity("info_target");
local model = Entity("prop_dynamic");
local fixtures = [
    [sprite, first, second], [first, sprite, second], [first, second, sprite],
    [first, second], [sprite], [], [unrelated, sprite, first, second]
];
foreach (attachment in [0, 1])
{
    foreach (fixture in fixtures)
    {
        first.moves = 0;
        second.moves = 0;
        sprite.moves = 0;
        unrelated.moves = 0;
        model.attachment = attachment;
        model.attachmentReads = 0;
        Entities <- {
            FindByName = function(cursor, name) {
                if (name == "PlayerModel") return model;
                local index = cursor ? fixture.find(cursor) + 1 : 0;
                return index < fixture.len() ? fixture[index] : null;
            }
        };
        local update = function() {
            // CLIENT_UPDATE
        };
        update();
        local hasLights = fixture.find(first) != null && fixture.find(second) != null;
        assert(first.moves == (hasLights ? 1 + attachment : 0));
        assert(second.moves == (hasLights ? 1 : 0));
        assert(unrelated.moves == 0);
        assert(model.attachmentReads == (hasLights ? attachment : 0));
        assert(sprite.moves == (hasLights && fixture.find(sprite) != null ? attachment : 0));
    }
}
print("PASS: client update with reordered/missing entities and missing chest attachment\n");
