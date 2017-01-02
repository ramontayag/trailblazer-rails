module Trailblazer::Rails
  module Controller
    def run(operation, params=self.params, *dependencies)
      result = operation.(
        _run_params(params),
        *_run_runtime_options(*dependencies)
      )

      @form  = Trailblazer::Rails::Form.new(result["contract.default"], result["model"].class)
      @model = result["model"]

      yield(result) if result.success? && block_given?

      @_result = result
    end

  private
    # Override to tweak params. Not recommended.
    # Use a deserializer instead.
    def _run_params(params)
      params
    end

    # This is where we can inject Dry.RB containers and the like via dependencies.
    def _run_runtime_options(options={}, *dependencies)
      [_run_options(options), *dependencies]
    end

    # Override this to inject dependencies such as "current_user"
    # into the runtime options.
    def _run_options(options)
      options
    end

    module Render
      def render(cell=nil, options={}, *, &block)
        return super unless cell.kind_of?(::Cell::ViewModel)
        render_cell(cell, options)
      end

      def render_cell(cell, options)
        options = options.reverse_merge(layout: true)

        # render the cell.
        content = cell.()

        render( { html: content }.merge(options) )
      end
    end

    include Render

    module Result
      def result
        @_result
      end
    end

    include Result
  end
end
