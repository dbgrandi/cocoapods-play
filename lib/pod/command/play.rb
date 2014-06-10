# @return [String] Contents for a default .timeline file for a Playground
#
TIMELINE_FILE = <<-TIMELINE
<?xml version="1.0" encoding="UTF-8"?>
<Timeline version = "3.0">
  <TimelineItems>
  </TimelineItems>
</Timeline>
TIMELINE

# @return [String] Contents for a default .contents file for a Playground
#
CONTENTS_FILE = <<-CONTENT
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<playground version='3.0' sdk='iphonesimulator'>
  <sections>
    <code source-file-name='section-1.swift'/>
  </sections>
  <timeline fileName='timeline.xctimeline'/>
</playground>
CONTENT

module Pod
  class Command
    # This is an example of a cocoapods plugin adding a subcommand to
    # the 'pod spec' command. Adapt it to suit your needs.
    #
    # @todo Create a PR to add your plugin to CocoaPods/cocoapods.org
    #       in the `plugins.json` file, once your plugin is released.
    #
    class Play < Command
      self.summary = "Try a Pod in an Xcode Playground."

      self.description = <<-DESC
        Downloads the Pod with the given NAME (or Git URL). If a README.playground
        file exists, we open it. If not, we generate one by concatenating together
        all the .swift files referenced in the Podspec.
      DESC

      self.arguments = 'NAME'

      def initialize(argv)
        @name = argv.shift_argument
        super
      end

      def validate!
        super
        help! "A Pod name or URL is required." unless @name
      end

      def run
        sandbox = Sandbox.new(PLAY_TMP_DIR)
        if git_url?(@name)
          spec = spec_with_url(@name)
          sandbox.store_pre_downloaded_pod(spec.name)
        else
          update_specs_repos
          spec = spec_with_name(@name)
        end
        
        source_files = spec.attributes_hash["source_files"]
        
        UI.title "Trying #{spec.name}" do
          pod_dir = install_pod(spec, sandbox)
          UI.puts("pod dir = #{pod_dir}")
          
          playground = search_for_playground(pod_dir)

          unless playground
            UI.puts "Unable to locate a README.playground in #{spec.name}"
            playground = create_playground(pod_dir, spec)
          end

          open_playground(playground)
        end
      end
      
      public
      
      def search_for_playground(pod_dir)
        Dir.glob("#{pod_dir}/**/*.playground")[0]
      end

      def create_playground(pod_dir, spec)
        playground = "#{pod_dir}/#{spec.name}.playground"
        Dir.mkdir(playground)
        
        # make the helper files
        create_contents(playground)
        create_timeline(playground)
        
        swift_files = []
        source_files = Array(spec.attributes_hash["source_files"])
        source_files.each do |source|
          Dir.glob(pod_dir.to_s + '/' + source) do |file|
            if !File.directory?(file) && file.end_with?(".swift")
              swift_files << file
            end
          end
        end
        
        # concatenate them together in a new playground file
        File.open(playground + "/section-1.swift", "w+") do |swift_file|
          swift_files.uniq.each do |file|
            UI.puts "Adding #{file} to playground"
            swift_file.write("// File: #{file}\n")
            IO.copy_stream(File.open(file),swift_file)
            swift_file.write("\n\n")
          end
          
          swift_file.write("// Commence playing.\n\n")
        end

        return playground
      end

      # Opens the playground at the given path.
      #
      # @return [String] path
      #         The path of the Playground file.
      #
      # @return [void]
      #
      def open_playground(playground_dir)
        UI.puts "Opening #{playground_dir}..."
        `open "#{playground_dir}"`
      end
      
      # Helpers
      #-----------------------------------------------------------------------#
      
      # @return [Pathname]
      #
      PLAY_TMP_DIR = Pathname.new('/tmp/CocoaPods/Play')
      
      # Returns the specification of the last version of the Pod with the given
      # name.
      #
      # @param  [String] name
      #         The name of the pod.
      #
      # @return [Specification] The specification.
      #
      def spec_with_name(name)
        set = SourcesManager.search(Dependency.new(name))
        if set
          set.specification.root
        else
          raise Informative, "Unable to find a specification for `#{name}`"
        end
      end
      
      # Returns the specification found in the given Git repository URL by
      # downloading the repository.
      #
      # @param  [String] url
      #         The URL for the pod Git repository.
      #
      # @return [Specification] The specification.
      #
      def spec_with_url(url)
        name = url.split('/').last
        name = name.chomp(".git") if name.end_with?(".git")
      
        target_dir = PLAY_TMP_DIR + name
        target_dir.rmtree if target_dir.exist?
      
        downloader = Pod::Downloader.for_target(target_dir, { :git => url })
        downloader.download
      
        spec_file = target_dir + "#{name}.podspec"
        Pod::Specification.from_file(spec_file)
      end
      
      # Installs the specification in the given directory.
      #
      # @param  [Specification] The specification of the Pod.
      # @param  [Pathname] The directory of the sandbox where to install the
      #         Pod.
      #
      # @return [Pathname] The path where the Pod was installed
      #
      def install_pod(spec, sandbox)
        specs = { :ios => spec, :osx => spec }
        installer = Installer::PodSourceInstaller.new(sandbox, specs)
        installer.aggressive_cache = config.aggressive_cache?
        installer.install!
        sandbox.root + spec.name
      end
      
      # Performs a CocoaPods installation for the given project if Podfile is
      # found.  Shells out to avoid issues with the config of the process
      # running the try command.
      #
      # @return [String] proj
      #         The path of the project.
      #
      # @return [String] The path of the file to open, in other words the
      #         workspace of the installation or the given project.
      #
      def install_podfile(proj)
        return unless proj
        dirname = Pathname.new(proj).dirname
        podfile_path = dirname + 'Podfile'
        if podfile_path.exist?
          Dir.chdir(dirname) do
            perform_cocoapods_installation
      
            podfile = Pod::Podfile.from_file(podfile_path)
      
            if podfile.workspace_path
              File.expand_path(podfile.workspace_path)
            else
              proj.chomp(File.extname(proj.to_s)) + '.xcworkspace'
            end
          end
        else
          proj
        end
      end
      
      public
      
      # Private Helpers
      #-----------------------------------------------------------------------#
      
      # @return [void] Updates the specs repo unless disabled by the config.
      #
      def update_specs_repos
        unless config.skip_repo_update?
          UI.section 'Updating spec repositories' do
            SourcesManager.update
          end
        end
      end
      
      
      # @return [void] Performs a CocoaPods installation in the working
      #         directory.
      #
      def perform_cocoapods_installation
        UI.puts `pod install`
      end
      
      # @return [Bool] Wether the given string is the name of a Pod or an URL
      #         for a Git repo.
      #
      def git_url?(name)
        prefixes = ['https://', 'http://']
        if prefixes.any? { |prefix| name.start_with?(prefix) }
          true
        else
          false
        end
      end

      #-------------------------------------------------------------------#

      def create_timeline(playground_dir)
        File.open(playground_dir + "/timeline.xctimeline", "w+") do |f|
          f.write(TIMELINE_FILE)
        end
      end
      
      def create_contents(playground_dir)
        File.open(playground_dir + "/contents.xcplayground", "w+") do |f|
          f.write(CONTENTS_FILE)
        end
      end
      
    end
  end
end
