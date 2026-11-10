# Export/import the whole plan (subjects, topics and tasks) as one JSON file,
# in a fixed, versioned schema - a backup, or a reusable starting template.
# Import only ever adds: it never deletes or overwrites existing records.
class PlanTemplatesController < ApplicationController
  FORMAT_VERSION = 1

  def show
    payload = {
      version: FORMAT_VERSION,
      exported_at: Time.current.iso8601,
      subjects: Current.user.subjects.active.includes(topics: :tasks).order(:position).map { |subject| subject_json(subject) },
      unscheduled_tasks: Current.user.tasks.kept.where(subject_id: nil, topic_id: nil).order(:position).map { |task| task_json(task) }
    }
    send_data JSON.pretty_generate(payload), filename: "focusos-plan-#{Date.current.iso8601}.json",
                                               type: "application/json", disposition: "attachment"
  end

  def create
    file = params[:file]
    if file.blank?
      return redirect_to subjects_path, alert: "Choose a FocusOS plan export file first."
    end

    data = JSON.parse(file.read)
    if data["version"] != FORMAT_VERSION
      return redirect_to subjects_path, alert: "This file is from an unsupported FocusOS export version."
    end

    counts = import_plan(data)
    redirect_to subjects_path, notice: "Imported #{counts[:subjects]} subject(s), #{counts[:topics]} topic(s), " \
                                        "#{counts[:tasks]} task(s)."
  rescue JSON::ParserError
    redirect_to subjects_path, alert: "That file isn't a valid FocusOS plan export."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to subjects_path, alert: "Couldn't import that file: #{e.record.errors.full_messages.to_sentence}."
  end

  private
    def subject_json(subject)
      { name: subject.name, color: subject.color, weekly_target_minutes: subject.weekly_target_minutes,
        topics: subject.topics.map { |topic| topic_json(topic) },
        tasks: subject.tasks.kept.where(topic_id: nil).map { |task| task_json(task) } }
    end

    def topic_json(topic)
      { name: topic.name, estimated_minutes: topic.estimated_minutes,
        tasks: topic.tasks.kept.map { |task| task_json(task) } }
    end

    def task_json(task)
      { title: task.title, notes: task.notes, priority: task.priority, estimate_minutes: task.estimate_minutes,
        energy: task.energy, due_on: task.due_on&.iso8601, scheduled_on: task.scheduled_on&.iso8601,
        starts_time: task.starts_at&.in_time_zone&.strftime("%H:%M"),
        subtasks: task.subtasks.map { |s| { text: s["text"], done: s["done"] } } }
    end

    def import_plan(data)
      counts = { subjects: 0, topics: 0, tasks: 0 }

      Task.transaction do
        Array(data["subjects"]).each do |subject_data|
          subject = Current.user.subjects.find_or_create_by!(name: subject_data["name"].to_s.presence || "Untitled") do |s|
            s.color = subject_data["color"].presence || "#0f766e"
            s.weekly_target_minutes = subject_data["weekly_target_minutes"]
          end
          counts[:subjects] += 1

          Array(subject_data["topics"]).each do |topic_data|
            topic = subject.topics.create!(user: Current.user, name: topic_data["name"].to_s.presence || "Untitled",
                                            estimated_minutes: topic_data["estimated_minutes"])
            counts[:topics] += 1
            Array(topic_data["tasks"]).each do |task_data|
              import_task(task_data, subject: subject, topic: topic)
              counts[:tasks] += 1
            end
          end

          Array(subject_data["tasks"]).each do |task_data|
            import_task(task_data, subject: subject)
            counts[:tasks] += 1
          end
        end

        Array(data["unscheduled_tasks"]).each do |task_data|
          import_task(task_data)
          counts[:tasks] += 1
        end
      end

      counts
    end

    def import_task(task_data, subject: nil, topic: nil)
      Current.user.tasks.create!(
        title: task_data["title"].to_s.presence || "Untitled",
        notes: task_data["notes"],
        priority: normalize_priority(task_data["priority"]),
        estimate_minutes: task_data["estimate_minutes"],
        energy: normalize_energy(task_data["energy"]),
        due_on: parse_date(task_data["due_on"]),
        scheduled_on: parse_date(task_data["scheduled_on"]),
        starts_at: parse_starts_at(task_data["scheduled_on"], task_data["starts_time"]),
        subtasks: Array(task_data["subtasks"]).filter_map { |s| subtask_from(s) },
        subject: subject,
        topic: topic
      )
    end

    def subtask_from(subtask_data)
      text = subtask_data["text"].to_s
      return nil if text.blank?

      { "text" => text, "done" => ActiveModel::Type::Boolean.new.cast(subtask_data["done"]) }
    end

    # External files (hand-written, or from another tool) may use values our
    # fixed enums don't - e.g. "medium" energy. Drop what we don't recognize
    # rather than fail the whole import over one field.
    def normalize_energy(value)
      value if Task::ENERGIES.include?(value)
    end

    def normalize_priority(value)
      value if (1..3).cover?(value)
    end

    def parse_date(value)
      Date.iso8601(value) if value.present?
    rescue ArgumentError
      nil
    end

    def parse_starts_at(date_value, time_value)
      return nil if date_value.blank? || time_value.blank?

      Time.zone.parse("#{date_value} #{time_value}")
    end
end
