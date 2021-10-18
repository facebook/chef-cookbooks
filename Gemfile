source 'https://rubygems.org'

gem 'chef', '~> 13'
gem 'foodcritic', '~> 12'
gem 'rspec', '= 3.6'
gem 'rubocop', '= 1.3.1'
# work around https://github.com/cucumber/cucumber-ruby-core/issues/160
# remove this once we're on ruby 2.5 or later
gem 'gherkin', '~> 5.1'
# workaround for https://github.com/cucumber/cucumber/issues/483
gem 'cucumber-core', '~> 3.2.1'

%w{
  chefspec
  diffy
  test-kitchen
  kitchen-dokken
}.each do |g|
  gem g
end
