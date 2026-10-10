-- Shared by the editor and exported packs. No editor assets or globals required.
local M = {}
local mouseDown = Input.IsMouseBtnPressed
local keyDown, keyPressed = Input.IsButtonPressed, Input.IsButtonTriggered
local wheel = Input.GetMouseWheel
local function clamp(n,a,b) return math.max(a,math.min(b,n)) end

local theme = include('cm_theme')
local COLORS = theme and theme.colors or {
    overlay={R=0.03,G=0.02,B=0.02,A=0.94}, panel={R=0.60,G=0.52,B=0.43,A=1},
    border={R=0.12,G=0.09,B=0.07,A=1}, button={R=0.66,G=0.55,B=0.43,A=1},
    buttonHover={R=0.73,G=0.60,B=0.46,A=1}, field={R=0.58,G=0.50,B=0.40,A=1},
    white={R=0.15,G=0.12,B=0.10,A=1}, dim={R=0.28,G=0.22,B=0.17,A=1},
    scrollbar={R=0.27,G=0.21,B=0.17,A=1}, scrollbarThumb={R=0.62,G=0.49,B=0.36,A=1},
}

local function colorParts(c)
    if type(c) ~= "number" and c ~= nil then
        local ok,r,g,b,a = pcall(function() return c.R,c.G,c.B,c.A end)
        if ok and type(r)=="number" and type(g)=="number" and type(b)=="number" then
            return r,g,b,type(a)=="number" and a or 1
        end
    end
    return nil
end

local function box(x,y,w,h,r,g,b,a)
    if w<=0 or h<=0 then return end
    local rr,gg,bb,aa = colorParts(r)
    rr,gg,bb,aa=rr or r or 1,gg or g or 1,bb or b or 1,aa or a or 1
    -- DrawLine is stable in every gameplay renderer. Its in-game colour pass
    -- warms UI primitives, so cool the source tint to match the editor paper.
    local kc=KColor(math.min(1,rr*1.10),math.min(1,gg*1.08),math.min(1,bb*0.92),aa)
    Isaac.DrawLine(Vector(x,y+h/2),Vector(x+w,y+h/2),kc,kc,math.floor(h))
end

local function outlinedRect(x,y,w,h,fill,border,thickness)
    if theme and theme.outline then
        theme.outline(box,x,y,w,h,fill,border,thickness or 1)
    else
        box(x,y,w,h,border)
        box(x+1,y+1,w-2,h-2,fill)
    end
end

local paperFont=Font()
local fontReady=pcall(function() paperFont:Load('font/teammeatfont10.fnt') end)
fontReady=fontReady and paperFont:GetStringWidth('ABC')>0

local function text(s,x,y,scale,r,g,b)
    local rr,gg,bb,aa = colorParts(r)
    local color = rr and {R=rr,G=gg,B=bb,A=aa} or {R=r or 0.15,G=g or 0.12,B=b or 0.10,A=1}
    scale=scale or 1
    if theme and theme.text and theme.text(s,x,y,scale,color) then return end
    if fontReady and s~='' then
        local width=paperFont:GetStringWidth(s)
        if width>0 then
            paperFont:DrawStringScaled(s,math.floor(x),math.floor(y),
                Isaac.GetTextWidth(s)*scale/width,scale*0.8,KColor(color.R,color.G,color.B,color.A or 1),0,false)
            return
        end
    end
    Isaac.RenderScaledText(s,x,y,scale,scale,color.R,color.G,color.B,color.A or 1)
end

local function textWidth(s,scale)
    return Isaac.GetTextWidth(s or '')*(scale or 1)
end

local function drawHeader(cx,y,title)
    text(title,cx-textWidth(title,1.45)/2,y,1.45,COLORS.white)
    if theme and theme.header then theme.header(box,cx,y,textWidth(title,1.45)) end
end

local function button(x,y,w,h,label,hover)
    outlinedRect(x,y,w,h,hover and COLORS.buttonHover or COLORS.button,COLORS.border,2)
    text(label,x+w/2-textWidth(label,1)/2,y+h/2-6,1,COLORS.white)
