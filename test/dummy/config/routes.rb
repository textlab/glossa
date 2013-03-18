Rails.application.routes.draw do
  devise_for :users

  mount Rglossa::Engine => "/"

end
