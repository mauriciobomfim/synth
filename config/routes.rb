ActionController::Routing::Routes.draw do |map|

  map.resources :applications, :collection => { :shutdown => :get }
  map.resources :operations
  map.resources :contexts
  map.resources :indexes,   :collection => { 
                                           :navigation_attribute_index_parameters                 => :get, 
                                           :navigation_attribute_index_parameters_post_data       => :get,
                                           :navigation_attribute_context_parameters               => :get, 
                                           :navigation_attribute_context_parameters_post_data     => :get,
                                           :index_navigation_attribute_index_parameters           => :get,
                                           :index_navigation_attribute_index_parameters_post_data => :get                                           
                                         }


  map.resources :landmarks
  map.resources :operation_parameters
  map.resources :abstract_interfaces, :member => { :xslt => :get }, :collection => { :htmlTags => :get, :css => :get, :aixsl => :get }
  map.resources :effects
  map.resources :concrete_widgets
  map.resources :concrete_interfaces
  map.resources :in_context_classes, :collection => { 
                                                      :navigation_attribute_index_parameters                 => :get, 
                                                      :navigation_attribute_index_parameters_post_data       => :get,
                                                      :navigation_attribute_context_parameters               => :get,
                                                      :navigation_attribute_context_parameters_post_data     => :get,
                                                      :index_navigation_attribute_index_parameters           => :get,
                                                      :index_navigation_attribute_index_parameters_post_data => :get
                                        }
  map.resources :resources, :requirements => { :id => /.*/ }, :collection => { :search_property => :get , :search_class => :get, :search_resource => :get}
  map.resources :classes,   :requirements => { :id => /.*/ }
  map.resources :properties,:requirements => { :id => /.*/ }
  map.resources :datasets
  map.resources :ontologies, :member => { :activate_ontology => :post, :disable_ontology => :post}
  map.resources :namespaces
	
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "applications"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.connect 'home',       :controller => :applications
  map.connect 'domain',     :controller => :ontologies
  map.connect 'navigation', :controller => :contexts
  map.connect 'interface',  :controller => :abstract_interfaces
  map.connect 'behavior',   :controller => :operations
  
end
