/*
      * Author::    Andreia Luna (mailto: amluna@inf.puc-rio.br)
      * ---
      * WUI-Runtime-JS Library
      * These functions display responses from server in the HTML page.
      * ---
*/

// Mapping Hashes
var attrWidMap = new Object();      // maps attributes into widgets
var nodeWidMap = [];                // maps widgets into nodes
var inteWidMap = new Object();      // maps nodes into interfaces
var inteLitWidMap = new Object();      // maps literal (not nodes) widgets into interfaces
var widgetsFromTemplate = [];       // maps templates with widgets templates
var interfaces = [];                // list of interfaces in the current HTML document
var idSeparator = "$";
var ajaxIdSeparator = "#"

// traverses the DOM tree, looking for RDFa annotation
function traverseDOM(tag, interf, nodeWidg) {
   if (interf != undefined && nodeWidg != undefined) {inteWidMap[nodeWidg]=interf;}
   for (var i=0; i<tag.childNodes.length; ++i) {
      var child = tag.childNodes[i];
      var attrs = child.attributes;
      if (attrs == null) continue;
      
      var attrName =  child.getAttribute("property");
      if (attrName != null) {
         //attrName = (swui_piece(attrName,":",1) == '') ? attrName : swui_piece(attrName,":",1);
         var widgName = child.getAttribute("id");
         if (attrWidMap[attrName] == undefined) {
            attrWidMap[attrName] = [];
            idx = 0;
         } else {
            idx = attrWidMap[attrName].length;
         }
         attrWidMap[attrName][idx]=widgName;
         inteLitWidMap[widgName]=interf;
         if (nodeWidg!=undefined) { nodeWidMap[widgName]=nodeWidg; }
      }
      
      var nodeType =  child.getAttribute("typeof");
      if (nodeType != null) {
         var widgNodeName = child.getAttribute("id");
         if (nodeType == 'swui:AbstractInterface') {
            interfaces[interfaces.length]=widgNodeName;
            traverseDOM(child, widgNodeName, undefined);
         } else {
            traverseDOM(child, interf, widgNodeName); 
         }
      } else {
         traverseDOM(child, interf, nodeWidg);
      }
   }
}

// Sets mapping hashes
function createMapObjects() {
   var collection = document.getElementsByTagName("BODY");
   var bodyTag=collection[0];
   traverseDOM(bodyTag);
   
}

// Create widgets whose content is not dynamic
function createLiteralWidgets(interfResult, template, parent) {
   for (var i=0; i<template.childNodes.length; i++) {
         var childTemplate = template.childNodes[i];
         childTemplateId = childTemplate.id;
         if (childTemplateId != null) {
               var widgProperty = childTemplate.getAttribute("property");
               if (widgProperty == 'swui:literal' || widgProperty == 'swui:action' || widgProperty == 'swui:ajaxControl') {
                     var type = childTemplate.nodeName;
                     var content = ""
                     if (widgProperty != 'swui:action') {
                        content = childTemplate.innerHTML;
                        if (type == 'IMG') { content = childTemplate.src; }
                     }
                     var newWidg = document.getElementById(childTemplateId + idSeparator + swui_piece(parent.id,idSeparator,1));
                     if (newWidg == null) {
                        newWidg = createWidget(interfResult, type, childTemplate, childTemplateId + idSeparator + swui_piece(parent.id,idSeparator,1), parent);
                        renderWidget(interfResult, type, newWidg, content);
                     }
               }
         }
   }
}

// Sets widget attributes
function setWidgetAttr(el, newEl) {
   newEl.className = el.className;   // necessary for IE

   var attrs = el.attributes;
   for(var i=attrs.length-1; i>=0; i--) {
      if (attrs[i].nodeName != "id")  {
         newEl.setAttribute(attrs[i].nodeName,attrs[i].nodeValue);
      }
   }
   
   if (el.nodeName == 'OPTION') {
      newEl.innerHTML = el.innerHTML;
   }
   
   if (registeredEvents[el.id] != undefined)  {
      for (var event in registeredEvents[el.id]) {
         newEl.addEventListener(event, function (event) {
            eventHandler(swui_piece(this.id,idSeparator,0,1), event.type, this.id);
            }
               ,false);
         }
   }
  
}

