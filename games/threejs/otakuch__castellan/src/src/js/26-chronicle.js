/* ══════════════ 20 · the chronicle ══════════════
   Every holding gets a past. It is derived from its name, so the same name
   always yields the same founder, the same river and the same superstition —
   and then the chronicle keeps writing itself as you build and as days pass. */
function nameSeed(s){
  let h=2166136261>>>0;
  for(let i=0;i<s.length;i++){ h^=s.charCodeAt(i); h=Math.imul(h,16777619)>>>0; }
  return h>>>0;
}
const LORE={};
function makeLore(name){
  const r=mulberry32(nameSeed(name.toLowerCase()));
  const p=a=>a[Math.floor(r()*a.length)];
  const given=['Aldric','Ceawlin','Roheis','Ivo','Bertrand','Maud','Sighere','Odo','Alys',
               'Rainald','Godith','Warin','Emmeline','Thurstan','Isolde','Fulk'];
  const epithet=['the Reed','Stonefoot','the Patient','Redhand','the Quiet','Ninefingers',
                 'the Otter','Ashgrey','the Elder','Coldhand','the Wren','Ironbrow'];
  const river=['Aube','Vell','Marrow','Thirl','Sedge','Loach','Wenne','Colde','Brack'];
  const saint=['Ceneth','Aubine','Merrow','Halgar','Ivetta','Bardolf','Wilnoth'];
  const why=[
    'to hold the ford against the men who came up it every spring',
    'to watch the salt road where it bends around the marsh',
    'in payment for a wound taken at a battle nobody now remembers the name of',
    'because the old hall burned and the well was the only thing left worth keeping',
    'on the word of a surveyor who was wrong about almost everything else',
    'to spite a cousin who had built first, and worse, on the far bank'
  ];
  const relic=[
    'a saint&rsquo;s knucklebone in a lead box',
    'a banner so faded that nobody agrees what beast is on it',
    'a stone said to sweat before a hard winter',
    'a bell too cracked to ring and too holy to melt',
    'a key to a door that no longer exists'
  ];
  const omen=[
    'They say the well never freezes, and in the worst winter on record it did not.',
    'No dog will cross the causeway after Compline. The dogs have their reasons.',
    'The masons left one course deliberately crooked, so the work would not offend heaven.',
    'Swallows nest in the gatehouse arch. Turning them out is held to be very bad luck.',
    'The bell is rung twice at Vespers: once for the living, once for whoever built the first wall.',
    'A light is sometimes seen on the keep stair. The watch has stopped reporting it.'
  ];
  const year=1290+Math.floor(r()*30);
  LORE.name=name;
  LORE.founder=p(given)+' '+p(epithet);
  LORE.river=p(river);
  LORE.saint='St '+p(saint);
  LORE.year=year;
  LORE.text=
    '<p><b>'+name+'</b> was raised in the year '+year+' by '+LORE.founder+', '+p(why)+
    '. It stands above the '+LORE.river+', which is shallow enough to wade in August '+
    'and quite impossible in March.</p>'+
    '<p>The chapel, when there is one, is held to '+LORE.saint+', and keeps '+p(relic)+
    ' that has never been examined closely by anyone in a position to be disappointed.</p>'+
    '<p><i>'+p(omen)+'</i></p>';
  LORE.day=1;
  chronicle.length=0;
  chron('The first stone is laid.');
}
const chronicle=[];
const MONTH=['Spring','Summer','Harvest','Winter'];
function stamp(){
  return officeFor(hour)[1]+', day '+LORE.day+' of '+MONTH[season];
}
function chron(text,quiet){
  if(chronicle.length&&chronicle[0].text===text) return;
  chronicle.unshift({when:stamp(),text:text});
  if(chronicle.length>80) chronicle.pop();
  if(tab==='chronicle') drawChronicle();
  if(!quiet) markChron();
}
let chronUnread=0;
function markChron(){
  if(tab==='chronicle'){ chronUnread=0; return; }
  chronUnread++;
  const b=document.querySelector('#tabs button[data-t="chronicle"]');
  if(b) b.textContent='Chronicle ('+chronUnread+')';
}
function drawChronicle(){
  chronUnread=0;
  const b=document.querySelector('#tabs button[data-t="chronicle"]');
  if(b) b.textContent='Chronicle';
  const el=$('chronicle');
  if(!el) return;
  el.innerHTML='<div id="lore">'+(LORE.text||'')+'</div>'+
    chronicle.map(e=>'<div class="crow"><span class="cwhen">'+e.when+'</span>'+
                      '<span class="ctxt">'+e.text+'</span></div>').join('');
}

/* what is worth writing down */
const FIRST={};
const NOTE={
  keep:'The keep is up. It can be seen from the far side of the water.',
  gate:'A gatehouse. From today, everyone comes and goes by one road.',
  tower:'The first tower is finished, and someone is already standing on it.',
  wall:'The first course of the curtain wall is laid.',
  chapel:'A chapel, held to SAINT. The masons were paid in ale and thought it fair.',
  cottage:'The first cottage is roofed. Two souls move in before the thatch has settled.',
  mill:'The mill turns. The miller is said to be honest, which is unusual.',
  smithy:'A smithy. The ring of it carries further than anyone expected.',
  bakehouse:'A bakehouse. The ward smells of bread by Terce.',
  tavern:'A tavern opens. Vespers is noticeably better attended after it.',
  granary:'A granary, raised on staddle stones so the rats have to be inventive.',
  well:'The well is sunk. It comes in sweet, which nobody had promised.',
  pen:'A pen is fenced. The flock is driven in and objects loudly.',
  field:'The first strips are ploughed east of the walls.',
  orchard:'An orchard is planted. Nobody alive will see it at its best.',
  dovecote:'A dovecote. The doves arrive within the day, uninvited and permanent.',
  jetty:'A jetty runs out over the water. A fisher claims the end of it as his own.',
  beacon:'A beacon is set. It will be lit every night, and once in earnest.',
  bridge:'The water is bridged.',
  butts:'Marks are set up for the butts. The watch shoots badly and improves.',
  garden:'A herb garden is walled in against the goats.',
  hall:'A hall and stable. Horses in the yard by evening.',
  beehive:'Skeps are set on a bench. The bees settle in as though owed it.',
  stall:'A stall goes up in the ward. Trade, of a sort.'
};
function notePlaced(key){
  if(FIRST[key]) return;
  FIRST[key]=true;
  const t=NOTE[key];
  if(t) chron(t.replace('SAINT',LORE.saint||'the saint'));
}
function noteDay(){
  LORE.day++;
  const souls=world.count(C.HUMAN), beasts=world.count(C.BEAST);
  if(souls) chron('Day '+LORE.day+' begins. '+souls+' souls and '+beasts+
                  ' beasts, and the gate opens on time.');
  else chron('Day '+LORE.day+' begins over empty ground.');
}
function noteSeason(){
  const s=SN();
  chron(s.name+' comes in. '+s.note);
}

