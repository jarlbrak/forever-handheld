local texts,all={},{}
local textWrites=0
local function object()
 local t={shown=true,scripts={}}
 setmetatable(t,{__index=function(self,key)
  if key=='CreateFontString' then return function()local f=object();texts[#texts+1]=f;return f end end
  if key=='CreateTexture' then return function()return object()end end
  if key=='SetText' then return function(_,s) self.text=s;textWrites=textWrites+1 end end
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
ChatFrame1EditBox={GetChatType=function()return 'CHANNEL'end,GetChannelTarget=function()return 1 end}
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
LOOT_ITEM_SELF='You receive loot: %s.'
C_Item={GetItemIconByID=function()return 123 end}
C_QuestLog={GetTitleForQuestID=function()return 'A Small Reward' end}
local addon={}
assert(loadfile(arg[2]))('ForeverHandheld',addon)
assert(loadfile(arg[1]))('ForeverHandheld',addon)
local frame=ForeverHandheldActivityFeed
local function event(kind,msg)frame.scripts.OnEvent(nil,kind,msg)end
local function bottom()return texts[3].text end
assert(not pending and not frame.shown)
for _,f in ipairs(all) do assert(not f.scripts.OnUpdate,'idle Activity Feed has a frame callback') end
event('CHAT_MSG_LOOT','You receive loot: |cff1eff00|Hitem:1|h[Green Item]|h|r.');assert(bottom()=='|cff1eff00[Green Item]|r')
event('CHAT_MSG_MONEY','You loot 2 Silver.');assert(bottom()=='You loot 2 Silver.')
event('QUEST_TURNED_IN',1);assert(bottom()=='Completed: A Small Reward')
local painted=textWrites
assert(pending.at==120 and all[4].alpha==1)
advance(120);assert(all[4].alpha==.75 and pending.at==135)
advance(136);assert(all[4].alpha<.75 and all[4].alpha>.6 and textWrites==painted)
ForeverHandheldComms={active=true,visible=true};addon.refreshFeeds();assert(not frame.shown and not pending)
ForeverHandheldComms.visible=false;addon.refreshFeeds();assert(frame.shown and pending and textWrites==painted)
advance(145);assert(not frame.shown and not pending)
assert(not (ForeverHandheldDB and ForeverHandheldDB.activityFeedError))

frame.StoryNotice('Story: The canal');assert(bottom()=='Story: The canal','story notice missing from passive event feed')
frame.Preview();assert(bottom()=='Preview: Linen Cloth x3' and pending.at==205)
ForeverHandheldComms.visible=true;addon.refreshFeeds();assert(not pending)
advance(210)
ForeverHandheldComms.visible=false;addon.refreshFeeds();assert(not frame.shown and not pending)
frame.StoryNotice('Story: Back again');assert(frame.shown and bottom()=='Story: Back again')
assert(not (ForeverHandheldDB and ForeverHandheldDB.activityFeedError))
print('PASS: native rewards, compact story, fade without text rewrites, hidden expiry, preview and zero idle updates')
