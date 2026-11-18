local frames={}
local M={}
function M:IsVisible()return not self.hidden end
function M:GetFont()return 'font',self.font or 12,'' end
function M:SetFont(_,size)self.font=size end
function M:GetHeight()return self.h or 18 end
function M:GetWidth()return self.w or 150 end
function M:SetHeight(v)self.h=v end
function M:SetWidth(v)self.w=v end
function M:GetStringHeight()return 15 end
function M:SetScript(k,v)self[k]=v end
local function region(t)return setmetatable(t or {},{__index=M})end
function CreateFrame()local f=region();frames[#frames+1]=f;return f end
local function widget(kind)
 local w={type=kind,frame=region({h=24,w=150}),text=region(),label=region(),children={},width=150,value=true,disabled=true,callbacks={untouched=true}}
 function w:SetFullWidth(v)self.width=v and 'fill' or nil end
 function w:SetHeight(v)self.frame:SetHeight(v)end
 function w:SetWidth(v)self.frame:SetWidth(v)end
 function w:DoLayout()self.layouts=(self.layouts or 0)+1 end
 function w:BuildTabs()self.builds=(self.builds or 0)+1 end
 return w
end
local box=widget('CheckBox');local tab=widget('TabGroup');tab.tabs={{Text=region()}};tab.children={box}
local root=widget('BlizOptionsGroup');root.children={tab}
local gui={Release=function(_,w)w.frame.hidden=true;w.width=nil;w.frame.h=24 end}
local dialog={BlizOptions={RXP={main=root}}}
function LibStub(name)return name=='AceGUI-3.0' and gui or dialog end
function hooksecurefunc(obj,key,fn)local orig=obj[key];obj[key]=function(self,...)orig(self,...);fn(self,...)end end
SettingsPanel=region();local combat=false
local refreshes=0
SmartNavigation={activeInfo={frame=SettingsPanel},RefreshButtonGroups=function(_,panel)assert(panel==SettingsPanel);refreshes=refreshes+1 end}
function InCombatLockdown()return combat end
function GetTime()return 30 end
dofile(arg[1]);local driver=frames[#frames]
local function tick()driver.OnUpdate(driver,.5);assert(not (ForeverHandheldDB and ForeverHandheldDB.addonSettingsError),ForeverHandheldDB and ForeverHandheldDB.addonSettingsError)end
SettingsPanel.hidden=true;tick();assert(box.text.font==nil,'hidden page changed')
SettingsPanel.hidden=false;combat=true;tick();assert(box.text.font==nil,'combat page changed')
combat=false;tick();assert(box.text.font==17 and box.width=='fill' and box.frame.h==34,'checkbox readability not applied');assert(tab.tabs[1].Text.font==15 and tab.builds==1,'tabs not reflowed');assert(box.value and box.disabled and box.callbacks.untouched,'native state modified')
local layouts=root.layouts;assert(refreshes==1,'native focus list not refreshed after dynamic page construction');tick();assert(root.layouts==layouts and refreshes==1,'unchanged page reflowed or refreshed repeatedly')
gui:Release(box);assert(box.text.font==12 and box.text.h==18 and box.width==nil,'pooled checkbox style leaked');gui:Release(tab);assert(tab.tabs[1].Text.font==12,'pooled tab style leaked')
print('PASS: readable AceGUI rows/tabs, hidden/combat deferral, stable layout, original callbacks/disabled/value state, shared-pool font/height restoration.')
-- AutoGear's checkbox chain and secondary controls stay native and keep order.
function M:GetChildren()return unpack(self.children or {})end
function M:GetRegions()return unpack(self.regions or {})end
function M:IsObjectType(kind)return self.kind==kind end
function M:SetSize(w,h)self.w=w;self.h=h end
function M:GetFontString()return self.label end
function M:GetStringWidth()return 80 end
function M:SetWordWrap(v)self.wrap=v end
function M:SetJustifyH(v)self.justify=v end
function M:GetPoint()return unpack(self.point or {})end
function M:ClearAllPoints()self.point=nil end
function M:SetPoint(...)self.point={...}end
AutoGearOptionsMenu=region()
local page=region({kind='Frame'})
local check=region({kind='CheckButton',label=region(),checked=true,callback=function()error('option executed while styling')end})
local drop=region({kind='DropdownButton',h=24,label=region()});check.dropDown=drop
local second=region({kind='CheckButton',label=region()})
local scan=region({kind='Button',label=region()})
check.point={'TOPLEFT',page,'TOPLEFT',12,-12};second.point={'TOPLEFT',check,'BOTTOMLEFT',0,-2};scan.point={'TOPLEFT',second,'BOTTOMLEFT',4,-10};page.lastRow=scan
AutoGearOptionsTabContainer=region({w=640,children={page}})
AutoGearOptionsTabContainerTab1=region({label=region()})
local callback=check.callback
tick()
assert(check.point[2]==page and second.point[2]==page,'rows lost native page parent anchor')
assert(drop.point[2]==page and drop.point[5]<check.point[5] and second.point[5]<drop.point[5]-drop.h,'dropdown overlaps label or next row')
assert(scan.point[5]<second.point[5]-second.h,'scan overlaps preceding row')
assert(check.label.font==17 and check.label.w==575 and drop.w==572,'AutoGear text/control width not fitted')
assert(check.checked and check.callback==callback,'AutoGear option state or handler changed')
local y=scan.point[5];tick();assert(scan.point[5]==y,'row chain reordered after reflow')
assert(AutoGearOptionsMenu.h>AutoGearOptionsTabContainer.h,'scroll child too short')
print('PASS: AutoGear row order, stacked dropdown spacing, scroll extent, native checked state/callbacks and stable repeated layout.')
-- Questie builds pages in a coroutine. The adapter must preserve that yielding
-- behavior and return value, plus native callbacks and source definitions.
local input={one={type='checkbox',width=.5,titleSize=12,descriptionSize=10,get=function()return true end,set=function()error('preference changed by styling')end},two={type='text',titleSize=24}}
local observed,nextControl
local questie={Build=function(parent,items,width,level,created)
 observed=items
 assert(parent=='parent' and width==600 and level==1)
 coroutine.yield('native-budget')
 created(nextControl or {itemData=items.one})
 return 440
end}
QuestieLoader={ImportModule=function(_,name)assert(name=='QuestieOptionsLayout');return questie end}
tick()
local called=false
local thread=coroutine.create(function()return questie.Build('parent',input,600,1,function(item)called=true;assert(item.itemData.get==input.one.get and item.itemData.set==input.one.set)end)end)
local ok,value=coroutine.resume(thread);assert(ok and value=='native-budget','Questie build no longer yieldable')
ok,value=coroutine.resume(thread);assert(ok and value==440 and called,'native layout result or callback lost')
assert(observed.one.width==1 and observed.one.titleSize==17 and observed.one.descriptionSize==14 and observed.two.titleSize==24,'Questie presentation not adapted')
assert(input.one.width==.5 and input.one.titleSize==12 and input.one.descriptionSize==10,'source definitions mutated')
local before=refreshes;tick();assert(refreshes==before+1,'completed Questie build did not refresh native navigation')
print('PASS: Questie yieldable native layout, presentation-only copies, existing larger headings, native callback/value preservation and post-build navigation refresh.')

local slider=region({w=500,h=16,Text=region(),Low=region(),High=region(),value=7})
function slider.Text:GetStringHeight()return 34 end
nextControl=region({h=42,itemData={type='slider'},widget=slider,valueDisplay=region()})
thread=coroutine.create(function()return questie.Build('parent',input,600,1,function(c)assert(c==nextControl)end)end)
assert(coroutine.resume(thread));assert(coroutine.resume(thread))
assert(slider.Text.font==17 and slider.Low.font==13 and nextControl.valueDisplay.font==16,'slider labels stayed small')
assert(slider.point[5]==-42 and nextControl.h>=84,'wrapped title or values overlap adjacent row')
assert(slider.value==7,'slider value changed during layout')
local dropdown=region({w=500,h=22,label=region()})
nextControl=region({h=40,itemData={type='dropdown'},widget=dropdown,titleFrame=region()})
thread=coroutine.create(function()return questie.Build('parent',input,600,1,function()end)end)
assert(coroutine.resume(thread));assert(coroutine.resume(thread))
assert(nextControl.titleFrame.font==17 and dropdown.label.font==16 and nextControl.h>=51,'dropdown label/row sizing incomplete')
print('PASS: wrapped Questie slider labels, readable range/value text, full dropdown label spacing; stored slider value preserved.')

nextControl=region({h=20,itemData={type='text'},titleFrame=region(),descriptionFrame=region()})
function nextControl.titleFrame:GetStringHeight()return 0 end
function nextControl.descriptionFrame:GetStringHeight()return 28 end
thread=coroutine.create(function()return questie.Build('parent',input,600,1,function()end)end)
assert(coroutine.resume(thread));assert(coroutine.resume(thread))
assert(nextControl.h>=34 and nextControl.titleFrame.point[2]==nextControl,'description-only row overflows into next control')
print('PASS: description-only profile help reserves wrapped text height before following input.')

local aceSlider=widget('Slider');aceSlider.lowtext=region();aceSlider.hightext=region();aceSlider.editbox=region({h=14})
local key=widget('Keybinding');key.button=region({h=24,label=region()})
root.children={aceSlider,key};root.frame.hidden=false;tick()
assert(aceSlider.frame.h>=60 and aceSlider.label.h==22 and aceSlider.editbox.h==22 and aceSlider.editbox.font==16,'Ace slider clips readable label/value')
assert(key.frame.h>=56 and key.button.h==30 and key.button.label.font==16 and key.width=='fill','keybinding remains too small')
gui:Release(aceSlider);gui:Release(key)
assert(aceSlider.label.h==18 and aceSlider.editbox.h==14 and aceSlider.editbox.font==12 and key.button.h==24,'pooled control dimensions leaked')
print('PASS: Ace slider/keybinding readable sizing and shared-pool restoration without changing preferences.')

local tex={desaturated=false,color={1,.2,.1,1}}
function tex:GetVertexColor()return unpack(self.color)end
function tex:IsDesaturated()return self.desaturated end
function tex:SetDesaturated(v)self.desaturated=v end
function tex:SetVertexColor(...)self.color={...}end
local styledButton=widget('Button')
function styledButton.frame:GetNormalTexture()return tex end
root.children={styledButton};tick();assert(tex.desaturated and tex.color[1]==.5,'addon button stays default red')
gui:Release(styledButton);assert(not tex.desaturated and tex.color[1]==1 and tex.color[2]==.2,'button theme leaks into shared widget pool')
print('PASS: scoped charcoal button texture and shared-pool color/desaturation restoration.')
for _,kind in ipairs({'RS_Markers','LSM30_Sound'})do
 local w=widget(kind);w.frame.label=region();w.frame.text=region();local callback=w.callbacks
 root.children={w};tick();assert(w.frame.label.font==16 and w.frame.text.font==16 and w.frame.h>=56 and w.width=='fill','custom selector remains too small')
 assert(w.callbacks==callback and w.value==true and w.disabled==true,'custom selector behavior changed')
 gui:Release(w);assert(w.frame.label.font==12 and w.frame.text.font==12 and w.frame.label.h==18,'custom selector pool style leaked')
end
print('PASS: native marker/sound selectors retain callbacks, values and pooled styles.')
local edit=widget('EditBox');edit.editbox=region({h=19});root.children={edit};tick()
assert(edit.editbox.font==16 and edit.editbox.h==24 and edit.frame.h>=56,'edit text not readable')
gui:Release(edit);assert(edit.editbox.font==12 and edit.editbox.h==19,'editbox pooled font/height leaked')
print('PASS: editbox text readability and pooled geometry restoration.')
local long=widget('CheckBox');long.checkbg=region();long.text.savedPoint={'LEFT',long.checkbg,'RIGHT',0,0}
function long.text:GetStringHeight()return 51 end
function long.text:GetNumPoints()return 1 end
function long.text:GetPoint()return unpack(self.savedPoint)end
function long.text:ClearAllPoints()self.point=nil end
function long.text:SetPoint(...)self.point={...};self.firstPoint=self.firstPoint or self.point end
root.children={long};tick();assert(long.text.h==53 and long.frame.h>=63,'long checkbox label still truncated')
assert(long.text.firstPoint[1]=='TOPLEFT','multiline label grows above row')
gui:Release(long);assert(long.text.h==18 and long.text.point[1]=='LEFT','checkbox pooled anchors or height leaked')
print('PASS: multiline checkbox height and top anchoring, native pool anchor restoration.')

local tree=widget('TreeGroup');tree.frame.w=650
tree.localstatus={treewidth=175,treesizable=true,scrollvalue=4,selected='timers',groups={icons=true}}
tree.buttons={region({text=region(),h=18}),region({text=region(),h=18,hidden=true})}
function tree:GetTreeWidth()return self.localstatus.treewidth end
function tree:SetTreeWidth(w,sizable)self.localstatus.treewidth=w;self.localstatus.treesizable=sizable end
local callbacks=tree.callbacks
root.children={tree};tick()
assert(tree.buttons[1].text.font==16 and tree.buttons[1].h==18,'tree text readability changed native row stride')
assert(tree.buttons[2].text.font==nil,'hidden pooled tree row was styled')
assert(math.abs(tree.localstatus.treewidth-221)<.01 and tree.localstatus.treesizable==true,'tree width did not fit available space')
assert(tree.localstatus.scrollvalue==4 and tree.localstatus.selected=='timers' and tree.localstatus.groups.icons and tree.callbacks==callbacks,'tree selection/scroll/expansion or callbacks changed')
local n=root.layouts;tick();assert(root.layouts==n,'unchanged tree reflowed repeatedly')
gui:Release(tree);assert(tree.buttons[1].text.font==12,'shared tree font leaked after release')
print('PASS: readable native tree rows, width fitting, unchanged selection/scroll/expansion/callbacks, stable layout and pooled font restoration.')

local drop=widget('Dropdown');local pullout=widget('Dropdown-Pullout')
local item=widget('Dropdown-Item-Toggle');item.frame.h=17;item.checked=true
pullout.items={item};drop.pullout=pullout
pullout.frame.color={0,0,0,.8};pullout.frame.border={.5,.5,.5,1}
function pullout.frame:GetBackdropColor()return unpack(self.color)end
function pullout.frame:GetBackdropBorderColor()return unpack(self.border)end
function pullout.frame:SetBackdropColor(...)self.color={...}end
function pullout.frame:SetBackdropBorderColor(...)self.border={...}end
root.children={drop};tick()
assert(item.text.font==15 and item.frame.h==17 and item.checked and item.callbacks.untouched,'dropdown row state or native geometry changed')
assert(pullout.frame.color[4]==1 and pullout.frame.border[1]==.68,'dropdown palette not applied')
gui:Release(item);gui:Release(pullout)
assert(item.text.font==12 and pullout.frame.color[4]==.8 and pullout.frame.border[1]==.5,'shared dropdown style leaked')
print('PASS: native pullout readable rows, unchanged checked state/geometry/callbacks and shared-pool palette/font restoration.')
