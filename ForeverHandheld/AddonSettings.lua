-- Readable AceGUI option pages inside the native Settings window.
-- Widgets retain their values, callbacks, disabled state, tooltip and navigation.
-- Styling is restored when AceGUI returns a widget to its shared pool.
local VERSION='3.7.36'
local driver=CreateFrame('Frame')
local records=setmetatable({},{__mode='k'})
local hooked
local needsNavigationRefresh=false
local gearLastPage,gearLastWidth
local function shown(f)return f and f.IsVisible and f:IsVisible()end
local function remember(widget)
 local r=records[widget]
 if not r then r={fonts={},heights={},textures={},points={}};records[widget]=r end
 return r
end
local function font(widget,region,size)
 if not region or not region.GetFont then return false end
 local face,old,flags=region:GetFont()
 if not face or old>=size then return false end
 local r=remember(widget)
 if not r.fonts[region] then r.fonts[region]={face,old,flags}end
 region:SetFont(face,size,flags)
 return true
end
local function restore(widget)
 if ForeverHandheldColorEditorRelease then ForeverHandheldColorEditorRelease(widget)end
 local r=records[widget];if not r then return end
 for region,old in pairs(r.fonts)do region:SetFont(unpack(old))end
 for region,old in pairs(r.heights)do region:SetHeight(old)end
 for region,old in pairs(r.textures)do region:SetDesaturated(old.desaturated);region:SetVertexColor(unpack(old.color))end
 for region,old in pairs(r.points)do region:ClearAllPoints();for _,point in ipairs(old)do region:SetPoint(unpack(point))end end
 if r.backdrop then
  widget.frame:SetBackdropColor(unpack(r.backdrop.color))
  widget.frame:SetBackdropBorderColor(unpack(r.backdrop.border))
 end
 records[widget]=nil
