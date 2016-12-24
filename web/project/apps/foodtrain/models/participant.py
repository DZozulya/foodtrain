from __future__ import absolute_import
from __future__ import unicode_literals

from django.db import models


class Participant(models.Model):
    name = models.CharField(max_length=50, unique=True)

    def __str__(self):
        return self.name

    class Meta:
        app_label = 'foodtrain'
