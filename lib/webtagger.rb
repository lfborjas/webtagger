%w{net/http json digest/md5}.each{|m| require m }

#Class for extracting keywords from text. Uses the tagthe, yahoo and alchemyAPI web services.
#it uses caching to avoid being throttled by the apis, via the httparty_icebox gem
class WebTagger

    #one of these days, gotta add filesystem cache
    @@cache = {}
    #Macro for creating a provider-specific tagger
    def self.tags_with(service, options={}, &callback)
        opts = {:uri => "",
                :use_tokens=>true,
                :cache=>true, 
                :json=>true,
                :method=>:post,
                :text_param=>"text",
                :token_param=>"",
                :extra_params=>{} }.merge(options)
                
        #use the meta-class to inject a static method in this class
        (class << self; self; end).instance_eval do

            #hack the block: using the star operator we can get an empty second param without fuss
            define_method("tag_with_#{service.to_s}") do | text, *tokens |

                text_digest = Digest::MD5.hexdigest service.to_s+text
                callback.call(@@cache[text_digest]) unless @@cache[text_digest].nil?

                query = {opts[:text_param] => text}.merge(opts[:extra_params])
                query[opts[:token_param]] = *tokens if opts[:use_tokens]

                r = Net::HTTP.post_form URI.parse(opts[:uri]), query

                response = if opts[:json] then JSON.parse(r.body) else r.body end
                if (100..399) === r.code.to_i
                    @@cache[text_digest] = response
                    callback.call(response)
                else
                    callback.call(nil)
                end
            end
        end
    end

    Boilerplate = {:yahoo=>{:uri=>"http://search.yahooapis.com/ContentAnalysisService/V1/termExtraction",
                            :token_param=>"appid",
                            :text_param=>"context",
                            :extra_params=>{:output=>"json"}
                            },
                   :alchemy=>{
                            :uri =>  "http://access.alchemyapi.com/calls/text/TextGetRankedKeywords",
                            :token_param => "apikey",
                            :extra_params=>{:outputMode => "json"}
                            },
                   :tagthe=>{:uri=>"http://tagthe.net/api",
                             :extra_params=>{:view=>"json"}
                            }
                  }

    tags_with :yahoo, Boilerplate[:yahoo] do |r|
        r['ResultSet']['ResultSet'] if r and r['ResultSet']
    end
    
    tags_with :alchemy, Boilerplate[:alchemy] do |resp|
        if resp['status'] != 'ERROR'
            #it's a hash array of [{:text=>"", :relevance=>""}]
            kws = []
            resp['keywords'].each do |m|
                kws.push m["text"]
            end
            kws
        end          
    end

    tags_with :tagthe, Boilerplate[:tagthe] do |resp|
        if resp.has_key?('memes') and resp['memes'][0].has_key?('dimensions') \
            and resp['memes'][0]['dimensions'].has_key?('topic')
            
            resp['memes'][0]['dimensions']['topic']
        end
    end
end #of webtagger module
