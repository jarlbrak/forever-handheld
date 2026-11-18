-- Addon-owned color editing avoids the native color picker's callback-driven
-- binding footer, which taints the Forever client controller stack.
-- Only Apply calls the original AceGUI value callback. B/Escape/release cancel.
local VERSION='3.7.36'
local editor,owner,draft,original
local pendingNavigationClose
local installed=setmetatable({},{__mode='k'})
local gold={.72,.60,.39,1}
local function label(parent,text,x,y,size)
 local t=parent:CreateFontString(nil,'OVERLAY')
 t:SetFont(STANDARD_TEXT_FONT,size,'');t:SetPoint('TOPLEFT',x,-y)
 t:SetTextColor(unpack(gold));t:SetText(text);return t
end
local function fill(parent,x,y,w,h,r,g,b,a)
 local t=parent:CreateTexture(nil,'BACKGROUND');t:SetPoint('TOPLEFT',x,-y)
 t:SetSize(w,h);t:SetColorTexture(r,g,b,a);return t
end
local function close()if editor then editor:Hide()end end
local function leaveNavigation(frame)
 -- Public navigation wrappers reject addon calls during combat restrictions.
 -- Discard the draft immediately; defer only the registration cleanup.
 if InCombatLockdown() then pendingNavigationClose=frame;return end
 pendingNavigationClose=nil
 if GamepadMode and GamepadMode.FrameControlsManager then GamepadMode.FrameControlsManager:FrameHidden(frame)end
end
local function scale(index)return index==4 and 100 or 255 end
local function refresh()
 if not editor or not draft then return end
 editor.preview:SetColorTexture(unpack(draft))
 editor.hex:SetText(string.format('#%02X%02X%02X',math.floor(draft[1]*255+.5),math.floor(draft[2]*255+.5),math.floor(draft[3]*255+.5)))
 for i,row in ipairs(editor.rows)do
  row.value:SetText(tostring(math.floor(draft[i]*scale(i)+.5))..(i==4 and '%' or ''))
  row.slider:SetValue(draft[i]*scale(i))
 end
end
local function adjust(index,value)
 if not draft then return end
 local limit=scale(index)
 value=math.max(0,math.min(limit,value))
 -- Returning to the original displayed step preserves its exact stored value.
 draft[index]=(original and value==math.floor(original[index]*limit+.5)) and original[index] or value/limit
 refresh()
end
local function apply()
 local widget,values,old=owner,draft,original
 close()
 if not widget or widget.disabled or InCombatLockdown() or not widget.frame:IsVisible() or (widget.IsValid and not widget:IsValid()) then return end
 local changed=false;for i=1,4 do if values[i]~=old[i] then changed=true end end
 if changed then
  widget:SetColor(unpack(values))
  widget:Fire('OnValueConfirmed',unpack(values))
 end
end
local function button(parent,text,x,y,w,callback)
 local b=CreateFrame('Button',nil,parent,'BackdropTemplate');b:SetPoint('TOPLEFT',x,-y);b:SetSize(w,32)
 b:SetBackdrop({bgFile='Interface/Buttons/WHITE8X8',edgeFile='Interface/Buttons/WHITE8X8',edgeSize=1})
 b:SetBackdropColor(.045,.052,.045,1);b:SetBackdropBorderColor(unpack(gold))
 local t=b:CreateFontString(nil,'OVERLAY');t:SetFont(STANDARD_TEXT_FONT,17,'');t:SetPoint('CENTER');t:SetTextColor(.94,.90,.80,1);t:SetText(text)
 b:SetHighlightTexture('Interface/Buttons/WHITE8X8');b:GetHighlightTexture():SetVertexColor(.72,.60,.39,.2)
 b:SetScript('OnClick',callback);return b
