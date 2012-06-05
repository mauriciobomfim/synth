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
      //alert(value_a[0], value_a[1]);
      options_hash[value_a[0]] = { 'value' : value_a[0], 'selected' : false, 'html': value_a[1]};
    });
    return options_hash;
}

function create_window_modal_name(window_name, after){
  return (after ? 'after_modal-box-' : '_modal-box-') + window_name.replace(/ {1}/gi, '-');
}

function create_window(form_hash,window_name, include_after, run_after){
  var modal_name = create_window_modal_name( window_name );
  $('#'+modal_name).remove();
  var box = $('<div id="'+modal_name+'" title="'+window_name+'">').appendTo('body');
  box.dialog({
        autoOpen: false,
        width: 400,
        modal: true
    });
   
    $.dform.subscribe('change', function(options, type) { 
        var handler = options; 
        if($.isFunction(window[options])) { 
                handler = window[options]; 
        } 
        $(this).change(handler); 
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
  
  var after_modal_name = create_window_modal_name(window_name, true);
  $('<div id="'+after_modal_name+'" class="after_form" >').appendTo(box);
  if(include_after){
    $(include_after).appendTo('#'+after_modal_name);
  }
  box.dialog( "open" );
  if(run_after){
    run_after(modal_name);
  }
  return box;
 }
 
 function create_window_modal(id, url_request, url_post, parameters, window_name, elements, callback_on_submit, include_after, run_after){
    var dialog_box;
    var on_submit = function(){
     dialog_box.dialog('close');
     if(callback_on_submit){callback_on_submit.call();}
    }
    var run_with_hash = function(hash){
       if(!id){window_name = "New "+window_name; }
      dialog_box = create_window(hash, window_name, include_after,run_after);
    }
    var hash = create_form_hash(id, url_request, url_post, parameters, elements, on_submit, run_with_hash);
 }
 
 function format_base_form_hash(data, elements, url_post, run_on_submit){
  var form_data = { "action" : url_post, "method" : "post", "ajax" : run_on_submit, "elements" : [ ] };
  var default_field = { "name" : "", "caption" : "", "type" : "text", "value" : "" }
  $.each(elements, function( key, value ){
        default_field['value']   = data[value['name']] ? data[value['name']] : value['value'];
        default_field['name']    = value['name'];
        default_field['type']    = value['type'] ? value['type'] : 'text';
        default_field['caption'] = value['caption'] ? value['caption'] : value['name'];
        default_field['caption'] = default_field['type'] == 'hidden' ? '' : value['caption'];
        value = jQuery.extend(true, value, default_field);
        if(default_field['type'] == 'select' && value['options']){
          $.each(value['options'], function(k, v){
                                    if(decodeURIComponent(v.value) == data[value['name']]){
                                      v['selected'] = true;
                                      
                                    }
                                    });
        }
        // Push fields
        form_data['elements'].push ( jQuery.extend(true, {}, value) );
      });
      form_data['elements'].push({ "type" : "submit", "value" : "Save", "class" : "confirm_button" });
      if(data['id']){
        form_data['elements'].push({ "type" : "submit", "name" : 'oper', "value" : "Delete", "class" : "delete_button", "onclick" : "if(!confirm('Are you sure?')){return false;}" });
      }
      form_data['elements'].push({ "type" : "button", "name" : "cancel", "html" : "Cancel", "class": "cancel_button" });
      return form_data;
 }
 
 function create_form_hash(id, url_request, url_post, post_parameters, elements, callback_on_submit, run_with_hash){
   if(post_parameters){
    url_post += "?"+decodeURIComponent($.param(post_parameters));
   }
   var run_on_submit = function(value, options) { 
    if(value){
       if(callback_on_submit){callback_on_submit.call();}
    }
   };
   var instance_hash = function(data) {
       var form_hash = format_base_form_hash(data, elements, url_post, run_on_submit);
       run_with_hash(form_hash);
   }
   if(!id){
      instance_hash({});
   }else{
      $.getJSON(url_request + (id ? id : ''),{}, instance_hash);
   }
 }
 
 function multiple_forms_in_target(id, target_element_id, data, url_request, request_params, url_post, post_parameters, elements, run_on_submit){
    id = id ? id : '';
    var url_request = url_request+id;
     if(post_parameters){
      url_post += "?"+decodeURIComponent($.param(post_parameters));
     }
    var instance_form = function(key, value) {
       var form_hash = format_base_form_hash(value, jQuery.extend(true, {}, elements), url_post, run_on_submit);
       $('#'+target_element_id).buildForm(form_hash);
    }
    if(data){
      instance_form(null, data);
    }else{
      $.getJSON(url_request, request_params,function(result){
        $.each(result, instance_form);
      });
    }
    
  }
 
