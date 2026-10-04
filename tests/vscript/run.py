#!/usr/bin/env python3
"""Compile affected scripts and run engine-boundary regressions with the bundled VM."""
from pathlib import Path
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
SQUIRREL = ROOT / 'sp/src/vscript/squirrel'
SCRIPTS = ('flash.nut', 'player_client.nut', 'keypad.nut', 'password.nut',
           'minimap.nut', 'minimap_redux.nut')


def run(command):
    result = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
    if result.returncode or 'AN ERROR HAS OCCURRED' in result.stderr:
        raise RuntimeError(f'{command}\n{result.stdout}\n{result.stderr}')
    if result.stdout:
        print(result.stdout, end='')


with tempfile.TemporaryDirectory(prefix='sourceworld-vscript-') as temporary:
    work = Path(temporary)
    vm = os.environ.get('SQUIRREL_BIN')
    if not vm:
        vm = str(work / 'sq')
        run(['g++', '-O2', '-D_SQ64', '-fno-exceptions', '-fno-rtti',
             '-I' + str(SQUIRREL / 'include'), '-I' + str(SQUIRREL / 'squirrel'),
             *map(str, sorted((SQUIRREL / 'squirrel').glob('*.cpp'))),
             *map(str, sorted((SQUIRREL / 'sqstdlib').glob('*.cpp'))),
             str(SQUIRREL / 'sq/sq.c'), '-o', vm])
    for script in SCRIPTS:
        run([vm, '-c', '-o', str(work / 'script.cnut'), script])
    print(f'PASS: syntax ({len(SCRIPTS)} game scripts)')
    run([vm, 'tests/vscript/flashlight.nut'])

    # Execute the real client update against missing/reordered render entities.
    source = (ROOT / 'player_client.nut').read_text()
    start = source.index('local MyFlashLight=null')
    end = source.index('LastPlrAng = MainViewAngles()', start)
    selection = source[start:end]
    fixture = (ROOT / 'tests/vscript/client_flashlight.nut').read_text()
    generated = work / 'client_flashlight.nut'
    generated.write_text(fixture.replace('// CLIENT_UPDATE', selection))
    run([vm, str(generated)])

    # These file-backed textures must be acquired outside Paint, without reloads.
    for script in ('keypad.nut', 'password.nut'):
        source = (ROOT / script).read_text()
        init = source.index('local KeypadTexture = surface.ValidateTexture(')
        paint = source.index('function Paint()')
        assert init < paint, script
        assert 'true, false, false' in source[init:paint], script
        assert source.count('surface.ValidateTexture(') == 1, script
        assert 'surface.SetTexture(KeypadTexture)' in source[paint:], script
    for script in ('minimap.nut', 'minimap_redux.nut'):
        source = (ROOT / script).read_text()
        assert ',true,true,true)' not in source, script
    print('PASS: keypad/minimap texture lifecycle checks')