// Place the widget in the correct DOM branch
function placeWidget(el) {
      var parentEl = el.parentNode;
      var widgTemplateId = swui_piece(el.id,idSeparator,0,1); // el's template id 
      var templateWidg = document.getElementById(widgTemplateId);
      var firstTemplateSearch =  null;
      var lastTemplateSearch = null;
      for (var i=0; i<=parentEl.childNodes.length-2; ++i) {
            var sibling = parentEl.childNodes[i]; // in the DOM tree, sibling comes before el
            var siblingId = sibling.id;
            if (siblingId != null) {
                  var siblingTemplateId  = swui_piece(siblingId,idSeparator,0,1); // sibling's template id
                  var firstTemplateSearch = document.getElementById(siblingTemplateId).previousSibling;
                  for (var current = firstTemplateSearch; current != lastTemplateSearch && current !=  null; current = current.previousSibling) {
                        if (current.id == widgTemplateId) { // el should come before sibling
                              parentEl.removeChild(el);
                              parentEl.insertBefore(el,sibling);   
                              return;
                        } 
                  }
            }
            lastTemplateSearch = firstTemplateSearch;
      }
}

// Append a widget in the DOM tree
function appendWidget(el, newEl, parent) {
   parent = (parent == null) ? el.parentNode : parent;
   parent.appendChild(newEl);
}

// Remove a widget from the DOM tree
function removeWidget(el, parent) {
   parent.removeChild(el);
}

// Create a new widget
function createWidget(interfResult, type, template, id, nodeWidg, order) {

   var parent = nodeWidg;
   if (parent == undefined) {
      // if the nodeWidg argument is undefined -> we are creating a node widget
      var newWidg = _createWidget();
      if (order != undefined) {
         // only at this level we need to consider the widget's order in a list
         var parent = newWidg.parentNode;
         // checks if the list is defined as ordered
         if (swui_CSSClass(parent, 'swui_ordered')) {
            var j=0;
            for (var i=0; i<parent.childNodes.length-1; ++i) {
               var sibling = parent.childNodes[i]; // in the DOM tree, sibling comes before el
               if (sibling.id != null) {
                  if (sibling.nodeName == type && sibling != template) { // this sibling is a node too, but it's not the template.
                     j++; // its order in the composite list
                     if (j == order) {
                        // find the sibling node whose order = swui:order
                        // and place the widget before it
                        parent.removeChild(newWidg);
                        parent.insertBefore(newWidg,sibling);   
                     }
                  }
               }
            }
         }
      }
   } else {
      // otherwise -> we are creating an attribute widget -> we need to determine its parent in the DOM path to the nodeWidg
      var parentTemplate = template.parentNode;
      var parentTemplateId =  parentTemplate.id;
      var templateNodeId  = swui_piece(nodeWidg.id,idSeparator,0,1);
      if (templateNodeId != parentTemplateId)  {
            var parentTemplateType = parentTemplate.nodeName;
            parent = document.getElementById(parentTemplateId + idSeparator + swui_piece(nodeWidg.id,idSeparator,1));
            if (parent == null) {
               parent = createWidget(interfResult, parentTemplateType,parentTemplate,parentTemplateId + idSeparator + swui_piece(nodeWidg.id,idSeparator,1),nodeWidg);
            } 
      }
      var newWidg = _createWidget();
   }

   // we must create all literal widgets that are newWidg's siblings (inside the current composite)
   createLiteralWidgets(interfResult, template, newWidg); 

   return newWidg;

   // Create a widget
   function _createWidget() {
      var newWidg = document.getElementById(id);
      if (newWidg == null) {
               var newWidg = document.createElement(type);
               newWidg.id = id;
               appendWidget(template,newWidg, parent);
               placeWidget(newWidg);
               setWidgetAttr(template,newWidg);
         
               if (swui_CSSClass(newWidg,"swui_invisible") && (newWidg.getAttribute("typeof")!=null )) { // if this is a node composite
                  swui_removeCSSClass(newWidg, "swui_invisible");
               }
               
               // Sets widgetsFromTemplate hash
               if (widgetsFromTemplate[template.id] == undefined ) {
                  widgetsFromTemplate[template.id] = "" //template.id + ";";
               }
               widgetsFromTemplate[template.id] += id
               widgetsFromTemplate[template.id] += ";"
               
               // checks if this widget is an element in a sortable list ...
               var parentTemplate = template.parentNode;
               if (swui_CSSClass(parentTemplate ,"swui_sortable")) {
                  // ... and calls the Scriptaculous Create Sortable function
                  Sortable.create(newWidg.parentNode.getAttribute("id"),{tag: newWidg.nodeName});
               }
         
               // checks if this widget is draggable
               if (swui_CSSClass(template ,"swui_draggable")) {
                  // ... and calls the Scriptaculous Create Draggable function
                  new Draggable(newWidg.getAttribute("id"));
               }
      }
      return newWidg;
   }
}

