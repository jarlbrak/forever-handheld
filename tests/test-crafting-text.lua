local driver,combat
function CreateFrame()driver={SetScript=function(s,k,v)s[k]=v end};return driver end
function InCombatLockdown()return combat end
function GetTime()return 100 end
function issecretvalue(v)return type(v)=='table' end
local function frame()
 return {children={},regions={},IsShown=function(s)return not s.hidden end,IsProtected=function(s)return s.protected end,
 IsForbidden=function(s)return s.forbidden end,GetChildren=function(s)return unpack(s.children)end,GetRegions=function(s)return unpack(s.regions)end}
end
local function font(size,h)
 local f=frame();f.size=size;f.h=h;f.writes=0
 f.GetFont=function(s)return 'Native',s.size,'OUTLINE'end
 f.SetFont=function(s,face,size,flags)assert(face=='Native' and flags=='OUTLINE');s.size=size;s.writes=s.writes+1 end
 f.IsObjectType=function(_,t)return t=='FontString'end
 f.GetHeight=function(s)return s.h end;f.SetHeight=function(s,h)s.h=h;s.writes=s.writes+1 end
 return f
end
ProfessionsFrame=frame();local page=frame();ProfessionsFrame.CraftingPage=page
local list=frame();page.RecipeList=list;local row=frame();row.h=20;list.children={row}
local title=font(12,13);row.regions={title};row.selection='same';local action=function()error('native action called')end;row.OnClick=action
local search=font(12,20);search.IsObjectType=function()return false end;search.text='unchanged';list.SearchBox=search;list.children[#list.children+1]=search
page.CreateButton=frame();local create=font(12,12);page.CreateButton.regions={create};page.CreateButton.OnClick=action;page.CreateButton.enabled=false
page.GamepadCreateMultiple=frame();local desc=frame();local amount=font(12,12);desc.FontString=amount;desc.regions={amount};desc.w=45;desc.h=12;amount.w=45
for _,f in ipairs({desc,amount})do f.GetWidth=function(s)return s.w end;f.SetWidth=function(s,w)s.w=w end;f.GetHeight=function(s)return s.h end;f.SetHeight=function(s,h)s.h=h end end
page.GamepadCreateMultiple.ControlDescText=desc;page.GamepadCreateMultiple.children={desc}
page.SchematicForm=frame();local detail=font(12,50);page.SchematicForm.regions={detail}
dofile(arg[1]);local function tick()driver.OnUpdate(driver,.25)end
combat=true;tick();assert(title.size==12);combat=false
ProfessionsFrame.hidden=true;tick();assert(title.size==12);ProfessionsFrame.hidden=false
tick();assert(title.size==16 and title.h==20 and row.h==20,'recipe text/row geometry incorrect')
assert(search.size==16 and search.text=='unchanged' and create.size==16,'search or footer readability failed')
assert(row.OnClick==action and row.selection=='same' and page.CreateButton.OnClick==action and not page.CreateButton.enabled,'native actions/state changed')
assert(desc.w==110 and amount.w==110 and amount.h==20 and amount.size==16,'amount prompt clipped')
assert(detail.size==16 and detail.h==50,'schematic font did not enlarge or existing multiline height changed')
local n=title.writes+create.writes+search.writes;tick();assert(n==title.writes+create.writes+search.writes,'settled font churn')
row.protected=true;title.size=12;tick();assert(title.size==12,'protected row painted');row.protected=false
ProfessionsFrame.protected=true;page.protected=true;list.protected=true
tick();assert(title.size==16,'ordinary recipe below protected container skipped')
ProfessionsFrame.protected=false;page.protected=false;list.protected=false;title.size=12
title.forbidden=true;tick();assert(title.size==12,'forbidden font painted');title.forbidden=false
title.size={};tick();assert(type(title.size)=='table','secret font changed')
title.size=22;title.h=45;tick();assert(title.size==22 and title.h==45,'larger/multiline text shrunk')
assert(not ForeverHandheldDB.craftingTextError and ForeverHandheldDB.craftingText.visited<=160)
print('PASS: readable recipe/search/footer text, unchanged rows/actions/selection/search/disabled state; scoped schematic typography, stable writes and hidden/combat/protected/forbidden/secret guards')

row.Label=title;row.Count=font(16,20);row.Count.GetStringWidth=function()return 32 end;row.SkillUps=frame();row.SkillUps.GetWidth=function()return 26 end;row.GetWidth=function()return 300 end
title.size=16;title.w=90;title.GetWidth=function(s)return s.w end;title.SetWidth=function(s,w)s.w=w;s.writes=s.writes+1 end;title.GetUnboundedStringWidth=function()return 180 end
tick();assert(title.w==180,'native pre-font label measurement clipped recipe')
row.Count.GetStringWidth=function()return 150 end;tick();assert(title.w==114,'recipe overlapped count or skill icon')
local before=title.writes;tick();assert(title.writes==before,'settled recipe width churn')
row.protected=true;title.w=90;tick();assert(title.w==90,'protected recipe width changed')
print('PASS: long recipe remeasurement reserves native count/skill icon width; no row/action mutation or settled writes')

row.protected=false
local form=page.SchematicForm
local function flow(width,height,needed)
 local f=font(12,height);f.w=width;f.needed=needed
 f.GetWidth=function(s)return s.w end;f.SetWidth=function(s,w)s.w=w;s.writes=s.writes+1 end
 f.GetStringHeight=function(s)return s.needed end
 return f
end
form.OutputText=flow(100,12,32);form.RequiredTools=flow(250,12,48);form.Description=flow(305,14,64)
form.regions={form.OutputText,form.RequiredTools,form.Description}
local slot=frame();slot.Name=font(12,36);slot.Button=frame();slot.Checkbox=frame();slot.regions={slot.Name};slot.OnClick=action;slot.h=50;form.children={slot}
page.RankBar=frame();page.RankBar.Rank=frame();local rank=font(12,9);page.RankBar.Rank.Text=rank;page.RankBar.Rank.regions={rank};page.RankBar.children={page.RankBar.Rank}
tick();assert(form.OutputText.size==16 and form.OutputText.w==225 and form.OutputText.h==33,'output title not reflowed')
assert(form.RequiredTools.h==49 and form.Description.h==65,'requirements/description not fully measured')
assert(slot.Name.size==16 and slot.Name.h==48 and slot.h==50 and slot.OnClick==action,'reagent rows/actions changed or text not readable')
assert(rank.size==20 and rank.h==20,'scaled rank text remains tiny')
local total=form.OutputText.writes+form.RequiredTools.writes+form.Description.writes+rank.writes+slot.Name.writes;tick()
assert(total==form.OutputText.writes+form.RequiredTools.writes+form.Description.writes+rank.writes+slot.Name.writes,'settled detail text churn')
form.protected=true;form.Description.size=12;form.Description.h=12;slot.protected=true;slot.Name.h=36;tick()
assert(form.Description.size==12 and form.Description.h==12 and slot.Name.h==36,'protected detail changed')
form.protected=false;slot.protected=false
ProfessionsFrame.BookPage=frame();local book=ProfessionsFrame.BookPage;book.ProfessionsContentFrame=frame()
local overviewLabel=font(12,12);book.ProfessionsContentFrame.regions={overviewLabel};page.hidden=true
tick();assert(overviewLabel.size==16 and ForeverHandheldDB.craftingText.mode=='overview','overview text not enlarged')
book.hidden=true;overviewLabel.size=12;tick();assert(overviewLabel.size==12,'hidden overview changed')
assert(not ForeverHandheldDB.craftingTextError)
print('PASS: native description/requirements/title reflow, reagent row/action preservation, scaled rank readability, overview scope, stable writes and protected guards')
