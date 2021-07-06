script_name("sensfix")
script_author("Montri")
script_version("1.0.0")



require"lib.moonloader"
require"lib.sampfuncs"
local raknet = require"lib.samp.raknet"
local ffi =			require "ffi"
local inicfg = require "inicfg"
local imgui = require "imgui"
local ec = require "encoding"
local fa         = require 'fAwesome5'
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
local lfs        = require 'lfs'
local memory = require("memory")
local sens = 0
ec.default = 'CP1251'
u8 = ec.UTF8


path = getWorkingDirectory() .. '\\config\\Montris Folder\\'
cfg = path .. 'Sensfix.ini'


function blankIni()
	sensfix = {
		globalSense = 0.2345,
        aimingSense = 0.163,
        scopeSense = 0.165,
	}
	saveIni()
end

function loadIni()
	local f = io.open(cfg, "r")
	if f then
		sensfix = decodeJson(f:read("*all"))
		f:close()
	end
end

function saveIni()
	if type(sensfix) == "table" then
		local f = io.open(cfg, "w")
		f:close()
		if f then
			local f = io.open(cfg, "r+")
			f:write(encodeJson(sensfix))
			f:close()
		end
	end
end


local fsFont = nil
function imgui.BeforeDrawFrame()
	if fa_font == nil then
		local font_config = imgui.ImFontConfig()
		font_config.MergeMode = true
		fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 13.0, font_config, fa_glyph_ranges)
	end
    if fsFont == nil then
        fsFont = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 25.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
end

if not doesDirectoryExist(path) then createDirectory(path) end
if doesFileExist(cfg) then loadIni() else blankIni() end
local all_senses = {[0] = sensfix.globalSense, [1] = sensfix.aimingSense, [2] = sensfix.scopeSense}

local main_window_state = imgui.ImBool(false)
local global_sense = imgui.ImFloat(all_senses[0])
local aiming_sense = imgui.ImFloat(all_senses[1])
local sniper_sense = imgui.ImFloat(all_senses[2])
function imgui.OnDrawFrame()
	if main_window_state.v then
		local sw, sh = getScreenResolution() -- Get Screenresolution to make perfect results.
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(400, 215), imgui.Cond.FirstUseEver)
		imgui.Begin("", main_window_state.v, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar)
		imgui.PushFont(fsFont) imgui.CenterTextColoredRGB('Sensfix') imgui.PopFont()
        if imgui.InputFloat(fa.ICON_FA_GLOBE .. ' Global Sense', global_sense, 0.001, 1.000) then
            all_senses[0] = global_sense.v
        end 
        if imgui.InputFloat(fa.ICON_FA_CROSSHAIRS .. ' Aiming Sense', aiming_sense, 0.001, 1.000) then
            all_senses[1] = aiming_sense.v
        end 
        if imgui.InputFloat(fa.ICON_FA_CROSSHAIRS .. ' Sniper Sense', sniper_sense, 0.001, 1.000) then
            all_senses[2] = sniper_sense.v
        end 
        if imgui.Button(fa.ICON_FA_UPLOAD .. " Transfer from sensfix.asi", imgui.ImVec2(415,30)) then 
            if getModuleHandle("sensfix.asi") ~= 0 or getModuleHandle("sensfix") ~= 0 then
                sampAddChatMessage("{05D353}[Sensfix] {FFFFFF} Cannot copy config from sensfix.asi while its actively running!")
            else
                local table = lines_from("sensfix.ini")
                for k,v in pairs(table) do
                    print('line[' .. k .. ']', v)
                end
                if table[1] == " [sensfix]" and string.find(table[2], " aiming_sniper=") and string.find(table[3], " aiming=") and string.find(table[4], " global=") then
                    print("this is a legit file.")
                    aiming_sniper = string.gsub(table[2], " aiming_sniper=", "")
                    aiming_normal = string.gsub(table[3], " aiming=", "")
                    aiming_global = string.gsub(table[4], " global=", "")
                    print(aiming_sniper .. " | " .. aiming_normal .. " | " .. aiming_global)
                    all_senses = {[0] = aiming_global*3.2, [1] = aiming_normal*3.2, [2] = aiming_sniper*3.2}
                    global_sense = imgui.ImFloat(all_senses[0])
                    aiming_sense = imgui.ImFloat(all_senses[1])
                    sniper_sense = imgui.ImFloat(all_senses[2])
                    sampAddChatMessage("{05D353}[Sensfix] {FFFFFF} Transfer successful!")
                    position_x = 0 
                    position_y = 0 
                    position_z = 0 
                    sound = 1057 
                    addOneOffSound(position_x,position_y,position_z,sound)
                else
                    sampAddChatMessage("{05D353}[Sensfix] {FFFFFF} This is not a valid sensfix.asi Config!")
                end 
            end 
        end 
        saveTitle = fa.ICON_FA_SAVE .. " Save"
        if imgui.Button(saveTitle, imgui.ImVec2(60,30)) then
            sensfix.globalSense = all_senses[0]
            sensfix.aimingSense = all_senses[1]
            sensfix.scopeSense = all_senses[2]
            saveIni()
        end 
        imgui.SameLine()
        loadTitle = fa.ICON_FA_DOWNLOAD .. " Load"
        if imgui.Button(loadTitle, imgui.ImVec2(60,30)) then
            loadIni()
            all_senses = {[0] = sensfix.globalSense, [1] = sensfix.aimingSense, [2] = sensfix.scopeSense}
            global_sense = imgui.ImFloat(all_senses[0])
            aiming_sense = imgui.ImFloat(all_senses[1])
            sniper_sense = imgui.ImFloat(all_senses[2])
        end 
        imgui.End()
    end 
