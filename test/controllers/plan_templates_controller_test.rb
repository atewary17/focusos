require "test_helper"

class PlanTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:one) }

  test "exports the user's own plan as JSON, excluding other users' data" do
    get plan_template_path

    assert_response :success
    assert_equal "application/json", response.media_type
    body = response.parsed_body

    assert_equal 1, body["version"]
    subject = body["subjects"].find { |s| s["name"] == "Economics" }
    assert subject, "expected the Economics subject in the export"
    topic = subject["topics"].find { |t| t["name"] == "Indifference curves" }
    assert_equal [ "Read chapter 3" ], topic["tasks"].pluck("title")
    assert_not body["subjects"].any? { |s| s["name"] == "History" }
  end

  test "imports subjects, topics and tasks under the signed-in user" do
    file = fixture_file("plan_template.json", "application/json")

    assert_difference [ "Subject.count", "Topic.count", "Task.count" ], 1 do
      post plan_template_path, params: { file: file }
    end

    assert_redirected_to subjects_path
    subject = users(:one).subjects.find_by!(name: "Imported Subject")
    topic = subject.topics.find_by!(name: "Imported Topic")
    task = topic.tasks.find_by!(title: "Imported Task")
    assert_equal users(:one), task.user
    assert_equal [ { "text" => "Step one", "done" => true } ], task.subtasks
  end

  test "rejects a file with the wrong version" do
    file = fixture_upload({ version: 2, subjects: [] }, "wrong_version.json")

    assert_no_difference -> { Subject.count } do
      post plan_template_path, params: { file: file }
    end
    assert_redirected_to subjects_path
    assert_match(/unsupported/i, flash[:alert])
  end

  test "rejects a file that isn't valid JSON" do
    file = Rack::Test::UploadedFile.new(StringIO.new("not json"), "application/json", original_filename: "bad.json")

    assert_no_difference -> { Subject.count } do
      post plan_template_path, params: { file: file }
    end
    assert_redirected_to subjects_path
    assert_match(/valid FocusOS plan export/i, flash[:alert])
  end

  test "requires a file" do
    post plan_template_path
    assert_redirected_to subjects_path
    assert_match(/choose/i, flash[:alert])
  end

  private
    def fixture_file(name, content_type)
      Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/#{name}"), content_type)
    end

    def fixture_upload(hash, filename)
      Rack::Test::UploadedFile.new(StringIO.new(hash.to_json), "application/json", original_filename: filename)
    end
end
