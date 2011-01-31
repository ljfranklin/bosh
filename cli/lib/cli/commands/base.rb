require "yaml"
require "terminal-table/import"

module Bosh::Cli
  module Command
    class Base

      DEFAULT_CONFIG_PATH = File.expand_path("~/.bosh_config")
      DEFAULT_CACHE_DIR   = File.expand_path("~/.bosh_cache")

      attr_reader   :cache, :config, :options, :work_dir
      attr_accessor :out

      def initialize(options = {})
        @options     = options.dup
        @work_dir    = Dir.pwd
        @config      = Config.new(@options[:config] || DEFAULT_CONFIG_PATH)
        @cache       = Cache.new(@options[:cache_dir] || DEFAULT_CACHE_DIR)
      end

      def director
        @director ||= Bosh::Cli::Director.new(target, username, password)
      end

      def logged_in?
        username && password
      end

      def non_interactive?
        options[:non_interactive]
      end

      def verbose?
        options[:verbose]
      end

      # TODO: implement it
      def dry_run?
        options[:dry_run]
      end

      def run(namespace, action, *args)
        eval(namespace.to_s.capitalize).new(options).send(action.to_sym, *args)
      end

      def redirect(*args)
        run(*args)
        raise Bosh::Cli::GracefulExit, "redirected to %s" % [ args.join(" ") ]
      end

      [:username, :password, :target, :deployment].each do |attr_name|
        define_method attr_name do
          config.send(attr_name)
        end
      end

      protected

      def check_if_release_dir
        if !in_release_dir?
          err "Sorry, your current directory doesn't look like release directory"        
        end      
      end

      def in_release_dir?
        File.directory?("packages") && File.directory?("jobs") && File.directory?("src")
      end
    end
  end
end
