local driver,combat
function CreateFrame()driver={SetScript=function(s,k,v)s[k]=v end};return driver end
function InCombatLockdown()return combat end
function GetTime()return 101 end
function issecretvalue(v)return type(v)=='table' and v.secret end
local function frame(kind,parent)
 local f={children={},regions={},kind=kind,height=20,writes=0}
 function f:IsForbidden()return self.forbidden end
 function f:IsProtected()return self.protected end
 function f:IsShown()return not self.hidden end
 function f:IsObjectType(k)return self.kind==k end
 function f:GetChildren()return unpack(self.children)end
 function f:GetRegions()return unpack(self.regions)end
 function f:GetHeight()return self.height end
 function f:SetHeight(h)self.height=h;self.writes=self.writes+1 end
 if parent then table.insert(parent.children,f)end
 return f
end
local function font(f,size,text)
 f.size=size;f.text=text
 function f:GetFont()return 'native',self.size,'OUTLINE' end
 function f:SetFont(face,size,flags)assert(face=='native' and flags=='OUTLINE');self.size=size;self.writes=self.writes+1 end
 function f:GetText()return self.text end
 function f:SetText()error('native text changed')end
 return f
end
local function label(parent,size,text)
 local f=font(frame('FontString'),size,text);table.insert(parent.regions,f);return f
end
CollectionsJournal=frame();CollectionsJournal.protected=true
local ordinary=frame('Button',CollectionsJournal);ordinary.action=function()error('native action invoked')end
local action=ordinary.action;local text=label(ordinary,12,'Paladin');local large=label(ordinary,20,'Large')
local protected=frame('Button',CollectionsJournal);protected.protected=true;local protectedText=label(protected,12,'Protected')
local hidden=frame('Button',CollectionsJournal);hidden.hidden=true;local hiddenText=label(hidden,12,'Hidden')
local forbidden=frame('Button',CollectionsJournal);forbidden.forbidden=true;local forbiddenText=label(forbidden,12,'Forbidden')
local secret=label(ordinary,12,{secret=true});local search=font(frame('EditBox',CollectionsJournal),12,'');local placeholder=label(search,12,'Search')
local owned=frame('Frame',CollectionsJournal);function owned:GetName()return 'ForeverHandheldPanelCollections'end;local ownedText=label(owned,10,'FOREVER / COLLECTION')
dofile(arg[1]);local function tick()driver.OnUpdate(driver,.25)end;tick()
assert(text.size==16 and placeholder.size==16 and search.size==16 and search.height==26,'visible controls unreadable')
assert(large.size==20 and ordinary.action==action and text.text=='Paladin','native content/action or larger type changed')
assert(protectedText.writes==0 and hiddenText.writes==0 and forbiddenText.writes==0 and secret.writes==0,'guard failure')
local writes=text.writes+search.writes+placeholder.writes;tick();assert(writes==text.writes+search.writes+placeholder.writes,'settled presentation churn')
text.size=12;combat=true;tick();assert(text.size==12,'combat write');combat=false;tick();assert(text.size==16,'native reset not respected')
CollectionsJournal.hidden=true;text.size=12;tick();assert(text.size==12,'hidden root write')
assert(ownedText.size==10 and ownedText.writes==0,'owned editorial style overwritten')
assert(not ForeverHandheldDB.collectionTextError)
print('PASS: collection labels/search readability, native actions/text and larger fonts preserved; ordinary descendants under protected root; protected/forbidden/hidden/secret/combat guards; stable writes and native reset')

SocialUIFrame=frame();SocialUIFrame.protected=true
local socialRow=frame('Button',SocialUIFrame);local socialName=label(socialRow,12,'Native friend name')
tick();assert(socialName.size==16 and ForeverHandheldDB.socialText.count==1,'social ordinary label missing')
assert(text.size==12,'hidden collections changed while social open')
SocialUIFrame.hidden=true;socialName.size=12;tick();assert(socialName.size==12,'hidden social changed')
CollectionsJournal.hidden=false
local weapon=frame('DropdownButton');weapon.width=150
function weapon:GetWidth()return self.width end
function weapon:SetWidth(w)self.width=w;self.writes=self.writes+1 end
WardrobeCollectionFrame={ItemsCollectionFrame={WeaponDropdown=weapon}}
tick();assert(weapon.width==240,'weapon label remains truncated')
local ww=weapon.writes;tick();assert(weapon.writes==ww,'weapon width churn')
weapon.width=300;tick();assert(weapon.width==300,'larger native weapon control shrunk')
weapon.width=150;weapon.protected=true;tick();assert(weapon.width==150,'protected weapon control modified')
assert(not ForeverHandheldDB.collectionTextError)
print('PASS: independent social/collection visibility, native contact text retained, weapon width expanded only when needed with stable/protected guards')

