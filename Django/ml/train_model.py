"""
Train a Random Forest classifier on fraud_dataset.csv
Saves: fraud_model.pkl and reason_encoder.pkl
"""

import os
import pandas as pd
import joblib
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix

BASE = os.path.dirname(__file__)

# --- 1. Load dataset ---
csv_path = os.path.join(BASE, "fraud_dataset.csv")
df = pd.read_csv(csv_path)
print(f"Loaded {len(df)} rows from {csv_path}")
print(f"Fraud distribution:\n{df['is_fraud'].value_counts()}\n")

# --- 2. Encode categorical column (return_reason) ---
le = LabelEncoder()
df["return_reason"] = le.fit_transform(df["return_reason"].astype(str))
print(f"Return reason classes: {list(le.classes_)}\n")

# --- 3. Split features / label ---
X = df.drop("is_fraud", axis=1)
y = df["is_fraud"]

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# --- 4. Train Random Forest ---
model = RandomForestClassifier(
    n_estimators=200,
    max_depth=10,
    random_state=42,
    class_weight="balanced",
)
model.fit(X_train, y_train)

# --- 5. Evaluate ---
pred = model.predict(X_test)
print("Accuracy:", round(accuracy_score(y_test, pred), 4))
print("\nClassification Report:")
print(classification_report(y_test, pred))
print("Confusion Matrix:")
print(confusion_matrix(y_test, pred))

# --- 6. Feature importance (nice to show your guide) ---
print("\nFeature Importance:")
for name, imp in sorted(
    zip(X.columns, model.feature_importances_),
    key=lambda x: -x[1],
):
    print(f"  {name:25s} {imp:.4f}")

# --- 7. Save model + encoder ---
model_path = os.path.join(BASE, "fraud_model.pkl")
encoder_path = os.path.join(BASE, "reason_encoder.pkl")
joblib.dump(model, model_path)
joblib.dump(le, encoder_path)
print(f"\nSaved → {model_path}")
print(f"Saved → {encoder_path}")