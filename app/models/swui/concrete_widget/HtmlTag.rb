require "utils"

type = "HtmlTag"
widgets = [ { "name"=>"Button", "legalAbstractWidgs"=> ["SimpleActivator"], "legalTags" => "<input type='button'>" }, \
                 { "name"=>"CheckBox", "legalAbstractWidgs"=> ["PredefinedVariable"], "legalTags" => "<input type='checkbox'>" }, \
                 { "name"=>"ComboBox", "legalAbstractWidgs"=> ["CompositeInterfaceElement"], "legalTags" => "<select>" }, \
                 { "name"=>"ComboItem", "legalAbstractWidgs"=> ["PredefinedVariable"], "legalTags" => "<option>" }, \
                 { "name"=>"Composition", "legalAbstractWidgs"=> ["AbstractInterface","CompositeInterfaceElement"], "legalTags" => "<div>" }, \
                 { "name"=>"UnorderedList", "legalAbstractWidgs"=> ["CompositeInterfaceElement"], "legalTags" => "<ul>" }, \
                 { "name"=>"OrderedList", "legalAbstractWidgs"=> ["CompositeInterfaceElement"], "legalTags" => "<ol>" }, \
                 { "name"=>"ListItem", "legalAbstractWidgs"=> ["CompositeInterfaceElement","ElementExhibitor"], "legalTags" => "<li>" }, \
                 { "name"=>"Paragraph", "legalAbstractWidgs"=> ["CompositeInterfaceElement","ElementExhibitor"], "legalTags" => "<p>" }, \
                 { "name"=>"Form", "legalAbstractWidgs"=> ["CompositeInterfaceElement"], "legalTags" => "<form>" }, \
                 { "name"=>"Image", "legalAbstractWidgs"=> ["ElementExhibitor"], "legalTags" => "<img>" }, \
                 { "name"=>"Text", "legalAbstractWidgs"=> ["ElementExhibitor"], "legalTags" => "<span>" }, \
                 { "name"=>"Label", "legalAbstractWidgs"=> ["ElementExhibitor"], "legalTags" => "<label>" }, \
                 { "name"=>"Header1", "legalAbstractWidgs"=> ["ElementExhibitor"], "legalTags" => "<h1>" }, \
                 { "name"=>"Header2", "legalAbstractWidgs"=> ["ElementExhibitor"], "legalTags" => "<h2>" }, \
                 { "name"=>"Header3", "legalAbstractWidgs"=> ["ElementExhibitor"], "legalTags" => "<h3>" }, \
                 { "name"=>"Header4", "legalAbstractWidgs"=> ["ElementExhibitor"], "legalTags" => "<h4>" }, \
                 { "name"=>"Header5", "legalAbstractWidgs"=> ["ElementExhibitor"], "legalTags" => "<h5>" }, \
                 { "name"=>"Header6", "legalAbstractWidgs"=> ["ElementExhibitor"], "legalTags" => "<h6>" }, \
                 { "name"=>"Link", "legalAbstractWidgs"=> ["SimpleActivator"], "legalTags" => "<a>" }, \
                 { "name"=>"RadioButton", "legalAbstractWidgs"=> ["PredefinedVariable"], "legalTags" => "<input type='radio'>" }, \
                 { "name"=>"Table", "legalAbstractWidgs"=> ["CompositeInterfaceElement"], "legalTags" => "<table>" }, \
                 { "name"=>"TableBody", "legalAbstractWidgs"=> ["CompositeInterfaceElement"], "legalTags" => "<tbody>" }, \
                 { "name"=>"TableCell", "legalAbstractWidgs"=> ["CompositeInterfaceElement","ElementExhibitor"], "legalTags" => "<td>" }, \
                 { "name"=>"TableHeadCell", "legalAbstractWidgs"=> ["CompositeInterfaceElement","ElementExhibitor"], "legalTags" => "<th>" }, \
                 { "name"=>"TableFooter", "legalAbstractWidgs"=> ["CompositeInterfaceElement"], "legalTags" => "<tfoot>" }, \
                 { "name"=>"TableHeader", "legalAbstractWidgs"=> ["CompositeInterfaceElement"], "legalTags" => "<thead>" }, \
                 { "name"=>"TableRow", "legalAbstractWidgs"=> ["CompositeInterfaceElement"], "legalTags" => "<tr>" }, \
                 { "name"=>"TextArea", "legalAbstractWidgs"=> ["IndefiniteVariable"], "legalTags" => "<textarea>" }, \
                 { "name"=>"TextBox", "legalAbstractWidgs"=> ["IndefiniteVariable"], "legalTags" => "<input type='text'>" } ]

ModelUtils.createObjects(widgets,type)