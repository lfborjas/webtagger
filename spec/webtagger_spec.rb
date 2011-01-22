require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "WebTagger" do
  before(:each) do
     @query = "I'm a very general surgeon, surgeon"
  end

  it "should tag with tagthe" do
   r = WebTagger.tag_with_tagthe @query
   r.should == ["surgeon"]
  end

  it "should tag with alchemy" do
     r = WebTagger.tag_with_alchemy @query
     r.should == ["general surgeon"]
  end

end
