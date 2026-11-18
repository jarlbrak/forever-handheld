-- Read long tutorial explanations in unused chapter-column space.
-- Native rows, settings, focus, bindings and geometry remain owned by CF.
local VERSION='3.7.112'
local driver=CreateFrame('Frame','ForeverHandheldTutorialDetailsDriver')
local elapsed,panel,measure,cover=0,nil,nil,nil
local measuredKey,measuredHeight
local header,headerMeasure
local layoutHint
local function hideHeader()if header then header:Hide()end end
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function readable(f)return f and not (f.IsForbidden and f:IsForbidden())end
local function number(v)return public(v) and type(v)=='number' and v==v and v>0 end
local function restore()
 if cover then cover:Hide()end
 if panel then panel:Hide()end
end
local function updateLayoutHint(root,desc,text,face)
 local step=root.rowsStep
 local dock=_G.ForeverHandheldDock
 if not (step and step.title=='Your Layout' and readable(dock) and dock:IsShown() and
  public(text) and type(text)=='string' and text:find('your buttons below change at once',1,true) and
  public(face) and type(face)=='string') then
  if layoutHint then layoutHint:Hide()end
  return
 end
 if not layoutHint then
  local f=CreateFrame('Frame','ForeverHandheldTutorialLayoutHint',root)
  f.ForeverHandheldOwnedPresentation=true;f:EnableMouse(false);f:SetAllPoints(desc)
  local bg=f:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints(f);bg:SetColorTexture(.06,.06,.06,1)
  local label=f:CreateFontString(nil,'OVERLAY');label:SetAllPoints(f)
  label:SetFont(face,16,'');label:SetJustifyH('LEFT');label:SetJustifyV('MIDDLE')
  label:SetTextColor(.88,.88,.84)
  label:SetText('Left / right picks a Controller Forever layout. Your handheld dock keeps all four action sets visible.')
  layoutHint=f
 end
 local level=root.info:GetFrameLevel()+2
 if layoutHint:GetFrameLevel()~=level then layoutHint:SetFrameLevel(level)end
 layoutHint:Show()
