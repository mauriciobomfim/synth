
# add the directory in which this file is located to the ruby loadpath
file =
if File.symlink?(__FILE__)
  File.readlink(__FILE__)
else
  __FILE__
end
$: << File.dirname(File.expand_path(file))

java_dir = File.expand_path(File.join(File.dirname(File.expand_path(file)), "..", "..", "ext"))
require "#{java_dir}/openrdf-sesame-2.0-beta5-onejar.jar" 
require "#{java_dir}/slf4j-api-1.3.0.jar" 
require "#{java_dir}/slf4j-jdk14-1.3.0.jar" 
require "#{java_dir}/wrapper-sesame2.jar" 

require 'sesame'

