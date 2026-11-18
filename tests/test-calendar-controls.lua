local callbacks, combat, pad, active={},false,true,nil
local onEvent, delayed
function CreateFrame()
 return {RegisterEvent=function()end,UnregisterAllEvents=function()end,SetScript=function(_,_,f)onEvent=f end}
end
function InCombatLockdown()return combat end
InputUtil={IsGamepadUIEnabled=function()return pad end}
EventRegistry={RegisterCallback=function(_,event,callback)callbacks[event]=callback end}
GamepadMode={FrameControlsManager={
 GetActiveFrame=function()return active end,
 HandlePopupShown=function(_,frame)assert(active==CalendarFrame);active=frame end,
 FrameHidden=function(_,frame)assert(active==frame);active=CalendarFrame end,
}}
C_Timer={After=function(_,f)delayed=f end}
local action, dateAction, commits
commits=0
local claim={set=function(key,v)
 if key=='PAD2' then action=v elseif key=='PAD3' then dateAction=v else error(key)end
 end,clear=function()action=nil;dateAction=nil end,commit=function()commits=commits+1 end}
local typing=false
ControllerForever={Kit={typing=function()return typing end},Binds={PRIORITY={gamewindow=80},claimant=function(_,name,priority,options)
 assert(name=='foreverCalendarCard' and priority==81 and options.overGame and options.outOfFight)
 return claim
end}}
CalendarFrame={IsShown=function()return true end}
CalendarViewHolidayFrame={IsVisible=function()return true end}
CalendarViewRaidFrame={IsVisible=function()return true end}
local editorHooks={}
local positioned, selected, selectionChanged
SmartNavigation={
 GetActiveFrame=function()return active end,
 GetCurrentButton=function()return selected end,
 RegisterCallback=function(_,event,f)assert(event=='SelectedButtonUpdated');selectionChanged=f end,
}
CalendarDayButton13={GetName=function()return 'CalendarDayButton13'end}
CalendarDayButton14={GetName=function()return 'CalendarDayButton14'end}
local function mockRegion()
 local r={}
 for _,name in ipairs({'SetAllPoints','SetColorTexture','SetWidth','SetHeight','SetPoint','SetFont','SetTextColor','SetText'})do r[name]=function()end end
 return r
end
CalendarCreateEventFrame={
 GetName=function()return 'CalendarCreateEventFrame'end,
 GetParent=function()return CalendarFrame end,
 IsVisible=function()return positioned~=nil end,IsProtected=function()return false end,
 SetClampedToScreen=function()end,ClearAllPoints=function()end,
 SetFrameStrata=function(_,strata)assert(strata=='DIALOG')end,
 SetPoint=function(_,anchor)assert(anchor=='CENTER')end,
 HookScript=function(_,name,fn)editorHooks[name]=fn end,
 CreateTexture=mockRegion,CreateFontString=mockRegion,
}
local filter={GetParent=function()return CalendarFrame end}
local rootMenu={GetOwnerRegion=function()return filter end}
local submenu={GetOwnerRegion=function()return rootMenu end}
local unrelated={GetOwnerRegion=function()return {}end}
dofile(arg[1])
local refresh=assert(callbacks['Gamepad.RefreshFrameFocus'])
active=CalendarViewHolidayFrame;refresh();assert(action=='CLICK CalendarViewHolidayCloseButton:LeftButton')
refresh();assert(commits==1,'stable focus recommitted')
active=submenu;refresh();assert(action==false,'native calendar menu Back got overridden')
active=unrelated;refresh();assert(action==nil,'unrelated menu Back intercepted')
active=CalendarViewRaidFrame;refresh();assert(action=='CLICK CalendarViewRaidCloseButton:LeftButton')
combat=true;refresh();assert(action==nil,'calendar captured combat input')
combat=false;pad=false;refresh();assert(action==nil,'keyboard mode captured')
pad=true
CalendarFrame.HookScript=function()end
CalendarFrame.IsShown=function()return false end
CalendarViewHolidayFrame=nil
CalendarViewRaidFrame=nil
onEvent(nil,'PLAYER_LOGIN')
CalendarFrame.IsShown=function()return true end
active=CalendarFrame;selected=CalendarDayButton13
selectionChanged();assert(not dateAction,'selection changed the binding synchronously')
delayed();assert(dateAction=='CLICK CalendarDayButton13:RightButton')
selected=CalendarDayButton14;selectionChanged();delayed()
assert(dateAction=='CLICK CalendarDayButton14:RightButton','date action kept the prior day')
active=rootMenu
positioned=true
editorHooks.OnShow(CalendarCreateEventFrame)
assert(active==rootMenu and delayed,'editor captured focus before the day menu closed')
active=CalendarFrame
delayed()
assert(active==CalendarCreateEventFrame and action=='CLICK CalendarCreateEventCloseButton:LeftButton','editor failed to take focus from the date grid')
assert(not dateAction,'date action captured X inside the form')
local dropdown={GetParent=function()return CalendarCreateEventFrame end}
active={GetOwnerRegion=function()return dropdown end};refresh()
assert(action==false,'editor dropdown Back got overridden')
active=CalendarCreateEventFrame;typing=true;refresh()
assert(action==nil,'editor captured the typing action')
typing=false;refresh();assert(action=='CLICK CalendarCreateEventCloseButton:LeftButton')
positioned=nil
editorHooks.OnHide(CalendarCreateEventFrame)
assert(active==CalendarFrame and action==nil and dateAction=='CLICK CalendarDayButton14:RightButton','closing the editor did not restore the date grid')
assert(not ForeverHandheldDB or not ForeverHandheldDB.calendarCloseError)
assert(not ForeverHandheldDB or not ForeverHandheldDB.calendarCardError)
print('PASS: Calendar editor takes focus after the day menu closes, restores the grid on close, and defers Back to menus, typing, keyboard mode and combat')
