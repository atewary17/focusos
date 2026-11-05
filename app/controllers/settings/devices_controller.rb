module Settings
  class DevicesController < ApplicationController
    def index
      @devices = Current.user.devices.includes(:api_tokens).order(created_at: :desc)
    end

    # Signs the device out by deleting its tokens. Data it already uploaded is kept.
    def destroy
      device = Current.user.devices.find(params[:id])
      device.api_tokens.destroy_all
      redirect_to settings_devices_path, notice: "#{device.name} is signed out. Its uploaded data is kept."
    end
  end
end
