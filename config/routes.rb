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
    get '/wfplayer-:corpus_id-:line_key-:start-:stop(-:oldstart-:oldstop(-:width))', to: 'waveform_player#show',
        :constraints => {:start => /\d+(\.\d+)?/, :stop => /\d+(\.\d+)?/, :width => /\d+/,
                         :oldstart => /\d+(\.\d+)?/, :oldstop => /\d+(\.\d+)?/}
    namespace :search_engines do
      # Add more search types to the resource list as they are implemented, e.g.
      # resources :cwb_searches, :corpuscle_searches, :annis2_searches do
      resources :speech_cwb_searches do
        member do
          get 'results'
          get 'count'
          get 'geo_distr'
        end
      end
    end
  end
end
