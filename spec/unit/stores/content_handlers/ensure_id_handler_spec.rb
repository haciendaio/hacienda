require_relative '../../unit_helper'
require_relative '../../../../app/stores/content_handlers/ensure_id_handler'
require_relative '../../../../app/model/content_query'

module Hacienda
  module Test

    describe EnsureIdHandler do

      it 'should ensure there is an id field' do
        data = { }

        query_new = ContentQuery.new(:public, 'fr', 'type', 'id')

        EnsureIdHandler.new.process!(data, query_new)

        expect(data[:id]).to eq('id')

      end

      it 'should not override it if it already exists' do
        data = { id: 'already_here' }

        query_new = ContentQuery.new(:public, 'fr', 'type', 'id')

        EnsureIdHandler.new.process!(data, query_new)

        expect(data[:id]).to eq('already_here')

      end

    end

  end
end
