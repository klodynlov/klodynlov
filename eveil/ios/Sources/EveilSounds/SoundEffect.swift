// SoundEffect.swift — les bruitages de la suite, CALCULÉS sur l'appareil.
//
// Aucun fichier son : chaque effet est synthétisé (`SoundSynth`) — pas de licence
// à gérer, rien à télécharger, et rien n'est jamais enregistré. Ce sont des
// bruitages de dessin animé, PROVISOIRES : de vrais sons (enregistrés ou libres
// de droits) pourront les remplacer un par un sans toucher au jeu.
//
// Règle d'or du Petit Train : un bruitage ne joue JAMAIS pendant l'écoute
// (tour de parole strict) — `SoundBoard.isSuspended` le garantit.

public enum SoundEffect: String, CaseIterable, Sendable {
    // Le train
    case whistle        // « tchou-tchou » : le train part vers un autre monde
    case steam          // « chhh » : le fourgon « ch » s'accroche (symbole sonore)
    case hiss           // « sss » : le fourgon « s » s'accroche (le serpent)
    case chime          // petit carillon joyeux (arrivée dans un monde)

    // Les bestioles qu'on attrape (chacune a SON bruit)
    case buzz           // mouche : bzzz grave, qui tourne
    case beeBuzz        // abeille : bzzz plus aigu et plus rond
    case tweet          // oiseau : cui-cui
    case flutter        // papillon : froufrou d'ailes léger
    case pop            // bulle qui éclate
    case drip           // goutte d'eau : « plic »
    case ding           // note de musique (la hauteur suit `variant`)
    case crackle        // étincelle, feu qui crépite
    case rustle         // feuille morte froissée
    case sparkle        // étoile magique : scintillement
    case whooshSoft     // plume qui passe
    case splat          // goutte de peinture : « splotch »
    case kiss           // cœur : bisou « smack »
    case twinkle        // flocon : clochette cristalline

    // Les objets des mots — français
    case shower         // douche : eau qui coule
    case woof           // niche : « ouaf ouaf »
    case moo            // vache : « meuh »
    case hooves         // biche : petits bonds sur les feuilles
    case clink          // tasse : porcelaine « tink »
    case meow           // minouche : « miaou »
    case sizzle         // saucisse : grésillement dans la poêle
    case zipper         // trousse : fermeture éclair
    case bubbles        // mousse : bulles qui éclatent en cascade
    case plop           // pêche : le fruit tombe « ploc »
    case crunch         // os : croc-croc
    case siren          // police : « pin-pon »
    case yap            // caniche : petit « waf » aigu
    case slime          // limace : glissade gluante
    case clipClop       // carrosse : sabots du cheval
    case maracas        // cactus : maracas
    case bell           // cloche : « ding-dong »
    case lick           // glace : coup de langue « slurp »
    case arrow          // flèche : « fffuit… toc ! »
    case brushing       // brosse : frotte-frotte
    case footsteps      // autruche : grandes enjambées « boum boum »

    // Les objets des mots — anglais
    case blub           // fish : bulles « blub »
    case scrape         // push : caisse qu'on pousse
    case water          // wash : eau qui clapote
    case honk           // goose : « honk »
    case bellow         // moose : long appel grave
    case iceClink       // ice : glaçons qui s'entrechoquent
    case click          // piece : pièce de puzzle qui s'emboîte
    case horn           // bus : « tut-tut »
    case pok            // tennis : balle « pok »
    case squeak         // mouse : « couic »
    case slurp          // juice : aspiration à la paille
    case doorbell       // house : sonnette « ding-dong »
    case fanfare        // circus : petite fanfare
    case splash         // splash : « plouf »
}
