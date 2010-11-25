/*
      * Author::    Andreia Luna (mailto: amluna@inf.puc-rio.br)
      * ---
      * WUI-Runtime-JS Library
      * These functions provide the interface with behaviour
      * ---
*/

// Animation Hashes
var onEvent = new Object() ;        // maps events into animations
var eventAction = new Object() ;    // maps events into action
var animation = new Object() ;      // animation's properties
var transition = new Object();      // interface's transitions
var rhetStructOrder = new Object(); // transitions' rhetorical structures list
var animationSeq = new Object();    // rhetorical structures' animations list
var transInterfMap = new Object();   // maps interfaces into entry transitions
var animWidMap = new Object();      // maps widgets into animations
var registeredEvents = new Object(); // registered events for a widget
var insertAnimWidgets = new Object(); // keeps track of widgets whose insertion was already animated

// Creates animation hashes
function createAnimHashes () {
   getEvents(0);
}

// Calls get_events action in AnimationsController
function getEvents(i) {
      interfaceName = interfaces[i];
      if (interfaceName == undefined) {
         registerListeners();
         getDecorations(0);
         return;
      }
      response = readEvents(interfaceName);
      if (response != "") { parseMetadataResponse(response, "createOnEventHash"); }
      getEvents(i+1);
}

// Calls get_animations action in AnimationsController
function getDecorations(i) {
      interfaceName = interfaces[i];
      if (interfaceName == undefined) {
        // I'm testing this along with the animWidMap setting inside the createAnimationSeqHash function
         transition['to'] = new Object();
         transition['from'] = new Object();
         transition['fromTo'] = new Object();
         getTransitions(0); 
         return;
      }
      response = readDecorations(interfaceName);
      if (response !="") { parseMetadataResponse(response, "createAnimationHash"); }
      getDecorations(i+1);
}

// Calls get_transitions action in AnimationsController
function getTransitions(i) {
      interfaceName = interfaces[i];
      if (interfaceName == undefined) {
         callUpdateInterfaces(); 
         return;
      }
      response = readTransitions(interfaceName);
      if (response !="") { parseMetadataResponse(response, "createTransitionHash"); }
      getTransitions(i+1);
}


// Sets onEvent and eventAction hashes
function createOnEventHash(eventObject) {
   if (onEvent[eventObject.event] == undefined) { onEvent[eventObject.event] = new Object() ; }
   onEvent[eventObject.event][eventObject.widget] = eventObject.rhetStruct.rhetStructId;
   initAnimationSeqHash(eventObject.rhetStruct);
   if (eventObject.action != "")  {
      if (eventAction[eventObject.event] == undefined) { eventAction[eventObject.event] = new Object() ; }
      eventAction[eventObject.event][eventObject.widget] = eventObject.action + ";" + eventObject.target + ";" + eventObject.transition;
   }
}

// Sets animation hash
function createAnimationHash(animationObject) {
   if (animation[animationObject.animation] == undefined) { animation[animationObject.animation] = new Object() ; }
   animation[animationObject.animation]['type'] = animationObject.type;
   if (animation[animationObject.animation]['widget'] == undefined) { animation[animationObject.animation]['widget'] = new Object(); }
   for (i=0; i<2; i++) {
      animation[animationObject.animation]['widget'][i] = animationObject.widget[i];
   }
   if (animation[animationObject.animation]['effect'] == undefined) { animation[animationObject.animation]['effect'] = new Object(); }
   animation[animationObject.animation]['effect']['name'] = animationObject.effect.name;
   animation[animationObject.animation]['effect']['params'] = animationObject.effect.params;
}

