pico-8 cartridge // http://www.pico-8.com
version 15
__lua__
--match3connect4
--@seansleblanc

function _init()
 board={}
 for y=0,7 do
  local r={}
  board[y]=r
  for x=0,7 do
   r[x]=0
  end
 end
 
 --attract
 for x=0,7 do
   for y=7,rnd(4)+4,-1 do
    board[y][x]=flr(rnd(2)+1)
   end
 end

 place={
  x=0,
  y=0,
  turn=1
 }
 light=7
 dark=6
 col={
  {8,2},
  {10,9},
  {light,dark}
 }

 parts={}
 lpart=1
 for i=1,512 do
  parts[i]={
   dead=true,
   vx=0,
   vy=0,
   x=0,
   y=0,
   r=0,
   c=7,
   t=0
  }
 end

 lerps={}
 placel={x=0,y=0}
 add(lerps,{place,placel,.2})

 anims={}

 anim(function()
 anim(function()
 mode="menu"
 music(0,1000)
 end,nil,function(self)
  local r=(self.p^2)*16
  for y=0,7 do
  for x=0,7 do
   circfill(x*16+8,y*16+8,16-r,0)
  end
  end
  draw_menu((1-self.p)^3*128)
 end,100)
 end,nil,function(self)
  cls()
 end,25)
 sfx(4)
end

function _draw()
 for i=0,500 do
  circ(i%128,rnd(128),2,0)
 end
 
 pal(12,1)
 pal(13,1)
 map(0,0,1,-2)
 pal()
 
 modes[mode].d()
 draw_parts()
 camera()
end

function _update60()
 modes[mode].u()
 for i=1,#parts do
  local p=parts[i]
  if not p.dead then
   p.x+=p.vx
   p.y+=p.vy
   p.vx*=.8
   p.vy*=.8
   p.t-=1
   if p.t <= 0 then
    p.dead=true
   end
  end
 end

 for k,l in pairs(lerps) do
  l[2].x=lerp(l[2].x,l[1].x,l[3])
  l[2].y=lerp(l[2].y,l[1].y,l[3])
 end
end
-->8
--logic helpers
function lerp(from,to,by)
 return from+(to-from)*by
end

function getdropy(x)
 for y=0,7 do
  if board[y][x] > 0 then
   return y
  end
 end
 return 8
end

function curpiece()
 return getpiece(place.y,place.x)
end

function getpiece(y,x)
 local r=board[y]
 if not r then
  return 0
 end
 if not r[x] then
  return 0
 end
 return r[x]
end

function update_pieces()
local blow={}
paths={}
--horizontal
for y=0,7 do
local p={}
for x=0,7 do
 add(p,{x=x,y=y})
end
add(paths,p)
end
--vertical
for x=0,7 do
local p={}
for y=0,7 do
 add(p,{x=x,y=y})
end
add(paths,p)
end
--diag
for y=-7,7 do
local p1={}
local p2={}
local p3={}
local p4={}
for a=0,y do
 add(p1,{y=y-a,x=a})
 add(p2,{y=7-y+a,x=7-a})
 add(p3,{y=y-a,x=7-a})
 add(p4,{y=7-y+a,x=a})
end
add(paths,p1)
add(paths,p2)
add(paths,p3)
add(paths,p4)
end

for k,path in pairs(paths) do
 local last=nil
 local cur=nil
 local seq={}
 for l,point in pairs(path) do
  local x=point.x
  local y=point.y
  cur=getpiece(y,x)
  if last~=nil and cur~=last then
   if last~=0 and #seq >= 3 then
    add(blow,seq)
   end
   seq={}
  end
  add(seq,{y=y,x=x})
  last=cur
 end
 if last~=0 and #seq >= 3 then
  add(blow,seq)
 end
end

