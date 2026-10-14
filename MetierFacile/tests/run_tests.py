"""Lance tests/run_tests.lua avec Lua 5.1 (via lupa) si aucun interpréteur lua5.1 n'est installé.
Usage (depuis le dossier MetierFacile) : python3 tests/run_tests.py
"""
import sys
import lupa.lua51 as lupa

lua = lupa.LuaRuntime(unpack_returned_tuples=True)
lua.execute('os.exit = function(code) error("EXIT " .. tostring(code), 0) end')
try:
    lua.execute('dofile("tests/run_tests.lua")')
except lupa.LuaError as err:
    print(err)
    sys.exit(1)
