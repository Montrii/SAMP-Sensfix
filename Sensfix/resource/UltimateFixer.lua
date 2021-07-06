script_author("Montri", "Export (CLEO)", "Albertio (Dual Monitor Fix)", "seven (AirCraft Explosion)")
script_name("UltimateFixer")
script_description("Allows you to fix some nasty issues in the game itself.")
require('lib.moonloader')
local ffi = require('ffi')
local wm  = require('lib.windows.message')

local memory = require "memory"

local result = getModuleHandle("samp.dll")
if result ~= 0 then
    local variable = 0x5CF2C
    writeMemory(variable, 1, 0x90909090, 1)
    variable = variable + 4
    writeMemory(variable, 1, 0x90, 1)
    variable = variable + 9
    writeMemory(variable, 1, 0x90909090, 1)
    variable = variable + 4
    writeMemory(variable, 1, 0x90, 1)
end 
local value = readMemory(5993075, 4, 0)
value = value + 4 
local value2 = readMemory(12045148, 4, 0)
value2 = value2 / 1.66666
value3 = 0.9
value3 = value3 * value2
writeMemory(value, 4, value3, 0)




ffi.cdef [[
	typedef unsigned long HANDLE;
	typedef HANDLE HWND;
	typedef struct _RECT {
		long left;
		long top;
		long right;
		long bottom;
	} RECT, *PRECT;

	HWND GetActiveWindow(void);

	bool GetWindowRect(
		HWND   hWnd,
		PRECT lpRect
	);

	bool ClipCursor(const RECT *lpRect);

	bool GetClipCursor(PRECT lpRect);
]]

local rcClip, rcOldClip = ffi.new('RECT'), ffi.new('RECT')

function main()
  ffi.C.GetWindowRect(ffi.C.GetActiveWindow(), rcClip);
  ffi.C.ClipCursor(rcClip);
  -- memory.setuint32(0x736F88, 0, true) AIRPLANE EXPLOSION
  while true do
    wait(0)
	if isCharInAnyCar(PLAYER_PED) and isCharPlayingAnim(PLAYER_PED, "CAR_FALLOUT_LHS") then -- THIS MIGHT BE REGARDED AS HACK ON RP SERVERS AS YOU TELEPORT
		X, Y, Z = getOffsetFromCharInWorldCoords(PLAYER_PED, 0, 0, 2.5)
		warpCharFromCarToCoord(PLAYER_PED, X, Y, Z) 
	end
  end
end

function onWindowMessage(msg, wparam, lparam)
  if msg == wm.WM_KILLFOCUS then
		ffi.C.GetClipCursor(rcOldClip);
		ffi.C.ClipCursor(rcOldClip);
	elseif msg == wm.WM_SETFOCUS then
		ffi.C.GetWindowRect(ffi.C.GetActiveWindow(), rcClip);
		ffi.C.ClipCursor(rcClip);
	end
end 
    