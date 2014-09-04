Rglossa::Engine.routes.draw do
  devise_for :users, :class_name => "Rglossa::User", module: :devise

  root :to => 'home#index'

  resources :corpora do
    collection do
      get 'find_by'
    end
  end

  resources :metadata_values

  resources :metadata_categories do
    resources :metadata_values
  end

  namespace :search_engines do
    # Add more search types to the resource list as they are implemented, e.g.
    # resources :cwb_searches, :corpuscle_searches, :annis2_searches do
    resources :cwb_searches do
      member do
        get 'results'
        get 'count'
      end
    end
  end

  scope module: 'speech' do
    namespace :search_engines do
      # Add more search types to the resource list as they are implemented, e.g.
      # resources :cwb_searches, :corpuscle_searches, :annis2_searches do
      resources :speech_cwb_searches do
        member do
          get 'results'
          get 'count'
        end
      end
    end
  end
end
