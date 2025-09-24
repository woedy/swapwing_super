from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase


class SchemaEndpointTests(APITestCase):
    def test_openapi_schema_endpoint_available(self):
        response = self.client.get(reverse("api-schema"), HTTP_ACCEPT="application/json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("openapi", response.data)

    def test_swagger_ui_endpoint_served(self):
        response = self.client.get(reverse("api-docs"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn(b"SwaggerUIBundle", response.content)
