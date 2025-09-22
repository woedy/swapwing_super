import json
import re

import requests

from django.conf import settings
from django.contrib.auth import get_user_model, authenticate
from django.contrib.auth.decorators import login_required
from django.contrib.auth.hashers import check_password
from django.contrib.auth.password_validation import validate_password
from django.core.mail import send_mail
from django.template.loader import get_template
from rest_framework import status, generics
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.api.serializers import PasswordResetSerializer, UserRegistrationSerializer
from all_activities.models import AllActivity
from garage.models import UserDesire, Garage

from mysite.utils import generate_random_otp_code, generate_email_token, base64_file
from user_profile.models import PersonalInfo, Wallet

User = get_user_model()



#####################################################################
#
#
#  USER VIEWS
#
#
#####################################################################


# Login Susu user





class UserLogin(APIView):
    authentication_classes = []
    permission_classes = []

    def post(self, request):
        payload = {}
        data = {}

        email = request.data.get('email', '0')
        password = request.data.get('password', '0')
        fcm_token = request.data.get('fcm_token', '0')

        errors = {}
        email_errors = []
        password_errors = []
        fcm_token_errors = []

        print(email)
        print(password)
        print(fcm_token)

        if not email:
            email_errors.append('Email is required.')
        if email_errors:
            errors['email'] = email_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)


        if not password:
            password_errors.append('Password is required.')
        if password_errors:
            errors['password'] = password_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        if not fcm_token:
            fcm_token_errors.append('FCM device token required.')
        if fcm_token_errors:
            errors['fcm_token'] = fcm_token_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)


        qs = User.objects.filter(email=email)
        if qs.exists():
            not_active = qs.filter(email_verified=False)
            if not_active:
                reconfirm_msg = "resend confirmation email."
                msg1 = "Please check your email to confirm your account or " + reconfirm_msg.lower()
                email_errors.append(msg1)
            if email_errors:
                errors['email'] = email_errors
                payload['message'] = "Error"
                payload['errors'] = errors
                return Response(payload, status=status.HTTP_404_NOT_FOUND)

        if not check_password(email, password):
            email_errors.append('Invalid Credentials')
            if email_errors:
                errors['email'] = email_errors
                payload['message'] = "Error"
                payload['errors'] = errors
                return Response(payload, status=status.HTTP_404_NOT_FOUND)

        user = authenticate(email=email, password=password)
        if not user:
            email_errors.append('Invalid Credentials')
            if email_errors:
                errors['email'] = email_errors
                payload['message'] = "Error"
                payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        else:
            try:
                token = Token.objects.get(user=user)
            except Token.DoesNotExist:
                token = Token.objects.create(user=user)

            try:
                user_personal_info = PersonalInfo.objects.get(user=user)
            except PersonalInfo.DoesNotExist:
                user_personal_info = PersonalInfo.objects.create(user=user)

            user_personal_info.active = True

            user_personal_info.save()

            user.fcm_token = fcm_token
            user.save()

            data["user_id"] = user.user_id
            data["email"] = user.email
            data["first_name"] = user.first_name
            data["last_name"] = user.last_name
            data["token"] = token.key

            payload['message'] = "Successful"
            payload['data'] = data

            new_activity = AllActivity.objects.create(
                user=user,
                subject="User Login",
                body=user.email + " Just logged in."
            )
            new_activity.save()

        return Response(payload, status=status.HTTP_200_OK)




def check_password(email, password):
    try:
        user = User.objects.get(email=email)
        return user.check_password(password)
    except User.DoesNotExist:
        return False



@api_view(['POST', ])
@permission_classes([])
@authentication_classes([])
def check_username_exist(request):
    payload = {}
    data = {}
    errors = {}
    username_errors = []

    username = request.data.get('username', '0').lower()

    print(username)

    qs = User.objects.filter(username=username)
    if qs.exists():
        payload['message'] = "Successful"
        return Response(payload, status=status.HTTP_200_OK)
    else:
        payload['message'] = "Error"
        return Response(payload, status=status.HTTP_404_NOT_FOUND)



