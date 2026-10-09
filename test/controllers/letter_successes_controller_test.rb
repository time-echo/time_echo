require "test_helper"

class LetterSuccessesControllerTest < ActionDispatch::IntegrationTest
  test "should redirect when no flash data" do
    get success_letters_path
    assert_redirected_to root_path
  end

  test "should show success page with flash data" do
    post letters_path, params: { letter_form: { title: "Test", email: "test@example.com", content: "This is a meaningful reflection for my future self to read in one year from today.", deliver_at: 1.year.from_now.to_s } }
    assert_redirected_to success_letters_path
    follow_redirect!
    assert_response :success
    refute_includes response.body, "&amp;larr;"
    assert_select "span", text: /Sello:/
    assert_select "span", text: /Apertura programada/
    assert_select "span", text: /de \w+ de/
  end

  test "should render success page in English when locale is en" do
    I18n.with_locale(:en) do
      post letters_path, params: { letter_form: { title: "Test", email: "test@example.com", content: "This is a meaningful reflection for my future self to read in one year from today.", deliver_at: 1.year.from_now.to_s } }
      assert_redirected_to success_letters_path
      follow_redirect!
      assert_response :success
      refute_includes response.body, "&amp;larr;"
      assert_select "span", text: /Seal:/
      assert_select "span", text: /Scheduled opening/
      assert_select "span", text: /#{1.year.from_now.strftime("%B")}/
    end
  end

  test "should show next steps confirmation instructions" do
    post letters_path, params: { letter_form: { title: "Test", email: "test@example.com", content: "This is a meaningful reflection for my future self to read in one year from today.", deliver_at: 1.year.from_now.to_s } }
    follow_redirect!
    assert_includes response.body, I18n.t("letters.success_next_desc", email: "test@example.com")
  end
end
