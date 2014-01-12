class GlobServer
  attr_accessor :files
  
  def initialize(args = {})
#    @server = args[:server] ||= "/Volumes/BigDrive"
    @server  = args[:server]  ||= "/var/smb/sdb1/photo"
    @folders = args[:folders] ||=  ['tmp'] 
    @exts    = args[:ext]     ||= ['jpg','jpeg','gif','png','bmp','JPG','JPEG','GIF','PNG','BMP']
    @files   = []
  end

  def media_glob
    @folders.each do |folder|
      @exts.each do |ext|
        Dir.glob("#{@server}/#{folder}/**/*.#{ext}") do |element|
          @files << {:path => element}
        end
      end
    end
  end
end