end
local function make()
 local f=CreateFrame('Frame','ForeverHandheldColorEditor',SettingsPanel,'BackdropTemplate')
 f:Hide();f:SetSize(540,426);f:SetPoint('CENTER',UIParent,'CENTER',0,0);f:SetFrameStrata('FULLSCREEN_DIALOG')
 f:SetFrameLevel(SettingsPanel:GetFrameLevel()+40);f:EnableMouse(true)
 f:SetBackdrop({bgFile='Interface/Buttons/WHITE8X8',edgeFile='Interface/Buttons/WHITE8X8',edgeSize=1})
 f:SetBackdropColor(.025,.030,.025,1);f:SetBackdropBorderColor(unpack(gold))
 label(f,'F O R E V E R  /  A P P E A R A N C E',22,16,11)
 f.title=label(f,'Color',22,38,24);f.title:SetWidth(490)
 fill(f,22,76,496,1,unpack(gold))
 label(f,'CURRENT',22,88,11);label(f,'PREVIEW',280,88,11)
 f.before=fill(f,22,108,236,38,1,1,1,1);f.preview=fill(f,280,108,238,38,1,1,1,1)
 -- Data swatches must render above BackdropTemplate's background texture.
 f.before:SetDrawLayer('ARTWORK');f.preview:SetDrawLayer('ARTWORK')
 f.hex=label(f,'',280,152,15)
 f.rows={}
 for i,name in ipairs({'Red','Green','Blue','Opacity'})do
  local y=182+(i-1)*42
  local row={};f.rows[i]=row
  row.label=label(f,name,22,y+7,16)
  row.minus=button(f,'−',102,y,36,function()if draft then adjust(i,math.floor(draft[i]*scale(i)+.5)-1)end end)
  row.plus=button(f,'+',422,y,36,function()if draft then adjust(i,math.floor(draft[i]*scale(i)+.5)+1)end end)
  row.value=label(f,'',474,y+7,16)
  local s=CreateFrame('Slider',nil,f,'OptionsSliderTemplate');row.slider=s
  s:SetPoint('TOPLEFT',152,-y-7);s:SetSize(254,18);s:SetMinMaxValues(0,scale(i));s:SetValueStep(1);s:SetObeyStepOnDrag(true)
  for _,part in ipairs({'Text','Low','High'})do if s[part] then s[part]:Hide()end end
  s:SetScript('OnValueChanged',function(_,v)
   if draft and math.abs(draft[i]*scale(i)-v)>.01 then adjust(i,math.floor(v+.5))end
  end)
 end
 f.apply=button(f,'Apply',280,358,112,apply)
 f.cancel=button(f,'Cancel',406,358,112,close)
 label(f,'D-pad  Navigate     A  Select     B  Cancel',22,402,14)
 f.SmartNavigationCloseHandler=function()close();return true end
 f:EnableKeyboard(true)
 f:SetScript('OnKeyDown',function(self,key)
  if InCombatLockdown() then close();return end
  self:SetPropagateKeyboardInput(key~='ESCAPE')
  if key=='ESCAPE' then close()end
 end)
 f:RegisterEvent('PLAYER_REGEN_DISABLED')
 f:RegisterEvent('PLAYER_REGEN_ENABLED')
 f:SetScript('OnEvent',function(_,event)
  if event=='PLAYER_REGEN_DISABLED' then close()
  elseif pendingNavigationClose then leaveNavigation(pendingNavigationClose)end
 end)
 f:SetScript('OnShow',function(self)
  if GamepadMode and GamepadMode.FrameControlsManager then GamepadMode.FrameControlsManager:FrameShown(self,true)end
 end)
 f:SetScript('OnHide',function(self)
  owner=nil;draft=nil;original=nil
  leaveNavigation(self)
 end)
 table.insert(UISpecialFrames,'ForeverHandheldColorEditor')
 return f
end
local function open(widget)
 if widget.disabled or InCombatLockdown() or (widget.IsValid and not widget:IsValid()) then return end
 if pendingNavigationClose then leaveNavigation(pendingNavigationClose)end
 if not editor then editor=make()end
 close()
 owner=widget;original={widget.r,widget.g,widget.b,widget.HasAlpha and (widget.a or 1) or 1};draft={unpack(original)}
 editor.title:SetText(widget.text:GetText() or 'Color')
 editor.before:SetColorTexture(unpack(original))
 for _,part in pairs(editor.rows[4])do part:SetShown(not not widget.HasAlpha)end
 if GameTooltip then GameTooltip:Hide()end
 refresh();editor:Show()
 ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.colorEditor={version=VERSION,opened=GetTime()}
end
ForeverHandheldColorEditorInstall=function(widget)
 if installed[widget] then return end
 installed[widget]=widget.frame:GetScript('OnClick')
 widget.frame:SetScript('OnClick',function()open(widget)end)
end
ForeverHandheldColorEditorRelease=function(widget)
 if widget==owner then close()end
 local handler=installed[widget]
 if handler then widget.frame:SetScript('OnClick',handler);installed[widget]=nil end
end

-- Questie's newer options engine creates its own swatch buttons, outside
-- AceGUI. Keep its current getter/setter and refresh lifecycle intact.
ForeverHandheldColorEditorInstallQuestie=function(control)
 local swatch=control.widget
 if not swatch or not swatch.SetScript then return end
 swatch:SetScript('OnClick',function()
  local item=control.itemData
  if not item or item.type~='colorPicker' or not item.get or not item.set then return end
  local r,g,b,a=item.get()
  local proxy={frame=swatch,text=control.titleFrame,HasAlpha=item.hasOpacity,r=r or 1,g=g or 1,b=b or 1,a=a or 1}
  function proxy:IsValid()return control.itemData==item and swatch:IsEnabled()end
  function proxy:SetColor(red,green,blue,alpha)self.r,self.g,self.b,self.a=red,green,blue,alpha end
  function proxy:Fire(_,red,green,blue,alpha)
   item.set(red,green,blue,alpha)
   local engine=QuestieLoader and QuestieLoader:ImportModule('QuestieOptionsEngine')
   if engine then engine:QueueRefresh()end
  end
  open(proxy)
 end)
 swatch:HookScript('OnHide',function()
  if owner and owner.frame==swatch then close()end
 end)
end
