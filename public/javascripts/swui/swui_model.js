/*
      * Author::    Andreia Luna (mailto: amluna@inf.puc-rio.br)
      * ---
      * WUI-Runtime-JS Library
      * These functions provide communication between model and view.
      * ---
*/

// Evaluates a JSON response 
function parseJSONResponse(jsonString) {
      //swui_writeLog(jsonString)
      var nodesArray = [];
      try {
            nodesArray = jsonString.evalJSON(true);
            nodesArray = nodesArray.nodes;
            return nodesArray;
      }
      catch (x) {
            //alert("JSON Parse failed!");
            return "";
      }
}
      
// Handle the resulting array object from a JSON string

function parseTransactionResponse(jsonString, interfResult) {
      var nodesArray = parseJSONResponse(jsonString);
      if (nodesArray != "") {
            for (var i = 0, len = nodesArray.length; i < len; ++i) {
                  renderNode(interfResult, nodesArray[i]);
            }
      }
}

// Handles the resulting array object from a JSON string
function parseMetadataResponse(jsonString, callbackFunction) {
      nodesArray = parseJSONResponse(jsonString);
      if (nodesArray != "") {
            for (var i = 0, len =nodesArray.length; i < len; ++i) {
                  eval(callbackFunction + "(nodesArray[i])");
            }
      }
}

// Triggers an action in Model
function sendQuery(url, params, sourceInterface, targetInterface, transitionInterface) {

      var count = 0;  // null replies counter
      var pollingRate = 15; // in requests per minute
      var timeout = 60;     // in seconds (after there are no more replies from server)
      var maxCount = timeout*pollingRate/60; // number of null replies before timeout
      var requestDelay = 60*1000/pollingRate; // in miliseconds

      var transact_id;
      var response = "";

      if (transitionInterface != '') {
            updateInterfaces(transitionInterface);  // shows transitionInterface before call Model
            // If there is a transitionInterface, triggers an action in Model under a transaction
            if (targetInterface != '') {
                  // targetInterface is already in the sourceInterface
                  if (document.getElementById(targetInterface) != null) {
                        // When targetInterface==0, Model returns nothing but JSONdata
                        params = params.replace(/swuiInterface=\w*&/i, "swuiInterface=0");
                  }
            }
            new Ajax.Request('/transactions/start', { method: 'get', onComplete: function(transport) {
                  transact_id = transport.responseText;
                  //if (params==undefined) new Ajax.Request('/'+transact_id+url, { method: 'get', onComplete: function(transport) {result = transport.responseText;} } );
                  //else
                  new Ajax.Request('/'+transact_id+url, { method: 'post', parameters: params, onComplete: function(transport) {result = transport.responseText;} } );
                  setTimeout(fetchResponse,requestDelay);
            }
            });
      } else {
            // there is no transition interface - it is a synchronous call
            if (targetInterface != '') {
                  // targetInterface defined before the operation call
                  if (document.getElementById(targetInterface) != null) {
                        // targetInterface inside the sourceInterface
                        // an Ajax call - expects data in the server's response
                        params.replace(/swuiInterface=\w*&/i, "swuiInterface=0");  // When targetInterface==0, Model returns nothing but JSONdata
                        new Ajax.Request(url, { method: 'post', parameters: params, onComplete: function(transport) {
                                      // shows the interface in which to display the results
                                      // I can't hide sourceInterface because targetInterface is a component of it.
                                      updateInterfaces(targetInterface, undefined, transport.responseText); 
                              }
                        } );
                  } else {
                        // targetInterface not in the sourceInterface
                        notAjaxCall();
                  }
            } else {
                  // targetInterface defined by the operation
                  notAjaxCall();
            }
      }
      
      function notAjaxCall() {
            // hides source interface
            updateInterfaces(undefined, sourceInterface); 
            // submits the page - server responds with the target interface
            if (params == "") {
                  callModel(url,targetInterface)
            } else {
                  postModel(url,params)
            }
      }

      function fetchResponse() {
            if (response != "EOT\n") {
                  new Ajax.Request('/transactions/pop_response/'+transact_id, { method: 'get' , onComplete: function(transport) {
                        // has timeout occurred?
                        if (count < maxCount) {
                              setTimeout(fetchResponse,requestDelay);
                        } else {
                              alert("Timeout has occurred while waiting for application to finish transaction!");
                        }
                        response = transport.responseText;
                        if (response != "" && response != "EOT" ) {
                              count = 0;  // resets null replies counter
                              parseTransactionResponse(response, transitionInterface);
                              var animationDelay = 0;
                              var transitionId = findEntryTransition(sourceInterface, transitionInterface);
                              animationDelay = performTransition(transitionId);
                        }
                        if (response == "") {count++;}  // counts when there are no replies to the request
                  }
                  });
            } else {
                  // End Of Transition
                  // switches from transitionInterface to targetInterface
                  if (targetInterface != '') {
                        // targetInterface defined before the operation call
                        if (document.getElementById(targetInterface) != null) {
                          // targetInterface inside the sourceInterface
                          // expects data in the server's response
                          // shows the interface in which to display the results
                          // I can't hide sourceInterface because targetInterface is a component of it.
                          setTimeout('updateInterfaces(\''+ targetInterface + '\',\'' + transitionInterface + '\',\'' + result + '\')', requestDelay);  
                        } else {
                              // targetInterface not in the sourceInterface
                              setTimeout(rewritePage,requestDelay)
                              //rewritePage();
                        }
                  } else {
                        // targetInterface defined by the operation 
                        setTimeout(rewritePage,requestDelay);
                        //rewritePage();
                  }
            }
      
            function rewritePage() {
                  // server responds with the target interface
                  //setTimeout('updateInterfaces('+ undefined + ' ,\'' + transitionInterface + '\')', requestDelay);
                  var animationDelay = 0;
                  animationDelay = Math.max(animationDelay,updateInterfaces(undefined, transitionInterface));
                  animationDelay = Math.max(animationDelay,updateInterfaces(undefined, sourceInterface));
                  setTimeout(_rewritePage,animationDelay);
                  
                  function _rewritePage() {
                        window.document.open();
                        window.document.write(result);
                        window.document.close();
                  }
            }
      }       
}

