class PhoneController < ApplicationController
  def show
    @report = PhoneReport.new(Current.user)
  end
end
