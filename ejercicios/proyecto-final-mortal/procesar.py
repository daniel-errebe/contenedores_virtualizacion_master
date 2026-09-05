import csv

with open("/datos/cafeteras.csv") as f:
    lector = csv.DictReader(f)
    filas = list(lector)

total = len(filas)
rotas = sum(1 for fila in filas if fila["taza_rota"] == "true")

print(f"Cafés servidos: {total}")
print(f"Tazas rotas: {rotas}  (una tragedia cada {total // max(rotas, 1)} cafés)")
