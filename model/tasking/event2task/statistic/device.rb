# encoding: UTF-8

module Tasking
  module Statistic
    class Device_platform
      attr_accessor :count_visits
      attr :browser,
           :browser_version,
           :os,
           :os_version,
           :screen_resolution
      SEPARATOR2=";"

      def initialize(plugin, resolution)
        @browser = plugin.browser
        @browser_version = plugin.browser_version
        @os = plugin.os
        @os_version = plugin.os_version
        @screen_resolution = resolution.screen_resolution
        @count_visits = plugin.count_visits < resolution.count_visits ? plugin.count_visits : resolution.count_visits
      end

      def to_s(*a)
        [
            @browser,
            @browser_version,
            @os,
            @os_version,
            @screen_resolution,
            @count_visits
        ].join(SEPARATOR2)
      end
    end

    class Device_plugin < Device_platform
      def initialize(plugin)
        splitted_plugin = plugin.strip.split(SEPARATOR2)
        @browser = splitted_plugin[0]
        @browser_version = splitted_plugin[1]
        @os = splitted_plugin[2]
        @os_version = splitted_plugin[3]
        @flash_version = splitted_plugin[4]
        @java_enabled = splitted_plugin[5]
        @is_mobile = splitted_plugin[6]
        @count_visits = splitted_plugin[7].to_i
      end
    end

    class Device_resolution < Device_platform
      def initialize(resolution)
        splitted_resolution = resolution.strip.split(SEPARATOR2)
        @browser = splitted_resolution[0]
        @browser_version = splitted_resolution[1]
        @os = splitted_resolution[2]
        @os_version = splitted_resolution[3]
        @screen_colors = splitted_resolution[4]
        @screen_resolution = splitted_resolution[5]
        @is_mobile = splitted_resolution[6]
        @count_visits = splitted_resolution[7].to_i
      end
    end
  end
end