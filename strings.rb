class String

   require 'iconv' 
   require 'open-uri'      # cf. http://www.ruby-doc.org/stdlib/libdoc/open-uri/rdoc/index.html

   # taken from: http://www.w3.org/International/questions/qa-forms-utf-8
   UTF8REGEX = /\A(?:                               # ?: non-capturing group (grouping with no back references)
                 [\x09\x0A\x0D\x20-\x7E]            # ASCII
               | [\xC2-\xDF][\x80-\xBF]             # non-overlong 2-byte
               |  \xE0[\xA0-\xBF][\x80-\xBF]        # excluding overlongs
               | [\xE1-\xEC\xEE\xEF][\x80-\xBF]{2}  # straight 3-byte
               |  \xED[\x80-\x9F][\x80-\xBF]        # excluding surrogates
               |  \xF0[\x90-\xBF][\x80-\xBF]{2}     # planes 1-3
               | [\xF1-\xF3][\x80-\xBF]{3}          # planes 4-15
               |  \xF4[\x80-\x8F][\x80-\xBF]{2}     # plane 16
               )*\z/mnx


#  create UTF-8 character arrays (as class instance variables)
#
#  mapping tables: - http://www.unicode.org/Public/UCA/latest/allkeys.txt
#                  - http://unicode.org/Public/UNIDATA/UnicodeData.txt 
#                  - http://unicode.org/Public/UNIDATA/CaseFolding.txt
#                  - http://www.decodeunicode.org 
#                  - ftp://ftp.mars.org/pub/ruby/Unicode.tar.bz2
#                  - http://camomile.sourceforge.net
#                  - Character Palette (Mac OS X)


   # test data
   @small_letters_utf8 = ["U+00F1", "U+00F4", "U+00E6", "U+00F8", "U+00E0", "U+00E1", "U+00E2", "U+00E4", "U+00E5", "U+00E7", "U+00E8", "U+00E9", "U+00EA", "U+00EB", "U+0153"].map { |x| u = [x[2..-1].hex].pack("U*"); u =~ UTF8REGEX ? u : nil }


   @capital_letters_utf8 = ["U+00D1", "U+00D4", "U+00C6", "U+00D8", "U+00C0", "U+00C1", "U+00C2", "U+00C4", "U+00C5", "U+00C7", "U+00C8", "U+00C9", "U+00CA", "U+00CB", "U+0152"].map { |x| u = [x[2..-1].hex].pack("U*"); u =~ UTF8REGEX ? u : nil }


   @other_letters_utf8 = ["U+03A3", "U+0639", "U+0041", "U+F8D0", "U+F8FF", "U+4E2D", "U+F4EE", "U+00FE", "U+10FFFF", "U+00A9", "U+20AC", "U+221E", "U+20AC", "U+FEFF", "U+FFFD", "U+00FF", "U+00FE", "U+FFFE", "U+FEFF"].map { |x| u = [x[2..-1].hex].pack("U*"); u =~ UTF8REGEX ? u : nil }

   if @small_letters_utf8.size != @small_letters_utf8.nitems then raise "Invalid UTF-8 char in @small_letters_utf8!" end
   if @capital_letters_utf8.size != @capital_letters_utf8.nitems then raise "Invalid UTF-8 char in @capital_letters_utf8!" end
   if @other_letters_utf8.size != @other_letters_utf8.nitems then raise "Invalid UTF-8 char in @other_letters_utf8!" end


   @unicode_array = []
   #open('http://unicode.org/Public/UNIDATA/UnicodeData.txt') do |f| f.each(nil) { |line| line.scan(/^[^;]+/) { |u| @unicode_array << u } }  end
   #open('http://unicode.org/Public/UNIDATA/UnicodeData.txt') do |f|                                                                               
   #   f.each do |line| line =~ /LATIN|GREEK|CYRILLIC/  ?  ( line.scan(/^[^;]+/) { |u| @unicode_array << u } )  :  next  end
   #end

   #@letters_utf8 = @unicode_array.map { |x| u = [x.hex].pack("U*"); u =~ UTF8REGEX ? u : nil }.compact   # code points from UnicodeData.txt
   @letters_utf8 = @small_letters_utf8 + @capital_letters_utf8 + @other_letters_utf8                      # test data only

   # Hash[*array_with_keys.zip(array_with_values).flatten]
   @downcase_table_utf8 = Hash[*@capital_letters_utf8.zip(@small_letters_utf8).flatten]
   @upcase_table_utf8 = Hash[*@small_letters_utf8.zip(@capital_letters_utf8).flatten]
   @letters_utf8_hash = Hash[*@letters_utf8.zip([]).flatten]    #=> ... "\341\272\242"=>nil ...

   class << self 
      attr_accessor :small_letters_utf8
      attr_accessor :capital_letters_utf8
      attr_accessor :other_letters_utf8
      attr_accessor :letters_utf8
      attr_accessor :letters_utf8_hash
      attr_accessor :unicode_array
      attr_accessor :downcase_table_utf8
      attr_accessor :upcase_table_utf8
   end


   def each_utf8_char
      scan(/./mu) { |c| yield c }
   end

   def each_utf8_char_with_index
      i = -1
      scan(/./mu) { |c| i+=1; yield(c, i) }
   end

   def length_utf8
      #scan(/./mu).size
      count = 0
      scan(/./mu) { count += 1 }
      count
   end
   alias :size_utf8 :length_utf8

   def reverse_utf8
      split(//mu).reverse.join
   end

   def reverse_utf8!
      split(//mu).reverse!.join
   end

   def swapcase_utf8
     gsub(/./mu) do |char|  
         if !String.downcase_table_utf8[char].nil? then String.downcase_table_utf8[char]
         elsif !String.upcase_table_utf8[char].nil? then String.upcase_table_utf8[char]
         else char.swapcase
         end
      end
   end

   def swapcase_utf8!
      gsub!(/./mu) do |char|  
         if !String.downcase_table_utf8[char].nil? then String.downcase_table_utf8[char]
         elsif !String.upcase_table_utf8[char].nil? then String.upcase_table_utf8[char]
         else ret = char.swapcase end
      end
   end

   def downcase_utf8
      gsub(/./mu) do |char|  
         small_char = String.downcase_table_utf8[char]
         small_char.nil? ? char.downcase : small_char
      end
   end

   def downcase_utf8!
      gsub!(/./mu) do |char|  
         small_char = String.downcase_table_utf8[char]
         small_char.nil? ? char.downcase : small_char
      end
   end

   def upcase_utf8
      gsub(/./mu) do |char|  
         capital_char = String.upcase_table_utf8[char]
         capital_char.nil? ? char.upcase : capital_char
      end
   end

   def upcase_utf8!
      gsub!(/./mu) do |char|  
         capital_char = String.upcase_table_utf8[char]
         capital_char.nil? ? char.upcase : capital_char
      end
   end

   def count_utf8(c)
      return nil if c.empty?
      r = %r{[#{c}]}mu
      scan(r).size
   end

   def delete_utf8(c)
      return self if c.empty?
      r = %r{[#{c}]}mu
      gsub(r, '')
   end

   def delete_utf8!(c)
      return self if c.empty?
      r = %r{[#{c}]}mu
      gsub!(r, '')
   end

   def first_utf8
      self[/\A./mu]
   end

   def last_utf8
      self[/.\z/mu]
   end

   def capitalize_utf8
     return self if self =~ /\A[[:space:]]*\z/m
     ret = ""
     split(/\x20/).each do |w| 
         count = 0
         w.gsub(/./mu) do |char|  
            count += 1
            capital_char = String.upcase_table_utf8[char]
            if count == 1 then 
               capital_char.nil? ? char.upcase : char.upcase_utf8
            else
               capital_char.nil? ? char.downcase : char.downcase_utf8
            end
         end
         ret << w + ' '
     end
     ret =~ /\x20\z/ ? ret.sub!(/\x20\z/, '') : ret  
   end

   def capitalize_utf8!
     return self if self =~ /\A[[:space:]]*\z/m 
     ret = ""
     split(/\x20/).each do |w| 
         count = 0
         w.gsub!(/./mu) do |char|  
            count += 1
            capital_char = String.upcase_table_utf8[char]
            if count == 1 then 
               capital_char.nil? ? char.upcase : char.upcase_utf8
            else
               capital_char.nil? ? char.downcase : char.downcase_utf8
            end
         end
         ret << w + ' '
     end
     ret =~ /\x20\z/ ? ret.sub!(/\x20\z/, '') : ret
   end


   def index_utf8(s)

      return nil unless !self.empty? && (s.class == Regexp || s.class == String)
      #raise(ArgumentError, "Wrong argument for method index_utf8!", caller) unless !self.empty? && (s.class == Regexp || s.class == String)

      if s.class == Regexp
         opts = s.inspect.gsub(/\A(.).*\1([eimnosux]*)\z/mu, '\2')
         if  opts.count('u') == 0 then opts = opts + "u" end
         str = s.source
         return nil if str.empty?
         str = "%r{#{str}}" + opts
         r = eval(str)
         l = ""
         sub(r) { l << $`; " " }  # $`: The string to the left of the last successful match (cf. http://www.zenspider.com/Languages/Ruby/QuickRef.html)
         l.empty? ? nil : l.length_utf8

      else

         return nil if s.empty?
         r = %r{#{s}}mu
         l = ""
         sub(r) { l << $`; " " }
         l.empty? ? nil : l.length_utf8

# this would be a non-regex solution
=begin 
         return nil if s.empty?
         return nil unless self =~ %r{#{s}}mu
         indices = []
         s.split(//mu).each do |x|
            ar = []
            self.each_utf8_char_with_index { |c,i| if c == x then ar << i end  }   # first get all matching indices c == x
            indices << ar unless ar.empty?
         end
         if indices.empty?
            return nil
         elsif indices.size == 1 
            indices.first.first
         else 
            #p indices
            ret = []
            a0 = indices.shift
            a0.each do |i|
               ret << i
               indices.each { |a| if a.include?(i+1) then i += 1; ret << i else ret = []; break end  }
               return ret.first unless ret.empty?
            end
            ret.empty? ? nil : ret.first
         end
=end

      end
   end   


   def rindex_utf8(s)

      return nil unless !self.empty? && (s.class == Regexp || s.class == String)
      #raise(ArgumentError, "Wrong argument for method index_utf8!", caller) unless !self.empty? && (s.class == Regexp || s.class == String)

      if s.class == Regexp
         opts = s.inspect.gsub(/\A(.).*\1([eimnosux]*)\z/mu, '\2')
         if  opts.count('u') == 0 then opts = opts + "u" end
         str = s.source
         return nil if str.empty?
         str = "%r{#{str}}" + opts
         r = eval(str)
         l = ""
         scan(r) { l = $` }  
         #gsub(r) { l = $`; " " }  
         l.empty? ? nil : l.length_utf8
      else
         return nil if s.empty?
         r = %r{#{s}}mu
         l = ""
         scan(r) { l = $` }  
         #gsub(r) { l = $`; " " }
         l.empty? ? nil : l.length_utf8
      end

   end   


   # note that the i option does not work in special cases with back references
   # example: "àÀ".slice_utf8(/(.).*?\1/i) returns nil whereas "aA".slice(/(.).*?\1/i) returns "aA"
   def slice_utf8(regex)   
      opts = regex.inspect.gsub(/\A(.).*\1([eimnosux]*)\z/mu, '\2')
      if  opts.count('u') == 0 then opts = opts + "u" end
      s = regex.source
      str = "%r{#{s}}" + opts
      r = eval(str)
      slice(r)
   end

   def slice_utf8!(regex)   
      opts = regex.inspect.gsub(/\A(.).*\1([eimnosux]*)\z/mu, '\2')
      if  opts.count('u') == 0 then opts = opts + "u" end
      s = regex.source
      str = "%r{#{s}}" + opts
      r = eval(str)
      slice!(r)
   end

   def cut_utf8(p,l)    # (index) position, length
      raise(ArgumentError, "Error: argument is not Fixnum", caller) if p.class != Fixnum or l.class != Fixnum
      s = self.length_utf8
      #if p < 0 then p = s - p.abs end
      if p < 0 then p.abs > s ? (p = 0) : (p = s - p.abs) end      #  or:  ... p.abs > s ? (return nil) : ...
      return nil if l > s or p > (s - 1)
      ret = ""
      count = 0
      each_utf8_char_with_index do |c,i| 
         break if count >= l
         if i >= p && count < l then count += 1; ret << c; end
      end
      ret
   end

   def starts_with_utf8?(s)
      return nil if self.empty? or s.empty?
      cut_utf8(0, s.size_utf8) == s 
   end

   def ends_with_utf8?(s)
      return nil if self.empty? or s.empty?
      cut_utf8(-(s.size_utf8), s.size_utf8) == s
   end

   def insert_utf8(i,s)                                  # insert_utf8(index, string)
      return self if s.empty?
      l = self.length_utf8
      if l == 0 then return s end
      if i < 0 then i.abs > l ? (i = 0) : (i = l - i.abs) end          #  or:  ... i.abs > l ? (return nil) : ...
      #return nil if i > (l - 1)                         # return nil ...
      spaces = ""
      if i > (l-1) then spaces = " " * (i - (l-1)) end   # ... or add spaces
      str = self << spaces
      s1 = str.cut_utf8(0, i)
      s2 = str.cut_utf8(i, l - s1.length_utf8)
      s1 << s << s2
   end

   def split_utf8(regex)
      opts = regex.inspect.gsub(/\A(.).*\1([eimnosux]*)\z/mu, '\2')
      if  opts.count('u') == 0 then opts = opts + "u" end
      s = regex.source
      str = "%r{#{s}}" + opts
      r = eval(str)
      split(r)
   end

   def scan_utf8(regex)
      opts = regex.inspect.gsub(/\A(.).*\1([eimnosux]*)\z/mu, '\2')
      if  opts.count('u') == 0 then opts = opts + "u" end
      s = regex.source
      str = "%r{#{s}}" + opts
      r = eval(str)
      if block_given? then scan(r) { |a,*m| yield(a,*m) } else scan(r) end
   end

   def range_utf8(r)

      return nil if r.class != Range
      #raise(ArgumentError, "No Range object given!", caller) if r.class != Range

      a = r.to_s[/^[\+\-]?\d+/].to_i
      b = r.to_s[/[\+\-]?\d+$/].to_i
      d = r.to_s[/\.+/]

      if d.size == 2 then d = 2 else d = d.size end 

      l = self.length_utf8

      return nil if b.abs > l || a.abs > l || d < 2 || d > 3

      if a < 0 then a = l - a.abs end
      if b < 0 then b = l - b.abs end
      
      return nil if a > b

      str = ""

      each_utf8_char_with_index do |c,i|
         break if i > b
         if d == 2
            (i >= a && i <= b) ? str << c : next
         else
            (i >= a && i < b) ? str << c : next
         end
      end

      str

   end
 
   def utf8?
     self =~ UTF8REGEX
   end

   def clean_utf8
       t = ""
       self.scan(/./um) { |c| t << c if c =~ UTF8REGEX }
       t
   end


   def utf8_encoded_file?   # check (or rather guess) if (HTML) file encoding is UTF-8 (experimental, so use at your own risk!)

      file = self
      str = ""

      if file =~ /^http:\/\//

         url = file

         if RUBY_PLATFORM =~ /darwin/i   # Mac OS X 10.4.10
          
            seconds = 30  

            # check if web site is reachable
            # on Windows try to use curb, http://curb.rubyforge.org (sudo gem install curb)
            var = %x{ /usr/bin/curl -I -L --fail --silent --connect-timeout #{seconds} --max-time #{seconds+10} #{url}; /bin/echo -n $? }.to_i

            #return false unless var == 0
            raise "Failed to create connection to web site: #{url}  --  curl error code: #{var}  --  " unless var == 0

            str = %x{ /usr/bin/curl -L --fail --silent --connect-timeout #{seconds} --max-time #{seconds+10} #{url} | \
                      /usr/bin/grep -Eo -m 1 \"(charset|encoding)=[\\"']?[^\\"'>]+\" | /usr/bin/grep -Eo \"[^=\\"'>]+$\" }
            p str
            return true if str =~ /utf-?8/i
            return false if !str.empty? && str !~ /utf-?8/i

            # solutions with downloaded file

            # download HTML file
            #downloaded_file = "/tmp/html"
            downloaded_file = "~/Desktop/html"
            downloaded_file = File.expand_path(downloaded_file)
            %x{ /usr/bin/touch #{downloaded_file} 2>/dev/null }
            raise "No valid HTML download file (path) specified!" unless File.file?(downloaded_file)
            %x{ /usr/bin/curl -L --fail --silent --connect-timeout #{seconds} --max-time #{seconds+10} -o #{downloaded_file} #{url} }
            
            simple_test = %x{ /usr/bin/file -ik #{downloaded_file} }    #  cf. man file
            p simple_test 

            # read entire file into a string
            File.open(downloaded_file).read.each(nil) do |str| 
               #return true if str =~ /(charset|encoding) *= *["']? *utf-?8/i
               str.utf8? ? (return true) : (return false) 
            end 

            #check each line of the downloaded file
            #count_lines = 0
            #count_utf8 = 0
            #File.foreach(downloaded_file) { |line| return true if line =~ /(charset|encoding) *= *["']? *utf-?8/i; count_lines += 1;  count_utf8 += 1 if line.clean_utf8.utf8?; break if count_lines != count_utf8 }
            #count_lines == count_utf8 ? (return true) : (return false)
            

            # in-memory solutions

            #html_file_cleaned_utf8 = %x{ /usr/bin/curl -L --fail --silent --connect-timeout #{seconds} --max-time #{seconds+10} #{url} }.clean_utf8
            #p html_file_cleaned_utf8.utf8?

            count_lines = 0
            count_utf8 = 0
            #%x{ /usr/bin/curl -L --fail --silent --connect-timeout #{seconds} --max-time #{seconds+10} #{url} }.each(nil) do |line|    # read entire file into string
            %x{ /usr/bin/curl -L --fail --silent --connect-timeout #{seconds} --max-time #{seconds+10} #{url} }.each('\n') do |line| 
               #return true if line =~ /(charset|encoding) *= *["']? *utf-?8/i
               count_lines += 1 
               count_utf8 += 1 if line.utf8?
               break if count_lines != count_utf8
            end
            count_lines == count_utf8 ? (return true) : (return false)

         else

            # check each line of the HTML file (or the entire HTML file at once)
            # cf. http://www.ruby-doc.org/stdlib/libdoc/open-uri/rdoc/index.html
            count_lines = 0
            count_utf8 = 0
            open(url) do |f|   
               # p f.meta, f.content_encoding, f.content_type
               cs = f.charset
               return true if cs =~ /utf-?8/i
               #f.each(nil) do |str| str.utf8? ? (return true) : (return false) end  # read entire file into string
               f.each_line do |line| 
                  count_lines += 1 
                  count_utf8 += 1 if line.utf8?
                  break unless count_lines == count_utf8
               end
            end
            count_lines == count_utf8 ? (return true) : (return false)

         end

      else

         return false unless File.file?(file)

         if RUBY_PLATFORM =~ /darwin/i then str = %x{ /usr/bin/file -ik #{file} }; return true if str =~ /utf-?8/i end

         # read entire file into a string
         #File.open(file).read.each(nil) do |str| return true if str =~ /(charset|encoding) *= *["']? *utf-?8/i; str.utf8? ? (return true) : (return false) end 

         # check each line of the file
         count_lines = 0
         count_utf8 = 0
         File.foreach(file) do |line| 
            return true if line =~ /(charset|encoding) *= *["']? *utf-?8/i
            count_lines += 1;  
            count_utf8 += 1 if line.utf8?; 
            break if count_lines != count_utf8 
         end

         count_lines == count_utf8 ? (return true) : (return false)
         
      end   

      str =~ /utf-?8/i ? true : false

   end


   # cf. Paul Battley, http://po-ru.com/diary/fixing-invalid-utf-8-in-ruby-revisited/
   def validate_utf8
      Iconv.iconv('UTF-8//IGNORE', 'UTF-8', (self + ' ') ).first[0..-2]
   end

   # cf. Paul Battley, http://www.ruby-forum.com/topic/70357
   def asciify_utf8
       return nil unless self.utf8?
       #Iconv.iconv('US-ASCII//IGNORE//TRANSLIT', 'UTF-8', (self + ' ') ).first[0..-2]
       # delete all punctuation characters inside words except "-" in words such as up-to-date
       Iconv.iconv('US-ASCII//IGNORE//TRANSLIT', 'UTF-8', (self + ' ') ).first[0..-2].gsub(/(?!-.*)\b[[:punct:]]+\b/, '')
   end

   def latin1_to_utf8     # ISO-8859-1 to UTF-8
      ret = Iconv.iconv("UTF-8//IGNORE", "ISO-8859-1", (self + "\x20") ).first[0..-2]
      ret.utf8? ? ret : nil
   end

   def cp1252_to_utf8     # CP1252 (WINDOWS-1252) to UTF-8
      ret = Iconv.iconv("UTF-8//IGNORE", "CP1252", (self + "\x20") ).first[0..-2]
      ret.utf8? ? ret : nil
   end

   # cf. Paul Battley, http://www.ruby-forum.com/topic/70357 
   def utf16le_to_utf8
       ret = Iconv.iconv('UTF-8//IGNORE', 'UTF-16LE', (self[0,(self.length/2*2)] + "\000\000") ).first[0..-2]
       ret =~ /\x00\z/ ?  ret.sub!(/\x00\z/, '') : ret
       ret.utf8? ? ret : nil
   end

   def utf8_to_utf16le
      return nil unless self.utf8?
      ret = Iconv.iconv('UTF-16LE//IGNORE', 'UTF-8', self ).first
   end

   def utf8_to_unicode
      return nil unless self.utf8?
      str = ""
      scan(/./mu) { |c| str << "U+" << sprintf("%04X", c.unpack("U*").first) }
      str
   end

   def unicode_to_utf8
      return self if self =~ /\A[[:space:]]*\z/m
      str = ""
      #scan(/U\+([0-9a-fA-F]{4,5}|10[0-9a-fA-F]{4})/) { |u| str << [u.first.hex].pack("U*") }
      #scan(/U\+([[:digit:][:xdigit:]]{4,5}|10[[:digit:][:xdigit:]]{4})/) { |u| str << [u.first.hex].pack("U*") }
      scan(/(U\+(?:[[:digit:][:xdigit:]]{4,5}|10[[:digit:][:xdigit:]]{4})|.)/mu) do        # for mixed strings such as "U+00bfHabla espaU+00f1ol?"
         c = $1
         if c =~ /^U\+/
            str << [c[2..-1].hex].pack("U*")
         else
            str << c
         end       
      end
      str.utf8? ? str : nil
   end


   # dec, hex, oct conversions (experimental!)

   def utf8_to_dec
      return nil unless self.utf8?
      str = ""
      scan(/./mu) do |c| 
         if c =~ /^\x00$/
            str << "aaa\x00"  # encode \x00 as "aaa"
         else
            str << sprintf("%04X", c.unpack("U*").first).hex.to_s << "\x00"   # convert to decimal
         end
      end     
      str[0..-2]
   end

   def dec_to_utf8   # \x00 is encoded as "aaa"
      return self if self.empty?
      return nil unless self =~ /\A[[:digit:]]+\x00/ && self =~ /\A[a[:digit:]\x00]+\z/
      str = ""
      split(/\x00/).each do |c|
         if c.eql?("aaa")
            str << "\x00"
         else
            str << [c.to_i].pack("U*")
         end
      end
      str
   end


   def utf8_to_dec_2
      return nil unless self.utf8?
      str = ""
      tmpstr = ""
      null_str = "\x00"
      scan(/./mu) do |c| 
         if c =~ /^\x00$/
            str << "aaa\x00\x00"  # encode \x00 as "aaa"
         else
            tmpstr = ""
            c.each_byte { |x| tmpstr << x.to_s << null_str }      # convert to decimal
            str << tmpstr << null_str
         end
      end     
      str[0..-3]
   end

   def dec_to_utf8_2   # \x00 is encoded as "aaa"
      return self if self.empty?
      return nil unless self =~ /\A[[:digit:]]+\x00/ && self =~ /[[:digit:]]+\x00\x00/ && self =~ /\A[a[:digit:]\x00]+\z/
      str = ""
      split(/\x00\x00/).each do |c|
         if c =~ /\x00/
            c.split(/\x00/).each { |x| str << x.to_i.chr }
         elsif c.eql?("aaa")
            str << "\x00"
         else
            str << c.to_i.chr
         end
      end
      str
   end


   def utf8_to_hex
      return nil unless self.utf8?
      str = ""
      tmpstr = ""
      null_str = "\x00"
      scan(/./mu) do |c| 
         if c =~ /^\x00$/
            str << "aaa\x00\x00"    # encode \x00 as "aaa"
         else
            tmpstr = ""
            c.each_byte { |x| tmpstr << sprintf("%X", x) << null_str }      # convert to hexadecimal
            str << tmpstr << null_str
         end
      end     
      str[0..-3]
   end

   def hex_to_utf8   # \x00 is encoded as "aaa"
      return self if self.empty?
      return nil unless self =~ /\A[[:xdigit:]]+\x00/ && self =~ /[[:xdigit:]]+\x00\x00/ && self =~ /\A[a[:xdigit:]\x00]+\z/
      str = ""
      split(/\x00\x00/).each do |c|
         if c =~ /\x00/
            c.split(/\x00/).each { |x| str << x.hex.chr }
         elsif c.eql?("aaa")
            str << "\x00"
         else
            str << c.hex.chr
         end
      end
      str
   end


   def utf8_to_oct
      return nil unless self.utf8?
      str = ""
      tmpstr = ""
      null_str = "\x00"
      scan(/./mu) do |c| 
         if c =~ /^\x00$/
            str << "aaa\x00\x00"   # encode \x00 as "aaa"
         else
            tmpstr = ""
            c.each_byte { |x| tmpstr << sprintf("%o", x) << null_str }      # convert to octal
            str << tmpstr << null_str
         end
      end     
      str[0..-3]
   end

   def oct_to_utf8   # \x00 is encoded as "aaa"
      return self if self.empty?
      return nil unless self =~ /\A[[:digit:]]+\x00/ && self =~ /[[:digit:]]+\x00\x00/ && self =~ /\A[a[:digit:]\x00]+\z/
      str = ""
      split(/\x00\x00/).each do |c|
         if c =~ /\x00/
            c.split(/\x00/).each { |x| str << x.oct.chr }
         elsif c.eql?("aaa")
            str << "\x00"
         else
            str << c.oct.chr
         end
      end
      str
   end

   # cf. http://node-0.mneisen.org/2007/03/13/email-subjects-in-utf-8-mit-ruby-kodieren/
   def email_subject_utf8
      return nil unless self.utf8?
      "=?utf-8?b?#{[self].pack("m").delete("\n")}?="
   end

end


puts
puts String.downcase_table_utf8.to_s

#puts String.letters_utf8.to_s
#String.letters_utf8.each { |c| puts "#{c.inspect} ::  #{c}" }

str = "Œuvres Complètes"
str = "Œuvres \000Complètes"

puts
str = str.validate_utf8; p str
str = str.clean_utf8; p str
str.utf8?  ? "#{str}: UTF-8 string seems OK!\n".display : "#{str}: No valid UTF-8 string!\n".display
puts str.asciify_utf8

puts
str_in_utf8 = "\303\251"
print "UTF-16:   "; p Iconv.iconv('UTF-16', 'UTF-8', str_in_utf8 ).first
print "UTF-16BE: "; p Iconv.iconv('UTF-16BE', 'UTF-8', str_in_utf8 ).first
print "UTF-16LE: "; p str_in_utf8.utf8_to_utf16le
str_in_utf16le = "c\000a\000f\000\351\000"
puts str_in_utf16le.utf16le_to_utf8
puts str_in_utf16le.utf16le_to_utf8.asciify_utf8

puts
puts str.upcase_utf8
puts str.downcase_utf8
puts str.capitalize_utf8
puts str.capitalize_utf8!
puts str.swapcase_utf8
puts "àcA绋féà".swapcase_utf8
puts "àcA绋féà".swapcase_utf8!

puts
puts str.slice_utf8(/../i)
puts str.slice_utf8(/(.).*?\1/i)
puts "àÀ".slice_utf8(/(.).*?\1/i)   # => nil despite the i option!
puts "aA".slice(/(.).*?\1/i)        # => aA
puts "àÀ àÀ".slice_utf8!(/([àÀ]).*?\1/i)
puts "àÀ àÀ".slice_utf8!(/(.).*?\1/ium)
puts "绋 àÀ 绋 àÀ".slice_utf8!(/(.).*?\1/ium)

puts
str.capitalize_utf8.each_utf8_char_with_index { |c,i| puts "#{i}: #{c}" }

puts
puts str.range_utf8(0..2)
puts str.range_utf8(0..-2)
puts str.range_utf8(-4..-1)
puts str.range_utf8(-3..-1)
puts str.range_utf8(-3...-1)
puts str.range_utf8([-3..-1])

puts
p str.scan_utf8(/./)
"àcA绋féà".scan_utf8(/./) { |c| puts c }
"àcA绋féà".scan_utf8(/(.)(.)?/) { |a,b| print a,b,"\n" }

puts
p "àcA绋féà".index_utf8('绋')
p "àcA绋féà".index_utf8('绋f')
p "àcA绋féà".index_utf8('z')
p "kféà 绋f àc 绋 9h绋!fz A绋kféà 绋f 9绋!fz".index_utf8('9绋!fz')
p "kféà 绋f àc 绋 9h绋!fz A绋kféà 绋f 9绋!ofz 9绋!fz".index_utf8(/9绋!fz/)
p "kféà 绋f àc 绋 9绋!fz A绋kféà 绋f 9绋!ofz 9绋!fz kféà 绋f àc 绋 9h绋!fz 9绋!fz A绋kféà 绋f".index_utf8(//)

puts
p "kféà 绋f àc 绋 9绋!fz A绋kféà 绋f 9绋!ofz 9绋!fz kféà 绋f àc 绋 9h绋!fz 9绋!fz A绋kféà 绋f".rindex_utf8('9绋!fz')
p "kféà 绋f àc 绋 9绋!fz A绋kféà 绋f 9绋!ofz 9绋!fz kféà 绋f àc 绋 9h绋!fz 9绋!fz A绋kféà 绋f".rindex_utf8(/9绋!fz/)
p "kféà 绋f àc 绋 9绋!fz A绋kféà 绋f 9绋!ofz 9绋!fz kféà 绋f àc 绋 9h绋!fz 9绋!fz A绋kféà 绋f".rindex_utf8(/9..fz/)
p "kféà 绋f àc 绋 9绋!fz A绋kféà 绋f 9绋!ofz 9绋!fz kféà 绋f àc 绋 9h绋!fz 9绋!fz A绋kféà 绋f".rindex_utf8(//)

puts
puts "àcA绋féà".utf8_to_utf16le.utf16le_to_utf8
puts "àcA绋féà".utf8_to_utf16le.utf16le_to_utf8.asciify_utf8
puts "àÀ".slice_utf8(/../i)
puts "àÀ".slice_utf8!(/../i)

puts "绋 àÀ 绋 àÀ".count_utf8('绋')
puts "绋 àÀ 绋 àÀ".count_utf8('àÀ')
puts "绋 àÀ 绋 àÀ".count_utf8('z')
puts "绋 àÀ/ ^绋 àÀ".count_utf8('/绋^')
puts "绋 àÀ/ ^绋 àÀ".count_utf8('^/绋^')  # count all chars except those specified; note that the leading ^ will result in the regex: /[^\/绋^]/u

puts
puts "绋 àÀ 绋 àÀ".delete_utf8('àÀ ')
puts "绋 àÀ 绋 àÀ 绋 àÀ 绋 àÀ".delete_utf8!('ɟ绋à æ¥')

puts str.cut_utf8(0,5)
puts str.cut_utf8(-5,5)
puts str.cut_utf8(-10,50)

puts str.length_utf8
puts str.size_utf8

puts
puts "绋 àÀ 绋 àÀ".first_utf8
puts "绋 àÀ 绋 àÀ".last_utf8
p "绋 àÀ 绋 àÀ\n".last_utf8
puts "".first_utf8

puts "绋 àÀ 绋 àÀ".starts_with_utf8?('绋')
puts "绋 àÀ 绋 àÀ".ends_with_utf8?('k')
puts "".ends_with_utf8?('k')
puts "绋 àÀ 绋 àÀ".ends_with_utf8?('')
puts "绋 àÀ 绋 à".starts_with_utf8?('绋 àÀ 绋 àÀ')

puts "绋 àÀ 绋 à".insert_utf8(20, "abc")
puts "绋àÀ绋à".insert_utf8(2, "abc")
puts "绋àÀ绋à".insert_utf8(-2, "abc")
puts "绋àÀ绋à".insert_utf8(-200, "abc")
puts "绋àÀ绋à".insert_utf8(200, "abc")

puts
p "Hello, world!".utf8_to_unicode
p "绋àÀ绋à".utf8_to_unicode
p "绋àÀ绋à𐍆".utf8_to_unicode

puts "Hello, world!".utf8_to_unicode.unicode_to_utf8
puts "绋àÀ绋à𐍆".utf8_to_unicode.unicode_to_utf8
puts "绋àÀ绋à𐍆".size_utf8

puts
encoded_file = "/ISO-8859-Latin-1.txt"
encoded_file = "/cp1252.txt"

File.open(encoded_file).read.each(nil) do |str| 
   p str
   #str = str.latin1_to_utf8
   str = str.cp1252_to_utf8
   p str
   puts str
   str.utf8? ? (puts "UTF-8 conversion - YES") : (puts "UTF-8 conversion - NO") 
end 

puts
puts "U+00bfHabla espaU+00f1ol?".unicode_to_utf8

# cf. http://www.decodeunicode.org/en/miscellaneous_symbols
code_points = <<-EOS
U+2603   SNOWMAN
U+2708   AIRPLANE
U+00a9   COPYRIGHT SIGN
U+2615   HOT BEVERAGE
U+2602   UMBRELLA
U+2614   UMBRELLA WITH RAIN DROPS
U+261D   WHITE UP POINTING INDEX
U+2620   SKULL AND CROSSBONES
U+262F   YIN YANG
U+262E   PEACE SYMBOL
U+263A   WHITE SMILING FACE
EOS

puts code_points.unicode_to_utf8

# see:
# - http://intertwingly.net/stories/2004/04/14/i18n.html (Iñtërnâtiônàlizætiøn)
# - http://www.intertwingly.net/blog/1763.html (Unicode and weblogs)
# - http://www.intertwingly.net/blog/1768.html (UTF-8 musings)

puts "Iñtërnâtiônàlizætiøn".asciify_utf8
puts "Iñtërnâtiônàlizætiøn".utf8_to_unicode
puts "Iñtërnâtiônàlizætiøn".utf8_to_unicode.unicode_to_utf8
puts "Iñtërnâtiônàlizætiøn".size_utf8
puts "Iñtërnâtiônàlizætiøn".upcase_utf8

puts
# NOTE: To convert the following UTF-8 strings containing a \x00 to dec, hex or oct you have to add \x00 to UTF8REGEX:  [\x00\x09\x0A\x0D\x20-\x7E]            # ASCII 
p "Iñtërnâtiônàlizætiø\x00n".utf8_to_dec
puts "Iñtërnâtiônàlizætiø\x00n".utf8_to_dec
p "Iñtërnâtiônàlizætiø\x00n".utf8_to_dec.dec_to_utf8
puts "Iñtërnâtiônàlizætiø\x00n".utf8_to_dec.dec_to_utf8

puts
p "Iñtërnâtiônàlizætiø\x00n".utf8_to_hex
puts "Iñtërnâtiônàlizætiø\x00n".utf8_to_hex
p "Iñtërnâtiônàlizætiø\x00n".utf8_to_hex.hex_to_utf8
puts "Iñtërnâtiônàlizætiø\x00n".utf8_to_hex.hex_to_utf8
    
puts
p "Iñtërnâtiônàlizætiø\x00n".utf8_to_oct
puts "Iñtërnâtiônàlizætiø\x00n".utf8_to_oct
p "Iñtërnâtiônàlizætiø\x00n".utf8_to_oct.oct_to_utf8
puts "Iñtërnâtiônàlizætiø\x00n".utf8_to_oct.oct_to_utf8

puts
puts '"Hello, world" in Portuguese: "Olá Mundo" or "Alô Mundo" (Português)'.email_subject_utf8

puts
file = "http://www.ruby-forum.com"
file = "http://blade.nagaokaut.ac.jp"
file = "http://blade.nagaokaut.ac.jp/ruby/ruby-talk/index.shtml"
file = "http://www.columbia.edu/kermit/utf8.html"   #  UTF-8 SAMPLER

p file.utf8_encoded_file?


require 'open-uri'  
  
# UnicodeData.txt
unicode_array = []

open('http://unicode.org/Public/UNIDATA/UnicodeData.txt') do |f| 
   #f.each(nil) do |line| line.scan(/^[^;]+/) { |u| unicode_array << u } end       # all code points
   f.each do |line| line =~ /LATIN|GREEK|CYRILLIC/ ?  ( line.scan(/^[^;]+/) { |u| unicode_array << u } ) : next end
end
unicode_array.each { |x| u = [x.hex].pack("U*"); u.utf8? ? (puts "U+#{x} ::  #{u.inspect}  ::  #{u}") : (puts "U+#{x} ::  #{u.inspect}  ::  #{u}  :: NO!") } 


class Array
   def dups_indices   # cf. http://www.ruby-forum.com/topic/122008 and http://snippets.dzone.com/posts/show/4148
      (0...self.size).to_a - self.uniq.map{ |x| index(x) }
   end
end

#  CaseFolding.txt
capital_letters_utf8 = []
small_letters_utf8 = []

open('http://www.unicode.org/Public/UNIDATA/CaseFolding.txt') do |f| 
   f.each do |line| 
      if line =~ /.*/ 
      #if line =~ /LATIN|GREEK|CYRILLIC/ 
         line.scan(/^([^;#]+); +\S+ ([^;\s]+)/) { capital_letters_utf8 << [$1.hex].pack("U*"); small_letters_utf8 << [$2.hex].pack("U*") }
      end
   end
end

puts small_letters_utf8.size, capital_letters_utf8.size
deleted_pairs = []
small_letters_utf8.dups_indices.reverse.each do |i|   # small_letters_utf8 will be array_with_keys below
   deleted_pairs << [small_letters_utf8.at(i), capital_letters_utf8.at(i)]
   small_letters_utf8.delete_at(i); capital_letters_utf8.delete_at(i)
end
puts small_letters_utf8.size, capital_letters_utf8.size

# Hash[*array_with_keys.zip(array_with_values).flatten]
upcase_table_utf8 = Hash[*small_letters_utf8.zip(capital_letters_utf8).flatten]
#upcase_table_utf8.each_pair { |k,v| puts "#{k} :: #{v}" }

puts upcase_table_utf8["a"]
puts upcase_table_utf8["ẚ"]
puts upcase_table_utf8.value?("A")

deleted_pairs.each { |s,c| puts "deleted:  #{s}   ::   #{c}" }

upcase_table_utf8.size.times do |i|
#20.times do |i|
   puts "array index #{i}  ::  #{small_letters_utf8.at(i)}  ::  #{capital_letters_utf8.at(i)}"
end

