

const app = new Vue({
  el: '#app',
  data: {
    ui:false,
    lastType:null,
    time:{
      date:'10th January 2024',
      clock:'10:10 AM',
    },
    tool: 100,
    type:'car', 
    speedometer:{
      speed:79,
      nitro:0,
      fuel:0,
      engine:false,
      seatbelt:false,
      door:false,
      light:false
    },
    hud:{
      location:{
        location1:'Vespucci Boulevard',
        location2:'Vespucci',
      },
        health:{
          status:0
        },
        armor:{
          status:0
        },
        hunger:{
          status:0
        },
        water:{
          status:0
        },
        oxygen:{
          status:100
        },
        stress:{
          status:0
        },
        parachute:{
          variable:false,
          status:0
        },
        voice:false,
    },
   },
   methods: {

      openUrl(url) {
        window.invokeNative("openUrl", url);
        window.open(url, '_blank');
       },
     
        updateTime() {
          const options = { hour: '2-digit', minute: '2-digit', hour12: true };
          const now = new Date();
          this.time.clock = now.toLocaleTimeString('en-US', options);
      },

      beforeEnter(el) {
        el.style.opacity = 0;
        el.style.transform = 'translateY(100px)';
    },
    enter(el, done) {
        anime({
            targets: el,
            opacity: [0, 1],
            translateY: [100, 0], 
            duration: 500,
            easing: 'easeOutElastic(1, .8)', 
            complete: done
        });
    },
    leave(el, done) {
        anime({
            targets: el,
            opacity: [1, 0],
            translateY: [0, -100], 
            duration: 500,
            easing: 'easeInExpo', 
            complete: done
        });
    },
    
    null(type) {
      const element = this.$refs.x90;
      if (type === this.lastType) {
        return;
      }
      const commonProps = {
        targets: element,
        easing: 'easeInOutQuad', 
        duration: 800 
      };
      if (type === 'car') {
        anime({
          ...commonProps,
          keyframes: [
            { translateY: 50, opacity: 0.5, duration: 300 },
            { translateY: 0, opacity: 1, duration: 500 }
          ],
        });
      } else {
        anime({
          ...commonProps,
          keyframes: [
            { translateY: -50, opacity: 0.5, duration: 300 },
            { translateY: 100, opacity: 0, duration: 500 }
          ],
        });
      }
  
      this.lastType = type;
    },

    handleEventMessage(event) {
      const item = event.data;
      switch (item.data) {
          case 'CAR':
              this.null('car');
              Object.assign(this.speedometer, {
                  speed: item.speed,
                  fuel: item.fuel,
                  seatbelt: item.seatbelt,
                  light: item.state,
                  door: item.door
              });
              this.tool = item.tool;
              break;
          case 'CIVIL':
              this.null('');
              break;
          case 'STREET':
              Object.assign(this.hud.location, {
                  location1: item.street1,
                  location2: item.street2
              });
              break;
          case 'HEALTH':
            this.hud.health.status = item[1];
          case 'ARMOR':
            this.hud.armor.status = item[1];
          case 'OXYGEN':
              this.hud[item.data.toLowerCase()].status = item[1];
              break;
  
          case 'STATUS':
              Object.assign(this.hud, {
                  hunger: { status: item.hunger },
                  water: { status: item.thirst }
              });
              this.ui = true;
              break;
          case 'SOUND':
              switch (item.type) {
                  case 'isTalking':
                    if (item.value){
                      this.hud.voice = true;
                    }else {
                      this.hud.voice = false;
                    }
                      break;
                  case 'mic_level':
                      this.hud.microphone.status = item.value;
                      break;
                  case 'isMuted':
                      this.hud.voice = false;
                      break;
              }
              break;
          case 'EXIT':
              this.ui = item.args;
              break;
          case 'STRESS':
              this.hud.stress.status = item.stress;
              break
          case 'PARACHUTE':
               this.hud.parachute.status = item.value;
              break
          case 'PARACHUTE_SET':
               this.hud.parachute.variable = item.value;
              break
          case 'NITRO':
               this.speedometer.nitro = item[1]
               break
      }
  }
  

    },

    mounted() {
      this.updateTime();  
      setInterval(() => {
          this.updateTime();  
      }, 1000);
      const hasVisited = localStorage.getItem('hasVisitedEyestore');
      if (!hasVisited) {
        this.openUrl('https://eyestore.tebex.io');
        localStorage.setItem('hasVisitedEyestore', 'true');
      }
     }, 
    
    created() {
      window.addEventListener('message', this.handleEventMessage);
      const options = { year: 'numeric', month: 'long', day: 'numeric' };
      const today = new Date();
      this.time.date = today.toLocaleDateString('en-US', options);
    },

    computed: {

      dynamicClasses() {
        let additionalClasses = '';
        let styles = {};
    
        if (this.lastType === 'car') {
          additionalClasses = ' animate-slide-left';
          styles = {
            top: '69%',
            left: '1.5%',
          };
        } else {
          additionalClasses = ' animate-slide-up';
          styles = {
            top: '89%',
            left: '1.5%',
          };
        }
    
        return {
          class: additionalClasses,
          style: styles,
        };
      },
      
      limitedWidth() {
        const calculatedWidth = this.tool * 0.92;
        return calculatedWidth > 92 ? 92 : calculatedWidth;
      },

      Fuel() {
        return 390 + this.speedometer.fuel * 2.085;
      },

      Noss() {
        return 390 + this.speedometer.nitro * 2.085;
      },

      seatbelt() {
        return this.speedometer.seatbelt ? '#3CB0F2' : '#DFDFDF'; 
      },

      engine() {
        return this.speedometer.engine ? '#3CB0F2' : '#BFFF38';
      },


      light() {
        return this.speedometer.light ? '#BFFF38' : '#DFDFDF';
      },

      door() {
        return this.speedometer.door ? '#BFFF38' : '#FFFFFF';
      },

      seatbeltOpacity() {
        return this.speedometer.seatbelt ? 0.7 : 0.1;
      },
      
      engineOpacity() {
        return this.speedometer.engine ? 0.7 : 0.25;
      },

      lightOpacity() {
        return this.speedometer.light ? 0.7 : 0.1;
      },

      formattedSpeed() {
        let speed = this.speedometer.speed;
        if (speed == 0) {
          return `000`; 
        } else if (speed < 10) {
          return `00${speed}`; 
        } else if (speed < 100) {
          return `0${speed}`; 
        } else {
          return `${speed}`; 
        }
      },
      

      LocationClasses() {
        let classes = 'LOCATION absolute';
        if (this.speedometer == 'standart') {
            classes += ' animate-slide-left top-[59.75rem] left-[-6.5rem]';
        }
        else if (this.speedometer === 'car') {
            classes += ' animate-slide-bottom top-[46.25rem] left-[-8rem]';
        } 
        
        return classes;
      },
      
    }
  })
  















