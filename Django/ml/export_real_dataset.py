"""
Export real Ordersub rows (with return_seller_risk set)
into fraud_dataset_real.csv for retraining.
"""

import os, sys, django, csv

# add project root to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "Ecommerce_Return_Fraud_Detection.settings")
django.setup()

from datetime import datetime
from myapp.models import Ordersub

def parse_date(s):
    if not s:
        return None
    for fmt in ("%Y-%m-%d", "%d-%m-%Y", "%Y/%m/%d", "%d/%m/%Y"):
        try:
            return datetime.strptime(s, fmt)
        except (ValueError, TypeError):
            continue
    return None

rows = []
qs = Ordersub.objects.select_related(
    "ORDER__DELIVERY_ADDRESS__CUSTOMER",
    "PRODUCT__SELLER",
).exclude(return_reason__isnull=True)

for o in qs:
    customer = o.ORDER.DELIVERY_ADDRESS.CUSTOMER
    seller   = o.PRODUCT.SELLER

    d1 = parse_date(o.ORDER.date)
    d2 = parse_date(o.return_date)
    days_to_return = (d2 - d1).days if d1 and d2 else -1

    try:
        quantity = int(o.quantity)
    except (ValueError, TypeError):
        quantity = 0
    try:
        price = float(o.price)
    except (ValueError, TypeError):
        price = 0.0

    rows.append({
        "quantity": quantity,
        "price": price,
        "return_reason": o.return_reason or "none",
        "has_image": 1 if o.return_image else 0,
        "days_to_return": days_to_return,
        "customer_return_count": Ordersub.objects.filter(
            ORDER__DELIVERY_ADDRESS__CUSTOMER=customer).count(),
        "customer_order_count": Ordersub.objects.filter(
            ORDER__DELIVERY_ADDRESS__CUSTOMER=customer
        ).values("ORDER").distinct().count(),
        "seller_risk_count": Ordersub.objects.filter(
            PRODUCT__SELLER=seller,
            return_seller_risk__isnull=False,
        ).exclude(return_seller_risk="").count(),
        "product_stock": o.PRODUCT.stock,
        "is_fraud": 1 if o.is_fraud else 0,
    })

out = os.path.join(os.path.dirname(__file__), "fraud_dataset_real.csv")
with open(out, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys())
    w.writeheader()
    w.writerows(rows)

fraud = sum(r["is_fraud"] for r in rows)
print(f"Exported {len(rows)} rows — fraud: {fraud}, safe: {len(rows) - fraud}")
print(f"Saved → {out}")