// Renders an image widget
function renderImg(widget, content) { 
   widget.src = content;
}

// Renders a label widget
function renderLabel(widget, content) { 
   widget.innerHTML = content; 
}

// Renders a table cell widget
function renderTableCell(widget, content) {
   widget.innerHTML = content;
}

// Renders a link widget
function renderLink(widget, content) {
   widget.href = content;
}

// Renders a textBox widget
function renderTextBox(widg, content) {
   widg.value = content; 
}

// Renders a textArea widget
function renderTextArea(widg, content) {
   widg.value = content; 
}

// Renders check boxes and radio buttons
function renderCheckBox(widg, content) {
   if (widg.value == content) { widg.checked="checked" }
}

// Renders a option widget
function renderCombo(widg, content) {
   for (var i=0; i<widg.childNodes.length; i++) {
      var child = widg.childNodes[i];
      childId = child.id;
      if (childId != null) {
         if (child.value == content) {
            child.selected="selected";
         }
      }
   }
}

// Renders a concrete widget
function renderWidget(interfResult, type, widg, content) {
   
   // renders the specific widget ...
   switch (type) {
         case 'IMG': renderImg(widg, content);
            break;
         case 'P': 
         case 'SPAN': 
         case 'LABEL': 
         case 'H1': 
         case 'H2': 
         case 'H3': 
         case 'H4': 
         case 'H5': 
         case 'H6': 
         case 'LI': renderLabel(widg, content);
            break;
         case 'TD':
         case 'TH': renderTableCell(widg, content);
            break;
         case 'A': renderLink(widg, content);
               break;
         case 'INPUT':
            if (widg.type == 'text') { renderTextBox(widg, content); }
            if (widg.type == 'checkbox') { renderCheckBox(widg, content); }
            if (widg.type == 'radio') { renderCheckBox(widg, content); }
            break;
         case 'SELECT': renderCombo(widg, content);
            break;
         case 'TEXTAREA': renderTextArea(widg, content);
            break;
         case 'DIV':
         case 'UL':
         case 'OL': //renderComposition(interfResult, widg, content, id);
            break;
         default: break;
   }
}

