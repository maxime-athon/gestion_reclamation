from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('tickets', '0002_ticket_est_archive'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Notification',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('titre', models.CharField(max_length=100)),
                ('message', models.TextField()),
                ('est_lue', models.BooleanField(default=False)),
                ('date_creation', models.DateTimeField(auto_now_add=True)),
                ('destinataire', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='notifications', to=settings.AUTH_USER_MODEL)),
                ('ticket', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='tickets.ticket')),
            ],
            options={'ordering': ['-date_creation']},
        ),
    ]