UIParent={GetWidth=function()return 1280 end,GetEffectiveScale=function()return 1 end}
SocialUIFrame.hidden=false
local side=frame('Frame');side.width=292;side.left=900
function side:GetWidth()return self.width end
function side:SetWidth(w)self.width=w;self.writes=self.writes+1 end
function side:GetLeft()return self.left end
function side:GetEffectiveScale()return 1 end
local function button()
 local b=frame('Button');b.width=115
 b.GetWidth=side.GetWidth;b.SetWidth=side.SetWidth;return b
end
side.BlockButton=button();side.UnblockButton=button();SocialUIFrame.IgnoreListFrame=side
tick();assert(side.width==360 and side.BlockButton.width==155 and side.UnblockButton.width==155,'ignore footer cramped')
local sw=side.writes;tick();assert(side.writes==sw,'ignore width churn')
side.width=292;side.left=950;tick();assert(side.width==314 and side.width+side.left<=1264,'ignore list grew off-screen')
side.width=292;side.protected=true;tick();assert(side.width==292,'protected ignore list resized')
assert(not ForeverHandheldDB.collectionTextError)
print('PASS: native ignore list footer readability, screen-space cap, stable writes and protected guard')

-- The friend form has nested native ResizeLayoutFrames. Reflow must follow
-- typography changes but stop once stable, without changing form state/actions.
AddFriendFrame=frame('Frame');local form=frame('Frame',AddFriendFrame)
local nested=frame('Frame',form);local prompt=label(nested,12,'Enter character name')
local edit=font(frame('EditBox',form),12,'');local accept=frame('Button',form)
accept.enabled=false;accept.action=function()error('request submitted')end;local acceptAction=accept.action
for _,f in ipairs({AddFriendFrame,form,nested})do function f:MarkDirty()self.dirty=(self.dirty or 0)+1 end end
tick();assert(prompt.size==16 and edit.size==16 and edit.height==26)
assert(AddFriendFrame.dirty==1 and form.dirty==1 and nested.dirty==1,'nested native layout not invalidated')
tick();assert(AddFriendFrame.dirty==1 and form.dirty==1,'stable native layout churn')
assert(accept.action==acceptAction and accept.enabled==false and edit.text=='','native form state changed')
form.protected=true;prompt.size=12;tick();assert(form.dirty==1,'protected layout changed')
AddFriendFrame.hidden=true;prompt.size=12;tick();assert(prompt.size==12,'hidden friend form changed')
assert(not ForeverHandheldDB.collectionTextError)
print('PASS: friend form native text/edit sizing and nested reflow, stable layout, protected/hidden guards; no input, request or enabled-state mutation')

StaticPopup1=frame('Frame');function StaticPopup1:MarkDirty()error('addon entered native popup layout')end
local popupTitle=label(StaticPopup1,12,'Set Notes for a friend:')
local popupEdit=font(frame('EditBox',StaticPopup1),12,'');local popupButton=frame('Button',StaticPopup1);popupButton.action=acceptAction
local popupLabel=label(popupButton,12,'Cancel')
tick();assert(popupTitle.size==16 and popupEdit.height==26 and popupLabel.size==16,'popup text unreadable')
assert(StaticPopup1.dirty==nil and popupButton.action==acceptAction and popupEdit.text=='','popup behavior changed')
tick();assert(StaticPopup1.dirty==nil,'stable popup relayout')
assert(not ForeverHandheldDB.collectionTextError)
print('PASS: native popup text/entry readability without entering protected layout; content/actions retained')

PlayerSpellsFrame=frame('Frame');PlayerSpellsFrame.protected=true
local spellRow=frame('Frame',PlayerSpellsFrame);local spellText=frame('Frame',spellRow)
local spellName=label(spellText,16,'Holy Light');local spellRank=label(spellText,12,'Rank 2')
local spellButton=frame('Button',spellRow);spellButton.protected=true;spellButton.action=acceptAction
function spellText:MarkDirty()self.dirty=(self.dirty or 0)+1 end
local spellSearch=font(frame('EditBox',PlayerSpellsFrame),12,'')
local legend=frame('Frame',PlayerSpellsFrame);legend.promptFrames={};legend.ApplyDefaultPromptPositioning=function()error('legend layout invoked')end
local legendLabel=label(legend,12,'Edit Action Bar')
tick();assert(spellName.size==16 and spellRank.size==16 and spellText.dirty==1,'spell row text/reflow failed')
assert(spellSearch.height==26 and spellSearch.size==16 and spellSearch.text=='','spell search styling changed text')
assert(spellButton.action==acceptAction and not PlayerSpellsFrame.dirty,'protected spell controls changed')
assert(legendLabel.size==12,'native icon/text legend geometry changed')
tick();assert(spellText.dirty==1,'stable spellbook relayout')
assert(ForeverHandheldDB.spellBookText.font==16 and not ForeverHandheldDB.collectionTextError)
print('PASS: spellbook presentation descendants and search readability; protected spell actions and stable native layout retained')

