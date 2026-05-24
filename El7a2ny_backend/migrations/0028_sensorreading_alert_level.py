# Generated migration for adding alert_level to SensorReading

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        (
            "El7a2ny_backend",
            "0027_alter_chatmessage_table_alter_incidentchat_table_and_more",
        ),
    ]

    operations = [
        migrations.AddField(
            model_name="sensorreading",
            name="alert_level",
            field=models.CharField(
                choices=[
                    ("NORMAL", "🟢 NORMAL"),
                    ("WARNING", "⚠️ WARNING"),
                    ("ALERT", "🚨 ALERT"),
                    ("CRITICAL", "🔥 CRITICAL"),
                ],
                default="NORMAL",
                help_text="Temperature alert level: NORMAL (<40°C), WARNING (40-70°C), ALERT (70-120°C), CRITICAL (≥120°C)",
                max_length=20,
            ),
        ),
    ]
