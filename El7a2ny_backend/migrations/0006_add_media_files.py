# Generated migration for adding media_files field to Incident model

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('El7a2ny_backend', '0005_alter_user_options'),
    ]

    operations = [
        migrations.AddField(
            model_name='incident',
            name='media_files',
            field=models.JSONField(blank=True, default=list, null=True),
        ),
        # Keep the old media field for backward compatibility
        # migrations.RemoveField(
        #     model_name='incident',
        #     name='media',
        # ),
    ]