for _,spec in ipairs({{'LFGParentFrame','groupFinderText'},{'CommunitiesFrame','guildText'},{'CommunitiesAvatarPickerDialog','communityIconText'}})do
 local root=frame('Frame');_G[spec[1]]=root
 local row=frame('Button',root);row.action=acceptAction;row.enabled=false
 local body=label(row,12,'Native group or guild information')
 local hints=frame('Frame',root);hints.promptFrames={};hints.ApplyDefaultPromptPositioning=legend.ApplyDefaultPromptPositioning
 local hint=label(hints,12,'Select')
 tick();assert(body.size==16 and body.text=='Native group or guild information','group/guild text unreadable')
 assert(row.action==acceptAction and row.enabled==false and hint.size==12,'group/guild action or native legend changed')
 assert(ForeverHandheldDB[spec[2]].font==16,'independent coverage missing')
 local settled=body.writes;tick();assert(body.writes==settled,'group/guild settled writes')
 root.hidden=true;body.size=12;tick();assert(body.size==12,'hidden group/guild modified')
end
assert(not ForeverHandheldDB.collectionTextError)
print('PASS: group finder and guild text, native actions/enabled states and legends retained; independent diagnostics, stable writes and hidden-root guard')

CommunitiesFrame.hidden=false
local guildFinder=frame('Frame',CommunitiesFrame);local disabled=frame('Frame',guildFinder)
CommunitiesFrame.GuildFinderFrame=guildFinder;guildFinder.DisabledFrame=disabled
disabled.Title=label(disabled,30,'Guild');disabled.Description=label(disabled,12,'Native guild information')
local description=disabled.Description
function description:ClearAllPoints()self.clears=(self.clears or 0)+1 end
function description:SetPoint(...)self.anchor={...}end
function description:SetJustifyV(v)self.justify=v end
local guildRow=frame('Button',CommunitiesFrame);guildRow.buttonContext='ButtonContext_CommunitiesListEntryButton'
guildRow.Name=label(guildRow,12,'Join or Create Community');guildRow.Name.SetPoint=description.SetPoint
tick();assert(description.anchor[1]=='TOP' and description.anchor[2]==disabled.Title and description.anchor[3]=='BOTTOM','guild paragraph overlaps title')
assert(description.height==180 and description.justify=='TOP' and description.text=='Native guild information','guild paragraph content changed')
assert(guildRow.Name.anchor[1]=='RIGHT' and guildRow.Name.anchor[4]==-6,'guild sidebar label padding unchanged')
tick();assert(description.clears==1,'guild layout churn')
assert(not ForeverHandheldDB.collectionTextError)
print('PASS: guild description below native title, sidebar label padding and stable presentation-only geometry')

LFGParentFrame.hidden=false;LFGBrowseFrame=frame('Frame',LFGParentFrame)
LFGBrowseFrame.SendMessageButton=button();LFGBrowseFrame.GroupInviteButton=button()
local category=button();category.width=118;category.x=70;category.y=-43
function category:GetPoint()return 'TOPLEFT',LFGBrowseFrame,'TOPLEFT',self.x,self.y end
function category:SetPoint(p,r,rp,x,y)assert(p=='TOPLEFT' and r==LFGBrowseFrame and rp=='TOPLEFT');self.x=x;self.y=y end
LFGBrowseFrame.CategoryDropdown=category
tick();assert(category.width==168 and category.x==20 and category.x+category.width==188 and category.y==-43,'category right edge shifted')
assert(LFGBrowseFrame.SendMessageButton.width==140 and LFGBrowseFrame.GroupInviteButton.width==140,'group footer labels cramped')
local cw=category.writes;tick();assert(category.writes==cw,'category geometry churn')
assert(not ForeverHandheldDB.collectionTextError)
print('PASS: complete group category/footer labels with preserved right edge, activity anchor and stable writes')

