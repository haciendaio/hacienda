require_relative 'support/functional_test_helper'

require_relative '../../spec/shared/navigation'

module Hacienda
  module Test

    describe 'Content Service Status' do
      include Navigation

      it 'should return the status' do
        status_response = get_status_response
        status_response.status.should eq 'OK'
      end

    end
  end
end
