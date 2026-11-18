-- Controller navigation for Loreward-owned buttons. Gameplay bindings are
-- loaned through ControllerForever's own window protocol, never the game's
-- protected focus tables. Native button scripts and guide actions stay intact.
local N={version='3.7.39'}
ForeverHandheldJourneyControls=N
local rootNames={'LorewardSetupBox','LorewardWhereNextBox','LorewardFindWindow','LorewardPlanWindow','LorewardDirectionsWindow','ForeverHandheldStoryReader','LorewardDiscordBox','ForeverHandheldJourneyNoticeWindow','ForeverHandheldRareReaderWindow','ForeverHandheldFieldReaderWindow'}
local guidePickerName='ForeverHandheldRestedXPWindow'
rootNames[#rootNames+1]=guidePickerName
local decor={}
local active,claim,ring,footer,chosen,held,wasShown
local buttons={}
local clickOwners=setmetatable({},{__mode='k'})
local guidePicker
local guidePageSize=9
local updateButtons
local function anchor(region,root,x,y)
 local p,r,rp,px,py=region:GetPoint(1)
 if p~='TOPLEFT' or r~=root or rp~='TOPLEFT' or px~=x or py~=-y then
  region:ClearAllPoints();region:SetPoint('TOPLEFT',root,'TOPLEFT',x,-y)
 end
end
local function font(region,size)
 if region and region.GetFont then
  local face,old,flags=region:GetFont()
  if face and old~=size then region:SetFont(face,size,flags) end
 end
end
local function setupLayout(root)
 if not root.rows or not root.intro then return end
 local known={[root.title]=true,[root.intro]=true,[root.where]=true}
 if root.beta then known[root.beta]=true end
 local groups={}
 for _,r in ipairs(root.rows)do
  known[r.label]=true;if r.note then known[r.note]=true end
  local key=r.group or r.key
  groups[key]=groups[key] or {};table.insert(groups[key],r)
 end
 -- Replace only this addon's original section headings. Choice labels, notes
 -- and the native checked-state artwork remain the original regions.
 for _,region in ipairs({root:GetRegions()})do
  if region:IsObjectType('FontString') and not known[region] then region:Hide() end
 end
 root.foreverJourneyHeaders=root.foreverJourneyHeaders or {}
 local sections={{'quests','Quest reading',24},{'steps','Guide steps',24},{'levelUp','Level-up messages',24},
  {'lore','Story notes',504},{'readAloud','Read aloud',504},{'recipes','Recipe discoveries',504}}
 local ys={[24]=70,[504]=70}
 root:SetWidth(960);font(root.intro,15);root.intro:SetWidth(900);anchor(root.intro,root,24,20)
 for _,section in ipairs(sections)do
  local key,title,x=unpack(section)
  local shown={}
  for _,r in ipairs(groups[key] or {})do if r.button:IsShown() then shown[#shown+1]=r end end
  local header=root.foreverJourneyHeaders[key]
  if not header then
   header=root:CreateFontString(nil,'OVERLAY');header:SetFont(STANDARD_TEXT_FONT,17,'')
   header:SetTextColor(.95,.78,.38);header:SetText(title);root.foreverJourneyHeaders[key]=header
  end
  header:SetShown(#shown>0)
  if #shown>0 then
   local y=ys[x];anchor(header,root,x,y);y=y+30
   for _,r in ipairs(shown)do
    r.button:SetSize(24,24);anchor(r.button,root,x,y)
    r.label:SetWidth(398);font(r.label,15);anchor(r.label,root,x+34,y+2)
    local h=math.max(30,r.label:GetStringHeight()+10)
    if r.note then
     r.note:SetWidth(398);font(r.note,13);anchor(r.note,root,x+34,y+h)
     h=h+r.note:GetStringHeight()+8
    end
    r.button:SetHitRectInsets(0,-410,0,-math.max(0,h-24))
    r.button.foreverJourneyLabel=r.text
    r.button.foreverJourneyFocusWidth=432
    r.button.foreverJourneyFocusHeight=h
    y=y+h+10
   end
   ys[x]=y+16
  end
 end
 local bottom=math.max(ys[24],ys[504])+10
 for i,b in ipairs({root.start,root.notNow})do
  b:SetSize(190,34);anchor(b,root,24+(i-1)*202,bottom)
  if b.GetFontString then font(b:GetFontString(),16) end
 end
 root.where:SetWidth(900);font(root.where,13);anchor(root.where,root,24,bottom+46)
 local h=bottom+46+root.where:GetStringHeight()+22
 if root.beta then root.beta:SetWidth(900);font(root.beta,13);anchor(root.beta,root,24,h);h=h+root.beta:GetStringHeight()+18 end
 root:SetHeight(h)
end
local function listParts(root)
 local sc,bar
 for _,f in ipairs({root:GetChildren()})do
  if f:IsObjectType('ScrollFrame') then sc=f elseif f:IsObjectType('Slider') then bar=f end
 end
 if sc and bar then return sc,bar,sc:GetScrollChild() end
end
local function fitScroll(root,sc,bar,content,top,height)
 local view=580-top-64
 anchor(sc,root,24,top);sc:SetSize(890,view)
 anchor(bar,root,924,top);bar:SetHeight(view)
 content:SetSize(890,math.max(1,height))
 local range=math.max(0,height-view)
 bar:SetMinMaxValues(0,range);bar:SetShown(range>0)
 local value=math.max(0,math.min(range,bar:GetValue() or 0));bar:SetValue(value);sc:SetVerticalScroll(value)
 if root.thumb then root.thumb:SetHeight(math.max(24,view*view/math.max(view,height))) end
 root.foreverJourneyScroll={frame=sc,bar=bar,content=content}
 for i,b in ipairs({root.close,root.again or root.all})do
  b:SetSize(160,32);anchor(b,root,24+(i-1)*172,536)
  if b.GetFontString then font(b:GetFontString(),16) end
 end
end
local function planLayout(root)
 local sc,bar,content=listParts(root);if not sc or not root.blocks then return end
 root:SetSize(960,580)
 root.about:SetText('Choose a guide for your level. Open continues that journey in RestedXP.')
 root.about:SetWidth(900);font(root.about,16);anchor(root.about,root,24,20)
 root.party:SetWidth(900);font(root.party,16);anchor(root.party,root,24,52)
 root.status:SetWidth(900);font(root.status,14);root.status:SetTextColor(.76,.74,.68);anchor(root.status,root,24,78)
 local top=math.max(120,78+root.status:GetStringHeight()+18)
 local y,rowHeight,index=4,0,0
 for _,b in ipairs(root.blocks)do
  if b.button:IsShown() then
   local col=index%2
   if col==0 and index>0 then y=y+rowHeight+18;rowHeight=0 end
   local x=6+col*444
   b.label:SetWidth(326);font(b.label,17);anchor(b.label,content,x+96,y+2)
   local lh=b.label:GetStringHeight()
   b.detail:SetWidth(326);font(b.detail,15);anchor(b.detail,content,x+96,y+lh+12)
   local h=math.max(60,lh+b.detail:GetStringHeight()+16)
   b.button:SetSize(84,32);anchor(b.button,content,x,y)
   if b.button.GetFontString then font(b.button:GetFontString(),16) end
   b.button.foreverJourneyLabel='Open '..(b.label:GetText() or 'guide')
   b.button.foreverJourneyFocusWidth=424;b.button.foreverJourneyFocusHeight=h
   b.button.foreverJourneyScroll=sc
   rowHeight=math.max(rowHeight,h);index=index+1
  end
 end
 if root.empty and root.empty:IsShown() then root.empty:SetWidth(870);font(root.empty,16);anchor(root.empty,content,6,6);rowHeight=50 end
 fitScroll(root,sc,bar,content,top,y+rowHeight+8)
end
local function nextLayout(root)
 if not root.rows or not root.intro or not root.footer then return end
 root:SetWidth(960);root.intro:SetWidth(900);font(root.intro,17);anchor(root.intro,root,24,24)
 local y=24+root.intro:GetStringHeight()+26
 for _,r in ipairs(root.rows)do
  if r.button:IsShown() and r.option then
   r.button:SetSize(340,38);anchor(r.button,root,24,y)
   if r.button.GetFontString then font(r.button:GetFontString(),16) end
   r.note:SetWidth(540);font(r.note,15);anchor(r.note,root,388,y+5)
   y=y+math.max(38,r.note:GetStringHeight()+10)+20
  end
 end
 root.footer:SetWidth(900);font(root.footer,14);anchor(root.footer,root,24,y)
 y=y+root.footer:GetStringHeight()+24
 root.close:SetSize(160,34);anchor(root.close,root,24,y);root:SetHeight(y+58)
end
local function findLayout(root)
 local sc,bar,content=listParts(root);if not sc or not root.lines then return end
 root:SetSize(960,580)
 root.about:SetWidth(900);font(root.about,16);anchor(root.about,root,24,20)
 local sy=24+root.about:GetStringHeight()+14
 font(root.searchLabel,16);anchor(root.searchLabel,root,24,sy+5)
 root.edit:SetSize(650,32);font(root.edit,16);anchor(root.edit,root,170,sy)
 if not root.foreverSearch then
  local b=CreateFrame('Button',nil,root,'UIPanelButtonNoTooltipTemplate')
  b:SetText('Search');b:SetScript('OnClick',function()N.startSearch(root)end);root.foreverSearch=b
 end
 root.foreverSearch:SetSize(100,32);anchor(root.foreverSearch,root,834,sy)
 if root.foreverSearch.GetFontString then font(root.foreverSearch:GetFontString(),16)end
 root.count:SetWidth(900);font(root.count,14);anchor(root.count,root,24,sy+44)
 local top=sy+44+root.count:GetStringHeight()+18
 local pieces={}
 local function add(region,kind,line)
  if region:IsShown() then local _,_,_,_,y=region:GetPoint(1);pieces[#pieces+1]={region=region,kind=kind,line=line,y=y or 0} end
 end
 for _,t in ipairs(root.titles or {})do add(t,'title')end
 for _,t in ipairs(root.notes or {})do add(t,'note')end
 for _,l in ipairs(root.lines)do add(l.button,'line',l)end
 table.sort(pieces,function(a,b)return a.y>b.y end)
 local y,context=6,nil
 for _,p in ipairs(pieces)do
  if p.kind=='line' then
   local l=p.line;l.button:SetSize(92,32);anchor(l.button,content,12,y)
   l.text:SetWidth(746);font(l.text,16);anchor(l.text,content,116,y+3)
   local h=math.max(36,l.text:GetStringHeight()+8)
   if l.button.GetFontString then font(l.button:GetFontString(),16)end
   l.button.foreverJourneyLabel='Open '..(l.target and l.target.title or 'quest')
   l.button.foreverJourneyFocusWidth=858;l.button.foreverJourneyFocusHeight=h
   l.button.foreverJourneyScroll=sc;l.button.foreverJourneyContext=context;y=y+h+12
  else
   local t=p.region;if p.kind=='title' then context=t end;t:SetWidth(866);font(t,p.kind=='title' and 18 or 15);anchor(t,content,6,y)
   y=y+t:GetStringHeight()+(p.kind=='title' and 12 or 18)
  end
 end
 fitScroll(root,sc,bar,content,top,y+4)
end
local function communityLayout(root)
 if not root.about or not root.edit or not root.hint or not root.close then return end
 root:SetSize(780,350)
 root.about:SetWidth(424);font(root.about,18);anchor(root.about,root,320,28)
 root.edit:SetSize(424,36);font(root.edit,17);anchor(root.edit,root,320,142)
 root.hint:SetWidth(424);font(root.hint,16);anchor(root.hint,root,320,196)
 root.hint:SetTextColor(.82,.80,.73)
 -- The image encodes only the installed addon's published invite. If that
 -- address changes, never show a QR code for a different destination.
 local matches=root.edit:GetText()=='https://discord.gg/tFDavRQXAj'
 if not root.foreverCommunityQR then
  local qr=root:CreateTexture(nil,'ARTWORK');qr:SetTexture('Interface\\AddOns\\ForeverHandheld\\CommunityQR.tga')
  qr:SetSize(256,256);anchor(qr,root,28,28);root.foreverCommunityQR=qr
 end
 root.foreverCommunityQR:SetShown(matches)
 root.hint:SetText(matches and 'Scan with your phone to open the community. No keyboard needed on the Deck.' or 'The community address has changed. Use the address above; the old QR code is hidden.')
 root.close:SetSize(200,36);anchor(root.close,root,548,290)
 if root.close.GetFontString then font(root.close:GetFontString(),16) end
end
local function routePane(root,height)
 local info=root.foreverRouteScroll
 if not info then
  local sc=CreateFrame('ScrollFrame',nil,root,'BackdropTemplate')
  sc:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
  sc:SetBackdropColor(.025,.030,.025,.85);sc:SetBackdropBorderColor(.45,.38,.25,.65)
  local content=CreateFrame('Frame',nil,sc);sc:SetScrollChild(content)
  local bar=CreateFrame('Slider',nil,root);bar:SetOrientation('VERTICAL');bar:SetWidth(6)
  local thumb=bar:CreateTexture(nil,'OVERLAY');thumb:SetColorTexture(.68,.56,.36,1);thumb:SetWidth(6);bar:SetThumbTexture(thumb)
  local title=root:CreateFontString(nil,'OVERLAY');title:SetFont(STANDARD_TEXT_FONT,14,'');title:SetTextColor(.84,.75,.56);title:SetText('ROUTE')
  anchor(title,root,644,20)
  bar:SetScript('OnValueChanged',function(_,v)sc:SetVerticalScroll(v)end)
  sc:EnableMouseWheel(true)
  sc:SetScript('OnMouseWheel',function(_,delta)
   local lo,hi=bar:GetMinMaxValues();bar:SetValue(math.max(lo,math.min(hi,(bar:GetValue() or 0)-delta*42)))
  end)
  info={frame=sc,bar=bar,content=content,thumb=thumb,label='Route'}
  root.foreverRouteScroll=info
  -- The native result remains the source of truth. Only its parent and
  -- presentation change; service actions, refresh and map links are untouched.
  root.result:SetParent(content)
 end
 local view=math.max(120,height-114)
 anchor(info.frame,root,638,48);info.frame:SetSize(288,view)
 anchor(info.bar,root,934,48);info.bar:SetHeight(view)
 root.result:SetWidth(268);font(root.result,18);root.result:SetSpacing(3);anchor(root.result,info.content,10,10)
 local text=root.result:GetText() or ''
 local total=(root.result.GetStringHeight and root.result:GetStringHeight() or 0)+24
 if ForeverHandheldRouteMap then total=ForeverHandheldRouteMap.layout(root,info,total) end
 total=math.max(view,total)
 info.content:SetSize(288,total)
 local limit=math.max(0,total-view);info.bar:SetMinMaxValues(0,limit)
 local value=text~=info.text and 0 or math.max(0,math.min(limit,info.bar:GetValue() or 0))
 info.text=text;info.bar:SetValue(value);info.frame:SetVerticalScroll(value);info.bar:SetShown(limit>0)
 info.thumb:SetHeight(math.max(24,view*view/total))
 root.foreverJourneyScroll=info
end
function N.layout(root)
 local name=root.GetName and root:GetName()
 if name=='LorewardDiscordBox' then return communityLayout(root) end
 if name=='LorewardSetupBox' then return setupLayout(root) end
 if name=='LorewardPlanWindow' then return planLayout(root) end
 if name=='LorewardWhereNextBox' then return nextLayout(root) end
 if name=='LorewardFindWindow' then return findLayout(root) end
 if not root.buttons or not root.headers or not root.about or not root.result then return end
 local groups={}
 for _,b in ipairs(root.buttons)do
  if b:IsShown() and b.section then
   groups[b.section]=groups[b.section] or {};table.insert(groups[b.section],b)
  end
 end
 if root:GetWidth()~=960 then root:SetWidth(960) end
 local intro='Choose a service. Loreward finds the nearest available stop and route.'
 if root.about:GetText()~=intro then root.about:SetText(intro) end
 font(root.about,15);root.about:SetWidth(580);anchor(root.about,root,24,18)
 local y,index=62,0
 for _,section in ipairs({'supplies','travel','trainers','mine','learn'})do
  local list=groups[section] or {}
  if #list>0 or (section=='learn' and root.learn and root.learn:IsShown()) then
   index=index+1
   local header=root.headers[index]
   if header then font(header,16);anchor(header,root,24,y) end
   if section=='learn' then
    root.learn:SetSize(96,26);anchor(root.learn,root,516,y-3)
   end
   y=y+26
   for i,b in ipairs(list)do
    local x=24+((i-1)%3)*200
    anchor(b,root,x,y+math.floor((i-1)/3)*38)
    if b:GetWidth()~=192 or b:GetHeight()~=30 then b:SetSize(192,30) end
    if b.GetFontString then font(b:GetFontString(),14) end
   end
   y=y+math.ceil(#list/3)*38+10
  end
 end
 local height=math.max(450,y+54)
 if root:GetHeight()~=height then root:SetHeight(height) end
 routePane(root,height)
 for i,b in ipairs({root.close,root.again})do
  b:SetSize(130,30);anchor(b,root,24+(i-1)*142,height-42)
  if b.GetFontString then font(b:GetFontString(),15) end
 end
end
local function visible(f)return f and f.IsVisible and not (f.IsForbidden and f:IsForbidden()) and f:IsVisible() and f:GetAlpha()>.01 end
local function wheelOwnsInput()
 return visible(_G.GamepadRadial) or visible(_G.GamepadSpellFlyout)
end
local function guideRows(menu)
 local rows={}
 for _,entry in ipairs(menu)do
  local children=type(entry.menuList)=='table' and guideRows(entry.menuList)
  local guide=not entry.isTitle and type(entry.func)=='function' and type(entry.arg1)=='string' and type(entry.arg2)=='string'
  if (children and #children>0) or guide then
   rows[#rows+1]={text=entry.text,children=children and #children>0 and children or nil,entry=entry}
  end
 end
 return rows
end
function N.front()
 local chosen,score
 local strata={BACKGROUND=0,LOW=1,MEDIUM=2,HIGH=3,DIALOG=4,FULLSCREEN=5,FULLSCREEN_DIALOG=6,TOOLTIP=7}
 for _,name in ipairs(rootNames)do
  local f=_G[name]
  if visible(f) then
   local layer=f.GetFrameStrata and f:GetFrameStrata() or 'MEDIUM'
   local value=(strata[layer] or 2)*100000+(f:GetFrameLevel() or 0)
   if not score or value>score then chosen,score=f,value end
  end
 end
 return chosen
end
local function otherHoldOwner()
 local cf=ControllerForever
 if cf.Menu and cf.Menu.state and cf.Menu.state.open then return true end
 if cf.Kit and cf.Kit.openOne and cf.Kit.openOne() then return true end
 if cf.AH and cf.AH.win and cf.AH.win.isOpen and cf.AH.win.isOpen() then return true end
 return false
end
local function otherOwner()
 if otherHoldOwner() then return true end
 for _,name in ipairs({'WorldMapFrame','GameMenuFrame','SettingsPanel','ControllerForeverChatEdit','StaticPopup1','StaticPopup2','StaticPopup3','StaticPopup4'})do
  if visible(_G[name]) then return true end
 end
 return false
end
local function enabled()
 local rb=ControllerForever.RuleBar
 return rb and rb.isGamepadOn and rb.isGamepadOn()
end
function N.next(items,current,dx,dy)
 local at=items[current];if not at then return 1 end
 local best,score=current,math.huge
 for i,p in ipairs(items)do
  local along=(p.x-at.x)*dx+(p.y-at.y)*dy
  local across=math.abs((p.x-at.x)*dy-(p.y-at.y)*dx)
  if along>2 then
   local s=along+across*3
   if s<score then best,score=i,s end
  end
 end
 return best
end
local function editing(root)
 return root and root==N.editingRoot and root.edit and root.edit:HasFocus()
end
function N.startSearch(root)
 if InCombatLockdown() or not visible(root) or root:GetName()~='LorewardFindWindow' then return end
 N.editingRoot=root;root.edit:SetFocus()
end
local function clearSearch(root)
 local refocus=editing(root)
 if root.all then root.all:Click('LeftButton') end
 if refocus then N.startSearch(root) end
end
local function release()
 if claim then claim.clear();if not InCombatLockdown() then claim.commit() end end
 if held and not InCombatLockdown() then
  if not otherHoldOwner() then ControllerForever.RuleBar.state.bindingHold=false end
  held=nil
 end
 active=nil;chosen=nil;buttons={};N.editingRoot=nil
 if ring then ring:Hide() end
 if footer then footer:Hide() end
end
local function collect(root)
 local out={}
 local function walk(f,depth)
  if depth>4 or not visible(f) then return end
  for _,child in ipairs({f:GetChildren()})do
   if child~=ring and child~=footer and visible(child) then
    if child.IsObjectType and (child:IsObjectType('Button') or child:IsObjectType('CheckButton')) and child:GetScript('OnClick') and
      (not child.IsEnabled or child:IsEnabled()) and (not child.IsProtected or not child:IsProtected()) then
     local x,y=child:GetCenter()
     if x and y then
      if not clickOwners[child] then
       local clicked=child
       child:HookScript('OnClick',function()
        local owner=clickOwners[clicked]
        if active==owner and visible(owner) then
         if not owner.foreverJourneyResumeChoice then chosen=clicked end
         if owner==guidePicker then updateButtons() end
        end
       end)
      end
      clickOwners[child]=root
      out[#out+1]={frame=child,x=x,y=y}
     end
    else walk(child,depth+1) end
   end
  end
 end
 walk(root,0)
 table.sort(out,function(a,b)if math.abs(a.y-b.y)>3 then return a.y>b.y end return a.x<b.x end)
 return out
end
function N.reveal(root,button)
 local info=root and root.foreverJourneyScroll
 if not info or not button or button.foreverJourneyScroll~=info.frame then return end
 local sc=info.frame
 local top,bottom=sc:GetTop(),sc:GetBottom()
 local bt=button:GetTop();local bb=bt-(button.foreverJourneyFocusHeight or button:GetHeight())
 if button.foreverJourneyContext then bt=math.max(bt,button.foreverJourneyContext:GetTop()) end
 local delta=bt>top-4 and top-4-bt or (bb<bottom+4 and bottom+4-bb or 0)
 if delta~=0 then
  local lo,hi=info.bar:GetMinMaxValues();info.bar:SetValue(math.max(lo,math.min(hi,info.bar:GetValue()+delta)))
 end
end
local function onScreen(button)
 local sc=button.foreverJourneyScroll;if not sc then return true end
 local top=button:GetTop();local bottom=top-(button.foreverJourneyFocusHeight or button:GetHeight())
 if button.foreverJourneyContext then top=math.max(top,button.foreverJourneyContext:GetTop()) end
 return top<=sc:GetTop()+1 and bottom>=sc:GetBottom()-1
end
local function draw()
 if not active then return end
 if editing(active) then
  ring:ClearAllPoints();ring:SetPoint('TOPLEFT',active.edit,'TOPLEFT',-3,3);ring:SetPoint('BOTTOMRIGHT',active.edit,'BOTTOMRIGHT',3,-3)
  ring:SetFrameLevel(active:GetFrameLevel()+4);ring:Show()
  footer.text:SetText('Hold upper-left rear to dictate    A Done    B Back    X Clear search');footer:Show()
  return
 end
 local index=1
 for i,p in ipairs(buttons)do if p.frame==chosen then index=i;break end end
 chosen=buttons[index] and buttons[index].frame
 if not chosen then ring:Hide();footer:Hide();return end
 ring:ClearAllPoints();ring:SetPoint('TOPLEFT',chosen,'TOPLEFT',-3,3);
 if chosen.foreverJourneyFocusWidth then
  ring:SetSize(chosen.foreverJourneyFocusWidth+6,chosen.foreverJourneyFocusHeight+6)
 else ring:SetPoint('BOTTOMRIGHT',chosen,'BOTTOMRIGHT',3,-3) end
 ring:SetFrameLevel(chosen:GetFrameLevel()+2);ring:SetShown(onScreen(chosen))
 local label=chosen.foreverJourneyLabel or (chosen.GetText and chosen:GetText()) or 'Select'
 if active==guidePicker then
  local list=guidePicker.path[#guidePicker.path]
  local page=#list.rows>guidePageSize and '    LB / RB Page' or ''
  local action=chosen.guideRow.children and 'Browse' or 'Load guide'
  local back=#guidePicker.path>1 and 'Back' or 'Close'
  footer.text:SetText('D-pad Choose'..page..'    A '..action..'    B '..back);footer:Show()
  return
 end
 if chosen.GetChecked then label=(chosen:GetChecked() and 'Selected: ' or '')..label end
 label=tostring(label or 'Select'):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')
 if #label>72 then label=label:sub(1,69)..'...' end
 footer.text:SetText('D-pad Choose    '..(active.foreverJourneyScroll and active.foreverJourneyScroll.bar:IsShown() and ('LB / RB '..(active.foreverJourneyScroll.label or 'Page')..'    ') or '')..'A '..label..(active:GetName()=='LorewardFindWindow' and '    X Search    Y Clear' or '')..'    B Back');footer:Show()
end
updateButtons=function()
 if not active then return end
 if active.foreverJourneyResumeChoice then
  chosen=active.foreverJourneyResumeChoice;active.foreverJourneyResumeChoice=nil
 end
 buttons=collect(active);draw()
end
local function renderGuidePicker(root,focus)
 local path=root.path
 local list=path[#path]
 local pages=math.ceil(#list.rows/guidePageSize)
 local start=(list.page-1)*guidePageSize
 local current=RXP.currentGuide
 local title=RXP.GetGuideName and current and RXP.GetGuideName(current)
 root.current:SetText(title and ('Current guide: '..title) or 'No guide loaded')
 root.location:SetText(#path>1 and list.title or 'Guide packs')
 root.page:SetText(pages>1 and (list.page..' / '..pages) or '')
 root.back:SetText(#path>1 and 'Back' or 'Close')
 for i,button in ipairs(root.rows)do
  local row=list.rows[start+i]
  button.guideRow=row
  button:SetShown(row~=nil)
  if row then
   button.label:SetText(row.text)
   local entry=row.entry
   local loaded=current and current.group==entry.arg1 and current.name==entry.arg2
   button.status:SetText(row.children and '>' or (loaded and 'Loaded' or ''))
  end
 end
 root.foreverJourneyResumeChoice=root.rows[focus or 1]
end
local function guideBack(root)
 if #root.path==1 then root:Hide();return end
 table.remove(root.path)
 renderGuidePicker(root,root.path[#root.path].focus)
 if active==root then updateButtons() end
end
local function guidePage(root,delta,focusLast)
 local list=root.path[#root.path]
 local page=math.max(1,math.min(math.ceil(#list.rows/guidePageSize),list.page+delta))
 if page==list.page then return end
 list.page=page
 renderGuidePicker(root,focusLast and guidePageSize or 1)
 if active==root then updateButtons() end
end
local function createGuidePicker()
 local root=CreateFrame('Frame',guidePickerName,UIParent,'BackdropTemplate')
 root:SetFrameStrata('DIALOG');root:EnableMouse(true);root:EnableMouseWheel(true)
 root:SetSize(760,500)
 root:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
 root:SetBackdropColor(.025,.030,.029,1);root:SetBackdropBorderColor(.72,.60,.39,1)
 local function label(parent,size,gold)
  local region=parent:CreateFontString(nil,'OVERLAY')
  region:SetFont(STANDARD_TEXT_FONT,size,'');region:SetJustifyH('LEFT');region:SetMaxLines(1)
  if gold then region:SetTextColor(.95,.78,.38) else region:SetTextColor(.94,.90,.82) end
  return region
 end
 local title=label(root,26,false);title:SetPoint('TOPLEFT',22,-16);title:SetText('RestedXP guides')
 root.current=label(root,16,false);root.current:SetPoint('TOPLEFT',22,-54);root.current:SetWidth(710)
 root.location=label(root,18,true);root.location:SetPoint('TOPLEFT',22,-91);root.location:SetWidth(650)
 root.page=label(root,15,true);root.page:SetPoint('TOPRIGHT',-22,-93)
 local back=CreateFrame('Button',nil,root,'UIPanelButtonNoTooltipTemplate')
 back:SetSize(86,28);back:SetPoint('TOPRIGHT',-20,-16)
 back:SetScript('OnMouseUp',function(_,key)if key=='LeftButton' then guideBack(root) end end);root.back=back
 root.rows={}
 for i=1,guidePageSize do
  local button=CreateFrame('Button',nil,root)
  button:SetSize(716,36);button:SetPoint('TOPLEFT',22,-122-(i-1)*41)
  local fill=button:CreateTexture(nil,'BACKGROUND');fill:SetAllPoints();fill:SetColorTexture(.075,.082,.067,1)
  local hover=button:CreateTexture(nil,'HIGHLIGHT');hover:SetAllPoints();hover:SetColorTexture(.95,.78,.38,.14)
  button.label=label(button,18,false);button.label:SetPoint('LEFT',12,0);button.label:SetWidth(600)
  button.status=label(button,15,true);button.status:SetPoint('RIGHT',-12,0)
  button:SetScript('OnClick',function(self)
   if InCombatLockdown() then return end
   local row=self.guideRow
   if not row then return end
   if row.children then
    root.path[#root.path].focus=i
    root.path[#root.path+1]={title=row.text,rows=row.children,page=1}
    renderGuidePicker(root)
   else
    local entry=row.entry
    root:Hide()
    entry.func(nil,entry.arg1,entry.arg2)
   end
  end)
  root.rows[i]=button
 end
 root:SetScript('OnMouseWheel',function(_,delta)guidePage(root,delta>0 and -1 or 1)end)
 root:Hide()
 if UISpecialFrames then table.insert(UISpecialFrames,guidePickerName) end
 return root
end
function N.openGuides()
 if InCombatLockdown() or wheelOwnsInput() then return end
 if guidePicker and guidePicker:IsShown() then guidePicker:Hide();return end
 if not RXP or not RXPFrame or not RXPFrame.GenerateMenuTable then
  print('RestedXP guide catalog is unavailable.');return
 end
 local rows=guideRows(RXPFrame:GenerateMenuTable({}))
 if #rows==0 then print('RestedXP has no guides available for this character.');return end
 guidePicker=guidePicker or createGuidePicker()
 guidePicker.path={{rows=rows,page=1}}
 local height=UIParent:GetHeight()
 local scale=math.min(1,(UIParent:GetWidth()-36)/760,(height-64)/500)
 guidePicker:SetScale(scale)
 guidePicker:ClearAllPoints();guidePicker:SetPoint('CENTER',UIParent,'CENTER',0,math.min(74,height/2-250*scale-18))
 RXP:CloseMenu()
 renderGuidePicker(guidePicker);guidePicker:Show()
end
SLASH_FOREVERHANDHELDGUIDES1='/fhguides'
if SlashCmdList then SlashCmdList.FOREVERHANDHELDGUIDES=N.openGuides end
function N.press(key)
 if not active or not visible(active) or InCombatLockdown() or otherOwner() or (active==guidePicker and wheelOwnsInput()) then return end
 if GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus() and not editing(active) then return end
 if editing(active) then
  if key=='A' or key=='B' then active.edit:ClearFocus();N.editingRoot=nil;updateButtons()
  elseif key=='X' then clearSearch(active);draw() end
  return
 end
 if active:GetName()=='LorewardFindWindow' then
  if key=='X' then N.startSearch(active);draw();return
  elseif key=='Y' then clearSearch(active);updateButtons();return end
 end
 if active~=guidePicker then updateButtons() end
 if active==guidePicker then
  if key=='B' then guideBack(active);return end
  if key=='PAGEUP' or key=='PAGEDOWN' then guidePage(active,key=='PAGEUP' and -1 or 1);return end
  if #buttons>0 then
   if key=='UP' and chosen==buttons[1].frame then guidePage(active,-1,true);return end
   if key=='DOWN' and chosen==buttons[#buttons].frame then guidePage(active,1);return end
  end
 end
 if key=='B' then active:Hide();release();return end
 if key=='PAGEUP' or key=='PAGEDOWN' then
  local info=active.foreverJourneyScroll
  if info then
   local lo,hi=info.bar:GetMinMaxValues();local delta=info.frame:GetHeight()*.8*(key=='PAGEUP' and -1 or 1)
   info.bar:SetValue(math.max(lo,math.min(hi,info.bar:GetValue()+delta)))
   for _,p in ipairs(buttons)do if p.frame.foreverJourneyScroll and onScreen(p.frame) then chosen=p.frame;break end end
   draw()
  end
  return
 end
 if key=='A' then
  N.reveal(active,chosen)
  if chosen and chosen:IsVisible() and chosen:IsEnabled() then chosen:Click('LeftButton') end
  if active and visible(active) then
   if active~=guidePicker then updateButtons() end
  else release() end
  return
 end
 local directions={UP={0,1},DOWN={0,-1},LEFT={-1,0},RIGHT={1,0}}
 local d=directions[key];if not d then return end
 local at=1;for i,p in ipairs(buttons)do if p.frame==chosen then at=i end end
 local nextIndex=N.next(buttons,at,d[1],d[2]);chosen=buttons[nextIndex] and buttons[nextIndex].frame;if chosen then N.reveal(active,chosen) end;draw()
end
local function build(root)
 ring=CreateFrame('Frame',nil,root);ring:EnableMouse(false)
 for _,side in ipairs({{'TOPLEFT','TOPRIGHT',false},{'BOTTOMLEFT','BOTTOMRIGHT',false},{'TOPLEFT','BOTTOMLEFT',true},{'TOPRIGHT','BOTTOMRIGHT',true}})do
  local t=ring:CreateTexture(nil,'OVERLAY');t:SetColorTexture(.95,.78,.38,1)
  t:SetPoint(side[1]);t:SetPoint(side[2]);if side[3] then t:SetWidth(2) else t:SetHeight(2) end
 end
 footer=CreateFrame('Frame',nil,root);footer:EnableMouse(false);footer:SetPoint('TOPLEFT',root,'BOTTOMLEFT',0,-4);footer:SetPoint('TOPRIGHT',root,'BOTTOMRIGHT',0,-4);footer:SetHeight(26)
 local bg=footer:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetColorTexture(.025,.030,.029,1)
 footer.text=footer:CreateFontString(nil,'OVERLAY');footer.text:SetFont(STANDARD_TEXT_FONT,13,'');footer.text:SetTextColor(.94,.9,.82);footer.text:SetPoint('CENTER')
 decor[root]={ring=ring,footer=footer}
 root:HookScript('OnHide',function()if active==root then release() end end)
end
local made=false
local function take(root)
 local cf=ControllerForever
 if not cf.Binds or not cf.Binds.claimant or not cf.RuleBar or not cf.RuleBar.state then return end
 if cf.RuleBar.state.bindingHold and not held then return end
 if not decor[root] then build(root) else ring=decor[root].ring;footer=decor[root].footer end
 if not made then
  for _,key in ipairs({'A','B','X','Y','UP','DOWN','LEFT','RIGHT','PAGEUP','PAGEDOWN','NOOP'})do
   local button=CreateFrame('Button','ForeverHandheldJourneyKey'..key,UIParent)
   button:SetSize(1,1);button:SetPoint('TOPLEFT',UIParent,'TOPLEFT',-20,20)
   button:RegisterForClicks('AnyUp');button:SetScript('OnClick',function()N.press(key)end)
  end
  made=true
 end
 claim=claim or cf.Binds:claimant('foreverJourney',cf.Binds.PRIORITY.ourwindow+1,{exclusive=true,overGame=true,outOfFight=true})
 local keys={PAD3='X',PAD4='Y',PADLSHOULDER='PAGEUP',PADRSHOULDER='PAGEDOWN',PAGEUP='PAGEUP',PAGEDOWN='PAGEDOWN',PAD1='A',PAD2='B',PADDUP='UP',PADDDOWN='DOWN',PADDLEFT='LEFT',PADDRIGHT='RIGHT',PADLTRIGGER='NOOP',PADRTRIGGER='NOOP',UP='UP',DOWN='DOWN',LEFT='LEFT',RIGHT='RIGHT',ENTER='A'}
 local map={}
 for pad,action in pairs(keys)do
  for _,prefix in ipairs({'','SHIFT-','CTRL-','ALT-','CTRL-SHIFT-','ALT-SHIFT-','ALT-CTRL-','ALT-CTRL-SHIFT-'})do map[prefix..pad]='CLICK ForeverHandheldJourneyKey'..action..':LeftButton' end
 end
 active=root;chosen=root.foreverJourneyResumeChoice;root.foreverJourneyResumeChoice=nil;held=true;cf.RuleBar.state.bindingHold=true
 claim.replace(map);claim.commit();updateButtons();if chosen then N.reveal(root,chosen) end
end
function N.attachMenu()
 local menu=ControllerForever and ControllerForever.Menu
 if not menu or not menu.opt or not menu.addHomeRow or not menu.pages or not SlashCmdList or not SlashCmdList.LOREWARD then return false end
 if menu.foreverJourneyPage then return true end
 local rows={}
 rows[#rows+1]=menu.opt({name='RestedXP guides',desc='Browse guide packs and load a route for this character.',icon='Interface\\Icons\\INV_Misc_Book_09',
  activate=N.openGuides})
 for _,item in ipairs({
  {'Nearby services','nearest','Find vendors, trainers, banks, mailboxes and travel connections.'},
  {'Quest destinations','find','Browse your quests and their guides. X opens search; hold the upper-left rear button to dictate.'},
  {'Plan your journey','plan','Compare guides suited to your level and group.'},
  {'Journey preferences','setup','Choose quest reading, guide details and story preferences.'},
  {'Next chapter','next','See the next choices in the current Loreward route.'},
 })do
  local command=item[2]
  rows[#rows+1]=menu.opt({name=item[1],desc=item[3],icon='Interface\\Icons\\INV_Misc_Map_01',
   activate=function()if not InCombatLockdown() then
    if command=='next' and ForeverHandheldJourneyNotice then ForeverHandheldJourneyNotice.run()
    else SlashCmdList.LOREWARD(command)end
   end end})
 end
 rows[#rows+1]=menu.opt({name='Story journal',desc='Read recent story cards and guide notes at your pace. LB / RB scroll longer notes.',icon='Interface\\Icons\\INV_Misc_Book_09',
  activate=function()if ForeverHandheldStory then ForeverHandheldStory.open() end end})
 rows[#rows+1]=menu.opt({name='Rare loot',desc='Inspect the loot from recent RareScanner alerts. A reads an item; LB / RB scroll its full details.',icon='Interface\\Icons\\INV_Misc_Bag_10',
  activate=function()if ForeverHandheldRareReader then ForeverHandheldRareReader.open()end end})
 rows[#rows+1]=menu.opt({name='Field notes',desc='Read the last inspected unit, spell or aura. LB / RB scroll; B returns.',icon='Interface\\Icons\\INV_Misc_Book_09',
  activate=function()if ForeverHandheldFieldReader then ForeverHandheldFieldReader.open()end end})
 rows[#rows+1]=menu.opt({name='Community',desc='Questions and guide feedback. Scan the invite with your phone.',icon='Interface\\Icons\\INV_Misc_Note_01',
  activate=function()if not InCombatLockdown() then SlashCmdList.LOREWARD('discord') end end})
 rows[#rows+1]=menu.opt({back=true,name='Back',desc='Return to the controller menu.'})
 menu.pages.foreverjourney={title='Journey',entries=rows}
 menu.addHomeRow(menu.opt({page='foreverjourney',name='Journey',icon='Interface\\Icons\\INV_Misc_Map_01',
  desc='Destinations, nearby services, guide planning and reading preferences.',keywords='loreward guide quest journey search restedxp'}),2)
 menu.foreverJourneyPage=true
 return true
end
local elapsed=0
local driver=CreateFrame('Frame')
driver:RegisterEvent('PLAYER_REGEN_DISABLED');driver:RegisterEvent('PLAYER_REGEN_ENABLED')
driver:SetScript('OnEvent',function(_,event)
 if event=='PLAYER_REGEN_DISABLED' and guidePicker then guidePicker:Hide() end
 release()
end)
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0
 local ok,err=pcall(function()
  if not InCombatLockdown() then N.attachMenu() end
  local root=N.front()
  local shown=visible(root)
  if shown and root~=wasShown and not InCombatLockdown() and enabled() and not otherOwner() then
   -- A slash command leaves an empty native chat editor focused. End only
   -- that empty editing session when the requested guide window opens.
   -- Never discard a draft or steal a later intentional chat focus.
   local edit=GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
   local name=edit and edit.GetName and edit:GetName()
   if root:GetName()=='LorewardDiscordBox' and edit==root.edit then edit:ClearFocus() end
   if name and name:match('^ChatFrame%d+EditBox$') and edit.GetText and edit:GetText()=='' then edit:ClearFocus() end
  end
  wasShown=shown and root or nil
  if N.editingRoot and not editing(N.editingRoot) then N.editingRoot=nil end
  if InCombatLockdown() or not enabled() or otherOwner() or (root==guidePicker and wheelOwnsInput()) or
    (GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus() and not editing(root)) or not shown then
   if active or held then release() end
   return
  end
  if active and active~=root then release() end
  if not active then take(root) elseif root~=guidePicker then updateButtons() end
 end)
 if not ok then release();ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.journeyError=tostring(err) end
end)
