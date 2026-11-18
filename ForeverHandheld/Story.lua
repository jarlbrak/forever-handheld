-- Preserve Loreward's native timers/queue while moving passive text out of
-- the action area. A bounded journal keeps it available for deliberate reading.
local S={version='3.7.37'}
ForeverHandheldStory=S
local seen=setmetatable({},{__mode='k'})
local mirrored=setmetatable({},{__mode='k'})
local reader,index
local function history()
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.storyHistory=ForeverHandheldDB.storyHistory or {}
 return ForeverHandheldDB.storyHistory
end
local function plain(value)
 if type(value)~='string' or (issecretvalue and issecretvalue(value)) then return '' end
 return value:gsub('|T.-|t',''):gsub('|A.-|a',''):gsub('|H.-|h(.-)|h','%1')
end
local function mirror(root,kind)
 if mirrored[root] then return end
 mirrored[root]=true
 local placing=false
 local function park()
  if placing then return end
  placing=true
  root:SetClampedToScreen(false);root:ClearAllPoints()
  root:SetPoint('TOPLEFT',UIParent,'TOPLEFT',-10000,10000)
  placing=false
 end
 -- Park the non-interactive native card outside pointer hit testing, so
 -- its IsMouseOver timer check cannot pause on an invisible center region.
 root:EnableMouse(false);park();root:SetAlpha(0)
 hooksecurefunc(root,'SetPoint',park)
 hooksecurefunc(root,'SetAlpha',function(_,alpha)if alpha~=0 then root:SetAlpha(0) end end)
 root:HookScript('OnShow',function()S.capture(root,kind)end)
