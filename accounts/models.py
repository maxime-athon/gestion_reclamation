from django.contrib.auth.models import AbstractUser
from django.db import models


class CustomUser(AbstractUser):
    class Role(models.TextChoices):
        CITOYEN = 'CITOYEN', 'Citoyen / Agent'
        TECHNICIEN = 'TECHNICIEN', 'Technicien Support'
        ADMIN = 'ADMIN', 'Administrateur'

    email = models.EmailField(unique=True)
    role = models.CharField(max_length=15, choices=Role.choices, default=Role.CITOYEN)
    telephone = models.CharField(max_length=20, blank=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    @property
    def full_name(self):
        full_name = f'{self.first_name} {self.last_name}'.strip()
        return full_name or self.username or self.email

    def save(self, *args, **kwargs):
        if self.email:
            self.email = self.email.strip().lower()
        if not self.username and self.email:
            self.username = self.email.split('@', 1)[0]
        super().save(*args, **kwargs)

    def __str__(self):
        return f'{self.full_name} ({self.role})'
