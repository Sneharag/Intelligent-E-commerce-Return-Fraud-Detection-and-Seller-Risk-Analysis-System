"""
Generate a realistic synthetic dataset for return fraud detection.

Encoded fraud patterns (ordered by weight):
  - Same-day / next-day return
  - Repeat returns by the same customer (2, 3, 5, 8+)
  - Very high return rate (>= 50%, >= 90%)
  - High-value item + quick return (price > 1000)
  - No image proof on "damaged" / "not_as_described" / "missing_parts"
  - Suspicious reasons ("changed_mind", "late_delivery")
  - Seller already flagged as risky
  - Large quantity returned
  - Underlying customer "behavior" factor (0..1) → adds noise

NEW (added):
  - Same product returned repeatedly by same customer
  - Multiple returns same day
  - New customer returning very fast
  - Return after 25+ days (window abuse)
  - Re-purchase after return
"""

import os
import csv
import random
from collections import defaultdict

random.seed(42)

RETURN_REASONS = [
    "damaged",
    "wrong_item",
    "not_as_described",
    "missing_parts",
    "changed_mind",
    "late_delivery",
]

N_ROWS = 5000
MAX_SCORE = 28.0   # raised from 20 → accounts for the 5 new signals


# ------------------------------------------------------------------
# 1. Simulate per-customer behavior
# ------------------------------------------------------------------
def build_customer_batch(customer_id):
    n_orders = random.randint(1, 8)
    behavior = random.betavariate(2, 3)
    account_age_days = random.randint(0, 1000)   # NEW

    batch = []
    product_ids = [random.randint(1, 20) for _ in range(n_orders)]   # NEW

    for idx in range(n_orders):
        p_return = 0.10 + behavior * 0.85
        if random.random() > p_return:
            continue

        batch.append({
            "_customer":        customer_id,
            "_behavior":        behavior,
            "_account_age":     account_age_days,     # NEW
            "_product_id":      product_ids[idx],     # NEW
            "_order_index":     idx,                  # NEW
            "_repurchase_flag": 0,                    # NEW (filled later)
            "quantity":         random.randint(1, 5),
            "price":            round(random.uniform(100, 5000), 2),
            "return_reason":    random.choice(RETURN_REASONS),
            "has_image":        random.randint(0, 1),
            "days_to_return":   random.randint(0, 30),
            "seller_risk":      random.randint(0, 8),
            "product_stock":    random.randint(0, 200),
        })
    return batch


all_rows = []
cid = 0
while len(all_rows) < N_ROWS * 1.5:
    cid += 1
    all_rows.extend(build_customer_batch(cid))

by_customer = defaultdict(list)
for r in all_rows:
    by_customer[r["_customer"]].append(r)


# ------------------------------------------------------------------
# 2. Score each row
# ------------------------------------------------------------------
final_rows = []