end

local function screenLayout()
    local sw = Isaac.GetScreenWidth()
    local sh = Isaac.GetScreenHeight()
    local panelW = math.min(430, sw - 36)
    local panelH = math.min(330, sh - 28)
    local panelX = (sw - panelW) / 2
    local panelY = (sh - panelH) / 2
    return sw, sh, panelX, panelY, panelW, panelH
end

function M.Wrap(value,width,scale)
    local lines={}
    value=tostring(value or ''):gsub('\r\n','\n'):gsub('\r','\n')
    for paragraph in (value..'\n'):gmatch('(.-)\n') do
        local line=''
        for word in paragraph:gmatch('%S+') do
            local candidate=line=='' and word or line..' '..word
            if Isaac.GetTextWidth(candidate)*scale<=width then line=candidate
            else
                if line~='' then lines[#lines+1]=line;line='' end
                for char in word:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
                    if line~='' and Isaac.GetTextWidth(line..char)*scale>width then lines[#lines+1]=line;line='' end
                    line=line..char
                end
            end
        end
        lines[#lines+1]=line
    end
    return lines
end
local function utf8chars(value)
    local chars={}
    for char in tostring(value or ''):gmatch('[%z\1-\127\194-\244][\128-\191]*') do chars[#chars+1]=char end
    return chars
end
local function editorLines(value,width,scale)
    local lines={{text='',carets={0}}}
    local caret=0
    for _,char in ipairs(utf8chars(value)) do
        if char=='\n' then
            caret=caret+1
            lines[#lines+1]={text='',carets={caret}}
        else
            local line=lines[#lines]
            if line.text~='' and Isaac.GetTextWidth(line.text..char)*scale>width then
                line={text='',carets={caret}}
                lines[#lines+1]=line
            end
            line.text=line.text..char
            caret=caret+1
            line.carets[#line.carets+1]=caret
        end
    end
    return lines,caret
end
local function caretLocation(lines,caret)
    local fallbackLine,fallbackColumn=1,1
    local exactLine,exactColumn=nil,nil
    for lineIndex,line in ipairs(lines) do
        for column,value in ipairs(line.carets) do
            -- At a soft wrap the same caret belongs to the end of one line and
            -- the start of the next. Prefer the latter so clicks at line start
            -- and newly wrapped text draw the caret where the user expects it.
            if value==caret then exactLine,exactColumn=lineIndex,column end
            if value<caret then fallbackLine,fallbackColumn=lineIndex,column end
        end
    end
    if exactLine then return exactLine,exactColumn end
    return fallbackLine,fallbackColumn
end
function M.MoveEditorCaret(value,caret,direction,width)
    local scale=0.9
    local lines,total=editorLines(value,width-24,scale)
    caret=clamp(tonumber(caret) or total,0,total)
    local lineIndex,column=caretLocation(lines,caret)
    local prefix=lines[lineIndex].text
    prefix=prefix:sub(1,(utf8.offset(prefix,column) or (#prefix+1))-1)
    local targetX=Isaac.GetTextWidth(prefix)*scale
    local targetLine=clamp(lineIndex+direction,1,#lines)
    local line=lines[targetLine]
    local bestCaret,bestDistance=line.carets[1],math.huge
    for candidateColumn,candidateCaret in ipairs(line.carets) do
        local candidatePrefix=line.text:sub(1,(utf8.offset(line.text,candidateColumn) or (#line.text+1))-1)
        local distance=math.abs(Isaac.GetTextWidth(candidatePrefix)*scale-targetX)
        if distance<bestDistance then bestCaret,bestDistance=candidateCaret,distance end
    end
    return bestCaret
end
function M.EditorArea(value,caret,x,y,w,h,state,clicked,followCaret)
    local scale,step=0.9,15
    local lines,total=editorLines(value,w-24,scale)
    caret=clamp(tonumber(caret) or total,0,total)
    local visible=math.max(1,math.floor(h/step))
    local maximum=math.max(0,#lines-visible)
    state.scroll=clamp(state.scroll or 0,0,maximum)
    local caretLine,caretColumn=caretLocation(lines,caret)
    if followCaret then
        if caretLine<=state.scroll then state.scroll=caretLine-1 end
        if caretLine>state.scroll+visible then state.scroll=caretLine-visible end
    end
    local delta=0
    if wheel then local v=wheel();delta=v and v.Y or 0 end
    state.scroll=clamp(state.scroll-delta*3,0,maximum)
    local pos=Isaac.WorldToScreen(Isaac.ScreenToWorld(Input.GetMousePosition(false)))
    if clicked and pos.X>=x and pos.X<=x+w-13 and pos.Y>=y and pos.Y<=y+h then
        local lineIndex=clamp(state.scroll+math.floor((pos.Y-y)/step)+1,1,#lines)
        local line=lines[lineIndex]
        local localX=math.max(0,pos.X-x)
        local bestCaret,bestDistance=line.carets[1],math.huge
        for column,candidateCaret in ipairs(line.carets) do
            local prefix=line.text:sub(1,(utf8.offset(line.text,column) or (#line.text+1))-1)
            local distance=math.abs(Isaac.GetTextWidth(prefix)*scale-localX)
            if distance<bestDistance then bestCaret,bestDistance=candidateCaret,distance end
        end
        caret=bestCaret
        caretLine,caretColumn=caretLocation(lines,caret)
    end
    if maximum>0 and mouseDown(0) and pos.X>=x+w-12 and pos.X<=x+w and pos.Y>=y and pos.Y<=y+h then
        state.scroll=clamp(math.floor((pos.Y-y)/h*(maximum+visible)-visible/2),0,maximum)
    end
    state.scroll=math.floor(state.scroll)
    for i=1,visible do
        local lineIndex=state.scroll+i
        local line=lines[lineIndex]
        if line then
            text(line.text,x,y+(i-1)*step,scale)
            if lineIndex==caretLine then
                local prefix=line.text:sub(1,(utf8.offset(line.text,caretColumn) or (#line.text+1))-1)
                box(x+Isaac.GetTextWidth(prefix)*scale,y+(i-1)*step,1,12,COLORS.white)
            end
        end
    end
    if maximum>0 then
        outlinedRect(x+w-10,y,8,h,COLORS.scrollbar,COLORS.border,1)
        local thumb=math.max(12,h*visible/#lines)
        box(x+w-9,y+1+(h-thumb-2)*state.scroll/maximum,6,thumb-2,COLORS.scrollbarThumb)
    end
    return caret
end
function M.Area(value,x,y,w,h,state,followEnd)
    local scale,step=0.9,15
    local lines=M.Wrap(value,w-24,scale)
    local visible=math.max(1,math.floor(h/step))
    local maximum=math.max(0,#lines-visible)
    state.scroll=clamp(state.scroll or 0,0,maximum)
    if followEnd then state.scroll=maximum end
    local delta=0
    if wheel then local v=wheel();delta=v and v.Y or 0 end
    if keyPressed(Keyboard.KEY_UP,0) then delta=delta+1 end
    if keyPressed(Keyboard.KEY_DOWN,0) then delta=delta-1 end
    state.scroll=clamp(state.scroll-delta*3,0,maximum)
    local pos=Isaac.WorldToScreen(Isaac.ScreenToWorld(Input.GetMousePosition(false)))
    if maximum>0 and mouseDown(0) and pos.X>=x+w-12 and pos.X<=x+w and pos.Y>=y and pos.Y<=y+h then
        state.scroll=clamp(math.floor((pos.Y-y)/h*(maximum+visible)-visible/2),0,maximum)
    end
    state.scroll=math.floor(state.scroll)
    for i=1,visible do
        local line=lines[state.scroll+i]
        if line then text(line,x,y+(i-1)*step,scale) end
    end
    if maximum>0 then
        outlinedRect(x+w-10,y,8,h,COLORS.scrollbar,COLORS.border,1)
        local thumb=math.max(12,h*visible/#lines)
        box(x+w-9,y+1+(h-thumb-2)*state.scroll/maximum,6,thumb-2,COLORS.scrollbarThumb)
    end
end
function M.Attach(mod,getConfig,manualStart)
    local state={open=false,scroll=0,wasDown=false,closing=false,hudWasVisible=nil,missingMods={},disabledMods={},modPopupY=nil,modPopupStatus=nil}
    local lastChallenge=nil
    local mainMenuSeen=true
    local function setHUDVisible(visible)
        pcall(function() Game():GetHUD():SetVisible(visible) end)
    end
    local function restoreHUD()
        if state.hudWasVisible ~= nil then
            setHUDVisible(state.hudWasVisible)
            state.hudWasVisible=nil
        end
    end
    local function hideHUD()
        if state.hudWasVisible == nil then
            local ok, visible=pcall(function() return Game():GetHUD():IsVisible() end)
            if ok then state.hudWasVisible=visible==true
            else state.hudWasVisible=true end
        end
        setHUDVisible(false)
    end
    function state.Blocked() return state.open or state.closing end
    function state.Close()
        state.open=false;state.closing=false
        state.missingMods={};state.disabledMods={};state.modPopupY=nil;state.modPopupStatus=nil
        restoreHUD()
    end
    function state.Start(_, continued)
        restoreHUD()
        local challenge=Isaac.GetChallenge()
        local isReset=lastChallenge~=nil and challenge==lastChallenge and not mainMenuSeen
        lastChallenge=challenge
        mainMenuSeen=false
        local cfg=getConfig()
        state.value=cfg and tostring(cfg.description or '') or ''
        state.missingMods=mod.MissingRequiredMods and mod:MissingRequiredMods(cfg) or {}
        state.disabledMods=mod.DisabledRequiredMods and mod:DisabledRequiredMods(cfg) or {}
        -- A disabled installed mod is not also a missing download.
        if #state.disabledMods>0 then
            local disabledIds={}
            for _,required in ipairs(state.disabledMods) do disabledIds[tostring(required.id or '')]=true end
            local downloads={}
            for _,required in ipairs(state.missingMods) do if not disabledIds[tostring(required.id or '')] then downloads[#downloads+1]=required end end
            state.missingMods=downloads
        end
        state.open=continued~=true and not isReset and (state.value:find('%S')~=nil or #state.missingMods>0 or #state.disabledMods>0)
        state.modPopupY=(#state.missingMods>0 or #state.disabledMods>0) and Isaac.GetScreenHeight()+8 or nil
        state.modPopupStatus=nil
        state.closing=false;state.scroll=0;state.wasDown=mouseDown(0)
        if state.open then hideHUD() end
    end
    if not manualStart then mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,state.Start) end
    mod:AddCallback(ModCallbacks.MC_MAIN_MENU_RENDER,function()
        mainMenuSeen=true
        state.Close()
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,state.Close)
    mod:AddCallback(ModCallbacks.MC_PRE_UPDATE,function()
        if state.open then
            hideHUD()
            return true
        end
        -- Keep swallowing the click-release frame, but the HUD was already
        -- restored by the X and must not be hidden again here.
        if state.closing then return true end
    end)
    mod:AddCallback(ModCallbacks.MC_INPUT_ACTION,function(_,entity,hook,action)
        if not state.Blocked() then return end
        -- Keep Escape/controller Start available so the normal pause menu can
        -- open above a blocking description. All gameplay actions stay muted.
        if action==ButtonAction.ACTION_PAUSE then return nil end
        -- This includes ACTION_RESTART, preventing R/Retry while the panel is open.
        if hook==InputHook.GET_ACTION_VALUE then return 0 end
        return false
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER,function()
        local down=mouseDown(0)
        if not state.open then
            -- Do not pass the click that closed the panel through to gameplay.
            if state.closing and not down then state.closing=false end
            state.wasDown=down;return
        end
        local _,_,panelX,panelY,panelW,panelH=screenLayout()
        hideHUD()
        box(0,0,Isaac.GetScreenWidth(),Isaac.GetScreenHeight(),COLORS.overlay)
        outlinedRect(panelX,panelY,panelW,panelH,COLORS.panel,COLORS.border,2)
        drawHeader(panelX+panelW/2,panelY+18,'DESCRIPTION')

        local closeW,closeH=28,24
        local closeX,closeY=panelX+panelW-closeW-18,panelY+12
        local p=Isaac.WorldToScreen(Isaac.ScreenToWorld(Input.GetMousePosition(false)))
        local closeHover=p.X>=closeX and p.X<=closeX+closeW and p.Y>=closeY and p.Y<=closeY+closeH
        local hasDisabled=#(state.disabledMods or {})>0
        local hasMissing=#(state.missingMods or {})>0 or hasDisabled
        button(closeX,closeY,closeW,closeH,hasMissing and '!' or 'X',closeHover and not hasMissing)

        local area={x=panelX+24,y=panelY+50,w=panelW-48,h=panelH-92}
        outlinedRect(area.x,area.y,area.w,area.h,COLORS.field,COLORS.border,2)
        M.Area(state.value,area.x+12,area.y+12,area.w-24,area.h-24,state)
        text('SCROLL: MOUSE WHEEL / UP / DOWN',panelX+24,panelY+panelH-28,0.65,COLORS.dim)
        local signature='Made with Challenge Maker'
        text(signature,panelX+panelW-24-textWidth(signature,0.65),panelY+panelH-28,0.65,COLORS.dim)

        if hasMissing then
            local popupW,popupH=panelW-44,126
            local targetY=panelY+panelH-popupH-20
            state.modPopupY=math.max(targetY,(state.modPopupY or Isaac.GetScreenHeight()+8)-28)
            local popupX=panelX+(panelW-popupW)/2
            outlinedRect(popupX,state.modPopupY,popupW,popupH,COLORS.button,COLORS.border,3)
            local popupTitle=hasDisabled and 'DISABLED MODS' or 'MISSING MODS'
            text(popupTitle,popupX+popupW/2-textWidth(popupTitle,1.02)/2,state.modPopupY+11,1.02,COLORS.white)
            local popupMods=hasDisabled and state.disabledMods or state.missingMods
            local names=mod.JoinModNames and mod:JoinModNames(popupMods) or 'mods'
            local needed=hasDisabled and ('Activate '..names..' to play this challenge.') or ('You need '..names..' to play this challenge.')
            text(needed,popupX+popupW/2-textWidth(needed,0.62)/2,state.modPopupY+38,0.62,COLORS.white)
            local warning="DON'T activate lua debug if you don't trust the mod,"
            text(warning,popupX+popupW/2-textWidth(warning,0.56)/2,state.modPopupY+58,0.56,COLORS.dim)
            local warning2='even if it asks you to.'
            text(warning2,popupX+popupW/2-textWidth(warning2,0.56)/2,state.modPopupY+72,0.56,COLORS.dim)
            local getW,getH=118,23
            local getX,getY=popupX+(popupW-getW)/2,state.modPopupY+96
            button(getX,getY,getW,getH,state.modPopupStatus or (hasDisabled and 'ACTIVATE MODS' or 'GET MODS'),p.X>=getX and p.X<=getX+getW and p.Y>=getY and p.Y<=getY+getH)
            if not hasDisabled and down and not state.wasDown and p.X>=getX and p.X<=getX+getW and p.Y>=getY and p.Y<=getY+getH then
                local opened,copied=mod:OpenRequiredModsInSteam(state.missingMods)
                state.modPopupStatus=copied and 'LINKS COPIED' or (opened and 'STEAM OPENED' or 'COPY FAILED')
            end
        end

        if down and not state.wasDown and closeHover and not hasMissing then
            state.open=false;state.closing=true
            restoreHUD()
        end
        state.wasDown=down
    end)
    return state
end
return M
