-- Isaac-style paper silhouettes. Drawing only; never touches game RNG or data.
local theme = {}
local function rgb(r,g,b,a) return Color(r/255,g/255,b/255,a or 1,0,0,0) end
local c = {
 overlay=rgb(9,7,6,0.90), panel=rgb(153,134,109),
 border=rgb(23,19,17), button=rgb(170,151,126),
 buttonHover=rgb(190,168,139), field=rgb(145,126,103),
 white=rgb(30,24,21), dim=rgb(71,56,46),
 scrollbar=rgb(91,76,60), scrollbarThumb=rgb(43,35,30),
 selected=rgb(178,148,118), selectedText=rgb(62,18,17),
 spriteWhite=rgb(255,255,255), blood=rgb(143,10,13),
 bloodLight=rgb(192,43,38), bloodHighlight=rgb(226,91,72),
 bloodShadow=rgb(91,8,11), crease=rgb(117,100,81),
 edgeLight=rgb(186,167,139), shadow=rgb(9,6,5,0.83),
 shade=rgb(45,36,29,0.68), backSheet=rgb(94,76,59),
}
theme.colors=c

-- Native menu lettering replaces the outlined debug-console font.
local fonts={}
for _,name in ipairs({'teammeatfont10','teammeatfont16bold'}) do
 local f=Font()
 local ok=pcall(function() f:Load('font/'..name..'.fnt') end)
 if ok and f:GetStringWidth('ABC')>0 then fonts[name]=f end
end
function theme.text(text,x,y,scale,color)
 text=tostring(text or '')
 local heading=scale>=1.2
 local f=fonts[heading and 'teammeatfont16bold' or 'teammeatfont10']
 if not f or text=='' then return false end
 -- Preserve the existing measured widths, wrapping and cursor positions.
 local width=f:GetStringWidth(text)
 if width<=0 then return false end
 f:DrawStringScaled(text,math.floor(x),math.floor(y),
   Isaac.GetTextWidth(text)*scale/width,scale*(heading and 0.56 or 0.8),
   KColor(color.R,color.G,color.B,color.A),0,false)
 return true
end

-- Coarse scanlines form torn edges, rather than a rectangular bevel.
local function paper(rect,x,y,w,h,fill,edge)
 local step=3
 for yy=0,h-1,step do
  local row=math.floor(yy/step)
  local corner=(yy<5 or yy>h-7) and 4 or 0
  local left=corner+math.floor(1.5+1.5*math.sin(row*0.61)+1.2*math.sin(row*0.17))
  local right=corner+math.floor(2+1.4*math.sin(row*0.47+2)+1.2*math.sin(row*0.21))
  rect(x+left,y+yy,w-left-right,math.min(step,h-yy),edge)
 end
 for xx=5,w-6,8 do
  local top=2+math.floor(2+1.5*math.sin(xx*0.11)+1.2*math.sin(xx*0.047))
  local bottom=2+math.floor(2+1.6*math.sin(xx*0.087+1)+1.1*math.sin(xx*0.031))
  rect(x+xx,y+top,math.min(8,w-5-xx),h-top-bottom,fill)
 end
 -- Broad inner fill leaves only the uneven outline exposed.
 rect(x+4,y+7,w-9,h-14,fill)
end
local function stroke(rect,x,y,len,color,down)
 for i=0,len-1 do rect(x+i*2,y+(down and i or -i),3,1,color) end
end
local function stain(rect,x,y,scale)
 if scale then
  local draw=rect
  rect=function(px,py,w,h,color)
   draw(x+math.floor((px-x)*scale),y+math.floor((py-y)*scale),
    math.max(1,math.floor(w*scale)),math.max(1,math.floor(h*scale)),color)
  end
 end
 -- Uneven splat and long dried drips, like the pause-menu blot.
 local rows={{9,4},{5,12},{3,16},{0,22},{4,16},{2,20},{6,12},{7,10},{9,6}}
 for i,r in ipairs(rows) do rect(x+r[1],y+(i-1)*2,r[2],2,c.blood) end
 rect(x+10,y+16,3,19,c.blood);rect(x+11,y+34,2,7,c.blood)
 rect(x+18,y+17,2,9,c.blood)
 rect(x+1,y-3,3,4,c.blood);rect(x+19,y-5,3,5,c.blood)
 rect(x-4,y+12,3,2,c.blood);rect(x+26,y+20,2,3,c.blood)
