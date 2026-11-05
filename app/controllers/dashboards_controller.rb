class DashboardsController < ApplicationController
  def show
    @dashboard = Dashboard.new(Current.user, days: params[:days].to_i)
  end
end