// Sets rhetStructOrder hash
function createRhetStructOrderHash(transitionId,rhStructList,ord,rhSt,interfToShow) {
   rhetStructOrder[transitionId][rhSt] = new Object();
   rhetStructOrder[transitionId][rhSt]["ord"] = ord;
   rhetStructOrder[transitionId][rhSt]["list"] = "";
   for (var i=0; i<rhStructList.length; i++) {
      rhStructObj = rhStructList[i];
      if (rhStructObj.rhetStructId != undefined) {
         // no more recursive calls - we've reached the last level
         rhetStructOrder[transitionId][rhSt]["list"] += "Id#";
         rhetStructOrder[transitionId][rhSt]["list"] += rhStructObj.rhetStructId;
         rhetStructOrder[transitionId][rhSt]["list"] += ";" ;
         initAnimationSeqHash (rhStructObj, interfToShow);
      } else {
         // calculates the next rhetStruct Id
         var nxtRhSt = rhSt;
         do {
            nxtRhSt++;
         } while (rhetStructOrder[transitionId][nxtRhSt] != undefined)
         rhetStructOrder[transitionId][rhSt]["list"] += "rS#";
         rhetStructOrder[transitionId][rhSt]["list"] += nxtRhSt;
         rhetStructOrder[transitionId][rhSt]["list"] += ";" ;
         if (rhStructObj.rhetStructsOrd != undefined) {
            createRhetStructOrderHash(transitionId,rhStructObj.rhetStructsOrd,"seq",nxtRhSt,interfToShow);
         } else if (rhStructObj.rhetStructsPll != undefined) {
            createRhetStructOrderHash(transitionId,rhStructObj.rhetStructsPll,"par",nxtRhSt,interfToShow);
         }
      }
   }
}


// Sets transition and rhetStructOrder hashes
function createTransitionHash(transitionObject) {
   transitionId = transitionObject.transition;
   source = transitionObject.from;
   target = transitionObject.to;
   if (source == "") {
      //if (transition['to'] == undefined) { transition['to'] = new Object(); }
      transition['to'][target] = transitionId;
      animWidMap[target] = new Object();
      transInterfMap[target] = transitionId;

   } else {
      if (target == "") {
         //if (transition['from'] == undefined) transition['from'] = new Object();
         transition['from'][source]= transitionId
      } else {
         //if (transition['fromTo'] == undefined) transition['fromTo'] = new Object();
         if (transition['fromTo'][source] == undefined) transition['fromTo'][source] = new Object();
         transition['fromTo'][source][target] = transitionId
         animWidMap[target] = new Object();
         transInterfMap[target] = transitionId;
      }
   }

   rhetStructOrder[transitionId] = new Object();
   if (transitionObject.rhetStructsOrd != undefined) {
      createRhetStructOrderHash(transitionId,transitionObject.rhetStructsOrd,"seq",1,target);
   } else if (transitionObject.rhetStructsPll != undefined) {
      createRhetStructOrderHash(transitionId,transitionObject.rhetStructsPll,"par",1,target);
   }
   
   /*
   rhStructList = transitionObject.rhetStructs;
   rhetStructOrder[transitionId] = "";
   for (var i=0; i<rhStructList.length; i++ ) {
      rhStruct = rhStructList[i];
      rhetStructOrder[transitionId] += rhStruct.rhetStructId;
      rhetStructOrder[transitionId] += ";";
      createAnimationSeqHash(rhStruct);
   }
   
   */
}

// Sets up animationSeq hash 
function initAnimationSeqHash (rhStructObj, interfToShow) {
   animationSeq[rhStructObj.rhetStructId] = new Object();
   if (rhStructObj.animationsSeq != undefined) {
      createAnimationSeqHash(rhStructObj.rhetStructId,rhStructObj.animationsSeq,"seq",1, interfToShow);
   } else if (rhStructObj.animationsPll != undefined) {
      createAnimationSeqHash(rhStructObj.rhetStructId,rhStructObj.animationsPll,"par",1, interfToShow);
   }
}

