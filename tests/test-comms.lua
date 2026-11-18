local frames={}
local combat=false
local writes=0
local M={}
function M:SetScript(k,v)self.scripts[k]=v end
function M:HookScript(k,v)self.hooks[k]=v end
function M:RegisterEvent()end
function M:IsForbidden()return false end
function M:GetFrameStrata()return self.strata or (self.parent and self.parent:GetFrameStrata()) or 'MEDIUM' end
function M:SetFrameStrata(v)self.strata=v;writes=writes+1 end
function M:SetAlpha(v)self.alpha=v end
function M:GetAlpha()return self.alpha or 1 end
function M:IsIgnoringParentAlpha()return self.ignoreAlpha==true end
function M:SetIgnoreParentAlpha(v)self.ignoreAlpha=v;writes=writes+1 end
function M:SetShown(v)self.shown=v end
function M:Hide()self.shown=false end
function M:IsShown()return self.shown end
function M:SetText(v)self.text=v end
function M:GetText()return self.text or '' end
function M:HasFocus()return self.focused end
function M:GetChatType()return 'SAY' end
function M:IsGamepadMenuOpen()return self.menuOpen end
local function obj(name,parent)
 local o=setmetatable({name=name,parent=parent,scripts={},hooks={},shown=false},{__index=function(_,k)
  if M[k] then return M[k] end
  if k:match('^Set') or k:match('^Enable') or k=='RegisterForClicks' then return function()end end
 end});return o
