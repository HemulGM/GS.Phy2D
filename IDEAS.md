# GSPhy2D - Ideas & Roadmap

## Effets fluides observés

Avec beaucoup de particules qui interagissent, on observe des comportements émergents similaires à la dynamique des fluides :

- **Convection** : les particules "chaudes" (rouges) montent et les "froides" (bleues) descendent
- **Transfert d'énergie** : quand une particule rapide frappe une lente, on voit le "flash" de couleur se propager
- **Équilibre thermique** : avec le temps, tout le système tend vers le bleu (refroidissement)

## Évolutions possibles vers la simulation de fluides

- **SPH (Smoothed Particle Hydrodynamics)** pour simuler de vrais fluides
- **Pression inter-particules** pour éviter la compression excessive
- **Viscosité** pour un comportement plus "liquide"

---

## Optimisations Performance

### État actuel
- ~10000 particules à 20 FPS
- Spatial hash avec pointeurs directs
- Intégration Verlet

### Prochaines étapes d'optimisation

#### 1. SIMD (SSE/AVX) - Gain estimé: 2-4x
Vectoriser les calculs sur 4 ou 8 particules simultanément :
```pascal
// Au lieu de traiter 1 particule à la fois
// Traiter 4 positions X en parallèle avec SSE
// Traiter 8 positions X en parallèle avec AVX
```
- Regrouper les données par composante (SoA au lieu de AoS)
- Utiliser les intrinsics SSE/AVX de Delphi

#### 2. Structure SoA (Structure of Arrays) - Gain estimé: 1.5-2x
Actuellement (AoS - Array of Structures):
```pascal
TPhyParticle = record
  Pos: TVec2;      // X, Y ensemble
  OldPos: TVec2;
  Radius: Single;
end;
FParticles: array of TPhyParticle;
```

Optimisé (SoA - Structure of Arrays):
```pascal
FPosX: array of Single;      // Tous les X ensemble (cache-friendly)
FPosY: array of Single;      // Tous les Y ensemble
FOldPosX: array of Single;
FOldPosY: array of Single;
FRadius: array of Single;
```
Meilleure utilisation du cache CPU car accès séquentiels.

#### 3. Multithreading - Gain estimé: 2-8x (selon nb de coeurs)
- **Phase 1 - Intégration** : parallélisable à 100% (chaque particule indépendante)
- **Phase 2 - Spatial Hash rebuild** : parallélisable avec locks par cellule
- **Phase 3 - Collision detection** : diviser l'espace en zones traitées en parallèle
- **Phase 4 - Collision response** : plus délicat, nécessite synchronisation

Utiliser `TParallel.For` de Delphi ou threads manuels.

#### 4. Éviter les allocations dynamiques
- Pré-allouer `FQueryResult` à une taille fixe max
- Éviter `SetLength` pendant la simulation
- Pool d'objets si nécessaire

#### 5. Optimisation du Spatial Hash
- **Taille de cellule optimale** : 2x le rayon max (déjà fait)
- **Grille plate** au lieu de 2D : `FCells: array of TCell` avec index = Y * Width + X
- **Skip des cellules vides** : maintenir une liste des cellules non-vides

#### 6. Broad Phase améliorée
- **Sort and Sweep** sur l'axe X pour réduire les paires à tester
- **Hierarchical Grid** : grille grossière + grille fine

#### 7. Réduction des calculs
- **Éviter Sqrt** quand possible (comparer distances au carré)
- **Fast inverse sqrt** pour la normalisation
- **Lookup tables** pour certaines fonctions

#### 8. Compilation optimisée
- Activer les optimisations Delphi : `{$O+}` `{$R-}` `{$Q-}`
- Compiler en 64-bit pour plus de registres
- Utiliser `inline` sur les fonctions critiques (déjà fait sur certaines)

### Ordre de priorité recommandé

1. **SoA + SIMD** - Plus gros gain potentiel
2. **Multithreading Intégration** - Facile à implémenter, bon gain
3. **Éviter allocations** - Petit gain mais facile
4. **Multithreading Collisions** - Plus complexe mais gros gain

### Benchmark cible
- 10000 particules @ 60 FPS (actuel: 20 FPS)
- 50000 particules @ 30 FPS
- 100000 particules @ 15 FPS
