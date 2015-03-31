Glossa2::Application.routes.draw do
scope module: 'rglossa' do
  devise_for :users, :class_name => "Rglossa::User", module: :devise

  root :to => 'home#index'
  match 'front', to: 'front#index'
  get 'admin', to: 'corpora#list'

  resources :corpora do
    collection do
      get 'find_by'
      post 'upload'
    end
    member do
      get 'cimdi'
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

  resources :saml, only: [] do
    collection do
      get :sso
      post :acs
      get :metadata
      get :logout
    end
  end

  get 'login/:idp' => 'saml#sso'
  post 'auth/:idp' => 'saml#acs'
  get 'logout/:idp' => 'saml#logout'
  get 'saml/metadata/:idp' => 'saml#metadata'

  post '(:idp)_auth' => 'saml#acs'
  get 'logout_(:idp)_user' => 'saml#logout'

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
end
