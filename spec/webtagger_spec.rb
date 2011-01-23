require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

#ATTENTION, ACTHUNG, ATENCIÓN:
#The calls to *yahoo* and *alchemy* require
#an API token in the actual service
#but, because I'm using fakeweb here, I can bypass that.
#IF YOU USE THOSE; REMEMBER TO ADD YOUR API TOKEN AS A 
#SECOND PARAMETER!
describe "WebTagger" do
  before(:each) do
     @query = "I'm a very general surgeon, surgeon"
  end

  it "should tag with an individual service" do
   r = WebTagger.tag_with_tagthe @query
   r.should == ["surgeon"]

   r = WebTagger.tag_with_alchemy @query
   r.should == ["general surgeon"]

   r = WebTagger.tag_with_yahoo @query
   r.should == nil 
  end
 
  it "should combine results" do
      r = WebTagger.tag_with_alchemy_and_tagthe @query
      r.sort.should == ["general surgeon", "surgeon"]

      r = WebTagger.tag_with_yahoo_and_alchemy_and_tagthe @query
      r.sort.should == ["general surgeon", "surgeon"]
  end

  it "should present disjoint results" do
      r = WebTagger.tag_with_alchemy_or_tagthe @query
      r.should == ["general surgeon"]

      s = WebTagger.tag_with_tagthe_or_alchemy @query
      s.should == ["surgeon"]

      s = WebTagger.tag_with_yahoo_or_tagthe_or_alchemy @query
      s.should == ["surgeon"]
  end
end
