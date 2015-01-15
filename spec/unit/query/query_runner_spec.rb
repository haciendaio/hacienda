require_relative '../unit_helper'
require_relative '../../../app/query/query_runner'

module Hacienda
  module Test

    describe QueryRunner do

      it 'run the query options in the correct order' do

        content_hash = {}
        query_options = [
            double('QueryOption', apply: content_hash),
            double('QueryOption', apply: content_hash),
            double('QueryOption', apply: content_hash)
        ]

        expect(query_options[0]).to receive(:apply).ordered.with(content_hash)
        expect(query_options[1]).to receive(:apply).ordered.with(content_hash)
        expect(query_options[2]).to receive(:apply).ordered.with(content_hash)

        QueryRunner.new({}, query_options).apply(content_hash)

      end

      it 'should return a new instance for content items' do
        initial_items = {}
        modified_items = QueryRunner.new({}, []).apply(initial_items)

        expect(initial_items).to_not be(modified_items)
      end

      describe 'QueryOptionLoader' do

        it 'should load all the correct query options in the correct order' do

          query_options = QueryRunner::QueryOptionLoader.load({ '$select' => 'id', '$top' => '3', '$filter' => "date gt datetime'2014-01-23'", '$orderBy' => 'date asc' })

          expect(query_options).to have(4).items
          expect(query_options[0]).to be_a FilterQueryOption
          expect(query_options[1]).to be_a OrderByQueryOption
          expect(query_options[2]).to be_a TopQueryOption
          expect(query_options[3]).to be_a SelectQueryOption

        end

        it 'should load only the provided query options ' do

          query_options = QueryRunner::QueryOptionLoader.load({ '$top' => '3', '$orderBy' => 'date asc' })

          expect(query_options).to have(2).items
          expect(query_options[0]).to be_a OrderByQueryOption
          expect(query_options[1]).to be_a TopQueryOption

        end

      end

    end

  end
end