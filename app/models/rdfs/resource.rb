require 'uuidtools'

ActiveRDF::Namespace.register :base, 'http://base#'
ActiveRDF::Namespace.register :shdm, 'http://shdm#'
ActiveRDF::Namespace.register :swui, 'http://swui#'

module RDFSClass
  
  def self.append_features(base)
    base.extend(ClassMethods)
    base.class_eval { @accessors = {} }
    super
  end

  module ClassMethods
    
    #TODO: handle composition of symbols, parameters and blocks
    def ClassMethods.create_callback(name)
      define_method name.to_sym, lambda { |*args, &block|
        method = args.first
      
        if method.is_a?Symbol
          define_method name.to_sym, lambda { send(method) }
        elsif block.is_a?Proc
          define_method name.to_sym, &block
        end
      }
    end
  
    def property(resource, options = {})      
      property = resource
      unless resource.rdfs::domain.include?(self)
        property_name = ActiveRDF::Namespace.localname(resource)
    
        property               = RDF::Property.create(resource, options)
        property.rdfs::domain << self
        property.rdfs::label  << property_name if property.rdfs::label.empty?
      end 
      property
    end

    def create(resource=nil, options={})
    
      if resource.is_a? Hash
        options = resource
        resource = self.new(ActiveRDF::Namespace.lookup(:base, UUIDTools::UUID.timestamp_create.to_s))
      else
        resource = self.new(resource)      
      end
    
      #before callback
      resource.before_create
                  
      options.each_pair {|property_name, value|
        property_name = property_name.to_s
        match = property_name.match(/^([a-z]+)::?(.+)/) #checking if the property is composed by a namespace
      
        if match
          property = resource.send(match[1]).send(match[2])          
        else
          property = resource.send(property_name)
        end
        
        unless property.nil?
          property << value
        else
          resource.send("#{property_name}=", value)
        end
        
        #property << (property.range.first.respond_to?(:new) ? property.range.first.new(value) : value) #creates a rdfs:resource based on property's range using the value as attribute for new
        
      }
      
      #after callback
      resource.after_create
      
      resource
    end
        
    def sub_class_of(rdfs_class)
      #unless self.rdfs::subClassOf.nil?
      #  self.rdfs::subClassOf << rdfs_class
      #else
      #  self.rdfs::subClassOf = rdfs_class
      #end
    end    

    def before_add_property(property, &block)
      define_method "before_add_property_#{property.to_s}".to_sym, &block
    end
    
    def after_add_property(property, &block)
      define_method "after_add_property_#{property.to_s}".to_sym, &block
    end
    
    def before_delete_property(property, &block)
      define_method "before_delete_property_#{property.to_s}".to_sym, &block
    end
    
    def after_delete_property(property, &block)
      define_method "after_delete_property_#{property.to_s}".to_sym, &block
    end
    
    ClassMethods.create_callback(:before_update_attributes)
    ClassMethods.create_callback(:after_update_attributes)
    ClassMethods.create_callback(:before_create)
    ClassMethods.create_callback(:after_create)
    ClassMethods.create_callback(:before_destroy)
    ClassMethods.create_callback(:after_destroy)
        
  end  
  
end

class RDFS::Resource
  include RDFSClass
  
  attr_reader :datasets
  
  def self.subclasses
    subclasses = ActiveRDF::Query.new.distinct(:s).where(:s, RDFS::subClassOf, self).execute.to_a
    subclasses.delete(self)
    subclasses.collect{|type_res| ActiveRDF::ObjectManager.construct_class(type_res)}
  end  
  
  
  def update_attributes(options)
    
    #before callback
    before_update_attributes
    
    options.each_pair {|property_name, value|
      property_name = property_name.to_s
      match = property_name.match(/^([a-z]+)::?(.+)/) #checking if the property is composed by a namespace
  
      if match
        property = self.send(match[1]).send(match[2])          
      else
        property = self.send(property_name)
      end
            
      #creates a rdfs:resource based on property's range using the value as attribute for new. 
      #It's not completely right, because it's using the first class from range. Needs a better heuristics.
      property.replace( (property.range.first.respond_to?(:new) ? property.range.first.new(value) : value) ) unless property == value
    }
    
    #after callback
    after_update_attributes
    
    self
  end
  
  def compact_uri
    ActiveRDF::Namespace.prefix(uri) ? "#{ActiveRDF::Namespace.prefix(uri)}:#{ActiveRDF::Namespace.localname(uri)}" : uri
  end
  
  def errors
    @errors ||= Errors.new(self.classes.first)
  end
  
  def id
    uri
  end
  
  def destroy
    #before callback
    before_destroy
    ActiveRDF::FederationManager.delete(:s, :p, self)
    ActiveRDF::FederationManager.delete(self, :p)
    #after callback
    after_destroy
  end
  
  def attributes
    attributes = {}
    for attribute in self.direct_predicates.map {|v| v.label ? v.label.first : nil }.compact do
      attributes[attribute] = self.send(attribute).first
    end
    attributes['id'] = id
    attributes
  end
  