LFGWhoListFrame=frame('Frame',LFGParentFrame);local whoSearch=button();whoSearch.width=255;whoSearch.x=56;whoSearch.y=-40
whoSearch.GetPoint=category.GetPoint;whoSearch.SetPoint=category.SetPoint;LFGWhoListFrame.EditBox=whoSearch
tick();assert(whoSearch.width==291 and whoSearch.x==20 and whoSearch.x+whoSearch.width==311 and whoSearch.y==-40,'who search edge shifted')
local ww=whoSearch.writes;tick();assert(whoSearch.writes==ww and not ForeverHandheldDB.collectionTextError,'who search churn or error')
print('PASS: Who search widened into unused left margin with search/filter button anchors preserved')

-- Native list rows are recycled. Keep the widened level column readable and
-- cap long names at its edge without changing the row's checkbox or action.
LFGParentFrame=frame('Frame')
local activity=frame('Frame',LFGParentFrame)
LFGListingFrame={ActivityView=activity}
local levelRow=frame('Frame',activity)
levelRow.CheckButton=frame('CheckButton',levelRow);levelRow.CheckButton.action=acceptAction
levelRow.NameButton=frame('Button',levelRow)
local levelName=label(levelRow.NameButton,12,'A long native activity name')
local level=label(levelRow,12,'(8 - 25)')
levelRow.Level=level;levelRow.NameButton.Name=levelName
local play=frame('DropdownButton',activity);activity.PlayStyleDropdown=play;play.action=acceptAction
local ranges=label(activity,16,'Show All Level Ranges');activity.LevelRangesCheckbox={Text=ranges}
for obj,width in pairs({[level]=60,[levelName]=282,[play]=210})do
 obj.width=width;obj.GetWidth=side.GetWidth;obj.SetWidth=side.SetWidth
end
function level:GetLeft()return 410-self.width end
function level:GetJustifyH()return self.justify end
function level:SetJustifyH(value)self.justify=value;self.writes=self.writes+1 end
function levelName:GetLeft()return 60 end
play.x=28
function play:GetPoint()return 'TOPLEFT',activity,'TOPLEFT',self.x,-10 end
function play:SetPoint(_,_,_,x)self.x=x;self.writes=self.writes+1 end
function play:GetRight()return self.x+self.width end
function ranges:GetLeft()return 290 end
tick()
assert(level.width==88 and level.justify=='RIGHT' and levelName.width==254)
assert(play.x==10 and play.width==270 and ranges:GetLeft()-play:GetRight()>=10)
assert(level.text=='(8 - 25)' and play.action==acceptAction and levelRow.CheckButton.action==acceptAction)
local before=level.writes+levelName.writes+play.writes
tick();assert(level.writes+levelName.writes+play.writes==before,'activity columns churn')
level.width=60;levelName.width=271;level.text='(15 - 30)';tick()
assert(level.width==88 and levelName.width==254,'recycled activity text overlaps')
level.protected=true;level.width=60;play.width=210;ranges.GetLeft=function()return {secret=true}end
tick();assert(level.width==60 and play.width==210 and not ForeverHandheldDB.collectionTextError)
print('PASS: Group Finder activity columns and Playstyle fit, recycled rows, stable writes and native actions')

-- Native channel pools recycle rows and reset typography on channel changes.
ChannelFrame=frame('Frame');ChannelFrame.protected=true
local list=frame('ScrollFrame',ChannelFrame);ChannelFrame.ChannelList=list;list.buttons={}
local function channelRow(height,key,textValue)
 local row=frame('Button',list);row.height=height;row.width=175;row.point={'native',6,0};row.action=acceptAction
 local text=label(row,10,textValue);text.height=8;text.width=163;text.point={'LEFT',row,6,0};text.color='native-color';row[key]=text
 function row:SetSize()error('native channel row resized')end
 function row:SetWidth()error('native channel width changed')end
 function row:SetHeight()error('native channel height changed')end
 function row:SetPoint()error('native channel anchor changed')end
 function row:MarkDirty()error('native channel list rebuilt')end
 function text:SetWidth()error('native label width changed')end
 function text:SetPoint()error('native label anchor changed')end
 return row,text
