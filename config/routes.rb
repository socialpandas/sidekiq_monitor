Sidekiq::Monitor::Engine.routes.draw do
  match '/' => 'jobs#index', :as => 'sidekiq_monitor'
  match '/queues' => 'queues#index'
  
  namespace 'api' do
    match '/jobs' => 'jobs#index'
    match '/jobs/:action(/:id)' => 'jobs'
    match '/queues/:queue' => 'queues#show'
  end
end
