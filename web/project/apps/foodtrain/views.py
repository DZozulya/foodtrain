from __future__ import absolute_import
from __future__ import unicode_literals

import datetime

from django.db.models import Count
from rest_framework import generics
from rest_framework import permissions
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.decorators import permission_classes
from rest_framework.response import Response
from rest_framework.reverse import reverse

from .models import Participant
from .models import Train
from .serializers import ParticipantSeralizer
from .serializers import TrainSerializer


class APIRoot(generics.GenericAPIView):
    """
    FoodTrain API documentation
    """
    permission_classes = (permissions.AllowAny,)

    def get(self, request):
        example_train = Train.objects.order_by('id').first()
        example_pk = example_train.pk if example_train else 0

        return Response({
            'train_list': reverse('train_list', request=request),
            'train_detail': reverse(
                'train_detail',
                kwargs={'pk': example_pk},
                request=request,
            ),
            'train_join': reverse(
                'train_join',
                kwargs={'pk': example_pk},
                request=request,
            ),
            'train_leave': reverse(
                'train_leave',
                kwargs={'pk': example_pk},
                request=request,
            ),
        })


@api_view(['GET', 'POST'])
@permission_classes((permissions.AllowAny,))
def train_list(request):
    """
    List all active trains ordered by `start_time` with GET. Or create new train with POST.
    """
    if request.method == 'GET':
        today = datetime.date.today()
        start_of_today = datetime.datetime.combine(today, datetime.time.min)
        trains = Train.objects.annotate(
            num_participants=Count('participants'),
        ).filter(
            start_time__gt=start_of_today,
            num_participants__gt=0,
        )
        train_serializer = TrainSerializer(trains, many=True)
        return Response(train_serializer.data)

    elif request.method == 'POST':
        data = request.data

        participant_seralizer = ParticipantSeralizer(data={
            'name': request.data['creator'],
        })
        if participant_seralizer.is_valid():
            creator_instance, _ = participant_seralizer.get_or_create()
        else:
            print("participant_seralizer error, {}".format(
                participant_seralizer.errors))
            return Response(participant_seralizer.errors, status=status.HTTP_400_BAD_REQUEST)

        train_serializer = TrainSerializer(data=data, context={
            'creator': creator_instance,
        })
        if train_serializer.is_valid():
            train_serializer.save()
            return Response(train_serializer.data)
        print("train_seralizer error, {}".format(train_serializer.errors))
        return Response(train_serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes((permissions.AllowAny,))
def train_detail(request, pk):
    """
    Get one train, for given `id`.
    """
    try:
        train = Train.objects.get(pk=pk)
    except Train.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)

    serializer = TrainSerializer(train)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes((permissions.AllowAny,))
def train_join(request, pk):
    """
    Join train for given `id` by submitting a dict containg the `name`.
    """
    try:
        train = Train.objects.get(pk=pk)
    except Train.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)

    if request.method == 'POST':
        participant_data = request.data
        participant_data.update({
            'train': train.pk,
        })
        participant_serializer = ParticipantSeralizer(data=participant_data)

        if participant_serializer.is_valid():
            participant_instance, _ = participant_serializer.get_or_create()

            if train.participants.filter(id=participant_instance.id).exists():
                return Response(status=status.HTTP_400_BAD_REQUEST)
            else:
                train.participants.add(participant_instance)
                serializer = TrainSerializer(train)
                return Response(serializer.data)

        return Response(participant_serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes((permissions.AllowAny,))
def train_leave(request, pk):
    """
    Leave train for given `id` by submitting a dict containg the `name`.
    """
    try:
        train = Train.objects.get(pk=pk)
    except Train.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)

    if request.method == 'POST':
        participant_data = request.data
        participant_data.update({
            'train': train.pk,
        })
        participant_serializer = ParticipantSeralizer(data=participant_data)
        if participant_serializer.is_valid():

            try:
                participant_instance = participant_serializer.get()
            except Participant.DoesNotExist:
                return Response(status=status.HTTP_404_NOT_FOUND)

            if not train.participants.filter(id=participant_instance.id).exists():
                return Response(status=status.HTTP_400_BAD_REQUEST)
            else:
                train.participants.remove(participant_instance)
                serializer = TrainSerializer(train)
                return Response(serializer.data)
        return Response(participant_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
