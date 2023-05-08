script_name('ChatGPT')
script_author('chapo')

local ffi = require('ffi')
local inicfg = require('inicfg')
ffi.cdef('int MessageBoxA(void* hWnd, const char* lpText, const char* lpCaption, unsigned int uType);')
local _require = require
-- local require = function(moduleName, url)
--     local status, module = pcall(_require, moduleName)
--     if status then return module end
--     local response = ffi.C.MessageBoxA(ffi.cast('void*', readMemory(0x00C8CF88, 4, false)), ('Библиотека "%s" не найдена.%s'):format(moduleName, url and '\n\nОткрыть страницу загрузки?' or ''), thisScript().name, url and 4 or 0)
--     if response == 6 then
--         os.execute(('explorer "%s"'):format(url))
--     end
-- end


local imgui = require('mimgui', 'https://www.blast.hk/threads/66959/')
local effil = require('effil', 'https://blast.hk/attachments/19493/')
local encoding = require('encoding')
local faInstalled, faicons = pcall(require, 'fAwesome6', 'https://www.blast.hk/threads/111224/')
if not faInstalled then
    faicons = function(str) return '##'..str end
end
encoding.default = 'CP1251'
u8 = encoding.UTF8




local iniFileName = 'ChatGPT\\settings.ini'
local ini = inicfg.load({
    main = {
        token = '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',
        model = 'gpt-3.5-turbo',
        top_p = '1',
        temperature = '0.9',
        frequency_penalty = '0',
        presence_penalty = '0.6',
        max_tokens = '200',
    },
}, iniFileName)
inicfg.save(ini, iniFileName)

local Rooms = { 
    load = function()
        local function getFilesInPath(path, ftype) ;assert(path, '"path" is required'); ;assert(type(ftype) == 'table' or type(ftype) == 'string', '"ftyp" must be a string or array of strings'); ;local result = {}; ;for _, thisType in ipairs(type(ftype) == 'table' and ftype or { ftype }) do ;local searchHandle, file = findFirstFile(path..'\\'..thisType); ;table.insert(result, file) ;while file do file = findNextFile(searchHandle) table.insert(result, file) end ;end return result; end
        local result = {}
        for _, filename in ipairs(getFilesInPath(getWorkingDirectory()..'\\config\\ChatGPT', '*.json')) do
            local F = io.open(getWorkingDirectory()..'\\config\\ChatGPT\\'..filename, 'r')
            if F then
                local data = F:read('*a')
                F:close()

                local decoded, json = pcall(decodeJson, data)
                if decoded and json then
                    table.insert(result, json)
                end
            end
        end
        return result
    end,
    save = function(r)
        for index, data in ipairs(r) do
            local F = io.open(getWorkingDirectory()..'\\config\\ChatGPT\\'..tostring(index)..'.json', 'w')
            if F then
                local status, encoded = pcall(encodeJson, data)
                F:write((status and encoded) and encoded or '[]')
                F:close()
            end
        end
    end
}
local window = imgui.new.bool(false)
local rooms = Rooms.load()
local activeRoom = -1
local input = imgui.new.char[2048]('')
local S = {
    token = imgui.new.char[128](ini.main.token),
    model = imgui.new.char[128](ini.main.model),
    top_p = imgui.new.float(ini.main.top_p),
    temperature = imgui.new.float(ini.main.temperature),
    frequency_penalty = imgui.new.float(ini.main.frequency_penalty),
    presence_penalty = imgui.new.float(ini.main.presence_penalty),
    max_tokens = imgui.new.int(ini.main.max_tokens),
}

function save()
    ini.main.token = ffi.string(S.token)
    ini.main.model = ffi.string(S.model)
    ini.main.top_p = S.top_p[0]
    ini.main.temperature = S.temperature[0]
    ini.main.frequency_penalty = S.frequency_penalty[0]
    ini.main.presence_penalty = S.presence_penalty[0]
    ini.main.max_tokens = S.max_tokens[0]
    Rooms.save(rooms)
    inicfg.save(ini, iniFileName)
