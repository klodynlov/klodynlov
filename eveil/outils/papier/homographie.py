"""Homographie à partir de 4 points (transformation perspective du plan) : la page vers la photo.

x' = (a x + b y + c) / (g x + h y + 1),  y' = (d x + e y + f) / (g x + h y + 1) ;
les 8 inconnues viennent de 4 correspondances (système 8 × 8, pivot de Gauss partiel).
"""
from __future__ import annotations


def resoudre(A: list[list[float]], b: list[float]) -> list[float]:
    n = len(b)
    M = [row[:] + [b[i]] for i, row in enumerate(A)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c]))
        if abs(M[p][c]) < 1e-12:
            raise ValueError("points alignés : pas d'homographie")
        M[c], M[p] = M[p], M[c]
        for r in range(n):
            if r != c:
                f = M[r][c] / M[c][c]
                for k in range(c, n + 1):
                    M[r][k] -= f * M[c][k]
    return [M[i][n] / M[i][i] for i in range(n)]


def homographie(src, dst) -> list[list[float]]:
    """La matrice 3 × 3 (h33 = 1) qui envoie chaque point de `src` sur celui de `dst`."""
    A, b = [], []
    for (x, y), (u, v) in zip(src, dst):
        A.append([x, y, 1, 0, 0, 0, -x * u, -y * u])
        b.append(u)
        A.append([0, 0, 0, x, y, 1, -x * v, -y * v])
        b.append(v)
    a, bb, c, d, e, f, g, h = resoudre(A, b)
    return [[a, bb, c], [d, e, f], [g, h, 1.0]]


def appliquer(H, p) -> tuple[float, float]:
    x, y = p
    w = H[2][0] * x + H[2][1] * y + H[2][2]
    return ((H[0][0] * x + H[0][1] * y + H[0][2]) / w, (H[1][0] * x + H[1][1] * y + H[1][2]) / w)


def inverse(H) -> list[list[float]]:
    (a, b, c), (d, e, f), (g, h, i) = H
    co = [[e * i - f * h, c * h - b * i, b * f - c * e],
          [f * g - d * i, a * i - c * g, c * d - a * f],
          [d * h - e * g, b * g - a * h, a * e - b * d]]
    det = a * co[0][0] + b * co[1][0] + c * co[2][0]
    if abs(det) < 1e-15:
        raise ValueError("homographie non inversible")
    m = [[v / det for v in row] for row in co]
    s = m[2][2]
    return [[v / s for v in row] for row in m]
