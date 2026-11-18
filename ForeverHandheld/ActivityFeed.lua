-- Read-only rewards and world notices, mirrored opposite passive conversation.
local _, addon=...
local frame=CreateFrame('Frame','ForeverHandheldActivityFeed',UIParent)
frame:SetSize(410,54);frame:SetPoint('BOTTOMRIGHT',-20,18)
frame:SetFrameStrata('LOW');frame:EnableMouse(false);frame:Hide()
local rows,messages={},{}
local previewUntil=0
local kinds={
  LOOT={'Interface\\Icons\\INV_Misc_Bag_08',.9,.85,.65},
  MONEY={'Interface\\Icons\\INV_Misc_Coin_01',1,.83,.35},
  CURRENCY={'Interface\\Icons\\INV_Misc_Coin_01',1,.83,.35},
  COMBAT_XP_GAIN={'Interface\\Icons\\INV_Misc_Book_09',.65,.65,1},
  COMBAT_FACTION_CHANGE={'Interface\\Icons\\INV_Misc_Note_01',.45,.8,1},
  SKILL={'Interface\\Icons\\INV_Misc_Book_09',.45,.75,1},
  SYSTEM={'Interface\\Icons\\INV_Misc_Note_01',1,.85,.45},
  ACHIEVEMENT={'Interface\\Icons\\Achievement_General',1,.85,.35},
  QUEST={'Interface\\GossipFrame\\AvailableQuestIcon',1,.85,.35},
  STORY={'Interface\\Icons\\INV_Misc_Book_09',.95,.78,.38},
}
local preview={
  {kind='COMBAT_XP_GAIN',text='Preview: +120 experience',age=24},
  {kind='MONEY',text='Preview: 2 Silver, 35 Copper',age=12},
  {kind='LOOT',text='Preview: Linen Cloth x3',icon='Interface\\Icons\\INV_Fabric_Linen_01',age=0},
}
for i=1,3 do
  local row=CreateFrame('Frame',nil,frame);row:SetSize(410,18)
  row:SetPoint('TOPRIGHT',0,-(i-1)*18);row:EnableMouse(false)
  local bg=row:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetColorTexture(1,1,1,1)
  bg:SetGradient('HORIZONTAL',CreateColor(.015,.02,.017,0),CreateColor(.015,.02,.017,.68))
  row.mark=row:CreateTexture(nil,'ARTWORK');row.mark:SetSize(2,12);row.mark:SetPoint('RIGHT',0,0)
  row.icon=row:CreateTexture(nil,'ARTWORK');row.icon:SetSize(14,14);row.icon:SetPoint('RIGHT',-7,0)
  row.text=row:CreateFontString(nil,'OVERLAY');row.text:SetFont('Fonts\\ARIALN.TTF',15,'OUTLINE')
  row.text:SetPoint('RIGHT',-28,0);row.text:SetWidth(380);row.text:SetJustifyH('RIGHT')
  row.text:SetMaxLines(1);row.text:SetWordWrap(false)
  row:Hide()
  rows[i]=row
end
local function clean(value)
  if type(value)~='string' or (issecretvalue and issecretvalue(value)) then return '' end
  -- Keep WoW quality colors and item names; links are non-interactive text here.
  return value:gsub('|T.-|t',''):gsub('|A.-|a',''):gsub('|H.-|h(.-)|h','%1'):gsub('[\r\n]',' ')
end
local function paint(now)
  for i=#messages,1,-1 do
    if now>=messages[i].time+45 then table.remove(messages,i) end
  end
  if ForeverHandheldComms and ForeverHandheldComms.visible then
    if frame:IsShown() then frame:Hide() end
    return
  end
  local showingPreview=previewUntil>now
  local list=showingPreview and preview or messages
  local nextAt=showingPreview and previewUntil or math.huge
  local shown=#list>0
  if frame:IsShown()~=shown then frame:SetShown(shown) end
  for i,row in ipairs(rows) do
    local message=list[i-(3-#list)]
    if row.message~=message then
      local visible=message~=nil
      if row:IsShown()~=visible then row:SetShown(visible) end
      row.message=message
      if message then
        local style=kinds[message.kind] or kinds.SYSTEM
        row.text:SetText(message.text);row.text:SetTextColor(style[2],style[3],style[4])
        row.icon:SetTexture(message.icon or style[1]);row.mark:SetColorTexture(style[2],style[3],style[4],.7)
      end
    end
    if message then
      local age=showingPreview and message.age or now-message.time
      local alpha=age<20 and 1 or age<35 and .75 or math.max(0,(45-age)/10)*.75
      if alpha~=row.alpha then row:SetAlpha(alpha);row.alpha=alpha end
      if not showingPreview then
        local transition=message.time+(age<20 and 20 or age<35 and 35 or 45)
        if age>=35 then transition=math.min(transition,now+.1) end
        nextAt=math.min(nextAt,transition)
      end
    end
  end
  if nextAt<math.huge then return nextAt end
end
local refresh=addon.createFeedRefresh(paint,'activityFeedError')
local function receive(event,message)
  local kind=event:sub(10)
  local icon
  if event=='QUEST_TURNED_IN' then
    local title=C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(message)
    message=title and ('Completed: '..title) or 'Quest completed';kind='QUEST'
  end
  if type(message)~='string' or (issecretvalue and issecretvalue(message)) then return end
  if kind=='LOOT' then
    local item=message:match('|H(item:.-)|h')
    if item then
      if C_Item and C_Item.GetItemIconByID then icon=C_Item.GetItemIconByID(item)
      elseif GetItemIcon then icon=GetItemIcon(item) end
      -- Compact self loot while preserving other players' names in group loot.
      local prefix=LOOT_ITEM_SELF and LOOT_ITEM_SELF:match('^(.-)%%s')
      if prefix and message:sub(1,#prefix)==prefix then message=message:sub(#prefix+1):gsub('%.$','') end
    end
  end
  message=clean(message);if message=='' then return end
  local now=GetTime()
  local last=messages[#messages]
  if kind=='SYSTEM' and last and last.kind==kind and last.text==message and now-last.time<1 then return end
  messages[#messages+1]={kind=kind,text=message,icon=icon,time=now}
  while #messages>3 do table.remove(messages,1) end
  refresh()
end
for kind in pairs(kinds) do if kind~='QUEST' and kind~='STORY' then frame:RegisterEvent('CHAT_MSG_'..kind) end end
function frame.StoryNotice(message)receive('CHAT_MSG_STORY',message)end
frame:RegisterEvent('QUEST_TURNED_IN')
frame:SetScript('OnEvent',function(_,event,...)
  local ok,err=pcall(receive,event,...)
  if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.activityFeedError=tostring(err) end
end)
function frame.Preview()previewUntil=GetTime()+60;refresh()end
function frame.ClearPreview()previewUntil=0;refresh()end
SLASH_FOREVERACTIVITYPREVIEW1='/fhactivity'
SlashCmdList.FOREVERACTIVITYPREVIEW=function(argument)
  if argument=='off' then
    frame.ClearPreview()
    if ForeverHandheldPassiveChat then ForeverHandheldPassiveChat.ClearPreview() end
  else
    frame.Preview()
    if argument=='both' and ForeverHandheldPassiveChat then ForeverHandheldPassiveChat.Preview() end
  end
end
