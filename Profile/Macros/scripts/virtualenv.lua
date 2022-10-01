local repo = nil
local options = '--system-site-packages'
local conemu = "4B675D80-1D4A-4EA9-8436-FDC23F2FC14B"

local function list_environments(active_env)
    local folder = mf.fsplit(APanel.Path, 0x04 + 0x08)

    local parent = mf.fsplit(APanel.Path, 0x01 + 0x02)
    parent = mf.fsplit(string.sub(parent, 0, #parent - 1), 0x04 + 0x08)

    local idx = nil
    local items = {}
    for dirname in io.popen('dir /B /AD '..repo):lines() do
        local fullpath = repo .. '\\' .. dirname
        local item = {text = dirname, fullpath = fullpath}
        if fullpath == active_env then
            item.checked = true
        end
        table.insert(items, item)

        if folder == dirname then
            idx = #items
        end
        if idx == nil and parent == dirname then
            idx = #items
        end
    end
    return items, idx
end

local function create3()
    local folder = mf.fsplit(APanel.Path, 0x04 + 0x08)

    local name = prompt('Create new Python 3 virtualenv', 'Name', 0x1 + 0x10, folder)

    if name then
        local items = list_environments(nil)
        for i, item in ipairs(items) do
            if item.text == name then
                far.Message('VirtualEnv "' .. item.text .. '" already exists', 'VirtualEnv', ';Ok')
                exit()
            end
        end

        local command_line = nil
        if not CmdLine.Empty then
            command_line = CmdLine.Value
        end

        local path = repo .. '\\' .. name

        Keys('CtrlY')
        print('py -3 -m venv ' ..options.. ' ' .. path)
        Keys('Enter')

        if command_line then
            print(command_line)
        end
    end
end


local function activate(item)
    local activator = item.fullpath .. '\\Scripts\\activate.bat > nul 2>&1 && set'

    for line in io.popen(activator):lines() do
        local i = string.find(line, '=')
        local var = string.sub(line, 0, i-1)
        local value = string.sub(line, i+1)
        win.SetEnv(var, value)
    end
end

local function deactivate()
    for i, var in ipairs({'PROMPT', 'PYTHONHOME', 'PATH'}) do
        local old_var = '_OLD_VIRTUAL_' .. var
        local val = win.GetEnv(old_var)
        if val then
            win.SetEnv(var, val)
            win.SetEnv(old_var, nil)
        end
    end
    if win.GetEnv('VIRTUAL_ENV') then
        win.SetEnv('VIRTUAL_ENV', nil)
    end
end

local function remove(item)
    local res = far.Message('Do you wish to delete '..item.text..'?', 'VirtualEnv', ';YesNo', 'w')
    if res == 0 then
        os.execute('rmdir /S /Q '..item.fullpath)
    end
end

local function goto_site_packages(item)
    -- if passive panel is hidden or not in normal mode...
    if not PPanel.Visible then Keys("CtrlP") end
    if PPanel.Type==1 then Keys("CtrlT")
    elseif PPanel.Type==2 then Keys("CtrlQ")
    elseif PPanel.Type==3 then Keys("CtrlL") end

    Panel.SetPath(1, item.fullpath .. '\\Lib\\site-packages')
end

local function activate_deactivate()
    local active_env = win.GetEnv('VIRTUAL_ENV')

    -- Flags = 0x02 — no hotkeys
    local menu_options = {Title = "VirtualEnv", Bottom = "Enter,Ctrl+Enter,Del", Flags = 0x02}
    local items, selected = list_environments(active_env)

    if selected then
        menu_options.SelectIndex = selected
    end

    local bkeys = {{BreakKey = 'DELETE'}, {BreakKey = 'C+RETURN'}}
    local item, pos = far.Menu(menu_options, items, bkeys)

    if item then
        if item.BreakKey then
            local selected = items[pos]
            if item.BreakKey == 'C+RETURN' then
                goto_site_packages(selected)
            elseif item.BreakKey == 'DELETE' then
                remove(selected)
                -- activate_deactivate()
            end
        else
            if item.fullpath == active_env then
                deactivate()
                if Plugin.SyncCall(conemu,"IsConEmu")=="Yes" then
                  Plugin.SyncCall(conemu, "Rename(0")
                end
            else
                activate(item)
                if Plugin.SyncCall(conemu, "IsConEmu")=="Yes" then
                  Plugin.SyncCall(conemu, 'Rename(0, "venv: ' .. item.text)
                end
            end
        end
    end
end

local function safe(fn)
    local workon = win.GetEnv('WORKON_HOME')

    if workon then
        repo = workon
    else
        repo = win.GetEnv('USERPROFILE') .. '\\.virtualenvs'
    end

    if not mf.fexist(repo) then
        local r = win.CreateDir(repo, 't')
        if not r then
            far.Message('Can\'t create folder "' .. repo .. '"', 'VirtualEnv', ';Ok', 'w')
        else
            local state = Far.DisableHistory(-1)
            fn()
            Far.DisableHistory(state)
        end
    else
        local state = Far.DisableHistory(-1)
        fn()
        Far.DisableHistory(state)
    end
end

Macro {
  area="Shell";
  key="virtualenv:activate";
  description="Activate VirtualEnv";
  action = function()
    safe(activate_deactivate)
  end;
}

Macro {
  area="Shell";
  key="virtualenv:create3";
  description="Create py3 VirtualEnv";
  action = function()
    safe(create3)
  end;
}