// Sets animationSeq hash
function createAnimationSeqHash(rhetStructId,animationList,ord,animat,interfToShow) {
   animationSeq[rhetStructId][animat] = new Object();
   animationSeq[rhetStructId][animat]["ord"] = ord;
   animationSeq[rhetStructId][animat]["list"] = "";
   for (var i=0; i<animationList.length; i++) {
      animationObj = animationList[i];
      if (typeof animationObj != "object") {
         // no more recursive calls - we've reached the last level
         animationSeq[rhetStructId][animat]["list"] += "Id#";
         animationSeq[rhetStructId][animat]["list"] += animationObj;
         animationSeq[rhetStructId][animat]["list"] += ";" ;
         if (interfToShow != undefined && interfToShow != "") {
            animWidMap[interfToShow][animation[animationObj]['widget'][0]] = animationObj;
         }
      } else {
         // calculates the next animation Id
         var nxtAnimat = animat;
         do {
            nxtAnimat++;
         } while (animationSeq[rhetStructId][nxtAnimat] != undefined)
         animationSeq[rhetStructId][animat]["list"] += "an#";
         animationSeq[rhetStructId][animat]["list"] += nxtAnimat;
         animationSeq[rhetStructId][animat]["list"] += ";" ;
         if (animationObj.animationsSeq != undefined) {
            createAnimationSeqHash(rhetStructId,animationObj.animationsSeq,"seq",nxtAnimat,interfToShow);
         } else if (animationObj.animationsPll != undefined) {
            createAnimationSeqHash(rhetStructId,animationObj.animationsPll,"par",nxtAnimat,interfToShow);
         }
      }
   }

   /*
   animationSeq[rhStruct.rhetStructId] = "";
   for (var i=0; i<rhStruct.animations.length; i++) {
      animationSeq[rhStruct.rhetStructId] += rhStruct.animations[i]
      animationSeq[rhStruct.rhetStructId] += ";"
   }
   */
   
}

// Adds event listeners to the widgets in the page
function registerListeners() {
   for (var event in onEvent) {
      for (var widget in onEvent[event]) {
         var widgetTarget = document.getElementById(widget);
         if (widgetTarget != null) { manageEvent(widgetTarget,event); }
      }
   }
}

// Chains an event handler to a widget
function manageEvent(widgetTarget,event) {
   
   // Keeps track of which events are registered for a widget
   if (registeredEvents[widgetTarget.id] == undefined) { registeredEvents[widgetTarget.id] = new Object() ; }
   registeredEvents[widgetTarget.id][event]="";
   widgetTarget.addEventListener(event, function (event) {
      eventHandler(this.id, event.type)
   }
      ,false);
   
}

// Triggers an animation when an event occurs.
function eventHandler(widgetA, event, instanceId) {
   // checks if the event on the widget triggers an animation sequence
   // and calls performRhetStructure function
   var rhetStructId = onEvent[event][widgetA];
   if (rhetStructId != undefined) {
      performRhetStructure(rhetStructId, undefined);
      /*
      var animationList = animationSeq[rhetStructId][1]["list"];
      var i=0;
      do {
         animationId = swui_piece(animationList, ";", i, i+1);
         if (animationId != "") {
            performAnimation(swui_piece(animationId,"#",1), undefined, instanceId);
         }
         i++;
      } while (animationId != "")
      */
   }
   // checks if the event on the widget triggers an action in Model
   var evtAct = eventAction[event]
   if (evtAct != undefined) {
      evtAct = eventAction[event][widgetA];
      if (evtAct != undefined) {
         var action = swui_piece(evtAct,";",0,1);
         var targetInterface = swui_piece(evtAct,";",1,2);
         var transitionInterface = swui_piece(evtAct,";",2);
         var activator = document.getElementById(instanceId);
         var sourceInterface = findInterface(activator);
         callAction(action, activator, sourceInterface, targetInterface, transitionInterface);
      }
   }
}

// Performs a set of ordered transition rhetorical structures
function performTransition(transitionId) {

   return traverseRhetTree(rhetStructOrder[transitionId][1]["list"], rhetStructOrder[transitionId][1]["ord"], 0, transitionId);

}

