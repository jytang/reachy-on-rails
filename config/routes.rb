Rails.application.routes.draw do

  resources :games do
    resources :rounds do
      member do
        delete 'reset_last'
      end
    end
    collection do
      delete 'destroy_all'
    end
  end

  root 'welcome#index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