end


class Error
  attr_accessor :base, :attribute, :type, :message, :options

  def initialize(base, attribute, type = nil, options = {})
    self.base      = base
    self.attribute = attribute
    self.type      = type || :invalid
    self.options   = options
    self.message   = options.delete(:message) || self.type
  end

  def message
    generate_message(@message, options.dup)
  end

  def full_message
    attribute.to_s == 'base' ? message : generate_full_message(message, options.dup)
  end

  alias :to_s :message

  def value
    @base.respond_to?(attribute) ? @base.send(attribute) : nil
  end

  protected

    # Translates an error message in it's default scope (<tt>activerecord.errrors.messages</tt>).
    # Error messages are first looked up in <tt>models.MODEL.attributes.ATTRIBUTE.MESSAGE</tt>, if it's not there,
    # it's looked up in <tt>models.MODEL.MESSAGE</tt> and if that is not there it returns the translation of the
    # default message (e.g. <tt>activerecord.errors.messages.MESSAGE</tt>). The translated model name,
    # translated attribute name and the value are available for interpolation.
    #
    # When using inheritence in your models, it will check all the inherited models too, but only if the model itself
    # hasn't been found. Say you have <tt>class Admin < User; end</tt> and you wanted the translation for the <tt>:blank</tt>
    # error +message+ for the <tt>title</tt> +attribute+, it looks for these translations:
    #
    # <ol>
    # <li><tt>activerecord.errors.models.admin.attributes.title.blank</tt></li>
    # <li><tt>activerecord.errors.models.admin.blank</tt></li>
    # <li><tt>activerecord.errors.models.user.attributes.title.blank</tt></li>
    # <li><tt>activerecord.errors.models.user.blank</tt></li>
    # <li><tt>activerecord.errors.messages.blank</tt></li>
    # <li>any default you provided through the +options+ hash (in the activerecord.errors scope)</li>
    # </ol>
    def generate_message(message, options = {})
      keys = @base.class.self_and_descendants_from_active_record.map do |klass|
        [ :"models.#{klass.name.underscore}.attributes.#{attribute}.#{message}",
          :"models.#{klass.name.underscore}.#{message}" ]
      end.flatten

      keys << options.delete(:default)
      keys << :"messages.#{message}"
      keys << message if message.is_a?(String)
      keys << @type unless @type == message
      keys.compact!

      options.reverse_merge! :default => keys,
                             :scope => [:activerecord, :errors],
                             :model => @base.class.human_name,
                             :attribute => @base.class.human_attribute_name(attribute.to_s),
                             :value => value

      I18n.translate(keys.shift, options)
    end

    # Wraps an error message into a full_message format.
    #
    # The default full_message format for any locale is <tt>"{{attribute}} {{message}}"</tt>.
    # One can specify locale specific default full_message format by storing it as a
    # translation for the key <tt>:"activerecord.errors.full_messages.format"</tt>.
    #
    # Additionally one can specify a validation specific error message format by
    # storing a translation for <tt>:"activerecord.errors.full_messages.[message_key]"</tt>.
    # E.g. the full_message format for any validation that uses :blank as a message
    # key (such as validates_presence_of) can be stored to <tt>:"activerecord.errors.full_messages.blank".</tt>
    #
    # Because the message key used by a validation can be overwritten on the
    # <tt>validates_*</tt> class macro level one can customize the full_message format for
    # any particular validation:
    #
    #   # app/models/article.rb
    #   class Article < ActiveRecord::Base
    #     validates_presence_of :title, :message => :"title.blank"
    #   end
    #
    #   # config/locales/en.yml
    #   en:
    #     activerecord:
    #       errors:
    #         full_messages:
    #           title:
    #             blank: This title is screwed!
    def generate_full_message(message, options = {})
      options.reverse_merge! :message => self.message,
                             :model => @base.class.human_name,
                             :attribute => @base.class.human_attribute_name(attribute.to_s),
                             :value => value

      key = :"full_messages.#{@message}"
      defaults = [:'full_messages.format', '{{attribute}} {{message}}']

      I18n.t(key, options.merge(:default => defaults, :scope => [:activerecord, :errors]))
    end
