// Corrections d'images des chapitres 7 à 9 (agent IMAGES, 19/10). Aucun job pour process-art.mjs : les retouches ont été
// faites hors pipeline (scripts Python + nano-banana), anciens fichiers gardés en `_v1` / `_v2`. Pour mémoire :
//  - props/portail_apex_ouvert.png : nano-banana (image entière sur magenta ×3) -> cinq disques (2+3), détourée et ramenée à 462×475 ; ancien = _v1
//  - dinos/trex_magma_face_dos.png : 3 essais nano-banana refusés (fumée énorme en défenses) -> REPLI par script : la fumée existante
//    (pixels gris peu saturés, rangée de face seule) est opacifiée, éclaircie, épaissie de 1 px et cernée ; dos intact ; ancien = _v2
//  - characters/helene_assise_sans_fauteuil.png : vue de dos de la rangée assise redessinée par nano-banana (assise de dos), détourée,
//    réduite à 160 px de haut et resserrée à 72 % en largeur ; autres cases intactes ; ancien = _v2
//  - characters/maia_arche_assise.png : têtes de la rangée assise agrandies de 24 % par script (coupe sous le menton, ancrage au cou) ; ancien = _v2
//  - characters/leonce_assis.png : case 2 = case 1 en miroir (cape alignée) ; ancien = _v2
//  - characters/leonce_port.png : liseré rose des bords neutralisé, pixels roses du filet rendus transparents ; ancien = _v2
export default () => [];
