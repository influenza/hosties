# Hosties
A Ruby gem for describing environments in an easy to read format. 

### Quick Start
Clone the repo, verify the tests:

```
$ git clone git://github.com/influenza/hosties.git
$ cd hosties
$ rake
```

Now you can install the gem from the source (it'll be pushed to rubygems.org soon):

```
$ gem build ./hosties.gemspec
$ gem install ./hosties-0.0.1.gem
```

From this point, you can start using hosties to expressively declare environments!

### Rationale
Often times, when you have a medium-sized project, there's a lot of code around 
performing automated deployments. I've found Ruby to be a really good fit for this
so when I can't use a full-blown configuration management tool (like [chef](http://www.opscode.com/chef/)), 
I always end up rolling my own scripts. Alongside these scripts there's usually a file 
containing all of the hosts for the various environments. The deployment tools, 
often exposed as a one-click affair through some web front-end, are intended for 
use by everyone, not just me. The other people at my organization might not be 
familiar with Ruby, but they may find themselves needing to update the environment
data - maybe to pull a host out of rotation, or to add a new set of hosts. To help
ease the pain of that while ensuring correctness, you have hosties! The number one 
ridiculously named gem for defining product deployment environments!

### Example

Declare a product type that has web hosts, service hosts, and monitoring hosts
```ruby
require 'hosties'

# First, describe the host types that we'll be using
host_type :web_host do
  have_service :http
end

host_type :service_host do
  have_services :awesomeness, :management, :metrics
  have_attributes :uuid, :awesome_level
  where(:awesome_level).can_be :low, :medium, :high
end

host_type :monitoring_host do
  have_services :graphing, :logging, :alerting
  have_attributes :facility
  where(:facility).can_be :north_america, :europe, :asia
end

# Now describe the environments for this product
environment_type :AmazingService do
  need :web_host, :service_host, :monitoring_host
  have_attribute :environment
  where(:environment).can_be :dev, :test, :live
  grouped_by :environment
end

# From here, we can define a couple of environments
environment_for :AmazingService do
  environment :dev
  web_host "hostname.webhost" do http 80 end
  service_host "hostname.svchost1" do 
    awesomeness 1234
    management 3333
    metrics 9090
    uuid "EED7A7EA-57D8-4F81-8E7C-45F5A057140E"
    awesome_level :low
  end
  service_host "hostname.svchost2" do 
    awesomeness 1234
    management 3333
    metrics 9090
    uuid "886ACE31-A15B-49DD-B017-14F7C489821F"
    awesome_level :medium
  end
  monitoring_host "hostname.monitoring" do
    graphing 8080
    logging 8081
    alerting 8082
    facility :north_america
  end
end
```
That's it! Now to access these in your spectacular deployment or management scripts 
using the following hashes:
- **Hosties::Environments** - Mapping of environment type (:AmazingService in the example) to a list of environments of that type
- **Hosties::GroupedEnvironments** - Mapping of environment type to a hash of values for the grouped_by attribute to a list of matches, for instance, Hosties::GroupedEnvironments[:AmazingService][:dev] to get a list containing the environment above.

In future versions, this will be changed from a raw hash to something friendlier to work with.
