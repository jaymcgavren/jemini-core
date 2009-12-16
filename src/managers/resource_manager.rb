require 'resource'

class ResourceManager < Jemini::GameObject
  java_import 'org.newdawn.slick.Image'
  java_import 'org.newdawn.slick.Music'
  java_import 'org.newdawn.slick.Sound'
  
  #Sets a default data directory path of "data".
  def load
    enable_listeners_for :resources_loaded
    @configs = {}
    @images = {}
    @sounds = {}
    @songs = {}
  end
  
  #Load resources for the given state.
  #Uses the current state if none specified.
  def load_resources(state_name = nil)
    state_name ||= game_state.name
    log.debug "Loading resources for state: #{state_name}"
    subdirectory = File.join(Jemini::Resource.base_path, state_name)
    log.debug "Looking for subdirectory: #{subdirectory}"
    load_directory(subdirectory) if File.directory?(subdirectory) || File.in_jar?(subdirectory)
    load_directory(Jemini::Resource.base_path, true)
    notify :resources_loaded
  end
  
  #Load the config at the given path, and make it accessible via the given key.
  def cache_config(key, path)
    log.debug "Caching config for #{key} with path: #{path}"
    log.warn "Skipping duplicate config for #{key} with path: #{path}" and return if @configs[key]
    @configs[key] = load_resource(path, :config)
  end
  
  #Load the image at the given path, and make it accessible via the given key.
  def cache_image(key, path)
    log.debug "Caching image for #{key} with path: #{path}"
    log.warn "Skipping duplicate image for #{key} with path: #{path}" and return if @images[key]
    @images[key] = load_resource(path, :image)
  end
  
  #Load the sound at the given path, and make it accessible via the given key.
  def cache_sound(key, path)
    log.debug "Caching sound for #{key} with path: #{path}"
    log.warn "Skipping duplicate sound for #{key} with path: #{path}" and return if @sounds[key]
    @sounds[key] = load_resource(path, :sound)
  end
  
  #Load the song at the given path, and make it accessible via the given key.
  def cache_song(key, path)
    log.debug "Caching song for #{key} with path: #{path}"
    log.warn "Skipping duplicate song for #{key} with path: #{path}" and return if @songs[key]
    @songs[key] = load_resource(path, :music)
  end
  
  #Get a config stored previously with cache_config.
  def get_config(key)
    @configs[key] or raise "Could not find config: #{key} - cached configs: #{@configs.keys}"
  end
  alias_method :config, :get_config
  
  #Get all configs stored previously with cache_config.
  def get_all_configs
    @configs.values
  end
  alias_method :configs, :get_all_configs

  def config_names
    @configs.keys
  end
  
  #Get an image stored previously with cache_image.
  def get_image(key)
    @images[key] or raise "Could not find image: #{key} - cached images: #{@images.keys}"
  end
  alias_method :image, :get_image
  
  #Get all images stored previously with cache_image.
  def get_all_images
    @images.values
  end
  alias_method :images, :get_all_images

  def image_names
    @images.keys
  end
  
  #Get a sound stored previously with cache_sound.
  def get_sound(key)
    @sounds[key] or raise "Could not find sound: #{key}"
  end
  alias_method :sound, :get_sound
  
  #Get all sounds stored previously with cache_sound.
  def get_all_sounds
    @sounds.values
  end
  alias_method :sounds, :get_all_sounds
  
  #Get a song stored previously with cache_song.
  def get_song(key)
    @songs[key] or raise "Could not find song: #{key}"
  end
  alias_method :song, :get_song
  
  #Get all songs stored previously with cache_song.
  def get_all_songs
    @songs.values
  end
  alias_method :songs, :get_all_songs

private

  def load_resource(path, type_name)
    # due to some JRuby trickery involved with java_import, we can't use metaprogramming tricks here.
    case type_name
    when :config
      File.read(Jemini::Resource.path_of(path))
    when :image
      Image.new(Jemini::Resource.path_of(path))
    when :sound
      Sound.new(Jemini::Resource.path_of(path))
    when :music
      Music.new(Jemini::Resource.path_of(path))
    end
  end

  # root dirs can't be skipped
  def load_directory(directory, root = false)
    log.debug "Loading contents of #{directory}"
    begin
      resources_for(directory).each do |file|
        next if file =~ /^\./
        path = File.in_jar?(directory) ? file : File.join(directory, file)
        log.debug "Dir in jar? #{File.in_jar?(directory)}"
        log.debug "Using path #{path} for #{file}"
        extension = File.extname(file).downcase
        key = File.basename(file, extension).downcase.to_sym
        log.debug "Extension: #{extension}"
        case extension
        when '.png', '.gif'
          cache_image(key, path)
        when '.wav'
          cache_sound(key, path)
        when '.ogg'
          cache_song(key, path)
        when '.ini'
          cache_config(key, path)
        else
          log.warn "Skipping unknown file: #{path}"
        end
      end
    rescue Errno::ENOENT => e
      if root
        raise
      else
        log.debug "#{directory} directory not found. Skipping."
      end
    end
  end

  def resources_for(directory)
    if File.in_jar?(directory)
      scan_entire_jar(directory)
    else
      log.debug "opening #{directory}"
      Dir.open(directory)
    end
  end

  # globs MUST start at the base dir of the jar, or it won't work.
  def scan_entire_jar(directory)
    just_dir = File.basename(directory)
    log.debug "just dir: #{just_dir}"
    log.debug "dir:      #{directory}"
    jar_name = File.jar_of(directory, 'data') # we're always going to get our data from the data jar
    log.debug "opening jar #{jar_name}"
    jar_file = java.util.jar.JarFile.new(jar_name)
    dir_regex = Regexp.new(just_dir)
    all_entries = jar_file.entries.map {|e| e.name }
    entries_under_directory = all_entries.select {|e| e =~ dir_regex }
    # need a shallow resultset
    entries_directly_under_directory = entries_under_directory.reject {|e| e =~ /#{just_dir}\/.*\//}
    entries_directly_under_directory
  end 
end
