require "spec_helper"

require "digest"
require "fileutils"
require "json"
require "open3"
require "tmpdir"
require "stringio"

describe "Out Command" do
  let(:manifest) { instance_double(BoshErrandResource::BoshManifest, fallback_director_uuid: nil, name: "bosh-deployment") }
  let(:bosh) { instance_double(BoshErrandResource::Bosh, errand: nil, director_uuid: "some-director-uuid") }
  let(:response) { StringIO.new }
  let(:command) { BoshErrandResource::OutCommand.new(bosh, manifest, response) }

  let(:written_manifest) do
    file = Tempfile.new("bosh_manifest")
    file.write("hello world")
    file.close
    file
  end

  def touch(*paths)
    path = File.join(paths)
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.touch(path)
  end

  def cp(src, *paths)
    path = File.join(paths)
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.cp(src, path)
  end

  def in_dir
    Dir.mktmpdir do |working_dir|
      yield working_dir
    end
  end

  before do
    allow(manifest).to receive(:write!).and_return(written_manifest)
  end

  let(:request) {
    {
      "source" => {
        "target" => "http://bosh.example.com",
        "username" => "bosh-username",
        "password" => "bosh-password",
        "deployment" => "bosh-deployment",
      },
      "params" => {
        "manifest" => "manifest/deployment.yml",
        "errand" => "smoke-tests",
      }
    }
  }

  context "with valid inputs" do

    it "emits a sha1 checksum of the manifest as the version" do
      in_dir do |working_dir|

        command.run(working_dir, request)

        expect(JSON.parse(response.string)["version"]).to eq({
          "manifest_sha1" => Digest::SHA1.file(written_manifest.path).hexdigest
        })
      end
    end



    it "generates a new manifest (with locked down versions and a defaulted director uuid) and deploys it" do
      in_dir do |working_dir|

        expect(bosh).to receive(:director_uuid).and_return("abcdef")
        expect(manifest).to receive(:fallback_director_uuid).with("abcdef")

        expect(bosh).to receive(:errand).with(written_manifest.path, "smoke-tests")

        command.run(working_dir, request)
      end
    end
  end

  context "with invalid inputs" do
    it "errors if the given deployment name and the name in the manifest do not match" do
      allow(manifest).to receive(:name).and_return("other-name")

      in_dir do |working_dir|
        expect do
          command.run(working_dir, {
            "source" => {
              "target" => "http://bosh.example.com",
              "username" => "bosh-user",
              "password" => "bosh-password",
              "deployment" => "bosh-deployment",
            },
            "params" => {
              "manifest" => "deployment.yml",
              "errand" => "smoke-tests",
            }
          })
        end.to raise_error /given deployment name 'bosh-deployment' does not match manifest name 'other-name'/
      end
    end

    it "requires a username" do
      in_dir do |working_dir|
        expect do
          command.run(working_dir, {
            "source" => {
              "target" => "http://bosh.example.com",
              "password" => "bosh-password",
              "deployment" => "bosh-deployment",
            },
            "params" => {
              "manifest" => "deployment.yml",
              "errand" => "smoke-tests",
            }
          })
        end.to raise_error /source must include 'username'/
      end
    end

    it "requires a password" do
      in_dir do |working_dir|
        expect do
          command.run(working_dir, {
            "source" => {
              "target" => "http://bosh.example.com",
              "username" => "bosh-username",
              "deployment" => "bosh-deployment",
            },
            "params" => {
              "manifest" => "deployment.yml",
              "errand" => "smoke-tests",
            }
          })
        end.to raise_error /source must include 'password'/
      end
    end

    it "requires a deployment" do
      in_dir do |working_dir|
        expect do
          command.run(working_dir, {
            "source" => {
              "target" => "http://bosh.example.com",
              "username" => "bosh-username",
              "password" => "bosh-password",
            },
            "params" => {
              "manifest" => "deployment.yml",
              "errand" => "smoke-tests",
            }
          })
        end.to raise_error /source must include 'deployment'/
      end
    end

    it "requires a manifest" do
      in_dir do |working_dir|
        expect do
          command.run(working_dir, {
            "source" => {
              "target" => "http://bosh.example.com",
              "username" => "bosh-username",
              "password" => "bosh-password",
              "deployment" => "bosh-deployment",
            },
            "params" => {
              "errand" => "smoke-tests",
            }
          })
        end.to raise_error /params must include 'manifest'/
      end
    end

    it "requires a errand" do
      in_dir do |working_dir|
        expect do
          command.run(working_dir, {
            "source" => {
              "target" => "http://bosh.example.com",
              "username" => "bosh-username",
              "password" => "bosh-password",
              "deployment" => "bosh-deployment",
            },
            "params" => {
              "manifest" => "deployment.yml",
            }
          })
        end.to raise_error /params must include 'errand'/
      end
    end

  end
end
