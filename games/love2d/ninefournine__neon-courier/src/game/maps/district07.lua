-- Authored District 07 definition. Plain data only: the shared builder turns
-- it into nodes, buildings and bound helpers. All coordinates, destination
-- colors/names, the two shortcut alleys and the start pose match the original
-- hand-written map so the default district is preserved exactly.
return {
 id='district07', label='DISTRICT 07', subtitle='MIDNIGHT DISPATCH / OLD GRID',
 w=960,h=720,halfwidth=28,
 xs={96,288,480,672,864},ys={96,264,432,600},
 locations={
  {id='noodle',name='LUCKY CAT NOODLES',sign='LUCKY CAT',x=96,y=264,color={1,.64,.26},kind='noodle'},
  {id='garage',name='AFTERHOURS GARAGE',sign='AFTERHOURS',x=288,y=600,color={.35,.85,1},kind='garage'},
  {id='mart',name='24/7 NIGHT MART',sign='NIGHT MART',x=672,y=264,color={1,.4,.72},kind='mart'},
  {id='dock',name='PIER 09 LOADING',sign='PIER 09',x=864,y=600,color={.45,1,.76},kind='dock'},
  {id='clinic',name='SAINT STATIC CLINIC',sign='CLINIC',x=480,y=96,color={.45,1,.76},kind='clinic'},
  {id='club',name='VELVET FREQUENCY',sign='VELVET',x=96,y=600,color={1,.4,.72},kind='club'},
  {id='substation',name='SUBSTATION 03',sign='POWER 03',x=864,y=96,color={1,.64,.26},kind='power'},
  {id='dispatch',name='NIGHT DISPATCH',sign='DISPATCH',x=480,y=432,color={.35,.85,1},kind='dispatch'},
 },
 shortcuts={
  {x=384,y=264,h=168,width=24,col=2,row=2,nodeIds={21,22},attachments={{7,8},{12,13}},label={'CUT','THRU'}},
  {x=768,y=432,h=168,width=24,col=4,row=3,nodeIds={23,24},attachments={{14,15},{19,20}},label={'CUT','THRU'}},
 },
 spawnNodeIds={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20},
 start={x=480,y=432,angle=-math.pi/2},
 initialJobs={
  {locationId='noodle',kind='medical'},
  {locationId='mart',kind='prototype'},
  {locationId='dock',kind='battery'},
 },
 theme={},
}
