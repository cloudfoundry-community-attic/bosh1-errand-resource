require 'digest'
require 'time'

module BoshErrandResource
  class OutCommand
    def initialize(bosh, manifest, writer=STDOUT)
      @bosh = bosh
      @manifest = manifest
      @writer = writer
    end

    def run(working_dir, request)
      validate! request

      manifest.fallback_director_uuid(bosh.director_uuid)

      new_manifest = manifest.write!
      manifest_sha1 = Digest::SHA1.file(new_manifest.path).hexdigest

      errand = request.fetch("params").fetch("errand")

      bosh.errand(new_manifest.path, errand)

      response = {
        "version" => {
          "manifest_sha1" => manifest_sha1
        },
        "metadata" => {}
      }

      writer.puts response.to_json
    end

    private

    attr_reader :bosh, :manifest, :writer

    def validate!(request)
      ["username", "password", "deployment"].each do |field|
        request.fetch("source").fetch(field) { raise "source must include '#{field}'" }
      end

      deployment_name = request.fetch("source").fetch("deployment")
      if manifest.name != deployment_name
        raise "given deployment name '#{deployment_name}' does not match manifest name '#{manifest.name}'"
      end

      ["manifest", "errand"].each do |field|
        request.fetch("params").fetch(field) { raise "params must include '#{field}'" }
      end
    end

    def enumerable?(object)
      object.is_a? Enumerable
    end
  end
end
