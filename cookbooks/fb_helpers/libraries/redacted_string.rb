# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

# Redacted Strings to avoid accidental logging, and make retreiving
# the plaintext of a secret into an explicit act
#
# irb(main):037:0> secret = FB::Helpers::RedactedString.new('ohai')
# => "***REDACTED***"
# irb(main):038:0> secret
# => "***REDACTED***"
# irb(main):040:0> secret.value
# => "ohai"

module FB
  class Helpers
    class SecretString < String
      def to_s
        self
      end
    end

    class RedactedString < String
      def initialize(*args)
        # Have the internal value be REDACTED to cover off cases we missed!
        super('**REDACTED**')
        @actual_string = args[0]
        # These are always frozen, since modifying them would break the implementation
        self.freeze
      end

      def value
        FB::Helpers::SecretString.new(@actual_string)
      end

      def to_s
        '**REDACTED**'
      end

      def to_str
        '**REDACTED**'
      end

      def inspect
        '***REDACTED***'.inspect
      end
    end
  end
end
