"""
model_train_v9_best.py

Train a strong, practical model to PREDICT PLAYER 3-ARROW COMBOS (v9).
- Simulates realistic player decks and choices.
- Picks top-K frequent combos as target classes (reduces noise).
- Trains RandomForest multi-class classifier to predict exact combo.
- Also prints top-3 per-sample "top-k" hit rate and multi-label metrics.

Outputs:
    archery_combo_model_v9_best.joblib
    archery_combo_le_v9_best.joblib
"""

import os
import random
import itertools
import numpy as np
import pandas as pd
from collections import Counter
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, top_k_accuracy_score
from sklearn.preprocessing import LabelEncoder
import joblib

from battle_engine import WEAPON_MAP, WEAPON_NAMES, synergy_multiplier, combo_power

# --------------------------
# 1) Load master arrow list 
# --------------------------
ARROWS = WEAPON_NAMES

random.seed(42)

# --------------------------
# 2) Data loading + dataset generation (prioritize real logs)
# --------------------------

ELEMENT_POOL = sorted(set(w["Element"] for w in WEAPON_MAP.values()))

CSV_PATHS = ["human_game_log_v9_enhanced.csv", "human_game_log.csv"]

def features_from_deck(deck):
    feat: dict[str, float] = {}
    feat.update({f"has__{a}": 1.0 if a in deck else 0.0 for a in ARROWS})
    elem_counts = {f"elemcount__{e}": float(sum(1 for a in deck if WEAPON_MAP[a]["Element"] == e)) for e in ELEMENT_POOL}
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


def load_samples_from_csv(paths, max_samples=12000):
    samples = []
    for path in paths:
        if not os.path.exists(path):
            continue
        try:
            df = pd.read_csv(path)
        except Exception as e:
            print(f"[DATA] Failed to read {path}: {e}")
            continue

        if "Remaining_Pool" not in df.columns or "Player_Picks" not in df.columns:
            print(f"[DATA] Missing required columns in {path} (need Remaining_Pool, Player_Picks)")
            continue

        for _, row in df.iterrows():
            pool_raw = str(row.get("Remaining_Pool", ""))
            pick_raw = str(row.get("Player_Picks", ""))
            pool = [x.strip() for x in pool_raw.split("|") if x.strip()]
            picks = [x.strip() for x in pick_raw.split("|") if x.strip()]

            if len(pool) < 3 or len(picks) != 3:
                continue

            # label must be sorted combo string
            label = "|".join(sorted(picks))

            # build feature from current remaining pool set
            feat = features_from_deck(pool)
            samples.append((feat, label))

            if len(samples) >= max_samples:
                break
        if len(samples) >= max_samples:
            break

    return samples


SAMPLES = load_samples_from_csv(CSV_PATHS, max_samples=12000)

if len(SAMPLES) == 0:
    print("[DATA] No log-based samples found, generating synthetic dataset...")
else:
    print(f"[DATA] Loaded {len(SAMPLES)} samples from CSV logs.")

if len(SAMPLES) < 3000:
    # fallback to synthetic generation for robust training when logs are insufficient
    print("[DATA] Insufficient CSV samples (<3000), adding synthetic data...")
    NUM_SAMPLES = 12000
    DECK_SIZE = 15
    for i in range(NUM_SAMPLES):
        player_deck = random.sample(ARROWS, DECK_SIZE)
        
        combos = list(itertools.combinations(player_deck, 3))
        scores = []
        for c in combos:
            imagined_def = random.sample(ARROWS, 3)
            power = combo_power(list(c), imagined_def)
            # players favor synergy and base damage (we want structured labels)
            scores.append(max(0.0001, power * (1.0 + random.uniform(-0.05, 0.12))))
            
        # convert to probabilities
        arr = np.array(scores)
        probs = arr / arr.sum()
        chosen_idx = np.random.choice(range(len(combos)), p=probs)
        chosen_combo = combos[chosen_idx]
        # build features using central function to keep types consistent
        feat = features_from_deck(player_deck)
        # label is sorted combo string
        label = "|".join(sorted(chosen_combo))
        SAMPLES.append((feat, label))

# Build DataFrame
feature_dicts = [s[0] for s in SAMPLES]
labels = [s[1] for s in SAMPLES]
X_df = pd.DataFrame(feature_dicts)
y_series = pd.Series(labels, name="combo")

