from __future__ import absolute_import
from __future__ import unicode_literals

import random
from datetime import datetime
from datetime import timedelta

from django.conf.urls import url
from django.contrib import messages
from django.contrib.admin import AdminSite
from django.shortcuts import redirect

from .models import Participant
from .models import Train


class AdminSite(AdminSite):
    site_header = 'FoodTrain Admin'

    def get_urls(self):
        urls = super(AdminSite, self).get_urls()
        my_urls = [
            url(r'^reset/$', self.reset),
        ]
        return my_urls + urls


admin_site = AdminSite(name='myadmin')
admin_site.register(Train)
admin_site.register(Participant)