end

imgui.OnInitialize(function() 
    imgui.GetIO().IniFilename = nil
    imgui.GetStyle().WindowPadding = imgui.ImVec2(0, 0)
    imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().FrameRounding = 3
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().WindowMinSize = imgui.ImVec2(300, 200)
    -- imgui.GetStyle().FramePadding = imgui.ImVec2(10, 0)
    -- imgui.GetStyle().Colors[imgui.Col.WindowTitle] = imgui.ImVec4(0.13, 0.13, 0.14, 1)
    imgui.GetStyle().Colors[imgui.Col.ChildBg] = imgui.ImVec4(0.13, 0.13, 0.14, 1)
    imgui.GetStyle().Colors[imgui.Col.TitleBg] = imgui.ImVec4(0.13, 0.13, 0.14, 1)
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.13, 0.13, 0.14, 1)
    imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(0, 0, 0, 0)
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.21, 0.21, 0.25, 1)
    imgui.GetStyle().Colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.21, 0.21, 0.25, 1)
    imgui.GetStyle().Colors[imgui.Col.WindowBg] = imgui.ImVec4(0.21, 0.21, 0.25, 1)
    imgui.GetStyle().Colors[imgui.Col.FrameBg] = imgui.ImVec4(0.13, 0.13, 0.14, 1)

    if faInstalled then
        imgui.GetIO().IniFilename = nil
        local config = imgui.ImFontConfig()
        config.MergeMode = true
        config.PixelSnapH = true
        iconRanges = imgui.new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
        imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 14, config, iconRanges) -- solid - тип иконок, так же есть thin, regular, light и duotone
    end
end)

