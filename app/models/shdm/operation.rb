SHDM::Operation
SHDM::OperationParameter
SHDM::Condition
SHDM::PreCondition
SHDM::PostCondition

class SHDM::Operation
  
  silence_warnings do
    Errors = {
      :operation_exception            => {:error => "The operation's code is not valid"},
      :pre_condition_default_failure  => {:error => "The precondition has failed"},
      :pre_condition_exception        => {:error => "The precondition's expression is not valid"},    
      :post_condition_default_failure => {:error => "The postcondition has failed"},
      :post_condition_exception       => {:error => "The postcondition's expression is not valid"},
    }
  end

  property SHDM::operation_name, 'rdfs:subPropertyOf' => RDFS::label
  property SHDM::operation_code
  property SHDM::operation_language
  property SHDM::operation_type
  
  property SHDM::operation_pre_conditions, 'rdfs:range' => SHDM::PreCondition, "owl:inverseOf" => SHDM::pre_condition_operation
  property SHDM::operation_post_conditions, 'rdfs:range' => SHDM::PostCondition, "owl:inverseOf" => SHDM::post_condition_operation
  property SHDM::operation_parameters, 'rdfs:range' => SHDM::OperationParameter, "owl:inverseOf" => SHDM::parameter_operation
    
  @@operation_types = [["Internal", "internal"], ["External", "external"]]  
  cattr_accessor :operation_types

  before_update_attributes  :remove_external_operation
  before_destroy            :remove_external_operation
  after_update_attributes   :add_external_operation
  after_create              :add_external_operation

  def execute(options = {})
    
    for param in operation_parameters do
      # a parameter must follow the operation_parameter_data_type
      __value = options[param.operation_parameter_name.first.to_sym]
      unless (__value.is_a?param.operation_parameter_data_type.first.constantize)
        return { :error => "The '#{param.operation_parameter_name.first}' parameter type mismatch. It should be #{param.operation_parameter_data_type.first}, but got #{__value.class}." }
      end
      eval "#{param.operation_parameter_name.first} = __value"
    end
    
    for pre in operation_pre_conditions do 
      unless pre.pre_condition_expression.first.blank? 
        begin
          unless eval(pre.pre_condition_expression.first)
            return pre.pre_condition_failure_handling.first.blank? ? Errors[:pre_condition_default_failure] : eval(pre.pre_condition_failure_handling.first)
          end
        rescue SyntaxError => ex    
          return Errors[:pre_condition_exception][:error] << "(#{operation_name}): " + ex.message + "<br/>" + ex.backtrace.join("<br/>")
        rescue
          return Errors[:pre_condition_exception][:error] << "(#{operation_name}): " + ex.message + "<br/>" + ex.backtrace.join("<br/>")
        end        
      end
    end
    
    begin
      result = eval(operation_code.first)
    rescue SyntaxError => ex
      return Errors[:operation_exception][:error] << "(#{operation_name}): " + ex.message + "<br/>" + ex.backtrace.join("<br/>")
      return Errors[:operation_exception][:error] << "(#{operation_name}): " + ex.message + "<br/>" + ex.backtrace.join("<br/>")
    end 
    
    for post in operation_post_conditions do 
      unless post.post_condition_expression.first.blank? 
        begin
          return Errors[:post_condition_default_failure] unless eval(post.post_condition_expression.first)
        rescue SyntaxError => ex            
          return Errors[:post_condition_exception][:error] << "(#{operation_name}): " + ex.message + "<br/>" + ex.backtrace.join("<br/>")
        rescue            
          return Errors[:post_condition_exception][:error] << "(#{operation_name}): " + ex.message + "<br/>" + ex.backtrace.join("<br/>")
        end        
      end
    end
    
    return result
    
  end

  def self.external_operations
    SHDM::Operation.find_by.operation_type('external').execute
  end

  def self.load_external_operations
    for operation in SHDM::Operation.external_operations do
      operation.add_external_operation
    end
  end

  protected
  
  def add_external_operation
    Operations.__add_external_operation(operation_name.first, self) if operation_type.first == 'external'
  end
  
  def remove_external_operation
    Operations.__remove_external_operation(operation_name.first) if Operations.instance_methods.include?operation_name.first
  end    
  
  before_destroy :remove_dependents
  
  protected
  
  def remove_dependents
    self.operation_pre_conditions.each{|opc| opc.destroy}
    self.operation_post_conditions.each{|opc| opc.destroy}
    self.operation_parameters.each{|op| op.destroy}
  end
  
