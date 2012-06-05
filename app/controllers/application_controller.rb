# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  before_filter :redefine_params 
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  def index
    render :template => 'welcome'
  end
  def children_attributes(id, children_attribute)
    attrs = RDFS::Resource.find(id).send(children_attribute)
    elements = []
    attrs.each{ |attr| 
      elements << attr.attributes
    }
    return elements
  end
  def jqgrid_children_index(children_attribute, attributes)
     if params[:id].present?
       children = RDFS::Resource.find(params[:id]).send(children_attribute).to_a
       total_entries = children.size
     else
       children = []
       total_entries = 0
     end
     new_children = Array.new
    
     children.each do |child|
        child_c = child.clone
        child_c.class.send :attr_accessor, :new_id
        child_c.new_id = child_c.id
        def child_c.id
          self.new_id.to_s.gsub(/[#:\/]/,"_")
        end
        new_children << child_c
     end
     render :text => new_children.to_jqgrid_json(attributes, 1, total_entries + 1, total_entries).gsub("\n", "\\n")
   end
   
   
   def jqgrid_children_post_data(children_class, children_attribute=nil)
       id                 = params.delete(:id)
       oper               = params.delete(:oper)
       parent             = params.delete(:parent) || params.delete(:parent_id).gsub("http___base_","http://base#")
       children_attribute = children_attribute || ActiveRDF::Namespace.localname(children_class).underscore.pluralize

       params.delete(:controller)
       params.delete(:action)

       #converts HashWithIndifferentAccess params to a ordinary Hash. It makes merge work.
       values = params.to_hash  
       values.merge!(values){|k,v| if v.is_a?(String); CGI::unescape(v) else v end }
       values.merge!(values){|k,v| if v.is_a?(String) && v.match(/http:\/\/.+/)
                                      r = RDFS::Resource.find(v)
                                      r.nil? ? v : r
                                   else
                                     v
                                   end                                  
                                   }

       if oper == "del" or oper == "Delete"
         children_class.find(id).destroy
       else      
         if id == "_empty" or id.empty?
				   parent_resource = RDFS::Resource.find(parent)
           if parent_resource.is_a?(SHDM::Index) || parent_resource.is_a?(SHDM::InContextClass)
             values[:navigation_attribute_parent] = parent_resource
           end
           parent_resource.send(children_attribute) << children_class.create(values)
         else
					 children_class.find(id).update_attributes(values)
         end
       end
       render :nothing => true
   end
   
   private
  
   def redefine_params
     params[:id] = params[:id].gsub("http___base_","http://base#") if params[:id]
     params[:parent_id] = params[:parent_id].gsub("http___base_","http://base#") if params[:parent_id]
     params[:parent] = params[:parent].gsub("http___base_","http://base#") if params[:parent]
   end
end
