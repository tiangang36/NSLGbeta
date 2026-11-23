local E={}
function E.rollQuality(n)if n<=800 then return 5 elseif n<=3800 then return 4 else return 3 end end
function E.new(pools,balance,rng)
 local s={pools=pools,map={},balance=balance or 0,history={},inventory={},nextId=910000000,pity={},rng=rng or math.random}
 for _,p in ipairs(pools)do
  p.buckets={};p.complete=true
  for q=3,5 do p.buckets[q]={[1]={},[2]={}} end
  local seen={}
  for _,c in ipairs(p.cards)do local key=c.kind..':'..c.id;if p.buckets[c.quality] and p.buckets[c.quality][c.kind] and not seen[key]then local b=p.buckets[c.quality][c.kind];b[#b+1]=c;seen[key]=true end end
  for q=3,5 do for k=1,2 do if #p.buckets[q][k]==0 then p.complete=false end end end
  s.map[p.id]=p
 end
 s.selected=pools[1]and pools[1].id
 function s:select(id)if not self.map[id]then return false end;self.selected=id;return true end
 function s:setBalance(n)assert(type(n)=='number'and n>=0 and n<1e12);self.balance=math.floor(n)end
 function s:draw(id,count)
  local p=self.map[id];if not p then return nil,'Unknown pool' end
  if not p.complete then return nil,'Pool lacks hero/skill entries in a required rarity' end
  if count~=1 and count~=5 and count~=10 and count~=20 then return nil,'Invalid draw count' end
  local cost=count==5 and 390 or 80*count;if self.balance<cost then return nil,'Insufficient local test currency' end
  local key=tostring(id);local pity=self.pity[key]or 0;local cards={}
  for i=1,count do
   local q=pity>=19 and 5 or E.rollQuality(self.rng(10000));local kind=self.rng(2);local bucket=p.buckets[q][kind];local c=bucket[self.rng(#bucket)]
   self.nextId=self.nextId+1;cards[i]={cardID=c.id,cardType=kind,cardUniqueID=self.nextId,quality=q,packageId=id,level=1,isBreak=false,index=i};pity=q==5 and 0 or pity+1
  end
  self.balance=self.balance-cost;self.pity[key]=pity
  for _,c in ipairs(cards)do local k=c.cardType..':'..c.cardID;self.inventory[k]=(self.inventory[k]or 0)+1;self.history[#self.history+1]=c end
  return cards
 end
 return s
end
return E
