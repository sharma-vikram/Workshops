# Oracle Frontend - Real-time Price Dashboard

Interface React/Next.js pour visualiser les prix de l'Oracle en temps réel.

## Fonctionnalités ✨

- 📊 **Prix en temps réel** - Affiche les prix actuels de 7 cryptomonnaies
- 🔔 **Événements live** - Écoute les événements \`PriceUpdated\` du smart contract
- 🪙 **Sélecteur de coins** - Bitcoin, Ethereum, Solana, Kaspa, Dogecoin, Sui, Aptos
- 📜 **Historique** - Affiche les 10 dernières mises à jour de prix
- 🎯 **Info Round** - Affiche le round ID et le quorum dynamique
- 💰 **Format USD** - Prix formatés en dollars avec 2 décimales

## Configuration

Fichier \`.env.local\`:

\`\`\`bash
NEXT_PUBLIC_ORACLE_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
\`\`\`

## Utilisation rapide

\`\`\`bash
# Installation
npm install

# Développement
npm run dev

# Production
npm run build && npm run start
\`\`\`

Ouvrir [http://localhost:3000](http://localhost:3000)

## Fonctionnement

### Événements en temps réel

Le frontend écoute les événements \`PriceUpdated\`:

\`\`\`typescript
contract.on("PriceUpdated", (coin, price, roundId, event) => {
  console.log(\`🔔 \${coin}: $\${price / 1e8} (Round \${roundId})\`);
  // Met à jour l'historique
});
\`\`\`

### Prix formatés

- Prix stocké: \`5000025000000\` (50000.25 × 10^8)
- Prix affiché: \`$50,000.25\`

## Exemple de flux complet

1. **10 nœuds** soumettent des prix toutes les 20 secondes
2. Quand **7 nœuds** (quorum) ont soumis → événement \`PriceUpdated\` émis
3. Le **frontend** reçoit l'événement via WebSocket
4. L'**interface se met à jour** instantanément
5. L'**historique s'enrichit** automatiquement
