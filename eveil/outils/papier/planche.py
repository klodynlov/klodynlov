"""Planche du mode papier : pour quelques pages, la photo simulée, le dessin redressé, et les coups de
crayon retrouvés sous les traits de l'app. `python3 -m papier.planche DOSSIER [pages…]`."""
from __future__ import annotations

import sys
import time
from pathlib import Path

from coloriages import analyse, apercu, catalogue, zones
from coloriages.dessin import PALETTE_RGB

from . import mise_en_page as mp, recaler, reperes, simuler
from .homographie import homographie
from .image import Image

TEINTES = ["rouge", "bleu", "jaune", "vert", "orange", "violet", "rose", "marron", "turquoise", "noir"]


def scenario(page_id: str, res: float = 1.0, n: int = 256, noir_au_coin: bool = False):
    """(photo, repères trouvés, vrais repères sur la photo, redressé, peinture, zones n×n, couleurs)."""
    a = analyse.analyser(next(p for p in catalogue.PAGES if p.id == page_id), variantes=False)
    c = zones.carte(a.traits, taille=round(mp.COTE * res))
    grandes = sorted((z for z in range(1, c.zones + 1) if c.part(z) > 0.004), key=lambda z: -c.aires[z])
    couleurs = {z: PALETTE_RGB[TEINTES[k % len(TEINTES)]] for k, z in enumerate(grandes[::2][:8])}
    if noir_au_coin:
        # L'enfant a colorié en noir la zone la plus proche du coin haut-gauche du dessin.
        z = min((z for z in range(1, c.zones + 1) if c.part(z) > 0.003),
                key=lambda z: zones.centre(c, z)[0] + zones.centre(c, z)[1])
        couleurs[z] = PALETTE_RGB["noir"]
    page, _, cote = simuler.page_imprimee(a, res, couleurs)
    W, H = page.W, page.H
    coins = [(0, 0), (W, 0), (W, H), (0, H)]
    photo_coins = [(0.03 * W, 0.02 * H), (0.985 * W, 0.045 * H), (0.96 * W, 0.99 * H), (0.01 * W, 0.965 * H)]
    Hp = homographie(coins, photo_coins)
    photo = simuler.photographier(page, Hp, W, H)
    from .homographie import appliquer
    vrais = [appliquer(Hp, (x * res, y * res)) for x, y in mp.reperes_page()]
    trouves = reperes.trouver(photo)
    rect = recaler.redresser(photo, trouves or reperes.sans_reperes(photo), n)
    cn = zones.carte(a.traits, taille=n)
    paint = recaler.peinture(rect, cn.labels)
    return a, photo, trouves, vrais, rect, paint, cn, couleurs, c


def main(argv=None) -> int:
    argv = argv if argv is not None else sys.argv[1:]
    dossier = Path(argv[0]) if argv else Path("/tmp/papier")
    ids = argv[1:] or ["locomotive", "minouche", "voiture"]
    dossier.mkdir(parents=True, exist_ok=True)
    for pid in ids:
        t0 = time.time()
        a, photo, trouves, vrais, rect, paint, cn, _, _ = scenario(pid)
        n = rect.W
        # Les coups de crayon sous les traits de l'app.
        traits = apercu._masque(a.traits, n, a.page.trait * n)
        rendu = Image(n, n)
        for i in range(n * n):
            if traits[i]:
                rendu.px[3 * i:3 * i + 3] = bytes(apercu.ENCRE_RGB)
            elif paint[i]:
                rendu.px[3 * i:3 * i + 3] = bytes(paint[i])
        petite = photo.reduire(max(1, round(photo.H / n)))
        H = n
        W = petite.W + 2 * n + 20
        out = Image(W, H, fond=(238, 238, 238))
        for y in range(min(H, petite.H)):
            for x in range(petite.W):
                out.put(x, y, petite.get(x, y))
        for y in range(n):
            for x in range(n):
                out.put(petite.W + 10 + x, y, rect.get(x, y))
                out.put(petite.W + n + 20 + x, y, rendu.get(x, y))
        out.png(dossier / f"papier-{pid}.png")
        erreur = max(((tx - vx) ** 2 + (ty - vy) ** 2) ** 0.5 for (tx, ty), (vx, vy) in zip(trouves, vrais)) \
            if trouves else None
        print(f"{pid}: repères {'trouvés' if trouves else 'ABSENTS'}, erreur max {erreur and round(erreur, 2)} px ; "
              f"accord {recaler.accord(rect, cn.labels):.2f} ; {time.time() - t0:.1f} s")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