// Traverses rhetStructOrder hash
function traverseRhetTree(list, ord, animationDelay, transitionId) {
    
    var parAnimationDelay = animationDelay;
    var i=0;

    do {
        var obj = swui_piece(list, ";", i, i+1);
        if (obj != "") {
            var t = swui_piece(obj,"#",0,1);
            var rhetStructId = swui_piece(obj,"#",1);
            var delay;
            if (t == "Id") {
               var childOrd = animationSeq[rhetStructId][1]["ord"];
               delay = performRhetStructure(rhetStructId, animationDelay);
               // it's a leaf in the tree
               if (ord == "seq") {
                  // series 
                  if (childOrd == "seq") {
                       animationDelay = delay;
                  } else {
                       animationDelay += delay;
                  }
               } else {
                  // parallel
                  parAnimationDelay = Math.max(parAnimationDelay,delay);
               }
            } else {
               // it's a pointer to an internal node in the tree
               var childOrd = rhetStructOrder[transitionId][rhetStructId]["ord"];
               var delay = 0;
               delay = traverseRhetTree(rhetStructOrder[transitionId][rhetStructId]["list"], rhetStructOrder[transitionId][rhetStructId]["ord"], animationDelay, transitionId);
               if (ord == "seq") {
                  // series 
                  if (childOrd == "seq") {
                       animationDelay = delay;
                  } else {
                       animationDelay += delay;
                  }
               } else {
                  // parallel
                  parAnimationDelay = Math.max(parAnimationDelay,delay);
               }
            }
        }
        i++;
    } while (obj != "")
    
  if (ord == "par") {
     return parAnimationDelay;   
  } else {
     return animationDelay;
  }
}

// Performs a sequence of animations
function performRhetStructure(rhetStructId, animationDelay) {
   if (animationSeq[rhetStructId] != undefined) {
      return traverseAnimTree(animationSeq[rhetStructId][1]["list"], animationSeq[rhetStructId][1]["ord"], animationDelay, rhetStructId);
   } else {
      return 0;
   }

}

// Traverses animationSeq hash
function traverseAnimTree(list, ord, animationDelay, rhetStructId) {
    var parAnimationDelay = animationDelay;
    var i=0;

    do {
        var obj = swui_piece(list, ";", i, i+1);
        if (obj != "") {
            var t = swui_piece(obj,"#",0,1);
            var animationId = swui_piece(obj,"#",1);
            if (t == "Id") {
               // it's a leaf in the tree
               var delay = 0;
               delay = performAnimation(animationId, animationDelay);
               if (ord == "seq") {
                  // series 
                  animationDelay += delay
               } else {
                  // parallel
                  parAnimationDelay = Math.max(parAnimationDelay,delay);
               }
            } else {
               // it's a pointer to an internal node in the tree
               var childOrd = animationSeq[rhetStructId][animationId]["ord"];
               var delay = 0;
               delay = traverseAnimTree(animationSeq[rhetStructId][animationId]["list"], childOrd, animationDelay, rhetStructId);
               if (ord == "seq") {
                  // series
                  if (childOrd == "seq") {
                       animationDelay = delay;
                  } else {
                       animationDelay += delay;
                  }
               } else {
                  // parallel
                  parAnimationDelay = Math.max(parAnimationDelay,delay);
               }                    
            }
          }
          i++;
    } while (obj != "")
    
  if (ord == "par") {
     return parAnimationDelay;   
  } else {
     return animationDelay;
  }
}

