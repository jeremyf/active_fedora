require 'spec_helper'

describe ActiveFedora::Associations::HasManyAssociation do
  it "should be able to replace the collection" do
    @owner = stub(:new_record? => false, :to_ary => nil, :internal_uri => 'info:fedora/changeme:99')
    @reflection = stub(:klass => mock.class, :options=>{:property=>'predicate'}, :class_name=> nil)
    ac = ActiveFedora::Associations::HasManyAssociation.new(@owner, @reflection)
    @target = [stub(:to_ary => nil, :new_record? => false, :remove_relationship=>true), stub(:to_ary => nil, :new_record? => false, :remove_relationship=>true), stub(:to_ary => nil, :new_record? => false, :remove_relationship=>true)]
    ac.target = @target 

    @expected1 = stub(:new_record? => false, :add_relationship=>true, :save=>true, :to_ary => nil)
    @expected2 = stub(:new_record? => false, :add_relationship=>true, :save=>true, :to_ary => nil)
    ac.replace([@expected1, @expected2])
    ac.target.should == [@expected1, @expected2]

  end


end
