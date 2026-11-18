local M={};local frames={}
local function obj(kind,name,parent)local o=setmetatable({kind=kind,name=name,parent=parent,scripts={},visible=true},{__index=M});frames[#frames+1]=o;if name then _G[name]=o end;return o end
for _,k in ipairs({'SetFont','SetPoint','SetSize','SetTextColor','SetWidth','SetFrameStrata','SetFrameLevel','EnableMouse','SetBackdrop','SetBackdropColor','SetBackdropBorderColor','SetHighlightTexture','SetVertexColor','SetValueStep','SetObeyStepOnDrag'})do M[k]=function()end end
function M:GetFrameLevel()return 10 end
function M:EnableKeyboard(v)self.keyboard=v end
function M:SetPropagateKeyboardInput(v)self.propagate=v end
function M:RegisterEvent(v)self.events=self.events or {};self.events[v]=true end
function M:IsEnabled()return not self.disabled end
function M:HookScript(k,v)local old=self.scripts[k];self.scripts[k]=function(...)if old then old(...)end;v(...)end end
function M:SetDrawLayer(v)self.layer=v end
function M:GetHighlightTexture()return self end
function M:SetText(t)self.text=t end
function M:GetText()return self.text end
function M:SetColorTexture(...)self.color={...}end
function M:CreateFontString()return obj('FontString',nil,self)end
function M:CreateTexture()return obj('Texture',nil,self)end
function M:SetScript(k,v)self.scripts[k]=v end
function M:GetScript(k)return self.scripts[k]end
function M:Show()local before=self.visible;self.visible=true;if not before and self.scripts.OnShow then self.scripts.OnShow(self)end end
function M:Hide()local before=self.visible;self.visible=false;if before and self.scripts.OnHide then self.scripts.OnHide(self)end end
function M:SetShown(v)if v then self:Show()else self:Hide()end end
function M:IsVisible()return self.visible end
function M:SetValue(v)self.value=v;if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v)end end
function M:SetMinMaxValues(a,b)self.min=a;self.max=b end
function CreateFrame(kind,name,parent,template)local f=obj(kind,name,parent);if template=='OptionsSliderTemplate' then f.Text=obj();f.Low=obj();f.High=obj()end;return f end
SettingsPanel=obj();UIParent=obj();UISpecialFrames={};STANDARD_TEXT_FONT='font';local combat=false
function InCombatLockdown()return combat end
function GetTime()return 5 end
local shown,hidden=0,0
GamepadMode={FrameControlsManager={FrameShown=function(_,f,popup)assert(not combat,'navigation activated in combat');assert(f==ForeverHandheldColorEditor and popup);shown=shown+1 end,FrameHidden=function(_,f)assert(not combat,'navigation cleanup called in combat');assert(f==ForeverHandheldColorEditor);hidden=hidden+1 end}}
ColorPickerFrame=setmetatable({},{__index=function()error('native color picker accessed')end})
GameTooltip=obj();dofile(arg[1])
local originalClick=function()error('unsafe old picker used')end
local w={r=.2,g=.4,b=.6,a=.7,HasAlpha=false,text=obj(),frame=obj(),events={}}
w.text:SetText('Route color');w.frame:SetScript('OnClick',originalClick)
function w:SetColor(r,g,b,a)self.r,self.g,self.b,self.a=r,g,b,a end
function w:Fire(event,...)self.events[#self.events+1]={event,...}end
local function click(f)f.scripts.OnClick(f)end
ForeverHandheldColorEditorInstall(w);click(w.frame)
local e=ForeverHandheldColorEditor
assert(e:IsVisible() and shown==1 and e.parent==SettingsPanel)
assert(not GameTooltip:IsVisible(),'owner tooltip obscures editor')
assert(e.before.layer=='ARTWORK' and e.preview.layer=='ARTWORK','data swatches can be covered by the backdrop')
assert(not e.rows[4].slider:IsVisible(),'opacity shown on RGB setting')
click(e.rows[1].plus);assert(w.r==.2 and #w.events==0,'draft writes setting early')
e.SmartNavigationCloseHandler();assert(not e:IsVisible() and #w.events==0 and hidden==1,'B did not cancel')
click(w.frame);click(e.apply);assert(#w.events==0,'unchanged apply executed setting')
click(w.frame);e.rows[1].slider:SetValue(123);click(e.apply)
assert(w.r==123/255 and w.a==1 and #w.events==1 and w.events[1][1]=='OnValueConfirmed','Apply contract failed')
w.HasAlpha=true;click(w.frame);assert(e.rows[4].slider:IsVisible());e.rows[4].slider:SetValue(66);click(e.cancel);assert(w.a==1 and #w.events==1,'alpha cancel changed setting')
click(w.frame);e.rows[4].slider:SetValue(66);click(e.apply);assert(w.a==66/100 and #w.events==2)
click(w.frame);click(e.rows[2].minus);ForeverHandheldColorEditorRelease(w);assert(not e:IsVisible() and #w.events==2 and w.frame:GetScript('OnClick')==originalClick,'pool release did not cancel/restore')
ForeverHandheldColorEditorInstall(w);w.disabled=true;click(w.frame);assert(not e:IsVisible());w.disabled=false;combat=true;click(w.frame);assert(not e:IsVisible());combat=false
click(w.frame);e.rows[1].slider:SetValue(10);w.disabled=true;click(e.apply);assert(#w.events==2,'disabled owner committed')
w.disabled=false;click(w.frame);e.scripts.OnKeyDown(e,'SPACE');assert(e.propagate and e:IsVisible());e.scripts.OnKeyDown(e,'ESCAPE');assert(not e.propagate and not e:IsVisible() and #w.events==2,'Escape leaked or committed')
click(w.frame);assert(e.events.PLAYER_REGEN_DISABLED and e.events.PLAYER_REGEN_ENABLED)
local beforeHidden=hidden;combat=true;e.scripts.OnEvent(e,'PLAYER_REGEN_DISABLED');assert(not e:IsVisible() and #w.events==2 and hidden==beforeHidden,'combat entry did not cancel/defer cleanup')
combat=false;e.scripts.OnEvent(e,'PLAYER_REGEN_ENABLED');assert(hidden==beforeHidden+1,'deferred cleanup missing');e.scripts.OnEvent(e,'PLAYER_REGEN_ENABLED');assert(hidden==beforeHidden+1,'cleanup repeated')
print('PASS: controller popup lifecycle, staged RGB/alpha edits, B/Cancel/unchanged Apply, one confirmed callback, pooling restoration, disabled/combat guards; native color picker untouched.')
local current={.1,.2,.3,.4};local commits,refreshes=0,0
local item={type='colorPicker',hasOpacity=true,get=function()return unpack(current)end,set=function(...)current={...};commits=commits+1 end}
local control={itemData=item,widget=obj(),titleFrame=obj()};control.titleFrame:SetText('Tracker background')
QuestieLoader={ImportModule=function(_,name)assert(name=='QuestieOptionsEngine');return {QueueRefresh=function()refreshes=refreshes+1 end}end}
ForeverHandheldColorEditorInstallQuestie(control);click(control.widget);assert(e.rows[4].slider:IsVisible() and e.title:GetText()=='Tracker background')
e.rows[4].slider:SetValue(100);click(e.cancel);assert(commits==0 and current[4]==.4,'Questie canceled alpha committed')
click(control.widget);e.rows[4].slider:SetValue(100);click(e.apply);assert(commits==1 and refreshes==1 and current[4]==1,'Questie callback/refresh/alpha contract failed')
current={.8,.7,.6,.5};click(control.widget);assert(e.rows[1].value:GetText()=='204','Questie getter not read at open')
e.rows[1].slider:SetValue(50);control.widget.disabled=true;click(e.apply);assert(commits==1,'Questie disabled during draft committed')
control.widget.disabled=false;click(control.widget);control.itemData={type='text'};click(e.apply);assert(commits==1,'Questie changed row committed stale item')
control.itemData=item;click(control.widget);control.widget:Hide();assert(not e:IsVisible() and commits==1,'Questie disappearing owner left editor open')
print('PASS: Questie current getter, alpha semantics, one setter/queued refresh, Cancel, disabled/replaced owner guards and page-hide cancellation.')

control.widget:Show();current={.12345,.7,.6,.5};click(control.widget);click(e.rows[1].plus);click(e.rows[1].minus);click(e.apply);assert(commits==1 and current[1]==.12345,'roundtrip quantized original RGB')
click(control.widget);assert(e.rows[4].slider.max==100 and e.rows[4].value:GetText()=='50%','opacity is not a percentage');click(e.rows[4].plus);click(e.apply);assert(current[4]==.51);click(control.widget);click(e.rows[4].minus);click(e.apply);assert(current[4]==.5,'opacity restoration lost precision')
print('PASS: exact original RGB roundtrip, percentage opacity and owner tooltip cleanup.')
