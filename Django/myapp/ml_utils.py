"""
Loads the fraud model once and exposes predict_fraud(ordersub).

Returns (is_fraud: bool, confidence: float).

Includes:
  - Robust date parsing (multiple formats)
  - Correct customer / seller counts
  - Behavioral pattern detection
  - NEW: same-product return tracking
  - NEW: same-day return count
  - NEW: customer account age
  - NEW: repurchase-after-return detection
"""

import os
import joblib
from datetime import datetime, timedelta
from django.conf import settings

ML_DIR       = os.path.join(settings.BASE_DIR, "ml")
MODEL_PATH   = os.path.join(ML_DIR, "fraud_model.pkl")
ENCODER_PATH = os.path.join(ML_DIR, "reason_encoder.pkl")

_model   = None
_encoder = None


def _load():
    global _model, _encoder
    if _model is None:
        _model   = joblib.load(MODEL_PATH)
        _encoder = joblib.load(ENCODER_PATH)
    return _model, _encoder


# ---------------------------------------------------------------
# Date parsing
# ---------------------------------------------------------------
_DATE_FORMATS = (
    "%Y-%m-%d",
    "%Y-%m-%d %H:%M:%S",
    "%Y-%m-%d %H:%M:%S.%f",
    "%Y/%m/%d",
    "%d-%m-%Y",
    "%d/%m/%Y",
    "%d %b %Y",
    "%b %d, %Y",
    "%Y-%m-%dT%H:%M:%S",
    "%Y-%m-%dT%H:%M:%S.%f",
)

def _parse_date(s):
    if not s:
        return None
    if isinstance(s, datetime):
        return s
    s = str(s).strip()
    for fmt in _DATE_FORMATS:
        try:
            return datetime.strptime(s, fmt)
        except (ValueError, TypeError):
            continue
    return None


