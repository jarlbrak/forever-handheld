local texts,all={},{}
local function object()
 local t={shown=true,scripts={}}
 setmetatable(t,{__index=function(self,key)
  if key=='CreateFontString' then return function()local f=object();texts[#texts+1]=f;return f end end
  if key=='CreateTexture' then return function()return object()end end
  if key=='SetText' then return function(_,s) self.text=s end end
  if key=='SetScript' then return function(_,k,v)self.scripts[k]=v end end
  if key=='Hide' then return function()self.shown=false end end
  if key=='IsShown' then return function()return self.shown end end
  if key=='SetShown' then return function(_,v)self.shown=v end end
  if key=='SetAlpha' then return function(_,v)self.alpha=v end end
  return function()end
 end})
 return t
end
UIParent={};SlashCmdList={}
function CreateFrame(_,name)local f=object();all[#all+1]=f;if name then _G[name]=f end;return f end
function CreateColor(...)return {...}end
local now,pending=100,nil
function GetTime()return now end
C_Timer={NewTimer=function(delay,callback)
 assert(not pending,'more than one timer scheduled')
 pending={at=now+delay,callback=callback,Cancel=function(self)assert(pending==self);pending=nil end}
 return pending
end}
local function advance(target)
 while pending and pending.at<=target do
  local due=pending;pending=nil;now=due.at
  due.callback()
 end
 now=target
end
ChatFrame1EditBox={GetChatType=function()return 'CHANNEL'end,GetChannelTarget=function()return 1 end}
local addon={}
assert(loadfile(arg[2]))('ForeverHandheld',addon)
assert(loadfile(arg[1]))('ForeverHandheld',addon)
local frame=ForeverHandheldPassiveChat
local function event(kind,msg,author,channel)frame.scripts.OnEvent(nil,'CHAT_MSG_'..kind,msg,author,nil,nil,nil,nil,nil,channel)end
local function bottom()return texts[6].text end
assert(not pending and not frame.shown)
for _,f in ipairs(all) do assert(not f.scripts.OnUpdate,'idle Passive Chat has a frame callback') end
event('PARTY','Ready for the next quest','Example-Realm');assert(bottom()=='Example: Ready for the next quest')
event('CHANNEL','Wrong channel','Other',2);assert(bottom()=='Example: Ready for the next quest')
event('CHANNEL','Selected channel','Other',1);assert(bottom()=='Other: Selected channel')
event('WHISPER','|cffffffffRead |Hitem:1|h[item]|h|r','Friend');assert(bottom()=='Friend: Read [item]')
assert(all[4].alpha==1 and pending.at==120)
advance(120);assert(all[4].alpha==.75 and pending.at==160)
advance(161);assert(all[4].alpha==.5 and not pending and frame.shown)
ForeverHandheldComms={active=true,visible=true};addon.refreshFeeds();assert(not frame.shown and not pending)
event('PARTY','New while Comms is open','Member');assert(not frame.shown and not pending)
ForeverHandheldComms.visible=false;addon.refreshFeeds();assert(frame.shown and bottom()=='Member: New while Comms is open')
frame.Preview();assert(bottom()=='Preview: Ready when you are.' and pending.at==221)
advance(221);assert(frame.shown and bottom()=='Member: New while Comms is open' and not pending)
assert(not (ForeverHandheldDB and ForeverHandheldDB.passiveChatError))
print('PASS: conversation filtering and link cleanup, fade into retained history, Comms handoff, preview, and zero idle updates')
