-- Presentation only: the native editor owns all selection, assignment and keys.
local VERSION='3.7.112'
local driver=CreateFrame('Frame')
local elapsed,shade,modalShade=0,nil,nil
local originals=setmetatable({},{__mode="k"})
local styledSide=setmetatable({},{__mode='k'})
local checkedPanel
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function safe(f)return f and not (f.IsForbidden and f:IsForbidden()) and not (f.IsProtected and f:IsProtected())end
local function shown(f)return safe(f) and f:IsShown()end
local function number(v)return public(v) and type(v)=='number' and v==v and v>0 end
local function scale(f,value)
 if math.abs(f:GetScale()-value)>.001 then f:SetScale(value)end
end
local function anchor(f,point,parent,relative,x,y)
 local a,b,c,d,e=f:GetPoint(1)
 if a==point and b==parent and c==relative and public(d) and public(e) and type(d)=='number' and type(e)=='number' and math.abs(d-x)<.05 and math.abs(e-y)<.05 then return end
 f:ClearAllPoints();f:SetPoint(point,parent,relative,x,y)
end
local function font(f,size)
 if not safe(f) or not f.GetFont then return end
 local face,n,flags=f:GetFont()
 if public(face) and number(n) and public(flags) and type(face)=='string' and n~=size then f:SetFont(face,size,flags)end
end
local function height(f,h)if safe(f) and f:GetHeight()~=h then f:SetHeight(h)end end
local function width(f,w)if safe(f) and f:GetWidth()~=w then f:SetWidth(w)end end
local function spacing(f,n)if safe(f) and f.GetSpacing and f:GetSpacing()~=n then f:SetSpacing(n)end end
local function restoreCombatSwitch(root)
 local switch=root and root.crCombatSwitch
 local old=switch and originals[switch]
 if old and safe(switch) then
  anchor(switch,unpack(old.point));width(switch,old.width)
  originals[switch]=nil
 end
end
local function releaseNested(picker)
 for _,key in ipairs({'editBox','styleBox'})do
  local box=picker and picker[key]
  local old=box and originals[box]
  if old and safe(box) then box:SetFrameStrata(old.strata);originals[box]=nil end
 end
end
local function restore(root,picker)
 releaseNested(picker)
 restoreCombatSwitch(root)
 local old=root and originals[root]
 if old then
  if safe(root) then height(root,old.h)end
  originals[root]=nil
 end
 local po=picker and originals[picker]
 if po and safe(picker) then picker:SetFrameStrata(po.strata);originals[picker]=nil end
end
local function fitExtraBars(root)
 local page=root.crSide
 local switch=root.crCombatSwitch
 if page and shown(page.tab) and shown(switch) then
  if not originals[switch] then originals[switch]={point={switch:GetPoint(1)},width=switch:GetWidth()}end
  width(switch,130);anchor(switch,'CENTER',root,'TOPLEFT',root:GetWidth()-112,-19)
 else restoreCombatSwitch(root)end
 if not page or not shown(page.cover) or not safe(page.about) or not safe(page.info) then return end
 if not styledSide[page.cover] then
  for _,r in ipairs({page.cover:GetRegions()})do
   if safe(r) and r.IsObjectType and r:IsObjectType('Texture') and r:GetDrawLayer()=='BACKGROUND' then
    r:SetColorTexture(.035,.043,.036,1)
   end
  end
  styledSide[page.cover]=true
 end
 local center=root:GetWidth()/2
 local aboutY=190
 width(page.about,460);spacing(page.about,3);anchor(page.about,'TOP',root,'TOPLEFT',center,-aboutY)
 local paragraph=page.about:GetStringHeight()
 local infoY=math.max(306,aboutY+(number(paragraph) and paragraph or 100)+14)
 width(page.info,460);spacing(page.info,4);anchor(page.info,'TOP',root,'TOPLEFT',center,-infoY)
 local detail=page.info:GetStringHeight()
 local buttonY=math.max(385,math.min(407,infoY+(number(detail) and detail or 35)+22))
 for i,button in ipairs(page.buttons or {})do
  if safe(button) then anchor(button,'CENTER',root,'TOPLEFT',center,-(buttonY+(i-1)*38))end
 end
