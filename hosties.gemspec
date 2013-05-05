Gem::Specification.new do |spec|
  spec.add_development_dependency 'rspec', '~> 2.5'
  spec.name = 'Hosties'
  spec.version = '0.0.1'
  spec.date = '2013-05-03'
  spec.summary = 'Easy environment description'
  spec.description = <<-DESC
    Hosties provides an expressive way to define environments, which are in turn
    comprised of lists of roles and the hosts that fill those roles.
  DESC
  spec.authors = ['Ron Dahlgren']
  spec.email = 'ronald.dahlgren@gmail.com'
  spec.files = Dir.glob("lib/**/*.rb")
  spec.files = ['lib/hosties.rb']
  spec.test_files = Dir.glob("spec/**/*.rb")
  spec.homepage = 'https://github.com/influenza/hosties'
end
