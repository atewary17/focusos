require "test_helper"

class SubjectTest < ActiveSupport::TestCase
  test "fixtures are valid" do
    assert subjects(:economics).valid?
    assert subjects(:history).valid?
  end

  test "assigns the next position for the user" do
    subject = users(:one).subjects.create!(name: "Physics", color: "#000000")
    assert_equal subjects(:economics).position + 1, subject.position
  end

  test "requires a hex color" do
    subject = Subject.new(user: users(:one), name: "Physics", color: "teal")
    assert_not subject.valid?
    assert_includes subject.errors[:color], "must be a hex color like #0f766e"
  end

  test "weekly target must be positive" do
    subject = Subject.new(user: users(:one), name: "Physics", color: "#000000", weekly_target_minutes: 0)
    assert_not subject.valid?
  end

  test "archived? reflects archived_at" do
    assert_not subjects(:economics).archived?
    subjects(:economics).update!(archived_at: Time.current)
    assert subjects(:economics).archived?
  end

  test "destroying a subject destroys its topics but only nullifies its tasks" do
    topic_id = topics(:indifference_curves).id
    subjects(:economics).destroy

    assert_not Topic.exists?(topic_id)
    assert_nil tasks(:read_chapter_three).reload.subject_id
  end
end