imgui.OnFrame(
    function() return window[0] end,
    function(this)
        local size, res = imgui.ImVec2(600, 400), imgui.ImVec2(getScreenResolution())
        imgui.SetNextWindowPos(imgui.ImVec2(res.x / 2, res.y / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(size, imgui.Cond.FirstUseEver)
        if imgui.Begin('ChatGPT', window, imgui.WindowFlags.NoCollapse) then
            local size = imgui.GetWindowSize()
            local DL = imgui.GetWindowDrawList()

            if imgui.BeginChild('rooms', imgui.ImVec2(size.x / 3.5, size.y - imgui.GetCursorPosY()), false) then
                local bx = size.x / 3.5 - 10
                imgui.SetCursorPos(imgui.ImVec2(5, 5))
                if imgui.Button(faicons('PLUS') .. ' New Chat', imgui.ImVec2(bx, 25)) then 
                    table.insert(rooms, {})
                    save()
                end

                imgui.Spacing()
                imgui.Separator()
                imgui.Spacing()
                
                imgui.PushStyleVarVec2(imgui.StyleVar.ButtonTextAlign, imgui.ImVec2(0, 0.5))
                if imgui.BeginChild('roomsList', imgui.ImVec2(size.x / 3.5, size.y - imgui.GetCursorPosY() - 60), false) then
                    for index, list in pairs(rooms) do
                        imgui.SetCursorPosX(5)
                        local __start = imgui.GetCursorScreenPos()
                        if imgui.Button(faicons('MESSAGE') .. ' ' .. (list[1] and list[1].content or 'No messages here')..'##BUTTON_ROOM_'..index, imgui.ImVec2(bx - 25, 25)) then activeRoom = index end
                        if imgui.IsItemHovered() then
                            imgui.GetWindowDrawList():AddRectFilledMultiColor(imgui.ImVec2(__start.x + bx - 75, __start.y), imgui.ImVec2(__start.x + bx, __start.y + 25), 0x00232120, 0xFF232120, 0xFF232120, 0x00232120)
                        end
                        imgui.SameLine(bx - 20)
                        if imgui.Button(faicons('trash')..'##BUTTON_DELETE_CHAT_'..index, imgui.ImVec2(25, 25)) then 
                            if activeRoom == index then
                                activeRoom = -1
                            end
                            table.remove(rooms, index)
                            save()
                        end
                        local __end = imgui.GetCursorScreenPos()
                        if activeRoom == index then
                            imgui.GetWindowDrawList():AddRect(imgui.ImVec2(__start.x, __start.y), imgui.ImVec2(__start.x + bx, __start.y + 25), 0xCCffffff, 3)
                        end
                    end
                end
                imgui.EndChild()
                imgui.PopStyleVar()
                imgui.SetCursorPosX(5)
                if imgui.Button(faicons('gear') .. '##BUTTON_SETTINGS') then
                    imgui.OpenPopup('ChatGPT Settings')
                end

                imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(5, 5))
                if imgui.BeginPopupModal('ChatGPT Settings', nil, imgui.WindowFlags.NoResize) then
                    imgui.SetWindowSizeVec2(imgui.ImVec2(300, 280))

                    imgui.CustomInput('Token', 'OpenAI Token', S.token, ffi.sizeof(S.token), imgui.InputTextFlags.Password, 245)
                    imgui.CustomInput('Model', 'Example: gpt-3.5-turbo', S.model, ffi.sizeof(S.model), nil, 245)
                    imgui.Link('https://platform.openai.com/account/api-keys', 'Get token')
                    imgui.PushItemWidth(155)
                    imgui.SliderFloat('top_p', S.top_p, 0, 1)
                    imgui.SliderFloat('temperature', S.temperature, 0, 1)
                    imgui.SliderFloat('frequency_penalty', S.frequency_penalty, 0, 2)
                    imgui.SliderFloat('presence_penalty', S.presence_penalty, 0, 2)
                    imgui.SliderInt('max_tokens', S.max_tokens, 5, 1000)
                    imgui.PopItemWidth()

                    if imgui.Button(faicons('xmark') .. ' Save and close', imgui.ImVec2(290, 30)) then
                        save()
                        imgui.CloseCurrentPopup()
                    end

                    imgui.EndPopup()
                end
                imgui.PopStyleVar()
            end
            imgui.EndChild()

            imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0, 0, 0, 0))
            imgui.SetCursorPos(imgui.ImVec2(size.x / 3.5 + 10, 30))
            if imgui.BeginChild('chat', imgui.ImVec2(size.x - (size.x / 3.5) - 20, size.y - 10 - 10 - 20 - 20 - 10), false) then
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.05, 0.64, 0.49, 1))
                if rooms[activeRoom] then
                    imgui.SetCursorPosY(10)
                    for index, message in ipairs(rooms[activeRoom]) do
                        imgui.SetCursorPosX(10)

                        local color = message.role == 'assistant' and imgui.ImVec4(0.05, 0.64, 0.49, 1) or (message.system and imgui.ImVec4(1, 0, 0, 1) or imgui.ImVec4(0.78, 0.27, 0.29, 1))
                        imgui.PushStyleColor(imgui.Col.Button, color)
                        imgui.PushStyleColor(imgui.Col.ButtonActive, color)
                        imgui.PushStyleColor(imgui.Col.ButtonHovered, color)
                        imgui.Button(faicons(message.role == 'assistant' and 'robot' or (message.system and 'SYSTEM' or 'user')), imgui.ImVec2(30, 30))
                        imgui.PopStyleColor(3)
                        imgui.SameLine()
                        imgui.TextColored(message.system and imgui.ImVec4(1, 0, 0, 1) or imgui.ImVec4(1, 1, 1, 0.7), message.role == 'assistant' and 'ChatGPT' or (message.system and 'SYSTEM' or 'You'))
                        imgui.SameLine()
                        if imgui.TextButton(faicons('copy')) then
                            setClipboardText(u8:decode(message.content or '_'))
                            sampAddChatMessage('ChatGPT >> Copied to clipboard!', -1)
                        end

                        imgui.SetCursorPos(imgui.ImVec2(10 + 30 + 5, imgui.GetCursorPosY() - 15))
                        if imgui.BeginChild('message'..index, imgui.ImVec2(imgui.GetWindowWidth() - imgui.GetCursorPosX() - 10, imgui.CalcTextSize(message.content, nil, nil, imgui.GetWindowWidth() - imgui.GetCursorPosX() - 10).y), false)  then
                            imgui.TextWrapped(message.content)
                        end
                        imgui.EndChild()
                    end
                end
                imgui.PopStyleColor()
            end
            imgui.EndChild()
            imgui.PopStyleColor()

            imgui.SetCursorPosX(size.x / 3.5 + 10)
            
            --// input
            imgui.PushItemWidth(size.x - size.x / 3.5 - 50)
            imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(5, 5))
            if imgui.InputText('##input', input, ffi.sizeof(input), imgui.InputTextFlags.EnterReturnsTrue) then sendInput() end
            imgui.PopStyleVar()
            imgui.PopItemWidth()

            --// send button
            imgui.SameLine()
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.13, 0.13, 0.14, 1))
            if imgui.Button(faicons('paper_plane_top'), imgui.ImVec2(25, 25)) then sendInput() end
            imgui.PopStyleColor()
            imgui.End()
        end
    end
)