@api_view(['POST', ])
@permission_classes([])
@authentication_classes([])
def check_email_exist(request):
    payload = {}


    email = request.data.get('email', '0').lower()

    print(email)

    qs = User.objects.filter(email=email)
    if qs.exists():
        payload['message'] = "Successful"
        return Response(payload, status=status.HTTP_200_OK)
    else:
        payload['message'] = "Error"
        return Response(payload, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST', ])
@permission_classes([])
@authentication_classes([])
def check_user_email_exist(request):
    payload = {}
    data = {}
    errors = {}
    email_errors = []

    email = request.data.get('email', '0').lower()


    if not email:
        email_errors.append('Email is required.')
        if email_errors:
            errors['email'] = email_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    qs = User.objects.filter(email=email)
    if qs.exists():
        email_errors.append('Email is already exists.')
        if email_errors:
            errors['email'] = email_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    payload['message'] = "Successful"
    payload['data'] = {
        "email": "Email not available in our database."
    }

    return Response(payload, status=status.HTTP_200_OK)

@api_view(['POST', ])
@permission_classes([])
@authentication_classes([])
def check_username_and_email_exist(request):
    payload = {}
    errors = {}
    email_errors = []
    username_errors = []

    username = request.data.get('username', '').lower()
    email = request.data.get('email', '').lower()

    if not email:
        email_errors.append('Email is required.')
    else:
        qs = User.objects.filter(email=email)
        if qs.exists():
            email_errors.append('Email already exists.')

    if not username:
        username_errors.append('Username is required.')
    else:
        qs = User.objects.filter(username=username)
        if qs.exists():
            username_errors.append('Username already exists.')

    if email_errors:
        errors['email'] = email_errors

    if username_errors:
        errors['username'] = username_errors

    if email_errors or username_errors:
        payload['message'] = "Error"
        payload['errors'] = errors
        return Response(payload, status=status.HTTP_404_NOT_FOUND)

    payload['message'] = "Successful"
    payload['data'] = {
        "email": "Email not available in our database.",
        "username": "Username not available in our database."
    }

    return Response(payload, status=status.HTTP_200_OK)

@api_view(['POST', ])
@permission_classes([])
@authentication_classes([])
def user_registration_view(request):
    payload = {}
    data = {}
    errors = {}
    email_errors = []

    email = request.data.get('email', '0').lower()
    username = request.data.get('username', '0')
    first_name = request.data.get('first_name', '0')
    last_name = request.data.get('last_name', '0')
    password = request.data.get('password', '0')
    password2 = request.data.get('password2', '0')
    phone = request.data.get('phone', '0')
    country = request.data.get('country', '0')
    gender = request.data.get('gender', '0')



    if not email:
        email_errors.append('Email is required.')
        if email_errors:
            errors['email'] = email_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    qs = User.objects.filter(email=email)
    if qs.exists():
        email_errors.append('Email is already exists.')
        if email_errors:
            errors['email'] = email_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)




    serializer = UserRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        data['email'] = user.email
        data['first_name'] = user.first_name
        data['last_name'] = user.last_name

        personal_info = PersonalInfo.objects.get(user=user)
        personal_info.phone = phone
        personal_info.country = country
        personal_info.gender = gender


        personal_info.save()

        data['phone'] = personal_info.phone

        wallet = Wallet.objects.create(
            user=user,
        )


        token = Token.objects.get(user=user).key
        data['token'] = token

        email_token = generate_email_token()

        user = User.objects.get(email=email)
        user.email_token = email_token
        user.save()

        context = {
            'email_token': email_token,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name
        }

        txt_ = get_template("registration/emails/verify.txt").render(context)
        html_ = get_template("registration/emails/verify.html").render(context)

        subject = 'EMAIL CONFIRMATION CODE'
        from_email = settings.DEFAULT_FROM_EMAIL
        recipient_list = [user.email]

        sent_mail = send_mail(
            subject,
            txt_,
            from_email,
            recipient_list,
            html_message=html_,
            fail_silently=False
        )

        new_activity = AllActivity.objects.create(
            user=user,
            subject="User Registration",
            body=user.email + " Just created an account."
        )
        new_activity.save()

        garage = Garage.objects.create(
            user=user,
        )


    payload['message'] = "Successful"
    payload['data'] = data

    return Response(payload, status=status.HTTP_200_OK)



