      # Author::    Andreia Luna (mailto: amluna@inf.puc-rio.br)
      # ---
      # This class parses a rhetorical description
      # and translates it into a JSON object.
      # ---

class RhetCompiler

  attr_reader :transitions, :events, :decorations, :effects
  
  def initialize
    @eventArray = Array.new
    @transitionArray = Array.new
    @rhetStructSeqArray = Array.new
    @rhetStructSetArray = Array.new
    @rhetoricalStructureArray = Array.new
    @decorationSeqArray = Array.new
    @decorationSetArray = Array.new
    @decorationArray = Array.new
  end
  
  def compile
      @decorHash = Hash.new
      @transHash = Hash.new
      @transitions = Hash.new
      @events = Hash.new
      @decorations = Hash.new
      @effects = Hash.new
      searchTransitions
      searchEvents
  end
  
  def event(*args)
    # Args: name, type, onInterface, onElement, hasRhetoricalStructures, fromAction = nil
    # Clear non-required hashes before setting them
    @fromAction = nil
    setArgs(args)
    type="event"
    @eventHash = Hash.new
    setHash(type, "name", @name)
    setHash(type, "concreteEvent", @concreteEvent) 
    setHash(type, "onInterface", @onInterface)
    setHash(type, "onElement", @onElement)
    setHash(type, "hasRhetoricalStructures", @hasRhetoricalStructures)
    setHash(type, "fromAction", @fromAction) unless @fromAction.nil?
    setHash(type, "targetComponent", @targetComponent) unless @targetComponent.nil?
    setHash(type, "targetInterface", @targetInterface) unless @targetInterface.nil?
    setHash(type, "transitionInterface", @transitionInterface) unless @transitionInterface.nil?
    @eventArray.push @eventHash

  end
  
  def  transition(*args)
    # Args: name, hasRhetoricalStructures, fromInterface=nil, toInterface=nil
    # Clear non-required hashes before setting them
    @fromInterface = nil
    @toInterface = nil
    setArgs(args)
    type="transition"
    @transitionHash = Hash.new
    setHash(type, "name", @name)
    setHash(type, "hasRhetoricalStructures", @hasRhetoricalStructures)
    setHash(type, "fromInterface", @fromInterface) unless @fromInterface.nil?
    setHash(type, "toInterface", @toInterface) unless @toInterface.nil?
    @transitionArray.push @transitionHash

  end
  
  def rhetStructSeq(*args)
    # Args: name, firstOfSeq, lastOfSeq=nil
    # Clear non-required hashes before setting them
    @lastOfSeq = nil
    setArgs(args)
    type="rhetStructSeq"
    @rhetStructSeqHash = Hash.new
    setHash(type, "name", @name)
    setHash(type, "firstOfSequence", @firstOfSeq)
    setHash(type, "lastOfSequence", @lastOfSeq) unless @lastOfSeq.nil?
    @rhetStructSeqArray.push @rhetStructSeqHash

  end
  
  def rhetStructSet(*args)
    # Args: name, hasRhetoricalStructures
    setArgs(args)
    type="rhetStructSet"
    @rhetStructSetHash = Hash.new
    setHash(type, "name", @name)
    setHash(type, "hasRhetoricalStructures", @hasRhetoricalStructures)
    @rhetStructSetArray.push @rhetStructSetHash

  end
  
  def rhetoricalStructure(*args)
    # Args: name, hasDecorations
    setArgs(args)
    type="rhetoricalStructure"
    @rhetoricalStructureHash = Hash.new
    setHash(type, "name", @name)
    setHash(type, "hasDecorations", @hasDecorations)
    @rhetoricalStructureArray.push @rhetoricalStructureHash

  end
  
  def decorationSeq(*args)
    # Args: name, firstOfSeq, lastOfSeq=nil
    # Clear non-required hashes before setting them
    @lastOfSeq = nil
    setArgs(args)
    type="decorationSeq"
    @decorationSeqHash = Hash.new
    setHash(type, "name", @name)
    setHash(type, "firstOfSequence", @firstOfSeq)
    setHash(type, "lastOfSequence", @lastOfSeq) unless @lastOfSeq.nil?
    @decorationSeqArray.push @decorationSeqHash

  end
  
  def decorationSet(*args)
    # Args: name, hasDecorations
    setArgs(args)
    type="decorationSet"
    @decorationSetHash = Hash.new
    setHash(type, "name", @name)
    setHash(type, "hasDecorations", @hasDecorations)
    @decorationSetArray.push @decorationSetHash
    
  end
  
  def decoration(*args)
    # Args: name, type, hasElement, effect=nil, parameters=nil
    setArgs(args)
    type="decoration"
    @decorationHash = Hash.new
    setHash(type, "name", @name)
    setHash(type, "type", @type)
    if @hasElement.include?(";") then
      setHash(type, "hasSourceElement", @hasElement.split(";").first) 
      setHash(type, "hasTargetElement", @hasElement.split(";").last)
    else
      setHash(type, "hasElement", @hasElement) 
    end
    setHash(type, "effect", @effect) 
    setHash(type, "parameters", @parameters) 
    @decorationArray.push @decorationHash
    
  end

  private
  
  def searchTransitions
    j = 1
    @transitionArray.each do
      |transitionHsh|
      transition = transitionHsh['name']
      from = ""
      to = ""
      from = transitionHsh['fromInterface'] unless transitionHsh['fromInterface'].nil?
      to = transitionHsh['toInterface'] unless transitionHsh['toInterface'].nil?
      if !@transHash.has_key?(transition) then
        @transHash[transition]=""
        @JSONentity = ""
        @JSONentity += "," unless j==1
        @JSONentity += "{"
        keys =  [ "transition", "from", "to" ]
        keys.each do |key| 
          @JSONentity += "\"#{key}\":\"#{eval(key)}\""
          @JSONentity += ","
        end
        interface = "#{from};#{to}"
        if (rhetStructType(transitionHsh['hasRhetoricalStructures']) == "RhetStructSet") then
          @JSONentity += "\"rhetStructsPll\":["
          searchRhetStructSet(transitionHsh['hasRhetoricalStructures'], interface)
          @JSONentity += "]"
        end
        if (rhetStructType(transitionHsh['hasRhetoricalStructures']) == "RhetStructSeq")  then
          @JSONentity += "\"rhetStructsOrd\":["
          searchRhetStructSeq(transitionHsh['hasRhetoricalStructures'], interface)
          @JSONentity += "]"
        end
        @JSONentity +="}"
        unless from.empty?
          if (!@transitions.has_key?(from))
              @transitions[from] = Array.new
          end
          # @transitions is an array
          @transitions[from].push(@JSONentity)    # adds an element to the last position in the array
        end
        unless to.empty?
          if (!@transitions.has_key?(to))
              @transitions[to] = Array.new
          end
          # @transitions is an array
          @transitions[to].push(@JSONentity)    # adds an element to the last position in the array
        end
      end
      j = j + 1
    end
  end
  
  def searchEvents
    i = 1
    @eventArray.each do
      |event|
      evtId = event['name']
      interface = event['onInterface']
      @JSONentity = ""
      #@JSONentity += "," unless i==1
      @JSONentity += "{"
      @JSONentity += "\"event\":\"#{event['concreteEvent']}\"" 
      @JSONentity += "," 
      @JSONentity += "\"widget\":\"#{event['onElement']}\""
      @JSONentity += "," 
      @JSONentity += "\"action\":\"#{event['fromAction']}\""
      @JSONentity += "," 
      @JSONentity += "\"target\":\"#{event['targetInterface']}\""
      @JSONentity += "," 
      @JSONentity += "\"transition\":\"#{event['transitionInterface']}\""
      @JSONentity += "," 
      @JSONentity += "\"rhetStruct\":"
      searchRhetStruct(event['hasRhetoricalStructures'], interface)
      @JSONentity +="}"
      if (!@events.has_key?(interface))
          @events[interface] = Array.new
      end
      # @events is an array
      @events[interface].push(@JSONentity)    # adds an element to the last position in the array
      i = i + 1
    end
    
  end
  
  def searchRhetStructSet(id, interface)
    @rhetStructSetArray.each do
      |rhetStructSet|
      name = rhetStructSet['name']
      if (name==id) then
        i=1
        rhetoricalStructures = rhetStructSet['hasRhetoricalStructures']
        rhetoricalStructures.split(";").each do
          |rhetStruct|
            @JSONentity += "," unless i==1
            if (rhetStructType(rhetStruct) == "RhetoricalStructure")  then
              searchRhetStruct(rhetStruct, interface)
            end
            if (rhetStructType(rhetStruct) == "RhetStructSet")  then
              @JSONentity +="{"
              @JSONentity += "\"rhetStructsPll\":["
              searchRhetStructSet(rhetStruct, interface)
              @JSONentity += "]"
              @JSONentity +="}"
            end
            if (rhetStructType(rhetStruct) == "RhetStructSeq")  then
              @JSONentity +="{"
              @JSONentity += "\"rhetStructsOrd\":["
              searchRhetStructSeq(rhetStruct, interface)
              @JSONentity += "]"
              @JSONentity +="}"
            end
            i=i+1;
        end
      end
    end
  end
  
  def searchRhetStructSeq(id, interface)
    @rhetStructSeqArray.each do
      |rhetStructSeq|
      name = rhetStructSeq['name']
      if (name == id) then
          firstId = rhetStructSeq['firstOfSequence']
          firstType = rhetStructType(rhetStructSeq['firstOfSequence'])
          lastId = rhetStructSeq['lastOfSequence'] unless rhetStructSeq['lastOfSequence'].nil?
          lastType = rhetStructType(rhetStructSeq['lastOfSequence']) unless rhetStructSeq['lastOfSequence'].nil?
          if (firstType == "RhetoricalStructure")  then
            searchRhetStruct(firstId, interface)
          end
          if (firstType == "RhetStructSet")  then
            @JSONentity +="{"
            @JSONentity += "\"rhetStructsPll\":["
            searchRhetStructSet(firstId, interface)
            @JSONentity += "]"
            @JSONentity +="}"
          end
          if (firstType == "RhetStructSeq")  then
              searchRhetStructSeq(firstId, interface)
          end

          if (!lastId.nil?) then
            @JSONentity += ","
            if (lastType == "RhetoricalStructure")  then
              searchRhetStruct(lastId, interface)
            end
            if (lastType == "RhetStructSet")  then
              @JSONentity +="{" 
              @JSONentity += "\"rhetStructsPll\":["
              searchRhetStructSet(lastId, interface)
              @JSONentity += "]"
              @JSONentity +="}" 
            end
            if (lastType == "RhetStructSeq")  then
              searchRhetStructSeq(lastId, interface)
            end
          end
      end
    end
  end
  
  def searchRhetStruct(id, interface)
    @rhetoricalStructureArray.each do
      |rhetStruct|
      name = rhetStruct['name']
      if (name == id) then
        @JSONentity +="{" 
        @JSONentity += "\"rhetStructId\":\"#{name}\""
        @JSONentity += "," 
        if (decorType(rhetStruct['hasDecorations']) == "DecorationSet")  then
          @JSONentity += "\"animationsPll\":["
          searchdecorSet(rhetStruct['hasDecorations'], interface)
          @JSONentity += "]"
        end
        if (decorType(rhetStruct['hasDecorations']) == "DecorationSeq")  then
          @JSONentity += "\"animationsSeq\":["
          searchdecorSeq(rhetStruct['hasDecorations'], interface)
          @JSONentity += "]"
        end
       @JSONentity +="}" 
      end
    end
  end
  
  def searchdecorSet(id, interface)
    @decorationSetArray.each do
      |decorSet|
      name = decorSet['name']
      if (name == id) then
        i=1
        decorations = decorSet['hasDecorations']
        decorations.split(";").each do
          |decor|
            @JSONentity += "," unless i==1
            if (decorType(decor) == "DecorationSet")  then
              @JSONentity +="{"
              @JSONentity += "\"animationsPll\":["
              searchdecorSet(decor, interface)
              @JSONentity += "]"
              @JSONentity +="}"
            elsif (decorType(decor) == "DecorationSeq")  then
              @JSONentity +="{"
              @JSONentity += "\"animationsSeq\":["
              searchdecorSeq(decor, interface)
              @JSONentity += "]"
              @JSONentity +="}"
            else 
              searchDecoration(decor,decorType(decor), interface)
            end
           i=i+1 
        end
      end
    end
  end
  
  def searchdecorSeq(id, interface)
    @decorationSeqArray.each do
      |decorSeq|
      name = decorSeq['name']
      if (name == id) then
          firstId = decorSeq['firstOfSequence']
          firstType = decorType(decorSeq['firstOfSequence'])
          lastId = decorSeq['lastOfSequence'] unless decorSeq['lastOfSequence'].nil?
          lastType = decorType(decorSeq['lastOfSequence']) unless decorSeq['lastOfSequence'].nil?
          if (firstType == "DecorationSet")  then
            @JSONentity +="{"
            @JSONentity += "\"animationsPll\":["
            searchdecorSet(firstId, interface)
            @JSONentity += "]"
            @JSONentity +="}"
          elsif (firstType == "DecorationSeq")  then
              searchdecorSeq(firstId, interface)
          else 
            searchDecoration(firstId,firstType, interface)
          end

          if (!lastId.nil?) then
            @JSONentity += ","
            if (lastType == "DecorationSet")  then
              @JSONentity +="{" 
              @JSONentity += "\"animationsPll\":["
              searchdecorSet(lastId, interface)
              @JSONentity += "]"
              @JSONentity +="}" 
            elsif (lastType == "DecorationSeq")  then
              searchdecorSeq(lastId, interface)
            else
              searchDecoration(lastId,lastType, interface)
            end
          end

      end
    end  
  end

  def searchDecoration(id, decorType, interface)
    @decorationArray.each do
      |decor|
      decoration = decor['name']
      if (decoration == id) then
        type = decorType.downcase
        type.gsub!(/element[s]*/,"")
        effect = decor['effect'] unless decor['effect'].nil?
        params = decor['parameters'] unless decor['parameters'].nil?
        params = params.nil? ? "" : params
        @JSONentity += "\"#{decoration}\""
        if !@decorHash.has_key?(decoration) then
          @decorHash[decoration]=""
          @JSONdecoration = ""
          case type
            when "match","trade"
              sourceWidget = decor['hasSourceElement']
              targetWidget = decor['hasTargetElement']
              searchDecoration2Widg(sourceWidget, targetWidget, decoration, type, effect, params)
            else
              widget=decor['hasElement']
              searchDecoration1Widg(widget, decoration, type, effect, params)
            end
          interface.each(";") do |interf| 
            if (!interf.eql?(";")) then
              if (!@decorations.has_key?(interf))
                  @decorations[interf] = Array.new
              end
              @decorations[interf].push(@JSONdecoration)    # adds an element to the last position in the array
              # saves the reference to the effect
              if (!@effects.has_key?(interf))
                  @effects[interf] = Array.new
              end
              @effects[interf].push(effect)    # adds an element to the last position in the array
            end
          end
        end
      end
    end
  end

  def searchDecoration1Widg(widget, decoration, type, effect, params)
      printDecorationAttr(decoration, type, effect, params)
      @JSONdecoration += "\"widget\": [\"#{widget}\"]}"
  end

  def searchDecoration2Widg(widget1, widget0, decoration, type, effect, params)
        printDecorationAttr(decoration, type, effect, params)
        @JSONdecoration += "\"widget\": [\"#{widget0}\",\"#{widget1}\"]}"
  end
  
  def printDecorationAttr(decoration, type, effect, params)
    @JSONdecoration += "{\"animation\":\"#{decoration}\","
    @JSONdecoration += "\"type\":\"#{type}\","
    @JSONdecoration += "\"effect\": {\"name\":\"#{effect}\", \"params\":\"#{params}\"},"
  end

  def rhetStructType(name)
    type="RhetoricalStructure"
    @rhetStructSeqArray.each do
      |rhetStruct|
      if (rhetStruct['name']==name)
        type = "RhetStructSeq"
      end
    end
    @rhetStructSetArray.each do
      |rhetStruct|
      if (rhetStruct['name']==name)
        type = "RhetStructSet"
      end
    end
    return type
  end
  
  def decorType(name)
    type=""
    @decorationSeqArray.each do
      |rhetStruct|
      if (rhetStruct['name']==name)
        type = "DecorationSeq"
      end
    end
    @decorationSetArray.each do
      |rhetStruct|
      if (rhetStruct['name']==name)
        type = "DecorationSet"
      end
    end
    if type.empty?
      @decorationArray.each do 
        |decor| 
        if (decor['name']==name)
          type = decor['type']
        end
      end
      
    end
    
    return type
  end
  
  def setArgs(args)
    args.each { |hash| hash.each { |key,value| eval("@#{key} = \"#{value}\"") } }
  end

  def setHash(name, key, value)
    eval("@#{name}Hash[\"#{key}\"]=\"#{value}\"")
  end
  
end