end
function M:CreateFontString()return obj(nil,self)end
function CreateFrame(_,name,parent)local f=obj(name,parent);frames[#frames+1]=f;if name then _G[name]=f end;return f end
function InCombatLockdown()return combat end
function GetTime()return 100 end
NUM_CHAT_WINDOWS=1
UIParent=obj('UIParent');UIParent.strata='MEDIUM'
ChatFrame1=obj('ChatFrame1',UIParent);ChatFrame1.strata='LOW'
ChatFrame1Tab=obj('Tab',ChatFrame1)
ChatFrame1ButtonFrame=obj('Buttons',ChatFrame1)
ChatFrame1EditBox=obj('Edit',UIParent);ChatFrame1EditBox.strata='DIALOG'
local draft=ChatFrame1EditBox
local native=function()end;draft.scripts.OnEnterPressed=native
ForeverHandheldPanels={active=false}
local transitions={}
assert(loadfile(arg[1]))('ForeverHandheld',{refreshFeeds=function()
 transitions[#transitions+1]=ForeverHandheldComms.visible
end})
local driver=frames[1]
local function paint()driver.scripts.OnUpdate(driver,.2);assert(not ForeverHandheldDB or not ForeverHandheldDB.commsError,ForeverHandheldDB and ForeverHandheldDB.commsError)end
paint();assert(ChatFrame1.alpha==0 and #transitions==0,'idle chat must stay unobtrusive')
draft.focused=true;draft.shown=true;draft:SetText('Unsent test draft');paint()
assert(ChatFrame1.alpha==1 and ChatFrame1:GetFrameStrata()=='LOW' and transitions[1]==true,'normal chat or feed handoff changed')
ForeverHandheldPanels.active=true;paint()
assert(ChatFrame1.alpha==1 and draft.alpha==1 and ChatFrame1:GetFrameStrata()=='TOOLTIP','focused draft hidden under workspace')
assert(ChatFrame1Tab:GetFrameStrata()=='TOOLTIP' and ForeverHandheldCommsChrome:GetFrameStrata()=='TOOLTIP','chat chrome/tabs left beneath workspace')
local count=writes;for i=1,20 do paint()end;assert(writes==count and #transitions==1,'settled chat repainted or broadcast redundant changes')
draft.focused=false;paint()
assert(ChatFrame1.alpha==0 and ChatFrame1:GetFrameStrata()=='LOW' and ChatFrame1Tab:GetFrameStrata()=='LOW','parked draft failed to restore parent/child layers')
assert(draft:GetText()=='Unsent test draft' and draft.scripts.OnEnterPressed==native,'draft or native send action changed')
ChatFrame1.menuOpen=true;paint();assert(ChatFrame1.alpha==1,'native chat menu lost visibility')
ChatFrame1.menuOpen=false;draft.focused=true;paint();combat=true;count=writes
draft.focused=false;paint();assert(writes==count and ChatFrame1.alpha==0,'combat mutated frame layers or exposed parked draft')
combat=false;paint();assert(ChatFrame1:GetFrameStrata()=='LOW' and draft:GetFrameStrata()=='DIALOG','deferred layer restoration did not recover')
ForeverHandheldPanels.active=false;paint();assert(ChatFrame1.alpha==1,'outside workspace parked draft presentation changed')
assert(draft:GetText()=='Unsent test draft' and draft.scripts.OnEnterPressed==native,'test sent or changed draft')
ControllerForeverDialogueBand=obj('Dialogue',UIParent);ControllerForeverDialogueBand.shown=true
draft.focused=true;ChatFrame1Tab.ignoreAlpha=true;paint()
assert(draft:IsIgnoringParentAlpha() and ChatFrame1:IsIgnoringParentAlpha() and ForeverHandheldCommsChrome:IsIgnoringParentAlpha(),'cinematic fade hides focused editor or chrome')
assert(draft:GetFrameStrata()=='TOOLTIP','focused chat remains beneath cinematic dialogue')
count=writes;for i=1,20 do paint()end;assert(writes==count,'settled cinematic opacity repeatedly mutated')
draft.focused=false;paint()
assert(ChatFrame1.alpha==0 and not draft:IsIgnoringParentAlpha() and ChatFrame1Tab:IsIgnoringParentAlpha(),'parked cinematic draft or original opacity flags not restored')
draft.focused=true;paint();combat=true;count=writes;draft.focused=false;paint()
assert(writes==count and ChatFrame1.alpha==0,'combat changed opacity flags or exposed parked draft')
combat=false;paint();assert(not draft:IsIgnoringParentAlpha(),'deferred opacity restoration failed')
draft.focused=true;paint();ControllerForeverDialogueBand.shown=false;paint()
assert(not ChatFrame1:IsIgnoringParentAlpha() and ChatFrame1Tab:IsIgnoringParentAlpha() and not ForeverHandheldCommsChrome:IsIgnoringParentAlpha(),'dialogue close did not restore exact opacity flags')
assert(draft:GetText()=='Unsent test draft' and draft.scripts.OnEnterPressed==native,'cinematic check changed draft or send handler')
draft.focused=false;draft:SetText('');draft.shown=false;paint()
assert(#transitions==10,'missing or duplicate feed visibility transition')
for i,shown in ipairs(transitions)do assert(shown==(i%2==1),'feed transition out of order')end
print('Cinematic Comms contracts passed: focused draft survives parent fade, parked draft hidden, exact original flags restored, combat deferral and stable settled state.')
print('Comms contracts passed: focused draft/menu above workspace, parked draft hidden, original parent/child layers restored, no repeated mutations, combat defer and native draft/send preservation.')

-- Exercise real configured F8 hooks; route changes must never submit a draft.
ControllerForeverDB={};C_Timer={After=function(_,f)f()end}
function SetOverrideBinding()end
function SetOverrideBindingClick()end
local grouped,raided,guilded,instanced=false,false,false,false
LE_PARTY_CATEGORY_HOME=1;LE_PARTY_CATEGORY_INSTANCE=2
function IsInGroup(category)if category==LE_PARTY_CATEGORY_INSTANCE then return instanced end;return grouped end
function IsInRaid()return raided end
function IsInGuild()return guilded end
local joined={}
function GetChannelList()return unpack(joined)end
function GetChannelName(id)for i=1,#joined,3 do if joined[i]==id then return id,joined[i+1]end end end
local now=200
function GetTime()return now end
function draft:GetChatType()return self.chatType end
function draft:SetChatType(kind)self.chatType=kind end
function draft:SetStickyType(kind)self.sticky=kind end
function draft:GetChannelTarget()return self.channelTarget end
function draft:SetChannelTarget(id)self.channelTarget=id end
function draft:GetAttribute(k)return self[k]end
function draft:UpdateHeader()self.headerUpdates=(self.headerUpdates or 0)+1 end
function SendChatMessage()error('Comms submitted a draft')end
function BNSendWhisper()error('Comms submitted a BNet draft')end
local submits=0;local originalSubmit=draft.scripts.OnEnterPressed
draft.scripts.OnEnterPressed=function()submits=submits+1;error('Comms called native submit')end
local guardedSubmit=draft.scripts.OnEnterPressed
driver.scripts.OnEvent(driver,'PLAYER_ENTERING_WORLD')
draft.focused=true;draft.shown=true;draft:SetText('Unsent route test')
local function nextRoute(kind,id)
 if kind then draft.chatType=kind;draft.channelTarget=id end
 now=now+1;draft.hooks.OnKeyDown(draft,'F8');return draft.chatType,draft.channelTarget
end
for _,kind in ipairs({'WHISPER','BN_WHISPER','OFFICER','RAID_WARNING'})do
 assert(nextRoute(kind)=='SAY',kind..' did not re-enter route cycle at Say')
end
assert(nextRoute('CHANNEL',99)=='SAY','unavailable channel did not return to Say')
assert(nextRoute('SAY')=='YELL' and nextRoute()=='SAY','solo supported routes changed')
grouped,raided,guilded,instanced=true,true,true,true
joined={1,'General',false,2,'Disabled',true,3,'Trade',false}
assert(nextRoute('SAY')=='PARTY' and nextRoute()=='RAID' and nextRoute()=='GUILD' and nextRoute()=='INSTANCE_CHAT' and nextRoute()=='YELL','supported group cycle changed')
local kind,id=nextRoute();assert(kind=='CHANNEL' and id==1)
kind,id=nextRoute();assert(kind=='CHANNEL' and id==3,'disabled channel entered cycle')
assert(nextRoute()=='SAY','channel cycle did not wrap to Say')
local oldHeaderUpdates=draft.headerUpdates;draft.hooks.OnKeyDown(draft,'F8')
assert(draft.headerUpdates==oldHeaderUpdates,'duplicate key bypassed debounce')
assert(submits==0 and draft:GetText()=='Unsent route test' and draft.scripts.OnEnterPressed==guardedSubmit,'routing changed or sent the draft')
draft.scripts.OnEnterPressed=originalSubmit
print('PASS: unsupported whisper/BNet/officer/channel routes restart at Say; supported group/channel cycle, debounce and native unsent draft preserved')

-- Visibility, not a parked draft's existence, determines whether messages
-- have been presented. Covered drafts must retain unread state across ticks.
ForeverHandheldPanels.active=true;draft.focused=false;paint()
assert(ForeverHandheldComms.active and not ForeverHandheldComms.visible and ChatFrame1.alpha==0)
driver.scripts.OnEvent(driver,'CHAT_MSG_WHISPER');driver.scripts.OnEvent(driver,'CHAT_MSG_GUILD')
assert(ForeverHandheldComms.unread==2,'hidden parked draft consumed unread messages')
paint();paint();assert(ForeverHandheldComms.unread==2,'hidden repaint cleared unread messages')
draft:SetText('');draft.shown=false;paint()
assert(not ForeverHandheldComms.active and ForeverHandheldComms.unread==2,'closing unread hidden draft lost indicator')
ForeverHandheldPanels.active=false;paint()
assert(ForeverHandheldCommsBadge.shown and ForeverHandheldComms.unread==2,'badge did not retain unread messages after workspace closed')
draft.focused=true;draft.shown=true;draft:SetText('Still unsent');paint()
assert(ForeverHandheldComms.visible and ForeverHandheldComms.unread==0,'visible conversation did not acknowledge messages')
driver.scripts.OnEvent(driver,'CHAT_MSG_WHISPER');assert(ForeverHandheldComms.unread==0,'visible draft accumulated unread messages')
ForeverHandheldPanels.active=true;draft.focused=false;paint()
for i=1,101 do driver.scripts.OnEvent(driver,'CHAT_MSG_WHISPER')end
assert(ForeverHandheldComms.unread==99,'hidden unread count lost bounded cap')
ChatFrame1.menuOpen=true;paint()
assert(ForeverHandheldComms.visible and ForeverHandheldComms.unread==0,'native chat menu did not acknowledge visible messages')
assert(draft:GetText()=='Still unsent' and draft.scripts.OnEnterPressed==originalSubmit,'unread handling changed or sent draft')
print('PASS: hidden parked draft retains unread messages, close preserves badge, visible draft/menu acknowledges, count bounded and native sending unchanged')
