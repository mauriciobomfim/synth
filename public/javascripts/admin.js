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

function create_window(form_hash,window_name){
  $('#__modal-box').remove();
  var box = $('<div id="__modal-box" title='+window_name+'>').appendTo('body');
  box.dialog({
        autoOpen: false,
        width: 400,
        modal: true
    });
    box.buildForm(form_hash);
    box.dialog( "open" );
    return box;
 }
 function create_window_modal(id, url_request, url_post, parameters, window_name, elements, callback){
   var dialog_box;
   if(parameters){
    url_post += "?"+decodeURIComponent($.param(parameters));
   }
   var send_to_post = function(value, options) { 
    if(value){
       if(callback){callback.call();}
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
        // Push fields
        form_data['elements'].push ( jQuery.extend(true, {}, default_field));
      });
      form_data['elements'].push({ "type" : "submit", "value" : "Confirm" });
      if(id){
        form_data['elements'].push({ "type" : "submit", "name" : 'oper', "value" : "Delete"});
      }
      dialog_box = create_window(form_data, window_name);
      //alert(form_data.toSource());
    });

 } 