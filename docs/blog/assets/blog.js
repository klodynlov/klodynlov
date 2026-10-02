/* Le Carnet — comportements partagés (bascule de thème + liste d'articles).
   Aucune dépendance, aucun réseau : marche aussi en ouvrant les fichiers
   directement (file://) comme en ligne sur GitHub Pages. */

/* ---- bascule clair / sombre -------------------------------------------- */
(function themeToggle(){
  var root = document.documentElement;
  var btn  = document.getElementById('toggle');
  if(!btn) return;
  var prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  btn.addEventListener('click', function(){
    var current = root.getAttribute('data-theme') || (prefersDark ? 'dark' : 'light');
    var next = current === 'dark' ? 'light' : 'dark';
    root.setAttribute('data-theme', next);
    btn.setAttribute('aria-label', next === 'dark' ? 'Passer en thème clair' : 'Passer en thème sombre');
  });
})();

/* ---- liste des articles (page d'accueil) -------------------------------
   POUR PUBLIER UN NOUVEL ARTICLE :
   1. Copie posts/2026-07-13-agents-ia-100-local.html sous un nouveau nom.
   2. Écris ton contenu dedans.
   3. Ajoute UNE entrée en tête du tableau POSTS ci-dessous (les plus récents
      en premier). C'est tout — la carte apparaît automatiquement.
   ------------------------------------------------------------------------ */
var POSTS = [
  {
    url: 'posts/2026-07-13-agents-ia-100-local.html',
    titre: 'Pourquoi je fais tourner mes agents IA à 100 % en local',
    categorie: 'IA locale',
    date: '2026-07-13',
    dateLisible: '13 juillet 2026',
    lecture: '6 min',
    resume: "La vie privée n'est pas une posture, c'est devenu le choix le plus rationnel sur mon poste de travail. Ce que le local change vraiment — et ses vrais compromis."
  },
  {
    url: 'posts/2026-07-06-mcp-donner-des-mains.html',
    titre: 'MCP, expliqué simplement : donner des mains à un modèle de langage',
    categorie: 'MCP',
    date: '2026-07-06',
    dateLisible: '6 juillet 2026',
    lecture: '6 min',
    resume: "Un modèle ne sait que générer du texte. Le Model Context Protocol est la prise standard qui le branche sur le monde réel — client, serveur, et pourquoi ça change tout."
  },
  {
    url: 'posts/2026-06-28-agent-aller-au-bout.html',
    titre: "Faire en sorte qu'un agent de code aille vraiment au bout",
    categorie: 'Agents',
    date: '2026-06-28',
    dateLisible: '28 juin 2026',
    lecture: '7 min',
    resume: "Routage adaptatif, boucle ReAct, Best-of-N, vérification : les briques qui transforment un modèle local médiocre-en-un-coup en un système têtu qui converge."
  }
];

(function renderPosts(){
  var mount = document.getElementById('posts');
  if(!mount) return;
  if(!POSTS.length){
    mount.innerHTML = '<li class="empty">Le premier article arrive bientôt. 🌱</li>';
    return;
  }
  function esc(s){ return String(s).replace(/[&<>"]/g, function(c){
    return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]; }); }
  mount.innerHTML = POSTS.map(function(p){
    return '<li class="post"><a href="'+esc(p.url)+'">'
      + '<div class="meta">'
      +   '<span class="chip">'+esc(p.categorie)+'</span>'
      +   '<time datetime="'+esc(p.date)+'">'+esc(p.dateLisible)+'</time>'
      +   '<span aria-hidden="true">·</span><span>'+esc(p.lecture)+' de lecture</span>'
      + '</div>'
      + '<h2>'+esc(p.titre)+'</h2>'
      + '<p>'+esc(p.resume)+'</p>'
      + '<span class="more">Lire l\'article <span aria-hidden="true">→</span></span>'
      + '</a></li>';
  }).join('');
})();
