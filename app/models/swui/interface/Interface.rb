require "utils"
path = "#{RAILS_ROOT}/app/models/swui/interface/"

ary = Array.new
ary.push("type" => "ComponentInterface", "names" =>  ["DefaultJSONDisplay","DefaultContextIndex","DefaultLandmarks","DefaultLandmarksForIndexes","DefaultNavBar"])
ary.push("type" => "AbstractInterface", "names" =>  ["DefaultAbstractInterface"])
ary.push("type" => "ContextInterface", "names" =>  ["DefaultContextInterface"])
ary.push("type" => "IndexInterface", "names" =>  ["DefaultIndexInterface"])

ary.each do
     |item|
     type = item["type"]
     names = item["names"]
     interfaces = Array.new
     names.each { |name| interfaces.push({ "name"=>"#{name}", "abstract_spec" =>  FileAccessUtils.readFileContent(path+name+"/abstract_spec")}) }
     ModelUtils.createObjects(interfaces,type)
end