end
local function buttonTheme(widget,button)
 if not button or not button.GetNormalTexture then return false end
 local changed=false
 local candidates={button:GetNormalTexture(),button.GetPushedTexture and button:GetPushedTexture(),button.Left,button.Middle,button.Center,button.Right}
 if button.GetRegions then
  for _,region in ipairs({button:GetRegions()})do
   local atlas=region.GetAtlas and region:GetAtlas()
   if type(atlas)=='string' and atlas:lower():find('redbutton',1,true) and region:GetDrawLayer()~='HIGHLIGHT' then
    candidates[#candidates+1]=region
   end
  end
 end
 for _,t in pairs(candidates)do
  if t and t.GetVertexColor and t.IsDesaturated then
   local r=remember(widget)
   if not r.textures[t] then r.textures[t]={desaturated=t:IsDesaturated(),color={t:GetVertexColor()}};changed=true end
   t:SetDesaturated(true);t:SetVertexColor(.50,.48,.38,1)
  end
 end
 return changed
end
local function style(widget)
 if not widget or not widget.frame or not shown(widget.frame) then return false end
 local changed=false
 local function bigger(region,size)if font(widget,region,size)then changed=true end end
 local function taller(region,height)
  if region and region.GetHeight and region:GetHeight()<height then
   remember(widget).heights[region]=region:GetHeight();region:SetHeight(height);changed=true
  end
 end
 local kind=widget.type
 if kind=='Button' or kind=='Keybinding' then
  if buttonTheme(widget,kind=='Keybinding' and widget.button or widget.frame)then changed=true end
 end
 if kind=='CheckBox' then
  bigger(widget.text,17)
  if widget.width~='fill' then widget:SetFullWidth(true);changed=true end
  local labelHeight=24
  if widget.text then
   local r=remember(widget);local t=widget.text
   local width=t:GetWidth();local text=t.GetText and t:GetText()
   if r.labelWidth~=width or r.labelText~=text or not r.labelHeight then
    if not r.heights[t] then r.heights[t]=t:GetHeight()end
    t:SetHeight(0);labelHeight=math.max(24,t:GetStringHeight()+2);t:SetHeight(labelHeight)
    r.labelWidth=width;r.labelText=text;r.labelHeight=labelHeight;changed=true
   else labelHeight=r.labelHeight end
   if widget.checkbg and t.GetNumPoints and not r.points[t] then
    r.points[t]={};for i=1,t:GetNumPoints()do r.points[t][i]={t:GetPoint(i)}end
    t:ClearAllPoints();t:SetPoint('TOPLEFT',widget.checkbg,'TOPRIGHT',0,-3);t:SetPoint('RIGHT',widget.frame,'RIGHT',0,0)
    changed=true
   end
   if widget.desc and widget.desc.GetNumPoints and not r.points[widget.desc] then
    local d=widget.desc;r.points[d]={};for i=1,d:GetNumPoints()do r.points[d][i]={d:GetPoint(i)}end
    d:ClearAllPoints();d:SetPoint('TOPLEFT',t,'BOTTOMLEFT',0,-4);d:SetPoint('RIGHT',widget.frame,'RIGHT',-30,0)
    changed=true
   end
  end
  local extra=widget.desc and shown(widget.desc) and widget.desc:GetStringHeight() or 0
  if widget.frame:GetHeight()<labelHeight+10+extra then widget:SetHeight(labelHeight+10+extra);changed=true end
 elseif kind=='Slider' then
  bigger(widget.label,16);bigger(widget.lowtext,13);bigger(widget.hightext,13);bigger(widget.editbox,16)
  taller(widget.label,22);taller(widget.editbox,22)
  if widget.width~='fill' then widget:SetFullWidth(true);changed=true end
  if widget.frame:GetHeight()<60 then widget:SetHeight(60);changed=true end
 elseif kind=='Keybinding' then
  bigger(widget.label,16)
  if widget.button and widget.button.GetFontString then bigger(widget.button:GetFontString(),16)end
  taller(widget.label,22);taller(widget.button,30)
  if widget.width~='fill' then widget:SetFullWidth(true);changed=true end
  if widget.frame:GetHeight()<56 then widget:SetHeight(56);changed=true end
 elseif kind=='RS_Markers' or kind=='LSM30_Sound' then
  bigger(widget.frame.label,16);bigger(widget.frame.text,16)
  taller(widget.frame.label,22);taller(widget.frame.text,22)
  if widget.width~='fill' then widget:SetFullWidth(true);changed=true end
  if widget.frame:GetHeight()<56 then widget:SetHeight(56);changed=true end
 elseif kind=='Dropdown' or kind=='EditBox' or kind=='MultiLineEditBox' then
  bigger(widget.label,16);bigger(widget.text,16);bigger(widget.editbox,16)
  if kind=='EditBox' then
   taller(widget.label,22);taller(widget.editbox,24)
   if widget.frame:GetHeight()<56 then widget:SetHeight(56);changed=true end
  end
  if widget.width~='fill' then widget:SetFullWidth(true);changed=true end
 elseif kind=='Button' then
  bigger(widget.text,14)
  if widget.frame:GetWidth()<200 then widget:SetWidth(200);changed=true end
  if widget.frame:GetHeight()<30 then widget:SetHeight(30);changed=true end
 elseif kind=='ColorPicker' then
  if ForeverHandheldColorEditorInstall then ForeverHandheldColorEditorInstall(widget)end
  bigger(widget.text,16)
  if widget.width~='fill' then widget:SetFullWidth(true);changed=true end
  if widget.frame:GetHeight()<30 then widget:SetHeight(30);changed=true end
 elseif kind=='Heading' or kind=='Label' then
  bigger(widget.label,kind=='Heading' and 17 or 16)
 elseif kind=='TreeGroup' then
  -- AceGUI's native rows are 18px high. Keep its scroll/selection arithmetic
  -- and row hit targets intact; enlarge text within that native row height.
  for _,button in ipairs(widget.buttons or {})do
   if shown(button) then bigger(button.text,16)end
  end
  local status=widget.status or widget.localstatus
  local width=widget.frame:GetWidth()
  local desired=math.min(225,math.max(175,width*.34))
  if widget.GetTreeWidth and widget.SetTreeWidth and widget:GetTreeWidth()<desired then
   widget:SetTreeWidth(desired,status and status.treesizable);changed=true
  end
 elseif kind=='TabGroup' then
  local tabsChanged=false
  for _,tab in ipairs(widget.tabs or {})do
   if font(widget,tab.Text or tab.text,15)then tabsChanged=true end
  end
  if tabsChanged then widget:BuildTabs();changed=true end
 end
 for _,child in ipairs(widget.children or {})do if style(child)then changed=true end end
 local pullout=kind=='Dropdown' and widget.pullout
 if pullout and shown(pullout.frame) then
  -- The pullout is parented to UIParent, outside the option-page tree.
  -- Keep its native 16px row spacing and selection/scroll handlers intact.
  for _,item in ipairs(pullout.items or {})do
   if shown(item.frame)then font(item,item.text,15)end
  end
  local f=pullout.frame
  if f.GetBackdropColor and f.GetBackdropBorderColor then
   local r=remember(pullout)
   if not r.backdrop then r.backdrop={color={f:GetBackdropColor()},border={f:GetBackdropBorderColor()}}end
   f:SetBackdropColor(.025,.030,.025,1);f:SetBackdropBorderColor(.68,.56,.36,1)
  end
 end
 if changed and widget.DoLayout then widget:DoLayout()end
 return changed
end
local gearPages=setmetatable({},{__mode='k'})
local function place(f,relative,x,y)
 local a,b,c,px,py=f:GetPoint(1)
 if a~='TOPLEFT' or b~=relative or c~='TOPLEFT' or px~=x or py~=y then
  f:ClearAllPoints();f:SetPoint('TOPLEFT',relative,'TOPLEFT',x,y)
 end
end
local function autoGear()
 local container=AutoGearOptionsTabContainer
 if not shown(container) then return end
 local width=container:GetWidth()
 for _,page in ipairs({container:GetChildren()})do
  if page.lastRow and shown(page) then
   if gearLastPage~=page or gearLastWidth~=width then needsNavigationRefresh=true;gearLastPage=page;gearLastWidth=width end
   local rows=gearPages[page]
   if not rows then
    rows={};local row=page.lastRow;local seen={}
    while row and row~=page and not seen[row] do
     seen[row]=true;table.insert(rows,1,row)
     local _,relative=row:GetPoint(1);row=relative
    end
    gearPages[page]=rows
   end
   local y=14
   for _,row in ipairs(rows)do
    place(row,page,14,-y)
    if row:IsObjectType('CheckButton') then
     row:SetSize(28,28)
     font(page,row.label,17)
     if row.label then row.label:SetWidth(math.max(100,width-65));row.label:SetWordWrap(true);row.label:SetJustifyH('LEFT')end
     y=y+math.max(36,row.label and row.label:GetStringHeight()+12 or 36)
     local child=row.dropDown or row.editBox
     if child then
      place(child,page,46,-y);child:SetWidth(math.max(100,width-68))
      if child.GetFontString then font(page,child:GetFontString(),16)end
      if child.GetFont then font(page,child,16)end
      y=y+math.max(30,child:GetHeight())+12
     end
    elseif row:IsObjectType('Button') then
     if row.GetFontString then font(page,row:GetFontString(),17)end
     row:SetSize(180,34);y=y+46
    else
     for _,region in ipairs({row:GetRegions()})do
      if region.IsObjectType and region:IsObjectType('FontString')then font(page,region,17)end
     end
     row:SetHeight(26);y=y+38
    end
   end
   -- AutoGear owns page switching and reads this height when a tab is chosen.
   -- Keep its layout metadata consistent with the taller native controls.
   page.height=y
   container:SetHeight(y+12)
   if AutoGearOptionsMenu then AutoGearOptionsMenu:SetHeight(72+y+12+16)end
  end
 end
 local x=6
 for i=1,12 do
  local tab=_G['AutoGearOptionsTabContainerTab'..i];if not tab then break end
  local label=tab:GetFontString();font(container,label,15)
  local textWidth=label.GetUnboundedStringWidth and label:GetUnboundedStringWidth() or label:GetStringWidth()
  label:SetWidth(textWidth+4)
  local w=math.max(82,textWidth+28)
  if tab:GetWidth()~=w then tab:SetWidth(w)end
  local a,b,c,px,py=tab:GetPoint(1)
  if a~='BOTTOMLEFT' or b~=container or c~='TOPLEFT' or px~=x or py~=-2 then
   tab:ClearAllPoints();tab:SetPoint('BOTTOMLEFT',container,'TOPLEFT',x,-2)
  end
  x=x+w-4
 end
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.addonSettingsCoverage=ForeverHandheldDB.addonSettingsCoverage or {}
 ForeverHandheldDB.addonSettingsCoverage.AutoGear={version=VERSION,seen=GetTime()}
end
local function refreshNavigation()
 if not needsNavigationRefresh or InCombatLockdown() then return end
 local nav=SmartNavigation
 if not nav or not nav.RefreshButtonGroups or not nav.activeInfo or nav.activeInfo.frame~=SettingsPanel then return end
 -- Public wrapped API: rebuild the native list after an addon creates/reflows
 -- controls. Do not write native focus tables or replace its input callbacks.
 nav:RefreshButtonGroups(SettingsPanel)
 needsNavigationRefresh=false
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.addonSettingsNavigationRefresh={version=VERSION,at=GetTime()}
end
local function questieControl(control)
 local item=control.itemData or {}
 font(control,control.titleFrame,17)
 font(control,control.descriptionFrame,14)
 if item.type=='text' and control.descriptionFrame and control.titleFrame then
  -- Questie's 30px label wrapper can overflow a shorter description-only row.
  place(control.titleFrame,control,0,0)
  control:SetHeight(math.max(control:GetHeight(),control.titleFrame:GetStringHeight()+control.descriptionFrame:GetStringHeight()+6))
 end
 local widget=control.widget
 if not widget then return end
 if item.type=='button' then
  buttonTheme(control,widget)
 elseif item.type=='colorPicker' then
  if ForeverHandheldColorEditorInstallQuestie then ForeverHandheldColorEditorInstallQuestie(control)end
 elseif item.type=='slider' then
  font(control,widget.Text,17);font(control,widget.Low,13);font(control,widget.High,13)
  font(control,control.valueDisplay,16)
  local titleHeight=17
  if widget.Text then
   widget.Text:SetWidth(widget:GetWidth());widget.Text:SetWordWrap(true)
   titleHeight=math.max(titleHeight,widget.Text:GetStringHeight())
  end
  place(widget,control,15,-titleHeight-8)
  control:SetHeight(math.max(control:GetHeight(),titleHeight+widget:GetHeight()+34))
 elseif item.type=='dropdown' or item.type=='fontDropdown' or item.type=='textbox' then
  if widget.GetFontString then font(control,widget:GetFontString(),16)end
  if item.type=='textbox' then font(control,widget,16)end
  local titleHeight=17
  if control.titleFrame then
   control.titleFrame:SetWidth(widget:GetWidth()-12);control.titleFrame:SetWordWrap(true)
   titleHeight=math.max(titleHeight,control.titleFrame:GetStringHeight())
  end
  place(widget,control,item.type=='textbox' and 16 or 10,-titleHeight-6)
  control:SetHeight(math.max(control:GetHeight(),titleHeight+widget:GetHeight()+12))
 end
end
local questieLayout
local function installQuestieLayout()
 if questieLayout or not QuestieLoader then return end
 local layout=QuestieLoader:ImportModule('QuestieOptionsLayout')
 if not layout or type(layout.Build)~='function' then return end
 local original=layout.Build
 layout.Build=function(parent,items,width,level,onCreated)
  -- Questie's native builder measures wrapping and scroll height itself.
  -- Copy presentation fields only; preserve original preferences and callbacks.
  local readable={}
  for key,item in pairs(items)do
   local copy={};for k,v in pairs(item)do copy[k]=v end
   copy.width=1
   copy.titleSize=math.max(17,tonumber(copy.titleSize) or 0)
   copy.descriptionSize=math.max(14,tonumber(copy.descriptionSize) or 0)
   readable[key]=copy
  end
  -- Keep this call yieldable: Questie builds its pages over several frames.
  local height=original(parent,readable,width,level,function(control)
   questieControl(control)
   onCreated(control)
  end)
  needsNavigationRefresh=true
  ForeverHandheldDB=ForeverHandheldDB or {}
  ForeverHandheldDB.addonSettingsCoverage=ForeverHandheldDB.addonSettingsCoverage or {}
  ForeverHandheldDB.addonSettingsCoverage.Questie={version=VERSION,seen=GetTime()}
  return height
 end
 questieLayout=layout
end
local function update()
 installQuestieLayout()
 if InCombatLockdown() or not shown(SettingsPanel) then return end
 autoGear()
 if not LibStub then refreshNavigation();return end
 local gui=LibStub('AceGUI-3.0',true)
 local dialog=LibStub('AceConfigDialog-3.0',true)
 if not gui or not dialog then refreshNavigation();return end
 if hooked~=gui then
  hooksecurefunc(gui,'Release',function(_,widget)restore(widget)end);hooked=gui
 end
 for app,groups in pairs(dialog.BlizOptions or {})do
  for _,widget in pairs(groups)do
   if shown(widget.frame) then
    if style(widget)then needsNavigationRefresh=true end
    ForeverHandheldDB=ForeverHandheldDB or {}
    ForeverHandheldDB.addonSettingsCoverage=ForeverHandheldDB.addonSettingsCoverage or {}
    ForeverHandheldDB.addonSettingsCoverage[app]={version=VERSION,seen=GetTime()}
   end
  end
 end
 refreshNavigation()
end
local elapsed=0
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.5 then return end;elapsed=0
 local ok,err=pcall(update)
 if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.addonSettingsError=tostring(err)end
end)
