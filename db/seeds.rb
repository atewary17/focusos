# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Sample planner data for your own dev account, so /plan has something in it
# the moment you open it. Never runs outside development/test, and never
# touches other users or other tables.
if Rails.env.local?
  user = User.order(:created_at).first

  if user
    Time.use_zone(user.time_zone) do
      product = user.subjects.find_or_create_by!(name: "Product") { |s| s.color = "#7c3aed" }
      growth = user.subjects.find_or_create_by!(name: "Growth") { |s| s.color = "#f97316" }
      planning = user.subjects.find_or_create_by!(name: "Planning") { |s| s.color = "#2563eb" }

      daily_notes = product.topics.find_or_create_by!(name: "Daily notes feature")
      channels = growth.topics.find_or_create_by!(name: "Secondary growth channels")
      one_on_ones = planning.topics.find_or_create_by!(name: "1:1s")

      today = Date.current
      tomorrow = today + 1
      day_after = today + 2

      seed_task = ->(title:, **attrs) do
        subtasks = attrs.delete(:subtasks) || []
        task = user.tasks.find_or_create_by!(title: title) { |t| t.assign_attributes(**attrs) }
        task.update!(subtasks: subtasks.map { |text, done| { "text" => text, "done" => done } }) if subtasks.any? && task.subtasks.empty?
        task
      end

      seed_task.call(title: "Build daily notes feature", topic: daily_notes, scheduled_on: today,
                      starts_at: today.in_time_zone.change(hour: 9), estimate_minutes: 240,
                      subtasks: [ [ "Mockups", true ], [ "Data model", true ], [ "Basic functionality", false ] ])
      seed_task.call(title: "Document customer feedback", topic: daily_notes, scheduled_on: today, estimate_minutes: 90,
                      subtasks: [ [ "Summarize customer churn surveys", true ], [ "Review top posts in Canny", true ] ])
      seed_task.call(title: "Investigate secondary growth channels", topic: channels, scheduled_on: today, estimate_minutes: 60)

      seed_task.call(title: "Answer customer support tickets", topic: channels, scheduled_on: tomorrow, estimate_minutes: 30)
      seed_task.call(title: "1:1 with Tomoa", topic: one_on_ones, scheduled_on: tomorrow,
                      starts_at: tomorrow.in_time_zone.change(hour: 11), estimate_minutes: 30)
      seed_task.call(title: "Review prototype of new feature", topic: daily_notes, scheduled_on: tomorrow,
                      starts_at: tomorrow.in_time_zone.change(hour: 13), estimate_minutes: 120)

      seed_task.call(title: "Search for local art show on First Friday", scheduled_on: day_after, estimate_minutes: 20)
      seed_task.call(title: "Investigate third growth channels", topic: channels, scheduled_on: day_after, estimate_minutes: 30)

      seed_task.call(title: "Plan next sprint", priority: 2)
      seed_task.call(title: "Clean up old branches", priority: 3)
    end

    puts "Seeded sample planner data for #{user.email_address}."
  end
end