// Uses a template to display some information
function renderTemplate(templateWidgetId, contentWidget, id, interfResult, order) {

   var templateNodeId = nodeWidMap[templateWidgetId];

    var templateNode = document.getElementById(templateNodeId);
    var typeWidgetNode = templateNode.nodeName;
    var newNode = document.getElementById(templateNode.id + idSeparator + "id" + id);
    if (newNode == null) {
        newNode = createWidget(interfResult,typeWidgetNode,templateNode,templateNode.id + idSeparator + "id" + id, undefined, order);
    }
    var parent = newNode;

   var template = document.getElementById(templateWidgetId);
   var typeWidget = template.nodeName;
   
   var l = (typeof contentWidget != "object") ? 1 : contentWidget.length;

   for (var k = 0; k < l; ++k) {
         var content = (typeof contentWidget != "object") ? contentWidget : contentWidget[k];
         if (typeof content != "object") {
            // if the attribute holds an array of strings
            var seq  = (l>1) ? idSeparator + "s" + k: ""; // we do not use a sequence id when there is only one element
            var newWidg = document.getElementById(template.id + idSeparator + swui_piece(parent.id,idSeparator,1) + seq);
            if (newWidg == null) {
                  newWidg = createWidget(interfResult, typeWidget,template,template.id + idSeparator + swui_piece(parent.id,idSeparator,1) + seq, parent, order);
            }
            renderWidget(interfResult, typeWidget, newWidg, content);
            _callAjaxControlLogic();
         } else {
            // if the attribute holds an array of objects
               for (var attrName in content) {
                  if (attrWidMap[attrName] == undefined) { continue; }
                  for (var i=0,j=attrWidMap[attrName].length; i < j; ++i) {
                     templateWidgetId = attrWidMap[attrName][i]
                     template = document.getElementById(templateWidgetId);
                     typeWidget = template.nodeName;
                     
                     var seq  = (l>1) ? idSeparator + "s" + k: ""; // we do not use a sequence id when there is only one element
                     
                     // PredefinedVariable (ComboBox, Radio and CheckBox): we do not create more than one set of fields
                     if (typeWidget == 'INPUT') {
                        if (template.type == 'checkbox' || template.type == 'radio') { seq = ""; }
                     }
                     if (typeWidget == 'SELECT') { seq = ""; }
                     
                     // creates the composite that holds the instance for that object
                     var templateItemId = nodeWidMap[template.getAttribute("id")]
                     var templateItem = document.getElementById(templateItemId)
                     var typeTemplateItem = templateItem.nodeName;
                     var newNode = document.getElementById(templateItemId + idSeparator + "id" + id + seq);
                     if (newNode == null) {
                         newNode = createWidget(interfResult, typeTemplateItem, templateItem, templateItemId + idSeparator + "id" + id + seq, parent, order);
                     }

                     var newWidg = document.getElementById(template.id + idSeparator + swui_piece(parent.id,idSeparator,1) + seq);
                     if (newWidg == null) {
                           newWidg = createWidget(interfResult, typeWidget,template,template.id + idSeparator + swui_piece(parent.id,idSeparator,1) + seq, newNode, order);
                     }
                     renderWidget(interfResult, typeWidget, newWidg, content[attrName]);
                     _callAjaxControlLogic();
                  }
               }
         }
   //setTimeout(_callAjaxControlLogic,2500);
   //_callAjaxControlLogic();
   }
   
   function _callAjaxControlLogic() {
      callAjaxControlLogic(template.parentNode, newWidg.parentNode.id);
   }
}


// Calls the javascript function associated with an Ajax Control
function callAjaxControlLogic(widget,id) {
   ajaxControlName = getAjaxControlName(widget);
   if (ajaxControlName != null) {
      args = id;
      ajaxControlName = ajaxControlName.replace(/-/g,"_");
      functionCall = "swui_Rich_" + ajaxControlName + "(args)"
      eval(functionCall);
   }
}

