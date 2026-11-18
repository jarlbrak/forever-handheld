-- Native interaction contract and dynamic-panel resilience.
local M,frames={},{}
local combat=false
local mutations=0
function M:GetName()return self.name end
function M:GetParent()return self.parent end
function M:IsForbidden()return false end
function M:IsVisible()return not self.hidden end
function M:IsShown()return not self.hidden end
function M:GetAlpha()return self.alpha or 1 end
function M:GetSize()return self.w or 500,self.h or 400 end
function M:GetWidth()return self.w or 500 end
function M:GetHeight()return self.h or 400 end
function M:GetScale()return self.scale or 1 end
function M:GetEffectiveScale()return self.scale or 1 end
function M:GetFrameLevel()return self.level or 10 end
function M:SetFrameLevel(v)self.level=v end
function M:GetFrameStrata()return self.strata or 'MEDIUM' end
function M:SetFrameStrata(v)assert(not self.native,'native strata changed');self.strata=v end
function M:GetPoint()return unpack(self.point or {'TOPLEFT',UIParent,'TOPLEFT',20,-100}) end
function M:GetNumPoints()return 1 end
function M:GetLeft()return 100 end
function M:GetRight()return 600 end
function M:GetTop()return 600 end
function M:GetBottom()return 100 end
function M:GetChildren()return unpack(self.children or {})end
function M:SetPoint(...)self.point={...};if self.native then mutations=mutations+1 end end
function M:ClearAllPoints()self.point=nil end
function M:SetScale(n)self.scale=n;mutations=mutations+1 end
function M:SetSize(w,h)self.w=w;self.h=h end
function M:SetWidth(w)self.w=w end
function M:SetHeight(h)self.h=h end
function M:SetAlpha(a)self.alpha=a end
function M:SetShown(v)self.hidden=not v end
function M:SetIgnoreParentAlpha(v)self.ignoreParentAlpha=v end
function M:SetText(v)self.text=v end
function M:GetText()return self.text end
function M:SetAttribute(k,v)assert(not self.native);self.attributes[k]=v end
function M:GetAttribute(k)return self.attributes[k]end
function M:SetFont(...)self.font={...}end
function M:SetScript(event,fn)assert(not self.native,'native handler replaced');self[event]=fn end
function M:RegisterEvent()end
function M:RegisterForClicks()end
function M:EnableMouse(v)assert(not self.native,'native input changed');self.mouse=v end
local function obj(name,parent,native)
 local f=setmetatable({name=name,parent=parent,native=native,attributes={}},{__index=function(_,k)
  if M[k] then return M[k] end
  if k:match('^Set') then return function(self)assert(not self.native,'native state changed: '..k)end end
 end});frames[#frames+1]=f;return f
end
function M:CreateTexture()return obj(nil,self)end
function M:CreateFontString()return obj(nil,self)end
function CreateFrame(_,name,parent,template)local f=obj(name,parent);f.template=template;return f end
function InCombatLockdown()return combat end
function GetTime()return 10 end
STANDARD_TEXT_FONT='Font'
UIParent=obj('UIParent');UIParent.w=1280;UIParent.h=800
SettingsPanel=obj('SettingsPanel',UIParent,true);SettingsPanel.w=1100;SettingsPanel.h=850
ControllerForeverMenu=obj('ControllerForeverMenu',UIParent,true);ControllerForeverMenu.w=1100;ControllerForeverMenu.h=710
MerchantFrame=obj('MerchantFrame',UIParent,true)
FriendsFrame=obj('FriendsFrame',UIParent,true)
GuildFrame=obj('GuildFrame',FriendsFrame,true)
StaticPopup1=obj('StaticPopup1',UIParent,true);StaticPopup1.h=140
local original=function()error('native action invoked')end
MerchantFrame.OnClick=original
UIPanelWindows={}
local ace={objPools={},RegisterAsContainer=function()end}
local dialog={OpenFrames={}}
function LibStub(name)return name=='AceGUI-3.0' and ace or name=='AceConfigDialog-3.0' and dialog end
local containerHook,commodityHook
function hooksecurefunc(owner,key,fn)
 if owner==ace then assert(key=='RegisterAsContainer');containerHook=fn
 else assert(key=='refresh' and type(owner.refresh)=='function');commodityHook=fn end
end
local originalPairs=pairs
function pairs(t)assert(t~=_G,'full-global polling causes measured frame stalls');return originalPairs(t)end
dofile(arg[1])
ForeverHandheldDB={panelError='prior session error',auctionCommodityError='prior session error'}
local driver=frames[#frames]
driver.OnUpdate(driver,.3)
assert(not ForeverHandheldDB.panelError,ForeverHandheldDB.panelError)
assert(not ForeverHandheldDB.auctionCommodityError,'stale commodity error persisted into a new session')
assert(not ForeverHandheldDB.panelErrors,'panel decoration error')
assert(SettingsPanel:GetScale()<1,'large panel did not fit')
assert(SettingsPanel.point[1]=='CENTER','workspace was not centered')
assert(ControllerForeverMenu:GetScale()<1 and ControllerForeverMenu.point[1]=='CENTER','controller settings header must fit within the handheld viewport')
assert(MerchantFrame.point==nil,'paired merchant arrangement changed without overflow')
assert(not GuildFrame.point,'nested guild content moved out of its social parent')
assert(MerchantFrame.OnClick==original,'native action handler replaced')
MailFrame=obj('MailFrame',UIParent,true);InboxFrame=obj('InboxFrame',MailFrame,true)
SendMailFrame=obj('SendMailFrame',MailFrame,true);SendMailFrame:SetShown(false)
local inboxCount=0
function GetInboxNumItems()return inboxCount end
driver.OnEvent(driver,'MAIL_SHOW')
driver.OnUpdate(driver,.3)
local function namedFrame(name)
 for _,frame in ipairs(frames)do if frame.name==name then return frame end end
end
assert(not namedFrame('ForeverHandheldEmptyInbox'),'empty card appeared before the server inbox event')
driver.OnEvent(driver,'MAIL_INBOX_UPDATE')
driver.OnUpdate(driver,.3)
local empty=namedFrame('ForeverHandheldEmptyInbox')
assert(empty and empty:IsShown() and empty.mouse==false,'empty state missing or captures input')
inboxCount=1;driver.OnEvent(driver,'MAIL_INBOX_UPDATE');driver.OnUpdate(driver,.3)
assert(not empty:IsShown(),'empty state covered a populated inbox')
inboxCount=0;InboxFrame:SetShown(false);SendMailFrame:SetShown(true)
SendMailBodyEditBox=obj('SendMailBodyEditBox',SendMailFrame,true)
function SendMailBodyEditBox:GetFont()return 'Font',12,'' end
driver.OnUpdate(driver,.3)
assert(not empty:IsShown() and SendMailBodyEditBox.font[2]==18,'compose must retain its own fields with readable text')
SendMailFrame:SetShown(false);InboxFrame:SetShown(true)
driver.OnEvent(driver,'MAIL_CLOSED');driver.OnEvent(driver,'MAIL_SHOW');driver.OnUpdate(driver,.3)
assert(not empty:IsShown(),'a reopened mailbox reused the previous response')
MailFrame:SetShown(false);InboxFrame:SetShown(false)
local merchantHeader
for _,f in ipairs(frames)do if f.name=='ForeverHandheldPanelMerchantFrame' then merchantHeader=f end end
assert(merchantHeader and merchantHeader.ignoreParentAlpha,'paired header must remain opaque under native focus dimming')
MerchantFrame.alpha=.25;driver.OnUpdate(driver,.3)
assert(not merchantHeader.hidden and MerchantFrame.alpha==.25,'native focus dimming must remain untouched')
MerchantFrame.alpha=0;driver.OnUpdate(driver,.3)
assert(merchantHeader.hidden,'alpha-hidden native panel must not leave a floating title')
MerchantFrame.alpha=1;driver.OnUpdate(driver,.3)
assert(not merchantHeader.hidden,'paired title must return with native panel')
assert(ForeverHandheldDB.panelCoverage.StaticPopup1,'confirmation dialog not covered')
combat=true;local before=mutations;driver.OnUpdate(driver,.3);assert(mutations==before,'geometry modified in combat')
combat=false
local anonymous=obj(nil,UIParent,true)
containerHook(ace,{type='Frame',frame=anonymous})
for i=1,9 do driver.OnUpdate(driver,.3)end
assert(ForeverHandheldPanels.roots[anonymous],'late anonymous addon settings missed')
local recycled=obj(nil,UIParent,true)
ace.objPools.Frame={[{type='Frame',frame=recycled}]=true}
local alreadyOpen=obj(nil,UIParent,true)
dialog.OpenFrames.test={type='Window',frame=alreadyOpen}
local customRoot=obj(nil,UIParent,true)
QuestieConfigFrame={type='Frame',frame=customRoot}
for i=1,9 do driver.OnUpdate(driver,.3)end
assert(ForeverHandheldPanels.roots[recycled] and ForeverHandheldPanels.roots[alreadyOpen],'existing or pooled addon settings missed')
assert(ForeverHandheldPanels.roots[customRoot] and ForeverHandheldPanels.aceFrames[customRoot].title=='Questie','custom Questie root missed')
-- Auction and inventory keep their own behavior, with one fitted native
-- header and the auction's paint above the paused inventory.
local ah=obj('ControllerForeverAHWindow',UIParent,true)
local ahHeader=obj(nil,ah);ahHeader.title=obj(nil,ahHeader);ahHeader.logo=obj(nil,ahHeader)
local ahLegend=obj(nil,ah);ahLegend.text=obj(nil,ahLegend)
function ahHeader.title:GetFont()return 'Font',26,'' end
ControllerForeverWin_bags=obj('ControllerForeverWin_bags',UIParent,true)
ControllerForeverWin_bags.level=40
ControllerForever={
 AH={win={state={frame=ah,zones={header=ahHeader,legend=ahLegend}}}},
 Inv={bankView={}},
 Kit={top=function(inst)return inst.stack[#inst.stack]end},
}
ah.OnClick=original
driver.OnUpdate(driver,.3)
assert(not ForeverHandheldDB.panelError,ForeverHandheldDB.panelError)
assert(ForeverHandheldPanels.active and ForeverHandheldPanels.dockCovered,'auction must claim gameplay dock')
assert(ForeverHandheldDB.panelCoverage.ControllerForeverAHWindow and ahLegend.text:GetAlpha()==1,'auction must retain its own legend')
assert(ah:GetFrameLevel()==140,'auction did not cover paused inventory')
assert(ah.OnClick==original and not ah.hidden and not ControllerForeverWin_bags.hidden,'auction paint changed native behavior')
assert(not ForeverHandheldPanels.configs.ControllerForeverAHWindow,'duplicate offscreen auction title')
for i=1,20 do driver.OnUpdate(driver,.3) end
assert(ah:GetFrameLevel()==140,'auction layers grow on repeated updates')
ControllerForeverWin_bags.hidden=true;driver.OnUpdate(driver,.3)
assert(ah:GetFrameLevel()==10,'original auction layer not restored')
ControllerForeverWin_bags.hidden=false;driver.OnUpdate(driver,.3)
ah.hidden=true;driver.OnUpdate(driver,.3)
assert(ah:GetFrameLevel()==10,'closed auction retained elevated layer')
local continued=0
local help={card=obj(nil,ah),onKey=function(key)assert(key=='A');continued=continued+1 end}
help.card.ok=obj(nil,help.card)
ControllerForever.AH.views={help=help}
ControllerForever.AH.win.current=function()return help end
ah.hidden=false;driver.OnUpdate(driver,.3)
local proceed
for _,f in ipairs(frames)do if f.name=='ForeverHandheldAuctionContinue' then proceed=f end end
assert(proceed,'help prompt lacks pointer target')
proceed.OnClick();assert(continued==1,'help action not invoked')
combat=true;proceed.OnClick();assert(continued==1,'help activated during combat');combat=false
ControllerForever.AH.win.current=function()return {} end
proceed.OnClick();assert(continued==1,'help target invoked another auction view')
local hint=obj(nil)
ControllerForever.AH.views['sell.list']={ui={cards={hint=hint}}}
driver.OnUpdate(driver,.3)
assert(hint.text=='D-pad Left / Right: sections\nLT / RT: page','sell hints conflict with voice paddles')
local confirmMode='always'
local ahApi=ControllerForever.AH
ahApi.get=function(k)return k=='confirm' and confirmMode or 250000 end
ahApi.win.tr=function(text)return text end
ahApi.win.money=function(limit,opts)assert(limit==250000 and opts.letters);return '25g' end
local quote={f=obj(nil,ah),refresh=original}
quote.f.total=obj(nil,quote.f);quote.f.limit=obj(nil,quote.f)
local coin='|TInterface\\MoneyFrame\\UI-CopperIcon:23:23:2:0|t'
local over='Over your 25g limit: A gets the price, A again buys.'
quote.f.total:SetText('Total 60'..coin)
quote.f.limit:SetText(over)
ahApi.views['buy.commodity']=quote
driver.OnUpdate(driver,.3)
assert(commodityHook and quote.refresh==original and not ForeverHandheldDB.auctionCommodityError,'auction price presentation replaced the native refresh')
assert(quote.f.total.text=='Total 60'..coin:gsub('23:23','15:15'),'total coin overlaps its average line')
assert(quote.f.limit.text=='A gets the price. A again buys.','always-confirm mode misstates the price limit')
confirmMode='limit';quote.f.limit:SetText(over);commodityHook()
assert(quote.f.limit.text==over,'limit confirmation should retain its native reason')
confirmMode='always';quote.f.limit:SetText('Only 2 left at these prices');quote.f.total:SetText('Total …');commodityHook()
assert(quote.f.limit.text=='Only 2 left at these prices' and quote.f.total.text=='Total …','availability and loading states must retain native copy')
GameMenuFrame=obj('GameMenuFrame',UIParent,true)
local function button(label)
 local b=obj(nil,GameMenuFrame,true);b.text=label
 b.GetText=function(self)return self.text end
 b.GetFontString=function()return nil end
 return b
end
local a,b=button('Options'),button('Exit Game')
local c=button('Macros');GameMenuFrame.children={b,c,a}
driver.OnUpdate(driver,.3)
assert(a.point[4]==24 and a.point[5]==-20,'menu action order incorrect')
a.text='Exit Game';b.text='Options'
driver.OnUpdate(driver,.3)
assert(b.point[4]==24 and b.point[5]==-20,'recycled menu action order incorrect')
SettingsPanel.GetSize=function()error('unavailable panel')end
LorewardDirectionsWindow=obj('LorewardDirectionsWindow',UIParent,true)
LorewardDirectionsWindow.w=460;LorewardDirectionsWindow.h=470
LorewardDirectionsWindow.title=obj(nil,LorewardDirectionsWindow)
driver.OnUpdate(driver,.3)
assert(LorewardDirectionsWindow:GetScale()==1.25,'Loreward text not enlarged for handheld use')
assert(LorewardDirectionsWindow.title.alpha==0,'duplicate Loreward title remained')
assert(ForeverHandheldDB.panelCoverage.LorewardDirectionsWindow,'Loreward coverage missed')
driver.OnUpdate(driver,.3)
assert(ForeverHandheldDB.panelErrors.SettingsPanel,'isolated window error not recorded')
assert(ForeverHandheldPanels.active,'one broken window interrupted the other panels')
print('Panel contracts passed: native actions untouched, paired/nested layout preserved, screen fit, combat defer, lazy addons and failure isolation.')

assert(not ForeverHandheldPanels.configs.LorewardStepNotes,'passive story notes must not become a workspace')
assert(ForeverHandheldPanels.configs.ForeverHandheldStoryReader.mode=='workspace','deliberate story reading lacks shared presentation')
-- The native bank stays logically open while CF's animation fades it.
-- Only our duplicate header yields; hiding BankFrame would end the session.
BankFrame=obj('BankFrame',UIParent,true);BankFrame.alpha=1;BankFrame.OnClick=original
ControllerForever.Kit={fades={}}
driver.OnUpdate(driver,.3)
local bankHeader
for _,f in ipairs(frames)do if f.name=='ForeverHandheldPanelBankFrame' then bankHeader=f end end
assert(bankHeader and not bankHeader.hidden)
ControllerForever.Kit.fades[BankFrame]={on=true};driver.OnUpdate(driver,.3)
assert(bankHeader.hidden and not BankFrame.hidden and BankFrame.alpha==1 and BankFrame.OnClick==original,'duplicate title must follow owner fade without ending banking')
ControllerForever.Kit.fades[BankFrame].on=false;driver.OnUpdate(driver,.3)
assert(not bankHeader.hidden,'native bank title returns when controller replacement yields')
print('PASS: controller replacement fade hides only duplicate native-panel title and restores it on release')
-- All seven bank hints, including contextual B, survive the native six-item
-- drawing cap without changing input or the native legend's stored text.
M.Show=function(self)self.hidden=false end;M.Hide=function(self)self.hidden=true end
local nativeBags=obj('ContainerFrameCombinedBags',UIParent,true)
ContainerFrameCombinedBags=nativeBags
local owner=BankFrame
local selected=obj(nil,BankFrame,true)
function selected:IsEnabled()return not self.disabled end
InputUtil={IsGamepadUIEnabled=function()return true end}
SmartNavigation={GetActiveFrame=function()return owner end,GetCurrentButton=function()return selected end}
StaticPopup1:Hide();driver.OnUpdate(driver,.3)
local nativeFooter
for _,f in ipairs(frames)do if f.name=='ForeverHandheldNativeBankFooter' then nativeFooter=f end end
assert(nativeFooter and nativeFooter:IsShown() and nativeFooter.parent==BankFrame and nativeFooter.mouse==false)
assert(nativeFooter.hint.text:find('A|r Select',1,true) and nativeFooter.hint.text:find('RT|r Bags',1,true) and nativeFooter.hint.text:find('B|r Close bank',1,true))
selected.disabled=true;nativeBags:Hide();driver.OnUpdate(driver,.3)
assert(nativeFooter.hint.text=='|cfff0cf88B|r Close bank','native footer advertised unavailable actions')
selected.disabled=false;nativeBags:Show();owner=nativeBags;driver.OnUpdate(driver,.3)
assert(not nativeFooter:IsShown(),'native bank footer must yield to bags')
owner=BankFrame;StaticPopup1:Show();driver.OnUpdate(driver,.3)
assert(not nativeFooter:IsShown(),'native bank footer must yield to confirmation')
StaticPopup1:Hide();driver.OnUpdate(driver,.3)
assert(nativeFooter:IsShown(),'native bank footer did not return after confirmation')
combat=true;driver.OnUpdate(driver,.3);assert(not nativeFooter:IsShown(),'native bank footer must yield in combat');combat=false
ControllerForever.Kit.fades[BankFrame].on=true;driver.OnUpdate(driver,.3)
assert(not nativeFooter:IsShown() and BankFrame.OnClick==original,'native bank fallback changed the native action')
DressUpFrame=obj('DressUpFrame',UIParent,true);DressUpFrame.OnClick=original
owner=DressUpFrame;driver.OnUpdate(driver,.3)
local dressFooter
for _,f in ipairs(frames)do if f.name=='ForeverHandheldDressingRoomFooter' then dressFooter=f end end
assert(dressFooter and dressFooter:IsShown() and dressFooter.mouse==false and dressFooter.hint.text:find('B|r Close preview',1,true))
assert(not dressFooter.hint.text:find('RT',1,true) and DressUpFrame.OnClick==original,'dressing room footer copied a bank shortcut or changed the action')
DressUpFrame:Hide();driver.OnUpdate(driver,.3)
assert(not dressFooter:IsShown(),'closed dressing room left a footer')
ControllerForever.Kit.fades[BankFrame].on=false;StaticPopup1:Show()
InputUtil=nil;SmartNavigation=nil;ContainerFrameCombinedBags=nil
print('PASS: native bank and dressing room footers follow selection, focus, popup and combat without intercepting input')
local bf=obj('ControllerForeverWin_bags',UIParent)
local bh=obj(nil,bf);bh.title=obj(nil,bh);function bh.title:GetFont()return 'Font',25,''end
local bl=obj(nil,bf);bl.w=1180;bl.text=obj(nil,bl);bl.text.alpha=.8;bl.text.text='Native six hints'
local bv={};local view=bv;local hints={{key='A',label='Pick Up'},{key='X',label='To Bank'},{key='Y',label='More'},{key='LT/RT',label='Bank'},{key='SELECT',label='Play'},{key='LB/RB',label='Sections'},{key='B',label='Close the Bank'}}
local bi={id='bags',frame=bf,zones={header=bh,legend=bl},state={}}
ControllerForever.Inv={bankView=bv};ControllerForever.Kit={live={bags=bi},top=function()return view end,legendOf=function()return hints end,glyphs=function(k)return '['..k..']'end}
driver.OnUpdate(driver,.3)
local footer
for _,f in ipairs(frames)do if f.parent==bl and f.text and f.text:find('Close the Bank',1,true)then footer=f end end
assert(footer and footer.text:find('\n',1,true) and bl.text.alpha==0,'bank B hint missing from complete two-row footer')
assert(bl.text.text=='Native six hints','native legend text overwritten')
hints[7].label='Put Back';driver.OnUpdate(driver,.3)
assert(footer.text:find('[B] Put Back',1,true) and not footer.text:find('Close the Bank',1,true),'contextual B operation not updated')
view={};driver.OnUpdate(driver,.3)
assert(footer.hidden and bl.text.alpha==.8,'original footer not restored on bank subview')
print('PASS: complete bank legend, contextual B action, original legend restoration and untouched owner text')

-- Inspect retains native identity and separates season/rank without touching input.
InspectFrame=obj('InspectFrame',UIParent,true)
InspectFrame.TitleText=obj(nil,InspectFrame);InspectFrame.TitleText.text='Test Player'
function InspectFrame.TitleText:GetText()return self.text end
InspectPVPFrame={MainInfoFrame={CurrentSeasonField=obj(),CurrentRankField=obj()}}
InspectFrame.OnClick=original
driver.OnUpdate(driver,.3)
local title
for _,f in ipairs(frames)do if f.text=='Test Player' then title=f end end
assert(title,'native inspected player identity missing from custom header')
local info=InspectPVPFrame.MainInfoFrame
assert(info.CurrentRankField.point[2]==info.CurrentSeasonField and info.CurrentRankField.point[5]==-10,'honor season/rank overlap')
InspectFrame.TitleText.text='Next Player';driver.OnUpdate(driver,.3)
assert(title.text=='Next Player' and InspectFrame.OnClick==original,'Inspect identity update changed native interaction')
print('PASS: Inspect identity, rank separation and unchanged native actions.')

-- Social tab content is lazy and identified by the client's parentKey.
SocialUIFrame=obj('SocialUIFrame',UIParent,true)
driver.OnUpdate(driver,.3)
local socialTitle
for _,f in ipairs(frames)do if f.text=='Friends & groups' and f.parent and f.parent.name=='ForeverHandheldPanelSocialUIFrame' then socialTitle=f end end
assert(socialTitle,'social header missing before lazy raid view')
local raid=obj(nil,SocialUIFrame,true);SocialUIFrame.RaidFrame=raid
raid.RaidDescription=obj(nil,raid)
function raid.RaidDescription:GetFont()return unpack(self.font or {'Font',12,''})end
raid.RaidInfoButton=obj(nil,raid,true);raid.ConvertToRaidButton=obj(nil,raid,true)
raid.RaidInfoButton.OnClick=original;raid.ConvertToRaidButton.OnClick=original
for _,b in ipairs({raid.RaidInfoButton,raid.ConvertToRaidButton})do
 b.label=obj(nil,b);function b.label:GetFont()return unpack(self.font or {'Font',12,''})end
 function b:GetFontString()return self.label end
end
driver.OnUpdate(driver,.3)
assert(socialTitle.text=='Raid' and raid.RaidDescription.font[2]==16,'lazy raid title/readability missing')
assert(raid.RaidInfoButton.label.font[2]==14 and raid.RaidInfoButton.OnClick==original and raid.ConvertToRaidButton.OnClick==original,'native raid actions changed')
raid.hidden=true;driver.OnUpdate(driver,.3)
assert(socialTitle.text=='Friends & groups','social title did not restore after raid tab')
function SocialUIFrame:GetTitleForSelectedTab()return self.tabTitle end
SocialUIFrame.tabTitle='Recent Allies';driver.OnUpdate(driver,.3)
assert(socialTitle.text=='Recent Allies','native Social tab title missing')
InputUtil={IsGamepadUIEnabled=function()return true end}
SmartNavigation={GetActiveFrame=function()return owner end,GetCurrentButton=function()return selected end}
StaticPopup1:Hide()
SocialUIFrame.tabTitle='Friend Requests';owner=SocialUIFrame;driver.OnUpdate(driver,.3)
local socialFooter=namedFrame('ForeverHandheldSocialFooter')
assert(socialTitle.text=='Friend Requests' and socialFooter and socialFooter:IsShown() and socialFooter.mouse==false)
assert(socialFooter.hint.text:find('D-pad|r Navigate',1,true) and socialFooter.hint.text:find('A|r Select',1,true) and socialFooter.hint.text:find('B|r Close',1,true))
local originalBinds=ControllerForever.Binds
local binding,commits
commits=0
ControllerForever.Binds={
 PRIORITY={gamewindow=80},claimant=function(_,name,priority,options)
  assert(name=='forever-handheld-friend-actions' and priority==83 and options.overGame and options.outOfFight)
  return {set=function(key,value)assert(key=='PAD3');binding=value end,
   clear=function()binding=nil end,commit=function()commits=commits+1 end}
 end,
}
local list=obj(nil,SocialUIFrame,true);SocialUIFrame.FriendsList=list
local content=obj(nil,list,true)
local card,other=obj(nil,content,true),obj(nil,content,true)
for _,row in ipairs({card,other})do
 row.OpenMenu=original;row.OnClick=original;row.IsObjectType=function(_,kind)return kind=='Button'end
end
selected=card;driver.OnUpdate(driver,.3)
local proxy=namedFrame('ForeverHandheldFriendActionsButton')
assert(proxy and proxy.template=='SecureActionButtonTemplate' and proxy:GetAttribute('type2')=='click')
assert(proxy:GetAttribute('clickbutton2')==card and binding=='CLICK ForeverHandheldFriendActionsButton:RightButton')
assert(socialFooter.hint.text:find('X|r Actions',1,true) and socialFooter.w==398)
proxy.PreClick(proxy);assert(proxy:GetAttribute('clickbutton2')==card)
selected=other;proxy.PreClick(proxy);assert(not proxy:GetAttribute('clickbutton2'),'same-frame input kept a stale friend card')
driver.OnUpdate(driver,.3)
assert(proxy:GetAttribute('clickbutton2')==other and commits==1,'selection change rewrote the binding or kept the old card')
combat=true;driver.OnUpdate(driver,.3);assert(not socialFooter:IsShown(),'combat retained the Social controller footer')
combat=false
other.HasAccessConstraints=function()return true end
driver.OnUpdate(driver,.3)
assert(not binding and not proxy:GetAttribute('clickbutton2') and not socialFooter.hint.text:find('X|r Actions',1,true))
assert(card.OpenMenu==original and card.OnClick==original and other.OpenMenu==original and other.OnClick==original)
ControllerForever.Binds=originalBinds
owner=StaticPopup1;driver.OnUpdate(driver,.3)
assert(not socialFooter:IsShown(),'Social footer must yield when native focus moves to a dialog')
owner=nil;InputUtil=nil;SmartNavigation=nil;StaticPopup1:Show()
print('PASS: native Social tab titles, context-aware controller footer, lazy raid readability and untouched raid actions.')
print('PASS: focused friend actions delegate native RightButton, disarm on stale focus or restricted input, and preserve native row handlers.')
ItemTextFrame=obj('ItemTextFrame',UIParent,true)
ItemTextFrame.TitleText=obj(nil,ItemTextFrame);ItemTextFrame.TitleText.text='The Weathered Journal'
function ItemTextFrame.TitleText:GetText()return self.text end
ItemTextFrame.OnClick=original
driver.OnUpdate(driver,.3)
local bookTitle
for _,f in ipairs(frames)do if f.text=='The Weathered Journal' and f~=ItemTextFrame.TitleText then bookTitle=f end end
assert(bookTitle and ItemTextFrame.OnClick==original,'book identity missing or native action replaced')
ItemTextFrame.TitleText.text='';driver.OnUpdate(driver,.3)
assert(bookTitle.text=='Reading','empty book title has no readable fallback')
print('PASS: book title follows native document identity with empty-title fallback.')
-- Ready-check initiators keep the state parent shown without a response view.
ReadyCheckFrame=obj('ReadyCheckFrame',UIParent,true)
ReadyCheckListenerFrame=obj('ReadyCheckListenerFrame',ReadyCheckFrame,true);ReadyCheckListenerFrame.hidden=true
ReadyCheckListenerFrame.OnClick=original
UIPanelWindows.ReadyCheckFrame={}
for i=1,10 do driver.OnUpdate(driver,.3)end
assert(not ForeverHandheldPanels.roots[ReadyCheckFrame],'ready-check state parent received a ghost panel')
assert(not ForeverHandheldPanels.roots[ReadyCheckListenerFrame],'hidden ready-check listener was decorated')
ReadyCheckListenerFrame.hidden=false;driver.OnUpdate(driver,.3)
assert(ForeverHandheldPanels.roots[ReadyCheckListenerFrame],'actual ready-check prompt not decorated')
assert(not ReadyCheckListenerFrame.point and ReadyCheckListenerFrame.OnClick==original,'compact ready-check native layout/action changed')
LFGInvitePopup=obj('LFGInvitePopup',UIParent,true);LFGInvitePopup.OnClick=original
driver.OnUpdate(driver,.3)
assert(ForeverHandheldPanels.roots[LFGInvitePopup] and not LFGInvitePopup.point and LFGInvitePopup.OnClick==original,'group invitation presentation changed native behavior')
print('PASS: ready-check state-only parent excluded; actual listener and invitation themed without action/layout mutation.')

-- Small guild forms enlarge as a unit, preserving actions and fitting height.
for name,title in pairs({GuildRegistrarFrame='Guild registration',PetitionFrame='Guild charter',TabardFrame='Guild tabard'})do
 local form=obj(name,UIParent,true);_G[name]=form;form.w=338;form.h=424;form.OnClick=original
 driver.OnUpdate(driver,.3)
 assert(math.abs(form:GetScale()-1.4)<.001 and form.OnClick==original,'guild readability/action preservation failed')
 assert(ForeverHandheldPanels.configs[name].title==title,'guild window identity incorrect')
 assert((form:GetHeight()+64)*form:GetScale()<=UIParent:GetHeight()-105,'guild header exceeds viewport')
 UIParent.h=600;driver.OnUpdate(driver,.3)
 assert((form:GetHeight()+64)*form:GetScale()<=UIParent:GetHeight()-105+.01,'guild form does not adapt to smaller viewport')
 form.hidden=true;UIParent.h=800
end
print('PASS: guild forms have distinct titles, enlarged native geometry, viewport fitting and unchanged actions.')
-- The controller tutorial owns a continuously fitted header and sample layout.
ControllerForeverTutorial=obj('ControllerForeverTutorial',UIParent,true)
local tutorial=ControllerForeverTutorial
tutorial.w=1100;tutorial.h=710;tutorial.scale=1;tutorial.OnClick=original
tutorial.point={'TOP',UIParent,'TOP',0,-30}
local anchor=tutorial.point
for i=1,10 do driver.OnUpdate(driver,.3)end
assert(tutorial.point==anchor and tutorial.scale==1 and tutorial.h==710,'tutorial geometry competed with its native owner')
assert(ForeverHandheldPanels.roots[tutorial] and tutorial.OnClick==original,'tutorial paint registration or native action changed')
for _,f in ipairs(frames)do assert(f.name~='ForeverHandheldPanelControllerForeverTutorial','duplicate tutorial heading created')end
tutorial.point={'TOPLEFT',UIParent,'TOPLEFT',12,-12};anchor=tutorial.point;tutorial.scale=.8;tutorial.h=500
driver.OnUpdate(driver,.3)
assert(tutorial.point==anchor and tutorial.scale==.8 and tutorial.h==500,'native dock/step geometry overwritten')
assert(ForeverHandheldDB.panelCoverage.ControllerForeverTutorial.mode=='native-header')
tutorial.GetTop=function()return 1200 end;driver.OnUpdate(driver,.3)
assert(not ForeverHandheldDB.panelCoverage.ControllerForeverTutorial.fits,'coverage ignored actual screen bounds')
print('PASS: tutorial native header/scale/dock/step geometry retained; paint registered, actions untouched and actual bounds recorded.')
-- Choosing a click-cast action requires both the source picker and bindings.
PlayerSpellsFrame=obj('PlayerSpellsFrame',UIParent,true);PlayerSpellsFrame.w=625;PlayerSpellsFrame.h=620
ClickBindingFrame=obj('ClickBindingFrame',UIParent,true);ClickBindingFrame.w=440;ClickBindingFrame.h=620
PlayerSpellsFrame.OnClick=original;ClickBindingFrame.OnClick=original
for i=1,3 do driver.OnUpdate(driver,.3)end
assert(PlayerSpellsFrame.point[4]<0 and ClickBindingFrame.point[4]>0,'native click-casting companion obscured by independent centering')
local leftRight=PlayerSpellsFrame.point[4]*PlayerSpellsFrame:GetScale()+PlayerSpellsFrame:GetWidth()*PlayerSpellsFrame:GetScale()/2
local rightLeft=ClickBindingFrame.point[4]*ClickBindingFrame:GetScale()-ClickBindingFrame:GetWidth()*ClickBindingFrame:GetScale()/2
assert(rightLeft-leftRight>=15.9,'click-casting panes overlap')
assert(PlayerSpellsFrame.OnClick==original and ClickBindingFrame.OnClick==original,'native click-casting actions changed')
ClickBindingFrame.hidden=true;driver.OnUpdate(driver,.3)
assert(PlayerSpellsFrame.point[4]==0,'spellbook failed to recenter after click-casting closed')
print('PASS: click-casting source picker and binding panel separated; native actions retained; standalone picker recenters')
PlayerSpellsFrame.hidden=true;MacroFrame=obj('MacroFrame',UIParent,true);MacroFrame.w=338;MacroFrame.h=424;MacroFrame.OnClick=original
ClickBindingFrame.hidden=false
for i=1,3 do driver.OnUpdate(driver,.3)end
assert(MacroFrame.point[4]<0 and ClickBindingFrame.point[4]>0,'macro companion was not paired')
assert(MacroFrame.OnClick==original)
ClickBindingFrame.hidden=true;driver.OnUpdate(driver,.3)
assert(MacroFrame.point[4]==0,'macro window did not return to standalone position')
print('PASS: macro companion pairing and standalone restoration')

-- Scaled anchors round-trip with small floating-point error in the client.
MacroFrame.point[4]=.00001525879;MacroFrame.point[5]=-22.000001
local before=mutations;driver.OnUpdate(driver,.3)
assert(mutations==before,'rounded settled center repeatedly reanchored')
print('PASS: scaled-coordinate rounding does not churn settled panel anchors')

QuickKeybindFrame=obj('QuickKeybindFrame',UIParent,true)
local quick=QuickKeybindFrame;quick.w=450;quick.h=250;quick.OnKeyDown=original;quick.OnClick=original
quick.Header=obj(nil,quick)
quick.InstructionText=obj(nil,quick);quick.InstructionText.point={'TOP',quick,'TOP',0,-20}
quick.InstructionText.IsObjectType=function(_,t)return t=='FontString'end
quick.GetRegions=function(s)return s.InstructionText end
driver.OnUpdate(driver,.3)
assert(quick:GetScale()==1.4 and quick.Header.alpha==0,'quick-bind native geometry not enlarged or duplicate header remains')
assert(quick.InstructionText:GetAlpha()==1,'actual quick-binding instructions mistaken for decorative title')
assert(quick.OnKeyDown==original and quick.OnClick==original,'quick binding listener changed')
assert(MacroFrame:GetScale()==1.4,'native macro editor remains too small')
assert(ForeverHandheldPanels.configs.CooldownViewerSettings.title=='Cooldown settings')
print('PASS: quick-bind instructions preserved, matching header/enlarged native geometry, unchanged key listener; macro readability and cooldown identity')

-- Top-docked tutorial samples need the real action dock, while chat remains
-- suppressed by modal ownership. Compare physical coordinates, not raw sizes.
for name in pairs(ForeverHandheldPanels.configs)do if _G[name]then _G[name].hidden=true end end
for frame in pairs(ForeverHandheldPanels.aceFrames)do frame.hidden=true end
ControllerForever=nil
ForeverHandheldDock=obj('ForeverHandheldDock',UIParent)
ForeverHandheldDock.GetTop=function()return 212 end
local bottom=360
tutorial.hidden=false;tutorial.scale=1
tutorial.GetTop=function()return 788 end
tutorial.GetBottom=function()return bottom end
driver.OnUpdate(driver,.3)
assert(ForeverHandheldPanels.active and not ForeverHandheldPanels.dockCovered,'top-docked tutorial hid samples or lost modal ownership')
bottom=60;driver.OnUpdate(driver,.3)
assert(ForeverHandheldPanels.dockCovered,'full tutorial failed to cover dock')
bottom=300;tutorial.scale=.5;driver.OnUpdate(driver,.3)
assert(ForeverHandheldPanels.dockCovered,'effective scale ignored in dock overlap')
bottom=440;driver.OnUpdate(driver,.3)
assert(not ForeverHandheldPanels.dockCovered,'clear scaled tutorial hid dock')
SettingsPanel.GetSize=M.GetSize;SettingsPanel.hidden=false;driver.OnUpdate(driver,.3)
assert(ForeverHandheldPanels.dockCovered,'other modal lost dock ownership')
SettingsPanel.hidden=true;bottom=nil;driver.OnUpdate(driver,.3)
assert(ForeverHandheldPanels.dockCovered,'missing bounds did not fail closed')
tutorial.hidden=true;driver.OnUpdate(driver,.3)
assert(not ForeverHandheldPanels.active and not ForeverHandheldPanels.dockCovered,'close did not restore dock')
assert(tutorial.OnClick==original,'native tutorial action changed')
print('PASS: docked tutorial retains real action dock; full/overlapping/scaled/unknown bounds and other modals hide it; native modal ownership/actions and close restoration preserved')

-- View's Play state is separate from service pauses and closes. The owner
-- keeps the open instance and selection, and its combat bags can still open.
view=bv;bi.mode='live';bi.open=true;bi.away='focus';bf:Show();bf.OnClick=original
local section=obj(nil,bf);section.w=196;section.OnClick=original
section.name=obj(nil,section);section.name:SetText('Trade Goods')
function section.name:GetFont()return unpack(self.font or {'Font',18,''})end
function section.name:GetText()return self.text end
function section.name:GetUnboundedStringWidth()local _,size=self:GetFont();return size*(self.letterWidth or 6.3)end
section.count=obj(nil,section);section.count:SetText('12');section.count.textWidth=24
function section.count:GetStringWidth()return self.textWidth end
bi.column={rows={section}}
ControllerForever={Inv={bankView=bv},Kit={live={bags=bi},top=function()return view end}}
driver.OnUpdate(driver,.3)
local resume
for _,f in ipairs(frames)do if f.name=='ForeverHandheldInventoryResume' then resume=f end end
assert(resume and resume:IsShown() and resume.mouse==false and resume.hint.text:find('Resume bank',1,true))
assert(not bf:IsShown() and bi.open and bi.away=='focus' and not ForeverHandheldPanels.dockCovered,'Play must free the dock while preserving the bank session')
local focus={isUIFocused=true,frame=nativeBags,returns=0}
function focus:GetActiveFrame()return self.frame end
function focus:SetUIFocusState()error('protected focus must remain with the game')end
GamepadMode={FrameControlsManager=focus}
ControllerForever.Kit.fades={[nativeBags]={on=true}}
function ControllerForever.Inv.endVisit(inst)assert(inst==bi and inst.away=='focus')end
function ControllerForever.Kit.back(inst)focus.returns=focus.returns+1;inst.away=nil;inst.frame:Show();return true end
GamepadRadial=obj('GamepadRadial',UIParent,true);driver.OnUpdate(driver,.3)
assert(focus.returns==0 and not resume:IsShown(),'active radial should own input and hide the chip')
GamepadRadial:Hide();combat=true;driver.OnUpdate(driver,.3);assert(focus.returns==0,'inventory resumed in combat');combat=false
focus.frame=SettingsPanel;driver.OnUpdate(driver,.3);assert(focus.returns==0,'another panel lost its real focus')
focus.frame=nativeBags;driver.OnUpdate(driver,.3);driver.OnUpdate(driver,.3)
assert(focus.returns==1 and bf:IsShown() and not resume:IsShown(),'radial return kept its faded inventory focus')
GamepadMode=nil;GamepadRadial=nil;bi.away='focus';driver.OnUpdate(driver,.3)
ProfessionsFrame=obj('ProfessionsFrame',UIParent,true);driver.OnUpdate(driver,.3)
assert(not resume:IsShown(),'Play chip appeared behind the workbench')
ProfessionsFrame:Hide();StaticPopup1:Show();driver.OnUpdate(driver,.3)
assert(not resume:IsShown(),'Play chip advertised a shortcut during a confirmation')
StaticPopup1:Hide();ForeverHandheldComms={active=true};driver.OnUpdate(driver,.3)
assert(not resume:IsShown(),'Play chip advertised a shortcut during chat')
ForeverHandheldComms=nil;driver.OnUpdate(driver,.3)
assert(resume:IsShown(),'Play chip did not return after modal overlays')
SettingsPanel:Show();driver.OnUpdate(driver,.3)
assert(not resume:IsShown() and ForeverHandheldPanels.dockCovered,'Play chip appeared over a workspace')
SettingsPanel:Hide();bi.away=nil;bf:Show();driver.OnUpdate(driver,.3)
assert(bf:IsShown() and not resume:IsShown() and ForeverHandheldPanels.dockCovered and bf.OnClick==original,'View return did not restore original navigation presentation')
assert(section.name:GetWidth()==111 and section.name.font[2]==16 and section.name.text=='Trade Goods' and section.count.text=='12' and section.count.point[4]==-8 and section.OnClick==original,'section label must reserve room for the native count')
section.count.textWidth=36;driver.OnUpdate(driver,.3)
assert(section.name:GetWidth()==99,'section label did not adapt to a larger count')
section.count.textWidth=24;section.scale=.7;section.name.letterWidth=7.1;driver.OnUpdate(driver,.3)
assert(section.name:GetWidth()==111 and section.name.font[2]==15,'narrow service inventory truncates a normal section name')
section.name:SetText('Gear');section.name.letterWidth=3;driver.OnUpdate(driver,.3)
assert(section.name.font[2]==16,'recycled short section did not recover readable type size')
bi.away='visit';driver.OnUpdate(driver,.3)
assert(bf:IsShown() and not resume:IsShown(),'service visit was treated as Play')
local service
for _,f in ipairs(frames)do if f.name=='ForeverHandheldServiceBagsHint' then service=f end end
assert(service and service:IsShown() and service.mouse==false and service.point[2]==bf,'native service visit lacks a visible RT return hint')
bf:SetFrameStrata('HIGH');DressUpFrame:Show();driver.OnUpdate(driver,.3)
assert(bf:GetFrameStrata()=='LOW' and DressUpFrame:GetFrameStrata()=='MEDIUM' and not service:IsShown(),'paired inventory covers the native preview or advertises the service switch')
DressUpFrame:Hide();driver.OnUpdate(driver,.3)
assert(bf:GetFrameStrata()=='HIGH' and service:IsShown(),'closing preview did not restore the paired inventory and hint')
StaticPopup1:Show();driver.OnUpdate(driver,.3)
assert(not service:IsShown(),'service return hint advertised during confirmation')
StaticPopup1:Hide()
ControllerForeverChatEdit=obj('ControllerForeverChatEdit',UIParent,true)
driver.OnUpdate(driver,.3)
assert(not service:IsShown(),'service return hint advertised during a controller keyboard prompt')
ControllerForeverChatEdit:Hide();driver.OnUpdate(driver,.3)
assert(service:IsShown(),'keyboard closure did not restore the service return hint')
view={};bi.away='focus';driver.OnUpdate(driver,.3)
assert(resume:IsShown() and resume.hint.text:find('Resume bags',1,true) and not service:IsShown(),'ordinary bags lack their Play hint or retained the service hint')
-- A parked native bag no longer participates in modal focus restoration.
local nativePlayManager={shownFrames={nativeBags},isUIFocused=false}
local parkedAction,restorations,commits=nil,0,0
function nativePlayManager:FrameHidden(frame)
 assert(frame==nativeBags and not self.isUIFocused and frame:IsShown())
 self.shownFrames={}
 return true
end
function nativePlayManager:FrameShown(frame,popup,takeFocus)
 assert(frame==nativeBags and popup==false and takeFocus==false)
 self.shownFrames={frame};restorations=restorations+1
end
GamepadMode={FrameControlsManager=nativePlayManager}
ControllerForever.Binds={PRIORITY={gamewindow=80},claimant=function(_,name,priority,options)
 assert(name=='forever-handheld-inventory-resume' and priority==83 and options.outOfFight)
 return {
  set=function(key,action)assert(key=='PADBACK');parkedAction=action end,
  clear=function()parkedAction=nil end,
  commit=function()commits=commits+1 end,
 }
end}
ControllerForever.Inv.holdBack=function(on)assert(on==false)end
nativeBags:Show();bf:Show();driver.OnUpdate(driver,.3)
assert(#nativePlayManager.shownFrames==0 and nativeBags:IsShown() and parkedAction and commits==1,'Play closed the actual bag or retained native focus')
ProfessionsFrame:Show();driver.OnUpdate(driver,.3)
assert(not parkedAction and commits==2 and restorations==0 and bi.away=='focus','modal lost View or restored inventory')
ProfessionsFrame:Hide();driver.OnUpdate(driver,.3);driver.OnUpdate(driver,.3)
assert(parkedAction and commits==3 and restorations==0 and resume:IsShown(),'closing modal did not return to Play')
local resumeButton=namedFrame('ForeverHandheldInventoryResumeButton')
resumeButton.OnClick();driver.OnUpdate(driver,.3)
assert(not parkedAction and commits==4 and restorations==1 and bf:IsShown() and not bi.away,'View did not restore the native registration and original instance once')
GamepadMode=nil;bi.away='focus';driver.OnUpdate(driver,.3)
bi.away=nil;bi.fightMode=true;combat=true;driver.OnUpdate(driver,.3)
assert(bf:IsShown() and not resume:IsShown(),'combat bags stayed hidden after taking over Play')
combat=false;bi.fightMode=nil;bi.away='focus';driver.OnUpdate(driver,.3)
bi.open=false;bi.away=nil;driver.OnUpdate(driver,.3)
assert(not bf:IsShown() and not resume:IsShown(),'closing in Play resurrected inventory')
bi.open=true;bi.away='focus';bf:Show();bf.IsProtected=function()return true end
driver.OnUpdate(driver,.3)
assert(bf:IsShown() and not resume:IsShown(),'protected owner frame was hidden')
ControllerForever=nil
print('PASS: Play keeps native inventory parked across modal close, returns View to the same session, and respects service and combat handoffs')
print('PASS: inventory section labels fit changing scale and count, and the service return hint yields to dialogs')

EditModeManagerFrame=obj('EditModeManagerFrame',UIParent,true);EditModeManagerFrame.level=1
EditModeImportLayoutDialog=obj('EditModeImportLayoutDialog',UIParent,true)
local modal=EditModeImportLayoutDialog;modal.level=100;modal.w=320;modal.h=370;modal.OnClick=original
driver.OnUpdate(driver,.3)
local editHeader
for _,f in ipairs(frames)do if f.name=='ForeverHandheldPanelEditModeManagerFrame' then editHeader=f end end
assert(editHeader and editHeader.level==2 and editHeader.level<modal.level-1,'editor header covers native modal underlay')
assert(modal.scale==1.3 and modal.point==nil and modal.level==100,'dialog enlargement changed native anchors/layer')
assert(modal.OnClick==original and not modal.hidden,'dialog behavior changed')
local count=mutations;for i=1,5 do driver.OnUpdate(driver,.3)end
assert(mutations==count,'settled dialog repeated geometry writes')
UIParent.h=400;driver.OnUpdate(driver,.3)
assert(modal.scale*370<=352.01,'dialog does not fit shorter viewport')
UIParent.h=800;modal.IsProtected=function()return true end;local scale=modal.scale
driver.OnUpdate(driver,.3);assert(modal.scale==scale,'protected dialog geometry changed')
modal.IsProtected=nil;combat=true;driver.OnUpdate(driver,.3);assert(modal.scale==scale,'combat dialog geometry changed')
combat=false;driver.OnUpdate(driver,.3);assert(modal.scale==1.3,'safe dialog scale did not recover')
assert(not ForeverHandheldDB.panelError and not (ForeverHandheldDB.panelErrors or {}).EditModeManagerFrame and not (ForeverHandheldDB.panelErrors or {}).EditModeImportLayoutDialog)
print('PASS: native edit modal layering, larger controls, viewport fit, stable writes, protected/combat guards and original actions preserved')

-- Native editor drag and resize transitions must retain its chosen anchors.
local editor=EditModeManagerFrame
editor.point={'TOPLEFT',UIParent,'TOPLEFT',45,-90};editor.w=510;editor.h=400
local chosen=editor.point;local savedAction=editor.OnClick
driver.OnUpdate(driver,.3)
assert(editor.point==chosen,'editor drag anchor overwritten')
assert(ForeverHandheldDB.panelCoverage.EditModeManagerFrame.mode=='layout-editor')
editor.h=760;driver.OnUpdate(driver,.3)
assert(editor.point==chosen,'advanced editor resize recentered user position')
assert((editor.h+editHeader:GetHeight())*editor.scale<=UIParent.h-105.01+.02,'advanced editor does not fit height')
editor.h=200;driver.OnUpdate(driver,.3)
assert(editor.point==chosen,'collapsed editor lost dragged position')
local stable=mutations;for i=1,5 do driver.OnUpdate(driver,.3)end
assert(mutations==stable,'settled editor repeats geometry mutations')
assert(editor.OnClick==savedAction,'native editor action replaced')
print('PASS: native editor drag anchors survive basic/advanced/collapsed fitting without repeated writes or handler replacement')

local channelConfig=ForeverHandheldPanels.configs.ChannelFrame
assert(channelConfig and channelConfig.category=='SOCIAL' and channelConfig.title=='Chat channels','channel workspace label missing')
