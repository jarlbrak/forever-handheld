local driver,combat,enabled
function CreateFrame()driver={SetScript=function(s,k,v)s[k]=v end};return driver end
function InCombatLockdown()return combat end
function GetTime()return 100 end
InputUtil={IsGamepadUIEnabled=function()return enabled end}
local parent={};local manager={shown=0,hidden=0,focusedFrame=parent}
function manager:FrameShown(f,popup)assert(popup);self.shown=self.shown+1;self.focusedFrame=f;return true end
function manager:FrameHidden(f)assert(self.focusedFrame==f);self.hidden=self.hidden+1;self.focusedFrame=parent end
GamepadMode={FrameControlsManager=manager}
local f={hidden=true,hooks={}}
function f:IsShown()return not self.hidden end
function f:IsForbidden()return self.forbidden end
function f:IsProtected()return self.protected end
function f:HookScript(k,fn)assert(not self.hooks[k]);self.hooks[k]=fn end
f.OnClick=function()error('request invoked')end;f.CloseButton={};local close=f.CloseButton;local click=f.OnClick
AddFriendFrame=f;dofile(arg[1]);local function tick()driver.OnUpdate(driver,.25)end
tick();assert(f.hooks.OnShow and f.hooks.OnHide)
f.hidden=false;f.hooks.OnShow(f);assert(manager.shown==0,'registered in keyboard mode')
enabled=true;tick();assert(manager.shown==1 and manager.focusedFrame==f,'dialog not focused on gamepad activation')
tick();assert(manager.shown==1,'repeated stable registration')
f.hidden=true;f.hooks.OnHide(f);assert(manager.hidden==1 and manager.focusedFrame==parent,'parent focus not returned')
f.hidden=false;combat=true;f.hooks.OnShow(f);assert(manager.shown==1,'combat registration')
combat=false;tick();assert(manager.shown==2,'deferred registration missed')
f.hidden=true;combat=true;f.hooks.OnHide(f);assert(manager.hidden==1);combat=false;tick();assert(manager.hidden==2,'deferred closure missed')
f.hidden=false;f.protected=true;tick();assert(manager.shown==2,'protected dialog registration');f.protected=false;f.forbidden=true;tick();assert(manager.shown==2,'forbidden registration')
assert(f.OnClick==click and f.CloseButton==close,'native actions replaced')
assert(not ForeverHandheldDB.socialDialogError)
print('PASS: native special dialog registration/return, keyboard-to-gamepad activation, stable calls, deferred combat closure, protected/forbidden guards and no button mutation')

f.forbidden=false;f.hidden=false;tick();local before=manager.shown
-- Native gamepad uninitialization clears the list on the SAME manager object.
manager.shownFrames={};manager.focusedFrame=nil;enabled=false;tick()
assert(manager.shown==before,'registered while controller UI disabled')
enabled=true
local originalShown=manager.FrameShown
function manager:FrameShown(frame,popup)local result=originalShown(self,frame,popup);self.shownFrames={frame};return result end
tick();assert(manager.shown==before+1 and manager.focusedFrame==f,'same-manager reset left dialog unfocused')
tick();assert(manager.shown==before+1,'registration churn after recovery')
print('PASS: same-manager gamepad reset recovers active dialog and settles without repeated registration')

-- Visible child view changes must never leave focus on a hidden button.
local function child()return {IsShown=function(s)return not s.hidden end,IsForbidden=function()return false end,IsProtected=function()return false end}end
f.InfoFrame=child();f.EntryFrame=child();f.InfoFrame.hidden=true
f.InfoFrame.OkayButton=child();AddFriendEntryFrameInfoButton=child()
local refreshes,selections=0,{}
SmartNavigation={RefreshButtonGroups=function(_,root)assert(root==f);refreshes=refreshes+1 end,SetTargetButtonForFrame=function(_,root,target)assert(root==f);selections[#selections+1]=target end}
tick();assert(refreshes==0,'initial native focus unnecessarily replaced')
f.InfoFrame.hidden=false;f.EntryFrame.hidden=true;tick()
assert(refreshes==1 and selections[1]==f.InfoFrame.OkayButton,'information view did not focus Okay')
for i=1,5 do tick()end;assert(refreshes==1,'settled view repeatedly steals focus')
f.InfoFrame.hidden=true;f.EntryFrame.hidden=false;combat=true;tick();assert(refreshes==1)
combat=false;tick();assert(refreshes==2 and selections[2]==AddFriendEntryFrameInfoButton,'entry view did not restore information origin')
f.InfoFrame.hidden=false;f.EntryFrame.hidden=true;enabled=false;tick();assert(refreshes==2)
enabled=true;tick();assert(refreshes==3)
assert(f.OnClick==click and f.CloseButton==close and not ForeverHandheldDB.socialDialogError)
print('PASS: Info/Entry transition focus through native API, stable focus, combat/input guards, no request action')

f.hidden=true;tick()
local activity=child();activity.hidden=true;activity.IsVisible=activity.IsShown
local play=child();play.IsVisible=play.IsShown;play.IsEnabled=function()return true end;play.action=click
activity.PlayStyleDropdown=play
LFGParentFrame={};LFGListingFrame={ActivityView=activity}
local hidden=child();hidden.hidden=true;hidden.IsVisible=hidden.IsShown
local nativeOwner=LFGParentFrame
local calls=0
SmartNavigation={
 currentButton=hidden,
 GetActiveFrame=function()return nativeOwner end,
 RefreshButtonGroups=function(_,owner)assert(owner==nativeOwner);calls=calls+1 end,
 SetTargetButtonForFrame=function(s,owner,target)assert(owner==nativeOwner and target==play);s.currentButton=target;calls=calls+1 end,
}
tick();activity.hidden=false;tick()
assert(calls==2 and SmartNavigation.currentButton==play and play.action==click,'hidden activity category retained focus')
tick();assert(calls==2)
activity.hidden=true;tick();activity.hidden=false;tick()
assert(calls==2,'visible native focus overwritten')
activity.hidden=true;tick();nativeOwner=parent;SmartNavigation.currentButton=hidden;activity.hidden=false;tick()
assert(calls==2 and not ForeverHandheldDB.groupFinderFocusError,'another frame lost focus')
print('PASS: Group Finder activity focus recovers hidden selection once; visible focus and unrelated owners retained')

LFGListingFrame=nil
local social,list,close,menu=child(),child(),child(),child()
for _,frame in ipairs({social,list,close,menu})do frame.IsVisible=frame.IsShown end
close.GetParent=function()return list end
menu.IsEnabled=function()return true end
social.IgnoreListFrame=list
social.BattleNetBar={ControlsContainer={BattleNetMenuButton=menu}}
SocialUIFrame=social
local selected=close
calls=0
SmartNavigation={
 GetActiveFrame=function()return social end,
 GetCurrentButton=function()return selected end,
 RefreshButtonGroups=function(_,root)assert(root==social);calls=calls+1 end,
 SetTargetButtonForFrame=function(_,root,target)assert(root==social and target==menu);selected=target;calls=calls+1 end,
}
tick();assert(calls==0,'opening Ignore List changed native selection')
list.hidden=true;close.hidden=true;tick()
assert(calls==2 and selected==menu,'closed Ignore List retained its hidden close button')
tick();assert(calls==2,'settled menu repeatedly refreshed')
list.hidden=false;tick();list.hidden=true;tick()
assert(calls==2,'already-visible Social selection was replaced')
assert(not ForeverHandheldDB.socialDialogError)
print('PASS: Ignore List close restores focus to the Social menu once; valid focus remains untouched')