end
-- Small stains and paper damage are tied to each rectangle's position.
-- They stay stable while the UI is open and never consume the game's RNG.
local function mark(rect,x,y,w,h,kind)
 local function pixel(dx,dy,pw,ph,col)
  if pw>0 and ph>0 then rect(x+dx,y+dy,pw,ph,col) end
 end
 if kind==0 then
  -- A blot hanging from the upper-left edge.
  pixel(8,2,11,3,c.blood);pixel(11,5,7,3,c.blood)
  pixel(13,8,3,math.min(7,h-10),c.blood)
  pixel(5,4,3,2,c.bloodLight);pixel(20,3,2,2,c.blood)
 elseif kind==1 then
  -- Blood soaked into the right edge, plus a small drip.
  pixel(w-9,5,7,4,c.blood)
  pixel(w-6,9,4,math.min(9,h-11),c.blood)
  pixel(w-12,7,3,2,c.bloodLight)
 elseif kind==2 then
  -- A scuffed, folded corner with a small red thumbprint.
  pixel(w-17,3,11,2,c.crease)
  pixel(w-12,5,6,2,c.edgeLight)
  pixel(w-8,8,4,3,c.blood)
  pixel(w-6,11,2,math.min(6,h-13),c.blood)
 elseif kind==3 then
  -- Specks underneath one edge.
  pixel(14,h-5,9,2,c.blood)
  pixel(17,h-7,4,3,c.bloodLight)
  pixel(27,h-6,2,2,c.blood)
 else
  pixel(w-21,h-5,8,2,c.crease)
  pixel(w-14,h-7,5,2,c.crease)
 end
end

local function pin(rect,x,y)
 rect(x-3,y-3,6,6,c.border);rect(x-4,y-1,8,3,c.border)
 rect(x-2,y-2,4,4,c.scrollbar);rect(x-2,y-2,3,2,c.edgeLight)
end
function theme.outline(rect,x,y,w,h,fill,border,t)
 if w<=0 or h<=0 then return end
 if w<22 or h<14 then
  rect(x,y,w,h,border);rect(x+1,y+1,w-2,h-2,fill);return
 end
 if fill==c.panel then
  paper(rect,x+8,y+10,w,h,c.shadow,c.shadow)
  paper(rect,x+3,y+5,w,h,c.backSheet,c.border)
  paper(rect,x,y,w,h,fill,border)
  -- An uneven fold catches light; the opposite side sinks into shade.
  rect(x+10,y+7,w-29,2,c.edgeLight)
  rect(x+w-9,y+13,2,h-29,c.shade)
  rect(x+17,y+h-10,w-35,2,c.shade)
  -- Scratches and pencil marks instead of speckled yellow parchment.
  for _,v in ipairs({{12,44,7},{w-28,15,5},{18,h-22,5},{w-34,h-15,8}}) do
   stroke(rect,x+v[1],y+v[2],v[3],c.crease,true)
   stroke(rect,x+v[1]+3,y+v[2]-4,math.max(2,v[3]-3),c.crease,true)
  end
  if w>130 and h>85 then
   stain(rect,x+w-29,y+h-59)
   stain(rect,x+7,y+h-39,0.55)
   stain(rect,x+w-65,y+9,0.6)
   pin(rect,x+12,y+10)
   mark(rect,x,y,w,h,1)
  end
  return
 end
 if fill==c.field and h>65 then
  -- Open paper workspace: no heavy inset-box frame.
  paper(rect,x+4,y+6,w,h,c.shade,c.shade)
  paper(rect,x+2,y+3,w,h,c.backSheet,c.crease)
  paper(rect,x,y,w,h,fill,c.crease)
  rect(x+7,y+5,w-18,1,c.edgeLight)
  rect(x+w-7,y+9,1,h-20,c.shade)
  if w>100 and h>90 then mark(rect,x,y,w,h,2) end
 else
  -- The raised slip has a dark offset shadow and a pale paper highlight.
  if w>45 and h>20 then
   rect(x+4,y+6,w-6,h-5,c.shadow)
   rect(x+3,y+4,w-5,h-5,c.backSheet)
  end
  rect(x+2,y+4,w-4,h-8,fill)
  for xx=2,w-3,6 do
   local sw=math.min(6,w-2-xx)
   local top=1+math.floor(1+math.sin(xx*0.09))
   local bottom=1+math.floor(1+math.sin(xx*0.075+1))
   rect(x+xx,y+top,sw,1,border)
   rect(x+xx,y+top+1,sw,h-top-bottom-2,fill)
   rect(x+xx,y+h-bottom-1,sw,1,border)
  end
  rect(x+1,y+4,1,h-8,border)
  rect(x+w-2,y+4,1,h-8,border)
  if w>45 and h>20 then
   rect(x+8,y+4,w-17,1,c.edgeLight)
   rect(x+w-5,y+7,1,h-12,c.shade)
  end
  if w>65 and h>21 then
   local variant=(math.floor(x/11)+math.floor(y/13)*3+math.floor(w/17))%5
   mark(rect,x,y,w,h,variant)
  end
 end
 if fill==c.buttonHover or fill==c.selected then
  -- Hand-inked selection arrow, like the original pause menu.
  local mid=y+h/2
  for i=0,3 do rect(x+5+i,mid-3+i,1,7-i*2,c.blood) end
 end
end
function theme.clippedAccent(rect,x,y,w,h,clip,fill)
 if fill~=c.buttonHover and fill~=c.selected then return end
 local top=math.max(y+3,clip.y)
 local bottom=math.min(y+h-3,clip.y+clip.h)
 if bottom>top then rect(x+2,top,2,bottom-top,c.blood) end
end
function theme.header(rect,cx,y,width)
 local half=math.min(width*0.28,90)
 for i=0,math.floor(half*2/5) do
  rect(cx-half+i*5,y+17+(i%3==0 and 1 or 0),5,1,c.white)
 end
end
return theme
