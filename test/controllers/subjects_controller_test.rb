require "test_helper"

class SubjectsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:one) }

  test "lists the user's active and archived subjects" do
    get subjects_path
    assert_response :success
    assert_select "p", text: subjects(:economics).name
  end

  test "creates a subject for the signed-in user" do
    assert_difference -> { users(:one).subjects.count } do
      post subjects_path, params: { subject: { name: "Physics", color: "#1d4ed8" } }
    end
    assert_redirected_to subjects_path
  end

  test "rejects an invalid subject" do
    assert_no_difference -> { Subject.count } do
      post subjects_path, params: { subject: { name: "", color: "#1d4ed8" } }
    end
    assert_response :unprocessable_entity
  end

  test "archives and unarchives a subject" do
    patch subject_path(subjects(:economics)), params: { subject: { archived: true } }
    assert_not_nil subjects(:economics).reload.archived_at

    patch subject_path(subjects(:economics)), params: { subject: { archived: false } }
    assert_nil subjects(:economics).reload.archived_at
  end

  test "destroys a subject" do
    assert_difference -> { Subject.count }, -1 do
      delete subject_path(subjects(:economics))
    end
  end

  test "cannot update or destroy another user's subject" do
    patch subject_path(subjects(:history)), params: { subject: { name: "x" } }
    assert_response :not_found

    delete subject_path(subjects(:history))
    assert_response :not_found
  end
end