end 


function lines_from(file)
    if not file_exists(file) then return {} end
    lines = {}
    for line in io.lines(file) do 
      lines[#lines + 1] = line
    end
    return lines
end

function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end




function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage("{05D353}[Sensfix] {FFFFFF}Made by Montri.")
    sampRegisterChatCommand("sens", sens)
    while true do
        wait(0)
        local weapon = getCurrentCharWeapon(PLAYER_PED)
        if isKeyDown(0x11) then
            detectSpecialSens(weapon, all_senses)
        else
            detectSens(weapon, all_senses) 
        end 
            
		imgui.Process = main_window_state.v
    end 
end 


function sens()
    main_window_state.v = not main_window_state.v
end 





 function detectSpecialSens(weapon)
    if weapon == 22 or weapon == 23 or weapon == 24 or weapon == 25 or weapon == 26 or weapon == 27 or weapon == 28 or weapon == 29 or weapon == 30 or weapon == 31 or weapon == 32 or weapon == 33 or weapon == 35 or weapon == 37 or weapon == 38 then -- Handguns
        SetSens(all_senses[1])
    elseif weapon == 34 or weapon == 36 then -- Bazuga and Sniper
        SetSens(all_senses[2])
    else
        SetSens(all_senses[0])
    end 
end 


function SetSens(sens)
	memory.setfloat(11987996, sens / 1000, false)
	memory.setfloat(11987992, sens / 1000, false)
	return
end

function detectSens(weapon)
    if weapon == 22 or weapon == 23 or weapon == 24 or weapon == 25 or weapon == 26 or weapon == 27 or weapon == 28 or weapon == 29 or weapon == 30 or weapon == 31 or weapon == 32 or weapon == 33 or weapon == 35 or weapon == 37 or weapon == 38 then -- Handguns
        SetSens(all_senses[1])
    elseif weapon == 34 or weapon == 36 then -- Bazuga and Sniper
        SetSens(all_senses[2])
    else
        SetSens(all_senses[0])
    end 
end 




function imgui.CenterTextColoredRGB(text)
    local width = imgui.GetWindowWidth()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local textsize = w:gsub('{.-}', '')
            local text_width = imgui.CalcTextSize(u8(textsize))
            imgui.SetCursorPosX( width / 2 - text_width .x / 2 )
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else
                imgui.Text(u8(w))
            end
        end
    end
    render_text(text)
end

function imgui.TextColoredRGB(text)
    local width = imgui.GetWindowWidth()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local textsize = w:gsub('{.-}', '')
            local text_width = imgui.CalcTextSize(u8(textsize))
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else
                imgui.Text(u8(w))
            end
        end
    end
    render_text(text)
end

function imgui.Hint(text, delay)
    if imgui.IsItemHovered() then
        if go_hint == nil then go_hint = os.clock() + (delay and delay or 0.0) end
        local alpha = (os.clock() - go_hint) * 5 --spawn rate
        if os.clock() >= go_hint then 
            imgui.PushStyleVar(imgui.StyleVar.Alpha, (alpha <= 1.0 and alpha or 1.0))
                imgui.PushStyleColor(imgui.Col.PopupBg, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
                    imgui.BeginTooltip()
                    imgui.PushTextWrapPos(450)
                    imgui.TextUnformatted(text)
                    if not imgui.IsItemVisible() and imgui.GetStyle().Alpha == 1.0 then go_hint = nil end
                    imgui.PopTextWrapPos()
                    imgui.EndTooltip()
                imgui.PopStyleColor()
            imgui.PopStyleVar()
        end
    end
end