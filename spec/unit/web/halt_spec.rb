require_relative '../unit_helper'
require_relative '../../../app/web/halt'
require_relative '../../../spec/fake_settings'

module Hacienda
  module Test

    describe Halt do
      include FakeSettings

      it 'should halt when unauthorised' do

        content_service = double('Hacienda', {
                                               :halt => nil,
                                           })

        authorisation = double('HMACAuthorisation', { :authorised? => false })

        Halt.new(content_service, authorisation).unauthorised(double('Request'))

        content_service.should have_received(:halt).with(401)
      end

      it 'should not halt when authorised' do

        content_service = double('Hacienda', {
                                               :halt => nil,
                                           })

        authorisation = double('HMACAuthorisation', { :authorised? => true })

        Halt.new(content_service, authorisation).unauthorised(double('Request'))

        content_service.should_not have_received(:halt).with(401)
      end

    end
  end
end
