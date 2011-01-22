require 'fileutils'
require 'httparty'
require 'httparty_icebox'

#Module for extracting keywords from text. Uses the tagthe, yahoo and alchemyAPI web services.
#Because the yahoo and alchemy services require an API key, a command line utility is provided
#to add those tokens for subsequent uses of the modules, storing them in <tt>~/.webtagger</tt>
#it uses caching to avoid being throttled by the apis, via the httparty_icebox gem
module WebTagger
    
    #The services supported by this version
    SERVICES = ['yahoo', 'alchemy', 'tagthe']
    
    #A generic exception to handle api call errors
    class WebTaggerError < RuntimeError
        attr :response
        def initialize(resp)
            @response = resp
        end
    end
    
    #Get the persisted token for a service, if no service is provided, all tokens are returned in a hash
    #Params:
    #+service+:: the service for which the token should be retrieved, must be one of SERVICES
    def get_token(service="")
        service = service.strip.downcase
        conf = File.join(ENV['HOME'], '.webtagger')
        return nil unless File.exist? conf
        srvcs = {}
        File.open(conf).each do |service_conf|
            s, t = service_conf.split(/\s*=\s*/) rescue next
            srvcs[s.strip.downcase] = t.strip
        end

        return case 
        when service == "all"
            srvcs
        when (SERVICES.include?(service) and srvcs[service])
            srvcs[service]
        else
            nil
        end
    end
    
    #Class to access the 
    #{yahoo term extraction web service}[http://developer.yahoo.com/search/content/V1/termExtraction.html]
    class Yahoo
        include HTTParty
        include HTTParty::Icebox
        format :json
        base_uri "http://search.yahooapis.com/ContentAnalysisService/V1"
        cache :store => 'memory', :timeout => 60
        
        def self.tag(text, token)
            raise "Token missing!" unless token
            resp = post("/termExtraction", :query => {:appid => token, :context => text, :output=>'json'} )
            if resp.has_key?('ResultSet')
                return resp['ResultSet']['Result'] || []
            else
                raise WebTaggerError.new(resp), "Error in API call"
            end
        end
    end
    
    #Class for accessing the
    #{alchemy keyword extraction service}[http://www.alchemyapi.com/api/keyword/textc.html]
    class Alchemy
        include HTTParty
        include HTTParty::Icebox
        format :json
        base_uri "http://access.alchemyapi.com/calls/text"
        cache :store => 'memory', :timeout => 60
        
        def self.tag(text, token)
            raise "Token missing!" unless token
            resp = post("/TextGetRankedKeywords", :query => {:apikey => token, :text => text, :outputMode=>'json'} )
            if resp['status'] != 'ERROR'
                #it's a hash array of [{:text=>"", :relevance=>""}]
                kws = []
                resp['keywords'].each do |m|
                    kws.push m["text"]
                end
                return kws
            else
                raise WebTaggerError.new(resp), "Error in API call"
            end          
        end
    end
    
    #class for accesing the 
    #{tagthe API}[http://tagthe.net/fordevelopers]
    class Tagthe 
        include HTTParty
        include HTTParty::Icebox
        format :json
        base_uri "http://tagthe.net/api"
        cache :store => 'memory', :timeout => 60
        
        def self.tag(text)
            resp = post("/", :query => {:text => text, :view=>'json'} )
            if resp.has_key?('memes') and resp['memes'][0].has_key?('dimensions') \
                and resp['memes'][0]['dimensions'].has_key?('topic')
                
                return resp['memes'][0]['dimensions']['topic']
            else
                return []
            end
        end
    end
    
    #Method for obtaining keywords in a text
    #Params:
    #+text+:: a +String+, the text to tag
    #+service+(optional):: a +String+, the name of the service to use, defaults to tagthe and must be one of SERVICES
    #+token+(optional):: a token to use for calling the service (tagthe doesn't need one), keep in mind that this value,
    #superseeds the one stored in +~/.webtagger+ and that, due to caching, might not be used if the request is done
    #less than a minute after the last one with a different token
    def tag(text,service="tagthe",token=nil)
        service = service.strip.downcase
        token = get_token(service) unless token
        return case
            when service == "yahoo"
                Yahoo.tag(text, token)
            when service == "alchemy"
                Alchemy.tag(text, token)
            else
                Tagthe.tag(text)
        end
    end

    module_function :tag
    module_function :get_token
end #of webtagger module
