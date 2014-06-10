require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Play do

    #-------------------------------------------------------------------------#

    describe "CLAide" do
      it "registers it self" do
        Command.parse(%w{ play }).should.be.instance_of Command::Play
      end

      it "presents the help if no name is provided" do
        command = Pod::Command.parse(['play'])
        should.raise CLAide::Help do
          command.validate!
        end.message.should.match /A Pod name or URL is required/
      end

      it "runs if passed in an Pod name" do
        Config.instance.skip_repo_update = false
        command = Pod::Command.parse(['play', 'Agent'])
        Installer::PodSourceInstaller.any_instance.expects(:install!)
        command.expects(:update_specs_repos)
        command.run
      end

      it "runs if passed in a git repository URL" do
        Config.instance.skip_repo_update = false
        command = Pod::Command.parse(['play', 'https://github.com/hallas/agent.git'])
        Installer::PodSourceInstaller.any_instance.expects(:install!)
        command.expects(:update_specs_repos).never
        command.run
      end

    end

    #-------------------------------------------------------------------------#

    describe "Helpers" do

      before do
        @sut = Pod::Command.parse(['play'])
      end

      it "returns the spec with the given name" do
        spec = @sut.spec_with_name('Agent')
        spec.name.should == 'Agent'
      end

      describe "#spec_at_url" do

        it "returns a spec for an https git repo" do
          spec = @sut.spec_with_url('https://github.com/hallas/agent.git')
          spec.name.should == "Agent"
        end

        it "returns a spec for a github url" do
          spec = @sut.spec_with_url('https://github.com/hallas/agent')
          spec.name.should == "Agent"
        end

        it "returns a spec for a git protocol url" do
          spec = @sut.spec_with_url('git://github.com/hallas/agent')
          spec.name.should == "Agent"
        end

        it "returns a spec for a git ssh url" do
          spec = @sut.spec_with_url('git@github.com:hallas/agent.git')
          spec.name.should == "Agent"
        end

      end

      it "installs the pod" do
        Installer::PodSourceInstaller.any_instance.expects(:install!)
        spec = stub(:name => 'Agent')
        path = @sut.install_pod(spec, '/tmp/CocoaPods/Play')
        path.should == Pathname.new("/tmp/CocoaPods/Play/Agent")
      end

    end

    #-------------------------------------------------------------------------#

  end
end
