module PDF
  class Wrapper

    # a proxy to a PDF::Wrapper object that disallows new pages
    class Page

      def initialize(pdf)
        @pdf = pdf
      end

      def method_missing(method, *args, &block)
        if method.to_sym == :start_new_page
          raise InvalidOperationError, 'start_new_page is not allowed in the current context'
        else
          @pdf.__send__(method, *args, &block)
        end
      end
    end
  end
end
