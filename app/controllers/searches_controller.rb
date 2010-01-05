class SearchesController < ApplicationController
  def create
    unless params.has_key?(:data)
      render :json => {:success => false, :message => 'Data parameter is missing'}, :status => :bad_request
      return
    end

    unless params[:data].is_a?(Hash) && params[:data].has_key?(:queries)
      render :json => {:success => false, :message => 'Queries parameter is missing'}, :status => :bad_request
      return
    end

#    unless params[:data].has_ke
#    current_user.searches.create!(params[:data]) if current_user
  end

  def destroy
  end

end
