require 'fileutils'
require 'httparty'
require 'httparty_icebox'

module WebTagger

    SERVICES = ['yahoo', 'alchemy', 'tagthe']
    
    class WebTaggerError < RuntimeError
        attr :response
        def initialize(resp)
            @response = resp
        end
    end
    
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

    class Yahoo
        include HTTParty
        include HTTParty::Icebox
        format :json
        base_uri "http://search.yahooapis.com/ContentAnalysisService/V1"
        cache :store => 'memory', :timeout => 1
        
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

    class Alchemy
        include HTTParty
        include HTTParty::Icebox
        format :json
        base_uri "http://access.alchemyapi.com/calls/text"
        cache :store => 'memory', :timeout => 1
        
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

    class Tagthe 
        include HTTParty
        include HTTParty::Icebox
        format :json
        base_uri "http://tagthe.net/api"
        cache :store => 'memory', :timeout => 1
        
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
