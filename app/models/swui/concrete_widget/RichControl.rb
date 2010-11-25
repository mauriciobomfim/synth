require "utils"
type = "RichControl"

path = "#{RAILS_ROOT}/app/models/concrete_widget/"

ary = Array.new
ary.push("name" => "Carousel", "absWidg" => ["ElementExhibitor"])
ary.push("name" => "Rating", "absWidg" => ["ElementExhibitor","PredefinedVariable"])

widgets = Array.new
ary.each do
    |item|
    name = item["name"]
    absWidg = item["absWidg"]
    widgets.push({ "name"=>"#{name}", "legalAbstractWidgs"=> absWidg,  "htmlCode" => FileAccessUtils.readFileContent(path+name+"/htmlCode"),  "jsCode" =>  FileAccessUtils.readFileContent(path+name+"/jsCode"), "cssCode" =>  FileAccessUtils.readFileContent(path+name+"/cssCode"), "dependencies" => FileAccessUtils.readFileContent(path+name+"/dependencies") })
end

ModelUtils.createObjects(widgets,type)