@api_view(['POST', ])
@permission_classes([])
@authentication_classes([])
def user_registration_view222(request):
    payload = {}
    data = {}
    errors = {}
    email_errors = []
    password_errors = []
    first_name_errors = []
    last_name_errors = []
    phone_errors = []
    photo_errors = []

    email = request.data.get('email', '0').lower()
    username = request.data.get('username', '0')
    first_name = request.data.get('first_name', '0')
    last_name = request.data.get('last_name', '0')
    password = request.data.get('password', '0')
    password2 = request.data.get('password2', '0')
    phone = request.data.get('phone', '0')
    photo = request.data.get('photo', '0')
    country = request.data.get('country', '0')
    gender = request.data.get('gender', '0')


    # CHECK PASSWORD FIRST
    if validate_password(password) == "Password is too weak. It should be at least 5 characters long.":
        password_errors.append('Password is too weak. It should be at least 5 characters long.')
        if password_errors:
            errors['password'] = password_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)


    if not email:
        email_errors.append('Email is required.')
        if email_errors:
            errors['email'] = email_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    qs = User.objects.filter(email=email)
    if qs.exists():
        email_errors.append('Email is already exists.')
        if email_errors:
            errors['email'] = email_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)



    if not password:
        password_errors.append('Password required.')
        if password_errors:
            errors['password'] = password_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    if password != password2:
        password_errors.append('Password don\'t match.')
        if password_errors:
            errors['password'] = password_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    if not phone:
        phone_errors.append('Phone number required.')
        if phone_errors:
            errors['phone'] = phone_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    serializer = UserRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        data['email'] = user.email
        data['first_name'] = user.first_name
        data['last_name'] = user.last_name

        personal_info = PersonalInfo.objects.get(user=user)
        personal_info.phone = phone
        personal_info.country = country
        personal_info.gender = gender
        personal_info.photo = base64_file(photo)


        personal_info.save()

        data['phone'] = personal_info.phone

        wallet = Wallet.objects.create(
            user=user,
        )


        token = Token.objects.get(user=user).key
        data['token'] = token

        email_token = generate_email_token()

        user = User.objects.get(email=email)
        user.email_token = email_token
        user.save()

        context = {
            'email_token': email_token,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name
        }

        txt_ = get_template("registration/emails/verify.txt").render(context)
        html_ = get_template("registration/emails/verify.html").render(context)

        subject = 'EMAIL CONFIRMATION CODE'
        from_email = settings.DEFAULT_FROM_EMAIL
        recipient_list = [user.email]

        sent_mail = send_mail(
            subject,
            txt_,
            from_email,
            recipient_list,
            html_message=html_,
            fail_silently=False
        )

        new_activity = AllActivity.objects.create(
            user=user,
            subject="User Registration",
            body=user.email + " Just created an account."
        )
        new_activity.save()

        garage = Garage.objects.create(
            user=user,
        )


    payload['message'] = "Successful"
    payload['data'] = data

    return Response(payload, status=status.HTTP_200_OK)




def validate_password(password):
    if len(password) < 5:
        return "Password is too weak. It should be at least 5 characters long."

    # Check for at least one lowercase letter, one uppercase letter, and one digit
    if not re.search(r'[a-z]', password) or not re.search(r'[A-Z]', password) or not re.search(r'\d', password):
        return "Password is too weak. It should contain a mix of lowercase letters, uppercase letters, and numbers."

    # Evaluate password strength
    strength = 0
    if len(password) >= 8:
        strength += 1
    if re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        strength += 1
    if re.search(r'[A-Za-z0-9]*([A-Za-z][0-9]|[0-9][A-Za-z])[A-Za-z0-9]*', password):
        strength += 1

    if strength < 2:
        return "Password is weak. Try adding more complexity."
    elif strength < 3:
        return "Password is moderate in strength."
    else:
        return "Password is strong."



@api_view(['POST', ])
@permission_classes([])
@authentication_classes([])
def verify_user_email(request):
    payload = {}
    data = {}
    errors = {}
    email_errors = []
    token_errors = []
    password_errors = []

    email = request.data.get('email', '0').lower()
    email_token = request.data.get('email_token', '0')

    if not email:
        email_errors.append('Email is required.')
    if email_errors:
        errors['email'] = email_errors
        payload['message'] = "Error"
        payload['errors'] = errors
        return Response(payload, status=status.HTTP_404_NOT_FOUND)

    qs = User.objects.filter(email=email)
    if not qs.exists():
        email_errors.append('Email does not exist.')
        if email_errors:
            errors['email'] = email_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    if not email_token:
        token_errors.append('Token is required.')
        if token_errors:
            errors['token'] = token_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    user = User.objects.get(email=email)
    if email_token != user.email_token:
        token_errors.append('Invalid Token.')
        if token_errors:
            errors['token'] = token_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    try:
        user_personal_info = PersonalInfo.objects.get(user=user)
    except PersonalInfo.DoesNotExist:
        user_personal_info = PersonalInfo.objects.create(user=user)

    try:
        token = Token.objects.get(user=user)
    except Token.DoesNotExist:
        token = Token.objects.create(user=user)

    user.is_active = True
    user.email_verified = True
    user.save()


    data["user_id"] = user.user_id
    data["email"] = user.email
    data["first_name"] = user.first_name
    data["last_name"] = user.last_name
    data["token"] = token.key

    payload['message'] = "Successful"
    payload['data'] = data

    new_activity = AllActivity.objects.create(
        user=user,
        subject="Verify Email",
        body=user.email + " just verified their email",
    )
    new_activity.save()

    return Response(payload, status=status.HTTP_200_OK)



