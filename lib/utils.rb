      # Author::    Andreia Luna (mailto: amluna@inf.puc-rio.br)
      # ---
      # Common functions
      # ---

class FileAccessUtils
  
    # Read a file
    def self.readFileContent(fileName)
      file = File.open(fileName)
      content = file.read
      file.close
      return content
    end

    # Write a file
    def self.writeFileContent(fileName, content="")
      file = File.new(fileName, "w")
      file.puts content
      file.close
    end

    # Delete a file
    def self.deleteFile(fileName)
      File.delete(fileName)
    end
    
end


class ModelUtils
  
  # Create Objects
  def self.createObjects(attributes,type)
        attributes.each do
         |hash| 
         object = eval("#{type}.new")
          hash.each do
            |key, value|
            if value.class == String
              eval("object.#{key}=\"#{value}\"") 
            elsif value.class == Array
              eval("object.#{key}=Array.new") 
              value.each { |item| eval("object.#{key}.push(\"#{item}\")")  }
            end
          end
          object.save
        end
  end

  # Traverses a JSON hash
  def self.traverseJSON(hash, list=false, &f)
    puts "XXXXentrei traverse"
    puts hash.inspect

    hash.each do |key,value|
      puts "XXXXentrei each"
      puts key.inspect
      puts value.inspect
      if (value.class == Array && !value.empty?)
        yield('OpenList',key,value,hash,list) # execute the code in the block
        traverseJSON(value.first,true,&f)
        yield('CloseList',key,value,hash,list) # execute the code in the block
      else
        yield('Item',key,value,hash,list) # execute the code in the block
      end
    end
  end

end