for cid, cust_rows in by_customer.items():
    n_returns = len(cust_rows)
    n_orders  = max(n_returns, random.randint(n_returns, n_returns + 4))
    return_rate = n_returns / n_orders if n_orders else 0

    # NEW: per-product return count for this customer
    product_return_count = defaultdict(int)
    for r in cust_rows:
        product_return_count[r["_product_id"]] += 1

    # NEW: same-day return count (pairs of consecutive orders = same "day")
    same_day_count = defaultdict(int)
    for r in cust_rows:
        same_day_count[r["_order_index"] // 2] += 1

    # NEW: repurchase after return — if customer later re-ordered same product
    for i, r in enumerate(cust_rows):
        for j in range(i + 1, len(cust_rows)):
            other = cust_rows[j]
            if other["_product_id"] == r["_product_id"]:
                r["_repurchase_flag"] = 1
                break

    for r in cust_rows:
        score = 0.0

        # ---- SAME-DAY / VERY FAST RETURN ----
        if r["days_to_return"] == 0:      score += 2.5
        elif r["days_to_return"] <= 1:    score += 2.0
        elif r["days_to_return"] <= 3:    score += 1.0

        # ---- RETURN FREQUENCY ----
        if n_returns >= 2:  score += 1.0
        if n_returns >= 3:  score += 2.5
        if n_returns >= 5:  score += 3.0
        if n_returns >= 8:  score += 3.0

        # ---- RETURN RATE ----
        if return_rate >= 0.5:  score += 2.0
        if return_rate >= 0.9:  score += 3.0

        # ---- HIGH-VALUE + QUICK ----
        if r["price"] > 1000 and r["days_to_return"] <= 3:  score += 2.0
        if r["price"] > 2500 and r["days_to_return"] <= 7:  score += 1.5

        # ---- NO IMAGE ON SERIOUS REASON ----
        if r["has_image"] == 0 and r["return_reason"] in (
            "damaged", "not_as_described", "missing_parts"
        ):
            score += 2.0

        # ---- SUSPICIOUS REASON ----
        if r["return_reason"] in ("changed_mind", "late_delivery"):
            score += 1.0

        # ---- SELLER RISK ----
        if r["seller_risk"] >= 5:  score += 1.5

        # ---- LARGE QUANTITY ----
        if r["quantity"] >= 4:  score += 1.0

        # ---- NEW: SAME PRODUCT RETURNED REPEATEDLY ----
        if product_return_count[r["_product_id"]] >= 2:
            score += 2.5
        if product_return_count[r["_product_id"]] >= 3:
            score += 2.0

        # ---- NEW: MULTIPLE RETURNS SAME DAY ----
        if same_day_count[r["_order_index"] // 2] >= 2:
            score += 2.5

        # ---- NEW: NEW CUSTOMER + FAST RETURN ----
        if r["_account_age"] <= 7 and r["days_to_return"] <= 3:
            score += 2.0

        # ---- NEW: RE-PURCHASE AFTER RETURN ----
        if r["_repurchase_flag"]:
            score += 1.5

        # ---- NEW: RETURN AFTER 25+ DAYS ----
        if r["days_to_return"] >= 25:
            score += 2.0

        # ---- CUSTOMER BEHAVIOR NOISE ----
        score += r["_behavior"] * 4.0

        # ---- score → label ----
        fraud_probability = min(score / MAX_SCORE, 0.97)
        is_fraud = 1 if random.random() < fraud_probability else 0

        final_rows.append({
            # EXISTING 13 features (same order as before)
            "quantity":              r["quantity"],
            "price":                 r["price"],
            "return_reason":         r["return_reason"],
            "has_image":             r["has_image"],
            "days_to_return":        r["days_to_return"],
            "customer_return_count": n_returns,
            "customer_order_count":  n_orders,
            "seller_risk_count":     r["seller_risk"],
            "product_stock":         r["product_stock"],
            # NEW 5 features (appended, order preserved)
            "same_product_return_count": product_return_count[r["_product_id"]],
            "returns_same_day_count":    same_day_count[r["_order_index"] // 2],
            "customer_account_age_days": r["_account_age"],
            "repurchase_after_return":   r["_repurchase_flag"],
            "is_fraud":                  is_fraud,
        })

        if len(final_rows) >= N_ROWS:
            break
    if len(final_rows) >= N_ROWS:
        break


# ------------------------------------------------------------------
# 3. Report + save
# ------------------------------------------------------------------
fraud_count = sum(r["is_fraud"] for r in final_rows)
print(f"Generated {len(final_rows)} rows — "
      f"fraud: {fraud_count}, safe: {len(final_rows) - fraud_count}")

repeat = [r for r in final_rows if r["customer_return_count"] >= 3
          and r["customer_order_count"] > 0
          and r["customer_return_count"] / r["customer_order_count"] >= 0.9]
if repeat:
    flagged = sum(r["is_fraud"] for r in repeat)
    print(f"3+ returns at ≥90% rate: {flagged}/{len(repeat)} flagged as fraud")

out_path = os.path.join(os.path.dirname(__file__), "fraud_dataset_real.csv")
with open(out_path, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=final_rows[0].keys())
    w.writeheader()
    w.writerows(final_rows)

print(f"\nSaved → {out_path}")