@api_view(['POST', ])
@permission_classes([])
@authentication_classes([])
def verify_user_email22222(request):
    payload = {}
    data = {}
    errors = {}
    email_errors = []
    token_errors = []
    password_errors = []

    email = request.data.get('email', '0').lower()
    email_token = request.data.get('email_token', '0')

    if not email:
        email_errors.append('Email is required.')
    if email_errors:
        errors['email'] = email_errors
        payload['message'] = "Error"
        payload['errors'] = errors
        return Response(payload, status=status.HTTP_404_NOT_FOUND)

    qs = User.objects.filter(email=email)
    if not qs.exists():
        email_errors.append('Email does not exist.')
        if email_errors:
            errors['email'] = email_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    if not email_token:
        token_errors.append('Token is required.')
        if token_errors:
            errors['token'] = token_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    user = User.objects.get(email=email)
    if email_token != user.email_token:
        token_errors.append('Invalid Token.')
        if token_errors:
            errors['token'] = token_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    try:
        user_personal_info = PersonalInfo.objects.get(user=user)
    except PersonalInfo.DoesNotExist:
        user_personal_info = PersonalInfo.objects.create(user=user)

    try:
        token = Token.objects.get(user=user)
    except Token.DoesNotExist:
        token = Token.objects.create(user=user)

    user.is_active = True
    user.email_verified = True
    user.save()


    data["user_id"] = user.user_id
    data["email"] = user.email
    data["first_name"] = user.first_name
    data["last_name"] = user.last_name
    data["token"] = token.key

    payload['message'] = "Successful"
    payload['data'] = data

    new_activity = AllActivity.objects.create(
        user=user,
        subject="Verify Email",
        body=user.email + " just verified their email",
    )
    new_activity.save()

    return Response(payload, status=status.HTTP_200_OK)



class PasswordResetView(generics.GenericAPIView):
    serializer_class = PasswordResetSerializer



    def post(self, request, *args, **kwargs):
        payload = {}
        data = {}
        errors = {}
        email_errors = []

        email = request.data.get('email', '0').lower()

        if not email:
            email_errors.append('Email is required.')
        if email_errors:
            errors['email'] = email_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        qs = User.objects.filter(email=email)
        if not qs.exists():
            email_errors.append('Email does not exist.')
            if email_errors:
                errors['email'] = email_errors
                payload['message'] = "Error"
                payload['errors'] = errors
                return Response(payload, status=status.HTTP_404_NOT_FOUND)


        user = User.objects.filter(email=email).first()
        otp_code = generate_random_otp_code()
        user.otp_code = otp_code
        user.save()

        context = {
            'otp_code': otp_code,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name
        }

        txt_ = get_template("registration/emails/send_otp.txt").render(context)
        html_ = get_template("registration/emails/send_otp.html").render(context)

        subject = 'OTP CODE'
        from_email = settings.DEFAULT_FROM_EMAIL
        recipient_list = [user.email]

        sent_mail = send_mail(
            subject,
            txt_,
            from_email,
            recipient_list,
            html_message=html_,
            fail_silently=False
        )
        data["otp_code"] = otp_code
        data["emai"] = user.email
        data["user_id"] = user.user_id

        new_activity = AllActivity.objects.create(
            user=user,
            subject="Reset Password",
            body="OTP sent to " + user.email,
        )
        new_activity.save()

        payload['message'] = "Successful"
        payload['data'] = data

        return Response(payload, status=status.HTTP_200_OK)



# Confirm OTP


@api_view(['POST', ])
@permission_classes([])
@authentication_classes([])
def confirm_otp_view(request):
    payload = {}
    data = {}
    errors = {}
    email_errors = []
    otp_errors = []

    email = request.data.get('email', '0')
    otp_code = request.data.get('otp_code', '0')

    if not email:
        email_errors.append('Email is required.')
    if email_errors:
        errors['email'] = email_errors
        payload['message'] = "Error"
        payload['errors'] = errors
        return Response(payload, status=status.HTTP_404_NOT_FOUND)

    if not otp_code:
        otp_errors.append('OTP code is required.')
    if otp_errors:
        errors['otp_code'] = otp_errors
        payload['message'] = "Error"
        payload['errors'] = errors
        return Response(payload, status=status.HTTP_404_NOT_FOUND)

    user = User.objects.filter(email=email).first()

    if user is None:
        email_errors.append('Email does not exist.')
    if email_errors:
        errors['email'] = email_errors
        payload['message'] = "Error"
        payload['errors'] = errors
        return Response(payload, status=status.HTTP_404_NOT_FOUND)


    client_otp = user.otp_code

    if client_otp != otp_code:
        otp_errors.append('Invalid Code.')
    if otp_errors:
        errors['otp_code'] = otp_errors
        payload['message'] = "Error"
        payload['errors'] = errors
        return Response(payload, status=status.HTTP_404_NOT_FOUND)



    data['email'] = user.email
    data['user_id'] = user.user_id

    payload['message'] = "Successful"
    payload['data'] = data
    return Response(payload, status=status.HTTP_200_OK)



