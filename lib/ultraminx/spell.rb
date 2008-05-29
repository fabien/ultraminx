

module Ultraminx

=begin rdoc

In order to spellcheck your user's query, Ultraminx bundles a small spelling module. 

== Setup

Make sure Aspell and the Rubygem <tt>raspell</tt> are installed. See http://blog.evanweaver.com/files/doc/fauna/raspell/ for detailed instructions.
  
Copy the <tt>examples/ap.multi</tt> file into your Aspell dictionary folder (<tt>/opt/local/share/aspell/</tt> on Mac, <tt>/usr/lib/aspell-0.60/</tt> on Linux). This file lets Aspell load a custom wordlist generated by Sphinx from your app data (you can configure its filename in the <tt>config/ultraminx/*.base</tt> files). Modify the file if you don't want to also use the default American English dictionary.
  
Finally, to build the custom wordlist, run:  
  sudo rake ultraminx:spelling:build  

You need to use <tt>sudo</tt> because Ultraminx needs to write to the Aspell dictionary folder. Also note that Aspell, <tt>raspell</tt>, and the custom dictionary must be available on each application server, not on the Sphinx daemon server.


== Usage

Now you can see if a query is correctly spelled as so:
  @correction = Ultraminx::Spell.correct(@search.query)

If <tt>@correction</tt> is not <tt>nil</tt>, go ahead and suggest it to the user. 

=end

  module Spell  
  
    begin    
      SP = Aspell.new(Ultraminx::DICTIONARY)   
      SP.suggestion_mode = Aspell::NORMAL
      SP.set_option("ignore-case", "true")
      Ultraminx.say "spelling support enabled"
    rescue Object => e      
      SP = nil
      Ultraminx.say "spelling support not available (raspell configuration raised \"#{e}\")"
    end    
    
    def self.correct string
      return nil unless SP
      correction = string.gsub(/[\w\']+/) do |word| 
        unless SP.check(word)
          SP.suggest(word).first
        else
          word
        end
      end
      
      correction if correction != string
    end    
    
  end    
end

