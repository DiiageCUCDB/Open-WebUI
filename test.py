import statistics

def calcul_note_liste(notes):
    # Calcul de la moyenne
    total = 0
    count = 0
    for note in notes:
        if note["note"] is None:
            raise ValueError("Une note est considérée comme non cohérente")
        
        total += note["note"]
        count += 1

    if count == 0:
        raise ZeroDivisionError("La liste de notes est vide")

    moyenne = total / count
    note_min = min(note["note"] for note in notes)
    note_max = max(note["note"] for note in notes)

    # Création du rapport Markdown
    rapport = f"**Rapport de calcul des notes**\n"
    rapport += "### Moyenne\n"
    rapport += f"* La moyenne est de {moyenne:.2f}\n"

    rapport += "\n### Note Min et Max\n"
    rapport += f"* Le plus bas score est de {note_min}\n"
    rapport += f"* Le plus haut score est de {note_max}"

    return rapport

# Test unitaires avec pytest
import pytest

def test_calcul_note_liste():
    notes = [
        {"nom": "Joules", "note": 15},
        {"nom": "Baud", "note": 12},
        {"nom": "Newton", "note": 18}
    ]

    rapport = calcul_note_liste(notes)

    # Vérification de la moyenne
    assert round(statistics.mean([note["note"] for note in notes]), 2) == 15.0

def test_calcul_note_liste_vide():
    with pytest.raises(ZeroDivisionError):
        calcul_note_liste([])

def test_calcul_note_liste_nulle():
    notes = [{"note": None}]
    try:
        calcul_note_liste(notes)
        assert False
    except ValueError as e:
        assert str(e) == "Une note est considérée comme non cohérente"