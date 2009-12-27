require 'spec_helper'

describe SearchesController do

  #Delete these examples and add some real ones
  it "should use SearchesController" do
    controller.should be_an_instance_of(SearchesController)
  end


  describe "POST 'create'" do
    it "should be successful" do
      post 'create'
      response.should be_success
    end
  end

  describe "POST 'destroy'" do
#    it "should be successful" do
#      delete '/'
#      response.should be_success
#    end
  end
end
