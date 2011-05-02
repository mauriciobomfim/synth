# Author::    Andreia Luna (mailto: amluna@inf.puc-rio.br)
# ---
# Provide methods to the navigation controller and the user-defined controllers
# ---
require 'json'
require 'ai_compiler'

module SwuiController

  include ActionView::Helpers::JavaScriptHelper

  @@tmpdir="#{RAILS_ROOT}/tmp/"

  def push_response(seq, data="EOT")
    if (data != "EOT") then
      data = toJSON(data)
    end
    objectIdsPrefix = "o_"
    transactionId = params["transaction"]

    unless transactionId.nil?
        #hyperDEPushResponse(objectIdsPrefix+transactionId, data)
        fileSystemPushResponse(seq, transactionId, data)
    end
    
  end
  
  def render_context(navContext, current_node=nil, interface_name=nil)

    current_node = current_node
    
    init = Time.now
    interface = nil
    interfaceName = interface_name || params['swuiInterface'] 

    unless interfaceName.nil? || interfaceName.empty?
      interface = SWUI::ContextInterface.find_by.swui::interface_name(interfaceName).execute.first rescue nil
    end

    if interface.nil? then
        unless current_node.nil?
          interface ||= SWUI::ContextInterface.find_by.swui::context(navContext.context).swui::domain_class(current_node.classes.first).execute.first
          interface ||= SWUI::ContextInterface.find_by.swui::domain_class(current_node.classes.first).execute.first
        end
        interface ||= SWUI::ContextInterface.find_by.swui::context(navContext.context).execute.first
        interface ||= SWUI::ContextInterface.find_by.swui::interface_name("DefaultContextInterface").execute.first
    end
    
    if interface.nil? then
        return  "Interface #{interfaceName} not found."
    else
      if interface.widget_decription_type.first == "concrete"
        render_to_string :inline => interface.abstract_spec.first
      else
        interfaceName = interface.name if interfaceName.nil?
        #ctxData = formatJSONContextData(node)
        ctxData = node_to_swui_hash(current_node).to_json
        render_data(ctxData, interfaceName, interface)
        #Time.now.to_f - init.to_f
      end
    end
  end
  
  def render_index(navIndex, interface_name=nil) 

    interface = nil
    interfaceName = interface_name || params['swuiInterface'] 
    unless interfaceName.nil? || interfaceName.empty?
      interface = SWUI::IndexInterface.find_by.swui::interface_name(interfaceName).execute.first  rescue nil
    end
    interface ||= SWUI::IndexInterface.find_by.swui::index(navIndex.index).execute.first
    interface ||= SWUI::IndexInterface.find_by.swui::interface_name("DefaultIndexInterface").execute.first

    if interface.nil? then
        return "Interface #{interfaceName} not found."
    else
      if interface.widget_decription_type.first == "concrete"
        render_to_string :inline => interface.abstract_spec.first
      else
        interfaceName = interface.swui::interface_name.first if interfaceName.nil?
        landmarks = SHDM::Landmark.alpha(SHDM::landmark_position)
        idxData = formatJSONIndexData(navIndex.entries, landmarks)
        return render_data(idxData, interfaceName, interface)
      end
    end

  end

  def render_response(data, interfaceName=nil)
    defaultInterface = interfaceName
    interfaceName = params['swuiInterface']
    unless interfaceName.nil?||interfaceName.empty?
      interface = SWUI::AbstractInterface.find_by.swui::interface_name(interfaceName).execute.first  rescue nil
    end
      
    if  interface.nil? then
        interface = SWUI::AbstractInterface.find_by.swui::interface_name(defaultInterface).execute.first rescue nil
        interface = SWUI::AbstractInterface.find_by.swui::interface_name("DefaultAbstractInterface").execute.first if interface.nil?
    end

    if interface.nil? then
        return "Interface #{defaultInterface} not found."
    else
        return render_data(toJSON(data), interfaceName, interface)
    end

  end
  
  def render_data(data, interfaceName, interface=nil)      
      puts 'entrei render_data'
      transactionId = params["transaction"]
      unless transactionId.nil?
          seq = FileAccessUtils.readFileContent("#{@@tmpdir+transactionId}-0").to_s.strip.to_i rescue 100
          push_response(seq) 
      end
      puts 'antes if'
      if (interfaceName=="0") then
        return data
      else
        puts 'antes find_by'
        interface = SWUI::AbstractInterface.find_by.swui::interface_name(interfaceName).execute.first if interface.nil?
        puts 'depois find_by'
        if interface.nil? then
          return  "Interface #{interfaceName} not found."
        else
            abstr_spec=interface.abstract_spec.first
            if (interface.dynamic.first=="true") then
              # (default) dynamic interface
              compiler = AICompiler.new
              puts 'antes precompile'
              abstr_spec=SWUI::AbsInterface.preCompile(interface.abstract_spec.first,true,data)
              puts 'depois precompile'
              abstr_spec = abstr_spec.first
              compiler.parseXML(abstr_spec)
              interface.concrete_code = compiler.concrete_code
            end
            if (interfaceName=="1") then
              return abstr_spec
            else
              puts 'antes concrete'
              return ConcreteInterfaces.render_interface(interface,data)
            end
        end
      end
    
  end

  private

  def toJSON(data)
      if (data.class == Array) then
        array = data
      else
        array = []
        array << data
      end
      jsonString = JSON.generate array
      jsonString = jsonString.gsub("&quot;","'")
      data = "{\"nodes\":#{jsonString}}"
      return data
  end

  def node_to_swui_hash(node)
    hash = {
      :nodes => [ { 'swui:id' => node.uri } ]
    }
    hash[:nodes].first.merge!(direct_properties_hash(node))
    hash[:nodes].first.merge!(navigation_attributes_hash(node.attributes_hash))
    hash[:nodes].first.merge!(landmarks_hash(node.landmarks))
    hash[:nodes].first.merge!(default_index_hash(node))
    hash
  end
  
  def direct_properties_hash(node)
    hash = Hash.new
    for attr in node.direct_properties
      unless attr.first.is_a?(RDFS::Resource) || node.attributes_names.map{|v| v.downcase}.include?(attr.localname.downcase)
        key   = attr.label.nil? ? attr.compact_uri : attr.label.first
        value = CGI::escapeHTML(attr.to_s)
        hash.store(key, value)
      end
    end
    hash
  end
  
  def navigation_attributes_hash(attributes_hash)
    hash = Hash.new
    for attr in attributes_hash.keys
      key = attr
      value = attributes_hash[attr]
      classValue = value.class
      if (classValue == ContextAnchorNodeAttribute) || (classValue == IndexAnchorNodeAttribute)
        hash.store(key, CGI::escapeHTML(value.label.to_s))
        hash.store(key+'|swui:target', value.target_url)
      elsif classValue == IndexNodeAttribute
         entries = value.value.entries
         hash.store(key, entries.map{ |entry| 
            internal_hash = Hash.new
            entry.attributes_hash.each{|attrkey, attrvalue|               
              internal_hash.merge!(attribute_hash("#{key}|#{attrkey}", attrvalue))
            }
            internal_hash
         })
      else
        unless value.nil?
          hash.store(key, CGI::escapeHTML(value.value.to_s))
        end
      end          
    end
    hash
  end
  
  def landmarks_hash(landmarks)
    hash            = Hash.new
    landmarks_hashes = landmarks.map{ |landmark| { 
          "swui:landmarks|swui:landmark"             => landmark.label, 
          "swui:landmarks|swui:landmark|swui:target" => landmark.target_url
    } }
    hash.store("swui:landmarks", landmarks_hashes)
    hash
  end

  def default_index_hash(node)
    hash = Hash.new
    
    entries = node.default_index.entries

    previous_node_entry = nil
    next_node_entry = nil    
    
    entries_hashes = entries.map{ |entry|      
      if entry.uri == node.uri
        current_node_entry = entry
        current_index = entries.index(current_node_entry)
        previous_node_entry = entries[current_index - 1] if current_index > 0
        next_node_entry = entries[current_index + 1] if current_index < entries.size
      end
      
      internal_hash = Hash.new
      entry.attributes_hash.each{ |attrkey, attrvalue|        
        #key = attr.navigation_attribute.navigation_attribute_name.first
        internal_hash.merge!(attribute_hash("swui:idxEntry|#{attrkey}", attrvalue, node.uri != entry.uri))
      }
      internal_hash
    }
    hash.store("swui:contextIdx", entries_hashes)    
    hash.merge!(attribute_hash("swui:contextPrev|item", previous_node_entry.attributes_hash['item'])) unless previous_node_entry.nil?
    hash.merge!(attribute_hash("swui:contextNext|item", next_node_entry.attributes_hash['item'])) unless next_node_entry.nil?
    hash
  end
  
  
  def attribute_hash(label, attribute, is_anchor=true)
    hash = Hash.new
    hash.store(label, CGI::escapeHTML(attribute.label.to_s))
    if is_anchor && attribute.class == ContextAnchorNodeAttribute || attribute.class == IndexAnchorNodeAttribute
      hash.store("#{label}|swui:target", attribute.target_url)
    end
    hash
  end
    
  # PREVIEWS IMPLEMENTATION, ITS HERE FOR SECURE, BUT WILL BE DROPED SOON
  # Presents context data in JSON format 
  def formatJSONContextData(node)
    idx = node.default_index
    landmarks = node.landmarks
    id = node.uri
    buffer = "{\"nodes\":["
    buffer << "{\"swui:id\":\"#{id}\""

    attrs = node.attributes_hash
    lengthAttrsHash = attrs.length
    k = 0
          
    for attr in node.direct_properties
      unless attr.first.is_a?RDFS::Resource or attrs.keys.map{|v| v.downcase}.include?(attr.localname.downcase)
        key   = attr.label.nil? ? attr.compact_uri : attr.label.first
        value = attr.to_s
        buffer << ","
        buffer << "\"#{key}\":\"#{value}\""
      end
    end
          
    for attr in attrs.keys
      k = k + 1
      key = attr
      value = attrs[attr]
      classValue = value.class
      if (classValue == ContextAnchorNodeAttribute) || (classValue == IndexAnchorNodeAttribute)
              buffer << "," #unless k == 1
              buffer << "\"#{key}\":\"#{value.label}\""
              buffer << ",\"#{key}|swui:target\":\"#{value.target_url}\""
      elsif classValue == IndexNodeAttribute
              entries = value.value.entries
              lengthEntries = entries.length
              if lengthEntries > 0
                buffer << "," #unless k == 1
                buffer << "\"#{key}\":["
                j = 0
                for entry in entries
                  j = j + 1
                  buffer << "{"
                  lengthAttrHash = entry.attributes_names.length
                  i = 0
                  for attrEntry in entry.attributes_hash.keys
                    i=i+1
                    keyIdx = key + "|" + attrEntry
                    value =  entry.attributes_hash[attrEntry]
                    buffer << "\"#{keyIdx}\":\"#{value.label}\""
                    action = action_for_index_entry_attribute(value)
                    if action
                      buffer << ",\"#{keyIdx}|swui:target\":\"#{value.target_url}\""
                    end
                    if i < lengthAttrHash
                      buffer << ","
                    end
                  end
                  buffer << "}"
                  if j < lengthEntries
                    buffer << ","
                  end
                end
                buffer << "]"
              else 
                value = nil
              end
      else
        unless value.nil?
            buffer << "," #unless k == 1
            buffer << "\"#{key}\":\"#{value.value}\"" 
        end
      end          
    end
    
    # Includes application landmarks in context data as node attributes
    landmarksNum =  landmarks.length
    buffer << ",\"swui:landmarks\":[" unless landmarksNum == 0
    r = 0
    landmarks.each do
      |landmark|

      r = r + 1
      buffer << "{"
      
      buffer << landmarksAttr(landmark, "swui:landmarks")
      
      buffer << "}"

      if r < landmarksNum then
        buffer << ","
      end
      
    end
    buffer << "]" unless landmarksNum == 0
    # End

    # Includes the context index in context data as node attributes
    
    #limit = 5

    entries = idx.entries

    #if selected and limit
    #  lbound = selected - limit
    #  ubound = selected + limit 
    #  if lbound < 0
    #    ubound -= lbound
    #    lbound = 0
    #  elsif ubound > entries.length-1
    #    lbound -= (ubound - entries.length-1)
    #    ubound = entries.length-1
    #  end
    #  lbound = 0 if lbound < 0
    #  ubound = entries.length-1 if ubound > entries.length-1
    #else
    #  lbound = 0
    #  ubound = entries.length-1
    #end

    buffer << ",\"swui:contextIdx\":["

    #s = 0
    #lengthEntriesHash = entries[lbound..ubound].length
    #for entry in entries[lbound..ubound]
    #  s = s +1
    #  value = ""
    #  buffer << "{"
    #
    #  buffer << indexAttr(entry, params["p"], "swui:idxEntry", 20, entry != entries[selected])
    #  
    #  buffer << "}"
    #  if s < lengthEntriesHash
    #    buffer << ","
    #  end
    #end

    previous_node_entry = nil
    next_node_entry = nil
    buffer <<  entries.map{ |entry|

      if entry.uri == node.uri
        current_node_entry = entry
        current_index = entries.index(current_node_entry)
        previous_node_entry = entries[current_index - 1] if current_index > 0
        next_node_entry = entries[current_index + 1] if current_index < entries.size
      end

      "{" + indexAttr(entry, "swui:idxEntry", nil, entry.uri != node.uri ) + "}"
    }.join(',')
    
    buffer << "]"

    # End

    buffer << ",#{indexAttr(previous_node_entry, "swui:contextPrev")}" unless previous_node_entry.nil?
    buffer << ",#{indexAttr(next_node_entry, "swui:contextNext")}" unless next_node_entry.nil?
    
    # Includes the context navigation in context data as node attributes
    #unless selected.nil?
    #  entry = entries[selected-1]
    #  buffer << ",#{indexAttr(entry, params["p"], "swui:contextPrev", 15)}" unless entry.nil? || ((selected-1)<0)
    #  entry = entries[selected+1]
    #  buffer << ",#{indexAttr(entry, params["p"], "swui:contextNext", 15)}" unless entry.nil? || ((selected+1)==entries.length)
    #end
    # End

    buffer << "}"
    
    buffer << "]}"
    return buffer
  end
  
  # Presents index data in JSON format 
  def formatJSONIndexData(entries, landmarks)
    
    buffer = "{\"nodes\":["
    j = 0
    lengthEntriesHash = entries.length
    for entry in entries
      j = j +1
      id = entry.uri 
      buffer << "{\"swui:id\":\"#{id}\","

      buffer << indexAttr(entry)

      buffer << "}"
      if j < lengthEntriesHash
        buffer << ","
      end
    end
    
    buffer << "{}" if lengthEntriesHash == 0 # there was no entry in the index, so we forge an object here
    
    # Includes application landmarks in index data as index entries
    landmarks.each do
      |landmark|

      buffer << ","
      
      buffer << "{"
      buffer << landmarksAttr(landmark)
      buffer << "}"

    end
    
    buffer << "]}"
    return buffer
  end

  def truncate (string, truncate_by = 20)
    if string.length >= truncate_by
      shortened = string[0, truncate_by]
      shortened + "..."
    else 
      string
    end
  end

  def indexAttr(entry, label=nil, truncate_by=nil, link=true)
    label = "#{label}|" unless label.nil?
    buffer = ""
    t = 0
    lengthIdxAttrHash = entry.attributes_hash.length
    for key, attr in entry.attributes_hash
      t = t + 1
      key = attr.navigation_attribute.navigation_attribute_name.first
      puts "BBBBBBBBBBBBBBBBBBBBBBBBBBBBB"
      value = CGI::escapeHTML(attr.label.to_s)
      puts value
      value = truncate(value, truncate_by) unless truncate_by.nil?
      buffer << "\"#{label}#{key}\":"
      buffer << value.gsub('\\', '\\\\').gsub('"', '\"').to_json

      action = action_for_index_entry_attribute(attr)
      if action
        unless !link
          buffer << ",\"#{label}#{key}|swui:target\""
          buffer <<":\"#{attr.target_url}\""
        end
      end
      if t < lengthIdxAttrHash
        buffer << ","
      end
    end
    buffer
  end

  def landmarksAttr(landmark, tag=nil)
      tag = "#{tag}|" unless tag.nil?
      buffer = ""
      attributes = landmark.attributes
      label = landmark.label rescue landmark.landmark_name.first
      2.times { label.sub!("\"","") }
      2.times { label.sub!("'","") }
      buffer << "\"#{tag}swui:landmark\":\"#{label}\""
      buffer << ",\"swui:id\":\"#{attributes["id"]}\"" unless !tag.nil?
      buffer << ",\"#{tag}swui:landmark|swui:target\":\"#{landmark.target_url}\""
      buffer
  end
  
  #### to refactor

  def params_for_anchor(*params)
    ret = []
    params.each { |p| ret << p if p } if params
    ret.length == 0 ? nil : ret.join(',')   # { :p => ret.length == 0 ? nil : ret.join(',') } - original
  end

  def action_for_index_entry_attribute(attr) # from navigation_helper.rb
    case attr
    when ContextAnchorNodeAttribute
      "context"
    when IndexAnchorNodeAttribute
      "show_index"
    else
      nil
    end
  end
  
  def set_app_context
    AppContext.current.params = (p = @params[:p]) ? p.split(",") : []
    AppContext.current.context = @context #navigational context
    AppContext.current.index = @index
    AppContext.current.landmarks = @landmarks
    AppContext.current.view = @interface
    AppContext.current.user = @user
  end

  ##### to refactor
  
  def hyperDEPushResponse(transactionId, data)
    newResponse  = HyperDEResponse.new
    newResponse.response = data
    newResponse.save
    transaction = HyperDETransaction.find(transactionId) rescue nil
    
    unless transaction.nil?
          queueTail = transaction.queue_tail
          unless queueTail.empty?
              link = IsAfter.new
              link.node_id = newResponse.id
              link.target_node_id = queueTail.first.id
              link.save
              # isBefore is an inverted link - automatically created
          end
            
          if (transaction.queue_head.empty?)
              link = QueueHead.new
              link.node_id = transaction.id
              link.target_node_id = newResponse.id
              link.save
          end
            
          oldTail = QueueTail.find_by_node_id(transaction.id)
          NodeLink.destroy oldTail.id unless oldTail.nil?
          link = QueueTail.new
          link.node_id = transaction.id
          link.target_node_id = newResponse.id
          link.save
    end
  end

  def fileSystemPushResponse(seq, transactionId, data)
      FileAccessUtils.writeFileContent("#{@@tmpdir+transactionId}-#{seq}",data)
      FileAccessUtils.writeFileContent("#{@@tmpdir+transactionId}-0",(seq+1).to_s)   # saves the next position in the queue
  end

  def get_interface_spec(interface_name)
    interface = SWUI::Interface.find_by.swui::interface_name(interface_name).execute.first
    unless interface.nil?
      interface.swui::abstract_spec.first
    else
      "The interface '#{interface_name}' was not found."
    end
  end
  
  def render_interface(interface_name)
    spec = get_interface_spec(interface_name)
    render_to_string :inline => spec
  end
  
end
