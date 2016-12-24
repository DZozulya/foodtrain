from __future__ import absolute_import
from __future__ import unicode_literals

from rest_framework import serializers

from .models import Participant
from .models import Train


class ParticipantSeralizer(serializers.ModelSerializer):
    name = serializers.CharField(min_length=1, max_length=50)

    class Meta:
        model = Participant
        fields = ('id', 'name',)

    def get_or_create(self):
        """
        Get or create a `Participant` instance, given the validated data.
        """
        return Participant.objects.get_or_create(
            name=self.validated_data['name'],
        )

    def get(self):
        """
        Get a `Participant` instance, given the validated data.
        """
        return Participant.objects.get(
            name=self.validated_data['name'],
        )


class TrainSerializer(serializers.ModelSerializer):
    participants = serializers.StringRelatedField(
        many=True,
        read_only=True,
    )
    creator = serializers.StringRelatedField()
    start_time = serializers.DateTimeField(format="%Y-%m-%dT%H:%M:%S")

    class Meta:
        model = Train
        fields = ('id', 'restaurant_name', 'creator',
                  'start_time', 'yelp_id', 'participants',)

    def create(self, validated_data):
        """
        Create and return a new `Train` instance, given the validated data.
        """
        creator = self.context['creator']
        validated_data['creator'] = creator
        train = Train.objects.create(**validated_data)
        train.participants.add(creator)
        return train
