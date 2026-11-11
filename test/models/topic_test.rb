require "test_helper"

class TopicTest < ActiveSupport::TestCase
  test "fixtures are valid" do
    assert topics(:indifference_curves).valid?
    assert topics(:world_war_one).valid?
  end

  test "inherits the user from its subject" do
    topic = subjects(:economics).topics.create!(name: "Consumer theory")
    assert_equal subjects(:economics).user, topic.user
  end

  test "assigns the next position within the subject" do
    topic = subjects(:economics).topics.create!(name: "Consumer theory")
    assert_equal topics(:indifference_curves).position + 1, topic.position
  end

  test "rejects a subject that belongs to another user" do
    topic = Topic.new(user: users(:one), subject: subjects(:history), name: "Treaty of Versailles")
    assert_not topic.valid?
    assert_includes topic.errors[:subject], "must belong to you"
  end

  test "counts done and total tasks" do
    assert_equal 1, topics(:indifference_curves).tasks_count
    assert_equal 0, topics(:indifference_curves).done_tasks_count

    tasks(:read_chapter_three).update!(status: "done")
    assert_equal 1, topics(:indifference_curves).done_tasks_count
  end

  test "deleting a topic nullifies its tasks instead of destroying them" do
    topics(:indifference_curves).destroy
    assert_nil tasks(:read_chapter_three).reload.topic_id
  end
end