end
function S.capture(root,kind)
 if InCombatLockdown() or not root or not root:IsShown() or not root.text then return end
 local body=plain(root.text:GetText())
 if body=='' then return end
 local title=kind=='tour' and root.title and plain(root.title:GetText()) or 'Guide notes'
 if title=='' then title='Story note' end
 -- Do not Hide the native frame: OnHide advances Tour's queue. Its own
 -- expiry/hold logic still runs, and scripts are never replaced.
 mirror(root,kind)
 local key=title..'\n'..body
 if seen[root]==key then return end
 seen[root]=key
 local list=history()
 local latest=list[#list]
 if latest and latest.title==title and latest.text==body then return end
 list[#list+1]={title=title,text=body:sub(1,32768),kind=kind}
 while #list>20 do table.remove(list,1) end
 local feed=ForeverHandheldActivityFeed
 if feed and feed.StoryNotice then feed.StoryNotice('Story: '..title..'  |  Journey > Story journal') end
end
local function text(root,size,x,y,width)
 local f=root:CreateFontString(nil,'OVERLAY')
 f:SetFont(STANDARD_TEXT_FONT,size,'');f:SetTextColor(.94,.90,.82)
 f:SetPoint('TOPLEFT',x,-y);f:SetWidth(width);f:SetJustifyH('LEFT');f:SetWordWrap(true)
 return f
end
function S.render()
 if not reader then return end
 local list=history();index=math.max(1,math.min(index or #list,math.max(1,#list)))
 local item=list[index]
 reader.heading:SetText(item and item.title or 'Your story journal')
 reader.position:SetText(#list>0 and (index..' / '..#list..' notes  •  Latest 20 kept') or 'No story notes yet')
 -- Let wrapped chapter titles push the counter and reading area down.
 -- The buttons stay anchored; a long body scrolls inside the remaining space.
 local titleHeight=math.max(28,reader.heading:GetStringHeight())
 local counterTop=24+titleHeight+12
 reader.position:ClearAllPoints();reader.position:SetPoint('TOPLEFT',28,-counterTop)
 local bodyTop=counterTop+reader.position:GetStringHeight()+20
 local viewport=math.max(80,458-bodyTop)
 reader.scroll:ClearAllPoints();reader.scroll:SetPoint('TOPLEFT',28,-bodyTop);reader.scroll:SetHeight(viewport)
 reader.bar:ClearAllPoints();reader.bar:SetPoint('TOPLEFT',924,-bodyTop);reader.bar:SetHeight(viewport)
 reader.body:SetText(item and item.text or 'Loreward story cards and guide notes will appear here. Read them at your pace; the center of the screen stays clear while you play.')
 local height=math.max(1,reader.body:GetStringHeight()+12)
 reader.content:SetHeight(height)
 local range=math.max(0,height-reader.scroll:GetHeight())
 reader.bar:SetMinMaxValues(0,range);reader.bar:SetValue(0);reader.scroll:SetVerticalScroll(0)
 reader.bar:SetShown(range>0)
 reader.bar:GetThumbTexture():SetHeight(math.max(24,math.min(viewport,viewport*viewport/height)))
 reader.previous:SetEnabled(#list>0 and index>1);reader.next:SetEnabled(index<#list)
 reader.previous:SetAlpha(#list>0 and index>1 and 1 or .35);reader.next:SetAlpha(index<#list and 1 or .35)
end
local function build()
 local f=CreateFrame('Frame','ForeverHandheldStoryReader',UIParent,'BackdropTemplate')
 reader=f;S.reader=f
 f:SetSize(960,540);f:SetPoint('CENTER',UIParent,'CENTER',0,-22)
 f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true)
 f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
 f:SetBackdropColor(.025,.030,.029,1);f:SetBackdropBorderColor(.72,.60,.39,1)
 f.heading=text(f,24,28,24,890);f.heading:SetTextColor(.95,.78,.38)
 f.position=text(f,14,28,62,890);f.position:SetTextColor(.72,.70,.64)
 f.scroll=CreateFrame('ScrollFrame',nil,f);f.scroll:SetPoint('TOPLEFT',28,-102);f.scroll:SetSize(872,350)
 f.content=CreateFrame('Frame',nil,f.scroll);f.content:SetSize(872,350);f.scroll:SetScrollChild(f.content)
 f.body=text(f.content,19,0,0,858);f.body:SetSpacing(5)
 f.bar=CreateFrame('Slider',nil,f);f.bar:SetPoint('TOPLEFT',924,-102);f.bar:SetSize(12,350)
 f.bar:SetOrientation('VERTICAL');f.bar:SetValueStep(32);f.bar:SetMinMaxValues(0,0)
 f.bar:SetThumbTexture('Interface\\Buttons\\WHITE8X8')
 local thumb=f.bar:GetThumbTexture();thumb:SetSize(8,32);thumb:SetVertexColor(.72,.60,.39,1)
 f.bar:SetScript('OnValueChanged',function(_,value)f.scroll:SetVerticalScroll(value)end)
 f.scroll:EnableMouseWheel(true)
 f.scroll:SetScript('OnMouseWheel',function(_,delta)
  local lo,hi=f.bar:GetMinMaxValues();f.bar:SetValue(math.max(lo,math.min(hi,f.bar:GetValue()-delta*64)))
 end)
 f.foreverJourneyScroll={frame=f.scroll,bar=f.bar,content=f.content}
 local function button(label,x,action)
  local b=CreateFrame('Button',nil,f,'BackdropTemplate')
  b:SetSize(200,36);b:SetPoint('TOPLEFT',x,-480)
  b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
  b:SetBackdropColor(.045,.052,.047,1);b:SetBackdropBorderColor(.72,.60,.39,.65)
  b.label=text(b,16,0,0,188);b.label:ClearAllPoints();b.label:SetPoint('CENTER');b.label:SetJustifyH('CENTER');b.label:SetText(label)
  b.foreverJourneyLabel=label
  b:SetHighlightTexture('Interface\\Buttons\\WHITE8X8','ADD');b:GetHighlightTexture():SetVertexColor(.72,.60,.39,.16)
  b:SetScript('OnClick',function()if not InCombatLockdown() then action() end end)
  return b
 end
 f.previous=button('Previous note',28,function()index=index-1;S.render()end)
 f.next=button('Next note',244,function()index=index+1;S.render()end)
 f.close=button('Close',732,function()f:Hide()end)
 f:Hide();UISpecialFrames[#UISpecialFrames+1]='ForeverHandheldStoryReader'
end
function S.open()
 if InCombatLockdown() then return false end
 if not reader then build() end
 index=#history();S.render();reader:Show();return true
end
local elapsed=0
local driver=CreateFrame('Frame')
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0
 if InCombatLockdown() then return end
 local ok,err=pcall(function()
  S.capture(LorewardTourCard,'tour');S.capture(LorewardStepNotes,'guide')
 end)
 if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.storyError=tostring(err) end
end)
