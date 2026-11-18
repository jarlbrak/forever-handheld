-- Contract: visual styling cannot drive native window/controller behavior.
local objects,driver={},nil
local now,combat=10,false
local M={}
function M:GetName()return self.name end
function M:IsObjectType(t)return self.kind==t end
function M:IsForbidden()return false end
function M:IsVisible()return not self.hidden end
function M:IsShown()return not self.hidden end
function M:GetLeft()return self.left or 0 end
function M:GetRight()return self.right or 200 end
function M:GetTop()return self.top or 100 end
function M:GetBottom()return self.bottom or 0 end
function M:GetAlpha()return self.alpha or 1 end
function M:GetFrameStrata()return self.strata or 'MEDIUM' end
function M:GetFrameLevel()return self.level or 10 end
function M:GetRegions()return unpack(self.regions or {})end
function M:GetChildren()return unpack(self.children or {})end
function M:GetSize()return self.w or 200,self.h or 100 end
function M:GetTexture()return self.file end
function M:GetAtlas()return self.atlas end
function M:GetDrawLayer()return self.layer or 'BACKGROUND' end
function M:GetTextColor()return unpack(self.color or {1,1,1})end
function M:SetColorTexture(...)self.color={...}end
function M:SetTextColor(...)self.color={...}end
function M:SetBackdropColor(...)self.backdropColor={...}end
function M:SetBackdropBorderColor(...)self.backdropBorderColor={...}end
function M:SetAlpha(a)self.alpha=a;self.shellWrites=(self.shellWrites or 0)+1 end
function M:SetFrameLevel(v)assert(not self.native);self.level=v;self.shellWrites=(self.shellWrites or 0)+1 end
function M:SetFrameStrata(v)assert(not self.native);self.strata=v;self.shellWrites=(self.shellWrites or 0)+1 end
function M:SetScript(event,fn)assert(not self.native);self[event]=fn end
function M:RegisterEvent()assert(not self.native)end
function M:SetShown(shown)assert(not self.native);self.hidden=not shown;self.shellWrites=(self.shellWrites or 0)+1 end
function M:SetAllPoints(frame)assert(not self.native);self.anchor=frame end
local function obj(kind,name,native)
 local f=setmetatable({kind=kind,name=name,native=native},{__index=function(t,k)
   if M[k] then return M[k] end
   if k:match('^Set') or k:match('^Enable') or k=='Show' or k=='Hide' then
     return function(self,...)assert(not self.native,'native behavior changed: '..k)end
   end
 end})
 objects[#objects+1]=f;return f
end
function M:CreateTexture(_,layer)local t=obj('Texture');t.layer=layer;return t end
function CreateFrame(_,name,parent)
 local f=obj('Frame',name);driver=driver or f;f.parent=parent
 if parent then parent.children=parent.children or {};table.insert(parent.children,f)end
 return f
end
function GetTime()return now end
function InCombatLockdown()return combat end
UIParent=obj('Frame','UIParent')
ColorPickerFrame=obj('Frame','ColorPickerFrame',true)
ColorPickerFrame.Content=obj('Frame',nil,true)
local swatch=obj('Texture',nil,true);swatch.atlas='colorpicker-background-checkerboard'
local gradient=obj('Texture',nil,true);gradient.file='colorpicker-value-background'
ColorPickerFrame.Content.regions={swatch,gradient}
ColorPickerFrame.children={ColorPickerFrame.Content}
ColorPickerFrame.Header=obj('Frame',nil,true)
local colorHeader=obj('Texture',nil,true);ColorPickerFrame.Header.regions={colorHeader}
local colorAction=function()error('color action must not be invoked by styling')end
ColorPickerFrame.OnClick=colorAction
ProfessionsFrame=obj('Frame','ProfessionsFrame',true)
local stone=obj('Texture',nil,true);stone.atlas='Profession-Background-Template2'
local spell=obj('Texture',nil,true);spell.file='Interface/Icons/Spell_Holy_FlashHeal'
local map=obj('Texture',nil,true);map.atlas='WorldMap-Background'
local gold=obj('FontString',nil,true);gold.color={1,.82,0}
local black=obj('FontString',nil,true);black.color={0,0,0}
-- Explicitly allowed region-only paint operations.
M.SetDesaturated=function(self,v)self.desaturated=v end;M.SetVertexColor=function()end;M.SetShadowColor=function()end;M.SetShadowOffset=function()end
ProfessionsFrame.regions={stone,spell,map,gold,black}
ProfessionsFrame.NineSlice=obj('Frame',nil,true)
local edge=obj('Texture',nil,true);ProfessionsFrame.NineSlice.regions={edge}
local originalPairs=pairs
function pairs(t)assert(t~=_G,'full-global polling causes measured frame stalls');return originalPairs(t)end
local populated=function()end
Menu={PopulateDescription=populated,GetManager=function()return {GetOpenMenu=function()end}end}
local menuHook
function hooksecurefunc(owner,key,fn)assert(owner==Menu and key=='PopulateDescription');menuHook=fn end
dofile(arg[1])
ControllerForeverDB={winLook='dark',winColor='silver',winBackground=90}
driver.OnEvent(driver,'PLAYER_LOGIN')
assert(ControllerForeverDB.winColor=='cf' and ControllerForeverDB.winLook=='dark','CF palette not integrated')
assert(ForeverHandheldDB.windowPaletteBefore.color=='silver','previous palette not preserved')
ControllerForeverDB.winColor='blue';driver.OnEvent(driver,'PLAYER_LOGIN')
assert(ControllerForeverDB.winColor=='blue','palette reapplied after migration')
driver.OnUpdate(driver,.3)
assert(not ForeverHandheldDB.windowThemeError,ForeverHandheldDB.windowThemeError)
assert(stone.color and stone.color[1]==.025,'background not themed')
assert(not spell.color and not map.color,'native icon/map changed')
assert(edge.alpha==0,'old chrome not suppressed')
assert(black.color[1]==.94 and gold.color[1]==1,'text contrast/quality color changed')
assert(ForeverHandheldDB.windowTheme.seen.ProfessionsFrame,'coverage not recorded')
assert(ForeverHandheldDB.windowTheme.seen.ColorPickerFrame,'color dialog missing shared finish')
assert(not swatch.color and not gradient.color and colorHeader.alpha==0,'native color data altered or old header art retained')
assert(ColorPickerFrame.OnClick==colorAction,'color picker action replaced')
ColorPickerFrame.hidden=true
stone.color=nil;combat=true;now=20;driver.OnUpdate(driver,.3)
assert(not stone.color,'paint ran in combat')
ProfessionsFrame.hidden=true;driver.OnUpdate(driver,.3)
for _,f in ipairs(objects) do
 if f.kind=='Frame' and f.parent==UIParent and f.anchor==ProfessionsFrame then
   assert(f.hidden,'window background lingered after a combat closure')
 end
end
combat=false;ProfessionsFrame.hidden=false
ForeverHandheldFieldNotes=obj('Frame','ForeverHandheldFieldNotes')
ForeverHandheldFieldNotes.left=150;ForeverHandheldFieldNotes.right=392
driver.OnUpdate(driver,.3)
assert(ForeverHandheldFieldNotes.alpha==0,'inspection card overlapped an open panel')
function ProfessionsFrame:GetEffectiveScale()return self.scale or 1 end
function ForeverHandheldFieldNotes:GetEffectiveScale()return self.scale or 1 end
ProfessionsFrame.scale=.5;driver.OnUpdate(driver,.3)
assert(ForeverHandheldFieldNotes.alpha==1,'scaled compact panel falsely covered the rail')
ForeverHandheldFieldNotes.scale=.5;driver.OnUpdate(driver,.3)
assert(ForeverHandheldFieldNotes.alpha==0,'equal-scale real overlap missed')
ProfessionsFrame.scale=1;ForeverHandheldFieldNotes.scale=1
ProfessionsFrame.hidden=true;driver.OnUpdate(driver,.3)
assert(ForeverHandheldFieldNotes.alpha==1,'inspection card did not return')
ProfessionsFrame.hidden=false;ForeverHandheldWorkbench={};stone.h=450
local rank=obj('Frame',nil,true);local fill=obj('Texture',nil,true)
fill.atlas='Profession-ProgressBar-Fill';fill.w=440;fill.h=180;rank.regions={fill}
ProfessionsFrame.RankBar=rank;table.insert(ProfessionsFrame.children,rank)
for i=1,3 do
 now=now+2;driver.OnUpdate(driver,.3)
 assert(stone.color[4]==0,'shared painter covered the custom workbench')
 assert(not fill.color,'native rank fill was erased with the backdrop')
 assert(not spell.color and not map.color,'native artwork changed during workbench painting')
end
-- Circular honor meters use large translucent Background textures. Painting
-- those opaque hides the title and rank; preserve the entire meter subtree.
local meter=obj('Cooldown',nil,true)
local backdrop=obj('Texture',nil,true);backdrop.atlas='UI-Character-Info-Honor-Bar-BG-Glow'
meter.Background=backdrop;meter.regions={backdrop};table.insert(ProfessionsFrame.children,meter)
now=now+2;driver.OnUpdate(driver,.3)
assert(not backdrop.color,'honor meter transparency was replaced')
ClassTrainerFrame=obj('Frame','ClassTrainerFrame',true)
local trainerBG=obj('Texture',nil,true);trainerBG.file=12345
ClassTrainerFrame.BG=trainerBG;ClassTrainerFrame.regions={trainerBG}
local recipe=obj('Button',nil,true)
recipe.icon=obj('Texture',nil,true);recipe.selectedTex=obj('Texture',nil,true);recipe.disabledBG=obj('Texture',nil,true)
local function trainerLabel(size)
 local label=obj('FontString',nil,true)
 label.font={'Font',size,''}
 function label:GetFont()return unpack(self.font)end
 function label:SetFont(...)self.font={...}end
 function label:SetHeight(value)self.h=value end
 return label
end
recipe.name=trainerLabel(12);recipe.subText=trainerLabel(10)
recipe.GetName=function()return nil end
recipe.GetWidth=function()return 298 end
function recipe.name:GetNumPoints()return self.anchor and 1 or 2 end
function recipe.name:GetPoint()return unpack(self.anchor or {}) end
function recipe.name:ClearAllPoints()self.anchor=nil end
function recipe.name:SetPoint(...)self.anchor={...}end
function recipe.name:GetWidth()return self.w or 75 end
function recipe.name:SetWidth(width)self.w=width end
function recipe.name:GetHeight()return self.h or 12 end
function recipe.name:GetUnboundedStringWidth()return self.font[2]*(self.lengthFactor or 7)end
ClassTrainerStatusBar=obj('StatusBar','ClassTrainerStatusBar',true)
ClassTrainerStatusBar.rankText=trainerLabel(10)
function ClassTrainerStatusBar:SetStatusBarColor(...)self.fill={...}end
ClassTrainerStatusBarBackground=obj('Texture','ClassTrainerStatusBarBackground',true)
local normal=obj('Texture',nil,true);normal.file=12345
recipe.GetNormalTexture=function()return normal end;recipe.regions={recipe.icon,recipe.selectedTex,recipe.disabledBG,normal}
ClassTrainerFrame.children={recipe};UIPanelWindows={ClassTrainerFrame={}}
now=now+4;driver.OnUpdate(driver,.3)
assert(trainerBG.color and trainerBG.color[1]==.025,'trainer empty-list parchment not replaced')
assert(normal.desaturated and not recipe.icon.desaturated and not recipe.selectedTex.color and not recipe.disabledBG.color,'trainer item/selection/availability art changed')
assert(recipe.name.font[2]==16 and recipe.name.h==18 and recipe.subText.font[2]==13,'trainer labels remain hard to read')
assert(recipe.name.w==170 and recipe.name.anchor[2]==recipe.icon,'trainer name clips or overlaps its price')
assert(ClassTrainerStatusBar.rankText.font[2]==14 and ClassTrainerStatusBar.fill[1]==.65 and ClassTrainerStatusBarBackground.color[1]==.14,'trainer skill rank lost its presentation')
recipe.name.lengthFactor=11
now=now+2;driver.OnUpdate(driver,.3)
assert(recipe.name.font[2]==15,'a long recycled recipe did not fit the name column')
recipe.name.lengthFactor=7
now=now+2;driver.OnUpdate(driver,.3)
assert(recipe.name.font[2]==16,'a short recycled recipe did not recover the larger text')
ClassTrainerFrame.hidden=true
MailFrame=obj('Frame','MailFrame',true)
InboxFrameBg=obj('Texture','InboxFrameBg',true);InboxFrameBg.w=512;InboxFrameBg.h=512
SendStationeryBackgroundLeft=obj('Texture','SendStationeryBackgroundLeft',true)
SendMailBodyEditBox=obj('EditBox','SendMailBodyEditBox',true)
local mailRow=obj('Frame','MailItem1',true);local mailBorder=obj('Texture',nil,true)
local mailButton=obj('Button',nil,true);local mailIcon=obj('Texture',nil,true);mailIcon.layer='ARTWORK'
mailButton.OnClick=function()error('mail collection invoked')end;local mailAction=mailButton.OnClick
mailButton.regions={mailIcon};mailRow.regions={mailBorder};mailRow.children={mailButton};MailFrame.children={mailRow}
now=now+2;driver.OnUpdate(driver,.3)
assert(InboxFrameBg.color and InboxFrameBg.color[4]==0 and InboxFrameBg.w==512,'mail parchment padding became opaque')
assert(SendStationeryBackgroundLeft.color[4]==0 and SendMailBodyEditBox.color[1]==.94,'mail composition contrast')
assert(mailBorder.desaturated and not mailIcon.desaturated and mailButton.OnClick==mailAction,'mail item/action contract')
MailFrame.hidden=true
local reads=0
local original=ProfessionsFrame.GetSize
ProfessionsFrame.GetSize=function(self)reads=reads+1;return original(self)end
UIPanelWindows={ProfessionsFrame={}}
ForeverHandheldPanels={roots={[ProfessionsFrame]=true}}
now=now+4;driver.OnUpdate(driver,.3)
assert(reads==1,'registered window visited more than once per tick')
local shop=obj('Frame','ControllerForeverWin_shop',true)
ControllerForever={Kit={live={shop={frame=shop}}}}
now=now+1;driver.OnUpdate(driver,.3)
assert(ForeverHandheldDB.windowTheme.seen.ControllerForeverWin_shop,'late custom shop not discovered through its registry')
-- New menu proxies, including short nested menus, use supported lifecycle
-- notifications without replacing native responders or touching their layout.
local desc={}
function desc:AddMenuAcquiredCallback(fn)assert(not self.acquired);self.acquired=fn end
function desc:AddMenuReleasedCallback(fn)assert(not self.released);self.released=fn end
assert(menuHook and Menu.PopulateDescription==populated,'menu population handler replaced')
menuHook(nil,nil,desc);menuHook(nil,nil,desc)
local popup=obj('Frame',nil,true);popup.w=120;popup.h=28
local popupBorder=obj('Texture',nil,true);popup.NineSlice=obj('Frame',nil,true);popup.NineSlice.regions={popupBorder}
popup.OnClick=function()error('native popup action invoked')end
local handler=popup.OnClick
desc.acquired(popup);now=now+2;driver.OnUpdate(driver,.3)
assert(popupBorder.alpha==0 and popup.OnClick==handler,'short submenu chrome/navigation contract')
local popupBg
for _,f in ipairs(objects)do if f.kind=='Frame' and f.parent==UIParent and f.anchor==popup then popupBg=f end end
assert(popupBg and not popupBg.hidden,'short submenu background missing')
desc.released(popup);assert(popupBg.hidden and not popup.hidden,'release must hide only our paint immediately')
local allocated=#objects
for i=1,20 do desc.acquired(popup);now=now+2;driver.OnUpdate(driver,.3);desc.released(popup)end
assert(#objects==allocated,'pooled menu reuse leaks decoration frames')
popup.hidden=true
L_DropDownList1=obj('Frame','L_DropDownList1',true);L_DropDownList1.w=140;L_DropDownList1.h=28
local legacyBackdrop=obj('Frame',nil,true);local legacyBorder=obj('Texture',nil,true)
legacyBackdrop.regions={legacyBorder};L_DropDownList1.MenuBackdrop=legacyBackdrop
local legacyOption=obj('Button',nil,true);legacyOption.OnClick=function()error('legacy option invoked')end
local legacyAction=legacyOption.OnClick
L_DropDownList1.children={legacyBackdrop,legacyOption}
now=now+2;driver.OnUpdate(driver,.3)
assert(legacyBorder.alpha==0 and legacyOption.OnClick==legacyAction,'legacy menu chrome/navigation contract')
local legacyBg
for _,f in ipairs(objects)do if f.kind=='Frame' and f.parent==UIParent and f.anchor==L_DropDownList1 then legacyBg=f end end
assert(legacyBg and not legacyBg.hidden,'short legacy submenu missing')
L_DropDownList1.hidden=true;driver.OnUpdate(driver,.3)
assert(legacyBg.hidden,'legacy menu background lingered after native close')
shop.hidden=true
ProfessionsFrame.hidden=true
DressUpFrame=obj('Frame','DressUpFrame',true);DressUpFrame.SetSelectionPanel=false;DressUpFrame.left=0;DressUpFrame.right=100
local scene=obj('Texture',nil,true);scene.atlas='dressingroom-background-warrior'
DressUpFrame.regions={scene}
local detail=obj('Frame',nil,true);detail.left=150;detail.right=392
local ornament=obj('Texture',nil,true);ornament.atlas='dressingroom-sideframe';ornament.layer='OVERLAY'
local itemIcon=obj('Texture',nil,true);itemIcon.file='Interface/Icons/INV_Chest_Plate'
local quality=obj('Texture',nil,true);quality.atlas='loottoast-itemborder-green'
detail.regions={ornament,itemIcon,quality};DressUpFrame.CustomSetDetailsPanel=detail;DressUpFrame.children={detail}
now=now+2;driver.OnUpdate(driver,.3)
assert(ornament.alpha==0 and not scene.color and not itemIcon.color and not quality.color,'appearance chrome must not replace model or item artwork')
assert(ForeverHandheldFieldNotes.alpha==0,'attached appearance list must cover overlapping field notes')
detail.hidden=true;driver.OnUpdate(driver,.3)
assert(ForeverHandheldFieldNotes.alpha==1,'closing attached list restores unobstructed notes')
for _,f in ipairs(objects)do
 if f.kind=='Frame' and f.parent==UIParent and f.anchor==detail then assert(f.hidden,'attached background lingered after list closure')end
end
DressUpFrame.hidden=true
LorewardDirectionsWindow=obj('Frame','LorewardDirectionsWindow',true)
local loreAction=function()error('guide action invoked by paint')end
LorewardDirectionsWindow.OnClick=loreAction
now=now+2;driver.OnUpdate(driver,.3)
assert(LorewardDirectionsWindow.backdropColor[1]==.025,'Loreward background missed')
assert(LorewardDirectionsWindow.backdropBorderColor[4]==0,'Loreward ornamental border remained')
assert(LorewardDirectionsWindow.OnClick==loreAction,'Loreward behavior changed')
LorewardDirectionsWindow.hidden=true
SettingsPanel=obj('Frame','SettingsPanel',true)
SettingsPanel.GetSize=function()error('isolated unavailable window')end
ProfessionsFrame.hidden=true;driver.OnUpdate(driver,.3)
assert(ForeverHandheldDB.windowErrors.SettingsPanel,'per-window failure not recorded')
assert(ForeverHandheldFieldNotes.alpha==1,'broken window prevented other windows closing')
print('Window theme contracts passed: native behavior untouched; artwork/colors preserved; combat deferred.')
BankFrame=obj('Frame','BankFrame',true);BankFrame.alpha=1
ControllerForever.Kit.fades={}
now=now+2;driver.OnUpdate(driver,.3)
local bankDecor={}
for _,f in ipairs(objects)do if f.kind=='Frame' and f.anchor==BankFrame then bankDecor[#bankDecor+1]=f end end
assert(#bankDecor==2,'bank rim/background fixture missing')
ControllerForever.Kit.fades[BankFrame]={on=true};now=now+2;driver.OnUpdate(driver,.3)
for _,f in ipairs(bankDecor)do assert(f.hidden,'duplicate bank decoration remains visible through native fade')end
assert(not BankFrame.hidden and BankFrame.alpha==1,'bank session state changed')
ControllerForever.Kit.fades[BankFrame].on=false;now=now+2;driver.OnUpdate(driver,.3)
for _,f in ipairs(bankDecor)do assert(not f.hidden,'native bank decorations not restored')end
print('PASS: native replacement fade suppresses independent rim/background and restores on release')
-- Guild parchment shares a file with real guild heraldry: target only its BG.
InspectFrame=obj('Frame','InspectFrame',true)
InspectGuildFrame=obj('Frame','InspectGuildFrame',true)
InspectGuildFrameBG=obj('Texture','InspectGuildFrameBG',true)
local heraldry=obj('Texture','InspectGuildFrameBanner',true)
InspectGuildFrameBG.file='Interface/GuildFrame/GuildInspect-Parts';heraldry.file=InspectGuildFrameBG.file
InspectGuildFrame.regions={InspectGuildFrameBG,heraldry};InspectFrame.children={InspectGuildFrame}
now=now+2;driver.OnUpdate(driver,.3)
assert(InspectGuildFrameBG.color and InspectGuildFrameBG.color[1]==.025,'Inspect guild parchment unchanged')
assert(not heraldry.color and not heraldry.desaturated,'guild identity art recolored')
print('PASS: Inspect guild backdrop matches palette; native heraldry preserved.')
-- Match column backgrounds are short native textures, not score/team data.
for _,name in ipairs({'PVPMatchResults','PVPMatchScoreboard'})do
 local match=obj('Frame',name,true);_G[name]=match;UIPanelWindows[name]={}
 local strip=obj('Texture',nil,true);strip.atlas='UI-Character-Info-Stat-StoneBG3';strip.h=50
 local icon=obj('Texture',nil,true);icon.atlas='PVP-Horde';icon.w=32;icon.h=32
 local team=obj('FontString',nil,true);team.color={.9,.1,.1}
 match.regions={strip,icon,team};match.OnClick=colorAction
 now=now+4;driver.OnUpdate(driver,.3)
 assert(strip.color and strip.color[1]==.025,'short PvP column strip remained native stone')
 assert(not icon.color and team.color[1]==.9 and match.OnClick==colorAction,'PvP data or actions changed')
 match.hidden=true
end
print('PASS: both PvP match column strips themed; native icons, team colors and actions preserved.')
-- Readable native books preserve larger decorative headings and native content.
ItemTextFrame=obj('Frame','ItemTextFrame',true)
ItemTextPageText=obj('SimpleHTML','ItemTextPageText',true)
ItemTextFrame.children={ItemTextPageText}
local bookFonts={P={'Font',12,''},H1={'Fancy',48,''},H2={'Font',12,''},H3={'Font',12,''}}
local bookSpacing={P=0,H1=8,H2=0,H3=0};local writes,reflows=0,0
function ItemTextPageText:GetFont(tag)return unpack(bookFonts[tag])end
function ItemTextPageText:SetFont(tag,face,size,flags)bookFonts[tag]={face,size,flags};writes=writes+1 end
function ItemTextPageText:GetSpacing(tag)return bookSpacing[tag]end
function ItemTextPageText:SetSpacing(tag,value)bookSpacing[tag]=value;writes=writes+1 end
ItemTextScrollFrame={UpdateScrollChildRect=function()reflows=reflows+1 end}
now=now+2;driver.OnUpdate(driver,.3)
assert(bookFonts.P[2]==18 and bookFonts.H2[2]==21 and bookFonts.H3[2]==19,'native book text too small')
assert(bookFonts.H1[1]=='Fancy' and bookFonts.H1[2]==48 and bookSpacing.H1==8,'native larger heading was replaced')
assert(bookSpacing.P==3 and reflows==1,'native scroll extent not refreshed after typography change')
local before=writes;now=now+2;driver.OnUpdate(driver,.3)
assert(writes==before and reflows==1,'unchanged book caused repeated font/layout writes')
bookFonts.P[2]=12;combat=true;now=now+2;driver.OnUpdate(driver,.3)
assert(bookFonts.P[2]==12,'book font modified during combat')
combat=false;now=now+2;driver.OnUpdate(driver,.3);assert(bookFonts.P[2]==18,'book readability not restored after combat')
print('PASS: native book font minima and spacing, larger heading preservation, bounded reflow, combat defer; no content/input mutation.')
ReadyCheckFrame=obj('Frame','ReadyCheckFrame',true)
ReadyCheckListenerFrame=obj('Frame','ReadyCheckListenerFrame',true);ReadyCheckListenerFrame.hidden=true
local readyBg=obj('Texture',nil,true);readyBg.file='Interface/DialogFrame/UI-DialogBox-Background-Dark'
ReadyCheckListenerFrame.regions={readyBg};ReadyCheckFrame.children={ReadyCheckListenerFrame};UIPanelWindows.ReadyCheckFrame={}
now=now+4;driver.OnUpdate(driver,.3)
assert(not ForeverHandheldDB.windowTheme.seen.ReadyCheckFrame and not readyBg.color,'state-only ready-check parent painted')
ReadyCheckListenerFrame.hidden=false;now=now+2;driver.OnUpdate(driver,.3)
assert(readyBg.color and readyBg.color[1]==.025,'actual ready-check listener not painted')
ReadyCheckListenerFrame.hidden=true;driver.OnUpdate(driver,.3)
for _,f in ipairs(objects)do if f.kind=='Frame' and f.parent==UIParent and f.anchor==ReadyCheckListenerFrame then assert(f.hidden,'ready-check backdrop remained after listener hid')end end
print('PASS: ready-check background follows listener visibility, never the state-only parent.')

QuickKeybindFrame=obj('Button','QuickKeybindFrame',true);UIPanelWindows.QuickKeybindFrame={}
local quick=QuickKeybindFrame;quick.BG=obj('Frame',nil,true)
local rim=obj('Texture',nil,true);quick.BG.regions={rim};quick.children={quick.BG}
local quickAction=function()error('quick-bind input invoked by paint')end
quick.OnKeyDown=quickAction;quick.OnClick=quickAction
now=now+4;driver.OnUpdate(driver,.3)
assert(rim.alpha==0,'quick-bind ornamental rim remains over shared finish')
assert(quick.OnKeyDown==quickAction and quick.OnClick==quickAction,'quick-bind input changed')
print('PASS: quick-bind decorative BG replaced by shared rim without changing native listeners')

SettingsPanel=obj('Frame','SettingsPanel',true);UIPanelWindows.SettingsPanel={}
local nested=SettingsPanel
for i=1,9 do local child=obj('Frame',nil,true);nested.children={child};nested=child end
local deepBg=obj('Texture',nil,true);deepBg.file='Interface/DialogFrame/UI-DialogBox-Background-Dark';nested.regions={deepBg}
nested.OnClick=quickAction;now=now+4;driver.OnUpdate(driver,.3)
assert(deepBg.color and deepBg.color[1]==.025,'nested settings background missed')
assert(nested.OnClick==quickAction,'nested native action changed')
print('PASS: deeper Settings-only palette traversal retains native actions and other-window depth bound')

local selector=obj('Frame',nil,true);selector.GetMenuDescription=function()error('native menu queried')end
selector.Arrow=obj('Texture',nil,true);selector.Text=obj('FontString',nil,true)
local image=obj('Texture',nil,true);image.atlas='common-dropdown-c-button';image.w=240;image.h=39
image.GetVertexColor=function(s)return unpack(s.vertex or {1,1,1,1})end
image.SetVertexColor=function(s,...)s.vertex={...};s.colorWrites=(s.colorWrites or 0)+1 end
image.IsDesaturated=function(s)return s.desaturated end
image.SetColorTexture=function()error('dropdown transparency replaced by solid fill')end
selector.Background=image;selector.regions={image};selector.OnClick=quickAction
SettingsPanel.children={selector};now=now+2;driver.OnUpdate(driver,.3)
assert(image.atlas=='common-dropdown-c-button' and image.vertex[1]==.5 and image.desaturated,'native dropdown atlas tint failed')
assert(selector.OnClick==quickAction,'native dropdown action changed')
local n=image.colorWrites;now=now+2;driver.OnUpdate(driver,.3);assert(image.colorWrites==n,'settled tint rewritten')
image.atlas='common-dropdown-c-button-hover';now=now+2;driver.OnUpdate(driver,.3)
assert(image.atlas=='common-dropdown-c-button-hover','native hover atlas replaced')
print('PASS: native settings dropdown transparency/atlas/state/actions retained, scoped tint and stable writes')

selector.IsProtected=function()return true end;image.vertex={1,1,1,1};now=now+2;driver.OnUpdate(driver,.3)
assert(image.vertex[1]==1 and not ForeverHandheldDB.windowThemeError,'protected selector painted')

ProfessionsFrame=obj('Frame','ProfessionsFrame',true);UIPanelWindows.ProfessionsFrame={};ForeverHandheldWorkbench={}
local readableCopy=obj('Frame','ForeverHandheldProfessionLabel1',true)
local cover=obj('Texture',nil,true);cover.w=220;cover.h=120;cover.SetColorTexture=function()error('owned overview text mask erased')end
readableCopy.regions={cover};ProfessionsFrame.children={readableCopy}
now=now+4;driver.OnUpdate(driver,.3)
assert(not ForeverHandheldDB.windowThemeError,'shared painter changed owned profession presentation')
print('PASS: profession overview text masks survive generic workbench artwork cleanup')

SocialUIFrame=obj('Frame','SocialUIFrame',true)
local ignore=obj('Frame',nil,true);SocialUIFrame.IgnoreListFrame=ignore;ignore.OnClick=quickAction
now=now+4;driver.OnUpdate(driver,.3)
local background
for _,f in ipairs(objects)do if f.kind=='Frame' and f.parent==UIParent and f.anchor==ignore then background=f end end
assert(background and not background.hidden,'anonymous ignore list missing shared frame')
assert(ignore.OnClick==quickAction,'ignore action changed')
ignore.hidden=true;now=now+1;driver.OnUpdate(driver,.3)
assert(background.hidden,'ignore-list background lingered after close')
assert(not ForeverHandheldDB.windowThemeError)
print('PASS: anonymous native Ignore List receives matching shell and clears on closure with native actions intact')

AddFriendFrame=obj('Frame','AddFriendFrame',true);AddFriendFrame.OnClick=quickAction
local friendIcon=obj('Texture',nil,true);friendIcon.atlas='friends-icon-addFriend-logo-WoW';AddFriendFrame.regions={friendIcon}
now=now+4;driver.OnUpdate(driver,.3)
local friendBackground
for _,f in ipairs(objects)do if f.kind=='Frame' and f.parent==UIParent and f.anchor==AddFriendFrame then friendBackground=f end end
assert(friendBackground and not friendBackground.hidden,'friend dialog missing opaque shell')
assert(AddFriendFrame.OnClick==quickAction and not friendIcon.color,'native friend action or icon changed')
AddFriendFrame.hidden=true;now=now+1;driver.OnUpdate(driver,.3)
assert(friendBackground.hidden,'friend background lingered after close')
assert(not ForeverHandheldDB.windowThemeError)
print('PASS: friend dialog shell and close cleanup, native action/icon preservation')

local noteInput=obj('EditBox','StaticPopup1EditBox',true);noteInput.NineSlice=obj('Frame',nil,true)
local inputEdge=obj('Texture',nil,true);noteInput.NineSlice.regions={inputEdge}
StaticPopup1=obj('Frame','StaticPopup1',true);StaticPopup1.children={noteInput};noteInput.OnEnterPressed=quickAction
now=now+4;driver.OnUpdate(driver,.3)
assert(inputEdge.alpha~=0,'empty text input border hidden')
assert(noteInput.OnEnterPressed==quickAction,'input submit action changed')
assert(not ForeverHandheldDB.windowThemeError)
print('PASS: native edit-box border remains visible; input behavior unchanged')

StaticPopup1.BG=obj('Frame',nil,true);local dialogArt=obj('Texture',nil,true);StaticPopup1.BG.regions={dialogArt}
local progress=obj('Texture',nil,true);progress.atlas='ui-frame-lfg-progressbar-fill-green';StaticPopup1.regions={progress}
now=now+4;driver.OnUpdate(driver,.3)
assert(dialogArt.alpha==0,'native popup ornament not replaced')
assert(progress.alpha~=0 and not progress.color,'native progress/data art changed')
print('PASS: only popup ornamental BG suppressed; input border and native progress data retained')

local inactive=obj('Frame','HiddenNativeTab',true);inactive.hidden=true
local inactivePaint=obj('Texture',nil,true);inactivePaint.atlas='native-panel-background'
inactive.regions={inactivePaint}
local originalRegions,originalChildren=M.GetRegions,M.GetChildren
local visits=0
function inactive:GetRegions()visits=visits+1;return originalRegions(self)end
function inactive:GetChildren()visits=visits+1;return originalChildren(self)end
local inactiveAction=function()error('hidden tab action must remain native')end
inactive.OnClick=inactiveAction
StaticPopup1.children={inactive}
now=now+4;driver.OnUpdate(driver,.3)
assert(visits==0 and not inactivePaint.color,'invisible branch was traversed or painted')
inactive.hidden=false
now=now+4;driver.OnUpdate(driver,.3)
assert(visits>0 and inactivePaint.color,'newly visible branch was not styled')
assert(inactive.OnClick==inactiveAction and not inactive.hidden,'native visibility or action changed')
assert(not ForeverHandheldDB.windowThemeError)
print('PASS: invisible branches skip traversal; newly visible native content is styled without changing actions')

-- Forbidden dialogs must never be inspected or modified. Only their published
-- outbound flow state drives a separate, noninteractive background.
CommunitiesAddDialog=setmetatable({}, {__index=function()error('forbidden dialog accessed')end})
CommunitiesCreateDialog=CommunitiesAddDialog
local flowShown=true
function AddCommunitiesFlow_IsShown()return flowShown end
now=now+1;driver.OnUpdate(driver,.3)
local shade
for _,f in ipairs(objects)do if f.name=='ForeverHandheldCommunityBackdrop' then shade=f end end
assert(shade and not shade.hidden and shade.parent==UIParent and shade.anchor==UIParent,'secure flow backdrop missing')
assert(ForeverHandheldDB.communityDialogBackdrop.nativeDialogUntouched,'backdrop evidence missing')
local avatarShown=true
CommunitiesFrame=obj('Frame','CommunitiesFrame',true);CommunitiesFrame.alpha=.8
function CommunitiesAvatarPicker_IsShown()return avatarShown end
driver.OnUpdate(driver,.3);assert(shade.hidden,'secure shade covered lower-strata icon picker')
assert(CommunitiesFrame.alpha==0 and not CommunitiesFrame.hidden,'guild text still bleeds through picker or native visibility changed')
avatarShown=false;driver.OnUpdate(driver,.3);assert(not shade.hidden,'secure shade failed to return from icon picker')
assert(CommunitiesFrame.alpha==.8,'guild paint not restored after picker')
avatarShown=true;driver.OnUpdate(driver,.3);CommunitiesFrame.alpha=.6;avatarShown=false;driver.OnUpdate(driver,.3)
assert(CommunitiesFrame.alpha==.6,'external guild alpha overwritten')
CommunitiesAvatarPicker_IsShown=nil
combat=true;flowShown=false;driver.OnUpdate(driver,.3);assert(shade.hidden,'backdrop stranded after combat closure')
flowShown=true;driver.OnUpdate(driver,.3);assert(not shade.hidden,'backdrop not shown in combat')
function AddCommunitiesFlow_IsShown()error('native flow unavailable')end
driver.OnUpdate(driver,.3);assert(shade.hidden,'backdrop stranded after unavailable native flow')
AddCommunitiesFlow_IsShown=nil;combat=false;driver.OnUpdate(driver,.3)
assert(shade.hidden and not ForeverHandheldDB.windowThemeError,'native flow absence caused error')
print('PASS: community backdrop follows public native flow including combat/error cleanup without touching forbidden dialogs')

CommunitiesAvatarPickerDialog=obj('Frame','CommunitiesAvatarPickerDialog',true)
local avatarIcon=obj('Texture',nil,true);avatarIcon.file=123456
CommunitiesAvatarPickerDialog.regions={avatarIcon};CommunitiesAvatarPickerDialog.OnClick=quickAction
CommunitiesAvatarPickerDialog.Selector=obj('Frame',nil,true)
local selectorArt=obj('Texture',nil,true);CommunitiesAvatarPickerDialog.Selector.regions={selectorArt}
now=now+4;driver.OnUpdate(driver,.3)
local avatarBackground
for _,f in ipairs(objects)do if f.parent==UIParent and f.anchor==CommunitiesAvatarPickerDialog then avatarBackground=f end end
assert(avatarBackground and not avatarBackground.hidden and not avatarIcon.color,'ordinary icon picker missing shell or native icon changed')
assert(CommunitiesAvatarPickerDialog.OnClick==quickAction,'native icon picker action replaced')
assert(selectorArt.alpha==0,'ordinary selector ornament remains')
CommunitiesAvatarPickerDialog.hidden=true;driver.OnUpdate(driver,.3);assert(avatarBackground.hidden,'icon picker shell lingered')
assert(not ForeverHandheldDB.windowThemeError)
print('PASS: ordinary community icon picker shell/closure with native icon and action preservation')

ControllerForeverShoulderSetup=obj('Frame','ControllerForeverShoulderSetup',true)
ControllerForeverKeybindDetail=obj('Frame','ControllerForeverKeybindDetail',true)
ControllerForeverPicker=obj('Frame','ControllerForeverPicker',true);ControllerForeverPicker.hidden=true
now=now+4;driver.OnUpdate(driver,.3)
local bindingBackground
for _,f in ipairs(objects)do if f.parent==UIParent and f.anchor==ControllerForeverShoulderSetup then bindingBackground=f end end
assert(bindingBackground and not bindingBackground.hidden,'binding shell missing')
ControllerForeverPicker.hidden=false;driver.OnUpdate(driver,.3)
assert(bindingBackground.hidden,'ancestor rim remains behind picker')
assert(not ControllerForeverShoulderSetup.hidden,'native parent hidden with picker')
ControllerForeverPicker.hidden=true;driver.OnUpdate(driver,.3)
assert(not bindingBackground.hidden,'binding shell not restored after picker')
assert(not ForeverHandheldDB.windowThemeError)
print('PASS: picker suppresses only owned ancestor shell; native parent remains visible; shell restores on close')

ControllerForeverPicker.hidden=false;driver.OnUpdate(driver,.3)
local pickerBg
for _,f in ipairs(objects)do if f.parent==UIParent and f.anchor==ControllerForeverPicker then pickerBg=f end end
assert(pickerBg and not pickerBg.hidden)
ControllerForeverPicker.editBox=obj('Frame',nil,true)
now=now+4;driver.OnUpdate(driver,.3)
assert(pickerBg.hidden,'picker rim crosses nested macro editor')
ControllerForeverPicker.editBox.hidden=true;driver.OnUpdate(driver,.3);assert(not pickerBg.hidden,'picker rim not restored')
ControllerForeverChatEdit=obj('Frame','ControllerForeverChatEdit',true);ControllerForeverChatEdit.mode='prompt'
now=now+4;driver.OnUpdate(driver,.3)
local promptBg
for _,f in ipairs(objects)do if f.parent==UIParent and f.anchor==ControllerForeverChatEdit then promptBg=f end end
assert(promptBg and not promptBg.hidden,'binding prompt missing theme')
ControllerForeverPicker.hidden=true;driver.OnUpdate(driver,.3);assert(promptBg.hidden,'binding prompt background stranded after picker close')
ControllerForeverPicker.hidden=false;ControllerForeverChatEdit.mode='chat';driver.OnUpdate(driver,.3);assert(promptBg.hidden,'binding prompt styling applied to chat mode')
assert(not ForeverHandheldDB.windowThemeError)
print('PASS: anonymous nested editor shell, parent-rim restoration and scoped prompt cleanup; normal chat mode untouched')
EditModeImportLayoutDialog=obj('Frame','EditModeImportLayoutDialog',true)
local editModal=EditModeImportLayoutDialog
editModal.Border=obj('Frame',nil,true);local border=obj('Texture',nil,true)
editModal.Border.regions={border};editModal.children={editModal.Border}
editModal.OnClick=original
now=now+4;driver.OnUpdate(driver,.3)
local modalBg,modalEdge
for _,f in ipairs(objects)do
 if f.parent==UIParent and f.anchor==editModal then modalBg=f end
 if f.parent==editModal and f.anchor==editModal then modalEdge=f end
end
assert(modalBg and not modalBg.hidden and modalEdge and not modalEdge.hidden,'native edit modal theme missing')
assert(border.alpha==0 and editModal.OnClick==original,'modal decoration changed native actions')
editModal.hidden=true;driver.OnUpdate(driver,.3)
assert(modalBg.hidden and modalEdge.hidden,'modal theme remains after cancel')
editModal.hidden=false;driver.OnUpdate(driver,.3)
assert(not modalBg.hidden and not modalEdge.hidden,'modal theme failed to reopen')
assert(not ForeverHandheldDB.windowThemeError)
print('PASS: actual edit modal roots receive opaque shell, decorative border replacement and close/reopen cleanup without native actions')

-- Stable shells are presentation only; their background follows native fades
-- and depth changes and is removed promptly even through combat closure.
local f=obj('Frame','CharacterFrame',true);CharacterFrame=f
local function frameTick()now=now+.3;driver.OnUpdate(driver,.3)end
frameTick();frameTick()
local rim,bg
for _,o in ipairs(objects)do
 if o.parent==f and o.anchor==f then rim=o end
 if o.parent==UIParent and o.anchor==f then bg=o end
end
assert(rim and bg and not rim.hidden and not bg.hidden)
local function count()return (rim.shellWrites or 0)+(bg.shellWrites or 0)end
local start=count()
for _=1,60 do frameTick()end
local stable=count()-start
print('Stable visible shell writes per 60 paint ticks:',stable)
assert(stable==0,'steady shell still submits native setter calls')
local current=rim.level;rim.level=current+4;frameTick();assert(rim.level==current,'native child-level shift left rim at wrong depth')
f.alpha=.4;f.level=40;f.strata='HIGH';for _=1,5 do frameTick()end
assert(bg.alpha==.4 and bg.level==39 and bg.strata=='HIGH' and rim.strata=='HIGH','native layering change not followed')
f.alpha=.001;frameTick()
assert(bg.hidden and rim.hidden,'native fade did not hide shell')
f.alpha=1;frameTick();assert(not bg.hidden and not rim.hidden and bg.alpha==1,'native fade restoration failed')
f.hidden=true;combat=true;frameTick();assert(bg.hidden,'independent backdrop leaked during combat close')
combat=false;f.hidden=false;frameTick();assert(not bg.hidden and not rim.hidden,'shell did not recover after combat')
print('PASS: settled shell writes, native alpha/depth changes, fade restoration and combat close')
