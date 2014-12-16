#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "lapis_lazuli/logger"

require "lapis_lazuli/world/config"

module LapisLazuli
module WorldModule
  ##
  # Module for easy logging
  #
  # Manages the following:
  #   @log        - TeeLogger instances
  module Logging
    include LapisLazuli::WorldModule::Config

    ##
    # Log "singleton"
    def log
      if not @log.nil?
        return @log
      end

      # Make log directory
      dir = env_or_config('log_dir')
      begin
        Dir.mkdir dir
      rescue SystemCallError => ex
        # Swallow this error; it occurs (amongst other situations) when the
        # directory exists. Checking for an existing directory beforehand is
        # not concurrency safe.
      end

      # Start the logger with the config filename
      log_file = "#{dir}#{File::SEPARATOR}#{File.basename(Config.config_file, ".*")}.log"
      # Or a filename from the environment
      if has_env_or_config?("log_file")
        log_file = env_or_config("log_file")
      end
      @log = TeeLogger.new(log_file)
      @log.level = env_or_config("log_level")

      return @log
    end
  end # module Logging
end # module WorldModule
end # module LapisLazuli