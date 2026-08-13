#!/usr/bin/env python3
"""Verifica la propiedad: cada par de cartas comparte exactamente un símbolo."""


def generar_mazo(q: int = 5) -> list[list[int]]:
    cartas: list[list[int]] = []
    for pendiente in range(q):
        for intercepto in range(q):
            carta = [x * q + ((pendiente * x + intercepto) % q) for x in range(q)]
            carta.append(q * q + pendiente)
            cartas.append(carta)
    for x in range(q):
        cartas.append([x * q + y for y in range(q)] + [q * q + q])
    cartas.append(list(range(q * q, q * q + q + 1)))
    return cartas


mazo = generar_mazo()
assert len(mazo) == 31
assert all(len(carta) == 6 for carta in mazo)
for i, primera in enumerate(mazo):
    for segunda in mazo[i + 1 :]:
        comunes = set(primera) & set(segunda)
        assert len(comunes) == 1, (primera, segunda, comunes)
print("OK: 31 cartas, 6 símbolos y exactamente 1 coincidencia por par.")

