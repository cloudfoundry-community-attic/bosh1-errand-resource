require "open3"
require "yaml"
require "zlib"

require "archive/tar/minitar"

module BoshErrandResource
  class BoshStemcell
    def initialize(path)
      @path = path
    end

    def name
      manifest.fetch("name")
    end

    def version
      manifest.fetch("version")
    end

    private

    def manifest
      @manifest ||= YAML.load(manifest_file_contents)
    end

    def manifest_file_contents
      tgz = Zlib::GzipReader.new(File.open(path, 'rb'))

      Archive::Tar::Minitar::Reader.open(tgz) do |reader|
        reader.each_entry do |entry|
          next unless File.basename(entry.full_name) == "stemcell.MF"

          return entry.read
        end
      end

      raise "could not find stemcell.MF"
    ensure
      tgz.close if tgz
    end

    attr_reader :path
  end
end
