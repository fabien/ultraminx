require 'rubygems'
require 'rake/gempackagetask'

PLUGIN = "ultraminx"
NAME = "ultraminx"
VERSION = "0.0.1"
AUTHOR = "Fabien Franzen"
EMAIL = "info@atelierfabien.be"
HOMEPAGE = "http://merb-plugins.rubyforge.org/ultraminx/"
SUMMARY = "This is a Merb port of Evan Weaver's Ultrasphinx Sphinx-based fulltext-search plugin."

spec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "LICENSE", 'TODO']
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  s.add_dependency('merb-core', '>= 0.4.0')
  s.require_path = 'lib'
  s.autorequire = PLUGIN
  s.files = %w(LICENSE README Rakefile TODO DEPLOYMENT_NOTES RAKE_TASKS) + Dir.glob("{lib,specs,vendor,examples}/**/*")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

task :install => [:package] do
  sh %{sudo gem install pkg/#{NAME}-#{VERSION}}
end

namespace :jruby do

  desc "Run :package and install the resulting .gem with jruby"
  task :install => :package do
    sh %{#{SUDO} jruby -S gem install pkg/#{NAME}-#{Merb::VERSION}.gem --no-rdoc --no-ri}
  end
  
end