"""Une petite image RGB (octets) : lire, échantillonner, réduire, écrire en PNG. Stdlib seule."""
from __future__ import annotations

import math


class Image:
    def __init__(self, W: int, H: int, px: bytearray | None = None, fond=(255, 255, 255)):
        self.W, self.H = W, H
        self.px = px if px is not None else bytearray(bytes(fond) * (W * H))

    def get(self, x: int, y: int) -> tuple[int, int, int]:
        i = (y * self.W + x) * 3
        return self.px[i], self.px[i + 1], self.px[i + 2]

    def put(self, x: int, y: int, c) -> None:
        i = (y * self.W + x) * 3
        self.px[i:i + 3] = bytes(c)

    def luma(self) -> list[float]:
        p = self.px
        return [0.299 * p[i] + 0.587 * p[i + 1] + 0.114 * p[i + 2] for i in range(0, len(p), 3)]

    def bilineaire(self, x: float, y: float, fond=(255, 255, 255)) -> tuple[int, int, int]:
        """Couleur au point (x, y) en pixels (centre du pixel k en k + 0,5) ; `fond` hors de l'image."""
        x -= 0.5
        y -= 0.5
        x0, y0 = math.floor(x), math.floor(y)
        if x0 < -1 or y0 < -1 or x0 >= self.W or y0 >= self.H:
            return fond
        fx, fy = x - x0, y - y0
        out = [0.0, 0.0, 0.0]
        for dy, wy in ((0, 1 - fy), (1, fy)):
            for dx, wx in ((0, 1 - fx), (1, fx)):
                w = wx * wy
                if w == 0:
                    continue
                xx, yy = min(max(x0 + dx, 0), self.W - 1), min(max(y0 + dy, 0), self.H - 1)
                i = (yy * self.W + xx) * 3
                out[0] += w * self.px[i]
                out[1] += w * self.px[i + 1]
                out[2] += w * self.px[i + 2]
        return (round(out[0]), round(out[1]), round(out[2]))

    def tourner(self, k: int) -> "Image":
        """L'image tournée de k quarts de tour dans le sens des aiguilles d'une montre."""
        k %= 4
        if k == 0:
            return self
        W, H = (self.H, self.W) if k % 2 else (self.W, self.H)
        out = Image(W, H)
        for y in range(H):
            for x in range(W):
                if k == 1:
                    sx, sy = y, self.H - 1 - x
                elif k == 2:
                    sx, sy = self.W - 1 - x, self.H - 1 - y
                else:
                    sx, sy = self.W - 1 - y, x
                i = (sy * self.W + sx) * 3
                o = (y * W + x) * 3
                out.px[o:o + 3] = self.px[i:i + 3]
        return out

    def reduire(self, f: int) -> "Image":
        """Moyenne de blocs f × f."""
        if f <= 1:
            return self
        W, H = self.W // f, self.H // f
        out = bytearray(W * H * 3)
        n = f * f
        for y in range(H):
            for x in range(W):
                s = [0, 0, 0]
                for j in range(f):
                    base = ((y * f + j) * self.W + x * f) * 3
                    for k in range(f):
                        i = base + 3 * k
                        s[0] += self.px[i]
                        s[1] += self.px[i + 1]
                        s[2] += self.px[i + 2]
                o = (y * W + x) * 3
                out[o], out[o + 1], out[o + 2] = s[0] // n, s[1] // n, s[2] // n
        return Image(W, H, out)

    def png(self, chemin) -> None:
        from coloriages.apercu import ecrire_png
        ecrire_png(chemin, self.W, self.H, self.px)