end

class SHDM::OperationParameter
    
  property SHDM::operation_parameter_name, 'rdfs:subPropertyOf' => RDFS::label
  property SHDM::operation_parameter_data_type
  #property SHDM::operation_parameter_type_attr
    
  @@data_types = ["String", "Integer", "Float", "DateTime", "Hash", "Array", "List"]  
  cattr_accessor :data_types 
      
  #validates_format_of :operation_parameter_name, :with => /^[a-z][A-Za-z0-9_]*$/, 
  #:message => 'Parameter in name must start with a lowercase letter and must only
  #             contain letters, digits and underscore characters'
  #             
  #def validate
  #  errors.add "operation_id", "Operation for parameter must be defined" if operation_id == 0
  #  errors.add("operation_parameter_name", "This name has been taken.") if !SHDM::OperationParameter.find_by.operation_parameter_name(name).empty? and SHDM::OperationParameter.find_by.operation_parameter_name(name) != self 
  #end
end

class SHDM::PreCondition
  
  property SHDM::pre_condition_name, 'rdfs:subPropertyOf' => RDFS::label
  property SHDM::pre_condition_expression
  property SHDM::pre_condition_failure_handling

  def validate
    errors.add "operation_id", "Operation for parameter in must be defined" if operation_id == 0
  end
    
  validates_format_of :condition_name, :with => /^[a-z][A-Za-z0-9_]*$/, 
  :message => 'Pre-condition name must start with a lowercase letter and must only
               contain letters, digits and underscore characters'
               
end

class SHDM::PostCondition
  
  property SHDM::post_condition_name, 'rdfs:subPropertyOf' => RDFS::label
  property SHDM::post_condition_expression

  def validate
    errors.add "operation_id", "Operation for parameter in must be defined" if operation_id == 0
  end
      
  validates_format_of :condition_name, :with => /^[a-z][A-Za-z0-9_]*$/, 
  :message => 'Pos-condition name must start with a lowercase letter and must only
               contain letters, digits and underscore characters'

end

module Operations
  
  def self.method_missing(operation_name, options = {})
    operation = SHDM::Operation.find_by.operation_name(operation_name.to_s).execute.first
    unless operation.nil?
      operation.execute(options)
    else
      raise NoMethodError, "There is no '#{operation_name}' operation"
    end
  end
  
  def self.__add_external_operation(operation_name, operation)
    define_method(operation_name.to_sym, lambda { 
      
      for pre in operation.operation_pre_conditions do 
        unless pre.pre_condition_expression.first.blank? 
          begin
            unless eval(pre.pre_condition_expression.first)
              if pre.pre_condition_failure_handling.first.blank?
                render :text => SHDM::Operation::Errors[:pre_condition_default_failure][:error] + " (#{operation_name}): " + ex.message + "<br/>" + ex.backtrace.join("<br/>")
                return
              else 
                eval(pre.pre_condition_failure_handling.first)
                return             
              end                
            end
          rescue SyntaxError => ex    
            render :text => SHDM::Operation::Errors[:pre_condition_exception][:error] + "(#{operation_name}): " + ex.message + "<br/>" + ex.backtrace.join("<br/>")
            return
          rescue => ex
            render :text => SHDM::Operation::Errors[:pre_condition_exception][:error] + "(#{operation_name}): " + ex.message + "<br/>" + ex.backtrace.join("<br/>")
            return
          end        
        end
      end
      
      begin
        eval operation.operation_code.first 
      rescue SyntaxError => ex
        render :text => SHDM::Operation::Errors[:operation_exception][:error] + "(#{operation_name}): " + ex.message + "<br/>" + ex.backtrace.join("<br/>")
      rescue => ex
        render :text => SHDM::Operation::Errors[:operation_exception][:error] + "(#{operation_name}): " + ex.message + "<br/>" + ex.backtrace.join("<br/>")
      end
    })    
  end
    
  def self.__remove_external_operation(operation_name)
    remove_method(operation_name.to_sym)
  end

end
