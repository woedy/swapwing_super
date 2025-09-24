import os

import pytest


os.environ.setdefault("DJANGO_SETTINGS_MODULE", "mysite.settings")


@pytest.fixture(autouse=True)
def _configure_test_environment(settings):
    settings.EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"
    settings.CELERY_TASK_ALWAYS_EAGER = True
    settings.CELERY_TASK_EAGER_PROPAGATES = True
    settings.CHANNEL_LAYERS = {
        "default": {"BACKEND": "channels.layers.InMemoryChannelLayer"}
    }
