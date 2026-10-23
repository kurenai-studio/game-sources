<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.11.2" name="game" tilewidth="128" tileheight="128" tilecount="13" columns="0">
 <editorsettings>
  <export target="../export/game.json" format="json"/>
 </editorsettings>
 <grid orientation="orthogonal" width="1" height="1"/>
 <tile id="0">
  <image source="images/item_star.png" width="128" height="128"/>
 </tile>
 <tile id="1">
  <image source="images/player.png" width="128" height="128"/>
 </tile>
 <tile id="3">
  <properties>
   <property name="field_portal_reverse" type="bool" value="false"/>
  </properties>
  <image source="images/tile_finish.png" width="128" height="128"/>
 </tile>
 <tile id="4">
  <image source="images/tile_portal.png" width="128" height="128"/>
 </tile>
 <tile id="5">
  <image source="images/tile_pushable.png" width="128" height="128"/>
 </tile>
 <tile id="6">
  <image source="images/tile_wall.png" width="128" height="128"/>
 </tile>
 <tile id="7">
  <image source="images/tile_floor_bg.png" width="128" height="128"/>
 </tile>
 <tile id="8">
  <image source="images/tile_corner_NE.png" width="128" height="128"/>
 </tile>
 <tile id="9">
  <image source="images/tile_corner_NW.png" width="128" height="128"/>
 </tile>
 <tile id="10">
  <image source="images/tile_corner_SE.png" width="128" height="128"/>
 </tile>
 <tile id="11">
  <image source="images/tile_corner_SW.png" width="128" height="128"/>
 </tile>
 <tile id="12">
  <image source="images/field_torch.png" width="128" height="128"/>
 </tile>
 <tile id="13">
  <properties>
   <property name="field_portal_reverse" type="bool" value="false"/>
  </properties>
  <image source="images/tile_portal_2.png" width="128" height="128"/>
 </tile>
</tileset>