end

# Active Record validation is reported to and from this object, which is used by Base#save to
# determine whether the object is in a valid state to be saved. See usage example in Validations.
class Errors
  include Enumerable

  class << self
    def default_error_messages
      ActiveSupport::Deprecation.warn("ActiveRecord::Errors.default_error_messages has been deprecated. Please use I18n.translate('activerecord.errors.messages').")
      I18n.translate 'activerecord.errors.messages'
    end
  end

  def initialize(base) # :nodoc:
    @base, @errors = base, {}
  end

  # Adds an error to the base object instead of any particular attribute. This is used
  # to report errors that don't tie to any specific attribute, but rather to the object
  # as a whole. These error messages don't get prepended with any field name when iterating
  # with +each_full+, so they should be complete sentences.
  def add_to_base(msg)
    add(:base, msg)
  end

  # Adds an error message (+messsage+) to the +attribute+, which will be returned on a call to <tt>on(attribute)</tt>
  # for the same attribute and ensure that this error object returns false when asked if <tt>empty?</tt>. More than one
  # error can be added to the same +attribute+ in which case an array will be returned on a call to <tt>on(attribute)</tt>.
  # If no +messsage+ is supplied, :invalid is assumed.
  # If +message+ is a Symbol, it will be translated, using the appropriate scope (see translate_error).
  # def add(attribute, message = nil, options = {})
  #   message ||= :invalid
  #   message = generate_message(attribute, message, options)) if message.is_a?(Symbol)
  #   @errors[attribute.to_s] ||= []
  #   @errors[attribute.to_s] << message
  # end

  def add(error_or_attr, message = nil, options = {})
    error, attribute = error_or_attr.is_a?(Error) ? [error_or_attr, error_or_attr.attribute] : [nil, error_or_attr]
    options[:message] = options.delete(:default) if options.has_key?(:default)

    @errors[attribute.to_s] ||= []
    @errors[attribute.to_s] << (error || Error.new(@base, attribute, message, options))
  end

  # Will add an error message to each of the attributes in +attributes+ that is empty.
  def add_on_empty(attributes, custom_message = nil)
    for attr in [attributes].flatten
      value = @base.respond_to?(attr.to_s) ? @base.send(attr.to_s) : @base[attr.to_s]
      is_empty = value.respond_to?(:empty?) ? value.empty? : false
      add(attr, :empty, :default => custom_message) unless !value.nil? && !is_empty
    end
  end

  # Will add an error message to each of the attributes in +attributes+ that is blank (using Object#blank?).
  def add_on_blank(attributes, custom_message = nil)
    for attr in [attributes].flatten
      value = @base.respond_to?(attr.to_s) ? @base.send(attr.to_s) : @base[attr.to_s]
      add(attr, :blank, :default => custom_message) if value.blank?
    end
  end

  # Returns true if the specified +attribute+ has errors associated with it.
  #
  #   class Company < ActiveRecord::Base
  #     validates_presence_of :name, :address, :email
  #     validates_length_of :name, :in => 5..30
  #   end
  #
  #   company = Company.create(:address => '123 First St.')
  #   company.errors.invalid?(:name)      # => true
  #   company.errors.invalid?(:address)   # => false
  def invalid?(attribute)
    !@errors[attribute.to_s].nil?
  end

  # Returns +nil+, if no errors are associated with the specified +attribute+.
  # Returns the error message, if one error is associated with the specified +attribute+.
  # Returns an array of error messages, if more than one error is associated with the specified +attribute+.
  #
  #   class Company < ActiveRecord::Base
  #     validates_presence_of :name, :address, :email
  #     validates_length_of :name, :in => 5..30
  #   end
  #
  #   company = Company.create(:address => '123 First St.')
  #   company.errors.on(:name)      # => ["is too short (minimum is 5 characters)", "can't be blank"]
  #   company.errors.on(:email)     # => "can't be blank"
  #   company.errors.on(:address)   # => nil
  def on(attribute)
    attribute = attribute.to_s
    return nil unless @errors.has_key?(attribute)
    errors = @errors[attribute].map(&:to_s)
    errors.size == 1 ? errors.first : errors
  end

  alias :[] :on

  # Returns errors assigned to the base object through +add_to_base+ according to the normal rules of <tt>on(attribute)</tt>.
  def on_base
    on(:base)
  end

  # Yields each attribute and associated message per error added.
  #
  #   class Company < ActiveRecord::Base
  #     validates_presence_of :name, :address, :email
  #     validates_length_of :name, :in => 5..30
  #   end
  #
  #   company = Company.create(:address => '123 First St.')
  #   company.errors.each{|attr,msg| puts "#{attr} - #{msg}" }
  #   # => name - is too short (minimum is 5 characters)
  #   #    name - can't be blank
  #   #    address - can't be blank
  def each
    @errors.each_key { |attr| @errors[attr].each { |error| yield attr, error.message } }
  end

  def each_error
    @errors.each_key { |attr| @errors[attr].each { |error| yield attr, error } }
  end

  # Yields each full error message added. So <tt>Person.errors.add("first_name", "can't be empty")</tt> will be returned
  # through iteration as "First name can't be empty".
  #
  #   class Company < ActiveRecord::Base
  #     validates_presence_of :name, :address, :email
  #     validates_length_of :name, :in => 5..30
  #   end
  #
  #   company = Company.create(:address => '123 First St.')
  #   company.errors.each_full{|msg| puts msg }
  #   # => Name is too short (minimum is 5 characters)
  #   #    Name can't be blank
  #   #    Address can't be blank
  def each_full
    full_messages.each { |msg| yield msg }
  end

  # Returns all the full error messages in an array.
  #
  #   class Company < ActiveRecord::Base
  #     validates_presence_of :name, :address, :email
  #     validates_length_of :name, :in => 5..30
  #   end
  #
  #   company = Company.create(:address => '123 First St.')
  #   company.errors.full_messages # =>
  #     ["Name is too short (minimum is 5 characters)", "Name can't be blank", "Address can't be blank"]
  def full_messages(options = {})
    @errors.values.inject([]) do |full_messages, errors|
      full_messages + errors.map { |error| error.full_message }
    end
  end

  # Returns true if no errors have been added.
  def empty?
    @errors.empty?
  end

  # Removes all errors that have been added.
  def clear
    @errors = {}
  end

  # Returns the total number of errors added. Two errors added to the same attribute will be counted as such.
  def size
    @errors.values.inject(0) { |error_count, attribute| error_count + attribute.size }
  end

  alias_method :count, :size
  alias_method :length, :size

  # Returns an XML representation of this error object.
  #
  #   class Company < ActiveRecord::Base
  #     validates_presence_of :name, :address, :email
  #     validates_length_of :name, :in => 5..30
  #   end
  #
  #   company = Company.create(:address => '123 First St.')
  #   company.errors.to_xml
  #   # =>  <?xml version="1.0" encoding="UTF-8"?>
  #   #     <errors>
  #   #       <error>Name is too short (minimum is 5 characters)</error>
  #   #       <error>Name can't be blank</error>
  #   #       <error>Address can't be blank</error>
  #   #     </errors>
  def to_xml(options={})
    options[:root] ||= "errors"
    options[:indent] ||= 2
    options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])

    options[:builder].instruct! unless options.delete(:skip_instruct)
    options[:builder].errors do |e|
      full_messages.each { |msg| e.error(msg) }
    end
  end

  def generate_message(attribute, message = :invalid, options = {})
    ActiveSupport::Deprecation.warn("ActiveRecord::Errors#generate_message has been deprecated. Please use ActiveRecord::Error#generate_message.")
    Error.new(@base, attribute, message, options).to_s
  end
end
