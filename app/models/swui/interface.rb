require "ai_compiler"
require "rhet_compiler"
require 'json'

SWUI::Interface
SWUI::ConcreteInterface
SWUI::AbsInterface
SWUI::ComponentInterface
SWUI::AbstractInterface
SWUI::ContextInterface
SWUI::IndexInterface

class SWUI::Interface

	property SWUI::interface_name, 'rdfs:subPropertyOf' => RDFS::label
  
end

class SWUI::ConcreteInterface; sub_class_of SWUI::Interface

  property SWUI::concrete_interface_code
  
end

class SWUI::AbsInterface; sub_class_of SWUI::Interface

	property SWUI::abstract_spec
  property SWUI::dynamic
  property SWUI::widget_decription_type
  
    # resolves the includes statements and execute Ruby code
    def self.preCompile(xml,executeCode=false,data="")
      puts 'entrei precompile'
      puts xml.inspect
      puts executeCode
      puts data
      puts 'XXXXXXXXX'       
      new_xml = ""
      escapeLine = false
      dyn = false
      rubyCode = ""
      xml.each_line do
        |line|
        includeLine = line.match(/^\s*<%=\s*include\s+\w+\s*%>\s*$/).to_s
        if (includeLine.empty?) then
          notOpenCodeLine = line.match(/^\s*<%\s*$/).to_s.empty? 
          notCloseCodeLine = line.match(/^\s*%>\s*$/).to_s.empty?
          notCodeLine = notOpenCodeLine && notCloseCodeLine
          if (notCodeLine) then
            if (escapeLine)
              rubyCode << line
              rubyCode << "\n"
            else
              new_xml << line  
              new_xml << "\n"
            end
          else
              if (notCloseCodeLine) then
                # open code line
                escapeLine = true
              else
                # close code line
                escapeLine = false
                if (executeCode) then
                    # executes a piece of Ruby code inside an abstract specification
                    # init variables
                    jsonData = Hash.new
                    list = false
                    buffer = ""
                    unless data.empty?
                        puts 'antes jsonparse'
                        hash = JSON.parse(data)
                        puts 'depois jasonparse'
                        puts hash.inspect
                        hash["nodes"].each { |item| list=true if item.has_key? "swui:landmark" } # it is an IndexInteface
                        puts 'depois hashnodes'
                        # jsonData is the variable that holds the dynamic data
                        # and can be referred to from the Ruby code
                        jsonData = hash["nodes"].first                        
                    end
                    unless rubyCode.empty?
                      puts 'antes eval'                      
                      puts rubyCode
                      eval("#{rubyCode}; new_xml << buffer") # buffer is the variable that holds the abstract spec and it is set inside the Ruby code
                      puts 'depois rubycode'
                    end
                    rubyCode = ""
                end
              end    
          end
        else
          includeLine.gsub!(/^\s*<%=\s*include\s+/,"")
          includeLine.gsub!(/\s*%>\s*$/,"")
          puts "antes find_by"
          component = SWUI::ComponentInterface.find_by.swui::interface_name(includeLine).execute.first
          if !component.nil? then
            puts "antes precompile"
            buf = SWUI::AbsInterface.preCompile(component.abstract_spec.first,executeCode,data)
            puts "depois precompile"
            new_xml << buf.first
            dyn = buf.last
          end
        end
      end
      dyn = dyn || !rubyCode.empty?
      return [new_xml,dyn]
    end

    def save
      unless self.widget_decription_type.first == "concrete"
        bool = eval("#{self.classes.first}.compile(self)")
        super unless !bool
        bool
      else
        super
      end
    end
  
    def errMsg(attr, msg)
      errors.add(attr, msg) 
    end

end

class SWUI::ComponentInterface; sub_class_of SWUI::AbsInterface
  
  def self.compile(obj)
    compiler = AICompiler.new
    buffer = SWUI::AbsInterface.preCompile(obj.abstract_spec.first)
    success = compiler.parseXML(buffer.first,obj.interface_name.first)
    if (success) then    
        obj.dynamic = buffer.last.to_s
        true
    else
        obj.errMsg("abstract_spec", compiler.error_msg) 
        false
    end
  end
  
  def save
    unless self.widget_decription_type.first == "concrete"
      bool = SWUI::ComponentInterface.compile(self)
      super unless !bool
      bool
    else
      super
    end
  end

end

