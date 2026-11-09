require "test_helper"

class TopicsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:one) }

  test "creates a topic under one of the user's subjects" do
    assert_difference -> { subjects(:economics).topics.count } do
      post subject_topics_path(subjects(:economics)), params: { topic: { name: "Consumer theory" } }
    end
    assert_redirected_to subjects_path
  end

  test "cannot add a topic to another user's subject" do
    post subject_topics_path(subjects(:history)), params: { topic: { name: "Treaty of Versailles" } }
    assert_response :not_found
  end

  test "updates and destroys the user's own topic" do
    patch topic_path(topics(:indifference_curves)), params: { topic: { name: "Renamed" } }
    assert_equal "Renamed", topics(:indifference_curves).reload.name

    delete topic_path(topics(:indifference_curves))
    assert_not Topic.exists?(topics(:indifference_curves).id)
  end

  test "cannot update or destroy another user's topic" do
    patch topic_path(topics(:world_war_one)), params: { topic: { name: "x" } }
    assert_response :not_found

    delete topic_path(topics(:world_war_one))
    assert_response :not_found
  end
end
