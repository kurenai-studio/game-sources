# ai_agent_v9_balanced.py
# AI Agent for v9 balanced match (tries to load model, else heuristic)

import os, random, itertools
import numpy as np
import pandas as pd
import joblib
from battle_engine import WEAPON_NAMES, combo_power, WEAPON_MAP

MODEL_PATH = "archery_combo_model.joblib"
COLS_PATH = "archery_combo_classes.joblib"  # classes from training
FEAT_PATH = "archery_feature_columns.joblib"  # feature column names from training


def features_from_deck(deck):
    from battle_engine import WEAPON_MAP 
    feat: dict[str, float] = {}
    feat.update({f"has__{a}": 1.0 if a in WEAPON_NAMES and a in deck else 0.0 for a in WEAPON_NAMES})
    elem_counts = {f"elemcount__{e}": float(sum(1 for a in deck if WEAPON_MAP[a]["Element"] == e)) for e in sorted(set(w["Element"] for w in WEAPON_MAP.values()))}
    feat.update(elem_counts)

    damages = [WEAPON_MAP[a]["Damage"] for a in deck]
    if damages:
        feat["avg_deck_damage"] = float(np.mean(damages))
        feat["min_deck_damage"] = float(np.min(damages))
        feat["max_deck_damage"] = float(np.max(damages))
        feat["std_deck_damage"] = float(np.std(damages, ddof=0))
        feat["median_deck_damage"] = float(np.median(damages))
        feat["element_diversity"] = float(len(set(WEAPON_MAP[a]["Element"] for a in deck)))
    else:
        feat["avg_deck_damage"] = 0.0
        feat["min_deck_damage"] = 0.0
        feat["max_deck_damage"] = 0.0
        feat["std_deck_damage"] = 0.0
        feat["median_deck_damage"] = 0.0
        feat["element_diversity"] = 0.0

    return feat
FEAT_PATH = "archery_feature_columns.joblib"  # feature column names from training

