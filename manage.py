#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys


def main():
    """Run administrative tasks."""
    # Force l'encodage UTF-8 pour éviter le crash sur les accents Windows
    os.environ['PYTHONUTF8'] = '1'
    os.environ['PGCLIENTENCODING'] = 'UTF8'
    os.environ['LC_ALL'] = 'C'  # Force les messages d'erreur en anglais

    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    main()
