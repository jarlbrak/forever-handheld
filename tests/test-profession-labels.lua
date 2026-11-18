local combat,created=false,{}
STANDARD_TEXT_FONT='Native'
function InCombatLockdown()return combat end
function GetTime()return 100 end
function issecretvalue(v)return type(v)=='table'end
local function object()
 return {hidden=false,alpha=1,level=2,w=0,h=0,writes=0,
 IsShown=function(s)return not s.hidden end,IsForbidden=function(s)return s.forbidden end,
 GetAlpha=function(s)return s.alpha end,GetFrameLevel=function(s)return s.level end,
 Show=function(s)s.hidden=false;s.writes=s.writes+1 end,Hide=function(s)s.hidden=true;s.writes=s.writes+1 end,
 SetWidth=function(s,x)s.w=x;s.writes=s.writes+1 end,SetHeight=function(s,x)s.h=x;s.writes=s.writes+1 end,
 GetHeight=function(s)return s.h end,SetPoint=function(s,...)s.anchor={...};s.writes=s.writes+1 end,
 SetText=function(s,t)s.text=t;s.writes=s.writes+1 end,GetText=function(s)return s.text end,
 GetTextColor=function(s)return unpack(s.color or {1,.8,.4,1})end,
 SetTextColor=function(s,...)s.color={...};s.writes=s.writes+1 end,
 SetFont=function(s,face,size)s.size=size;s.writes=s.writes+1 end,
 SetJustifyH=function()end,SetJustifyV=function()end,
 GetStringHeight=function(s)return math.ceil(#(s.text or '')/25)*(s.size or 12)end}
end
function CreateFrame(_,name,parent)
 local f=object();f.parent=parent;f.name=name
 f.EnableMouse=function(s,b)s.mouse=b end;f.SetFrameLevel=function(s,l)s.level=l end
 f.CreateTexture=function()return {SetAllPoints=function()end,SetColorTexture=function()end}end
 f.CreateFontString=function(s)local r=object();s.fonts=s.fonts or {};s.fonts[#s.fonts+1]=r;return r end
 created[#created+1]=f;return f
end
local function native(text)
 local f=object();f.text=text;f.protected=true
 for _,k in ipairs({'SetText','SetTextColor','SetFont','SetWidth','SetHeight','SetPoint','Show','Hide'})do f[k]=function()error('native protected object mutated: '..k)end end
 return f
end
local book=native();book.ProfessionsContentFrame=native();local card=native();book.ProfessionsContentFrame.PrimaryProfession1=card
local button=native();card.SpellButton1=button;button.spellString=native('Blacksmithing');button.subSpellString=native('Apprentice')
local action=function()error('native action invoked')end;button.OnClick=action;button.binding='native';button.icon='native icon'
card.ProfessionName=native('Hidden duplicate');card.ProfessionName.alpha=0
card.missingText=native('Visit a trainer to learn this profession. Full native description remains available.')
dofile(arg[1]);local function tick()ForeverHandheldPaintProfessionLabels(book)end
combat=true;tick();assert(#created==0);combat=false;book.hidden=true;tick();assert(#created==0);book.hidden=false
tick();assert(#created==2 and ForeverHandheldDB.professionLabels.count==2,'copies missing or hidden duplicate exposed')
assert(created[1].fonts[1].text=='Blacksmithing' and created[1].fonts[2].text=='Apprentice' and created[1].fonts[1].size==16,'button labels incorrect')
assert(created[1].ForeverHandheldOwnedPresentation and created[2].ForeverHandheldOwnedPresentation,'owned label backdrops not protected from native artwork cleanup')
assert(created[1].mouse==false and created[1].parent==book and created[1].anchor[2]==button,'copy stole native input or wrong anchor')
assert(created[2].fonts[1].text==card.missingText.text and created[2].h>22,'full overview explanation not measured')
local function writes()local n=0;for _,f in ipairs(created)do n=n+f.writes;for _,t in ipairs(f.fonts)do n=n+t.writes end end;return n end
local n=writes();tick();assert(writes()==n,'settled copy churn')
button.spellString.text='Smelting';button.subSpellString.text='';tick();assert(created[1].fonts[1].text=='Smelting' and created[1].fonts[2].text=='','live native text not reflected')
button.hidden=true;tick();assert(created[1].hidden,'hidden native button left visible copy');button.hidden=false
button.spellString.text={};tick();assert(created[1].hidden,'secret label rendered');button.spellString.text='Smelting'
card.missingText.forbidden=true;tick();assert(created[2].hidden,'forbidden content rendered')
assert(button.OnClick==action and button.binding=='native' and button.icon=='native icon','native action/binding/icon changed')
print('PASS: protected overview labels copied without native writes; original text/color/actions/icons/bindings retained; noninteractive overlays, full explanation sizing, hidden/secret/forbidden/combat guards and stable writes')
