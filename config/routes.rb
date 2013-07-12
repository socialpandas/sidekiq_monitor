Sidekiq::Monitor::Engine.routes.draw do
  get '/', to: 'jobs#index', :as => 'sidekiq_monitor'
  get '/queues', to: 'queues#index'
  
  namespace 'api' do
    get '/jobs', to: 'jobs#index'
    match '/jobs/:action(/:id)' => 'jobs', via: :all
    get '/queues/:queue', to: 'queues#show'
  end
end
