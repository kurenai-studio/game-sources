export default{

    uiMain(scene){
        scene.text_score=scene.add.text(30,30,"score: "+scene.score).setDepth(5)    
    },

    uiStart(scene,dead){
        if(dead){
           let txt=scene.add.text(140,260,'score: '+scene.score,{
            fontSize:'32px',
            }).setDepth(15) 
        }
       
        scene.add.image(0,0,'ui-bg',).setOrigin(0,0).setDepth(10).setAlpha(0.8)

       let play= scene.add.image(200,355,'ui-play',).setDepth(12).setInteractive().on('pointerdown',() => {
           if (dead) {
            scene._init=false
            scene.score=0
            scene.scene.restart("Level",)
            return
           }
           scene._init=false
        scene.scene.restart("Level",)
      })
      
      scene.add.image(360,scene.cameras.main.height/2,'right',).setDepth(12).setInteractive().on('pointerdown',() => {
            scene.active++
            if(scene.active>4)scene.active=1 
            
            scene.bg=scene.add.image(0,0,'bg'+scene.active).setOrigin(0,0)

      })

      scene.add.image(40,scene.cameras.main.height/2,'left',).setDepth(12).setInteractive().on('pointerdown',() => {
        scene.active++
            if(scene.active<1)scene.active=4 
            
            scene.bg=scene.add.image(0,0,'bg'+scene.active).setOrigin(0,0)
      })

       scene.add.image(30,40,'ui-leader',).setDepth(12).setScale(.5)

       scene.add.image(30,100,'ui-fb',).setDepth(12)

       scene.add.image(40,655,'ui-select-bird',).setDepth(12).setScale(.6).setInteractive().on('pointerdown',() => {
     scene.scene.start("MainMenu")
   })



    }
}