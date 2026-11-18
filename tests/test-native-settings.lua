local driver,combat=false,false
local function font(size)
 return {size=size,w=170,writes=0,
  IsObjectType=function(_,t)return t=='FontString'end,
  GetFont=function(s)return 'NativeFont',s.size,'OUTLINE'end,
  SetFont=function(s,face,n,flags)assert(face=='NativeFont' and flags=='OUTLINE');s.size=n;s.writes=s.writes+1 end,
  GetWidth=function(s)return s.w end,
  SetWidth=function(s,w)s.w=w;s.writes=s.writes+1 end}
end
local function frame(w,h)
 return {w=w or 100,h=h or 22,writes=0,regions={},children={},
  IsShown=function(s)return not s.hidden end,
  IsProtected=function(s)return s.protected end,
  IsForbidden=function(s)return s.forbidden end,
  GetWidth=function(s)return s.w end,GetHeight=function(s)return s.h end,
  SetSize=function(s,w,h)s.w=w;s.h=h;s.writes=s.writes+1 end,
  SetWidth=function(s,w)s.w=w;s.writes=s.writes+1 end,
  GetRegions=function(s)return unpack(s.regions)end,
  GetChildren=function(s)return unpack(s.children)end}
end
function CreateFrame()driver={SetScript=function(s,k,v)s[k]=v end};return driver end
function InCombatLockdown()return combat end
function GetTime()return 100 end
function issecretvalue(v)return type(v)=='table' end
SettingsPanel=frame(920,724)
local ornament={alpha=1,GetAtlas=function()return 'Options_InnerFrame'end,GetAlpha=function(s)return s.alpha end,SetAlpha=function(s,v)s.alpha=v end}
SettingsPanel.regions={ornament}
SettingsPanel.CategoryList=frame(199,569)
local category=frame();category.regions={font(12)};SettingsPanel.CategoryList.children={category}
local list=frame(600,600);SettingsPanel.Container={SettingsList=list,SettingsCanvas=frame()}
local row=frame(700,25);row.Label=font(12);row.Button1=frame(160,22);row.Button2=frame(160,22)
row.Button1.Text=font(10);row.Button2.Text=font(10)
row.Button1.regions={row.Button1.Text};row.Button2.regions={row.Button2.Text}
row.regions={row.Label};row.children={row.Button1,row.Button2};list.children={row}
list.Header={Title=font(28),DefaultsButton={Text=font(12)}}
SettingsPanel.CloseButton={Text=font(12)}
local action=function()error('native action called')end
row.Button1.OnClick=action;row.Button1.binding='SHIFT-PAD1';row.Button2.binding='W'
local canvasFont=font(10);SettingsPanel.Container.SettingsCanvas.regions={canvasFont}
dofile(arg[1])
local function tick()driver.OnUpdate(driver,.25)end
SettingsPanel.hidden=true;tick();assert(SettingsPanel.w==920,'hidden panel resized')
SettingsPanel.hidden=false;combat=true;tick();assert(SettingsPanel.w==920,'combat layout changed')
combat=false;SettingsPanel.protected=true;tick();assert(SettingsPanel.w==920,'protected layout changed')
SettingsPanel.protected=false;tick()
assert(SettingsPanel.w==1120 and SettingsPanel.h==620 and SettingsPanel.CategoryList.w==240,'workspace not adapted')
assert(ornament.alpha==0,'fixed-size inner artwork extends outside resized panel')
assert(category.regions[1].size==16 and row.Label.size==16 and row.Label.w==225,'native list readability')
assert(row.Button1.Text.size==16 and SettingsPanel.CloseButton.Text.size==16)
assert(list.Header.Title.size==28,'larger native heading shrunk')
assert(canvasFont.size==10,'addon canvas typography changed')
assert(row.Button1.OnClick==action and row.Button1.binding=='SHIFT-PAD1' and row.Button2.binding=='W','native binding behavior changed')
local writes=SettingsPanel.writes+row.Label.writes+row.Button1.Text.writes
for i=1,20 do tick()end
assert(writes==SettingsPanel.writes+row.Label.writes+row.Button1.Text.writes,'stable layout repeatedly written')
row.Button1.Text.size=10;tick();assert(row.Button1.Text.size==16,'recycled native font not reapplied')
local hidden=frame();hidden.hidden=true;hidden.regions={font(10)};list.children[#list.children+1]=hidden
local forbidden=frame();forbidden.forbidden=true;forbidden.GetRegions=function()error('forbidden read')end;list.children[#list.children+1]=forbidden
tick();assert(hidden.regions[1].size==10 and not ForeverHandheldDB.nativeSettingsError)
local secret=font({});list.regions={secret};tick();assert(secret.writes==0)
assert(ForeverHandheldDB.nativeSettings.visited<=240)
print('PASS native settings: readable native lists, viewport-friendly workspace, binding/script preservation, addon isolation, combat/protected guards, stable writes and pooled font reuse')

-- A native protected preview must not strand late-created ordinary settings.
SettingsPanel.protected=true;list.protected=true
local late=frame();late.regions={font(10)};list.children[#list.children+1]=late
local preview=frame();preview.protected=true;preview.regions={font(10)};list.children[#list.children+1]=preview
local rootWrites=SettingsPanel.writes;tick()
assert(late.regions[1].size==16,'protected container prevented ordinary row styling')
assert(preview.regions[1].size==10,'protected preview presentation changed')
assert(SettingsPanel.writes==rootWrites,'protected root geometry changed')
assert(ForeverHandheldDB.nativeSettings.protectedContainer)
print('PASS: protected preview/container preserves geometry and native preview while late ordinary rows remain readable')

local actionRow=frame(700,26);actionRow.EvaluateName=function()error('native name evaluator called')end
actionRow.Button=frame(200,26);local actionButton=actionRow.Button
actionButton.Text=font(12);actionButton.GetFontString=function(s)return s.Text end
actionButton.GetPoint=function()return 'LEFT',actionRow,'LEFT',0,0 end
actionButton.Text.GetStringWidth=function(s)return (s.characters or 30)*s.size/2 end
actionButton.OnClick=action;actionRow.children={actionButton};list.children[#list.children+1]=actionRow
tick();assert(actionButton.w==272 and actionButton.Text.size==16,'long standalone action label overflowed')
assert(actionButton.OnClick==action,'settings action callback changed')
local n=actionButton.writes;tick();assert(actionButton.writes==n,'stable action button resized repeatedly')
actionButton.Text.characters=4;tick();assert(actionButton.w==200,'recycled short action did not return to native width')
actionButton.Text.characters=100;actionButton.GetPoint=function()return 'LEFT',actionRow,'CENTER',-40,0 end
tick();assert(actionButton.w<=374,'labelled action overlaps row boundary')
actionButton.protected=true;actionButton.w=200;tick();assert(actionButton.w==200,'protected action geometry changed')
assert(not ForeverHandheldDB.nativeSettingsError)
print('PASS: standalone action labels fit; pooled short labels restore width, centred rows respect available room; callbacks/protected buttons retained')

local dropdownRow=frame(760,26);local control=frame(223,38);local dropdown=frame(220,22)
dropdownRow.Control=control;control.Dropdown=dropdown;dropdownRow.children={control};control.children={dropdown}
control.GetPoint=function()return 'LEFT',dropdownRow,'CENTER',-48,3 end
dropdown.OnClick=action;dropdown.value='enUS';control.IncrementButton={OnClick=action};control.DecrementButton={OnClick=action}
local language=frame(80,14);language.GetSize=function(s)return s.w,s.h end;language.atlas='language-enUS';dropdown.Language=language
list.children[#list.children+1]=dropdownRow;tick()
assert(dropdown.w==360 and control.w==363,'dropdown value did not use available right column')
assert(math.abs(control.w/2-dropdown.w/2-1.5)<.001,'dropdown left edge moved into label/stepper area')
assert(language.h==32 and math.abs(language.w/32-80/14)<.001 and language.atlas=='language-enUS','locale atlas identity/aspect ratio changed')
assert(dropdown.OnClick==action and dropdown.value=='enUS' and control.IncrementButton.OnClick==action)
local n=dropdown.writes+control.writes+language.writes;tick();assert(n==dropdown.writes+control.writes+language.writes)
language.w=80;language.h=14;dropdown.w=220;control.w=223;control.protected=true;tick();assert(language.h==14 and dropdown.w==220)
control.protected=false;combat=true;tick();assert(language.h==14 and dropdown.w==220);combat=false
language.hidden=true;dropdownRow.w=500;tick();assert(language.h==14 and dropdown.w==250,'hidden atlas or narrow column mishandled')
assert(not ForeverHandheldDB.nativeSettingsError)
print('PASS: native dropdown and container grow together, stable left edge/steppers/callbacks/value, proportional locale atlas, stable writes and protected/combat/narrow guards')

local labelRow=frame(760,26);labelRow.GetSetting=function()return {}end;labelRow.Text=font(16)
local label=labelRow.Text;label.h=16;label.wrap=false;label.lines=1
label.IsShown=function()return true end;label.CanWordWrap=function(s)return s.wrap end
label.SetWordWrap=function(s,v)s.wrap=v;s.writes=s.writes+1 end
label.GetMaxLines=function(s)return s.lines end;label.SetMaxLines=function(s,v)s.lines=v;s.writes=s.writes+1 end
label.GetHeight=function(s)return s.h end;label.SetHeight=function(s,v)s.h=v;s.writes=s.writes+1 end
labelRow.regions={label};list.children[#list.children+1]=labelRow;tick()
assert(label.wrap and label.lines==2 and label.h==32 and labelRow.h==26,'label did not fit two lines inside native row spacing')
local writes=label.writes;tick();assert(label.writes==writes,'settled label churn')
labelRow.protected=true;label.h=16;tick();assert(label.h==16,'protected label changed');labelRow.protected=false
combat=true;tick();assert(label.h==16,'combat label changed');combat=false
label.size=22;tick();assert(label.h==16,'large native heading changed')
assert(not ForeverHandheldDB.nativeSettingsError)
print('PASS: two-line setting labels use existing row spacing, unchanged row geometry, stable writes and protected/combat/large-heading guards')

local nested=list
for i=1,7 do local child=frame();nested.children[#nested.children+1]=child;nested=child end
local deepFont=font(10);nested.regions={deepFont};nested.OnClick=action
tick();assert(deepFont.size==16 and nested.OnClick==action,'nested graphics control missed or action altered')
local deepWrites=deepFont.writes;tick();assert(deepFont.writes==deepWrites,'nested font churn')
assert(ForeverHandheldDB.nativeSettings.visited<=240 and not ForeverHandheldDB.nativeSettingsError)
print('PASS: nested native graphics control readable within unchanged 240-frame budget; action and settled state retained')