class AIAgent:
    def __init__(self):
        self.model = None
        self.feature_cols = None
        self.label_cols = None
        if os.path.exists(MODEL_PATH) and os.path.exists(COLS_PATH) and os.path.exists(FEAT_PATH):
            try:
                self.model = joblib.load(MODEL_PATH)
                self.label_cols = joblib.load(COLS_PATH)  # classes
                self.feature_cols = joblib.load(FEAT_PATH)  # feature column names
                print("[AI] Loaded model:", MODEL_PATH)
                print("[AI] Model classes:", len(self.label_cols))
                print("[AI] Feature columns:", len(self.feature_cols))
            except Exception as e:
                print("[AI] Model load failed:", e)
                self.model = None

    def predict_player_probs(self, player_deck_segment):
        from battle_engine import WEAPON_MAP
        print("Running predict Player probability.......")
        n = len(player_deck_segment)
        print("player_deck_segment : ", player_deck_segment)
        if n == 0:
            return np.ones(0)
        
        # Try to use trained model first
        if self.model is not None and self.feature_cols is not None:
            try:
                # Create feature vector for current deck 
                feat_dict = features_from_deck(player_deck_segment)
                
                # Create feature vector in the exact order as training
                feature_vector = np.zeros(len(self.feature_cols))
                for i, col in enumerate(self.feature_cols):
                    if col in feat_dict:
                        feature_vector[i] = feat_dict[col]
                
                print("feature vector shape:", feature_vector.shape)
                print("feature vector sample:", feature_vector)
               
                
                # Get model prediction
                if hasattr(self.model, 'predict_proba'):
                    proba = self.model.predict_proba(pd.DataFrame([feature_vector], columns=self.feature_cols))[0]

                    # Convert combo predictions to individual arrow probabilities
                    arrow_probs = np.zeros(n)
                    model_classes = self.label_cols if self.label_cols is not None else getattr(self.model, 'classes_', [])
                    print("Model class = ", model_classes)

                    for cls_idx, cls_label in enumerate(model_classes):
                        if cls_idx >= len(proba):
                            break
                        if isinstance(cls_label, bytes):
                            cls_label = cls_label.decode('utf-8')
                        combo_arrows = cls_label.split('|') if isinstance(cls_label, str) else [str(cls_label)]

                        for i, arrow in enumerate(player_deck_segment):
                            if arrow in combo_arrows:
                                arrow_probs[i] += proba[cls_idx]
                    print("combo arrows : ", combo_arrows)
                    print("\n")
                    print(" Arrows  probes : ",arrow_probs)

                    if arrow_probs.sum() > 0:
                        return arrow_probs / arrow_probs.sum()

                    # Fallback if class mapping produced no weights (e.g., rare card not in combo classes)
                    arrow_probs = np.zeros(n)
                    for i, arrow in enumerate(player_deck_segment):
                        arrow_probs[i] = WEAPON_MAP[arrow]['Damage'] * (1 + np.random.uniform(0, 0.2))

                    if arrow_probs.sum() > 0:
                        return arrow_probs / arrow_probs.sum()

            except Exception as e:
                print(f"[AI] Model prediction failed: {e}, using heuristic")
        
        # Fallback heuristic: weight by damage and element diversity
        from battle_engine import WEAPON_MAP
        scores = np.array([WEAPON_MAP[w]["Damage"] for w in player_deck_segment], dtype=float)
        print( "now the model model predictions has failed so we are calculating heuristic scores ............")

        print("scores =",scores)
        
        # Boost for element diversity (players often pick different elements)
        elem_counts = {}
        for arrow in player_deck_segment:
            elem = WEAPON_MAP[arrow]["Element"]
            elem_counts[elem] = elem_counts.get(elem, 0) + 1

        print("ele_counts =",elem_counts)
        
        for i, arrow in enumerate(player_deck_segment):
            elem = WEAPON_MAP[arrow]["Element"]
            # Boost arrows from less common elements
            if elem_counts[elem] == 1:
                scores[i] *= 1.2  # Unique element bonus
            elif elem_counts[elem] == 2:
                scores[i] *= 1.1  # Semi-unique element bonus

        print("ele_counts =",elem_counts)
        
        # Add small randomness
        scores = scores + np.random.uniform(0, 1, size=scores.shape) * 0.1
        print(" returning updated heuristic scores ", scores)
        print(sum(scores))
        if scores.sum() <= 0:
            return np.ones(n) / n
        return scores / scores.sum()

    def pick_ai_combo(self, ai_pool, player_pool, player_probs=None, trials=300):
        """
        Choose best 3-arrow combo from ai_pool (remaining pool) to maximize expected advantage.
        If player_probs is None, sample uniformly (or use damage heuristic).
        """
        if len(ai_pool) <= 3:
            return list(ai_pool[:3])
        # candidate ai combos
        candidate_ai_combos = list(itertools.combinations(ai_pool, 3))
        print(" Now we are inside a function for predicting ai combos  ....")
        # sample player combos
        if player_probs is None:
            # uniform sampling: use all combos up to limit
            sampled_player_combos = list(itertools.islice(itertools.combinations(player_pool, 3), 200))
        else:
            # sample combos using per-item probs

            print ( " we are inside the else part that means we will use existing player prob.... \n")

            print("player pool : ",player_pool ,"\n", "Player probs = ", player_probs)

            idxs = list(range(len(player_pool)))
            print("idx = ",  idxs)
            sampled = set()
            tries = 0
            while len(sampled) < 180 and tries < 800:
                tries += 1
                try:
                    picks = np.random.choice(idxs, 3, replace=False, p=player_probs)
                except Exception:
                    picks = np.random.choice(idxs, 3, replace=False)
                combo = tuple(sorted([player_pool[i] for i in picks]))
                sampled.add(combo)
            sampled_player_combos = list(sampled)

            if not sampled_player_combos:
                sampled_player_combos = list(itertools.islice(itertools.combinations(player_pool,3),200))
        if not sampled_player_combos:
            sampled_player_combos = list(itertools.islice(itertools.combinations(player_pool,3),200))
        # evaluate expected advantage
        best_combo = None
        best_score = -1e9
        for ai_combo in candidate_ai_combos:
            s_combos = sampled_player_combos if len(sampled_player_combos) <= 200 else random.sample(sampled_player_combos,200)
            score = 0.0
            for pcombo in s_combos:
                ai_pow = combo_power(list(ai_combo), vs_defense_combo=list(pcombo))
                pl_pow = combo_power(list(pcombo), vs_defense_combo=list(ai_combo))
                score += (ai_pow - pl_pow)
            score /= max(1, len(s_combos))
            if score > best_score:
                best_score = score
                best_combo = ai_combo
        if best_combo is None:
            return list(random.choice(candidate_ai_combos))
        return list(best_combo)

# small helper to avoid import cycles in heuristic above
def battle_engine(name):
    from battle_engine import WEAPON_MAP
    return WEAPON_MAP[name]["Element"]
