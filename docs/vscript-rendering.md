# VScript rendering stability

## Scope and evidence

The reported minidump points into the closed-source materialsystem. No dump or
reproduction is available in this checkout, so these changes fix demonstrable
script problems without establishing the native crash's root cause.

- `flash.nut` used the same handle for two `Destroy()` calls and removed only one
  of the three entities named `playerflashlight`. Initialization now collects all
  matching entities before removing them, resets the enabled state, and releases
  partial allocations when an entity spawn fails. Updates skip missing handles.
- The flashlight animation previously sent FOV 0 and stopped at 90% of the
  configured angle. It now sends ten positive steps through the full angle, with
  the configurable FOV bounded to 1–179 degrees. The server's
  `CEnvProjectedTexture::InputSetFOV` forwards values without validation; the
  client uses them for the projection frustum in `UpdateLight`.
- The client assumed that the first two entities with the shared flashlight name
  were projectors. It now selects by class, tolerates an absent glow sprite, and
  checks the player model's chest attachment before reading its transform.
- Both keypad Paint callbacks requested `ValidateTexture(..., true, true, true)`
  every frame. The third argument forces `DrawSetTextureFile` in
  `CScriptSurface::ValidateTexture` (`sp/src/game/client/mapbase/vscript_vgui.cpp`).
  Keypad textures now load once per UI initialization as file-backed textures.
  Both minimap implementations also use file-backed textures without forced reloads.

A positive texture ID alone does not establish that the underlying material or
texture exists. The mod's actual VMT/VTF assets and native render targets still
need verification in the installed game; the script API inspected here exposes
no material-error check. The patch does not attempt to hide missing assets.

## Automated checks

From the repository root, with Python 3 and a 64-bit g++ toolchain:

```sh
python3 tests/vscript/run.py
```

The runner builds the bundled Squirrel 3.1 VM in a temporary directory, compiles
all six affected game scripts, and exercises mocked engine boundaries. Set
`SQUIRREL_BIN` to an existing compatible interpreter to reuse it. Tests cover
repeated startup, immediate handle invalidation, partial spawn failures, FOV
bounds and animation endpoints, missing entities, reordered client entities, and
texture initialization placement. They do not run the renderer.

## In-game verification still required

Use the installed SourceWorld scripts directory and start a fresh map/session
with the six changed scripts. Copying files into this source checkout alone does
not install them into HL2.

1. Toggle the flashlight rapidly, then test battery depletion and player death.
   Check first-person and player-model views, including models without a chest
   attachment. The glow sprite can be absent without a script error.
2. Repeat flashlight initialization, save/load, and map transitions. Check that
   the settled scene has two `env_projectedtexture` entities and one `env_sprite`
   named `playerflashlight`, plus one `playernoflashlight` speed modifier.
3. Open and close both keypad interfaces and whichever minimap is used by the
   map. Check that textures remain visible after save/load and level changes.
4. If the native crash persists, record the map, action, view mode, active weapon,
   and whether a UI was open. Preserve the next minidump and any missing-material
   console messages. Compare the same scenario with the custom flashlight and UI
   enabled individually to narrow the responsible render path.
