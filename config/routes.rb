Osem::Application.routes.draw do

  if CONFIG['authentication']['ichain']['enabled']
    devise_for :users, controllers: { registrations: :registrations }
  else
    devise_for :users,
               controllers: {
                   registrations: :registrations, confirmations: :confirmations,
                   omniauth_callbacks: 'users/omniauth_callbacks' },
               path: 'accounts'
  end

  resources :users, except: [:new, :index, :create, :destroy]

  namespace :admin do
    resources :users
    resources :people
    resources :comments, only: [:index]
    resources :conference do
      member do
        get :roles
        post :roles
        post :add_user
        delete :remove_user
      end
      resource :contact, except: [:index, :new, :create, :show, :destroy]
      resources :photos, except: [:show]
      resource :schedule, only: [:show, :update]
      get 'commercials/render_commercial' => 'commercials#render_commercial'
      resources :commercials, only: [:index, :create, :update, :destroy]
      get '/stats' => 'stats#index'
      get '/dietary_choices' => 'dietchoices#show', as: 'dietary_list'
      patch '/dietary_choices' => 'dietchoices#update', as: 'dietary_update'
      get '/volunteers_list' => 'volunteers#show'
      get '/volunteers' => 'volunteers#index', as: 'volunteers_info'
      patch '/volunteers' => 'volunteers#update', as: 'volunteers_update'

      resources :registrations, except: [:create, :new] do
        member do
          patch :toggle_attendance

        end
      end

      # Singletons
      resource :splashpage
      resource :venue do
        resources :rooms, except: [:show]
      end
      resource :registration_period
      resource :program do
        resource :cfp
        resources :tracks
        resources :event_types
        resources :difficulty_levels
        resources :events do
          member do
            post :comment
            patch :accept
            patch :confirm
            patch :cancel
            patch :reject
            patch :unconfirm
            patch :restart
            get :vote
          end
          resource :speaker, only: [:edit, :update]
        end
      end

      resources :tickets
      resources :sponsors, except: [:show]
      resources :lodgings, except: [:show]
      resources :targets, except: [:show]
      resources :campaigns, except: [:show]
      resources :emails, only: [:show, :update, :index]

      resources :sponsorship_levels, except: [:show] do
        member do
          patch :up
          patch :down
        end
      end

      resources :questions do
        collection do
          patch :update_conference
        end
      end
    end
  end

  resources :conference, only: [:index, :show] do
    resource :program, except: :destroy do
      resources :proposal do
        get 'commercials/render_commercial' => 'commercials#render_commercial'
        resources :commercials, only: [:create, :update, :destroy]
        resources :event_attachment, controller: 'event_attachments'
        member do
          patch '/confirm' => 'proposal#confirm'
          patch '/restart' => 'proposal#restart'
        end
      end
    end

    resource :conference_registrations, path: 'register'
    resources :tickets, only: [:index]
    resources :ticket_purchases, only: [:create, :destroy]
    resource :subscriptions, only: [:create, :destroy]

    member do
      get :schedule
    end
  end

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      resources :conferences, only: [ :index, :show ] do
        resources :rooms, only: :index
        resources :tracks, only: :index
        resources :speakers, only: :index
        resources :events, only: :index
      end
      resources :rooms, only: :index
      resources :tracks, only: :index
      resources :speakers, only: :index
      resources :events, only: :index
    end
  end

  get '/admin' => redirect('/admin/conference')

  root to: 'conference#index', via: [:get, :options]
end