# ---------------------------------------------------------------
# Main prediction function
# ---------------------------------------------------------------
def predict_fraud(ordersub):
    from .models import Ordersub

    model, encoder = _load()

    order    = ordersub.ORDER
    customer = order.DELIVERY_ADDRESS.CUSTOMER
    seller   = ordersub.PRODUCT.SELLER

    # ---- days to return ----
    d1 = _parse_date(order.date)
    d2 = _parse_date(ordersub.return_date)
    if d1 and d2:
        days_to_return = (d2 - d1).days
        if days_to_return < 0:
            days_to_return = 0
    else:
        days_to_return = -1

    # ---- encode return_reason ----
    reason = (ordersub.return_reason or "none").strip()
    reason_code = int(encoder.transform([reason])[0]) if reason in encoder.classes_ else 0

    # ============================================================
    # COUNTS — both "total including current" AND "before current"
    # ============================================================

    # Total returns by this customer (INCLUDING current row)
    customer_return_count_total = Ordersub.objects.filter(
        ORDER__DELIVERY_ADDRESS__CUSTOMER=customer,
        status="Returned",
    ).count()

    # Returns BEFORE this one (for ML feature — training semantic)
    customer_return_count = max(customer_return_count_total - 1, 0)

    customer_order_count = Ordersub.objects.filter(
        ORDER__DELIVERY_ADDRESS__CUSTOMER=customer
    ).values("ORDER").distinct().count()

    seller_risk_count = Ordersub.objects.filter(
        PRODUCT__SELLER=seller,
        return_seller_risk__isnull=False,
    ).exclude(return_seller_risk="").count()

    # Same product returned — BEFORE this one (for ML feature)
    same_product_return_count = Ordersub.objects.filter(
        ORDER__DELIVERY_ADDRESS__CUSTOMER=customer,
        PRODUCT=ordersub.PRODUCT,
        status="Returned",
    ).exclude(id=ordersub.id).count()

    # Same-day returns — BEFORE this one (for ML feature)
    returns_same_day_count_before = 0
    if d2:
        day_start = d2.replace(hour=0, minute=0, second=0, microsecond=0)
        day_end   = day_start + timedelta(days=1)
        for o in Ordersub.objects.filter(
            ORDER__DELIVERY_ADDRESS__CUSTOMER=customer,
            return_date__isnull=False,
        ).exclude(return_date="").exclude(id=ordersub.id):
            od = _parse_date(o.return_date)
            if od and day_start <= od < day_end:
                returns_same_day_count_before += 1

    # Same-day returns INCLUDING current row (for behavioral rules)
    returns_same_day_count_total = returns_same_day_count_before + 1

    # ---- customer account age ----
    try:
        customer_account_age_days = (
            datetime.now().date() - customer.USER.date_joined.date()
        ).days
    except Exception:
        customer_account_age_days = 9999

    # ---- repurchase after return ----
    repurchase_after_return = 0
    if d2:
        others = Ordersub.objects.filter(
            ORDER__DELIVERY_ADDRESS__CUSTOMER=customer,
            PRODUCT=ordersub.PRODUCT,
            ORDER__date__isnull=False,
        ).exclude(id=ordersub.id)
        for lo in others:
            lod = _parse_date(lo.ORDER.date)
            if lod and lod > d2:
                repurchase_after_return = 1
                break

    # ---- numeric casts ----
    try:    quantity = int(ordersub.quantity)
    except (ValueError, TypeError): quantity = 0
    try:    price = float(ordersub.price)
    except (ValueError, TypeError): price = 0.0

    # ============================================================
    # ML PREDICTION (13 features — order matters, matches training)
    # ============================================================
    features = [[
        quantity,
        price,
        reason_code,
        1 if ordersub.return_image else 0,
        days_to_return,
        customer_return_count,                    # BEFORE count
        customer_order_count,
        seller_risk_count,
        ordersub.PRODUCT.stock,
        same_product_return_count,                # BEFORE count
        returns_same_day_count_before,            # BEFORE count
        customer_account_age_days,
        repurchase_after_return,
    ]]

    pred = int(model.predict(features)[0])
    prob = float(model.predict_proba(features)[0][1])

    is_fraud   = bool(pred)
    confidence = prob

    # =============================================================
    # HARD RULE OVERRIDES — behavioral pattern detection
    # Rule: single return = safe. Repeated returns = fraud.
    # =============================================================
    return_rate_total = (
        customer_return_count_total / customer_order_count
        if customer_order_count else 0
    )

    # ---- FRAUD patterns (require REPEATED behavior) ----

    # 1. Serial returner — 3+ total returns at ≥90% rate
    if customer_return_count_total >= 3 and return_rate_total >= 0.9:
        is_fraud   = True
        confidence = max(confidence, 0.90)

    # 2. Very frequent returner — 5+ total returns
    if customer_return_count_total >= 5:
        is_fraud   = True
        confidence = max(confidence, 0.95)

    # 3. Multiple returns on the SAME DAY — 2+ including current
    if returns_same_day_count_total >= 2:
        is_fraud   = True
        confidence = max(confidence, 0.92)

    # 4. Same product returned 3+ times
    if same_product_return_count >= 3:
        is_fraud   = True
        confidence = max(confidence, 0.90)

    # 5. High return rate + high-value item + multiple returns
    if (customer_return_count_total >= 3
        and return_rate_total >= 0.5
        and price > 1000):
        is_fraud   = True
        confidence = max(confidence, 0.85)

    # 6. Repurchase-after-return (buy → return → buy → return)
    if repurchase_after_return == 1 and customer_return_count_total >= 2:
        is_fraud   = True
        confidence = max(confidence, 0.80)

    # 7. Return after 25+ days (window abuse) — only if repeat
    if days_to_return >= 25 and customer_return_count_total >= 2:
        is_fraud   = True
        confidence = max(confidence, 0.80)

    # ---- SAFE override (single clean return) ----
    # If this is their FIRST return, no same-day spam, has proof, credible reason
    # → force SAFE, even if ML was mildly suspicious
    CREDIBLE_REASONS = {
        "damaged", "wrong_item", "not_as_described", "missing_parts"
    }
    if (
        customer_return_count_total == 1                    # first return
        and returns_same_day_count_total <= 1               # no same-day spam
        and same_product_return_count <= 1                  # no repeat product
        and ordersub.return_image                           # has proof
        and (ordersub.return_reason or "").strip() in CREDIBLE_REASONS
    ):
        is_fraud   = False
        confidence = min(confidence, 0.15)

    return is_fraud, round(confidence, 3)