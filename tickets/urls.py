from rest_framework.routers import DefaultRouter
from .views import TicketViewSet, CommentaireViewSet

router = DefaultRouter()
router.register(r'tickets', TicketViewSet, basename='ticket')
router.register(r'commentaires', CommentaireViewSet, basename='commentaire')

urlpatterns = router.urls