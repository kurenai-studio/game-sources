local D = {}
D.cargo = {
  prototype = {name='STOLEN PROTOTYPE', payout=260, modifier='POLICE HEAT +2 WHILE CARRIED', color={1,.35,.64}},
  medical = {name='MEDICAL SUPPLIES', payout=160, modifier='3 IMPACTS / +$25 PER INTEGRITY', color={.35,1,.8}},
  battery = {name='UNSTABLE BATTERY', payout=230, modifier='38 SECONDS / EXPIRY: -26 HULL', color={1,.72,.25}},
}
D.upgrades = {
  {id='turbo',name='TURBO',description='+18% boost speed per level',max=3},
  {id='grip',name='GRIP TIRES',description='+25% turning / +20% grip per level',max=3},
  {id='chassis',name='REINFORCED CHASSIS',description='+25 max hull / repair 35 hull',max=3},
  {id='ram',name='RAM PLATING',description='-20% impact damage / stun cops +1s',max=3},
  {id='emp',name='EMP CAPACITOR',description='-2s cooldown / +25px radius per level',max=3},
  {id='cargo',name='CARGO PROTECTION',description='+1 medical integrity / +8s battery',max=3},
}
D.controls = {boost='SPACE / A',emp='X / B',pause='ESC / START',confirm='ENTER / A',back='ESC / B'}
return D
