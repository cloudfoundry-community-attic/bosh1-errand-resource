require "spec_helper"

require "yaml"

describe BoshErrandResource::BoshManifest do
  let(:manifest) { BoshErrandResource::BoshManifest.new("spec/fixtures/manifest.yml") }

  let(:resulting_manifest) { YAML.load_file(manifest.write!) }

  it "can get the name of the deployment" do
    expect(manifest.name).to eq("concourse")
  end

  describe ".fallback_director_uuid" do
    let(:uuid) { "some-filled-in-uuid" }

    context "when the source manifest has no director uuid" do
      let(:manifest) { BoshErrandResource::BoshManifest.new("spec/fixtures/manifest-without-uuid.yml") }

      it "fills it in with the given uuid" do
        manifest.fallback_director_uuid(uuid)
        expect(resulting_manifest.fetch("director_uuid")).to eq("some-filled-in-uuid")
      end
    end

    context "when the source manifest already has a uuid" do
      let(:manifest) { BoshErrandResource::BoshManifest.new("spec/fixtures/manifest-with-uuid.yml") }

      it "does not replace it" do
        manifest.fallback_director_uuid(uuid)
        expect(resulting_manifest.fetch("director_uuid")).to eq("some-director-uuid")
      end
    end
  end
end
