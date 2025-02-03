module FB
  class Grafana
    module Provider
      def load_current_plugins
        s = Mixlib::ShellOut.new('grafana-cli plugins ls').run_command
        s.error!
        plugins = {}
        s.stdout.each_line do |line|
          next unless line =~ / @ /

          name, version = line.chomp.strip.split(' @ ')
          plugins[name] = version
        end
        plugins
      end

      def load_available_plugins
        s = Mixlib::ShellOut.new('grafana-cli plugins list-remote').run_command
        s.error!
        plugins = {}
        s.stdout.each_line do |line|
          next unless line.start_with?('id:')

          m = line.chomp.match(/^id: (.*) version: (.*)$/)
          plugins[m[1]] = m[2]
        end
        plugins
      end
    end
  end
end
