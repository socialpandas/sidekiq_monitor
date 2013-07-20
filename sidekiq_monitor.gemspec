require File.expand_path('../lib/sidekiq/monitor/version', __FILE__)

Gem::Specification.new do |s|
  s.authors       = ["Tom Benner"]
  s.email         = ["tombenner@gmail.com"]
  s.description = s.summary = %q{Advanced monitoring for Sidekiq}
  s.homepage      = "https://github.com/socialpandas/sidekiq_monitor"

  s.files         = Dir["{app,config,lib,vendor}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.name          = "sidekiq_monitor"
  s.require_paths = ["lib"]
  s.version       = Sidekiq::Monitor::VERSION
  s.license       = 'MIT'

  s.add_dependency "sidekiq", ">= 2.2.1"
  s.add_dependency "slim"
  s.add_dependency "jquery-datatables-rails"
  s.add_dependency "ajax-datatables-rails"
end
