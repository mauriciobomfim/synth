require "utils"
type = "JSEffect"
effects = Array.new

path = "#{RAILS_ROOT}/app/models/effect/"

names = Dir["#{RAILS_ROOT}/app/models/effect/**"].select { |entry| File.directory?(entry) }.map {|entry| File.basename(entry) }
names.each { |name| effects.push({ "name"=>"#{name}", "jsCode" =>  FileAccessUtils.readFileContent(path+name+"/jsCode"), "dependencies" => FileAccessUtils.readFileContent(path+name+"/dependencies") }) }

ModelUtils.createObjects(effects,type)