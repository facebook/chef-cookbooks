module FB
  class Systemd
    class SpecHelpers
      def self.go!(node)
        allow(node).to receive(:systemd?).and_return(true)
      end
    end
  end
end