// Renders a node
function renderNode(interfResult, elem) { 
   // elem is a object that represents the navigation node (SHDM)
   // this function will look for the widgets meant to display the node's attributes
   // interfResult is the interface being updated

   var nodeId = "";  
   var response = [];
   
   var id = elem['swui:id'];
   var order = elem['swui:order'];

   for (var attrName in elem) {
       if (attrWidMap[attrName] == undefined) { continue; }
       for (var i=0,j=attrWidMap[attrName].length; i < j; ++i) {
          var templateWidgetId = attrWidMap[attrName][i];
          var templateNodeId = nodeWidMap[templateWidgetId];
          if (inteWidMap[templateNodeId] != interfResult) {
             // the interface is not the one that is being updated
             // so, we will not create the widget
             continue;
          }
          if (nodeId == "") { nodeId = templateNodeId + idSeparator + "id" + id; }
          var content = elem[attrName];
          if (content != "") {
            renderTemplate(templateWidgetId, content, id, interfResult, order);
          }
      }
   }
}


// Delete nodes in the DOM tree
function removeNodes(target) {
      for (var nodeWidg in inteWidMap) {
            //if (typeof inteWidMap[nodeWidg] == 'function') continue;
            if (inteWidMap[nodeWidg] == target) {
                  var parent = document.getElementById(nodeWidg).parentNode;
                  var nodesToRemove = [];
                  var j=0;
                  for (var i=0; i<parent.childNodes.length; ++i) {
                        var child = parent.childNodes[i];
                        childId = child.id;
                        if (childId != null ) {
                              if (childId.match(nodeWidg + idSeparator + 'id') != null) {
                                    nodesToRemove[j] = child;
                                    j++;
                              }
                        }
                  }
                  for (var i=0; i<nodesToRemove.length; ++i) {
                        removeWidget(nodesToRemove[i],parent)
                        //parent.removeChild(nodesToRemove[i]);
                  }
            }
      }      
}

// Retrieves the fields' values of a form
function buildPars(parent) {
      
      var pars="";
      for (var i=0; i<parent.childNodes.length; i++) {
            var child = parent.childNodes[i];
            childId = child.id;
            if (childId != null) {
                  if (child.name != null) {
                        // these fields' values are not sent to the form's action
                        if (child.nodeName == 'INPUT') {
                              switch (child.type) {
                              case 'submit':
                              case 'reset':
                              case 'button': continue; 
                                    break;
                              default: break;
                              }
                        }
                        pars = pars + child.name + "=" + escape(child.value) + "&";
                  }
            }
            pars += buildPars(child);
      }
      return pars
}

// Retrieves the form where a widget is placed
function findForm(widget) {
      var parent = widget.parentNode;
      if (parent.nodeName == 'FORM') {
            return parent;
      } else {
            return findForm(parent);
      }
}

// Retrieves the interface where a widget is placed
function findInterface(widget) {
      var parent = widget.parentNode;
      var nodeType = parent.getAttribute("typeof");
      if (nodeType == 'swui:AbstractInterface') {
            return parent.getAttribute("id");
      } else {
         return findInterface(parent);
      }
}


// Creates ajax controls
function createAjaxControls(interfaceName) {
   attrName = "swui:ajaxControl";
   if (attrWidMap[attrName] == undefined) { return; }
   l = attrWidMap[attrName].length;
   for (var i=0; i<l; i++) {
      widgName = attrWidMap[attrName][i]
      node = nodeWidMap[widgName];
      if (node == undefined) { // calls the function only if this is a static widget
         widget = document.getElementById(widgName);
         callAjaxControlLogic(widget, widgName);
      }
   }
}

// Creates sortable lists
function createSortLists(interf) {
   var tagList = ['div','ul','ol','li'];
   for (var i=0; i<tagList.length; i++) {
      var widgArray = getElementsByClassName('swui_sortable',tagList[i],interf);
      for (var j=0; j<widgArray.length; j++) {
         var tag = widgArray[j]
         if (typeof tag == 'function') continue;
         var childType='li';
         if (tagList[i] != 'ul' && tagList[i] != 'ol' ) {
            for (var k=0; k<tag.childNodes.length; ++k) {
               var child = tag.childNodes[k];
               var attrs = child.attributes;
               if (attrs == null) continue;
               var childId = child.getAttribute("id");
               if (childId != undefined) {
                  childType = child.nodeName;
               }
            }
         }
         // calls the Scriptaculous Create Sortable function
         Sortable.create(tag.getAttribute("id"),{tag: childType});
      }
   }
}

