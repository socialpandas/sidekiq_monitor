Sidekiq Monitor
===============
Advanced monitoring for Sidekiq

Description
-----------
Sidekiq Monitor offers a detailed, malleable UI for monitoring Sidekiq jobs.

It lets you:

  * Sort jobs by:
    * Queue
    * Class
    * Queued at time
    * Started at time
    * Duration
    * Status (e.g. queued, running, complete, failed)
  * Filter jobs by:
    * Queue
    * Class
    * Status
  * Set and view metadata for each job:
    * Name - A customizable, human-readable name (e.g. 'Data Import for John Doe')
    * Result - A customizable value describing the job's result (e.g. '{imported\_documents\_count: 241, imported\_contacts_count: 183}')
  * View errors for failed jobs, including a backtrace
  * Easily isolate long-running jobs and failed jobs
  * Retry failed jobs via a button-click

Installation
------------

Add sidekiq-monitor to your Gemfile:

    gem 'sidekiq-monitor', :git => 'git://github.com/socialpandas/sidekiq-monitor.git'

Install and run the migration:

    rails g sidekiq:monitor:install
    rake db:migrate

Mount it at a customizable path in `routes.rb`:

    mount Sidekiq::Monitor::Engine => '/sidekiq'

Usage
-----

### Setting a Job Name

To set a job's name (which makes the job's representation in the UI more human-readable), define a `self.job_name` method on your worker that takes the same arguments as its `perform` method:

```ruby
class HardWorker
  include Sidekiq::Worker

  def perform(user_id)
    puts 'Doing hard work'
  end

  def self.job_name(user_id)
    User.find(user_id).username
  end
end
```

### Setting a Job Result

To set a job's result (which can show what the job accomplished, for example), return a hash from the worker's `perform` method:

```ruby
class HardWorker
  include Sidekiq::Worker

  def perform(user_ids)
    puts 'Doing hard work'
    { processed_users_count: user_ids.length }
  end
end
```

### Authentication

You'll likely want to restrict access to this interface in a production setting. To do this, you can use routing constraints:

#### Devise

Checks a `User` model instance that responds to `admin?`

```ruby
constraint = lambda { |request| request.env["warden"].authenticate? and request.env['warden'].user.admin? }
constraints constraint do
  mount Sidekiq::Monitor::Engine => '/sidekiq'
end
```

Allow any authenticated `User`

```ruby
constraint = lambda { |request| request.env['warden'].authenticate!({ scope: :user }) }
constraints constraint do
  mount Sidekiq::Monitor::Engine => '/sidekiq'
end
```

Short version

```ruby
authenticate :user do
  mount Sidekiq::Monitor::Engine => '/sidekiq'
end
```

#### Authlogic

```ruby
# lib/admin_constraint.rb
class AdminConstraint
  def matches?(request)
    return false unless request.cookies['user_credentials'].present?
    user = User.find_by_persistence_token(request.cookies['user_credentials'].split(':')[0])
    user && user.admin?
  end
end

# config/routes.rb
require "admin_constraint"
mount Sidekiq::Monitor::Engine => '/sidekiq', :constraints => AdminConstraint.new
```

#### Restful Authentication

Checks a `User` model instance that responds to `admin?`

```
# lib/admin_constraint.rb
class AdminConstraint
  def matches?(request)
    return false unless request.session[:user_id]
    user = User.find request.session[:user_id]
    user && user.admin?
  end
end

# config/routes.rb
require "admin_constraint"
mount Sidekiq::Monitor::Engine => '/sidekiq', :constraints => AdminConstraint.new
```

#### Custom External Authentication

```ruby
class AuthConstraint
  def self.admin?(request)
    return false unless (cookie = request.cookies['auth'])

    Rails.cache.fetch(cookie['user'], :expires_in => 1.minute) do
      auth_data = JSON.parse(Base64.decode64(cookie['data']))
      response = HTTParty.post(Auth.validate_url, :query => auth_data)

      response.code == 200 && JSON.parse(response.body)['roles'].to_a.include?('Admin')
    end
  end
end

# config/routes.rb
constraints lambda {|request| AuthConstraint.admin?(request) } do
  mount Sidekiq::Monitor::Engine => '/admin/sidekiq'
end
```

_(This authentication documentation was borrowed from the [Sidekiq wiki](https://github.com/mperham/sidekiq/wiki/Monitoring).)_

License
-------

Sidekiq Monitor is released under the MIT License. Please see the MIT-LICENSE file for details.