class SWUI::AbstractInterface; sub_class_of SWUI::AbsInterface

	property SWUI::concrete_code
	property SWUI::interface_ref
  property SWUI::concrete_interfaces
	property SWUI::rhet_spec
	property SWUI::transitions
	property SWUI::events
	property SWUI::decorations
  property SWUI::effects
  property SWUI::ajaxcontrols

  def self.preCompile(xml,executeCode=false,data="")
    SWUI::AbsInterface.preCompile(xml, executedCode, data)
  end
  
  def self.compile(obj)
    component = ""
    concrete_interfaces = obj.concrete_interfaces.first.strip rescue nil
    err=false
    unless concrete_interfaces.nil?
      puts 'antes concrete interface split'
      puts concrete_interfaces.inspect
      concrete_interfaces.split(";").each do
        |name|
        component = SWUI::ConcreteInterface.find_by.interface_name(name).execute.first
        if component.nil? then 
          err=true
        end
      end
      puts 'depois concrete interface split'
    end
    if err then
        obj.errMsg("concrete_interfaces", "CSS Style Sheet not found.") 
        false
    else
        compiler = AICompiler.new
        buffer = SWUI::AbsInterface.preCompile(obj.abstract_spec.first)
        success = compiler.parseXML(buffer.first,obj.interface_name.first)
        if (success) then    
            dyn = buffer.last.to_s
            obj.concrete_code = compiler.concrete_code
            buffer = ""
            compiler.references.each  { |key, value| buffer << "#{key}=#{value};" }
            obj.interface_ref = buffer
            obj.ajaxcontrols = compiler.ajaxcontrols.join(";") unless compiler.ajaxcontrols.nil?
            obj.dynamic = dyn
            unless obj.rhet_spec.first.nil? 
                  compiler = RhetCompiler.new
                  compiler = executeDSL(compiler, obj.rhet_spec.first)
                  success = compiler.compile
                  if (success) then
                    # converts arrays into strings separated by ',' and append them to the attributes
                    obj.transitions = "" 
                    obj.events = "" 
                    obj.decorations = "" 
                    obj.effects = "" 
                    obj.transitions = compiler.transitions[obj.interface_name.first].join(",") unless compiler.transitions[obj.interface_name.first].nil?
                    obj.events = compiler.events[obj.interface_name.first].join(",") unless compiler.events[obj.interface_name.first].nil?
                    obj.decorations =  compiler.decorations[obj.interface_name.first].join(",") unless compiler.decorations[obj.interface_name.first].nil?
                    obj.effects =  compiler.effects[obj.interface_name.first].join(";") unless compiler.effects[obj.interface_name.first].nil?
                    true
                  else
                    obj.errMsg("rhet_spec", compiler.error_msg) 
                    false
                  end
            else
                    true
            end
        else
            obj.errMsg("abstract_spec", compiler.error_msg) 
            false
        end
    end
  end

  def save
    unless self.widget_decription_type.first == "concrete"
      bool = SWUI::AbstractInterface.compile(self)
      super unless !bool
      bool
    else
      super
    end
  end
  
  private  # private methods
  
  def self.executeDSL(compiler, source)
    source.split("\n").each do
      |line|
      buffer = ""
      #eval('compiler.transition "name"=>"TwitterSearch", "hasRhetoricalStructures"=>"rhseq1", "toInterface"=>"TwitterSearch"')
      code = line.strip
      eval("compiler.#{code}")  unless code.empty?
    end
    return compiler
  end

end

class SWUI::ContextInterface; sub_class_of  SWUI::AbstractInterface
	property SWUI::context, 'rdfs:range' => SHDM::Context
	property SWUI::domain_class, 'rdfs:range' => RDFS::Class
  
  def self.find_by_context_and_class(context)
    fail_on_nil_context(context)
    return nil if context.empty?
		find_by_context_id_and_nav_class_id(context.id, context.current.nav_class.id)
	end

	def self.find_by_context(context)
    fail_on_nil_context(context)
	  find_by_context_id_and_nav_class_id(context.id, nil)
	end
		
  def self.find_by_class(context)
    fail_on_nil_context(context)
    return nil if context.empty?
    find_by_context_id_and_nav_class_id(nil, context.current.nav_class.id)
  end

  def self.find_generic
    find_by_context_id_and_nav_class_id nil, nil
  end

  def self.fail_on_nil_context(context)
    fail "Context cannot be nil" if context.nil?
  end
  
  def save
    unless self.widget_decription_type.first == "concrete"
      bool = SWUI::AbstractInterface.compile(self)
      super unless !bool
      bool
    else
      super
    end
  end
  
end

class SWUI::IndexInterface; sub_class_of SWUI::AbstractInterface

  property SWUI::index, 'rdfs:range' => SHDM::Index

  def self.find_by_index(index)
    fail "Index cannot be nil" if index.nil?
    find_by_index_id(index.id)
  end
  
  def self.find_generic
    find_by_index_id nil
  end
  
  def save
    unless self.widget_decription_type.first == "concrete"
      bool = SWUI::AbstractInterface.compile(self)
      super unless !bool
      bool
    else
      super
    end
  end
  
end