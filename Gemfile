source 'https://rubygems.org'

gem 'chef', '~> 13'
gem 'foodcritic', '~> 12'
gem 'rspec', '= 3.6'
gem 'rubocop', '= 0.49'
# work around https://github.com/cucumber/cucumber-ruby-core/issues/160
gem 'gherkin', '~> 5.1'

%w{
  chefspec
  diffy
  test-kitchen
  kitchen-docker
}.each do |g|
  gem g
end
