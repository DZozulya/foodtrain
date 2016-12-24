"""project URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/1.10/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  url(r'^$', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  url(r'^$', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.conf.urls import url, include
    2. Add a URL to urlpatterns:  url(r'^blog/', include('blog.urls'))
"""
from __future__ import absolute_import
from __future__ import unicode_literals

from apps.foodtrain import admin
from apps.foodtrain import views
from django.conf.urls import include
from django.conf.urls import url

urlpatterns = [
    url(r'^$', views.APIRoot.as_view()),
    url(r'^trains/$', views.train_list, name='train_list'),
    url(r'^train/(?P<pk>[0-9]+)$', views.train_detail, name='train_detail'),
    url(r'^train/(?P<pk>[0-9]+)/join/$', views.train_join, name='train_join'),
    url(r'^train/(?P<pk>[0-9]+)/leave/$',
        views.train_leave, name='train_leave'),
    url(r'^admin/', admin.admin_site.urls),
    url(r'^api-auth/', include('rest_framework.urls')),
]
