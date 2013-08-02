Sidekiq Monitor
===============
Advanced monitoring for Sidekiq

Description
-----------
Sidekiq Monitor offers a detailed UI for monitoring Sidekiq jobs, letting you filter, search, and sort jobs by many attributes, view error backtraces, set job completion metadata, and more.

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

And it looks like this:

[<img src="https://raw.github.com/socialpandas/sidekiq_monitor/master/examples/screenshot_jobs.png" />](https://raw.github.com/socialpandas/sidekiq_monitor/master/examples/screenshot.png)

It also includes a live, stacked histogram showing the health of each queue:

[<img src="https://raw.github.com/socialpandas/sidekiq_monitor/master/examples/screenshot_graph.png" />](https://raw.github.com/socialpandas/sidekiq_monitor/master/examples/screenshot.png)

Sidekiq Monitor stores jobs using ActiveRecord, allowing you to perform complex queries and delete specific collections of jobs:

```ruby
Sidekiq::Monitor::Job.where(queue: 'user_update').where('enqueued_at > ?', 2.days.ago).destroy_all
```

Installation
------------

Add sidekiq_monitor to your Gemfile:

    gem 'sidekiq_monitor'

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