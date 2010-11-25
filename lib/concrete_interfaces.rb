# Author::    Andreia Luna (mailto: amluna@inf.puc-rio.br)
# ---
# This class renders a concrete interface as a HTML page,
# which involves resolving the references found in compilation time.
# ---

require "utils"

class ConcreteInterfaces
  
  class << self
    
    # class variables (constants...)
    @@filesPath = "#{RAILS_ROOT}/lib/ci_data/"
    @@headerFile1 = FileAccessUtils.readFileContent(@@filesPath + "openHeader.inc")
    @@headerFile2 = FileAccessUtils.readFileContent(@@filesPath + "closeHeader.inc")
    @@javascriptsFile = FileAccessUtils.readFileContent(@@filesPath + "javascripts.inc")
    @@footerFile = FileAccessUtils.readFileContent(@@filesPath + "footer.inc")

    def render_interface(interface,data="")
      createPages(interface,data)
      # Output variable holds the page content
      return @output
    end

    private   # subsequent methods are private.

    # Renders a HTML page
    def createPages(interface,data)
      page = interface.interface_name.first
      
      headerContent = "#{@@headerFile1}\n<title>#{page}</title>\n<link rel='stylesheet' type='text/css' href='/stylesheets/swui.css' />\n#{@@javascriptsFile}\n"
    
      footerContent = @@footerFile
      
      # References in a hash variable
      @references = Hash.new
      buffer = interface.interface_ref.first
      unless buffer.nil?
          buffer = buffer.split(";")
          buffer.each do |value| 
             value=value.split("=") 
             @references[value[0]] = value[1]
           end
      end
     
      @bodyContent = ""
      # ajaxcontrolIds variable holds an array with the page ajaxcontrol ids 
      @ajaxcontrolIds  = Array.new
      @effectIds = Array.new
      @concreteInterfaceIds  = Array.new
      @eventData = "// Retrieves the events specification embedded in the page code \n function readEvents(interfaceName) { \n"
      @animData =   "// Retrieves the decorations specification embedded in the page code \n function readDecorations(interfaceName) { \n"
      @transData =  "// Retrieves the transitions specification embedded in the page code \n function readTransitions(interfaceName) { \n"
      success = printInterface(page,interface.concrete_code.first, interface.ajaxcontrols.first, interface.concrete_interfaces.first, interface.effects.first, data)
      @eventData << " return '' \n}\n"
      @animData <<   " return '' \n}\n"
      @transData <<  " return '' \n}\n"
      @bodyContent << "\n"
      @bodyContent << "<script type='text/javascript'> \n"
      @bodyContent << printAjaxcontrolJS
      @bodyContent << printEffectJS
      @bodyContent << "// Call updateInterface function \n"
      @bodyContent << "function callUpdateInterfaces() { \n"
      if (success)
        @bodyContent << "updateInterfaces('#{page}');\n" 
      end
      @bodyContent << "}\n"
      if (success)
        @bodyContent << "// Retrieves the JSON Context or Index data embedded in the page code \n"
        @bodyContent << "function readJSONData(interfaceName) { \n"
        @bodyContent << "if (interfaceName == '#{page}') { \n"
        @bodyContent << "return #{data.inspect} \n" 
        @bodyContent << "} \n"
        @bodyContent << "return '' \n"
        @bodyContent << "}\n"
        @bodyContent << @eventData
        @bodyContent << @animData
        @bodyContent << @transData
      end
      @bodyContent << "</script>"
      headerContent << printEffectDep
      headerContent << printAjaxControlDep
      headerContent << printCSS 
      headerContent << @@headerFile2
      @output = "#{headerContent}\n#{@bodyContent}\n#{footerContent}"
      
    end

    # Includes the ajaxcontrol-related JS code
    def printAjaxcontrolJS
      ajaxcontrolJS = "//RichControl Logic\n"
      @ajaxcontrolIds.each do
        |ajaxcontrolId|
        ajaxcontrol = SWUI::RichControl.find_by.concrete_widget_name(ajaxcontrolId).execute.first
        functionName = "swui_Rich_#{ajaxcontrolId.gsub(/-/,"_")}"
        ajaxcontrolJS << "function #{functionName}(swui_id) {\n"
        ajaxcontrolJS << ajaxcontrol.jsCode.first
        ajaxcontrolJS << "\n"
        ajaxcontrolJS << "}\n"
      end
      ajaxcontrolJS << "\n"
      return ajaxcontrolJS
    end

    # Includes the ajaxcontrol external references (scripts & style sheets)
    def printAjaxControlDep
      ajaxcontrolDep="\n"
      ajaxcontrolDepArray = Array.new
      buffer = ""
      @ajaxcontrolIds.each do
        |ajaxcontrolId|
        ajaxcontrol = SWUI::RichControl.find_by.concrete_widget_name(ajaxcontrolId).execute.first
        buffer = ajaxcontrol.dependencies.first
        unless buffer.nil?
            buffer.split("\n").each do
              |dependence|
              if (!ajaxcontrolDepArray.include?(dependence)) then
                ajaxcontrolDepArray.push dependence
                ajaxcontrolDep << "#{dependence}\n"
              end
            end
        end
      end
      return ajaxcontrolDep
    end

    # Includes the effect-related JS code
    def printEffectJS
      effectJS = "//Effects Logic\n"
      @effectIds.each do
        |effectId|
        effect = SWUI::Effect.find_by.effect_name(effectId).execute.first
        unless effect.nil?
          functionName = "swui_Effect_#{effectId.gsub(/-/,"_")}"
          effectJS << "function #{functionName}(widgetA, widgetB, parameters)  {\n"
          effectJS << effect.jsCode.first
          effectJS << "\n"
          effectJS << "}\n"
        end
      end
      effectJS << "\n"
      return effectJS
    end

    # Includes the effect external references (scripts)
    def printEffectDep
      effectDep="\n"
      effectDepArray = Array.new
      buffer = ""
      @effectIds.each do
        |effectId|
        effect = SWUI::Effect.find_by.effect_name(effectId).first
        unless effect.nil?
          buffer = effect.dependencies
          unless buffer.nil?
              buffer.split("\n").each do
                |dependence|
                if (!effectDepArray.include?(dependence)) then
                  effectDepArray.push dependence
                  effectDep << "#{dependence}\n"
                end
              end
          end
        end
      end
      return effectDep
    end

    # Includes the CSS style sheets
    def printCSS
      css="<style type=\"text/css\">\n" 
      @concreteInterfaceIds.each do
        |concrete_interface|
        concrete_interface = SWUI::ConcreteInterface.find_by.interface_name(concrete_interface).execute.first.concrete_interface_code.first
        css << concrete_interface
        css << "\n"
      end
      @ajaxcontrolIds.each do
        |ajaxcontrolId|
        ajaxcontrol = SWUI::RichControl.find_by.concrete_widget_name(ajaxcontrolId).execute.first
        cssCode = ajaxcontrol.cssCode.first
        css << "#{cssCode}\n"
      end
      css << "</style>\n"
      return css
    end

    # Sets the @ajaxcontrolIds 
    def findAjaxControls(ajaxcontrols)
      ajaxcontrols = ajaxcontrols.split(";") 
      ajaxcontrols.each do
        |ajaxcontrolId|
        if (!@ajaxcontrolIds.include?(ajaxcontrolId)) then
          @ajaxcontrolIds.push(ajaxcontrolId)
        end
      end
    end

    # Sets the @concreteInterfaceIds
    def findCSS(css)
      css = css.split(";") 
      css.each do
        |concrete_interface|
        if (!@concreteInterfaceIds.include?(concrete_interface)) then
          @concreteInterfaceIds.push(concrete_interface)
        end
      end
    end

    # Sets the @effectIds 
    def findEffects(effects)
      effects = effects.split(";") 
      effects.each do
        |effectId|
        if (!@effectIds.include?(effectId)) then
          @effectIds.push(effectId)
        end
      end
    end

    # Includes a concrete interface code in a page
    def printInterface(pageName, concreteCode, ajaxcontrols=nil, css=nil, effects=nil, appData="")
      findAjaxControls(ajaxcontrols) unless ajaxcontrols.nil?
      findCSS(css) unless css.nil?
      findEffects(effects) unless effects.nil?
      data = get_events(pageName)
      @eventData << "if (interfaceName == '#{pageName}') { \n"
      data = "{\"nodes\":[#{data}]}" unless data.nil? or data.blank?
      @eventData << "return '#{data}' \n" 
      @eventData << "} \n"
      data = get_decorations(pageName)
      @animData << "if (interfaceName == '#{pageName}') { \n"
      data = "{\"nodes\":[#{data}]}" unless data.nil? or data.blank?
      @animData << "return '#{data}' \n" 
      @animData << "} \n"
      data = get_transitions(pageName)
      @transData << "if (interfaceName == '#{pageName}') { \n"
      data = "{\"nodes\":[#{data}]}" unless data.nil? or data.blank?
      @transData << "return '#{data}' \n" 
      @transData << "} \n"
      begin
        # Exceptions raised by this code will
        # be caught by the following rescue clause
        concreteCode.each { |line|
              @bodyContent << line
              divId = line.slice(/<div id='\S+'/)
              if (!divId.nil?)
                  divId.slice!('<div id=\'')
                  divId.slice!('\'')
                  interfaceToInclude = @references[divId]
                  if (!interfaceToInclude.nil?)
                          interfObj = SWUI::Interface.find_by.interface_name(interfaceToInclude).execute.first

                          if (interfObj.dynamic=="true") then
                            compiler = AICompiler.new
                            abstr_spec= SWUI::AbsInterface.preCompile(interfObj.abstract_spec.first,true, appData).first
                            compiler.parseXML(abstr_spec)
                            interfObj.concrete_code = compiler.concrete_code
                          end
                          
                          codeToInclude = interfObj.concrete_code.first
                          ajaxcontrolsToInclude = interfObj.ajaxcontrols.first
                          cssToInclude = interfObj.concrete_interfaces.first
                          effectsToInclude= interfObj.effects.first
                          printInterface(interfaceToInclude, codeToInclude, ajaxcontrolsToInclude, cssToInclude, effectsToInclude, appData)
                  end
              end
        }
        return true
      rescue Exception
        @bodyContent << "Interface #{pageName} not found.\n"
        @bodyContent << $! 
        return false
      end
    end
    
    def get_transitions(interfaceName)
      return SWUI::Interface.find_by.interface_name(interfaceName).execute.first.transitions.first rescue nil
    end
    
    def get_events(interfaceName)
      return SWUI::Interface.find_by.interface_name(interfaceName).execute.first.events.first rescue nil
    end
    
    def get_decorations(interfaceName)
      return SWUI::Interface.find_by.interface_name(interfaceName).execute.first.decorations.first rescue nil
    end
    
    end
end