end
local function checkTutorialHandoff(root)
 local tutorial=_G.ControllerForeverTutorial
 if checkedPanel==root or not tutorial or tutorial:IsShown() or not GetBindingAction then return end
 checkedPanel=root
 local cf=ControllerForever
 local before=GetBindingAction('PAD2',true)
 local cleared=false
 -- The hidden tutorial must relinquish its own override. The editor's
 -- native navigation then owns B, D-pad and every existing picker action.
 if public(before) and before=='CLICK ControllerForeverTutorialLeave:LeftButton' and cf and cf.Binds then
  cleared=cf.Binds:layer(tutorial).clear()==true
 end
 local after,down=GetBindingAction('PAD2',true),GetBindingAction('PADDDOWN',true)
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.keybindHandoff={version=VERSION,cleared=cleared,before=public(before) and before or nil,
  back=public(after) and after or nil,down=public(down) and down or nil}
end
local function readable(root,size)
 local count=0
 local function walk(f,depth)
  if depth>5 or count>=180 or not shown(f) or (f~=root and f==_G.ControllerForeverPicker) then return end
  count=count+1
  for _,r in ipairs({f:GetRegions()})do
   if safe(r) and r.IsObjectType and r:IsObjectType('FontString') then
    local face,n,flags=r:GetFont()
    local minimum=(r==root.hint or (root.detail and r==root.detail.mouseNote)) and 13 or ((root.crCombatSwitch and r==root.crCombatSwitch.label) and 12 or size)
    if public(face) and number(n) and public(flags) and type(face)=='string' and n<minimum then r:SetFont(face,minimum,flags)end
   end
  end
  for _,child in ipairs({f:GetChildren()})do walk(child,depth+1)end
 end
 walk(root,0)
