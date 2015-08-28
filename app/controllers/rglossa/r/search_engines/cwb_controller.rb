require 'rserve'

module Rglossa
  module R
    module SearchEngines
      class CwbController < ApplicationController

        def query_freq
          attribute = params[:attribute] || 'word'

          # TODO: Handle multiple queries
          query = params[:query].first[:query]
          corpus = params[:corpus].upcase

          conn = Rserve::Connection.new
          conn.eval('library("rcqp")')
          conn.eval(%Q{corp <- corpus("#{corpus}")})
          conn.eval(%Q{subcorp <- subcorpus(corp, '#{query}')})

          freqs = conn.eval(%Q{freqs <- cqp_flist(subcorp, "match", "#{attribute}")})

          pairs = []
          freqs.attr.to_ruby[0].zip(freqs.to_ruby) do |a, f|
            pairs << {form: a, freq: f}
          end

          render json: {pairs: pairs, success: true}
        end

      end
    end
  end
end
