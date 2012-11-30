class Page
  EOFLINE2 ="\n"
  SEPARATOR4="|"
  SEPARATOR2=";"
   attr :id_uri,
        :delay_from_start
   attr_writer :hostname,
               :page_path,
               :title


   def initialize(page)
     splitted_page = page.split(SEPARATOR4)
     @id_uri = splitted_page[0]
     @delay_from_start =  splitted_page[1]
   end

   def to_s(*a)
     page = "#{@id_uri}"
     page += "#{SEPARATOR4}#{@delay_from_start}" unless @delay_from_start.nil?
     page += "#{SEPARATOR4}#{@hostname}" unless @hostname.nil?
     page += "#{SEPARATOR4}#{@page_path}" unless @page_path.nil?
     page += "#{SEPARATOR4}#{@title}" unless @title.nil?
     page
   end


   def set_properties(pages_file)
     pages_file.rewind
     #p pages_file.lineno
     begin
       begin
         splitted_page = pages_file.readline(EOFLINE2).split(SEPARATOR2)
       end while @id_uri != splitted_page[0]
       @hostname = splitted_page[1].strip
       @page_path = splitted_page[2].strip
       @title = splitted_page[3].strip
     rescue Exception => e
       p "ERROR : #{e.message}=> id uri #{@id_uri} not found in pages_file"
       raise "errer"
     end
   end

   def to_json(*a)
     {
         "id_uri" => @id_uri,
         "delay_from_start" => @delay_from_start,
         "hostname" => @hostname,
         "page_path" => @page_path,
         "title" => @title
     }.to_json(*a)
   end
 end