SHDM::Landmark

class SHDM::Landmark

  property SHDM::landmark_name, 'rdfs:subPropertyOf' => RDFS::label
  property SHDM::landmark_position
  property SHDM::landmark_navigation_attribute

  def attribute
    @attribute ||= NodeAttributeFactory.create(landmark_navigation_attribute.first, self)
  end
  
  def label
    attribute.label
  end
  
  def target_url
    attribute.target_url
  end
  
  def self.all
    SHDM::Landmark.alpha(SHDM::landmark_position)
  end
  
  before_destroy :remove_dependents
  
  protected
  
  def remove_dependents
    self.landmark_navigation_attribute.each{|na| ia.destroy}
  end
  
end