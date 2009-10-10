require 'rubygems'
require 'id3lib'
require 'yaml'


@library_root = "/Users/iamjwc/Music/iTunes/iTunes\ Music/"
@clone_root   = "/Users/iamjwc/Music/clone/"

def build_index
  @bands = Dir[File.join(@library_root, "*/")]
  @bands.each do |band|
    band_name = File.basename(band)
  
    clone_band = File.join(@clone_root, band_name)
    Dir.mkdir clone_band unless File.exist? clone_band
  
    @albums = Dir[File.join(band, "*/")]
    @albums.each do |album|
      album_name = File.basename(album)
  
      clone_album = File.join(clone_band, album_name)
      Dir.mkdir clone_album unless File.exist? clone_album
  
      @songs = Dir[File.join(album, "*.mp3")]
      @songs.each do |song|
        song_name = File.basename(song).gsub(/\.mp3$/, "")
  
        tags = ID3Lib::Tag.new(song)
  
        song_hash = {}
        [:album, :artist, :band, :grouping, :disc, :time, :track, :title].each do |key|
          song_hash[key] = tags.send key
        end
  
        clone_song = File.join(clone_album, song_name + ".yml")
  
        File.open(clone_song, "w") do |f|
          f.write YAML.dump(song_hash)
        end
  
      end
    end
  end
end

def get_changes
  changes = %x{cd #{@clone_root} && git status}

  untracked_changes = changes.split("# Untracked files:").last.gsub(/\n$/, "").split("\n#	")[1..-1]

  untracked_files = {
    :songs => [],
    :artists => [],
    :albums => []
  }

  untracked_changes.each do |change|
    artist, album, song = change.split("/")

    if song
      untracked_files[:songs] << change
    elsif album
      untracked_files[:albums] << change
    else
      untracked_files[:artists] << change
    end
  end

  {:new => untracked_files, :modified => {}, :removed => {}, :moved => {}}
end

def display_changes
  changes = get_changes

  changes_helper(changes, :new, :songs)
  changes_helper(changes, :new, :albums)
  changes_helper(changes, :new, :artists)
end

def changes_helper(changes, section, type)
  puts "#{section.to_s.capitalize} #{type.to_s.capitalize}:"
  changes[section][type].each do |i|
    puts "  * #{i}"
  end
  puts
end


display_changes