function imgui.TextButton(label)
    local p = imgui.GetCursorPos()
    imgui.TextColored(imgui.GetStyle().Colors[imgui.Col.Button], label)
    -- local p2 = imgui.GetCursorPos()
    -- if imgui.IsItemHovered() or imgui.IsItemClicked() then
    --     imgui.SetCursorPos(p)
    --     imgui.TextColored(imgui.GetStyle().Colors[imgui.IsItemClicked() and imgui.Col.ButtonActive or imgui.Col.ButtonHovered], label)
    --     imgui.NewLine()
    --     imgui.SetCursorPos(p2)
    -- end
    return imgui.IsItemClicked()
end

function main()
    while not isSampAvailable() do wait(0) end
    sampRegisterChatCommand('chatgpt', function()
        window[0] = not window[0]
    end)
    sampRegisterChatCommand('__testsyncrequest', function()
        asyncHttpRequest('GET', 'http://ip-api.com/json/', {}, function() print('ok') end, function() print('err') end)
    end)
    wait(-1)
end

function sendInput()
    if not rooms[activeRoom] then
        table.insert(rooms, {})
        activeRoom = #rooms
    end
    table.insert(rooms[activeRoom], {
        role = 'user',
        content = ffi.string(input)
    })
    print(encodeJson(rooms[activeRoom]))
    sendToChatGptAsync(rooms[activeRoom], function(response)
        if response.status_code == 200 then
            local decodeStatus, data = pcall(decodeJson, response.text)
            if decodeStatus and data and #data.choices > 0 then
                local choices = data.choices
                math.randomseed(os.time() * math.random(19, 29999))
                table.insert(rooms[activeRoom], choices[math.random(1, #choices)].message)
            else
                table.insert(rooms[activeRoom], {
                    system = true,
                    content = ('Error decoding response! Decoded: %s, data: %s, dataLen: %s'):format(decodeStatus, data, #data)
                })
            end
            save()
        else
            table.insert(rooms[activeRoom], {
                system = true,
                content = 'Error sending request, code '..response.status_code..': '..tostring(response.text)
            })
        end
    end, function(error)
        table.insert(rooms[activeRoom], {
            system = true,
            content = 'Error in async request: '..tostring(error)
        })
    end)

    imgui.StrCopy(input, '')
end
--
function sendToChatGptAsync(messages, callbackOk, callbackError)
    for k, v in pairs(messages) do
        if v.system then
            table.remove(messages, k)
        end
    end
    asyncHttpRequest('POST', 'https://api.openai.com/v1/chat/completions', {
        headers = {
            Authorization = 'Bearer '..ffi.string(S.token),
            ['Content-Type'] = 'application/json'
        },
        data = encodeJson({
            model = ffi.string(S.model),
            messages = messages,
            temperature = S.temperature[0],
            max_tokens = S.max_tokens[0],
            top_p = S.top_p[0],
            frequency_penalty = S.frequency_penalty[0],
            presence_penalty = S.presence_penalty[0],
            stop = {'You:'}
        })
    }, callbackOk, callbackError)
end

function imgui.CustomInput(name, hint, buffer, bufferSize, flags, width)
    local width = width or imgui.GetWindowSize().x / 2;
    local DL = imgui.GetWindowDrawList();
    local pos = imgui.GetCursorScreenPos();
    local nameSize = imgui.CalcTextSize(name);
    local padding = imgui.GetStyle().FramePadding;
    DL:AddRectFilled(
        pos,
        imgui.ImVec2(pos.x + padding.x * 2 + nameSize.x, pos.y + nameSize.y + padding.y * 2),
        imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]),
        imgui.GetStyle().FrameRounding, 1 + 4
    );
    DL:AddRectFilled(
        imgui.ImVec2(pos.x + padding.x * 2 + nameSize.x, pos.y),
        imgui.ImVec2(pos.x + padding.x * 2 + nameSize.x + width, pos.y + nameSize.y + padding.y * 2),
        imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.FrameBg]),
        imgui.GetStyle().FrameRounding,
        10
    );
    DL:AddText(imgui.ImVec2(pos.x + padding.x, pos.y + padding.y), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Text]), name);
    imgui.SetCursorScreenPos(imgui.ImVec2(pos.x + padding.x * 2 + nameSize.x, pos.y))
    imgui.PushItemWidth(width);
    imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0, 0, 0, 0));
    local input = imgui.InputTextWithHint('##customInput_'..tostring(name), hint or '', buffer, bufferSize, flags);
    imgui.PopStyleColor();
    imgui.PopItemWidth();

    return input;
