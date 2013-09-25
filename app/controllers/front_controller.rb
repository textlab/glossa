class FrontController < ApplicationController
  layout false

  def index
    rconsole.log 'her'
  end
end
