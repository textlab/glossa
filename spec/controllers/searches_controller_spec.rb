require 'spec_helper'

describe SearchesController do
  describe "POST 'create'" do

    describe "if all parameters are correctly set" do
      it "should be successful" do
        post 'create', :data => {:queries => SAMPLE_SEARCH_DATA[:queries]}
        response.should be_success
      end
    end

    describe "if params[:data] is not set" do
      before do
        post 'create'
      end

      it "response status should be 'Bad Request'" do
        response.status.should include('Bad Request')
      end

      it "response message should say that the data parameter is missing" do
        resp = JSON.parse(response.body)
        resp['message'].should have_text('Data parameter is missing')
      end
    end

    describe "if params[:data][:queries] is not set" do
      before do
        post 'create', :data => {}
      end

      it "response status should be 'Bad Request'" do
        response.status.should include('Bad Request')
      end
    end

#    describe "if no user is logged in" do
#      it "should not create a Search object" do
#  #      Search.delete_all
#        Search.count.should == 0
#      end
#    end
#
#    describe "if a user is logged in" do
#      it "should create a Search object" do
#  #      Search.delete_all
#        post 'create'
#        Search.count.should == 1
#      end
#    end
  end
end
