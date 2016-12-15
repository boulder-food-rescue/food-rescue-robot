Webapp::Application.routes.draw do

  resources :assignments do
    collection do
      get :index
      get :knight
    end
  end

  resources :regions do
    get 'recipients', :on => :member
    get 'request_rescue', :on => :member
    as_routes
  end

  resources :cell_carriers do as_routes end
  resources :transport_types do as_routes end

  resources :food_types
  resources :scale_types

  resources :absences do
    collection do
      get :all
    end
  end

  resources :logs do
    collection do
      get :by_day
      get :tardy
      get :last_ten
      get :open
      get :todo
      get :mine_past
      get :mine_upcoming
      get :being_covered
      get :new_absence
      get :create_absence
      get :receipt
      get :index
      get :edit
      get :update
      get :create
      get :destroy
      get :stats_service
      get :stats
      get :export
    end
    member do
      get :take
      get :leave
    end
  end

  resources :schedule_chains do
    collection do
      get :today
      get :tomorrow
      get :yesterday
      get :open
      get :open_old
      get :mine
      get :mine_old
      get :take
      get :leave
      get :index
      get :edit
      get :update
      get :create
      get :destroy
    end
    #member do
    #  get :show
    #end
  end

  resources :locations do
    collection do
      get :donors
      get :recipients
      get :hubs
      get :sellers
      get :buyers
      get :index
      get :edit
      get :update
      get :create
      get :destroy
      get :hud
    end
  end

  devise_for :volunteers, :controllers => { :sessions => "sessions" }

  resources :volunteers do
    collection do
      get :home
      get :unassigned
      get :shiftless
      get :shiftless_old
      get :active
      get :inactive
      get :need_training
      get :super_admin
      get :region_admin
      get :stats
      get :switch_user
      get :knight
      get :index
      get :edit
      get :update
      get :create
      get :destroy
      get :assign
    end
    member do
      get :reactivate
    end
  end

  resource :waiver, only: [:new, :create]

  devise_scope :volunteer do
    authenticated do
      root to: 'volunteers#home'
    end

    unauthenticated do
      root to: 'sessions#new', as: :unauthenticated_root
    end
  end

end
