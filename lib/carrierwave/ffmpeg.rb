require 'carrierwave'
require 'streamio-ffmpeg'

module CarrierWave
  module FFmpeg
    module ClassMethods
      def encode format, opts = {}
        process encode: [ format, opts ]
      end

      def movie path
        ::FFMPEG::Movie.new path
      end
    end

    def encode format, opts = {}
      tmp_path = File.join File.dirname(current_path), "tmp_file.#{format}"
      file = movie current_path
      #binding.pry
      file.transcode tmp_path, options(format, file, opts), transcoder_options
      File.rename tmp_path, current_path
    end

    def convert format, opts = {}
      cache_stored_file! if !cached?

      tmp_path = File.join(File.dirname(current_path), "tmp_file.#{format}")
      file = movie(current_path)
      new_path = File.join(File.dirname(current_path), File.basename(current_path, File.extname(current_path)) + "." + format.to_s)

      file.transcode(tmp_path, options(format, file, opts), transcoder_options)

      File.rename tmp_path, new_path
      self.file.instance_variable_set(:@content_type, content_type_for_extension(format.to_s))
      self.file.instance_variable_set(:@file, new_path)
    end

    def codec format
      case format.to_s.to_sym
      when :mp4
        { video_codec: 'libx264',   
          audio_codec: 'libfaac' }
      when :webm
        { video_codec: 'libvpx',    
          audio_codec: 'libvorbis' }
      when :ogv
        { video_codec: 'libtheora', 
          audio_codec: 'libvorbis' }
      when :opus
        { strict: nil,
          "2": nil,
          video_codec: 'none',
          audio_codec: 'opus' }
      else
        raise CarrierWave::ProcessingError.new("Unsupported media format '#{format}'")
      end
    end

    def options format, file, opts = {}
      opts[:resolution]    = file.resolution unless opts[:resolution]
      opts[:video_bitrate] = file.bitrate unless opts[:video_bitrate]
      opts[:video_bitrate_tolerance] = (opts[:video_bitrate].to_i / 10).to_i
      opts[:threads] = 2 unless opts[:threads]
      opts.merge!(codec(format))
    end

    def transcoder_options 
      { preserve_aspect_ratio: :height }
    end

    def movie path
      ::FFMPEG::Movie.new path
    end

    private

    def content_type_for_extension extension
      case extension.to_sym
      when :mp3
        "audio/mpeg3"
      when :ogg, :vorbis
        "audio/ogg"
      end
    end
  end
end
