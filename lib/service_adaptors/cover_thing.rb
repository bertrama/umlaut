# Find book covers from LibraryThing's CoverThing service.
# Only fetches "medium" size image. Fetches only by ISBN. 

class CoverThing < Service
  require 'net/http'
  include MetadataHelper
  required_config_params :developer_key

  def service_types_generated
    return [ ServiceTypeValue[:cover_image] ]       
  end
  
  def initialize(config)
    @display_name = "LibraryThing"
    # http://covers.librarything.com/devkey/KEY/medium/isbn/0545010225
    @base_url = 'http://covers.librarything.com/devkey/';
    super(config)
  end
  
  def handle(request)
    image_url = image_url(request.referent)
    return request.dispatched(self, true) unless image_url

    uri = URI.parse(image_url)
    response = nil
    # All we need is a HEAD request to check content-length. 
    Net::HTTP.start(uri.host, uri.port) {|http|
      response = http.head(uri.path)
    }
    
    # Only way to know if we got an image or a transparent placeholder
    # is to check the content-length. Currently the transparent placeholder
    # is 43 bytes.
    unless (response.content_length < 50)
      request.add_service_response({
        :service=>self, 
        :display_text => 'Cover Image',
        :key=> 'medium', 
        :url => image_url, 
        :service_data => {:size => 'medium' }
      },
      [ServiceTypeValue[:cover_image]])
    end
    
  end
  
 def image_url(referent)
   isbn = get_identifier(:urn, "isbn", referent)
   isbn.gsub!(/[^\d]/, '') # just numeric isbn
   return nil if isbn.blank? # need an isbn to make the request
   
   return @base_url + @developer_key + '/medium/isbn/' + isbn
 end
  

end