local blewup=false
local victory={}
for k,seq in pairs(blow) do
 if #seq ~= 4 then
 local front=seq[1]
 local back=seq[#seq]
  --blow em up
  for l,spot in pairs(seq) do
   if getpiece(spot.y,spot.x)>0 then
    local c=getpiece(spot.y,spot.x)
    board[spot.y][spot.x]=0
    anim(function()
     blowup(spot.y,spot.x,c)
    end,function(self)
    end,function(self)
     draw_piece(
      spot.x+.5/16+(rnd()-.5)*.3*max(0,self.p-.25),
      spot.y+.5/16+(rnd()-.5)*.3*max(0,self.p-.25),
      c)
     line(
      front.x*16+6+rnd(4),
      front.y*16+6+rnd(4),
      back.x*16+6+rnd(4),
      back.y*16+6+rnd(4),
      col[c][flr(rnd(2))+1])
    end,60)
    blewup=true
   end
  end
 else
  add(victory,seq)
 end
end

for k,seq in pairs(victory) do
 local front=seq[1]
 local back=seq[#seq]
 for l,spot in pairs(seq) do
  local p=getpiece(spot.y,spot.x)
 if p>0 then
  board[spot.y][spot.x]=0
  anim(function()
   board[spot.y][spot.x]=p
  end,nil,function(self)
   draw_piece(
    spot.x,
    spot.y,
    3)
   line(
    front.x*16+6+rnd(4),
    front.y*16+6+rnd(4),
    back.x*16+6+rnd(4),
    back.y*16+6+rnd(4),
    col[3][flr(rnd(2))+1])
   end,60)
  end
 end
end

if blewup then
 sfx(12)
 --if things blew up, need to
 --check if things will fall
 anim(physics,nil,nil,65)
elseif #victory > 0 then
 --gameover!!!
 anim(function()
  local vboard={}
  for y=0,7 do
   local r={}
   vboard[y]=r
  for x=0,7 do
   r[x]=false
  end
  end
  
  winner=getpiece(victory[1][1].y,victory[1][1].x)
  for k,seq in pairs(victory) do
   if getpiece(seq[1].y,seq[1].x)!=winner then
    winner=3
   end
   for l,p in pairs(seq) do
    vboard[p.y][p.x]=true
   end
  end

  local d=0
  for y=0,7 do
  for x=0,7 do
   local p=getpiece(y,x)
   if p>0 and not vboard[y][x] then
    d+=5
    anim(function()
     blowup(y,x,p)
     board[y][x]=0
    end,nil,nil,
    d)
   end
  end
  end
  
  anim(function()
   mode="win"
   if winner == 3 then
    sfx(7)
   else
    sfx(4)
   end
   music(-1)
  end,nil,nil,d+50)
 
 end,nil,nil,65)
end

end

function physics()
--make pieces fall
local fell=false
for x=0,7 do
for y=6,0,-1 do
 local t=y+1
 if getpiece(y,x)>0 and getpiece(t,x)==0 then
  local c=getpiece(y,x)
  board[y][x]=0
  anim(function()
   board[t][x]=c
  end,function(self)
   draw_piece(
    x,
    lerp(y,t,self.p^2),
    c)
  end,nil,8+x-y)
  fell=max(fell,8+x-y)
 end
end
end

if fell then
 sfx(3)
 camera(0,1)
 --if something fell, need to
 --check if things keep falling
 anim(physics,nil,nil,fell+5)
else
 --if nothing fell, need to
 --check if things can blow up
 update_pieces()
end

end

function part()
 local p=parts[lpart]
 p.dead=false
 lpart=(lpart+1)%#parts+1
 return p
end

function anim(done,under,above,duration)
 add(anims,{
  done=done,
  t=duration,
  d=duration,
  under=under,
  above=above,
  p=0
 })
end

function blowup(y,x,t)
 sfx(0,1)
 local p=part()
 local x=x*16+8
 local y=y*16+8
 p.t=3
 p.x=x
 p.y=y
 p.c=col[t][2]
 p.r=15
 p.vx=0
 p.vy=0
 
 p=part()
 p.t=2
 p.x=x
 p.y=y
 p.c=col[t][1]
 p.r=16
 p.vx=0
 p.vy=0
 
 for i=0,10 do
 local p2=part()
 p=part()
 p.t=15+rnd(15)
 p2.t=p.t
 p.x=x
 p2.x=p.x
 p.y=y
 p2.y=p.y
 p.vx=rnd(8)-4
 p2.vx=p.vx
 p.vy=rnd(8)-4
 p2.vy=p.vy
 p.c=col[t][1]
 p2.c=col[t][2]
 p.r=rnd(2)
 p2.r=p.r+1
 end
end

function sparkle(x,y)
local p=part()
p.t=15+rnd(15)
p.x=x*16+8
p.y=y*16+8
p.vx=rnd(4)-2
p.vy=rnd(4)-2
p.c=col[place.turn][1]
p.r=rnd(2)
return p
end
-->8
--modes

modes={}
mode = "wait"

modes.win={
u=function()
 if press() then
  music(3)
  local d=0
  for y=0,7 do
  for x=0,7 do
   local p=getpiece(y,x)
   if p>0 then
    d+=5
    anim(function()
     blowup(y,x,p)
     board[y][x]=0
    end,nil,nil,d)
   end
  end
  end
  
  mode="wait"
 end
 
end,
d=function()
 draw_pieces()
 draw_board(true)
 
 local w={"red wins!","yellow wins!","it's a tie!"}
 w=w[winner]
 colpal(winner)
 for x=-1,1 do
 for y=-1,1 do
 print(w,x+64-#w*2,y+64-3,0)
 end
 end
 print(w,64-#w*2,64-3,7)
end
}

menuoptions={
{"start",function()
 local d=0
  for y=0,7 do
  for x=0,7 do
   local p=getpiece(y,x)
   if p>0 then
    d+=5
    anim(function()
     blowup(y,x,p)
     board[y][x]=0
    end,nil,nil,d)
   end
  end
  end
  
  anim(function()
   placel.x=-1
   mode="drop"
  end,nil,nil,d+50)
  mode="wait"
end},
{"how to play",function()mode="howto"end},
{"about",function()mode="about"end}
}
menuoption=0
modes.menu={
u=function()
 if press() then
  sfx(10)
  menuoptions[menuoption+1][2]()
  return
 end
 
 if btnp(⬆️) then
  menuoption-=1
  sfx(10)
 elseif btnp(⬇️) then
  menuoption+=1
  sfx(10)
 end
 menuoption%=#menuoptions
end,
d=function()
 draw_pieces()
 draw_board(true)
 draw_menu(0)
 
 for i=1,#menuoptions do
  local m=menuoptions[i]
  local s
  if i==menuoption+1 then
   s="> "..m[1].." <"
   colpal(flr(t()*2%2+1))
  else
   s=m[1]
   pal()
  end
  printc(s,64,64+22+10*i,7)
 end
end
}

modes.howto={
u=function()
if press() then
 mode="menu"
 sfx(10)
end
end,
d=function()
 draw_pieces()
 draw_board(true)
 draw_menu(0)
 
 pal()
 printc(
 "drop pieces in empty slots",
 64,64+22,7)
 printc(
 "swap pieces in filled slots",
 64,64+32,7)
 
 printc(
 "match 3+ to destroy pieces",
 64,64+42,7)
 
 printc(
 "connect exactly 4 to win",
 64,64+52,7)
end
}

modes.about={
u=function()
if press() then
 mode="menu"
 sfx(10)
end
end,
d=function()
 draw_pieces()
 draw_board(true)
 draw_menu(0)
 
 pal()
 printc("made by @seansleblanc",64,64+32,7)
 printc("for ludum dare 41",64,64+42,7)
 printc("with pico-8",64,64+52,7)
end
}

modes.wait={
u=function()
if #anims == 0 then
 --next turn
 anim(function()
  place.turn=(place.turn%2)+1
  sfx(5)
  if curpiece() > 0 then
   mode="pick"
  else
   mode="drop"
  end
 end,nil,nil,15)
end

for k,a in pairs(anims) do
 a.t-=1
 a.p=1-a.t/a.d
 if a.t<=0 then
  a.done()
  del(anims,a)
 end
end

end,
d=function()
 draw_pieces()
 for k,a in pairs(anims) do
  if(a.under)a:under()
 end
 draw_board(true)
 for k,a in pairs(anims) do
  if(a.above)a:above()
 end
end
}

modes.drop={
u=function()
if move() then
 sfx(10)
 if getpiece(place.y,place.x) > 0 then
  mode="pick"
 end
 return
end

if press() then
 --drop a piece
 sfx(1)
 local dropy=getdropy(place.x)-1
 anim(function()
  camera(0,-1)
  sfx(2)
  board[dropy][place.x]=place.turn
 
  for i=0,20 do
  local p=sparkle(place.x,dropy)
  if i==0 then
   p.r+=7
   p.t=2
   p.vx=0
   p.vy=0
   p.c=col[place.turn][2]
  end
  end
  
  update_pieces()
 end,
 function(self)
  draw_piece(place.x,lerp(-1,dropy,self.p^2),place.turn)
 end,
 nil,
 dropy*2+10)
 
 mode="wait"
end

end,
d=function()
 draw_pieces()
 
 colpal(place.turn)
 fillp(.6)
 local dropy=getdropy(place.x)
 local x=flr(lerp(placel.x,place.x,1.2)*16+7.5)
 for y=t()%2-2,dropy-.5 do
 rect(x,y*16,x+1,min(dropy*16-8,(y+.4)*16),light)
 end
 fillp()
 
 spr(0+t()*3%2,place.x*16+4,dropy*16-12)
 
 draw_board()
 draw_selector()
end
}

modes.pick={
u=function()
if move() then
 sfx(10)
 if getpiece(place.y,place.x) == 0 then
  mode="drop"
 end
 return
end

if press() then
 --select a piece to swap
 modes.swap.piece=curpiece()
 board[place.y][place.x]=0
 mode="swap"
 
 for i=0,20 do
  local p=sparkle(place.x,place.y)
  if i==0 then
   p.r+=7
   p.t=2
   p.vx=0
   p.vy=0
   p.c=col[place.turn][2]
  end
 end
 
 sfx(9)
end

end,
d=function()
 draw_pieces()
 draw_board()
 
 draw_selector()
 spr(0+t()*3%2,place.x*16+4,place.y*16+4)
end
}

modes.swap={
piece=nil,
u=function()

local ox=place.x
local oy=place.y
if move(true) then
 --try to swap pieces
 local b=curpiece()
 if (ox~=place.x or oy~=place.y) and b>0 then
  --swap
  local a=modes.swap.piece
  board[place.y][place.x]=0
  board[oy][ox]=0
  anim(function()
   board[place.y][place.x]=a
   board[oy][ox]=b
   update_pieces()
  end,
  function(self)
   local p=1-self.p^2
   draw_piece(
    lerp(ox,place.x,p),
    lerp(oy,place.y,p),
				b)
   end,
  function(self)
   local p=1-(1-self.p)^2
   draw_piece(
    lerp(ox,place.x,p),
    lerp(oy,place.y,p),
				a)
  end,
  16)
  mode="wait"
  sfx(6)
 else
  --invalid
  camera(ox-place.x,oy-place.y)
  place.x=ox
  place.y=oy
  sfx(8)
 end
 return
end

if press() then
 --cancel swap
 board[oy][ox]=modes.swap.piece
 mode="pick"
 sfx(11)
end

end,
d=function()
 draw_pieces()
 draw_board()
 
 local y = place.y
 local x = place.x
 draw_piece(
 x+(.5+cos(t()))/16,
 y+(.5+sin(t()))/16,
 modes.swap.piece)
 colpal(place.turn)
 local a=t()
 if getpiece(y-1,x) > 0 then
  spr(34+(a+.25)%2,x*16+4,y*16-4+2*sin(a+.00))end
 if getpiece(y+1,x) > 0 then
  spr(34+(a+.75)%2,x*16+4,y*16+13-2*sin(a+.11),1,1,false,true)end
 if getpiece(y,x-1) > 0 then
  spr(32+(a+.5)%2,x*16-4+2*sin(a+.22),y*16+4)end
 if getpiece(y,x+1) > 0 then
  spr(32+(a+1)%2,x*16+13-2*sin(a+.33),y*16+4,1,1,true,false)end
end
}
-->8
--drawing helpers
function colpal(t)
pal(light,col[t][1])
pal(dark,col[t][2])
end

function draw_menu(s)
 s+=1
 pal(light,0)
 pal(dark,0)
 for z=-1,1 do
 for w=-1,1 do
 for x=0,7 do
 for y=0,2 do
  spr(x+4+y*16,
   z+x*10+64-39+sin(t()/2+y/6+x/6)*s,
   w+y*9+64-13+cos(t()/2+y/6+x/6)*s
  )
 end
 end
 
 end
 end
 camera()
 for x=0,7 do
 for y=0,2 do
  colpal(flr(x/2+y+t()*4)%2+1)
  spr(x+4+y*16,
   x*10+64-39+sin(t()/2+y/6+x/6)*s,
   y*9+64-13+cos(t()/2+y/6+x/6)*s
  )
 end
 end
end

function draw_parts()
for i=1,#parts do
local p=parts[i]
if not p.dead then
circfill(p.x,p.y,p.r,p.c)
end
end
end

function draw_pieces()
 for y=0,7 do
  local r=board[y]
 for x=0,7 do
  local p=r[x]
  if p > 0 then
   draw_piece(x,y,p)
  end
 end
 end
end

function draw_piece(x,y,p)
 colpal(p)
 spr(2,x*16,y*16,1,1)
 spr(2,x*16+8,y*16,1,1,true)
 spr(2,x*16+8,y*16+8,1,1,true,true)
 spr(2,x*16,y*16+8,1,1,false,true)
end

function draw_board(neutral)
 colpal(place.turn)
 if neutral then
  pal()
 end
 map()
end

function draw_selector()
 colpal(place.turn)
 local a
 a=(sin(t())+1)*1.5
 fillp(.2)
 rect(placel.x*16+a,placel.y*16+a,(placel.x+1)*16-.001-a,(placel.y+1)*16-.001-a,dark)
 a=(sin(t()+.1)+1)*1.5
 rect(placel.x*16+a,placel.y*16+a,(placel.x+1)*16-.001-a,(placel.y+1)*16-.001-a,light)
 fillp()
end

-- dither helper
_fillp=fillp
fillp=function(f)
local d={
0,
0b1000000000000000.1,
0b1000000000100000.1,
0b1000000010100000.1,
0b1010000010100000.1,
0b1010010010100000.1,
0b1010010010100001.1,
0b1010010010100101.1,
0b1010010110100101.1,
0b1010110110100111.1,
0b1010111110101111.1,
0b1110111110101111.1,
0b1110111110111111.1,
0b1110111111111111.1,
0b1111111111111111.1,
0b1111111111111111.1
}
_fillp(d[flr(mid(0,f,1)*#d)])
end

function printc(s,x,y,c,o)
 for z=-1,1 do
 for w=-1,1 do
 print(s,x+z-#s*2,y+w-3,o or 0)
 end
 end
 print(s,x-#s*2,y-3,c)
end
-->8
--input

function move(nowrap)
if btnp(⬅️) then
 place.x-=1
elseif btnp(➡️) then
 place.x+=1
elseif btnp(⬆️) then
 place.y-=1
elseif btnp(⬇️) then
 place.y+=1
else
 return false
end

--edges
if nowrap then
 place.x=mid(0,place.x,7)
 place.y=mid(0,place.y,7)
else
 place.x%=8
 place.y%=8
end
return true
end

function press()
 return btnp(❎) or btnp(🅾️)
end
__gfx__
000000000000000000000000000000000000000077000077067777607777777767777776770000776777777600000000001cdcdcdcdcdcdcdcdcdcdcdcdcd100
00066000000770000000066600000000000000007760067767766776777777777777777777000077777777770000000001cdc111111dcdcdcdcdc111111dcd10
0067760000766700000667770000000000000000777777777700007700077000776000007700007700000077000000001cdc10000001dcdcdcdc10000001dcd1
067777600766667000677767000000000000000077677677777777770007700077000000777777770006777700000000cdc1000000001dcdcdc1000000001dcd
067777600766667000676777000000000000000077066077777777770007700077000000777777770006777700000000dc100000000001dcdc100000000001dc
006776000076670006777777000000000000000077000077770000770007700077600000770000770000007700000000c10000000000001dc10000000000001d
000660000007700006767777000000000000000077000077770000770007700077777777770000777777777700000000d10000000000001cd10000000000001c
000000000000000006777777000000000000000077000077770000770007700067777776770000776777777600000000c10000000000001dc10000000000001d
000000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000d10000000000001cd10000000000001c
000000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000c10000000000001dc10000000000001d
000000000000000000000000000000000000000000000000000000000000006776000000000000000000000000000000d10000000000001cd10000000000001c
000000000000000000000000000000000000000000000000000000000000777777770000000000000000000000000000cd100000000001cdcd100000000001cd
000000000000000000000000000000000000000000000000000000000000777777770000000000000000000000000000dcd1000000001cdcdcd1000000001cdc
000000000000000000000000000000000000000000000000000000000000006776000000000000000000000000000000cdcd10000001cdcdcdcd10000001cdcd
000000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000dcdcd111111cdcd66cdcd111111cdcdc
000000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000cdcdcdcdcdcdcd6776cdcdcdcdcdcdcd
000770000006600000077000000660006777777667777776770000777700007767777776677777767777777777000077dcdcdcdcdcdcdc6776dcdcdcdcdcdcdc
007670000067600000766700006776007777777777777777777000777770007777777777777777777777777777000077cdcdc111111dcdc66dcdc111111dcdcd
076677700677666007666670067777607760000077600677777700777777007777000000776000000007700077000077dcdc10000001dcdcdcdc10000001dcdc
766666676777777676666667677777767700000077000077776770777767707777776000770000000007700077777777cdc1000000001dcdcdc1000000001dcd
766666676777777677766777666776667700000077000077770776777707767777776000770000000007700067777777dc100000000001dcdc100000000001dc
076677700677666000766700006776007760000077600677770077777700777777000000776000000007700000000077c10000000000001dc10000000000001d
007670000067600000766700006776007777777777777777770007777700077777777777777777770007700000000077d10000000000001cd10000000000001c
000770000006600000077000000660006777777667777776770000777700007767777776677777760007700000000077c10000000000001dc10000000000001d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d10000000000001cd10000000000001c
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c10000000000001dc10000000000001d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d10000000000001cd10000000000001c
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cd100000000001cdcd100000000001cd
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dcd1000000001cdcdcd1000000001cdc
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001dcd10000001cdcdcdcd10000001cdc1
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001dcd111111cdcdcdcdcd111111cdc10
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001dcdcdcdcdcdcdcdcdcdcdcdcdc100
__map__
0c0d0e0d0e0d0e0d0e0d0e0d0e0d0e0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d1e1d1e1d1e1d1e1d1e1d1e1d1e1f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d2e2d2e2d2e2d2e2d2e2d2e2d2e2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d1e1d1e1d1e1d1e1d1e1d1e1d1e1f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d2e2d2e2d2e2d2e2d2e2d2e2d2e2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d1e1d1e1d1e1d1e1d1e1d1e1d1e1f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d2e2d2e2d2e2d2e2d2e2d2e2d2e2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d1e1d1e1d1e1d1e1d1e1d1e1d1e1f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d2e2d2e2d2e2d2e2d2e2d2e2d2e2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d1e1d1e1d1e1d1e1d1e1d1e1d1e1f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d2e2d2e2d2e2d2e2d2e2d2e2d2e2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d1e1d1e1d1e1d1e1d1e1d1e1d1e1f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d2e2d2e2d2e2d2e2d2e2d2e2d2e2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d1e1d1e1d1e1d1e1d1e1d1e1d1e1f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d2e2d2e2d2e2d2e2d2e2d2e2d2e2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3c3d3e3d3e3d3e3d3e3d3e3d3e3d3e3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01010000266732366321663112530e3430e2330922306213052130060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603
000300003c5203b5313957135561315612d5512b55125541205411853112521075110750105501000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
00020000036200c540036200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002a01021011170111001102011026210c54002620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0000180101f120240302424024050223501d05016450240502b1502e0502e2502e0502b35024050294502e050301503305035250370503a3503a0603a4703a0613a1513a0413a2313a0213a3113a0013a401
000f00000f515185350d5000d50024500245002450024500245000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
0002000007a500ba500f5500f550135501655018b50195501a55023b502ca502ca502da502da502ba500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000029e4027e5024e6022e501fe401de301be3018e3016e3013e3011e4011e700fe500fe700ce500ce600ae400ae500ae000ae000ae000ae000ae000ae0000e0000e0000e0000e0000e0000e0000e0000e00
010300001f3501f2401f2301f7201b3501b2401b2201b71025c0025c0025c0025c0025c0025c0025c0025c0025c0025c0024c0024c0024c0024c0024c0024c0024c0024c0000c0000c0000c0000c0000c0000c00
0002000015014150111502116031170411c041220312c035000000000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
000500001354300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503
000200002d014230111d0211803116041160411603114035000000000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
0110000002601036010461105611086210b6310e64100000000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000024a2200a0229a2230a221fa2200a0227a2227a2213a2200a021da2227a2200a021fa2227a2230a0227a2222a222ea2200a0229a221fa2200a0200a022ea2200a021fa2222a2200a0224a2227a2200a02
0110000011701117111172111721117211172111721117111d7011d7111d7211d7211d7211d7211d7211d71116701167111672116721167211672116721167111b7111b7211b7211b7211b7211b7211b7211b711
0110000018313117032b3131170311703117031b31311703183131d7031d703303131d7031d7031d7031d7031670316703333131670316703167031a3131a313163133370333703337032b31333703337033c313
01100000183131a113183131d3031d31311703183031a303183131d7031d703303131d7031f3031f3131f303167031670333313167031c313167031a3031a3031a3133370333703183132b303183131a31324313
0110000011505115151152511525115251152511525115151d5051d5151d5251d5251d5251d5251d5251d51516505165151652516525165251652516525165151b5151b5251b5251b5251b5251b5251b5251b515
0010000018a221ba3224a2224a221ba3218a5229a220aa4227a521da521da323aa2230a3216a5237a2224a3218a523ca3224a420aa5205a4216a5233a2222a423ca4237a323aa223fa323aa423ca423fa323ca42
__music__
00 10424344
00 10424344
00 104f4311
01 104f4311
00 104f1211
00 104f1214
00 104f1311
00 104f1214
00 104f1312
00 154f5114
00 134f1114
00 104f1112
00 154f1112
02 154f1014