// Creates draggable widgets
function createDraggables(interf) {
    var widgArray = getElementsByClassName('swui_draggable', undefined, interf);
    for (var j=0; j<widgArray.length; j++) {
       var tag = widgArray[j]
       if (typeof tag == 'function') continue;
       // calls the Scriptaculous Create Draggable function
       new Draggable(tag.getAttribute("id"));
    }
}

// Retrieves the [x,y] coordinates of a widget
function swui_findPos(obj) {
        objRef = obj;
        displayStatus = objRef.style.display;
        if (displayStatus == 'none') { objRef.style.display = ''; }
	var curleft = curtop = 0;
	if (obj.offsetParent) {
	do {
			curleft += obj.offsetLeft;
			curtop += obj.offsetTop;
		} while (obj = obj.offsetParent);
	}
        if (displayStatus == 'none') { objRef.style.display = displayStatus; }
	return [curleft,curtop];
}

// Retrieves the abstract widget name in an ajaxControl id
function getViewRef(ajaxControlId) {
	return swui_piece(ajaxControlId, ajaxIdSeparator, 0, 1);
}

// Retrieves the navigational object id in an ajaxControl id
function getModelRef(ajaxControlId) {
	return swui_piece(ajaxControlId, idSeparator, 1);
}

// Retrieves the runtime reference to a widget
function swui_getRunTimeRef(name,id) {
  widId = getViewRef(id);
  objId = getModelRef(id);
  if (name != undefined) {
      runTimeRef =  widId + ajaxIdSeparator + name;
  } else {
      runTimeRef =  widId;
  }
  if (objId != '') {
      runTimeRef = runTimeRef + idSeparator + objId;
  }
	return runTimeRef;

}

// Retrieves the the model attribute value of an Ajax Control's
function swui_getRunTimeAttrValue(id) {
  widget = swui_getRunTimeAttrWidget(id);
  if (widget != null) {
    value = widget.value
  } else {
    value = "";
  }
  return  value;
}

// Sets the the model attribute value of an Ajax Control's
function swui_setRunTimeAttrValue(id, value) {
  widget = swui_getRunTimeAttrWidget(id);
  if (widget != null) {
      widget.value = value;
  } 
}

// Retrieves the runtime reference to the Ajax Control's element that holds the model attribute 
function swui_getRunTimeAttrWidget(id) {
  objId = getModelRef(id);
  runTimeRef = getViewRef(id);
  if (objId != '') {
      runTimeRef = runTimeRef + idSeparator + objId;
  }
  widget = document.getElementById(runTimeRef);
  return widget;
}

// Finds the Ajax Control's name
function getAjaxControlName(widget) {
   name = null;
   //widget = widget.parentNode;
   for (var i=0; i<widget.childNodes.length; i++) {
         var child = widget.childNodes[i];
         var attrs = child.attributes;
         if (attrs == null) continue;
         var property =  child.getAttribute("property");
         if (property=='swui:ajaxControlId') {
             // this is a Ajax Control Widget
             name = child.innerHTML;
         }
   }
   return name;
}

// Apply a CSS class to a widget
function swui_setCSSClass(widget, className) {
   cssClasses = widget.getAttribute("class");
   if (cssClasses == null) {
      cssClasses = className;
   } else {
      cssClasses = className + " " + cssClasses;  // className is always the head of the list
   }
   widget.setAttribute("class",cssClasses)
}

// Remove a CSS class from a widget
function swui_removeCSSClass(widget, className) {
   cssClasses = widget.getAttribute("class");
   if (cssClasses == null) {
      cssClasses = "";
   } else {
      cssClasses = cssClasses.replace(className + " ",""); // className is always the head of the list
      cssClasses = cssClasses.replace(className,""); // in case of className being the only item in the list
   }
   widget.setAttribute("class",cssClasses)
}

