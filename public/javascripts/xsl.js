       var htmlTags = [];
       var widgetsIds = [];
       htmlTagsArray();
       
       function switchAreas(id) {
            var htmlId = "html_" + id 
            var ajaxId = "ajax_" + id 
            var tagAttrId = "tagAttr_" + id
            var cssClassId = "cssClass_" + id
            var concreteWidgetId = "concreteWidget_" + id
            var concreteWidget = document.getElementById(concreteWidgetId)
            if (isHTMLTag(concreteWidget.value)) {
              toggle_areas(htmlId,ajaxId)
            } else {
              tagAttrWidg = document.getElementById(tagAttrId)
              cssClassWidg = document.getElementById(cssClassId)
              tagAttrWidg.value=""
              cssClassWidg.value = ""
              toggle_areas(ajaxId,htmlId)
            }
       }
       
       function isHTMLTag(widget) {
        var found = false;
        for (var i=0; i<htmlTags.length; ++i) {
            if (widget == htmlTags[i]) { 
              found = true
              break
            }
        }
        return found
      }

      function loadCssSheets() {
        var url = '/abstract_interfaces/css/' + document.getElementById("interface_name").value;
        new Ajax.Request(url,
            {
              method:'get',
              onSuccess: function(transport){
                response = transport.responseText;
                document.getElementById('cssSheets').value=response;
              }
            });
      }
      
      function htmlTagsArray() {
        var url = '/abstract_interfaces/htmlTags'
        new Ajax.Request(url,
            {
              method:'get',
              onSuccess: function(transport){
                response = transport.responseText 
                var htmlTagsList = response;
                var i=0;
                 do {
                    htmlTag = swui_piece(htmlTagsList, ";", i, i+1);
                    htmlTags[i]=htmlTag;
                    i++;
                 } while (htmlTag != "")
                  for (var i=0; i<widgetsIds.length; ++i) {
                      switchAreas(widgetsIds[i]) ;
                  }
              }
            });
      }      
      
      function widgetsIdsArray(id) {
        widgetsIds[widgetsIds.length] = id;
      }
