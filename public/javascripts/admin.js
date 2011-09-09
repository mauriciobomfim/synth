function toggle_areas(show) {
  document.getElementById(show).style.display = "block";
  for (var i=1; i < arguments.length; i++) {
	  document.getElementById(arguments[i]).style.display = "none";
  }
}

function set_option(control, checked) {
	document.getElementById(control).checked = checked;
}  

function toggle_cbs(control, checked) {
	cbs = document.getElementsByName(control);
	for (i=0; i < cbs.length; i++) {
		cbs[i].checked = checked;
	}
}	

function remove_links(method) {
	form = document.forms[0];	
	form.action = "/node/remove_link?link_method=" + method;
	form.submit();
}

function register_toogle() {
	$(".toggle_action").toggle(
		function () {						
			$(".toggle_action").html("-");
	  $(".toggleable").slideToggle("slow");
	}, 
		function () {							
	  $(".toggleable").slideToggle("slow");
			$(".toggle_action").html("+");
	}				
	);
}

function numeric_options(ini, end){
  var hash = {};
  for(i=ini;i<=end;i++){
    hash[i.toString()] = i.toString()
  }
  return hash
}

function array_options_hash(options_array){
    var options_hash = {}
    $.each(options_array, function( key, value ){
      var value_a = value.toString().split(",");
      options_hash[value_a[0]] = { 'value' : value_a[0], 'selected' : false, 'html': value_a[1]};
    });
    return options_hash;
}

function create_window(form_hash,window_name, include_after){
  var modal_name = '_modal-box-'+ window_name.replace(' ', '-');
  $('#'+modal_name).remove();
  var box = $('<div id="'+modal_name+'" title="'+window_name+'">').appendTo('body');
  box.dialog({
        autoOpen: false,
        width: 400,
        modal: true
    });
    $.dform.subscribe("type", function(type, options) {
    if(type == "button")
    {
        this.click(function() {
            box.dialog( "close" );
            return false;
        });
    }
 });
    box.buildForm(form_hash);
    if(include_after){
      $('<div id="after'+modal_name+'" >'+include_after+'</div>').appendTo(box);
    }
    box.dialog( "open" );
    return box;
 }
 function create_window_modal(id, url_request, url_post, parameters, window_name, elements, callback_on_submit, include_after){
   var dialog_box;
   if(!id){
    window_name = "New "+window_name;
   }
   if(parameters){
    url_post += "?"+decodeURIComponent($.param(parameters));
   }
   var send_to_post = function(value, options) { 
    if(value){
       if(callback_on_submit){callback_on_submit.call();}
       dialog_box.dialog('close');
    }
   };
   var form_data = { "action" : url_post, "method" : "post", "ajax" : send_to_post, "elements" : [ ] };
   var default_field = { "name" : "", "caption" : "", "type" : "text", "value" : "" }
   
   $.getJSON(url_request + (id ? id : ''),
    function(data) {
      $.each(elements, function( key, value ){
        default_field['value']   = data[value['name']] ? data[value['name']] : value['value'];
        default_field['name']    = value['name'];
        default_field['type']    = value['type'] ? value['type'] : 'text';
        default_field['caption'] = value['caption'] ? value['caption'] : value['name'];
        default_field['caption'] = default_field['type'] == 'hidden' ? '' : value['caption']
        jQuery.extend(true, value, default_field)
        if(default_field['type'] == 'select' && value['options']){
          $.each(value['options'], function(k, v){
                                    if(v.value == data[value['name']]){
                                      v.selected = true; 
                                    }
                                    });
        }
        
        // Push fields
        form_data['elements'].push ( value );
        
      });
     
      form_data['elements'].push({ "type" : "hr" });
      
      form_data['elements'].push({ "type" : "submit", "value" : "Confirm" });
      if(id){
        form_data['elements'].push({ "type" : "submit", "name" : 'oper', "value" : "Delete"});
      }
      form_data['elements'].push({ "type" : "button", "name" : "cancel", "html" : "Cancel" });
      
      
      dialog_box = create_window(form_data, window_name, include_after);
      //alert(form_data.toSource());
    });

 } 