end
local function nested(picker,sw,sh,parentScale)
 local box=shown(picker.editBox) and picker.editBox or (shown(picker.styleBox) and picker.styleBox)
 if not box then if modalShade then modalShade:Hide()end;releaseNested(picker);return end
 if not originals[box] then originals[box]={strata=box:GetFrameStrata()}end
 if box:GetFrameStrata()~='FULLSCREEN_DIALOG' then box:SetFrameStrata('FULLSCREEN_DIALOG')end
 -- These public native subpanels used the old side-by-side picker coordinates.
 -- Give their existing controls a centered readable surface; actions stay native.
 if box:GetWidth()~=620 then box:SetWidth(620)end
 local target=math.min(1.12,(sw-96)/620,(sh-120)/box:GetHeight())
 scale(box,target/parentScale);anchor(box,'CENTER',UIParent,'CENTER',0,0)
 for _,key in ipairs({'title','spell'})do font(box[key],18)end
 for _,key in ipairs({'count','slots'})do font(box[key],12)end
 for _,key in ipairs({'about','preview','hint'})do
  font(box[key],14)
  if safe(box[key]) and box[key]:GetWidth()~=592 then box[key]:SetWidth(592)end
 end
 for _,row in ipairs(box.rows or {})do
  if safe(row) and row:GetWidth()~=596 then row:SetWidth(596)end
  font(row.text,14);font(row.have,12)
 end
 if not modalShade then
  modalShade=CreateFrame('Frame','ForeverHandheldBindingModalShade',UIParent)
  modalShade:SetAllPoints(UIParent);modalShade:EnableMouse(false)
  local fill=modalShade:CreateTexture(nil,'BACKGROUND');fill:SetAllPoints(modalShade);fill:SetColorTexture(.025,.030,.025,1)
 end
 modalShade:SetFrameStrata(box:GetFrameStrata());modalShade:SetFrameLevel(math.max(0,box:GetFrameLevel()-1));modalShade:Show()
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.bindingSubpanel={version=VERSION,seen=GetTime(),kind=box==picker.editBox and 'macro-editor' or 'macro-style',width=620,scale=target,nativeActions=true}
end
local function update()
 if InCombatLockdown() then if shade then shade:Hide()end;if modalShade then modalShade:Hide()end;return end
 local root=_G.ControllerForeverShoulderSetup
 -- The native menu also embeds this editor. That host owns its geometry.
 local detail,picker=_G.ControllerForeverKeybindDetail,_G.ControllerForeverPicker
 if not shown(root) or root:GetParent()~=UIParent then checkedPanel=nil;if shade then shade:Hide()end;if modalShade then modalShade:Hide()end;restore(root,picker);return end
 checkTutorialHandoff(root)
 if not originals[root] then originals[root]={h=root:GetHeight()}end
 height(root,originals[root].h+40)
 local picking=shown(picker)
 local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
 local w,h=root:GetWidth(),root:GetHeight()
 if not (number(sw) and number(sh) and number(w) and number(h))then return end
 local extra=shown(detail) and detail:GetWidth()-8 or 0
 if not public(extra) or type(extra)~='number' then return end
 -- Reserve only the pane actually in use; native placement reserves the
 -- entire spell list even when only the narrow detail pane is visible.
 local total=w+math.max(0,extra)
 local s=math.min(1.12,(sw-64)/total,(sh-96)/h)
 if s<=0 then return end
 scale(root,s)
 anchor(root,'TOPLEFT',UIParent,'TOPLEFT',(sw-total*s)/2/s,-(sh-h*s)/2/s)
 readable(root,14)
 fitExtraBars(root)
 if safe(root.hint) then
  anchor(root.hint,'BOTTOM',root,'BOTTOM',0,12);font(root.hint,13);spacing(root.hint,3)
  local text=root.hint:GetText()
  if public(text) and type(text)=='string' then
   local compact=text:gsub('        ','   ')
   if compact~=text then root.hint:SetText(compact)end
  end
 end
 if safe(detail) and safe(detail.mouseNote) then anchor(detail.mouseNote,'TOPLEFT',detail,'TOPLEFT',26,-336);font(detail.mouseNote,13)end
 if root.crCombatSwitch then font(root.crCombatSwitch.label,12)end
 if picking then
  local pw,ph=picker:GetWidth(),picker:GetHeight()
  if not (number(pw) and number(ph))then return end
  local ps=math.min(1.12,(sw-80)/pw,(sh-80)/ph)
  scale(picker,ps/s)
  anchor(picker,'CENTER',UIParent,'CENTER',0,0)
  -- The native list has compact fixed-width tabs. Keep their labels fitted,
  -- and allow long spell/category names two lines instead of truncating them.
  for _,key in ipairs({'how','pageSub','count','pageKeys','moreCats','hint'})do font(picker[key],13)end
  font(picker.lbText,12);font(picker.rbText,12)
  if safe(picker.how) and picker.how:GetWidth()~=500 then picker.how:SetWidth(500)end
  if picker.searchBox then font(picker.searchBox.text,13)end
  for _,tab in ipairs(picker.groupTabs or {})do font(tab.label,12)end
  for _,row in ipairs(picker.catRows or {})do
   font(row.name,13);font(row.count,11)
   if safe(row.name) then row.name:SetWordWrap(true);height(row.name,32)end
  end
  for _,card in ipairs(picker.cards or {})do
   font(card.name,13);font(card.kind,11)
   if safe(card.name) then
    anchor(card.name,'TOPLEFT',card,'TOPLEFT',50,-4)
    card.name:SetWordWrap(true);height(card.name,30)
   end
   if safe(card.kind) then anchor(card.kind,'LEFT',card,'TOPLEFT',50,-41)end
  end
  if not originals[picker] then originals[picker]={strata=picker:GetFrameStrata()}end
  if picker:GetFrameStrata()~='DIALOG' then picker:SetFrameStrata('DIALOG')end
  if not shade then
   shade=CreateFrame('Frame','ForeverHandheldKeybindShade',UIParent)
   shade:SetAllPoints(UIParent);shade:EnableMouse(false)
   local bg=shade:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints(shade);bg:SetColorTexture(.025,.030,.025,.99)
  end
  shade:SetFrameStrata(picker:GetFrameStrata())
  shade:SetFrameLevel(math.max(0,picker:GetFrameLevel()-1));shade:Show()
  nested(picker,sw,sh,ps)
 else
  if modalShade then modalShade:Hide()end
  releaseNested(picker)
  if shade then shade:Hide()end
  local old=picker and originals[picker]
  if old and safe(picker) then picker:SetFrameStrata(old.strata);originals[picker]=nil end
 end
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.keybindWorkspace={version=VERSION,seen=GetTime(),mode=picking and 'picker' or 'controller',scale=s,width=total,height=h,nativeActions=true}
end
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0
 local ok,err=pcall(update)
 if not ok then
  if modalShade then modalShade:Hide()end
  if shade then shade:Hide()end
  ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.keybindWorkspaceError=tostring(err)
 end
end)
