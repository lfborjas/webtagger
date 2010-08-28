require 'httparty'
require 'httparty_icebox'

class Yahoo
    include HTTParty
    include HTTParty::Icebox
    format :json
    base_uri "http://search.yahooapis.com/ContentAnalysisService/V1"
    cache :store => 'memory', :timeout => 1
    
    def self.tag(text, token)
        resp = post("/termExtraction", :query => {:appid => token, :context => text, :output=>'json'} )
        if resp.has_key?('ResultSet')
            return resp['ResultSet']['Result'] || []
        end
        return []
    end
end

class Alchemy
    include HTTParty
    include HTTParty::Icebox
    format :json
    base_uri "http://access.alchemyapi.com/calls/text"
    cache :store => 'memory', :timeout => 1
    
    def self.tag(text, token)
        resp = post("/", :query => {:apikey => token, :text => text, :outputMode=>'json'} )
        return [] if resp['status'] == 'ERROR'
        return resp['keywords']
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

def tag(text, token="", service="tagthe")
    service = service.strip.downcase
    case
        when service == "yahoo":
            return Yahoo.tag(text, token)
        when service == "alchemy":
            return Alchemy.tag(text, token)
        else
            return Tagthe.tag(text)
    end
end
