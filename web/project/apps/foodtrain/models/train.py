from __future__ import absolute_import
from __future__ import unicode_literals

from django.db import models

from .participant import Participant


class Train(models.Model):
    creator = models.ForeignKey(Participant, related_name='creators')
    restaurant_name = models.CharField(max_length=255)
    start_time = models.DateTimeField()
    yelp_id = models.CharField(max_length=255)
    participants = models.ManyToManyField(Participant)

    def __str__(self):
        return self.restaurant_name

    class Meta:
        app_label = 'foodtrain'
        ordering = ('-start_time',)
