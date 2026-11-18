local frames,driver={},nil
local combat,gamepad,focus=false,true,nil
SlashCmdList={}
local M={}
function M:GetName()return self.name end
function M:IsVisible()return not self.hidden and (not self.parent or self.parent:IsVisible())end
function M:IsShown()return not self.hidden end
function M:GetWidth()return self.w or 10 end
function M:GetHeight()return self.h or 10 end
function M:SetShown(v)self.hidden=not v end
function M:SetMinMaxValues(lo,hi)self.lo=lo;self.hi=hi end
function M:GetMinMaxValues()return self.lo or 0,self.hi or 0 end
function M:GetValue()return self.value or 0 end
function M:SetValue(v)self.value=v;if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v)end end
function M:SetVerticalScroll(v)self.scrollValue=v end
function M:SetWidth(w)self.w=w end
function M:SetHeight(h)self.h=h end
function M:SetSize(w,h)self.w=w;self.h=h end
function M:GetPoint()return unpack(self.point or {})end
function M:SetPoint(...)self.point={...}end
function M:GetFont()return 'Font',self.fontSize or 10,'' end
function M:SetFont(_,size)self.fontSize=size end
function M:SetText(s)self.label=s end
function M:GetAlpha()return 1 end
function M:GetChildren()return unpack(self.children)end
function M:IsObjectType(kind)return self.kind==kind end
function M:GetScript(event)return self.scripts[event]end
function M:IsEnabled()return not self.disabled end
function M:IsProtected()return self.protected end
function M:GetCenter()return self.x or 0,self.y or 0 end
function M:GetFrameLevel()return 1 end
function M:GetText()return self.label end
function M:SetScript(k,v)self.scripts[k]=v end
function M:HookScript(k,v)self.hooks[k]=v end
function M:RegisterEvent()driver=self end
function M:Click()if self.scripts.OnClick then self.scripts.OnClick(self) end;if self.hooks.OnClick then self.hooks.OnClick(self)end end
function M:Hide()self.hidden=true;if self.hooks.OnHide then self.hooks.OnHide(self)end end
function M:Show()self.hidden=false end
function M:CreateTexture()return setmetatable({},{__index=function()return function()end end})end
M.CreateFontString=M.CreateTexture
function CreateFrame(kind,name,parent)
 local f=setmetatable({kind=kind,name=name,parent=parent,children={},scripts={},hooks={}},{__index=function(t,k)if M[k] then return M[k] end;if k:match('^Set') or k:match('^Enable') or k=='RegisterForClicks' or k=='ClearAllPoints' then return function()end end end})
 frames[#frames+1]=f;if parent then parent.children[#parent.children+1]=f end;if name then _G[name]=f end;return f
end
UIParent=CreateFrame('Frame','UIParent')
STANDARD_TEXT_FONT='Font'
function InCombatLockdown()return combat end
function GetCurrentKeyBoardFocus()return focus end
local currentMap,commits={},0
local handle={clear=function()currentMap={}end,replace=function(map)currentMap=map end,commit=function()commits=commits+1 end}
ControllerForever={RuleBar={state={},isGamepadOn=function()return gamepad end},Menu={state={}},Binds={PRIORITY={ourwindow=100},claimant=function(_,name,priority,opts)assert(opts.outOfFight and opts.exclusive and opts.overGame);return handle end}}
LorewardDirectionsWindow=CreateFrame('Frame','LorewardDirectionsWindow',UIParent)
local selected={}
local function button(label,x,y)
 local b=CreateFrame('Button',nil,LorewardDirectionsWindow);b.label=label;b.x=x;b.y=y
 b:SetScript('OnClick',function()selected[#selected+1]=label end);return b
end
local vendor=button('Vendor',100,300)
local repair=button('Repair',250,300)
local bank=button('Bank',100,200)
local hidden=button('Hidden',250,200);hidden.hidden=true
local disabled=button('Disabled',400,300);disabled.disabled=true
local protected=button('Protected',100,400);protected.protected=true
local original=vendor.scripts.OnClick
dofile(arg[1])
local N=ForeverHandheldJourneyControls
local function tick()driver.scripts.OnUpdate(driver,.3);assert(not ForeverHandheldDB or not ForeverHandheldDB.journeyError,ForeverHandheldDB and ForeverHandheldDB.journeyError)end
focus={GetName=function()return 'ChatFrame1EditBox' end,GetText=function()return '' end,ClearFocus=function()focus=nil end}
tick();assert(ControllerForever.RuleBar.state.bindingHold and currentMap.PAD1,'window did not acquire input')
assert(currentMap.F8==nil and currentMap.F9==nil,'voice/chat rear buttons intercepted')
N.press('RIGHT');N.press('A');assert(selected[1]=='Repair','right did not choose adjacent enabled button')
N.press('DOWN');N.press('A');assert(selected[2]=='Bank','hidden button was navigated')
assert(vendor.scripts.OnClick==original,'native script changed')
local extra=button('Dynamic',250,200);tick();N.press('RIGHT');N.press('A');assert(selected[3]=='Dynamic','dynamic choice missing')
focus={};tick();assert(not next(currentMap) and not ControllerForever.RuleBar.state.bindingHold,'chat focus did not release navigation')
N.press('A');assert(#selected==3,'navigation acted while chat focused')
focus=nil;tick();gamepad=false;tick();assert(not next(currentMap),'mouse mode retains controller claim')
gamepad=true;tick();GameMenuFrame=CreateFrame('Frame','GameMenuFrame',UIParent);tick();assert(not ControllerForever.RuleBar.state.bindingHold,'game menu leaves our hold stuck')
GameMenuFrame.hidden=true;tick();combat=true;driver.scripts.OnEvent(driver,'PLAYER_REGEN_DISABLED');assert(not next(currentMap),'combat retained window claim')
N.press('A');assert(#selected==3,'guide changed in combat')
combat=false;driver.scripts.OnEvent(driver,'PLAYER_REGEN_ENABLED');tick();N.press('B');assert(LorewardDirectionsWindow.hidden and not next(currentMap) and not ControllerForever.RuleBar.state.bindingHold,'B did not return control')
LorewardDirectionsWindow:Show();tick();ControllerForever.Menu.state.open=true;tick();assert(ControllerForever.RuleBar.state.bindingHold,'native menu hold was cleared')
ControllerForever.Menu.state.open=false;ControllerForever.RuleBar.state.bindingHold=false;tick();LorewardDirectionsWindow:Hide();assert(not next(currentMap),'hide did not release immediately')
tick();focus={GetName=function()return 'ChatFrame1EditBox' end,GetText=function()return 'Unsent draft' end,ClearFocus=function()error('draft focus stolen')end}
LorewardDirectionsWindow:Show();tick();assert(not next(currentMap),'draft interrupted on window open')
local root=LorewardDirectionsWindow
root.buttons={vendor,repair,bank};vendor.section='supplies';repair.section='supplies';bank.section='travel'
root.headers={CreateFrame('Frame'),CreateFrame('Frame')};root.about=CreateFrame('Frame');root.result=CreateFrame('Frame')
root.close=button('Close',0,0);root.again=button('Again',0,0)
N.layout(root)
assert(root.w==960 and root.h>=450,'service workspace not widened')
assert(vendor.w==192 and vendor.h==30 and vendor.point[4]==24,'service controls not comfortably sized')
assert(repair.point[4]==224 and bank.point[5]<vendor.point[5],'service groups lost spatial organization')
assert(root.result.w==268 and root.foreverRouteScroll.frame.point[4]==638,'route does not have its own clipped reading column')
assert(vendor.scripts.OnClick==original,'layout replaced a service action')
print('Journey navigation passed: spatial choices, dynamic controls, native actions, chat/mouse/menu/combat handoff, rear-key preservation and close lifecycle.')
function M:GetName()return self.name end
function M:GetRegions()return unpack(self.regions or {})end
function M:GetStringHeight()return self.fontSize or 15 end
function M:SetShown(v)self.hidden=not v end
function M:CreateFontString()local f=CreateFrame('FontString');self.regions=self.regions or {};table.insert(self.regions,f);return f end
focus=nil;LorewardDirectionsWindow:Hide();tick()
local setup=CreateFrame('Frame','LorewardSetupBox',UIParent)
setup.title=setup:CreateFontString();setup.intro=setup:CreateFontString();setup.where=setup:CreateFontString()
local oldHeader=setup:CreateFontString();oldHeader:SetText('Original header')
setup.start=CreateFrame('Button',nil,setup);setup.start.label='Start';setup.start:SetScript('OnClick',function()error('test must not apply preferences')end)
setup.notNow=CreateFrame('Button',nil,setup);setup.notNow.label='Not now';setup.notNow:SetScript('OnClick',function()setup:Hide()end)
local choice=CreateFrame('CheckButton',nil,setup);choice.x=100;choice.y=500
local picked=0;local choose=function()picked=picked+1 end;choice:SetScript('OnClick',choose)
local row={button=choice,label=setup:CreateFontString(),note=setup:CreateFontString(),group='quests',text='Read quests'}
setup.rows={row}
N.layout(setup);assert(setup.w==960 and oldHeader.hidden,'preferences did not replace narrow layout')
assert(row.label.w==398 and row.label.fontSize==15 and not row.label.hidden,'choice text is not readable')
assert(choice.foreverJourneyFocusWidth==432 and choice.scripts.OnClick==choose,'choice action changed')
tick();N.press('A');assert(picked==1,'check button cannot be activated')
N.press('B');assert(setup.hidden and not next(currentMap),'setup B failed to release')
LorewardDirectionsWindow:Show();tick();assert(currentMap.PAD1,'service navigation did not resume after preferences')
setup:Show();tick();assert(currentMap.PAD1,'higher dialog failed to take navigation')
N.press('B');tick();assert(currentMap.PAD1,'underlying directions did not resume after dialog')
LorewardDirectionsWindow:Hide();tick();assert(not next(currentMap),'multi-window close leaked navigation')
print('Journey preferences passed: readable reflow, original choice actions, checkbox activation, dialog priority and return to underlying window.')
function M:GetScrollChild()return self.content end
function M:SetMinMaxValues(lo,hi)self.lo=lo;self.hi=hi end
function M:GetMinMaxValues()return self.lo or 0,self.hi or 0 end
function M:GetValue()return self.value or 0 end
function M:SetValue(v)self.value=v;if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v)end end
function M:SetVerticalScroll(v)self.scrollValue=v end
local planner=CreateFrame('Frame','LorewardPlanWindow',UIParent)
local sc=CreateFrame('ScrollFrame',nil,planner);local bar=CreateFrame('Slider',nil,planner)
local content=CreateFrame('Frame',nil,sc);sc.content=content
bar:SetScript('OnValueChanged',function(_,v)sc:SetVerticalScroll(v)end)
planner.about=planner:CreateFontString();planner.party=planner:CreateFontString();planner.status=planner:CreateFontString()
planner.close=CreateFrame('Button',nil,planner);planner.again=CreateFrame('Button',nil,planner)
planner.blocks={}
for i=1,12 do
 local b={button=CreateFrame('Button',nil,content),label=content:CreateFontString(),detail=content:CreateFontString()}
 b.label:SetText('Guide '..i);b.button:SetScript('OnClick',function()error('paging activated a guide')end)
 planner.blocks[i]=b
end
N.layout(planner)
assert(planner.w==960 and planner.h==580,'planner workspace dimensions')
assert(planner.blocks[1].button.w==84 and planner.blocks[1].label.fontSize==17,'planner cards not readable')
assert(planner.blocks[2].button.point[4]>planner.blocks[1].button.point[4],'planner not two columns')
assert(planner.blocks[3].button.point[5]<planner.blocks[1].button.point[5],'planner rows lost order')
assert(bar.hi>0 and planner.foreverJourneyScroll,'long planner is not scrollable')
function sc:GetTop()return 500 end
function sc:GetBottom()return 100 end
local target=planner.blocks[10].button
function target:GetTop()return 30+bar:GetValue() end
bar:SetMinMaxValues(0,1000);bar:SetValue(0)
N.reveal(planner,target);assert(bar:GetValue()>0,'below-screen focus not revealed')
local value=bar:GetValue();N.reveal(planner,target);assert(bar:GetValue()==value,'reveal does not settle')
bar:SetValue(900);N.reveal(planner,target);assert(bar:GetValue()<900,'above-screen focus not revealed')
N.reveal(planner,nil)
planner:Hide()
print('Journey lists passed: readable two-column planner, ordered cards, native action preservation, bounded scrolling and settled focus reveal.')
local find=CreateFrame('Frame','LorewardFindWindow',UIParent)
local fs=CreateFrame('ScrollFrame',nil,find);local fb=CreateFrame('Slider',nil,find);local fc=CreateFrame('Frame',nil,fs);fs.content=fc
find.about=find:CreateFontString();find.searchLabel=find:CreateFontString();find.edit=CreateFrame('EditBox',nil,find);find.count=find:CreateFontString()
find.close=CreateFrame('Button',nil,find);find.all=CreateFrame('Button',nil,find)
local title=fc:CreateFontString();title:SetPoint('TOPLEFT',fc,'TOPLEFT',0,-2);title:SetText('Quest title')
local line={button=CreateFrame('Button',nil,fc),text=fc:CreateFontString(),target={title='Quest title'}}
line.button:SetPoint('TOPLEFT',fc,'TOPLEFT',0,-24);line.text:SetText('Guide destination')
local action=function()error('layout activated quest')end;line.button:SetScript('OnClick',action)
find.titles={title};find.lines={line};find.notes={}
N.layout(find);assert(find.w==960 and line.text.fontSize==16 and title.fontSize==18,'quest list text not enlarged')
assert(line.button.point[5]<title.point[5] and line.button.scripts.OnClick==action,'quest list lost title/action association')
local firstY=line.button.point[5];N.layout(find);assert(line.button.point[5]==firstY,'quest list drifts across layout ticks')
find:Hide()
local nextBox=CreateFrame('Frame','LorewardWhereNextBox',UIParent)
nextBox.intro=nextBox:CreateFontString();nextBox.footer=nextBox:CreateFontString();nextBox.close=CreateFrame('Button',nil,nextBox)
local nb=CreateFrame('Button',nil,nextBox);local note=nextBox:CreateFontString();nextBox.rows={{button=nb,note=note,option={}}}
N.layout(nextBox);assert(nextBox.w==960 and nb.w==340 and note.w==540,'chapter choices not reflowed')
nextBox:Hide()
print('Journey quest/chapter layouts passed: original action identity, quest/title association, stable repeated layout and readable choice notes.')
function M:GetFrameLevel()return self.level or 1 end
planner:Show();find:Show();planner.level=20;find.level=10
assert(N.front()==planner,'input does not follow raised planner')
find.level=30;assert(N.front()==find,'input does not follow raised quest browser')
function setup:GetFrameStrata()return 'DIALOG' end
setup:Show();assert(N.front()==setup,'dialog must override lower workspace')
setup:Hide();find:Hide();planner:Hide()
print('Journey focus order passed: actual strata and frame level determine the visible input owner.')
function M:SetFocus()focus=self;if self.hooks.OnEditFocusGained then self.hooks.OnEditFocusGained(self)end end
function M:HasFocus()return focus==self end
function M:ClearFocus()if focus==self then focus=nil end end
local draft=CreateFrame('EditBox','ChatFrame1EditBox',UIParent);draft:SetText('Unsent private draft')
find.edit:SetText('Existing filter')
find.all:SetScript('OnClick',function()find.edit:SetText('');find.edit:ClearFocus()end)
function fs:GetTop()return 500 end
function fs:GetBottom()return 100 end
function line.button:GetTop()return 400 end
function title:GetTop()return 425 end
line.button.y=400;line.button.x=100
find:Show();tick();N.press('X');assert(focus==find.edit,'X does not focus search')
tick();assert(currentMap.PAD1 and ControllerForever.RuleBar.state.bindingHold,'search released controller ownership')
assert(draft:GetText()=='Unsent private draft','opening search altered chat draft')
N.press('X');assert(find.edit:GetText()=='' and focus==find.edit,'clear search failed to refresh/focus')
find.edit:SetText('Shadowvale');N.press('A');assert(not focus and not find.hidden and find.edit:GetText()=='Shadowvale','A did not finish search without opening guide')
N.press('X');N.press('B');assert(not focus and not find.hidden,'B in search closes entire window')
N.press('Y');assert(find.edit:GetText()=='','Y did not clear filter')
assert(draft:GetText()=='Unsent private draft','search workflow altered chat draft')
N.press('B');assert(find.hidden and not next(currentMap),'search window close retained input')
print('Journey search passed: focused dictation target, controller ownership, A/B finish, clear filtering, draft preservation and window exit.')
local adds,commands=0,{}
ControllerForever.Menu.pages={}
ControllerForever.Menu.opt=function(row)return row end
ControllerForever.Menu.addHomeRow=function(row,at)adds=adds+1;assert(row.page=='foreverjourney' and at==2)end
SlashCmdList.LOREWARD=function(command)commands[#commands+1]=command end
assert(N.attachMenu() and N.attachMenu() and adds==1,'Journey menu not installed exactly once')
local rows=ControllerForever.Menu.pages.foreverjourney.entries
assert(#rows==11 and rows[11].back,'Journey menu lacks actions/back')
rows[2].activate();rows[3].activate();assert(commands[1]=='nearest' and commands[2]=='find','menu action routing incorrect')
combat=true;rows[2].activate();assert(#commands==2,'menu navigation activated in combat');combat=false
print('Journey controller-menu integration passed: public menu API, single registration, native commands and combat guard.')

local storyOpened=0
ForeverHandheldStory={open=function()storyOpened=storyOpened+1 end}
rows[7].activate();assert(storyOpened==1,'Story journal not reachable from native menu')
local story=CreateFrame('Frame','ForeverHandheldStoryReader',UIParent)
local close=CreateFrame('Button',nil,story);close:SetScript('OnClick',function()story:Hide()end)
focus=nil;tick();assert(currentMap.PAD1,'Story reader did not acquire controller focus')
N.press('B');assert(story.hidden and not next(currentMap),'Story reader failed to return control')
local community=CreateFrame('Frame','LorewardDiscordBox',UIParent)
community.about=community:CreateFontString();community.edit=CreateFrame('EditBox',nil,community)
community.hint=community:CreateFontString();community.close=CreateFrame('Button',nil,community)
community.edit:SetText('https://discord.gg/tFDavRQXAj')
function community:CreateTexture()return CreateFrame('Texture',nil,self)end
local closed=0;local nativeClose=function()closed=closed+1;community:Hide()end
community.close:SetScript('OnClick',nativeClose)
N.layout(community)
assert(community.w==780 and community.about.fontSize==18 and not community.foreverCommunityQR.hidden,'community layout or QR missing')
assert(community.close.scripts.OnClick==nativeClose,'community native close handler replaced')
community.edit:SetFocus();tick();assert(not focus and currentMap.PAD1,'readonly community field stole controller navigation')
N.press('A');assert(closed==1 and community.hidden and not next(currentMap),'community cannot close through controller action')
community:Show();community.edit:SetText('https://example.com/changed');N.layout(community)
assert(community.foreverCommunityQR.hidden,'stale QR destination must not remain visible')
community:Hide();tick()
rows[10].activate();assert(commands[#commands]=='discord','native menu cannot open community')
print('Community contracts passed: readable QR presentation, destination mismatch guard, readonly focus handoff and original close action.')

-- Long directions stay inside their reading column and scroll independently
-- of the selected service. A fresh answer starts at its beginning.
for _,name in ipairs({'LorewardSetupBox','LorewardWhereNextBox','LorewardFindWindow','LorewardPlanWindow','ForeverHandheldStoryReader','LorewardDiscordBox'})do
 if _G[name] then _G[name]:Hide()end
end
focus=nil;root:Show();local nativeResult=root.result
local routeHeight=1100
nativeResult.GetStringHeight=function()return routeHeight end
nativeResult:SetText('Long service route, with several walking and flight legs.')
N.layout(root);tick()
local info=root.foreverRouteScroll
assert(info==root.foreverJourneyScroll and not info.bar.hidden,'long route lacks visible scrollbar')
assert(info.content.h==1124 and info.frame.h<info.content.h,'route clipping extent incorrect')
assert(currentMap.PADLSHOULDER and currentMap.PADRSHOULDER,'route paging has no controller bindings')
local pickedBefore=#selected
N.press('PAGEDOWN');assert(info.bar.value>0 and info.frame.scrollValue==info.bar.value,'RB did not scroll route')
local offset=info.bar.value;local frameCount=#frames
N.layout(root);assert(info.bar.value==offset and #frames==frameCount,'layout resets reading position or leaks frames')
N.press('A');assert(#selected==pickedBefore+1 and selected[#selected]=='Vendor','route paging changed selected service')
N.press('PAGEUP');assert(info.bar.value==0,'LB did not return to route start')
for i=1,12 do N.press('PAGEDOWN')end
assert(info.bar.value==info.bar.hi,'route paging exceeded bottom')
combat=true;N.press('PAGEUP');assert(info.bar.value==info.bar.hi,'route navigation acted during combat');combat=false
nativeResult:SetText('A different long answer.');N.layout(root);assert(info.bar.value==0,'new result retains stale offset')
routeHeight=30;N.layout(root);assert(info.bar.hidden and info.bar.value==0 and info.content.h==info.frame.h,'short result leaves stale scrolling')
assert(root.result==nativeResult and vendor.scripts.OnClick==original,'route layout replaced owner result or action')
N.press('B');assert(root.hidden and not next(currentMap),'route workspace close retained controls')
print('Service route contracts passed: bounded long text, controller paging, stable focus/offset, changed-answer reset, no frame growth, combat/exit release and unchanged owner action.')
root:Show();tick();local count=#selected
repair:Click();tick();N.press('A')
assert(#selected==count+2 and selected[#selected]=='Repair','mouse click and subsequent controller A target different actions')
local clickHook=repair.hooks.OnClick;tick();tick();assert(repair.hooks.OnClick==clickHook,'click tracking installs repeated hooks')
N.press('B');assert(root.hidden and not next(currentMap),'mixed input close retained ownership')
assert(vendor.scripts.OnClick==original,'focus tracking replaced native OnClick')
print('Journey mixed-input contract passed: mouse activation updates controller selection without replacing scripts or duplicating hooks.')

-- Returning from a route map restores the selected stop, and the native map
-- owns navigation while visible even if another addon leaves the route shown.
for _,f in ipairs({LorewardSetupBox,LorewardFindWindow,LorewardPlanWindow,LorewardWhereNextBox,LorewardDiscordBox,ForeverHandheldStoryReader})do if f then f:Hide()end end
focus=nil;gamepad=true;combat=false;LorewardDirectionsWindow:Hide();tick()
LorewardDirectionsWindow.foreverJourneyResumeChoice=repair;LorewardDirectionsWindow:Show();tick()
local before=#selected;N.press('A');assert(selected[before+1]=='Repair','map return lost selected control')
WorldMapFrame=CreateFrame('Frame','WorldMapFrame',UIParent);tick();assert(not next(currentMap),'Journey intercepted native map controls')
WorldMapFrame:Hide();tick();assert(currentMap.PAD1,'Journey failed to reclaim after map close')
print('Journey map handoff passed: remembered selection and native map input priority.')

local rareOpened=0
ForeverHandheldRareReader={open=function()rareOpened=rareOpened+1 end}
rows[8].activate();assert(rareOpened==1 and rows[8].name=='Rare loot','Rare reader not reachable')
local rare=CreateFrame('Frame','ForeverHandheldRareReaderWindow',UIParent)
local rb=CreateFrame('Button',nil,rare);rb:SetScript('OnClick',function()rare:Hide()end)
for _,name in ipairs({'LorewardSetupBox','LorewardWhereNextBox','LorewardFindWindow','LorewardPlanWindow','ForeverHandheldStoryReader','LorewardDiscordBox','ForeverHandheldJourneyNoticeWindow','LorewardDirectionsWindow'})do if _G[name] then _G[name]:Hide()end end
focus=nil;tick();assert(currentMap.PAD1 and currentMap.PAD2 and currentMap.PADLSHOULDER,'Rare reader lacks native window controls')
N.press('B');assert(rare.hidden and not next(currentMap),'Rare reader close retained bindings')
print('Rare reader menu, shared controller claim, shoulder paging and B release passed.')

local fieldOpened=0;ForeverHandheldFieldReader={open=function()fieldOpened=fieldOpened+1 end}
rows[9].activate();assert(fieldOpened==1 and rows[9].name=='Field notes','Field reader missing from Journey')
local field=CreateFrame('Frame','ForeverHandheldFieldReaderWindow',UIParent)
local close=CreateFrame('Button',nil,field);close:SetScript('OnClick',function()field:Hide()end)
local sc=CreateFrame('ScrollFrame',nil,field);sc:SetHeight(300)
local bar=CreateFrame('Slider',nil,field);bar:SetMinMaxValues(0,900);bar:SetValue(0)
field.foreverJourneyScroll={frame=sc,bar=bar,content=CreateFrame('Frame',nil,sc),label='Read'}
tick();assert(currentMap.PADLSHOULDER and currentMap.PADRSHOULDER and currentMap.PAD2,'Field notes has no controller paging/back')
N.press('PAGEDOWN');assert(bar:GetValue()==240,'Field reader RB page failed')
N.press('PAGEUP');assert(bar:GetValue()==0,'Field reader LB page failed')
N.press('B');assert(field.hidden and not next(currentMap),'Field reader B retained claim')
print('PASS: Field notes native-menu action, shared LB/RB paging and B input release')

UIParent:SetSize(1280,800)
local loaded={}
local list={}
for i=1,20 do
 list[i]={text='Guide '..i,arg1='Pack',arg2='Guide '..i,func=function(_,group,name)loaded[#loaded+1]=group..' / '..name end}
end
RXP={currentGuide={group='Pack',name='Guide 1'},CloseMenu=function()end,GetGuideName=function(g)return g.name end}
RXPFrame={GenerateMenuTable=function(_,menu)
 menu[1]={text='Empty',menuList={{text='Disabled',isTitle=true}}}
 menu[2]={text='Settings',func=function()error('settings mixed into guide choices')end}
 menu[3]={text='Pack',menuList=list}
 return menu
end}
assert(rows[1].name=='RestedXP guides' and rows[1].activate==SlashCmdList.FOREVERHANDHELDGUIDES,'missing menu or macro entry point')
rows[1].activate();tick()
local picker=ForeverHandheldRestedXPWindow
assert(currentMap.PAD1 and picker.rows[1].label:GetText()=='Pack' and picker.rows[2].hidden,'guide catalog included empty or unrelated rows')
for i,button in ipairs(picker.rows)do button.x=100;button.y=500-i*41 end
N.press('A');assert(picker.rows[1].status:GetText()=='Loaded','current guide state missing')
N.press('PAGEDOWN');assert(picker.rows[1].label:GetText()=='Guide 10','RB did not page')
N.press('B');assert(picker.rows[1].label:GetText()=='Pack' and currentMap.PAD1,'B did not return to the pack list')
N.press('A');N.press('PAGEDOWN');N.press('DOWN');N.press('A')
assert(loaded[1]=='Pack / Guide 11' and picker.hidden and not next(currentMap),'guide callback or input release failed')
SlashCmdList.FOREVERHANDHELDGUIDES();tick()
local frameCount=#frames
for _=1,10 do tick() end
assert(#frames==frameCount,'picker allocates idle frames')
combat=true;driver.scripts.OnEvent(driver,'PLAYER_REGEN_DISABLED')
assert(picker.hidden and not next(currentMap),'picker retained its combat claim')
N.openGuides();assert(picker.hidden,'picker opened during combat')
print('RestedXP picker passed: macro and Journey entry, filtering, current guide, paging, back, original callback and combat handoff.')
