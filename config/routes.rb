Rglossa::Engine.routes.draw do
  namespace :speech do
  end

  scope module: 'speech' do
    namespace :search_engines do
      # Add more search types to the resource list as they are implemented, e.g.
      # resources :cwb_searches, :corpuscle_searches, :annis2_searches do
      resources :speech_cwb_searches, controller: 'cwb_searches' do
        member do
          get 'results'
          get 'count'
        end
      end
    end
  end
end