end

function requestRunner()
    return effil.thread(function(method, url, args)
        local requests = require 'requests'
        local _args = {}
        local function table_assign(target, def, deep)
            for k, v in pairs(def) do
                if target[k] == nil then
                    if type(v) == 'table' or type(v) == 'userdata' then
                        target[k] = {}
                        table_assign(target[k], v)
                    else
                        target[k] = v
                    end
                elseif deep and (type(v) == 'table' or type(v) == 'userdata') and (type(target[k]) == 'table' or type(target[k]) == 'userdata') then
                    table_assign(target[k], v, deep)
                end
            end
            return target
        end
        table_assign(_args, args, true)
        local result, response = pcall(requests.request, method, url, _args)
        if result then
            response.json, response.xml = nil, nil
            return true, response
        else
            return false, response
        end
    end)
end

function handleAsyncHttpRequestThread(runner, resolve, reject)
    local status, err
    repeat
        status, err = runner:status() 
        wait(0)
    until status ~= 'running'
    if not err then
        if status == 'completed' then
            local result, response = runner:get()
            if result then
                resolve(response)
            else
                reject(response)
            end
        return
        elseif status == 'canceled' then
            return reject(status)
        end
    else
        return reject(err)
    end
end

function asyncHttpRequest(method, url, args, resolve, reject)
    assert(type(method) == 'string', '"method" expected string')
    assert(type(url) == 'string', '"url" expected string')
    assert(type(args) == 'table', '"args" expected table')
    local thread = requestRunner()(method, url, effil.table(args)) 
    if not resolve then resolve = function() end end
    if not reject then reject = function() end end
    
    return {
        effilRequestThread = thread;
        luaHttpHandleThread = lua_thread.create(handleAsyncHttpRequestThread, thread, resolve, reject);
    }
end

function imgui.Link(link, text) text = text or link;local tSize = imgui.CalcTextSize(text);local p = imgui.GetCursorScreenPos();local DL = imgui.GetWindowDrawList();local col = { 0xFFFF7700, 0xFFFF9900 };if imgui.InvisibleButton("##" .. link, tSize) then os.execute("explorer " .. link) end;local color = imgui.IsItemHovered() and col[1] or col[2];DL:AddText(p, color, text);DL:AddLine(imgui.ImVec2(p.x, p.y + tSize.y), imgui.ImVec2(p.x + tSize.x, p.y + tSize.y), color) end
