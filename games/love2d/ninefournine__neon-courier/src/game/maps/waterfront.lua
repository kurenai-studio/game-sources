-- Authored Waterfront definition. Same 960x720 grid and road centers as
-- District 07 so the two districts share driving feel; warehouses, the
-- coastal road at x=864 with its quay, and two 24px alleys make it distinct.
-- Plain data only; the shared builder generates nodes/buildings/helpers.
return {
 id='waterfront', label='WATERFRONT', subtitle='HARBOR DISPATCH / NIGHT TIDE',
 w=960,h=720,halfwidth=28,
 xs={96,288,480,672,864},ys={96,264,432,600},
 locations={
  {id='noodle',name='ANCHOR LIGHT NOODLES',sign='ANCHOR LIGHT',x=96,y=264,color={1,.64,.26},kind='noodle'},
  {id='garage',name='TIDEWAY GARAGE',sign='TIDEWAY',x=288,y=600,color={.35,.85,1},kind='garage'},
  {id='mart',name='NIGHT TIDE MARKET',sign='NIGHT TIDE',x=672,y=264,color={1,.4,.72},kind='mart'},
  {id='dock',name='PIER 12 LOADING',sign='PIER 12',x=864,y=600,color={.45,1,.76},kind='dock'},
  {id='clinic',name='HARBOR FIRST AID',sign='FIRST AID',x=480,y=96,color={.45,1,.76},kind='clinic'},
  {id='club',name='BRINE ROOM CLUB',sign='BRINE ROOM',x=96,y=600,color={1,.4,.72},kind='club'},
  {id='substation',name='BREAKWATER POWER',sign='BREAKWATER',x=864,y=96,color={1,.64,.26},kind='power'},
  {id='dispatch',name='HARBOR DISPATCH',sign='DISPATCH',x=480,y=432,color={.35,.85,1},kind='dispatch'},
 },
 shortcuts={
  {x=576,y=96,h=168,width=24,col=3,row=1,nodeIds={21,22},attachments={{3,4},{8,9}},label={'CUT','THRU'}},
  {x=768,y=264,h=168,width=24,col=4,row=2,nodeIds={23,24},attachments={{9,10},{14,15}},label={'CUT','THRU'}},
 },
 spawnNodeIds={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20},
 start={x=480,y=432,angle=-math.pi/2},
 initialJobs={
  {locationId='noodle',kind='medical'},
  {locationId='mart',kind='prototype'},
  {locationId='dock',kind='battery'},
 },
 theme={waterX=916,quayX=902,roadEndX=902,warehouses=true},
}