// Performs an animation upon a widget 
function performAnimation(animationId, seriesDelay, instanceId) {

   // retrieves the effect along with the duration and
   // applies the effect on the widget(s)
   var animationDelay = 0;
   var functionCall = "";
   var animatedWidgetA = animation[animationId]['widget'][0];
   var animatedWidgetB = animation[animationId]['widget'][1];
   var type = animation[animationId]['type']
   switch (type) {
      case 'emphasize':
         if (instanceId != undefined) {
            animatedWidgetA = instanceId
         }
         _applyEffect(animatedWidgetA);
         break;

      default:
         // insert, remove, match or trade transitions
         _performAnimation();
         break;
   }
   
   return animationDelay;

   function _performAnimation() {
      var i=0;
      var responseArray = [];
      var widAList = widgetsFromTemplate[animatedWidgetA]; // findWidgetsFromTemplate ??
      if (widAList == undefined) {
         // animatedWidgets are static
         widAId = animatedWidgetA;
         widBId = animatedWidgetB;
         _callEffectFunction();
      } else {
         // animatedWidgets are dynamic
         do {
            widAId = swui_piece(widAList, ";", i, i+1);
            if (widAId != "") {
               var widBId = animatedWidgetB;
               if (widBId != undefined) {
                  widBId = widBId + idSeparator + swui_piece(widAId,idSeparator,1);
               }
               _callEffectFunction();
            }
            i++;
         } while (widAId != "")
      }

      function _callEffectFunction() {
         if (type=='insert') {
            if (insertAnimWidgets[widAId] != undefined) {
               if (insertAnimWidgets[widAId][animationId]==true) { return; }
            }
         }
         responseArray = setEffectFunctionCall(animationId, widAId, widBId);
         functionCall = responseArray[0];
         animationDelay = Math.max(animationDelay,responseArray[1]);
         if (functionCall != "") {
            // Applies the animation effect
             if (seriesDelay == undefined) {
               eval(functionCall);
            } else {
               setTimeout('eval(' + functionCall + ');',seriesDelay);
            }
         }
         if (type=='insert') {
            if (insertAnimWidgets[widAId] == undefined) { insertAnimWidgets[widAId] = new Object(); }
            insertAnimWidgets[widAId][animationId]=true;
         }
         if (type=='remove') {
            if (insertAnimWidgets[widAId] != undefined) {
               for (var f in insertAnimWidgets[widAId]) {
                  insertAnimWidgets[widAId][f]=false;
               }
            }
         }
         if (type=='match' || type=='trade') {
            if (insertAnimWidgets[widAId] == undefined) { insertAnimWidgets[widAId] = new Object(); }
            insertAnimWidgets[widAId][animationId]=true;
            if (insertAnimWidgets[widBId] != undefined) {
               for (var f in insertAnimWidgets[widBId]) {
                  insertAnimWidgets[widBId][f]=false;
               }
            }
         }
      }

   }

   
   function _applyEffect(widAId, widBId) {
      responseArray = setEffectFunctionCall(animationId, widAId, widBId);
      functionCall = responseArray[0];
      animationDelay = Math.max(animationDelay,responseArray[1]);
      if (functionCall != "") {
         // Applies the animation effect
         if (seriesDelay == undefined) {
            eval(functionCall);
         } else {
            setTimeout('eval(' + functionCall + ');',seriesDelay);
         }
      }
   }
   

}

// Prepares the effects function call
function setEffectFunctionCall(animationId, animatedWidgetA, animatedWidgetB) {
   var responseArray = [];
   var animationDelay = 0.0;
   var effect = animation[animationId]['effect']['name'];
   var parameters = animation[animationId]['effect']['params'];
   // looks for duration value inside parameters
   for (var i=0; i<swui_piece(parameters,","); i++) {
      var param = swui_piece(parameters, ",", i, i+1);
      var parName = swui_piece(param, ":", 0, 1);
      if (parName == 'duration') { var parValue = swui_piece(param, ":", 1, 2)-0.0; animationDelay = Math.max(animationDelay,parValue); }
   }
   animationDelay = (animationDelay) * 1000;
   var functionCall = "swui_Effect_" + effect + "(\"" + animatedWidgetA + "\",\"" + animatedWidgetB + "\",\"" + parameters + "\")";
   responseArray[0] = functionCall;
   responseArray[1] = animationDelay;
   
   return responseArray;
}

function findEntryTransition(from, to) {
   if (from != undefined) {
      if (transition['fromTo'][from] != undefined) {
         // fromTo Transition
         transitionId = transition['fromTo'][from][to];
         if (transitionId == undefined) {
            transitionId = transition['to'][to];
         }
      } else {
         transitionId = transition['to'][to];
      }
   } else {
      transitionId = transition['to'][to];
   }
   return transitionId;
}
