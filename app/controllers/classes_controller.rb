class ClassesController < ResourcesController
  def index
    show
  end
  
  def show
    @domain_classes = RDFS::Class.domain_classes.sort{|a,b| a.compact_uri <=> b.compact_uri }
    @meta_classes   = RDFS::Class.meta_classes.sort{|a,b| a.compact_uri <=> b.compact_uri }
    @resource       = params[:id].nil? ? ( @domain_classes.first.nil? ? @meta_classes.first : @domain_classes.first ): RDFS::Resource.find(params[:id])
    render :template => 'resources/show'
  end
end