end
-- Keep the native title and progress state intact. Only replace a cramped
-- title's paint, with the exact text at a measured size inside its old bounds.
local function updateHeader(root)
 local title=root and root.head
 local segment=root and root.segments and root.segments[1]
 if not readable(root) or not root:IsShown() or not readable(title) or not title:IsShown() or not readable(segment) or not segment:IsShown() then hideHeader();return end
 local rs,ts,ss=root:GetEffectiveScale(),title:GetEffectiveScale(),segment:GetEffectiveScale()
 local left,top,w,h=title:GetLeft(),title:GetTop(),title:GetWidth(),title:GetHeight()
 local edge=segment:GetLeft()
 if not number(rs) or not number(ts) or not number(ss) or not number(left) or not number(top) or not number(w) or not number(h) or not number(edge) then hideHeader();return end
 local gap=(edge*ss-(left+w)*ts)/rs
 -- Do not cover another native region if a future version truly overlaps it.
 if gap<0 or gap>=20 then hideHeader();return end
 local text=title:GetText();local face,size,flags=title:GetFont()
 local red,green,blue,alpha=title:GetTextColor()
 for _,v in ipairs({red,green,blue,alpha})do if not public(v) or type(v)~='number' then hideHeader();return end end
 if not public(text) or type(text)~='string' or not public(face) or type(face)~='string' or not number(size) then hideHeader();return end
 local rootLeft,rootTop=root:GetLeft(),root:GetTop()
 if not number(rootLeft) or not number(rootTop) then hideHeader();return end
 local width,height=w*ts/rs,h*ts/rs
 local x,y=(left*ts-rootLeft*rs)/rs,(top*ts-rootTop*rs)/rs
 if x<0 or x+width>root:GetWidth() or y>0 then hideHeader();return end
 local fontSize=math.min(size*ts/rs,18)
 local key=text..'|'..face..'|'..tostring(flags)..'|'..width..'|'..fontSize
 if not headerMeasure then headerMeasure=UIParent:CreateFontString(nil,'OVERLAY');headerMeasure:Hide();headerMeasure:SetWordWrap(false)end
 if headerMeasure.signature~=key then
  headerMeasure:SetFont(face,fontSize,public(flags) and flags or '');headerMeasure:SetText(text)
  headerMeasure.measuredWidth=headerMeasure:GetStringWidth();headerMeasure.signature=key
 end
 if not number(headerMeasure.measuredWidth) or headerMeasure.measuredWidth>width-20 then hideHeader();return end
 if not header then
  header=CreateFrame('Frame','ForeverHandheldTutorialHeader',root)
  header.ForeverHandheldOwnedPresentation=true;header:EnableMouse(false)
  local bg=header:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints(header);bg:SetColorTexture(.06,.06,.06,1)
  header.text=header:CreateFontString(nil,'OVERLAY');header.text:SetPoint('LEFT',0,0);header.text:SetJustifyH('LEFT');header.text:SetJustifyV('MIDDLE');header.text:SetWordWrap(false)
 end
 local signature=key..'|'..height..'|'..x..'|'..y..'|'..red..'|'..green..'|'..blue..'|'..alpha
 if header.signature~=signature then
  header:ClearAllPoints();header:SetPoint('TOPLEFT',root,'TOPLEFT',x,y+1);header:SetSize(width,height+2)
  header.text:SetFont(face,fontSize,public(flags) and flags or '');header.text:SetTextColor(red,green,blue,alpha);header.text:SetText(text);header.signature=signature
 end
 local level=root:GetFrameLevel()+3
 if header:GetFrameLevel()~=level then header:SetFrameLevel(level)end
 header:Show()
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.tutorialHeader={version=VERSION,seen=GetTime(),nativeGap=gap,font=fontSize,gap=width-headerMeasure.measuredWidth+gap,nativeActions=true}
end
local function update()
 if InCombatLockdown() then return end
 local root=_G.ControllerForeverTutorial
 updateHeader(root)
 local info=root and root.info;local desc=root and root.desc
 if not readable(root) or not root:IsShown() or not readable(info) or not info:IsShown() or not readable(desc) then
  restore();if layoutHint then layoutHint:Hide()end;return
 end
 local text=desc:GetText();local face,size,flags=desc:GetFont()
 updateLayoutHint(root,desc,text,face)
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.tutorialDetailsProbe={font=public(size) and size or nil,chapters=#(root.chapters or {}),version=VERSION}
 if not public(text) or type(text)~='string' or text=='' or not public(face) or type(face)~='string' or not number(size) or size>=16 then restore();return end
 local es=root:GetEffectiveScale();local top=root:GetTop();local rh=root:GetHeight();local left=root:GetLeft()
 if not number(es) or not number(top) or not number(rh) or not number(left) then restore();return end
 local bottom,width,x=0,nil,nil
 for _,card in ipairs(root.chapters or {})do
  if readable(card) and card:IsShown() then
   local cb,ce,cw,cl=card:GetBottom(),card:GetEffectiveScale(),card:GetWidth(),card:GetLeft()
   if not number(cb) or not number(ce) or not number(cw) or not number(cl) then restore();return end
   bottom=math.max(bottom,(top*es-cb*ce)/es)
   width=math.min(width or cw*ce/es,cw*ce/es)
   x=(cl*ce-left*es)/es
  end
 end
 -- Slim/docked pages have no chapter column: keep their native explanation.
 if not width or width<180 or not x or x<0 or x+width>root:GetWidth()*.45 then restore();return end
 local y=bottom+18;local available=rh-y-24
 ForeverHandheldDB.tutorialDetailsProbe.width=width;ForeverHandheldDB.tutorialDetailsProbe.available=available
 if available<70 then restore();return end
 if not measure then
  measure=UIParent:CreateFontString(nil,'OVERLAY');measure:Hide()
  measure:SetWordWrap(true);measure:SetSpacing(2)
 end
 local signature=face..'|'..(public(flags) and flags or '')..'|'..text..'|'..width
 if measuredKey~=signature then
  measure:SetFont(face,16,public(flags) and flags or '')
  measure:SetWidth(width-28);measure:SetText(text)
  measuredHeight=measure:GetStringHeight()+46;measuredKey=signature
 end
 local height=measuredHeight
 ForeverHandheldDB.tutorialDetailsProbe.height=height
 if not number(height) or height>available then restore();return end
 if not panel then
  panel=CreateFrame('Frame','ForeverHandheldTutorialDetails',root)
  panel.ForeverHandheldOwnedPresentation=true;panel:EnableMouse(false)
  local bg=panel:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints(panel);bg:SetColorTexture(.025,.030,.025,.98)
  for _,side in ipairs({'TOP','BOTTOM','LEFT','RIGHT'})do
   local edge=panel:CreateTexture(nil,'BORDER');edge:SetColorTexture(.68,.56,.36,.8)
   if side=='TOP' or side=='BOTTOM' then edge:SetHeight(1);edge:SetPoint(side..'LEFT');edge:SetPoint(side..'RIGHT')
   else edge:SetWidth(1);edge:SetPoint('TOP'..side);edge:SetPoint('BOTTOM'..side)end
  end
  panel.title=panel:CreateFontString(nil,'OVERLAY');panel.title:SetFont(face,12,'');panel.title:SetPoint('TOPLEFT',14,-10);panel.title:SetTextColor(.87,.74,.48);panel.title:SetText('DETAILS')
  panel.text=panel:CreateFontString(nil,'OVERLAY');panel.text:SetFont(face,16,public(flags) and flags or '');panel.text:SetPoint('TOPLEFT',14,-30);panel.text:SetTextColor(.88,.88,.84);panel.text:SetJustifyH('LEFT');panel.text:SetJustifyV('TOP');panel.text:SetWordWrap(true);panel.text:SetSpacing(2)
 end
 if panel:GetParent()~=root then panel:SetParent(root)end
 local a,b,c,d,e=panel:GetPoint(1)
 if a~='TOPLEFT' or b~=root or c~='TOPLEFT' or d~=x or e~=-y then panel:ClearAllPoints();panel:SetPoint('TOPLEFT',root,'TOPLEFT',x,-y)end
 if panel:GetWidth()~=width or panel:GetHeight()~=height then panel:SetSize(width,height)end

 if panel.signature~=signature then
  panel.title:SetFont(face,12,'');panel.text:SetFont(face,16,public(flags) and flags or '')
  panel.text:SetWidth(width-28);panel.text:SetHeight(height-40);panel.text:SetText(text);panel.signature=signature
 end
 -- Mask only the old presentation with an owned noninteractive surface.
 -- Never alter the native protected info frame, font, alpha or handlers.
 if not cover then
  cover=CreateFrame('Frame','ForeverHandheldTutorialDetailsMask',root)
  cover.ForeverHandheldOwnedPresentation=true;cover:EnableMouse(false)
  local bg=cover:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints(cover);bg:SetColorTexture(.06,.06,.06,1)
 end
 if cover.owner~=info then cover:ClearAllPoints();cover:SetAllPoints(info);cover.owner=info end
 local level=info:GetFrameLevel()+1
 if cover:GetFrameLevel()~=level then cover:SetFrameLevel(level)end
 cover:Show()
 panel:Show()
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.tutorialDetailsError=nil
 ForeverHandheldDB.tutorialDetails={version=VERSION,seen=GetTime(),font=16,width=width,height=height,nativeActions=true}
end
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.15 then return end;elapsed=0
 local ok,err=pcall(update)
 if not ok then restore();hideHeader();if layoutHint then layoutHint:Hide()end;ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.tutorialDetailsError=tostring(err);ForeverHandheldDB.tutorialDetailsLastError={version=VERSION,seen=GetTime(),message=tostring(err)}end
end)
