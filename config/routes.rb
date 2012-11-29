Rglossa::Engine.routes.draw do

  root :to => 'home#index'

  resources :corpora, :metadata_categories, :metadata_values,
  :metadata_constraints

  namespace :search_types do
    # Add more search types to the resource list as they are implemented, e.g.
    # resources :cwb_searches, :corpuscle_searches, :annis2_searches do
    resources :cwb_searches do
      collection do
        get 'page'
        post 'query'

        # FIXME: These don't belong here
        get 'corpora_list'
        get 'corpus_info'
      end
    end
  end

end
