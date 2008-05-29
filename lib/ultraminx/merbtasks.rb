namespace :ultraminx do  

  task :_environment => [:merb_env] do
    # We can't just chain :merb_env because we want to make 
    # sure it's set only for known Sphinx tasks
    Ultraminx.with_rake = true
  end
  
  desc "Bootstrap a full Sphinx environment"
  task :bootstrap => [:_environment, :configure, :index, :"daemon:restart"] do
    say "done"
    say "please restart your application containers"
  end
  
  desc "Rebuild the configuration file for this particular environment."
  task :configure => [:_environment] do
    Ultraminx::Configure.run
  end
  
  namespace :index do    
    desc "Reindex and rotate the main index."
    task :main => [:_environment] do
      ultraminx_index(Ultraminx::MAIN_INDEX)
    end

    desc "Reindex and rotate the delta index."    
    task :delta => [:_environment] do
      ultraminx_index(Ultraminx::DELTA_INDEX)
    end
    
    desc "Merge the delta index into the main index."
    task :merge =>  [:_environment] do
      ultraminx_merge
    end
    
  end

  desc "Reindex and rotate all indexes."  
  task :index => [:_environment]  do
    ultraminx_index("--all")
  end
  
  namespace :daemon do
    desc "Start the search daemon"
    task :start => [:_environment] do
      FileUtils.mkdir_p File.dirname(Ultraminx::DAEMON_SETTINGS["log"]) rescue nil
      raise Ultraminx::DaemonError, "Already running" if ultraminx_daemon_running?
      system "searchd --config '#{Ultraminx::CONF_PATH}'"
      sleep(4) # give daemon a chance to write the pid file
      if ultraminx_daemon_running?
        say "started successfully"
      else
        say "failed to start"
      end
    end
    
    desc "Stop the search daemon"
    task :stop => [:_environment] do
      raise Ultraminx::DaemonError, "Doesn't seem to be running" unless ultraminx_daemon_running?
      system "kill #{pid = ultraminx_daemon_pid}"
      sleep(1)
      if ultraminx_daemon_running?
        system "kill -9 #{pid}"  
        sleep(1)
      end
      if ultraminx_daemon_running?
        say "#{pid} could not be stopped"
      else
        say "stopped #{pid}"
      end
    end

    desc "Restart the search daemon"
    task :restart => [:_environment] do
      Rake::Task["ultraminx:daemon:stop"].invoke if ultraminx_daemon_running?
      sleep(3)
      Rake::Task["ultraminx:daemon:start"].invoke
    end
    
    desc "Check if the search daemon is running"
    task :status => [:_environment] do
      if ultraminx_daemon_running?
        say "daemon is running."
      else
        say "daemon is stopped."
      end
    end      
  end
          
    
  namespace :spelling do
    desc "Rebuild the custom spelling dictionary. You may need to use 'sudo' if your Aspell folder is not writable by the app user."
    task :build => [:_environment] do    
      ENV['OPTS'] = "--buildstops #{Ultraminx::STOPWORDS_PATH} #{Ultraminx::MAX_WORDS} --buildfreqs"
      Rake::Task["ultraminx:index"].invoke
      tmpfile = "/tmp/ultraminx-stopwords.txt"
      words = []
      say "filtering"
      File.open(Ultraminx::STOPWORDS_PATH).each do |line|
        if line =~ /^([^\s\d_]{4,}) (\d+)/
          # XXX should be configurable
          words << $1 if $2.to_i > 40 
          # ideally we would also skip words within X edit distance of a correction
          # by aspell-en, in order to not add typos to the dictionary
        end
      end
      say "writing #{words.size} words"
      File.open(tmpfile, 'w').write(words.join("\n"))
      say "loading dictionary '#{Ultraminx::DICTIONARY}' into aspell"
      system("aspell --lang=en create master #{Ultraminx::DICTIONARY}.rws < #{tmpfile}")
    end
  end
  
end

# task shortcuts
namespace :us do
  task :start => ["ultraminx:daemon:start"]
  task :restart => ["ultraminx:daemon:restart"]
  task :stop => ["ultraminx:daemon:stop"]
  task :stat => ["ultraminx:daemon:status"]
  task :index => ["ultraminx:index"]
  task :in => ["ultraminx:index"]
  task :main => ["ultraminx:index:main"]
  task :delta => ["ultraminx:index:delta"]
  task :merge => ["ultraminx:index:merge"]
  task :spell => ["ultraminx:spelling:build"]
  task :conf => ["ultraminx:configure"]  
  task :boot => ["ultraminx:bootstrap"]  
end

# Support methods

def ultraminx_daemon_pid
  open(Ultraminx::DAEMON_SETTINGS['pid_file']).readline.chomp rescue nil
end

def ultraminx_daemon_running?
  if ultraminx_daemon_pid and `ps #{ultraminx_daemon_pid} | wc`.to_i > 1 
    true
  else
    # Remove bogus lockfiles.
    Dir[Ultraminx::INDEX_SETTINGS["path"] + "*spl"].each {|file| File.delete(file)}
    false
  end  
end

def ultraminx_index(index)
  rotate = ultraminx_daemon_running?
  ultraminx_create_index_path
  
  cmd = "indexer --config '#{Ultraminx::CONF_PATH}'"
  cmd << " #{ENV['OPTS']} " if ENV['OPTS']
  cmd << " --rotate" if rotate
  cmd << " #{index}"
  
  say "$ #{cmd}"
  system cmd
    
  ultraminx_check_rotate if rotate    
end

def ultraminx_merge
  rotate = ultraminx_daemon_running?

  indexes = [Ultraminx::MAIN_INDEX, Ultraminx::DELTA_INDEX]
  indexes.each do |index|
    raise "#{index} index is missing" unless File.exist? "#{Ultraminx::INDEX_SETTINGS['path']}/sphinx_index_#{index}.spa"
  end
  
  cmd = "indexer --config '#{Ultraminx::CONF_PATH}'"
  cmd << " #{ENV['OPTS']} " if ENV['OPTS']
  cmd << " --rotate" if rotate
  cmd << " --merge #{indexes.join(' ')}"
  
  say "$ #{cmd}"
  system cmd
      
  ultraminx_check_rotate
end

def ultraminx_check_rotate
  sleep(4)
  failed = Dir[Ultraminx::INDEX_SETTINGS['path'] + "/*.new.*"]
  if failed.any?
    say "warning; index failed to rotate! Deleting new indexes"
    failed.each {|f| File.delete f }
  else
    say "index rotated ok"
  end
end

def ultraminx_create_index_path
  unless File.directory? Ultraminx::INDEX_SETTINGS['path']
    mkdir_p Ultraminx::INDEX_SETTINGS['path'] 
  end
end

def say msg
  Ultraminx.say msg
end