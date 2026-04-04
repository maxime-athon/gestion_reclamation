from django.apps import AppConfig

# cet fichier définit la configuration de l'application "tickets". La classe TicketsConfig hérite de AppConfig et spécifie le nom de l'application. 
# La méthode ready() est utilisée pour importer les signaux définis dans tickets.
# signals, ce qui permet de connecter les signaux aux modèles ou autres composants de l'application lorsque celle-ci est prête.    

class TicketsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'tickets'

    def ready(self):
        import tickets.signals  # noqa: F401
