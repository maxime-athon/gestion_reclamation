import os
import django
from django.core.mail import send_mail

# Configuration de l'environnement Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ton_nom_de_projet.settings')
django.setup()

def tester_envoi():
    try:
        print("Tentative d'envoi d'email...")
        send_mail(
            'Test Railway + Resend',
            'Si tu reçois ce message, ta configuration Anymail est parfaite !',
            'athonbm6@gmail.com',  # L'expéditeur autorisé par défaut
            ['athonmaxime.gmail.com'],   # REMPLACE PAR TON PROPRE EMAIL
            fail_silently=False,
        )
        print("✅ Succès ! L'email a été envoyé.")
    except Exception as e:
        print(f"❌ Erreur lors de l'envoi : {e}")

if __name__ == "__main__":
    tester_envoi()
