require "spec_helper"

describe BoshErrandResource::CommandRunner do
  let (:command_runner) { BoshErrandResource::CommandRunner.new }

  describe '.run' do
    it 'takes a command and an environment and spanws a process' do
      expect {
        command_runner.run('sh -c "$PROG"', "PROG" => "true")
      }.to_not raise_error
    end

    it 'takes an options hash' do
      r, w = IO.pipe
      command_runner.run('sh -c "echo $FOO"', {"FOO" => "sup"}, out: w)
      expect(r.gets).to eq("sup\n")
    end

    it 'raises an exception if the command fails' do
      expect {
        command_runner.run('sh -c "$PROG"', "PROG" => "false")
      }.to raise_error("command 'sh -c \"$PROG\"' failed!")
    end

    it 'routes all output to stderr' do
      pid = 7223
      expect($?).to receive(:success?).and_return(true)
      expect(Process).to receive(:wait).with(pid)
      expect(Process).to receive(:spawn).with({}, 'echo "hello"', out: :err, err: :err).and_return(pid)

      command_runner.run('echo "hello"')
    end
  end
end

describe BoshErrandResource::Bosh do
  let(:target) { "http://bosh.example.com" }
  let(:username) { "bosh-userΩΩΩΩ" }
  let(:password) { "bosh-password!#%&#(*" }
  let(:command_runner) { instance_double(BoshErrandResource::CommandRunner) }

  let(:bosh) { BoshErrandResource::Bosh.new(target, username, password, command_runner) }

  describe ".errand" do
    it "runs the command to run errand" do
      expect(command_runner).to receive(:run).with(%{bosh -n --color -t #{target} -d /path/to/a/manifest.yml run errand smoke-tests}, { "BOSH_USER" => username, "BOSH_PASSWORD" => password }, {})

      bosh.errand("/path/to/a/manifest.yml", "smoke-tests")
    end
  end

  describe ".director_uuid" do
    it "collects the output of status --uuid" do
      expect(command_runner).to receive(:run).with(%{bosh -n --color -t #{target} status --uuid}, { "BOSH_USER" => username, "BOSH_PASSWORD" => password }, anything) do |_, _, opts|
        opts[:out].puts "abcdef\n"
      end

      expect(bosh.director_uuid).to eq("abcdef")
    end
  end
end
