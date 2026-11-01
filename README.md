# Compta TSNT

Application web installable (PWA) pour la comptabilité partagée de Tous Solidaires Néo-Tuileries.

## Architecture
- GitHub Pages héberge l'application.
- Supabase Auth gère les connexions des bénévoles.
- Supabase Database synchronise les opérations entre Android, iPhone et ordinateur.
- Les ventes et annulations de buvette sont traitées par des fonctions SQL transactionnelles (mise à jour du stock + écriture comptable).

## 1. Configurer Supabase
1. Crée un projet sur https://supabase.com/ (offre gratuite pour commencer).
2. Dans **SQL Editor**, ouvre une nouvelle requête, colle tout le contenu de \`supabase.sql\`, puis clique **Run**.
3. Dans **Project Settings > API**, copie **Project URL** et la clé **anon / publishable**.
4. Dans le fichier \`config.js\` de ce dépôt, remplace \`VOTRE-PROJET\` et \`VOTRE_CLE_ANON_PUBLIQUE\`.
   - La clé anon/publishable est destinée au navigateur et peut être publiée avec les politiques RLS.
   - Ne mets JAMAIS la clé \`service_role\` dans le dépôt.
5. Dans **Authentication > Providers > Email**, garde l'authentification e-mail activée.
6. Dans **Authentication > Settings**, désactive les inscriptions publiques si l'option est disponible.
7. Dans **Authentication > Users**, crée un compte par bénévole autorisé (Add user). Communique à chacun son accès de façon privée.

Les politiques SQL autorisent les utilisateurs authentifiés à lire et modifier les données TSNT. N'ajoute donc que des bénévoles de confiance.

## 2. Activer GitHub Pages
1. Dans GitHub, ouvre **Settings > Pages**.
2. Dans **Build and deployment**, choisis **Deploy from a branch**.
3. Sélectionne la branche \`main\` et le dossier \`/ (root)\`, puis **Save**.
4. Attends la publication. L'adresse sera \`https://koa42.github.io/Compta-TSNT/\`.

## 3. Installer sur les téléphones
- Android : ouvre l'adresse dans Chrome, menu ⋮, **Installer l'application** ou **Ajouter à l'écran d'accueil**.
- iPhone : ouvre l'adresse dans Safari, bouton Partager, **Sur l'écran d'accueil**.
- Ordinateur : ouvre simplement le lien dans un navigateur.

Connecte chaque appareil avec le compte personnel du bénévole. Les changements sont synchronisés en temps réel lorsque l'appareil est connecté à Internet.

## Fonctions incluses
- Tableau de bord : soldes banque/caisse, total disponible, stock et commandes.
- Journal comptable : recettes et dépenses.
- Stock : quantité, unité, conditionnement d'achat, prix d'achat par unité de stock, conditionnement de vente et prix.
- Buvette : panier rapide, encaissement espèces/carte, décrémentation du stock.
- Historique buvette : annulation d'une commande, recrédit du stock et écriture inverse.
- Justificatifs : référence, date et montant (le fichier lui-même reste à conserver dans le Drive de l'association).
- Cartes de fidélité et activités.
- Export et import JSON pour sauvegarder/restaurer les enregistrements.

## Important
- Une connexion Internet est nécessaire pour écrire et synchroniser. La PWA met en cache l'interface, mais ne valide aucune vente hors ligne.
- Les justificatifs sont actuellement référencés par leur nom, pas stockés comme pièces jointes.
- Les soldes sont calculés à partir des opérations saisies. Renseigne le solde initial comme une recette d'ouverture sur le compte correspondant.
- Avant utilisation réelle, fais des essais avec quelques produits et opérations fictifs et vérifie les soldes.
