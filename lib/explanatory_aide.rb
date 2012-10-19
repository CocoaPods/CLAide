module ExplanatoryAide
  class ARGV < Array
    def options
      parse.first
    end

    def arguments
      parse.last
    end

    #def flag?(key)
      #value = parse.first[key]
      #unless value.is_a?(String)
        #value
      #end
    #end

    private

    def parse
      options = {}
      args = []
      copy = dup
      while x = copy.shift
        if is_arg?(x)
          args << x
        else
          key = x[2..-1]
          value = nil
          if (next_x = copy.first) && is_arg?(next_x)
            value = copy.shift
          else
            value = true
            if key[0,3] == 'no-'
              key = key[3..-1]
              value = false
            end
          end
          options[key] = value
        end
      end
      [options, args]
    end

    def is_arg?(x)
      x[0,2] != '--'
    end
  end
end