@api_view(['POST', ])
@permission_classes([AllowAny])
@authentication_classes([])
def new_password_reset_view(request):
    payload = {}
    data = {}
    errors = {}
    email_errors = []
    password_errors = []

    email = request.data.get('email', '0')
    new_password = request.data.get('new_password')
    new_password2 = request.data.get('new_password2')



    if not email:
        email_errors.append('Email is required.')
        if email_errors:
            errors['email'] = email_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    qs = User.objects.filter(email=email)
    if not qs.exists():
        email_errors.append('Email does not exists.')
        if email_errors:
            errors['email'] = email_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)


    if not new_password:
        password_errors.append('Password required.')
        if password_errors:
            errors['password'] = password_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)


    if new_password != new_password2:
        password_errors.append('Password don\'t match.')
        if password_errors:
            errors['password'] = password_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    user = User.objects.filter(email=email).first()
    user.set_password(new_password)
    user.save()

    data['email'] = user.email
    data['user_id'] = user.user_id


    payload['message'] = "Successful, Password reset successfully."
    payload['data'] = data

    return Response(payload, status=status.HTTP_200_OK)


@api_view(['POST', ])
@permission_classes([AllowAny])
@authentication_classes([])
def resend_email_verification(request):
    payload = {}
    data = {}
    errors = {}
    email_errors = []


    email = request.data.get('email', '0').lower()

    if not email:
        email_errors.append('Email is required.')
    if email_errors:
        errors['email'] = email_errors
        payload['message'] = "Error"
        payload['errors'] = errors
        return Response(payload, status=status.HTTP_404_NOT_FOUND)

    qs = User.objects.filter(email=email)
    if not qs.exists():
        email_errors.append('Email does not exist.')
        if email_errors:
            errors['email'] = email_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    user = User.objects.filter(email=email).first()
    otp_code = generate_random_otp_code()
    user.otp_code = otp_code
    user.save()

    context = {
        'otp_code': otp_code,
        'email': user.email,
        'first_name': user.first_name,
        'last_name': user.last_name
    }

    txt_ = get_template("registration/emails/send_otp.txt").render(context)
    html_ = get_template("registration/emails/send_otp.html").render(context)

    subject = 'OTP CODE'
    from_email = settings.DEFAULT_FROM_EMAIL
    recipient_list = [user.email]

    sent_mail = send_mail(
        subject,
        txt_,
        from_email,
        recipient_list,
        html_message=html_,
        fail_silently=False
    )
    data["otp_code"] = otp_code
    data["emai"] = user.email
    data["user_id"] = user.user_id

    new_activity = AllActivity.objects.create(
        user=user,
        subject="Email verification sent",
        body="Email verification sent to " + user.email,
    )
    new_activity.save()

    payload['message'] = "Successful"
    payload['data'] = data

    return Response(payload, status=status.HTTP_200_OK)




@api_view(['POST', ])
@permission_classes([AllowAny])
@authentication_classes([])
def pre_add_desires(request):
    payload = {}
    data = {}
    errors = {}
    email_errors = []


    email = request.data.get('email', '0').lower()
    desires = request.data.get('desires', '0')

    if not email:
        email_errors.append('Email is required.')
    if email_errors:
        errors['email'] = email_errors
        payload['message'] = "Error"
        payload['errors'] = errors
        return Response(payload, status=status.HTTP_404_NOT_FOUND)



    qs = User.objects.filter(email=email)
    if not qs.exists():
        email_errors.append('Email does not exist.')
        if email_errors:
            errors['email'] = email_errors
            payload['message'] = "Error"
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

    user = User.objects.filter(email=email).first()

    for desire in desires:
        user_desire = UserDesire.objects.create(
            user=user,
            desire=desire,
        )
        print(desire)



    payload['message'] = "Successful"
    payload['data'] = data

    return Response(payload, status=status.HTTP_200_OK)








