module ApplicationHelper
  INPUT_CLASSES = "block w-full rounded-lg border border-stone-300 bg-white px-3 py-2.5 text-stone-900 " \
                  "placeholder:text-stone-400 focus:border-teal-600 focus:outline-none focus:ring-2 focus:ring-teal-600/20".freeze
  LABEL_CLASSES = "mb-1.5 block text-sm font-medium text-stone-700".freeze
  PRIMARY_BUTTON_CLASSES = "inline-flex w-full cursor-pointer items-center justify-center rounded-lg bg-teal-700 " \
                           "px-4 py-2.5 font-medium text-white hover:bg-teal-800 focus:outline-none " \
                           "focus:ring-2 focus:ring-teal-600/40".freeze
  DANGER_BUTTON_CLASSES = "inline-flex cursor-pointer items-center justify-center rounded-lg border border-red-300 " \
                          "bg-white px-4 py-2.5 font-medium text-red-700 hover:bg-red-50".freeze

  def input_classes = INPUT_CLASSES
  def label_classes = LABEL_CLASSES
  def primary_button_classes = PRIMARY_BUTTON_CLASSES
  def danger_button_classes = DANGER_BUTTON_CLASSES

  def greeting_for(time)
    case time.hour
    when 5..11 then "Good morning"
    when 12..16 then "Good afternoon"
    else "Good evening"
    end
  end

  def signup_requires_invite?
    ENV["SIGNUP_INVITE_CODE"].present?
  end
end
