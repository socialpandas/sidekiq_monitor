require File.expand_path('../lib/sidekiq/monitor/version', __FILE__)

Gem::Specification.new do |s|
  s.authors       = ["Tom Benner"]
  s.email         = ["tombenner@gmail.com"]
  s.description   = %q{Advanced monitoring for Sidekiq}
  s.summary       = %q{A detailed, malleable UI for monitoring Sidekiq jobs.}
  s.homepage      = "https://github.com/socialpandas/sidekiq-monitor"

  s.files         = Dir["{app,config,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.name          = "sidekiq-monitor"
  s.require_paths = ["lib"]
  s.version       = Sidekiq::Monitor::VERSION

  s.add_dependency "sidekiq", ">= 2.2.1"
  s.add_dependency "slim"
  s.add_dependency "ajax-datatables-rails"
end
