-- A read-only conversation glance beside the dock footer. Native Comms owns
-- history, focus, drafts and sending. Nothing here intercepts controller input.
local _, addon=...
local frame=CreateFrame('Frame','ForeverHandheldPassiveChat',UIParent)
frame:SetSize(410,54);frame:SetPoint('BOTTOMLEFT',20,18)
frame:SetFrameStrata('LOW');frame:EnableMouse(false);frame:Hide()
local rows,messages={},{}
local previewUntil=0
local channels={
  SAY={'SAY',1,1,1},YELL={'YELL',1,.35,.25},EMOTE={'EMOTE',1,.62,.30},
  WHISPER={'TELL',1,.5,1},WHISPER_INFORM={'TELL',1,.5,1},
  BN_WHISPER={'TELL',.3,.85,1},BN_WHISPER_INFORM={'TELL',.3,.85,1},
  PARTY={'PARTY',.67,.67,1},PARTY_LEADER={'PARTY',.67,.67,1},
  RAID={'RAID',1,.5,0},RAID_LEADER={'RAID',1,.5,0},RAID_WARNING={'RAID',1,.25,0},
  INSTANCE_CHAT={'GROUP',1,.5,0},INSTANCE_CHAT_LEADER={'GROUP',1,.5,0},
  GUILD={'GUILD',.25,1,.25},OFFICER={'GUILD',.25,.8,.25},CHANNEL={'ZONE',1,.75,.75},
}
local preview={
  {kind='SAY',author='Preview',text='Anyone heading north?',age=35},
  {kind='PARTY',author='Preview',text='Meet at the bridge.',age=12},
  {kind='WHISPER',author='Preview',text='Ready when you are.',age=0},
}
for i=1,3 do
  local row=CreateFrame('Frame',nil,frame);row:SetSize(410,18)
  row:SetPoint('TOPLEFT',0,-(i-1)*18);row:EnableMouse(false)
  local bg=row:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints()
  bg:SetColorTexture(1,1,1,1)
  bg:SetGradient('HORIZONTAL',CreateColor(.015,.02,.017,.68),CreateColor(.015,.02,.017,0))
  row.mark=row:CreateTexture(nil,'ARTWORK');row.mark:SetSize(2,12);row.mark:SetPoint('LEFT',0,0)
  row.tag=row:CreateFontString(nil,'OVERLAY');row.tag:SetFont('Fonts\\ARIALN.TTF',11,'OUTLINE')
  row.tag:SetPoint('LEFT',7,0);row.tag:SetWidth(45);row.tag:SetJustifyH('LEFT')
  row.text=row:CreateFontString(nil,'OVERLAY');row.text:SetFont('Fonts\\ARIALN.TTF',15,'OUTLINE')
  row.text:SetPoint('LEFT',55,0);row.text:SetWidth(353);row.text:SetJustifyH('LEFT')
  row.text:SetMaxLines(1);row.text:SetWordWrap(false)
  row:Hide()
  rows[i]=row
end
local function clean(value)
  if type(value)~='string' or (issecretvalue and issecretvalue(value)) then return '' end
  return value:gsub('|T.-|t',''):gsub('|A.-|a',''):gsub('|H.-|h(.-)|h','%1')
    :gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''):gsub('[\r\n]',' ')
end
local function paint(now)
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
        local c=channels[message.kind] or channels.SAY
        row.tag:SetText(message.channel or c[1]);row.tag:SetTextColor(c[2],c[3],c[4])
        row.mark:SetColorTexture(c[2],c[3],c[4],.7)
        row.text:SetText(message.author..': '..message.text);row.text:SetTextColor(.94,.92,.86)
      end
    end
    if message then
      local age=showingPreview and message.age or now-message.time
      local alpha=age<20 and 1 or age<60 and .75 or .5
      if alpha~=row.alpha then row:SetAlpha(alpha);row.alpha=alpha end
      if not showingPreview and age<60 then
        nextAt=math.min(nextAt,message.time+(age<20 and 20 or 60))
      end
    end
  end
  if nextAt<math.huge then return nextAt end
end
local refresh=addon.createFeedRefresh(paint,'passiveChatError')
local function receive(event,...)
  local kind=event:sub(10)
  local message,author,_,_,_,_,_,number=...
  if kind=='CHANNEL' then
    local edit=ChatFrame1EditBox
    if not edit or edit:GetChatType()~='CHANNEL' or edit:GetChannelTarget()~=number then return end
  end
  if C_FriendList and C_FriendList.IsIgnored and C_FriendList.IsIgnored(author) then return end
  local filters=ChatFrame_GetMessageEventFilters and ChatFrame_GetMessageEventFilters(event)
  if filters then for _,filter in ipairs(filters) do if filter(ChatFrame1,event,...) then return end end end
  message,author=clean(message),clean(author)
  if message=='' or author=='' then return end
  author=author:match('^[^-]+') or author
  if kind=='WHISPER_INFORM' or kind=='BN_WHISPER_INFORM' then author='You > '..author end
  messages[#messages+1]={kind=kind,text=message,author=author,time=GetTime(),channel=kind=='CHANNEL' and ('#'..number) or nil}
  while #messages>3 do table.remove(messages,1) end
  refresh()
end
for kind in pairs(channels) do frame:RegisterEvent('CHAT_MSG_'..kind) end
frame:SetScript('OnEvent',function(_,event,...)
  local ok,err=pcall(receive,event,...)
  if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.passiveChatError=tostring(err) end
end)
-- Local-only visual preview; never generates a chat event or sends a message.
function frame.Preview() previewUntil=GetTime()+60;refresh() end
function frame.ClearPreview() previewUntil=0;refresh() end
SLASH_FOREVERPASSIVEPREVIEW1='/fhpeek'
SlashCmdList.FOREVERPASSIVEPREVIEW=function(argument)
  if argument=='off' then frame.ClearPreview() else frame.Preview() end
end