// Calls a Model Action
function callAction(action, activator, sourceInterface, targetInterface, transitionInterface) {
      var nodeId = swui_piece(activator.id,idSeparator,1,2).replace('id','');
      var url = "";
      var params = "";
      if (action.match("swui:submitForm") != null) {
            // Submits a form
            url = action.replace("swui:submitForm(","");
            url = url.replace(")","")
            var form = findForm(activator);
            params = buildPars(form);
            if (targetInterface != '') { params = params + "swuiInterface=" + targetInterface + "&"; }
      } else {
            // Calls an action
            url = action; 
      }
      if (nodeId != '') { url = url.replace(":id",nodeId); }  // id - target object id 
      sendQuery(url, params, sourceInterface, targetInterface, transitionInterface);            
}

// Navigates to a targetContext or a targetIndex
function navTarget(targetURL, sourceInterface, targetInterface) {
      if (targetInterface != '') {
            if (document.getElementById(targetInterface) == null) {
              // targetInterface does not belong to the sourceInterface
              var animationDelay = updateInterfaces(undefined, sourceInterface);
              setTimeout('callModel(\'' + targetURL + '\',\'' + targetInterface + '\')',animationDelay);
            }
            else  {
              // targetInterface is already in the sourceInterface
              new Ajax.Request(setURL(targetURL,'0'), {  // When targetInterface==0, Model returns nothing but JSONdata
                method: 'get',                    
                onComplete: function(transport) {  
                  updateInterfaces(targetInterface, sourceInterface, transport.responseText); 
                }
              });
            }
      } else {
            // targetInterface not specified 
            var animationDelay = updateInterfaces(undefined, sourceInterface); 
            setTimeout('callModel(\'' + targetURL + '\')',animationDelay);
      }
}

// Navigates to a context or an index 
function callModel(targetURL,targetInterface) {
   window.document.location.href=setURL(targetURL,targetInterface)
}

// Posts data to an URL
function postModel (url,pars) {
  var swui_postForm = document.createElement("form");
  swui_postForm.method="post" ;
  swui_postForm.action = url ;
  pars.split('&').each( function(item) {
      params=item.split('=');
      for (var i=0;i<params.length;i++) {
            var myInput = document.createElement("input") ;
            myInput.setAttribute("name", params[0]) ;
            myInput.setAttribute("value", params[1]);
            swui_postForm.appendChild(myInput) ;
      }
      } )
  document.body.appendChild(swui_postForm) ;
  swui_postForm.submit() ;
  document.body.removeChild(swui_postForm) ;
}

// Returns an URL to access Model
function setURL(targetURL,targetInterface) {
   // targetType: 'context' or 'show_index'
   if (targetInterface == undefined) {
    targetInterface = ''
   } else {
    var symbol=""
    if (targetURL.match(/\?/) != null) {
      symbol = "&"
    } else {
      symbol = "?"
    }
    targetInterface = symbol+'swuiInterface='+targetInterface
   }
   return targetURL+targetInterface
}