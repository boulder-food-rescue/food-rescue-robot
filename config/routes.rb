Webapp::Application.routes.draw do
 
  resources :home do
    collection do
      get :welcome
    end
  end

  resources :assignments do
    collection do
      get :index
      get :knight
    end
  end
 
  resources :cell_carriers do as_routes end
  resources :regions do as_routes end
  resources :transport_types do as_routes end
  resources :food_types do as_routes end

  resources :logs do 
    collection do
      get :today
      get :tomorrow
      get :yesterday
      get :tardy
      get :last_ten
      get :open
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
    end
    member do
      get :take
    end
  end

  resources :schedules do 
    collection do
      get :today
      get :tomorrow
      get :yesterday
      get :open
      get :open_old
      get :mine
      get :mine_old
      get :take
      get :index
      get :edit
      get :update
      get :create
      get :destroy
    end
  end

  resources :locations do
    collection do
      get :donors
      get :recipients
      get :index
      get :edit
      get :update
      get :create
      get :destroy
      get :hud
    end
  end

  devise_for :volunteers
  resources :volunteers do 
    collection do
      get :home
      get :unassigned
      get :shiftless
      get :shiftless_old
      get :need_training
      get :super_admin
      get :region_admin
      get :switch_user
      get :knight
      get :index
      get :edit
      get :update
      get :create
      get :destroy
      get :waiver
      get :sign_waiver
      get :assign
    end
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'volunteers#home'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
