module ExplanatoryAide
  class ARGV < Array
    def options
      options = {}
      parse do |type, (key, value)|
        options[key] = value if type == :option || type == :flag
        false
      end
      options
    end

    def arguments
      args = []
      parse do |type, value|
        args << value if type == :arg
        false
      end
      args
    end

    def flag?(name)
      result = nil
      parse do |type, (key, value)|
        if name == key && type == :flag
          result = value
          true
        end
      end
      result
    end

    private

    def parse
      copy = dup
      i = 0
      while x = copy.shift
        start, i = i, i+1
        type = key = value = nil
        if is_arg?(x)
          type, value = :arg, x
        else
          key = x[2..-1]
          if (next_x = copy.first) && is_arg?(next_x)
            type = :option
            value = copy.shift
            i += 1
          else
            type = :flag
            value = true
            if key[0,3] == 'no-'
              key = key[3..-1]
              value = false
            end
          end
          value = [key, value]
        end
        if yield(type, value)
          delete_at(start)
          delete_at(start+1) if type == :option
        end
      end
    end

    def is_arg?(x)
      x[0,2] != '--'
    end
  end
end