// Checks if a widget is associated with a CSS class
function swui_CSSClass(tag, className) {
   var classAttr = tag.getAttribute("class");
   if (classAttr != null) {
      var vector = classAttr.split(" ");
      for (var i=0; i<vector.length; i++) {
         if (className == vector[i]) {
            return true;
         }
      }
   }
   return false;
}

// Shows one interface and hides another
function updateInterfaces(interfToShow, interfToHide, data) {

   var animationDelay = 0;
   var exitTransitionId = undefined;
   var entryTransitionId = undefined;
   var transitionId;
   
   if (interfToHide != undefined) {
      if (interfToShow != undefined) {
         // Both interfToShow & interfToHide are defined
         if (transition['fromTo'][interfToHide] != undefined) {
            // fromTo Transition
            transitionId = transition['fromTo'][interfToHide][interfToShow];
            if (transitionId != undefined) {
               showInterface(interfToShow, data);
               animationDelay = performTransition(transitionId);
               // hide elements
               setTimeout("hideInterface('" + interfToHide + "');", animationDelay);
            } else {
               // fromTransition
               exitTransitionId = transition['from'][interfToHide];
               // toTransition
               entryTransitionId = transition['to'][interfToShow];
               animationDelay = _updateInterfaces();
            }
         } else {
            // fromTransition
            exitTransitionId = transition['from'][interfToHide];
            // toTransition
            entryTransitionId = transition['to'][interfToShow];
            animationDelay = _updateInterfaces();
         }
      } else {
         // only interfToHide is defined
         // fromTransition
         exitTransitionId = transition['from'][interfToHide];
         animationDelay = _updateInterfaces();
      }
   } else {
      // if interfToHide is not defined, interfToShow must be defined
      // toTransition
      entryTransitionId = transition['to'][interfToShow];
      animationDelay = _updateInterfaces();
   }

  /*
   // Calls sortable lists & draggables creation functions
   for (var i=0; i<interfaces.length; i++) {
      createSortLists(document.getElementById(interfaces[i]));
      /createDraggables(interfaces[i]);
   }
   // Calls Ajax Control creation functions
   createAjaxControls();
   */
   
   if (interfToShow != undefined) {
      // Calls sortable lists & draggables creation functions
      createSortLists(document.getElementById(interfToShow));
      createDraggables(document.getElementById(interfToShow));
      
      // Calls Ajax Control creation functions
      createAjaxControls(interfToShow);
   }


   return animationDelay;

   function _updateInterfaces() {
      var animationDelay = 0;
      
      if (exitTransitionId != undefined) {
         animationDelay = performTransition(exitTransitionId);
      }
      if (interfToHide != undefined) {
         // hide elements
         setTimeout("hideInterface('" + interfToHide + "');", animationDelay);
      }
      if (interfToShow != undefined) {
         showInterface(interfToShow, data);
      }
      if (entryTransitionId != undefined) {
         animationDelay = Math.max(animationDelay,performTransition(entryTransitionId));
      }
      
      return animationDelay;
   }
}

// Shows an interface
function showInterface(interfId,data) {
      // create dynamic widgets
      jsonString = (data == undefined) ? readJSONData(interfId) : data;
      if (jsonString != "") { parseTransactionResponse(jsonString, interfId); }
      // display (only) the interface
      swui_removeCSSClass(document.getElementById(interfId), 'swui_invisible');
}

// Hides an interface
function hideInterface(interfId) {
   // delete interface's dynamic widgets
   removeNodes(interfId); 
   // hide (only) the interface
   swui_setCSSClass(document.getElementById(interfId), 'swui_invisible'); 
}

// Returns true if the widget's id holds an object id
function swui_isInstanceId(widgetId) {
   return (swui_piece(widgetId,idSeparator,1) != "")
}