print("Dataset shapes:", X_df.shape, y_series.shape)
print("Feature columns:", len(X_df.columns))
print("Sample feature names:", list(X_df.columns)[:10])
print("Unique combo labels in full set:", y_series.nunique())

# --------------------------
# 4) Reduce target space: keep top-K combos as classes
# --------------------------
TOP_K = 600   # tuneable: trade-off between accuracy and coverage
counter = Counter(y_series)
topk = [c for c,_ in counter.most_common(TOP_K)]
# map labels not in topk to "OTHER"
y_mapped = y_series.apply(lambda x: x if x in topk else "OTHER")
print("Top-K combos kept:", len(topk), "-> fallback OTHER class for rest")
print("Final label distribution (top 10):", counter.most_common(10))

# --------------------------
# 5) Train/test split (stratify on mapped labels)
# --------------------------
X = X_df
# Ensure correct numpy array type for stratify (pyright/mypy wants ArrayLike)
# y_mapped may be pandas Categorical/Extension type depending on pandas version.
# Convert to numpy array before calling train_test_split.
y = np.asarray(y_mapped)

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.20, random_state=42, stratify=y
)

# --------------------------
# 6) Train model (RandomForest multi-class)
# --------------------------
try:
    clf = RandomForestClassifier(
        n_estimators=300,
        max_depth=18,
        min_samples_split=4,
        class_weight="balanced_subsample",
        random_state=42,
        n_jobs=-1
    )
    print("Training RandomForest...")
    clf.fit(X_train, y_train)
except Exception as e:
    print(f"[ERROR] Training failed: {e}")
    import traceback
    traceback.print_exc()
    exit(1)

# --------------------------
# 7) Evaluation
# --------------------------
y_pred = clf.predict(X_test)
exact_acc = accuracy_score(y_test, y_pred)
print(f"\nExact-match (class) accuracy on test: {exact_acc*100:.2f}%")

# classification report for classes present in test
print("\nClassification report (top classes):")
print(classification_report(y_test, y_pred, zero_division=0, labels=list(set(y_test))))

# Top-K (top-3) by predicted proba: we compute top-3 predicted classes and see if true label is among them
# get class probability matrix
proba = clf.predict_proba(X_test)
# sklearn's predict_proba returns list-of-arrays when classes>2; for multiclass RandomForest it returns array
if isinstance(proba, list):
    # rare path: convert to array
    proba_arr = np.vstack([p[:,1] if p.shape[1]>1 else p[:,0] for p in proba]).T
else:
    proba_arr = proba  # shape (n_samples, n_classes)

# need class order
classes = clf.classes_
# top-k accuracy (k=3)
def topk_hit_rate(proba_arr, classes, y_true, k=3):
    hits = 0
    for i, probs in enumerate(proba_arr):
        topk_idx = np.argsort(probs)[-k:][::-1]
        topk_labels = classes[topk_idx]
        if y_true[i] in topk_labels:
            hits += 1
    return hits / len(y_true)

top3 = topk_hit_rate(proba_arr, classes, y_test, k=3)
print(f"Top-3 hit rate (true label in top-3 predicted classes): {top3*100:.2f}%")

# Also compute per-arrow top-3 recall: we can derive predicted combo by picking top class and splitting to arrows
# But a better multi-label metric is beyond this script's main goal.

# --------------------------
# 8) Save model + label encoder for class names
# --------------------------
le = LabelEncoder()
le.fit(np.append(np.array(topk), "OTHER"))  # label encoder only for topk + OTHER
# We will save mapping of classifier.classes_ for loading later
joblib.dump(clf, "archery_combo_model.joblib")
joblib.dump(np.array(clf.classes_), "archery_combo_classes.joblib")
joblib.dump(list(X_df.columns), "archery_feature_columns.joblib")  # Save feature column names
joblib.dump(WEAPON_MAP, "archery_weapon_map.joblib")
print("\nSaved model & classes: archery_combo_model.joblib, archery_combo_classes.joblib, archery_feature_columns.joblib")

# --------------------------
# 9) Quick usage example (how to call from game)
# --------------------------
example_idx = 0
print("\nExample test sample features (first):")
print(X_test.iloc[example_idx].head(20))
print("True label:", y_test[example_idx])
print("Predicted:", y_pred[example_idx])
print("Top-3 predicted classes:", classes[np.argsort(proba_arr[example_idx])[-3:][::-1]])


