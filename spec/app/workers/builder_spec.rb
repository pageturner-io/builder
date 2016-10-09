describe Workers::Builder do
  let(:builder)               { described_class.new(repo, build_requested_event) }
  let(:repo)                  { instance_double("Models::GitRepository").as_null_object }
  let(:repo_name)             { "octocat/Hello-World" }
  let(:build_requested_event) { { meta: { cid: SecureRandom.hex } } }

  before :all do
    Timecop.freeze
  end

  after :all do
    Timecop.return
  end

  before :each do
    allow(repo).to receive(:name).and_return(repo_name)
  end

  describe "#build!" do
    subject { builder.build! }

    let(:pid) { 12345 }

    before :each do
      allow(repo).to receive(:clone)
      allow(repo).to receive(:update)

      allow(builder).to receive(:fork) do |&block|
        block.call
        pid
      end

      allow(builder).to receive(:before_build)

      allow(Dir).to receive(:chdir) { |&block| block.call }
      allow(Kernel).to receive(:exec)
      allow(Process).to receive(:wait).with(pid)

      allow(S3Uploader).to receive(:upload)
    end

    it "calls #before_build" do
      subject

      expect(builder).to have_received(:before_build)
    end

    it "updates the repo" do
      subject

      expect(repo).to have_received(:update)
    end

    it "changes the directory to the repo's path" do
      subject

      expect(Dir).to have_received(:chdir).with(repo.repository_path)
    end

    it "builds a Jekyll project in the repo's directory" do
      subject

      expect(Kernel).to have_received(:exec)
        .with("bundle install && bundle exec jekyll build -d /sites/#{repo_name}")
    end

    it "uploads the built project into an S3 bucket" do
      subject

      expect(S3Uploader).to have_received(:upload).with(
        "/sites/#{repo_name}",
        ENV["S3_BUCKET_NAME"],
        {
          s3_key:          ENV["AWS_ACCESS_KEY_ID"],
          s3_secret:       ENV["AWS_SECRET_KEY"],
          destination_dir: "#{repo_name}/#{Time.now.to_i}",
          region:          ENV["AWS_REGION"]
        }
      )
    end

  end

  describe "#before_build" do
    subject { builder.before_build }

    it "publishes a 'build:started' event" do
      expect { subject }.to emit("build:started").with(
        repository: repo_name
      )
    end

    it "uses the cid from the event that triggered the build" do
      expect(subject[:meta][:cid]).to eq(build_requested_event[:meta][:cid])
    end

  end

  describe "#after_build" do
    subject { builder.after_build }

    let(:deploy_location) do
      {
        host:   "s3",
        bucket: ENV["S3_BUCKET_NAME"],
        object: "#{repo_name}/#{Time.now.to_i}"
      }
    end

    it "publishes a 'build:finished' event" do
      expect { subject }.to emit("build:finished").with(
        repository: repo_name,
        location:   deploy_location
      )
    end

    it "uses the cid from the event that triggered the build" do
      expect(subject[:meta][:cid]).to eq(build_requested_event[:meta][:cid])
    end
  end
end
