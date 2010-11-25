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