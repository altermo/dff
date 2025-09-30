---@class dff.conf
---@field window 'fullscreen'|'inline'?

local M={ns=vim.api.nvim_create_namespace'dff'}
---@enum dff.colors
M.colors={
    none=-1,
    note=0,
    comment=1,
    normal=2,
    important=3,
    spec=4,
    spec_important=5,
    spec_comment=6,
    important_space=7,
}
---@type table<dff.colors,string>
M.color_to_hl={
    [M.colors.none]='Whitespace',
    [M.colors.note]='DiffAdd',
    [M.colors.comment]='Comment',
    [M.colors.normal]='Normal',
    [M.colors.important]='Title',
    [M.colors.spec]='Special',
    [M.colors.spec_important]='Visual',
    [M.colors.spec_comment]='Comment',
    [M.colors.important_space]='Visual',
}

---@return string
local function get_binary()
    local file=vim.api.nvim_get_runtime_file('dff',false)[1]
    assert(file,'`./dff` not found in runtimepath')
    return file
end
---@param stdout table
---@return table
local function wait_for_event(stdout)
    assert(vim.wait(1000,function () return stdout[1] end,5), '')
    local json=stdout[1]
    stdout[1]=nil
    return vim.json.decode(json)
end
---@param obj vim.SystemObj
local function send_packet(obj,key,win)
    if key==vim.keycode'<bs>' then
        key=0x7f
    end
    local packet={
        row=vim.api.nvim_win_get_height(win),
        col=vim.api.nvim_win_get_width(win),
        key=key
    }
    obj:write(vim.json.encode(packet)..'\n')
end
local function render(packet,buf,win)
    vim.api.nvim_buf_clear_namespace(buf,M.ns,0,-1)
    local lines={}
    for _,entries in ipairs(packet) do
        local line={}
        for _,entry in ipairs(entries) do
            table.insert(line,entry[2])
        end
        table.insert(lines,table.concat(line))
    end
    vim.api.nvim_buf_set_lines(buf,0,-1,true,lines)
    vim.api.nvim_win_set_cursor(win,{1,#lines[1]})
    for row,entries in ipairs(packet) do
        local col=0
        for _,entry in ipairs(entries) do
            local color,text=unpack(entry)
            if #text~=0 then
                vim.hl.range(buf,M.ns,M.color_to_hl[color],{row-1,col},{row-1,col+#text})
                col=col+#text
            end
        end
    end
    vim.api.nvim__redraw({cursor=true,flush=true})
end
local function getchar_or_resized()
    local row,col=vim.o.lines,vim.o.columns
    while true do
        vim.cmd.sleep('5ms')
        local ch=vim.fn.getchar(0)
        if ch~=0 then return ch end
        vim.api.nvim__redraw({cursor=true,flush=true})
        if row~=vim.o.lines or col~=vim.o.columns then
            return
        end
    end
end
---@param conf dff.conf?
function M.run_dir(dir,conf)
    conf=conf or {}
    local buf=vim.api.nvim_create_buf(false,true)
    vim.bo[buf].bufhidden='wipe'
    local win
    local basewin
    if conf.window=='fullscreen' then
        win=vim.api.nvim_open_win(buf,true,{
            row=0,
            col=0,
            relative='editor',
            height=vim.o.lines,
            width=vim.o.columns,
            style='minimal',
        })
    elseif conf.window=='inline' or (conf.window==nil) then
        basewin=vim.api.nvim_get_current_win()
        local basewinconf=vim.api.nvim_win_get_config(basewin)
        win=vim.api.nvim_open_win(buf,true,{
            relative='win',
            row=0,
            col=0,
            height=basewinconf.height,
            width=basewinconf.width,
            style='minimal',
        })
    else
        error('NotImplemented')
    end
    vim.wo[win].winhl='Normal:FloatNormal'
    local bin=get_binary()
    local stdout={}
    local obj=vim.system({bin,'--json'},{cwd=dir,stdout=function (_,event)
        if event then
            stdout[1]=event
        end
    end,stdin=true})
    local function close()
        obj:kill(1)
        local comp=obj:wait(0)
        if comp and comp.code==1 then
            vim.notify('dff python script errored:\n'..comp.stderr)
        end
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win,true)
        end
        close=function () end
    end
    vim.api.nvim_create_autocmd('SafeState',{callback=close,once=true})
    assert(wait_for_event(stdout)[1]=='ready')
    send_packet(obj,nil,win)
    while true do
        local event,packet=unpack(wait_for_event(stdout))
        if event=='exit' then
            close()
            return packet
        end
        render(packet,buf,win)
        local ch=getchar_or_resized()
        if conf.window=='fullscreen' then
            vim.api.nvim_win_set_height(win,vim.o.lines)
            vim.api.nvim_win_set_width(win,vim.o.columns)
        elseif conf.window=='inline' or (conf.window==nil) then
            vim.api.nvim_win_set_height(win,vim.api.nvim_win_get_height(basewin))
            vim.api.nvim_win_set_width(win,vim.api.nvim_win_get_width(basewin))
        end
        send_packet(obj,ch,win)
    end
end
---@param conf dff.conf?
function M.file_expl(dir,conf)
    local path=M.run_dir(dir,conf)
    vim.cmd.edit(vim.uv.fs_realpath(path) or path)
end
return M
