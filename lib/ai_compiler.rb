      # Author::    Andreia Luna (mailto: amluna@inf.puc-rio.br)
      # ---
      # The program parses an abstract widgets description,
      # generating HTML code for the concrete interface.

class AICompiler
      require "fileutils"
      require "rexml/document"
      #require 'xml/libxml' -- libxml is not currently supported in JRuby
      require "utils"
      #require "swui/concrete_widget"
      
      include REXML  # so we do not need to prefix everything with REXML::...

      attr_reader :concrete_code, :references, :error_msg, :abstractInterfaceName, :ajaxcontrols

      # class variables (constants...)
      @@prefix_dir = "#{RAILS_ROOT}/lib/ai_data/"
      @@dtdFileName = 'swui.dtd'
      @@dtd = FileAccessUtils.readFileContent(@@prefix_dir+@@dtdFileName)
      @@tmpInput = "#{RAILS_ROOT}/tmp/aispec-xml.tmp"
      ['noCloseTags'].each do 
        |hashName|
          eval "@@#{hashName} = Hash.new" 
          IO.foreach(@@prefix_dir+hashName) { |line|
                line.chop!
                key,value = line.split(/\s*\:=\s*/)
                value = (value == nil) ? "" : value
                eval "@@#{hashName}[key]=value" 
          }
        end
      
      #@@modelAttributeRef  = "<span id=\"\" property='' class='swui_ajax_invisible'> property </span>"
      @@modelAttributeRef  = "<input type=\"text\" name=\"\" id=\"\" property='' value=\"\" class='swui_ajax_invisible'/>"
      @@ajaxControlName = "<span property='swui:ajaxControlId' class='swui_ajax_invisible'> property </span>"


      def initialize
            # References in a hash variable
            @concrete_code = ""
            @references = Hash.new
            @ajaxcontrols = Array.new
            @error_msg = ""
            @HTMLTagMap = Hash.new
            SWUI::HtmlTag.find_all.each do
              |widget|
              @HTMLTagMap[widget.concrete_widget_name.first]=widget.legalTags.first
            end
            @concreteWidMap = Hash.new
            SWUI::ConcreteWidget.find_all.each do
              |widget| 
              @concreteWidMap[widget.concrete_widget_name.first]=widget.legalAbstractWidgs.to_s
            end
      end
      
      # Parses and validates the input xml.
      def parseXML(xml, intefaceName=nil)
            
            @success = validateXML(xml)
            @interfaceName = intefaceName
            if (@success) then
                  @abstractInterfaceName = ""
                  begin
                        # Exceptions raised by this code will
                        # be caught by the following rescue clause
                        doc = Document.new xml                        
                        traverseXML(doc)
                  rescue Exception
                        @error_msg << "An error occurred while parsing the XML file: "
                        @error_msg <<  $!.to_s.split("\n").first.gsub("<","")
                        return false
                  end
            else
                  @error_msg << "An error occurred while parsing the XML file. Not valid XML."
            end
            return @success
     end
      
      private   # subsequent methods are private.


      # Performs XML validation against a DTD 
      def validateXML(xml)
            return true
            # libxml is not currently supported in JRuby
            dtd = XML::Dtd.new(@@dtd)
            inputFile = File.new(@@tmpInput, "w")
            inputFile.puts xml
            inputFile.close
            document = XML::Document.file(@@tmpInput)
            return document.validate(dtd)
      end

      # Traverse an XML tree
      def traverseXML(doc)
        doc.elements.each do |element|
            attrs = element.attributes
            if (element.name == 'AbstractInterface') then
              @abstractInterfaceName = attrs['name']
              if !@abstractInterfaceName.eql?(@interfaceName) then
                @error_msg <<  "AbstractInterface widget must be named after the interface: #{@interfaceName}"
                @success = false
              end
            end
            # we are compiling abstract widgets into concrete ones
            mapsTo = attrs['mapsTo'].nil? || attrs['mapsTo'].empty?
            tagAttr = attrs['tagAttributes'].nil? || attrs['tagAttributes'].empty?
            cssClas = attrs['cssClasses'].nil? || attrs['cssClasses'].empty?
            unless mapsTo && tagAttr && cssClas && @concrete_code.empty?
              closeTag = printConcreteWidg(attrs, element.name) 
              if (closeTag == 0) then
                    @success = false;
                    return
              end
            end
            traverseXML element
            # we are compiling abstract widgets into concrete ones
            unless mapsTo && tagAttr && cssClas && @concrete_code.empty?
              @concrete_code <<  closeTag unless closeTag == nil
            end
        end
      end

      # Translates abstract widgets into HTML code
      def printConcreteWidg(attrs, type)
            # checks if the abstract-concrete mapping is valid
            if attrs['mapsTo'].nil? || attrs['mapsTo'].empty? then
                @error_msg <<  "A concrete mapping was not found for #{type} named #{attrs['name']}."
                return 0
            end
            if (@concreteWidMap[attrs['mapsTo']].nil? || (!@concreteWidMap[attrs['mapsTo']].include?(type))) then
                @error_msg <<   "An illegal concrete widget for #{type} named #{attrs['name']} was found: #{attrs['mapsTo']}.".gsub("<","&lt;")
                return 0
            end
            if (ajaxcontrol = SWUI::RichControl.find_by.concrete_widget_name(attrs['mapsTo']).execute.first) then
                  ajaxcontrolId = attrs['mapsTo']  # a reference to an ajaxcontrol object
                  if (!@ajaxcontrols.include?(ajaxcontrolId)) then
                    @ajaxcontrols.push(ajaxcontrolId)
                  end
                  #ajaxcontrol = ajaxcontrol.find_by_name(ajaxcontrolId)
                  htmlCode = ajaxcontrol.htmlCode.first
                  modelAttributeRef = @@modelAttributeRef
                  modelAttributeRef = modelAttributeRef.gsub(/\sname=""/, " name=\"#{attrs['name']}\"")
                  modelAttributeRef = modelAttributeRef.gsub(/\sid=""/, " id=\"#{attrs['name']}\"")
                  modelAttributeRef = modelAttributeRef.gsub(/\sproperty=''/, " property='#{attrs['fromAttribute']}'") 
                  #modelAttributeRef = modelAttributeRef.gsub(/\sproperty\s/, " #{attrs['fromAttribute']} ")
                  ajaxControlName = @@ajaxControlName
                  ajaxControlName = ajaxControlName.gsub(/> property </,">#{ajaxcontrol.concrete_widget_name.first}<")
                  htmlCode.gsub!(/\sid="/, " property='swui:ajaxControl' id=\"#{attrs['name']}#") # includes the abstract element name in every concrete widget's id inside the ajaxcontrol. Also it includes the property attribute inside each tag
                  firstTagAjaxControl = htmlCode.slice(/\A<.+>/)

                  if attrs['fromAttribute'].nil? || attrs['fromAttribute'].empty?
                      # does not include the widget that will hold the model attribute if the ajaxcontrol does not map a model attribute
                      htmlCode.gsub!(/\A<.+>/, "#{firstTagAjaxControl}\n#{ajaxControlName}\n") 
                  else
                      # includes the widget that will hold the model attribute value inside the ajaxcontrol
                      htmlCode.gsub!(/\A<.+>/, "#{firstTagAjaxControl}\n#{modelAttributeRef}\n#{ajaxControlName}\n")  
                  end
                  
                  @concrete_code << htmlCode
                  @concrete_code << "\n"

                  closeTag = nil
            else
                  tagAttrHash = Hash.new 
                  tag = @HTMLTagMap[attrs['mapsTo']]
                  tag = tag.sub("<","")
                  tag = tag.sub(">","")
                  tagAttrs = tag.split(" ")  
                  tagName = tagAttrs.shift # removes array first element
                  if (tagName == 'input') then
                        typeAttribute = tagAttrs.select {|a| a =~ /type=/} # searches for type='' attribute 
                        tagName = tagName + " " + (typeAttribute.empty? ? "" : typeAttribute.first)
                  end
            
                  # Is tagName an allowed translation to the concrete widget?
                  matchLegalTag = (@HTMLTagMap[attrs['mapsTo']].include? "<#{tagName}>")
                  if (!matchLegalTag) then
                        @error_msg <<  "An illegal tag for #{attrs['mapsTo']} was found in the #{type} named #{attrs['name']}: <#{tagName}>.".gsub!("<","&lt;")
                        return 0
                  end
                  
                  # looks for attributes particularly defined
                  unless (attrs['tagAttributes'].nil?||attrs['tagAttributes'].empty?)
                    attrs['tagAttributes'].split("|").each { |item|  tagAttrs.push(item) } 
                  end

                  # Removes any class='' attribute in tag
                  #tag.gsub!(/class='(\w*\s?)+'/, '')
                  
                  tagAttrs.each do |attr|
                    pair = attr.split("=")
                    tagAttrHash[pair[0]]=pair[1] unless (pair[0] =='class' || pair[0] =='type')
                  end
                  
                  openTag = "<" + tagName + " id='#{attrs['name']}'"
                  if (type == 'AbstractInterface') then
                    openTag << " typeof='swui:AbstractInterface'"
                  end
                  unless attrs['fromClass'].nil? 
                    openTag << " typeof='#{attrs['fromClass']}'" unless attrs['fromClass'].empty?
                  end
                  # either a SimpleActivator maps a navigation action (target defined in fromAttribute) or it maps a Model Operation (defined in fromAction)
                  if !attrs['fromAttribute'].nil?&&(!attrs['fromAttribute'].empty?) then
                        openTag << " property='#{attrs['fromAttribute']}'" 
                  elsif (!attrs['fromAction'].nil? && !attrs['fromAction'].empty?)then
                        openTag << " property='swui:action'"
                        openTag << " " + setActCall(attrs)
                  end
                  if (!attrs['defaultContent'].nil? && !attrs['defaultContent'].empty?) then
                        openTag << " property='swui:literal'"  unless  (!attrs['fromAttribute'].nil? && !attrs['fromAttribute'].empty?)
                  end
                  
                  case tagName.split(" ").first
                        # sets required attributes if they are not provided by tagAttributes property
                        when "form"
                              openTag << " action='#'" 
                              openTag << " method='post'" 
                        when "input"
                              if (attrs['mapsTo']=='Button') then
                                    openTag << " value='Enviar'" unless !tagAttrHash['value'].nil?
                                    openTag << setTarget(attrs) unless (attrs['fromAttribute'].nil?) # Testar!!
                              elsif (attrs['mapsTo']=='TextBox')
                                    openTag << " value='#{attrs['defaultContent']}'" unless attrs['defaultContent'].nil?
                              else
                                   # CheckBox, RadioButton
                              end
                              if (attrs['mapsTo']=='CheckBox' || attrs['mapsTo']=='RadioButton')
                                    unless (attrs['fromAttribute'].nil? || attrs['fromAttribute'].empty? || !tagAttrHash["name"].nil?)
                                        name = attrs['fromAttribute']
                                        name = name.gsub(/\|/,"-")
                                        name = name.gsub(/_/,"-")
                                        openTag << " name='#{name}'" 
                                    else 
                                        openTag << " name='#{attrs['name']}'" unless !tagAttrHash['name'].nil?
                                    end
                              else
                                    openTag << " name='#{attrs['name']}'" unless !tagAttrHash['name'].nil?
                              end    
                        when "textarea"
                              openTag << " name='#{attrs['name']}'" unless !tagAttrHash['name'].nil?
                              openTag << " rows='3'" unless !tagAttrHash['rows'].nil?
                              openTag << " cols='40'" unless !tagAttrHash['cols'].nil?
                        when "select"
                              openTag << " name='#{attrs['name']}'" unless !tagAttrHash['name'].nil?
                        when "img"
                              openTag << " src='#{attrs['defaultContent']}'" unless attrs['defaultContent'].nil?||attrs['defaultContent'].empty?
                              openTag << " alt='#{attrs['fromAttribute']}'" unless !tagAttrHash['alt'].nil?
                        when "a"
                              openTag << setTarget(attrs) unless (attrs['fromAttribute'].nil?)
                      else
                  end

                  unless attrs['ordered'].nil?
                    if (attrs['ordered'] == 'true') then
                      if (attrs['cssClasses'].nil?) then
                        attrs['cssClasses'] = "swui_ordered"
                      else
                        attrs['cssClasses'] << " swui_ordered" 
                      end
                    end
                  end
                  # sets the other attributes provided by tagAttributes property
                  tagAttrHash.each { |key, value| openTag << " #{key}=#{value}" }
                    
                  css_invisible = ""
                  if (!attrs['fromClass'].nil?) then
                    if (!attrs['fromClass'].empty?) then
                      # context node templates are hidden and
                      css_invisible = "swui_invisible "
                    end
                  end
                  if (type == 'AbstractInterface') then
                      # all interfaces are hidden at first
                      css_invisible = "swui_invisible "
                  end
                  if (!attrs['cssClasses'].nil? && !attrs['cssClasses'].empty?) then
                      openTag << " class='#{css_invisible}#{attrs['cssClasses']}'"
                  else
                      openTag << " class='#{css_invisible.chop}'"  unless css_invisible.empty?
                  end
                  
                  if (@@noCloseTags[tagName.split(" ").first].nil?) then
                        openTag = openTag + ">\n"    
                            if !attrs['defaultContent'].nil?
                              openTag << " " + attrs['defaultContent'] + "\n"
                            elsif !attrs['fromAttribute'].nil?
                              openTag << " " + attrs['fromAttribute'] + "\n" unless attrs['fromAttribute'].empty?
                            end
                        closeTag = "</" + tagName + ">\n"
                  else
                       openTag = openTag + "/>\n"
                       closeTag = nil
                  end
                  @concrete_code << openTag

                  if (!attrs['loadInterface'].nil?) then 
                    createReference(attrs['name'], attrs['loadInterface'])
                  end
                  
            end
            
            return closeTag
      end
      
      # Creates javascript code for a navigation
      def setTarget(attrs)
            return " onclick=\"javascript: navTarget(this.href, '#{@abstractInterfaceName}', '#{attrs['targetInterface']}');return false;\""
      end
      
      # Creates javascript code for an action
      def setActCall(attrs)
            callString = "onclick=\"javascript:"
            callString += "callAction('#{attrs['fromAction']}', this, '#{@abstractInterfaceName}', '#{attrs['targetInterface']}', '#{attrs['transitionInterface']}');return false;\""
            return callString 
      end     

      # Saves references 
      def createReference(container, content)
            @references[container] = content
      end
      
end
