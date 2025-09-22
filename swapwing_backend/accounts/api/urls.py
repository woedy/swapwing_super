from django.urls import path

from accounts.api.views.user_views import UserLogin, confirm_otp_view, \
    PasswordResetView, new_password_reset_view, resend_email_verification, \
    check_user_email_exist, user_registration_view, verify_user_email, pre_add_desires, check_username_and_email_exist, \
    check_username_exist, check_email_exist

app_name = 'accounts'

urlpatterns = [
    # CLIENT URLS
    path('login-user', UserLogin.as_view(), name="login_user"),
    path('check-username-and-email-exist', check_username_and_email_exist, name="check_username_and_email_exist"),

    path('check-username-exist', check_username_exist, name="check_username_exist"),
    path('check-email-exist', check_email_exist, name="check_username_exist"),
    path('check-user-email-exist', check_user_email_exist, name="check_user_email_exist"),
    path('register-user', user_registration_view, name="user_registration_view"),
    path('verify-user-email', verify_user_email, name="verify_user_email"),
    path('forgot-user-password', PasswordResetView.as_view(), name="forgot_password"),
    path('confirm-otp', confirm_otp_view, name="confirm_otp_view"),
    path('resend-email-verification', resend_email_verification, name="resend_email_verification"),
    path('new-password-reset-view', new_password_reset_view, name="new_password_reset_view"),
    path('pre-add-desire', pre_add_desires, name="pre_add_desires"),
    #path('create-new-password', PasswordChangeView.as_view(), name="create_new_password_view"),

    #path('logout-user', logout_user, name="logout_user"),

]
