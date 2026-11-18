-- Deliberate, controller-readable loot inspection. Observes native alerts; never
-- targets units, changes filters, clicks loot, or writes RareScanner's database.
local R={version='3.7.39',history={}}
ForeverHandheldRareReader=R
local window,selection,itemIndex,pendingItem
local WHITE='Interface/Buttons/WHITE8X8'
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function text(v)return type(v)=='string' and public(v) and v or '' end
local function number(v)return type(v)=='number' and public(v) and v or 0 end
local function label(parent,size,x,y,width)
 local t=parent:CreateFontString(nil,'OVERLAY');t:SetFont(STANDARD_TEXT_FONT,size,'')
 t:SetTextColor(.94,.90,.82);t:SetJustifyH('LEFT');t:SetWordWrap(true)
 t:SetPoint('TOPLEFT',x,-y);t:SetWidth(width);return t
end
local function surface(f)
 f:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1})
 f:SetBackdropColor(.025,.030,.029,1);f:SetBackdropBorderColor(.72,.60,.39,.7)
end
function R.capture(b)
 if not b or not b:IsShown() or (b.IsForbidden and b:IsForbidden()) then return end
 local id=b.entityID;local pool=b.LootBar and b.LootBar.itemFramesPool
 if not public(id) or not id or not pool or not pool.EnumerateActive then return end
 local name=b.Title and text(b.Title:GetText()) or text(b.name)
 if name=='' then return end
 local items={}
 for item in pool:EnumerateActive()do
  local link=text(item.itemLink)
  if item:IsShown() and link:find('item:',1,true) then
   local _,_,_,x,y=item:GetPoint(1)
   items[#items+1]={id=item.itemID,link=link,chance=number(item.dropChance),
    icon=item.Icon and item.Icon:GetTexture(),x=number(x),y=number(y)}
  end
 end
 table.sort(items,function(a,b)if a.y~=b.y then return a.y>b.y end;if a.x~=b.x then return a.x<b.x end;return a.link<b.link end)
 -- The reader mirrors the displayed native row, not an inferred drop table.
 local count=#items;while #items>10 do table.remove(items)end
 local key=tostring(id)..':'..text(b.atlasName)
 local last=R.history[#R.history]
 if not last or last.key~=key then
  last={key=key,name=name,items={}};R.history[#R.history+1]=last
  while #R.history>8 do table.remove(R.history,1)end
 end
 last.name=name
 -- Native loot arrives asynchronously. Never erase a populated snapshot while
 -- its pool briefly recycles or a delayed cache lookup has not finished.
 if #items>0 then last.items=items;last.total=count end
 return last
end
local function fitDetail()
 if not window or not window:IsShown() or not itemIndex then return end
 local f=window
 local n=number(f.tip:NumLines())
 if n~=f.styledLines then
  for i=1,n do
   local left=_G['ForeverHandheldRareItemTooltipTextLeft'..i]
   local right=_G['ForeverHandheldRareItemTooltipTextRight'..i]
   local rw=0
   if right then
    right:SetFont(STANDARD_TEXT_FONT,i==1 and 21 or 17,'')
    if right:IsShown() and text(right:GetText())~='' then rw=math.min(200,number(right:GetStringWidth())) end
   end
   if left then
    left:SetFont(STANDARD_TEXT_FONT,i==1 and 21 or 17,'');left:SetWordWrap(true)
    left:SetWidth(470-(rw>0 and rw+18 or 0))
   end
  end
  f.styledLines=n;f.tip:Show()
 end
 local h=math.max(1,number(f.tip:GetHeight())+12)
 f.content:SetHeight(h);local view=f.scroll:GetHeight()
 f.bar:SetMinMaxValues(0,math.max(0,h-view));f.bar:SetShown(h>view)
 f.bar:SetValue(math.min(f.bar:GetValue() or 0,math.max(0,h-view)))
 f.bar:GetThumbTexture():SetHeight(math.max(24,math.min(view,view*view/h)))
end
function R.read(index)
 if not window or InCombatLockdown() then return end
 local entry=window.history[selection];local item=entry and entry.items[index]
 itemIndex=item and index or nil
 pendingItem=item and not C_Item.GetItemInfo(item.link) and item.id or nil
 local f=window
 f.tip:Hide();f.bar:SetValue(0)
 if item then
  f.empty:Hide()
  f.tip:SetOwner(f.content,'ANCHOR_NONE');f.tip:ClearLines()
  f.tip:SetMinimumWidth(490);f.tip:SetHyperlink(item.link)
  if item.chance>0 then f.tip:AddLine('Reported drop chance: '..item.chance..'%',.95,.78,.38,true)end
  -- Preserve native money, stat, effect and texture rendering. Only this owned
  -- tooltip changes font size and chrome; the shared GameTooltip stays intact.
  f.styledLines=nil
  f.tip:SetParent(f.content);f.tip:ClearAllPoints();f.tip:SetPoint('TOPLEFT',f.content,'TOPLEFT',0,0)
  f.tip:SetClampedToScreen(false);f.tip:SetScale(1)
  if f.tip.NineSlice then f.tip.NineSlice:SetAlpha(0)end
  f.tip:Show();fitDetail()
 else
  f.empty:SetText(entry and 'No loot items were available in this alert. RareScanner may still be loading them.' or 'RareScanner alerts will appear here as you explore. This keeps the last eight alerts from this session, including their displayed loot.')
  f.empty:Show();f.content:SetHeight(1);f.bar:SetMinMaxValues(0,0);f.bar:Hide()
 end
 for i,b in ipairs(f.items)do b:SetBackdropBorderColor(.72,.60,.39,i==itemIndex and 1 or .25)end
end
function R.render()
 if not window then return end
 local list=window.history;selection=math.max(1,math.min(selection or #list,math.max(1,#list)))
 local entry=list[selection];local f=window
 f.heading:SetText(entry and entry.name or 'Rare discoveries')
 f.position:SetText(entry and (selection..' / '..#list..' recent alerts  •  '..#entry.items..' displayed items') or 'No alerts this session')
 for i,b in ipairs(f.items)do
  local item=entry and entry.items[i]
  b:SetShown(item~=nil)
  if item then
   local name=C_Item.GetItemInfo(item.link)
   name=text(name);if name=='' then name=item.link:match('|h%[(.-)%]|h') or ('Item '..tostring(item.id))end
   b.icon:SetTexture(item.icon or C_Item.GetItemIconByID(item.id));b.title:SetText(name)
   b.foreverJourneyLabel='Read '..name
  end
 end
 f.previous:SetEnabled(selection>1);f.previous:SetAlpha(selection>1 and 1 or .35)
 f.next:SetEnabled(selection<#list);f.next:SetAlpha(selection<#list and 1 or .35)
 R.read(itemIndex and entry and entry.items[itemIndex] and itemIndex or 1)
end
local function snapshotHistory()
 local result={}
 for i,entry in ipairs(R.history)do result[i]={key=entry.key,name=entry.name,items=entry.items,total=entry.total}end
 return result
end
function R.refresh()
 if not window or InCombatLockdown() then return end
 local current=window.history[selection];local key=current and current.key
 R.capture(RARESCANNER_BUTTON);window.history=snapshotHistory()
 for i,entry in ipairs(window.history)do if entry.key==key then selection=i end end
 R.render()
end
local function build()
 local f=CreateFrame('Frame','ForeverHandheldRareReaderWindow',UIParent,'BackdropTemplate')
 f:Hide();f:SetSize(960,600);f:SetPoint('CENTER',UIParent,'CENTER',0,-12);f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true);surface(f)
 f.heading=label(f,23,24,20,900);f.heading:SetTextColor(.95,.78,.38);f.heading:SetMaxLines(1)
 f.position=label(f,14,24,52,900)
 local pane=CreateFrame('Frame',nil,f,'BackdropTemplate');pane:SetPoint('TOPLEFT',384,-80);pane:SetSize(552,444);surface(pane)
 f.scroll=CreateFrame('ScrollFrame',nil,pane);f.scroll:SetPoint('TOPLEFT',12,-12);f.scroll:SetSize(518,418)
 f.content=CreateFrame('Frame',nil,f.scroll);f.content:SetSize(518,1);f.scroll:SetScrollChild(f.content)
 f.empty=label(pane,19,20,20,496)
 f.tip=CreateFrame('GameTooltip','ForeverHandheldRareItemTooltip',f.content,'GameTooltipTemplate');f.tip:Hide()
 f.bar=CreateFrame('Slider',nil,pane);f.bar:SetPoint('TOPRIGHT',-9,-12);f.bar:SetSize(8,418);f.bar:SetOrientation('VERTICAL');f.bar:SetValueStep(36)
 f.bar:SetThumbTexture(WHITE);f.bar:GetThumbTexture():SetSize(6,28);f.bar:GetThumbTexture():SetVertexColor(.72,.60,.39,1)
 f.bar:SetScript('OnValueChanged',function(_,v)f.scroll:SetVerticalScroll(v)end)
 f.scroll:EnableMouseWheel(true);f.scroll:SetScript('OnMouseWheel',function(_,delta)
  local lo,hi=f.bar:GetMinMaxValues();f.bar:SetValue(math.max(lo,math.min(hi,f.bar:GetValue()-delta*60)))
 end)
 f.foreverJourneyScroll={frame=f.scroll,bar=f.bar,content=f.content,label='Details'}
 local function button(title,x,y,width,height,action)
  local b=CreateFrame('Button',nil,f,'BackdropTemplate');b:SetPoint('TOPLEFT',x,-y);b:SetSize(width,height);surface(b)
  b.title=label(b,17,10,9,width-20);b.title:SetMaxLines(1);b.title:SetText(title);b.foreverJourneyLabel=title
  b:SetHighlightTexture(WHITE);b:GetHighlightTexture():SetVertexColor(.72,.60,.39,.14)
  b:SetScript('OnClick',function()if not InCombatLockdown() then action()end end);return b
 end
 f.items={}
 for i=1,10 do
  local b=button('',24,80+(i-1)*44,344,40,function()R.read(i)end);f.items[i]=b
  b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetSize(32,32);b.icon:SetPoint('LEFT',4,0)
  b.title:ClearAllPoints();b.title:SetPoint('LEFT',44,0);b.title:SetWidth(286)
 end
 f.previous=button('Previous alert',24,548,172,36,function()selection=selection-1;itemIndex=nil;R.render()end)
 f.next=button('Next alert',208,548,172,36,function()selection=selection+1;itemIndex=nil;R.render()end)
 f.refresh=button('Refresh',610,548,140,36,function()R.refresh()end)
 f.close=button('Close',766,548,170,36,function()f:Hide()end)
 f:RegisterEvent('PLAYER_REGEN_DISABLED');f:RegisterEvent('GET_ITEM_INFO_RECEIVED')
 f:SetScript('OnEvent',function(_,event,id)
  if event=='PLAYER_REGEN_DISABLED' then f:Hide()
  elseif f:IsShown() and itemIndex and pendingItem and id==pendingItem then R.read(itemIndex)end
 end)
 f:SetScript('OnHide',function()f.tip:Hide()end)
 -- Native hyperlink data may complete on the following frame. Reflow only
 -- while this deliberate reader is visible, at a bounded rate.
 local elapsed=0
 f:SetScript('OnUpdate',function(_,dt)elapsed=elapsed+dt;if elapsed>=.2 then elapsed=0;fitDetail()end end)
 UISpecialFrames[#UISpecialFrames+1]='ForeverHandheldRareReaderWindow'
 window=f;R.window=f;return f
end
function R.open()
 if InCombatLockdown() then return false end
 R.capture(RARESCANNER_BUTTON);window=window or build();window.history=snapshotHistory();selection=#window.history;itemIndex=nil
 window:Show();R.render();return true
end
local driver=CreateFrame('Frame');local elapsed=0
-- No global scans or frame mutation. Reading the pool only while an alert is
-- visible also picks up asynchronous loot arrivals without replacing methods.
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.5 then return end;elapsed=0
 local ok,err=pcall(R.capture,RARESCANNER_BUTTON)
 if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.rareReaderError=tostring(err)end
end)