end
local entry,entryText=channelRow(27,'Text','|cffffffff1. General|r')
local header,headerText=channelRow(19.99998664855957,'Text','World')
list.buttons={header,entry}
function list:Update()error('native channel update invoked')end
local roster=frame('Frame',ChannelFrame);ChannelFrame.ChannelRoster=roster
local scroll=frame('Frame',roster);roster.ScrollBox=scroll
local member,memberName=channelRow(22,'Name','Native member')
memberName.height=0;scroll.live={member}
function scroll:EnumerateFrames()return ipairs(self.live)end
local entryAnchor,memberAnchor=entryText.point,memberName.point
tick()
assert(entryText.size==16 and headerText.size==16 and memberName.size==16,'channel/roster text remains tiny')
assert(entryText.height==18 and headerText.height==18 and memberName.height==18,'channel text region still clips readable font')
assert(entryText.text=='|cffffffff1. General|r' and entryText.color=='native-color' and entryText.point==entryAnchor and memberName.point==memberAnchor,'native channel text/color/anchor changed')
assert(entry.height==27 and header.height==19.99998664855957 and member.height==22 and entry.width==175 and entryText.width==163 and entry.action==acceptAction,'native channel geometry/action changed')
local settled=entryText.writes+headerText.writes+memberName.writes;tick();assert(settled==entryText.writes+headerText.writes+memberName.writes,'settled channel type repeats writes')
-- Native reset and newly acquired/replaced pooled rows must be seen.
entryText.size=10;entryText.height=8;entryText.text='3. LocalDefense';tick()
assert(entryText.size==16 and entryText.height==18 and entryText.text=='3. LocalDefense','recycled channel label stale')
local replacement,replacementText=channelRow(27,'Text','Another channel');list.buttons={replacement};entryText.size=10;tick()
assert(replacementText.size==16 and entryText.size==10,'pooled row replacement ignored or released row still painted')
local function guardedRow(kind)
 local row,text=channelRow(27,'Text','Guarded')
 if kind=='short' then row.height=18 elseif kind=='protected' then row.protected=true elseif kind=='forbidden' then row.forbidden=true elseif kind=='hidden' then row.hidden=true elseif kind=='secret-row-height' then row.height={secret=true} elseif kind=='secret-text-height' then text.height={secret=true} elseif kind=='protected-label' then text.protected=true elseif kind=='forbidden-label' then text.forbidden=true elseif kind=='secret-text' then text.text={secret=true} elseif kind=='secret-font' then text.size={secret=true} elseif kind=='large-font' then text.size=20 elseif kind=='nan-font' then text.size=0/0 end
 return row,text
end
local guarded={}
for _,kind in ipairs({'short','protected','forbidden','hidden','secret-row-height','secret-text-height','protected-label','forbidden-label','secret-text','secret-font','large-font','nan-font'})do
 local row,text=guardedRow(kind);list.buttons[#list.buttons+1]=row;guarded[#guarded+1]={text,kind}
end
tick();for _,case in ipairs(guarded)do assert(case[1].writes==0,'channel guard failed: '..case[2])end
replacementText.size=10;replacementText.height=8;combat=true;tick();assert(replacementText.size==10,'channel mutated in combat');combat=false
ChannelFrame.hidden=true;tick();assert(replacementText.size==10,'hidden channel root modified');ChannelFrame.hidden=false;tick();assert(replacementText.size==16,'channel type failed to recover')
-- Classic hybrid-scroll fallback uses the existing visible button pool.
roster.ScrollBox=nil;roster.ScrollFrame=scroll;scroll.EnumerateFrames=nil;local classic,classicName=channelRow(22,'Name','Classic member');scroll.buttons={classic};tick();assert(classicName.size==16 and classicName.height==18,'classic roster labels omitted')
assert(not ForeverHandheldDB.collectionTextError and ForeverHandheldDB.channelText.font==16)
print('PASS: channel/header and modern/classic roster readability; native pooled text/colors/widths/anchors/actions preserved, small/protected/forbidden/secret/combat guards and settled writes')

-- Text-only roster has useful space past the native 140px name cap.
function member:GetRight()return 186 end
function member:IsVoiceEnabled()return self.voice or false end
function memberName:GetLeft()return 8 end
function memberName:GetWidth()return self.width end
function memberName:SetWidth(v)self.width=v;self.writes=self.writes+1 end
memberName.width=140;memberName.size=16.00000190734863
scroll.buttons={member}
roster.ChannelName=label(roster,10,'General');roster.ChannelName.height=13
tick();assert(memberName.width==170 and roster.ChannelName.size==14 and roster.ChannelName.height==16,'roster label width or heading')
local ready=memberName.writes;tick();assert(memberName.writes==ready,'roster width churn')
member.voice=true;memberName.width=113;tick();assert(memberName.width==113,'voice control inset lost')
member.voice=false;member.Rank=frame();memberName.width=140;tick();assert(memberName.width==140,'rank control inset lost')
member.Rank.hidden=true;member.SelfMuteButton=frame();memberName.width=98;tick();assert(memberName.width==98,'mute control inset lost')
member.SelfMuteButton.hidden=true;member.voice={secret=true};tick();assert(memberName.width==98,'secret voice state was used')
print('PASS: rounded native headers, settled font values, plain roster label width and title, voice and rank reservations')
