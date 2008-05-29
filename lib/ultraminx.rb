require 'fileutils'
require 'chronic'
require 'singleton'

$LOAD_PATH << "#{File.dirname(__FILE__)}/../vendor/riddle/lib"
require 'riddle'
require 'ultraminx/ultraminx'
require 'ultraminx/associations'
require 'ultraminx/core_extensions'
require 'ultraminx/is_indexed'

# make sure we're running inside Merb
if defined?(Merb::Plugins)

  # Merb gives you a Merb::Plugins.config hash...feel free to put your stuff in your piece of it
  Merb::Plugins.config[:ultraminx] = {}
  
  Merb::BootLoader.before_app_loads do
    # require code that must be loaded before the application
  end
  
  Merb::BootLoader.after_app_loads do
    require 'ultraminx/configure'
    require 'ultraminx/fields'

    require 'ultraminx/search/internals'
    require 'ultraminx/search/parser'
    require 'ultraminx/search'

    begin
      require 'raspell'
    rescue Object => e
    end

    require 'ultraminx/spell'
    
    Ultraminx::Configure.load_constants
    Ultraminx.verify_database_name
  end
  
  Merb::Plugins.add_rakefiles "ultraminx/merbtasks"
end