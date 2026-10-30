import os
import random
import csv
from django.db.models import Q
from django.core.paginator import Paginator
import datetime
from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth.hashers import make_password, check_password
from django.contrib.auth.models import Group
from django.core.files.storage import FileSystemStorage
from django.core.mail import EmailMultiAlternatives
from django.db.models import Count, Avg, Q
from django.http import HttpResponse, JsonResponse
from django.shortcuts import render, redirect

# Create your views here.
from django.views.decorators.cache import never_cache

from Ecommerce_Return_Fraud_Detection import settings
from myapp.models import *


def index(request):
    return render(request,'index.html')

def logins(request):
    return render(request,"login.html")

def loginpost(request):
    username = request.POST['email']
    password = request.POST['password']
    data = authenticate(request,username=username, password=password)
    if data:
        login(request,data)
        if data.is_superuser:
            return redirect('/myapp/admin_dashboard')
        if data.groups.filter(name="seller").exists():
            request.session['sid']=Seller.objects.get(USER=data.id).id
            status = Seller.objects.get(id=request.session['sid']).status
            if status=='Approved':
                return redirect("/myapp/seller_dashboard")

            elif status=='Pending':
                messages.error(request,"Request still pending!!")
                return redirect("/myapp/login")

            elif status=='Rejected':
                messages.error(request,"Sorry, your profile has rejected!!")
                return redirect("/myapp/login")
        else:
            messages.error(request,"Invalid Username/Password!!")
            return redirect("/myapp/login")
    else:
        messages.error(request, "Invalid Username/Password!!")
        return redirect('/myapp/login')

def logouts(request):
    logout(request)
    request.session.flush()
    return redirect('/myapp/login')

def forgotpassword(request):
    return render(request, "forgotpassword.html")

def forgotpasswordbuttonclick(request):
    email = request.POST['textfield']

    if User.objects.filter(username=email).exists():

        pwd = str(random.randint(1100, 9999))

        request.session['otp'] = pwd
        request.session['email'] = email

        subject = f"Your OTP - {os.path.basename(settings.BASE_DIR)}"

        html_content = f"""
        <html>
        <body style="font-family:Arial,sans-serif;">
            <h2 style="color:#2c7be5;">{os.path.basename(settings.BASE_DIR)}</h2>

            <p>Hello,</p>

            <p>Your OTP is:</p>

            <div style="
                padding:10px;
                border:1px solid #ddd;
                display:inline-block;
                font-size:20px;
                font-weight:bold;
                color:#2c7be5;
                background:#f5f5f5;
            ">
                {pwd}
            </div>

            <p>Please do not share this OTP with anyone.</p>

            <hr>
            <small>This is an automated email from {os.path.basename(settings.BASE_DIR)}.</small>

        </body>
        </html>
        """

        email_message = EmailMultiAlternatives(
            subject=subject,
            body="Your OTP: " + pwd,
            from_email=None,
            to=[email]
        )

        email_message.attach_alternative(html_content, "text/html")
        email_message.send()

        return HttpResponse(
            "<script>window.location='/myapp/otp'</script>"
        )

    else:
        return HttpResponse(
            "<script>alert('Email not found');window.location='/myapp/forgotpassword'</script>"
        )

def otp(request):
    return render(request,"otp.html")

def otpbuttonclick(request):
    otp = request.POST["textfield"]

    if otp == str(request.session['otp']):
        return HttpResponse("<script>window.location='/myapp/forgotpswdpswed'</script>")
    else:
        return HttpResponse("<script>alert('Incorrect OTP');window.location='/myapp/otp'</script>")

def forgotpswdpswed(request):
    return render(request,"forgotpswdpswed.html")

def forgotpswdpswedbuttonclick(request):
    np = request.POST["password"]

    User.objects.filter(
        username=request.session['email']
    ).update(password=make_password(np))

    return HttpResponse(
        "<script>alert('Password changed successfully');window.location='/myapp/login'</script>"
    )

# ------admin-----
@never_cache
@login_required(login_url='/myapp/login')
# def admin_dashboard(request):
#     return render(request,'admin/admin_dashboard.html')

def admin_dashboard(request):
    # ── Counts ──
    total_sellers = Seller.objects.all().count()
    verified_sellers = Seller.objects.filter(status="Approved").count()
    total_users = Customer.objects.all().count()

    # ── Suspicious returns (returned items) ──
    suspicious_count = Ordersub.objects.filter(
        status__in=["Returned","Pickuped & Refunded"]
    ).count()

    # ── Total orders & revenue ──
    total_orders = Order.objects.count()
    total_revenue = 0.0
    for o in Order.objects.all():
        try:
            total_revenue += float(o.total_amount or 0)
        except Exception:
            pass

    # ── Order status distribution ──
    status_counts = {
        "delivered": Order.objects.filter(status__iexact="Delivered").count(),
        "shipped": Order.objects.filter(status__iexact="Shipped").count(),
        "pending": Order.objects.filter(status__iexact="Pending").count(),
        "cancelled": Order.objects.filter(status__iexact="Cancelled").count(),
    }

    # ── Weekly returns trend (last 8 weeks) ──
    # Since 'date' is a CharField, we bucket by counting per week using string comparison
    # Simple approach: last 8 groups of recent orders by order id
    recent_orders = list(Order.objects.order_by("-id")[:8])
    returns_trend_labels = []
    returns_trend_data = []
    fraud_trend_data = []

    for o in reversed(recent_orders):
        returns_trend_labels.append(f"#{o.id}")
        # count items in this order
        item_count = Ordersub.objects.filter(ORDER=o).count()
        returns_trend_data.append(item_count)
        # fraud = items with return status
        flagged = Ordersub.objects.filter(
            ORDER=o, status__icontains="return"
        ).count()
        fraud_trend_data.append(flagged)

    # ── Recent suspicious cases (returned items) ──
    suspicious_items = Ordersub.objects.filter(
        status__icontains="Returned"
    ).order_by("-id")[:5]

    recent_cases = []
    for it in suspicious_items:
        recent_cases.append({
            "order_id": it.ORDER.id,
            "customer": it.ORDER.DELIVERY_ADDRESS.CUSTOMER.name
                        if it.ORDER.DELIVERY_ADDRESS and it.ORDER.DELIVERY_ADDRESS.CUSTOMER
                        else "Customer",
            "risk": "High" if "return" in (it.status or "").lower() else "Medium",
            "status": it.status or "Returned",
        })

    # ── Most returned products ──
    returned_products = (
        Ordersub.objects
        .filter(status__in=["Returned","Pickuped & Refunded"])
        .values("PRODUCT__id", "PRODUCT__name", "PRODUCT__image")
        .annotate(return_count=Count("id"))
        .order_by("-return_count")[:5]
    )

    top_returned = []
    for rp in returned_products:
        top_returned.append({
            "name": rp["PRODUCT__name"],
            "image": rp["PRODUCT__image"],
            "returns": rp["return_count"],
        })

    # ── Latest reviews ──
    reviews = Review.objects.order_by("-id")[:5]
    latest_reviews = []
    for r in reviews:
        latest_reviews.append({
            "customer": r.CUSTOMER.name,
            "rating": r.rating,
            "review": r.review,
            "date": r.date,
        })

    # ── Top sellers by orders ──
    top_sellers = []
    for s in Seller.objects.all()[:5]:
        order_count = Ordersub.objects.filter(
            PRODUCT__SELLER=s
        ).values("ORDER").distinct().count()
        top_sellers.append({
            "name": s.name,
            "orders": order_count,
            "status": s.status,
        })
    top_sellers.sort(key=lambda x: x["orders"], reverse=True)

    context = {
        "total_sellers": total_sellers,
        "verified_sellers": verified_sellers,
        "total_users": total_users,
        "suspicious_cases": suspicious_count,
        "total_orders": total_orders,
        "total_revenue": round(total_revenue, 2),
        "status_counts": status_counts,
        "recent_cases": recent_cases,
        "top_returned": top_returned,
        "latest_reviews": latest_reviews,
        "top_sellers": top_sellers,
        # Chart data as JSON-safe lists
        "returns_trend_labels": returns_trend_labels,
        "returns_trend_data": returns_trend_data,
        "fraud_trend_data": fraud_trend_data,
    }

    return render(request, 'admin/admin_dashboard.html', context)

@never_cache
@login_required(login_url='/myapp/login')
def admin_viewsellers(request):
    data=Seller.objects.filter(status="Pending").order_by('-id')
    return render(request,'admin/view_sellers.html',{'sellers':data})

@never_cache
@login_required(login_url='/myapp/login')
def admin_approveseller(request,id):
    seller = Seller.objects.get(id=id)
    seller.status = "Approved"
    seller.save()

    email = seller.USER.username
    print(email)
    status = seller.status
    name = seller.name

    subject = f"Your Account Status - {os.path.basename(settings.BASE_DIR)}"

    html_content = f"""
               <html>
               <body style="font-family:Arial,sans-serif;">
                   <h2 style="color:#2c7be5;">{os.path.basename(settings.BASE_DIR)}</h2>

                   <p>Hello,</p>

                   <p>Your Account - {name} has been:</p>

                   <div style="
                       padding:10px;
                       border:1px solid #ddd;
                       display:inline-block;
                       font-size:20px;
                       font-weight:bold;
                       color:#2c7be5;
                       background:#f5f5f5;
                   ">
                       {status}
                   </div>


                   <hr>
                   <small>This is an automated email from {os.path.basename(settings.BASE_DIR)}.</small>

               </body>
               </html>
               """
    email_message = EmailMultiAlternatives(
        subject=subject,
        body="Account Status: " + status,
        from_email=None,
        to=[email]
    )
    email_message.attach_alternative(html_content, "text/html")
    email_message.send()

    messages.success(request, "Account Approved!")
    return redirect('/myapp/admin_viewverifiedsellers')

@never_cache
@login_required(login_url='/myapp/login')
def admin_rejectseller(request,id):
    seller = Seller.objects.get(id=id)
    seller.status = "Rejected"
    seller.save()

    email = seller.USER.username
    print(email)
    status = seller.status
    name = seller.name

    subject = f"Your Account Status - {os.path.basename(settings.BASE_DIR)}"

    html_content = f"""
                   <html>
                   <body style="font-family:Arial,sans-serif;">
                       <h2 style="color:#2c7be5;">{os.path.basename(settings.BASE_DIR)}</h2>

                       <p>Hello,</p>

                       <p>Your Account - {name} has been:</p>

                       <div style="
                           padding:10px;
                           border:1px solid #ddd;
                           display:inline-block;
                           font-size:20px;
                           font-weight:bold;
                           color:#2c7be5;
                           background:#f5f5f5;
                       ">
                           {status}
                       </div>


                       <hr>
                       <small>This is an automated email from {os.path.basename(settings.BASE_DIR)}.</small>

                   </body>
                   </html>
                   """
    email_message = EmailMultiAlternatives(
        subject=subject,
        body="Account Status: " + status,
        from_email=None,
        to=[email]
    )
    email_message.attach_alternative(html_content, "text/html")
    email_message.send()

    messages.success(request, "Account Rejected!")
    return redirect('/myapp/admin_viewsellers')

@never_cache
@login_required(login_url='/myapp/login')
def admin_viewverifiedsellers(request):
    data = Seller.objects.filter(status="Approved").order_by('-id')
    return render(request,'admin/verified_sellers.html',{'sellers':data})

@never_cache
@login_required(login_url='/myapp/login')
def admin_viewusers(request):
    data=Customer.objects.all().order_by('-id')
    def _parse_date(s):
        for fmt in ("%Y-%m-%d", "%d-%m-%Y", "%Y/%m/%d", "%d/%m/%Y"):
            try:
                return datetime.datetime.strptime(str(s), fmt)
            except (ValueError, TypeError):
                pass
        return None

    for i in data:
        i.address = Deliveryaddress.objects.get(CUSTOMER_id=i.id)

        # ---- order / return counts ----
        total_orders = Ordersub.objects.filter(
            ORDER__DELIVERY_ADDRESS__CUSTOMER=i
        ).values("ORDER").distinct().count()

        total_returns = Ordersub.objects.filter(
            ORDER__DELIVERY_ADDRESS__CUSTOMER=i,
            status="Returned",
        ).count()

        fraud_flags = Ordersub.objects.filter(
            ORDER__DELIVERY_ADDRESS__CUSTOMER=i,
            is_fraud=True,
        ).count()

        # ---- same-day multiple returns ----
        dates = []
        for o in Ordersub.objects.filter(
                ORDER__DELIVERY_ADDRESS__CUSTOMER=i,
                status="Returned",
                return_date__isnull=False,
        ).exclude(return_date=""):
            d = _parse_date(o.return_date)
            if d:
                dates.append(d.date())

        day_counts = {}
        for d in dates:
            day_counts[d] = day_counts.get(d, 0) + 1
        same_day_spam = sum(c for c in day_counts.values() if c >= 2)

        # ---- same product returned 2+ times ----
        same_product_dupes = (
            Ordersub.objects.filter(
                ORDER__DELIVERY_ADDRESS__CUSTOMER=i,
                status="Returned",
            )
                .values("PRODUCT")
                .annotate(c=Count("id"))
                .filter(c__gte=2)
                .count()
        )

        return_rate = (total_returns / total_orders) if total_orders else 0

        # ---- behavioural risk score (0..100) ----
        score = 0.0

        if total_returns >= 2: score += 10
        if total_returns >= 3: score += 15
        if total_returns >= 5: score += 20
        if total_returns >= 8: score += 20

        if return_rate >= 0.5: score += 10
        if return_rate >= 0.9: score += 20

        score += min(fraud_flags * 15, 40)

        if same_day_spam >= 2:  score += 20
        if same_product_dupes >= 1: score += 10
        if same_product_dupes >= 2: score += 10

        try:
            age = (datetime.now().date() - i.USER.date_joined.date()).days
            if age <= 7 and total_returns >= 1:
                score += 15
        except Exception:
            pass

        i.risk_score = int(min(max(score, 0), 100))

        if i.risk_score >= 65:
            i.risk_level = "high"
        elif i.risk_score >= 35:
            i.risk_level = "medium"
        else:
            i.risk_level = "low"

        if total_orders == 0:
            i.risk_label = "No orders yet"
        else:
            i.risk_label = f"{total_returns} returns / {total_orders} orders"

    return render(request,'admin/view_users.html',{'users':data})

@never_cache
@login_required(login_url='/myapp/login')
def admin_blockuser(request,id):
    user=Customer.objects.get(id=id)
    user.status="blocked"
    user.save()
    return redirect('/myapp/admin_viewusers')

def admin_unblockuser(request,id):
    user=Customer.objects.get(id=id)
    user.status='registered'
    user.save()
    return redirect('/myapp/admin_viewusers')

@never_cache
@login_required(login_url='/myapp/login')
def admin_viewfeedback(request):
    data=Feedback.objects.all()
    return render(request,'admin/view_feedback.html',{'feedbacks':data})

@never_cache
@login_required(login_url='/myapp/login')
def admin_changepassword(request):
    return render(request,'admin/change_password.html')

@never_cache
@login_required(login_url='/myapp/login')
def admin_changepassword_post(request):
    current_password = request.POST['currentpassword']
    new_password = request.POST['newpassword']
    confirm_password = request.POST['confirmpassword']

    data = check_password(current_password, request.user.password)
    if data:
        if new_password == confirm_password:
            udata = request.user
            udata.set_password(new_password)
            udata.save()
            messages.success(request,"Password Changed successfully!!!Login with new Credentials")
            return redirect('/myapp/login')
        else:
            messages.error(request, "Password Mismatch")
            return redirect('/myapp/admin_changepassword')
    messages.error(request, "Incorrect Password!!")
    return redirect('/myapp/admin_changepassword')

@never_cache
@login_required(login_url='/myapp/login')
def admin_viewsuspiciouscases(request):
    filter_type = request.GET.get('filter', 'all')

    # Base queryset — all returned items with fraud risk data
    qs = (
        Ordersub.objects
            .filter(status="Returned")
            .exclude(return_seller_risk__isnull=True)
            .exclude(return_seller_risk="")
            .select_related('ORDER', 'PRODUCT',
                            'PRODUCT__SELLER',
                            'ORDER__DELIVERY_ADDRESS',
                            'ORDER__DELIVERY_ADDRESS__CUSTOMER')
            .order_by('-return_date')
    )

    # ── Build row data ──
    cases = []
    flagged_count = 0
    safe_count = 0

    for it in qs:
        # Parse confidence from "Fraud 87.5%" or "Safe 92.1%"
        confidence_pct = 0.0
        risk_str = (it.return_seller_risk or "").strip()
        if "%" in risk_str:
            try:
                confidence_pct = float(risk_str.split()[-1].replace("%", ""))
            except (ValueError, IndexError):
                pass

        is_fraud = bool(it.is_fraud)
        if is_fraud:
            flagged_count += 1
        else:
            safe_count += 1

        customer_name = (
            it.ORDER.DELIVERY_ADDRESS.CUSTOMER.name
            if it.ORDER and it.ORDER.DELIVERY_ADDRESS and it.ORDER.DELIVERY_ADDRESS.CUSTOMER
            else "Customer"
        )

        cases.append({
            "id": it.id,
            "order_id": it.ORDER.id if it.ORDER else "",
            "customer_name": customer_name,
            "product_name": it.PRODUCT.name if it.PRODUCT else "",
            "seller_name": it.PRODUCT.SELLER.name if it.PRODUCT and it.PRODUCT.SELLER else "",
            "return_reason": it.return_reason or "—",
            "return_image": it.return_image or "",
            "return_date": it.return_date or "—",
            "is_fraud": is_fraud,
            "confidence_pct": f"{confidence_pct:.1f}",
        })

    # ── Apply fraud/safe filter after building (so counts reflect the full set) ──
    if filter_type == "fraud":
        cases = [c for c in cases if c["is_fraud"]]
    elif filter_type == "safe":
        cases = [c for c in cases if not c["is_fraud"]]

    # ── Pagination ──
    paginator = Paginator(cases, 20)

    try:
        page_number = int(request.GET.get("page", 1))
        if page_number < 1:
            page_number = 1
    except (ValueError, TypeError):
        page_number = 1

    page_obj = paginator.get_page(page_number)

    total_returns = Ordersub.objects.filter(status="Returned").count()
    fraud_rate = round((flagged_count / total_returns * 100), 1) if total_returns else 0

    context = {
        "suspicious": page_obj.object_list,
        "page_obj": page_obj,
        "total_count": len(cases),

        "filter_type": filter_type,
        "all_count": flagged_count + safe_count,
        "fraud_count": flagged_count,
        "safe_count": safe_count,

        "flagged_count": flagged_count,
        "pending_review": flagged_count,  # adjust if you track "reviewed" status
        "confirmed_fraud": 0,  # adjust once you have an admin action for this
        "total_returns": total_returns,
        "fraud_rate": fraud_rate,
    }

    return render(request, "admin/admin_viewsuspiciouscases.html", context)


# -------seller---------

def seller_register(request):
    return render(request,'seller/register.html')

def seller_registerpost(request):
    name = request.POST['name']
    email = request.POST['email']
    phone = request.POST['phone']
    place = request.POST['place']
    post = request.POST['post']
    pin = request.POST['pin']
    proof = request.FILES['proof']
    fs = FileSystemStorage()
    proof = fs.url(fs.save(proof.name, proof))
    password1 = request.POST['password1']
    password2 = request.POST['password2']

    if password1 != password2:
        messages.error(request, "Password Mismatch!!")
        return redirect('/myapp/seller_register')

    if User.objects.filter(username=email).exists():
        messages.error(request, "Email already Exists!!")
        return redirect('/myapp/seller_register')

    obj = User()
    obj.username = email
    obj.password = make_password(password1)
    obj.save()

    obj1 = Group.objects.filter(name="seller")

    if obj1.exists():
        obj.groups.add(Group.objects.get(name="seller"))

    else:
        obj2 = Group()
        obj2.name = "seller"
        obj2.save()
        obj.groups.add(Group.objects.get(name="seller"))

    obj3 = Seller()
    obj3.name = name
    obj3.email = email
    obj3.phone = phone
    obj3.place = place
    obj3.post = post
    obj3.pin = pin
    obj3.proof = proof
    obj3.status='Pending'
    obj3.USER = obj
    obj3.save()
    messages.success(request, "Registered successfully")
    return redirect("/myapp/login")

@never_cache
@login_required(login_url='/myapp/login')
# def seller_dashboard(request):
#     seller=Seller.objects.get(id=request.session['sid'])
#     return render(request,'seller/seller_dashboard.html',{"name":seller.name})


def seller_dashboard(request):
    seller_id = request.session['sid']
    if not seller_id:
        return redirect('/myapp/login/')

    seller = Seller.objects.get(id=seller_id)

    # ── Products listed by this seller ──
    total_products = Product.objects.filter(SELLER=seller).count()

    # ── Order items belonging to this seller's products ──
    items = Ordersub.objects.filter(PRODUCT__SELLER=seller)

    # ── Total distinct orders ──
    total_orders = items.values("ORDER").distinct().count()

    # ── Total sales (sum of price × quantity) ──
    total_sales = 0.0
    for it in items:
        try:
            total_sales += float(it.price) * int(it.quantity)
        except Exception:
            pass

    # ── Pending returns (items with return status) ──
    pending_returns = items.filter(
        status__in=["Returned","Pickuped & Refunded"]
    ).count()

    # ── Recent orders (last 5 distinct) ──
    recent_order_ids = (
        items.values_list("ORDER_id", flat=True)
        .distinct()
        .order_by("-ORDER_id")[:5]
    )
    recent_orders = []
    for oid in recent_order_ids:
        o = Order.objects.filter(id=oid).first()
        if not o:
            continue
        customer_name = "Customer"
        try:
            if o.DELIVERY_ADDRESS and o.DELIVERY_ADDRESS.CUSTOMER:
                customer_name = o.DELIVERY_ADDRESS.CUSTOMER.name
        except Exception:
            pass
        recent_orders.append({
            "id": o.id,
            "customer": customer_name,
            "amount": o.total_amount,
            "status": o.status or "Pending",
        })

    # ── Pending return requests ──
    return_items = items.filter(status__in=["Returned","Pickuped & Refunded"]).order_by("-id")[:5]
    pending_return_list = []
    for it in return_items:
        customer_name = "Customer"
        try:
            if it.ORDER.DELIVERY_ADDRESS and it.ORDER.DELIVERY_ADDRESS.CUSTOMER:
                customer_name = it.ORDER.DELIVERY_ADDRESS.CUSTOMER.name
        except Exception:
            pass

        # Simple risk label based on return_reason length or status text
        reason_text = (it.return_reason or "").lower()
        if "damage" in reason_text or "wrong" in reason_text or "not as" in reason_text:
            risk_label = "High"
        elif "size" in reason_text or "color" in reason_text:
            risk_label = "Med"
        else:
            risk_label = "Low"

        pending_return_list.append({
            "order_id": it.ORDER.id,
            "customer": customer_name,
            "product": it.PRODUCT.name if it.PRODUCT else "—",
            "reason": it.return_reason or "—",
            "risk": risk_label,
            "status": it.status or "Returned",
        })

    # ── Revenue & refund trend (last 8 distinct orders) ──
    last_orders = list(
        items.values_list("ORDER_id", flat=True)
            .distinct()
            .order_by("-ORDER_id")[:8]
    )

    trend_labels = []
    revenue_trend = []
    refund_trend = []
    returns_count_trend = []

    for oid in reversed(last_orders):
        trend_labels.append(f"#{oid}")
        order_items = items.filter(ORDER_id=oid)

        rev = 0.0
        returned_count = 0

        for it in order_items:
            try:
                val = float(it.price) * int(it.quantity)
                rev += val

                # count this item if it's been returned
                item_status = (it.status or "").lower()
                if "return" in item_status or "refund" in item_status:
                    returned_count += 1

            except Exception:
                pass

        revenue_trend.append(round(rev, 2))
        returns_count_trend.append(returned_count)

    # use the count-based trend for the chart
    refund_trend = returns_count_trend
    # ── Store health ──
    total_items = items.count()
    returned_items = items.filter(status__in=["Returned","Pickuped & Refunded"]).count()
    return_rate = (returned_items / total_items * 100) if total_items else 0

    delivered_items = items.filter(
        ORDER__status__iexact="Delivered"
    ).count()
    fulfillment = (delivered_items / total_items * 100) if total_items else 0

    shipped_items = items.filter(
        ORDER__status__iexact="Shipped"
    ).count()
    on_time = (shipped_items / total_items * 100) if total_items else 0

    fraud_flagged = items.filter(
        return_reason__isnull=False
    ).exclude(return_reason="").count()
    fraud_rate = (fraud_flagged / total_items * 100) if total_items else 0

    context = {
        "name": seller.name,
        "total_products": total_products,
        "total_orders": total_orders,
        "total_sales": round(total_sales, 0),
        "pending_returns": pending_returns,
        "recent_orders": recent_orders,
        "pending_return_list": pending_return_list,
        "trend_labels": trend_labels,
        "revenue_trend": revenue_trend,
        "refund_trend": refund_trend,
        "fulfillment": round(fulfillment, 1),
        "on_time": round(on_time, 1),
        "return_rate": round(return_rate, 1),
        "fraud_rate": round(fraud_rate, 1),
    }

    return render(request, 'seller/seller_dashboard.html', context)

@never_cache
@login_required(login_url='/myapp/login')

def seller_viewprofile(request):
    seller_id = request.session.get('sid')
    if not seller_id:
        return redirect('/myapp/login/')

    seller = Seller.objects.get(id=seller_id)

    # ── Products listed by this seller ──
    products_count = Product.objects.filter(SELLER=seller).count()

    # ── Distinct orders containing this seller's products ──
    items = Ordersub.objects.filter(PRODUCT__SELLER=seller)
    orders_count = items.values("ORDER").distinct().count()

    # ── Returns count (items with return status) ──
    returns_count = items.filter(status__in=["Returned","Pickuped & Refunded"]).count()

    # ── Average rating (across reviews of this seller's products) ──
    reviews = Review.objects.filter(
        ORDERSUB_PRODUCT__PRODUCT__SELLER=seller
    )

    total_reviews = reviews.count()
    if total_reviews > 0:
        total_rating = 0.0
        for r in reviews:
            try:
                total_rating += float(r.rating)
            except Exception:
                pass
        rating = round(total_rating / total_reviews, 1)
    else:
        rating = "—"

    context = {
        "seller": seller,
        "products_count": products_count,
        "orders_count": orders_count,
        "returns_count": returns_count,
        "rating": rating,
        "total_reviews": total_reviews,
    }

    return render(request, 'seller/view_profile.html', context)


@never_cache
@login_required(login_url='/myapp/login')
def seller_profileupdate(request):
    name = request.POST['name']
    phone = request.POST['phone']
    place = request.POST['place']
    post = request.POST['post']
    pin = request.POST['pin']
    seller=Seller.objects.get(id=request.session['sid'])
    seller.name = name
    seller.phone = phone
    seller.place = place
    seller.post = post
    seller.pin = pin
    seller.save()
    messages.success(request,"Profile Updates Successfully!!!")
    return redirect('/myapp/seller_viewprofile')

@never_cache
@login_required(login_url='/myapp/login')
def seller_changepassword(request):
    return render(request,'seller/change_password.html')

@never_cache
@login_required(login_url='/myapp/login')
def seller_changepasswordpost(request):
    current_password = request.POST['currentpassword']
    new_password = request.POST['newpassword']
    confirm_password = request.POST['confirmpassword']

    data = check_password(current_password, request.user.password)
    if data:
        if new_password == confirm_password:
            udata = request.user
            udata.set_password(new_password)
            udata.save()
            messages.success(request, "Password Changed successfully!!!Login with new Credentials")
            return redirect('/myapp/login')
        else:
            messages.error(request, "Password Mismatch")
            return redirect('/myapp/seller_changepassword')
    messages.error(request, "Incorrect Password!!")
    return redirect('/myapp/seller_changepassword')

@never_cache
@login_required(login_url='/myapp/login')
def seller_viewproducts(request):
    data=Product.objects.filter(SELLER_id=request.session['sid']).order_by('-id')
    return render(request,'seller/view_products.html',{"products":data})

@never_cache
@login_required(login_url='/myapp/login')
def seller_addproduct(request):
    return render(request,'seller/add_product.html')

@never_cache
@login_required(login_url='/myapp/login')
def seller_addproductpost(request):
    name=request.POST['name']
    description=request.POST['description']
    price=request.POST['price']
    stock=request.POST['stock']
    image=request.FILES['image']
    fs=FileSystemStorage()
    image=fs.url(fs.save(image.name,image))
    # seller=Seller.objects.get(USER_id=request.session['sid'])
    obj=Product()
    obj.name=name
    obj.description=description
    obj.price=price
    obj.stock=stock
    obj.image=image
    obj.status='Active'
    obj.SELLER_id=request.session['sid']
    obj.save()
    messages.success(request,"Product added Successfully!!")
    return redirect('/myapp/seller_viewproducts')

@never_cache
@login_required(login_url='/myapp/login')
def seller_editproduct(request,id):
    product=Product.objects.get(id=id)
    return render(request,'seller/edit_product.html',{'product':product})

@never_cache
@login_required(login_url='/myapp/login')
def seller_editproductpost(request):
    product_id = request.POST['id']
    name = request.POST['name']
    description = request.POST['description']
    price = request.POST['price']
    stock = request.POST['stock']
    status = request.POST['status']
    duplicate = (
        Product.objects
            .filter(name__iexact=name, description=description)
            .exclude(id=product_id)
            .exists()
    )
    if duplicate:
        messages.error(request,"Product already exists!!")
        return redirect("/myapp/seller_viewproducts")

    seller = Seller.objects.get(id=request.session['sid'])
    obj = Product.objects.get(id=product_id)
    obj.name = name
    obj.description = description
    obj.price = price
    obj.stock = stock
    if 'image' in request.FILES:
        image = request.FILES['image']
        fs = FileSystemStorage()
        image = fs.url(fs.save(image.name, image))
        obj.image = image
    obj.status = status
    obj.SELLER = seller
    obj.save()
    messages.success(request,"Product Edited Successfully")
    return redirect('/myapp/seller_viewproducts')

@never_cache
@login_required(login_url='/myapp/login')
def seller_deleteproduct(request,id):
    product=Product.objects.get(id=id)
    product.delete()
    messages.success(request,"Product deleted successfully!!")
    return redirect('/myapp/seller_viewproducts')


@never_cache
@login_required(login_url='/myapp/login')
def seller_vieworders(request):
    seller=Seller.objects.get(id=request.session['sid'])
    data=Ordersub.objects.filter(PRODUCT__SELLER=seller.id).values_list('ORDER_id', flat=True).distinct()
    orders = Order.objects.filter(id__in=data).order_by('-id')
    return render(request,'seller/view_orders.html',{"orders":orders})

@never_cache
@login_required(login_url='/myapp/login')
def seller_vieworderitems(request,id):
    seller = Seller.objects.get(id=request.session['sid'])
    items = Ordersub.objects.filter(
        ORDER_id=id,
        PRODUCT__SELLER=seller.id
    )
    return render(request, 'seller/order_items.html', {"items":items})

@never_cache
@login_required(login_url='/myapp/login')
def seller_updateorderstatus(request):
    status=request.POST['status']
    print(status)
    order_id= request.POST['order_id']
    order=Order.objects.get(id=order_id)
    order.status=status
    if (order.payment_method == "offline" and order.payment_status == "Pending"
        and status == "Delivered"):
        order.payment_status = "Paid"

    order.save()
    messages.success(request,"Status Updated!!")
    return redirect('/myapp/seller_vieworders')

@never_cache
@login_required(login_url='/myapp/login')
def seller_viewreviews(request,id):
    review=Review.objects.filter(ORDERSUB_PRODUCT_id=id).order_by('-id')
    product=Product.objects.get(id=id)
    return render(request,'seller/view_reviews.html',{"reviews":review,"product":product})

@never_cache
@login_required(login_url='/myapp/login')
def seller_viewreturnrequest(request):
    items = Ordersub.objects.filter(
        PRODUCT__SELLER_id=request.session['sid'],
        status__in=['Returned', 'Pickuped & Refunded'],
    ).order_by('-id')

    to_update = []

    for item in items:
        # If already predicted → reuse stored value, don't recompute
        if item.return_seller_risk:
            parts = item.return_seller_risk.split()
            item.is_fraud_pred = (parts[0].lower() == "fraud")
            item.fraud_confidence = float(parts[1].rstrip("%")) if len(parts) > 1 else 0.0
            continue

        # Predict
        try:
            is_fraud, confidence = predict_fraud(item)
        except Exception:
            is_fraud, confidence = False, 0.0

        item.is_fraud_pred = is_fraud
        item.fraud_confidence = round(confidence * 100, 1)

        label = "Fraud" if is_fraud else "Safe"
        item.return_seller_risk = f"{label} {item.fraud_confidence}%"

        # ✅ NEW — set the label automatically
        item.is_fraud = is_fraud

        to_update.append(item)

    if to_update:
        # ✅ now save both fields
        Ordersub.objects.bulk_update(to_update, ["return_seller_risk", "is_fraud"])

    return render(request, 'seller/seller_viewreturnrequests.html', {'items': items})

@never_cache
@login_required(login_url='/myapp/login')
def seller_updatereturnrequeststatus(request,id):
    item=Ordersub.objects.get(id=id)
    item.status="Pickuped & Refunded"
    item.save()
    return redirect('/myapp/seller_viewreturnrequest')

@never_cache
@login_required(login_url='/myapp/login')


def seller_viewsalesreports(request):
    # ── Session key ──
    seller_id = request.session.get('sid')
    if not seller_id:
        return render(request, 'seller/view_salesreport.html', {
            "sales": [], "search_query": "", "start_date": "", "end_date": "",
            "status_filter": "",                                            # 🆕
            "total_revenue": "0", "items_sold": 0, "total_orders": 0,
            "paid_orders": 0, "pending_orders": 0, "pending_amount": "0",
            "returns_count": 0, "fraud_count": 0,
        })

    q             = request.GET.get('q', '').strip()
    start         = request.GET.get('start', '').strip()
    end           = request.GET.get('end', '').strip()
    status_filter = request.GET.get('status', '').strip()               # 🆕

    items = (
        Ordersub.objects
        .filter(PRODUCT__SELLER_id=seller_id)
        .select_related('PRODUCT', 'ORDER', 'ORDER__DELIVERY_ADDRESS',
                        'ORDER__DELIVERY_ADDRESS__CUSTOMER')
    )

    if q:
        items = items.filter(
            Q(PRODUCT__name__icontains=q) |
            Q(ORDER__id__icontains=q) |
            Q(ORDER__DELIVERY_ADDRESS__CUSTOMER__name__icontains=q)
        )

    if start:
        items = items.filter(ORDER__date__gte=start)
    if end:
        items = items.filter(ORDER__date__lte=end)

    # 🆕 status filter — treat NULL/empty as Pending
    if status_filter:
        if status_filter.lower() == "pending":
            items = items.filter(
                Q(status__iexact="Pending") | Q(status__isnull=True) | Q(status="")
            )
        else:
            items = items.filter(status__iexact=status_filter)

    items = items.order_by('-ORDER__date')

    # ── Build row data ──
    sales = []
    for it in items:
        customer_name = (
            it.ORDER.DELIVERY_ADDRESS.CUSTOMER.name
            if it.ORDER and it.ORDER.DELIVERY_ADDRESS
               and it.ORDER.DELIVERY_ADDRESS.CUSTOMER
            else "Customer"
        )
        sales.append({
            "order_id":       it.ORDER.id if it.ORDER else "",
            "customer_name":  customer_name,
            "product_name":   it.PRODUCT.name if it.PRODUCT else "",
            "seller_name":    "",
            "quantity":       it.quantity,
            "amount":         it.price,
            "payment_status": it.ORDER.payment_status if it.ORDER else "",
            "status":         it.status or "",
            "date":           it.ORDER.date if it.ORDER else "",
            "is_fraud":       bool(it.is_fraud),                            # 🆕
        })

    EXCLUDED_STATUSES = {"cancelled", "returned"}

    total_revenue  = 0.0
    items_sold     = 0
    pending_amount = 0.0
    returns_count  = 0
    fraud_count    = 0
    paid_order_ids    = set()
    pending_order_ids = set()
    all_order_ids     = set()

    for s in sales:
        try:
            qty = int(str(s["quantity"] or "0").strip() or 0)
        except (ValueError, TypeError):
            qty = 0
        try:
            price = float(str(s["amount"] or "0").strip() or 0)
        except (ValueError, TypeError):
            price = 0.0

        line_total = price * qty
        pay = str(s["payment_status"] or "").strip().lower()
        st  = str(s["status"] or "").strip().lower()

        all_order_ids.add(s["order_id"])

        if pay == "paid" and st not in EXCLUDED_STATUSES:
            total_revenue += line_total
            paid_order_ids.add(s["order_id"])

        if st not in EXCLUDED_STATUSES:
            items_sold += qty

        if pay == "pending" and st not in EXCLUDED_STATUSES:
            pending_amount += line_total
            pending_order_ids.add(s["order_id"])

        if st == "returned":
            returns_count += 1

        if s.get("is_fraud"):
            fraud_count += 1

    context = {
        "sales":          sales,
        "search_query":   q,
        "start_date":     start,
        "end_date":       end,
        "status_filter":  status_filter,                                    # 🆕
        "total_revenue":  f"{total_revenue:,.0f}",
        "items_sold":     items_sold,
        "total_orders":   len(all_order_ids),
        "paid_orders":    len(paid_order_ids),
        "pending_orders": len(pending_order_ids),
        "pending_amount": f"{pending_amount:,.0f}",
        "returns_count":  returns_count,
        "fraud_count":    fraud_count,
    }
    return render(request, 'seller/view_salesreport.html', context)


def seller_downloadsalesreport(request):
    seller_id = request.session.get('sid')
    if not seller_id:
        return HttpResponse("Unauthorized", status=401)

    q             = request.GET.get('q', '').strip()
    start         = request.GET.get('start', '').strip()
    end           = request.GET.get('end', '').strip()
    status_filter = request.GET.get('status', '').strip()               # 🆕

    items = (
        Ordersub.objects
        .filter(PRODUCT__SELLER_id=seller_id)
        .select_related('PRODUCT', 'ORDER', 'ORDER__DELIVERY_ADDRESS',
                        'ORDER__DELIVERY_ADDRESS__CUSTOMER')
    )

    if q:
        items = items.filter(
            Q(PRODUCT__name__icontains=q) |
            Q(ORDER__id__icontains=q) |
            Q(ORDER__DELIVERY_ADDRESS__CUSTOMER__name__icontains=q)
        )
    if start:
        items = items.filter(ORDER__date__gte=start)
    if end:
        items = items.filter(ORDER__date__lte=end)

    # 🆕 status filter
    if status_filter:
        if status_filter.lower() == "pending":
            items = items.filter(
                Q(status__iexact="Pending") | Q(status__isnull=True) | Q(status="")
            )
        else:
            items = items.filter(status__iexact=status_filter)

    items = items.order_by('-ORDER__date')

    response = HttpResponse(content_type='text/csv')
    filename = f"sales_report_{start or 'all'}_{end or 'all'}.csv"
    response['Content-Disposition'] = f'attachment; filename="{filename}"'

    writer = csv.writer(response)
    writer.writerow([
        "Sl No", "Order ID", "Customer", "Product",
        "Quantity", "Price", "Total", "Payment Status",
        "Order Status", "Date",
    ])

    for idx, it in enumerate(items, start=1):
        customer = (
            it.ORDER.DELIVERY_ADDRESS.CUSTOMER.name
            if it.ORDER and it.ORDER.DELIVERY_ADDRESS
               and it.ORDER.DELIVERY_ADDRESS.CUSTOMER
            else "Customer"
        )
        try:
            price = float(it.price or 0)
        except (ValueError, TypeError):
            price = 0.0
        try:
            qty = int(it.quantity or 0)
        except (ValueError, TypeError):
            qty = 0

        writer.writerow([
            idx,
            it.ORDER.id if it.ORDER else "",
            customer,
            it.PRODUCT.name if it.PRODUCT else "",
            qty,
            f"{price:.2f}",
            f"{price * qty:.2f}",
            it.ORDER.payment_status if it.ORDER else "",
            it.status or "",
            it.ORDER.date if it.ORDER else "",
        ])

    return response


# ── 🆕 PDF download ──
def seller_downloadsalespdf(request):
    from io import BytesIO
    from django.utils import timezone
    from reportlab.lib.pagesizes import A4, landscape
    from reportlab.lib import colors
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import mm
    from reportlab.platypus import (
        SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    )

    seller_id = request.session.get('sid')
    if not seller_id:
        return HttpResponse("Unauthorized", status=401)

    q             = request.GET.get('q', '').strip()
    start         = request.GET.get('start', '').strip()
    end           = request.GET.get('end', '').strip()
    status_filter = request.GET.get('status', '').strip()

    items = (
        Ordersub.objects
        .filter(PRODUCT__SELLER_id=seller_id)
        .select_related('PRODUCT', 'ORDER', 'ORDER__DELIVERY_ADDRESS',
                        'ORDER__DELIVERY_ADDRESS__CUSTOMER')
    )

    if q:
        items = items.filter(
            Q(PRODUCT__name__icontains=q) |
            Q(ORDER__id__icontains=q) |
            Q(ORDER__DELIVERY_ADDRESS__CUSTOMER__name__icontains=q)
        )
    if start:
        items = items.filter(ORDER__date__gte=start)
    if end:
        items = items.filter(ORDER__date__lte=end)
    if status_filter:
        if status_filter.lower() == "pending":
            items = items.filter(
                Q(status__iexact="Pending") | Q(status__isnull=True) | Q(status="")
            )
        else:
            items = items.filter(status__iexact=status_filter)

    items = items.order_by('-ORDER__date')

    # ── Build PDF ──
    buf = BytesIO()
    doc = SimpleDocTemplate(
        buf,
        pagesize=landscape(A4),
        leftMargin=15 * mm, rightMargin=15 * mm,
        topMargin=15 * mm,  bottomMargin=15 * mm,
    )

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "Title", parent=styles["Heading1"],
        fontSize=18, textColor=colors.HexColor("#1F2937"), spaceAfter=4,
    )
    subtitle_style = ParagraphStyle(
        "Sub", parent=styles["Normal"],
        fontSize=10, textColor=colors.HexColor("#6B7280"), spaceAfter=14,
    )

    filters = []
    if q:             filters.append(f"Search: {q}")
    if status_filter: filters.append(f"Status: {status_filter}")
    if start:         filters.append(f"From: {start}")
    if end:           filters.append(f"To: {end}")
    filter_line = " • ".join(filters) if filters else "All records"
    subtitle = f"Generated on {timezone.now().strftime('%d %b %Y, %H:%M')} — {filter_line}"

    story = [
        Paragraph("Sales Report", title_style),
        Paragraph(subtitle, subtitle_style),
        Spacer(1, 4 * mm),
    ]

    header = ["#", "Order", "Customer", "Product", "Qty", "Amount", "Payment", "Status", "Date"]
    data = [header]

    total_revenue = 0.0
    total_items = 0

    for idx, it in enumerate(items, start=1):
        customer = (
            it.ORDER.DELIVERY_ADDRESS.CUSTOMER.name
            if it.ORDER and it.ORDER.DELIVERY_ADDRESS and it.ORDER.DELIVERY_ADDRESS.CUSTOMER
            else "Customer"
        )
        try:    price = float(it.price or 0)
        except (ValueError, TypeError): price = 0.0
        try:    qty = int(it.quantity or 0)
        except (ValueError, TypeError): qty = 0

        line_total = price * qty
        pay_status = (it.ORDER.payment_status if it.ORDER else "") or ""
        item_status = it.status or "Pending"

        if pay_status.lower() == "paid" and item_status.lower() not in ("cancelled", "returned"):
            total_revenue += line_total
        if item_status.lower() not in ("cancelled", "returned"):
            total_items += qty

        data.append([
            str(idx),
            f"#{it.ORDER.id}" if it.ORDER else "—",
            customer[:20],
            (it.PRODUCT.name[:30] if it.PRODUCT else "—"),
            str(qty),
            f"Rs.{line_total:.0f}",
            pay_status or "—",
            item_status,
            it.ORDER.date if it.ORDER else "—",
        ])

    data.append(["", "", "", "TOTAL", str(total_items),
                 f"Rs.{total_revenue:.0f}", "", "", ""])

    table = Table(data, repeatRows=1)
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#FACC15")),
        ("TEXTCOLOR",  (0, 0), (-1, 0), colors.HexColor("#1F2937")),
        ("FONTNAME",   (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE",   (0, 0), (-1, 0), 8.5),
        ("ALIGN",      (0, 0), (-1, 0), "LEFT"),
        ("BOTTOMPADDING", (0, 0), (-1, 0), 6),

        ("FONTNAME",   (0, 1), (-1, -2), "Helvetica"),
        ("FONTSIZE",   (0, 1), (-1, -1), 8),
        ("TEXTCOLOR",  (0, 1), (-1, -1), colors.HexColor("#1F2937")),
        ("VALIGN",     (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 1), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 1), (-1, -1), 4),

        ("ROWBACKGROUNDS", (0, 1), (-1, -2),
            [colors.white, colors.HexColor("#F9FAFB")]),

        ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#ECFDF5")),
        ("FONTNAME",   (0, -1), (-1, -1), "Helvetica-Bold"),
        ("TEXTCOLOR",  (0, -1), (-1, -1), colors.HexColor("#065F46")),

        ("GRID", (0, 0), (-1, -1), 0.3, colors.HexColor("#E5E7EB")),
    ]))

    story.append(table)
    story.append(Spacer(1, 6 * mm))
    story.append(Paragraph(
        f"Total revenue: Rs.{total_revenue:.0f} &nbsp;&nbsp;|&nbsp;&nbsp; "
        f"Total items: {total_items} &nbsp;&nbsp;|&nbsp;&nbsp; "
        f"Total records: {len(data) - 2}",
        ParagraphStyle("Footer", parent=styles["Normal"], fontSize=9,
                       textColor=colors.HexColor("#374151")),
    ))

    doc.build(story)
    pdf = buf.getvalue()
    buf.close()

    response = HttpResponse(pdf, content_type="application/pdf")
    response["Content-Disposition"] = (
        f'attachment; filename="sales_report_{start or "all"}_{end or "all"}.pdf"'
    )
    return response

# --------------ML-----------
from django.shortcuts import get_object_or_404
from .ml_utils import predict_fraud

def check_fraud(request, ordersub_id):
    """
    Seller clicks 'Check Fraud' → returns JSON with prediction.
    """
    ordersub = get_object_or_404(Ordersub, id=ordersub_id)

    try:
        is_fraud, confidence = predict_fraud(ordersub)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

    return JsonResponse({
        "ordersub_id": ordersub.id,
        "is_fraud": is_fraud,
        "confidence": confidence,
        "label": "⚠️ Likely Fraud" if is_fraud else "✅ Likely Safe",
    })




# ---------customer---------

def user_register(request):
    name=request.POST['name']
    email=request.POST['email']
    phone=request.POST['phone']
    house=request.POST['house']
    street=request.POST['street']
    place=request.POST['place']
    post=request.POST['post']
    pin=request.POST['pin']
    password=request.POST['password1']
    password1=request.POST['password2']

    if password!=password1:
        return JsonResponse({"status":"error"})

    if User.objects.filter(username=email).exists():
        return JsonResponse({'status':"error"})

    obj=User()
    obj.username=email
    obj.password=make_password(password1)
    obj.save()

    obj1=Group.objects.filter(name="customer")
    if obj1.exists():
        obj.groups.add(Group.objects.get(name="customer"))
    else:
        obj2=Group()
        obj2.name="customer"
        obj2.save()
        obj.groups.add(Group.objects.get(name="customer"))

    obj3=Customer()
    obj3.name=name
    obj3.email=email
    obj3.phone=phone
    obj3.USER=obj
    obj3.save()

    obj4=Deliveryaddress()
    obj4.housename=house
    obj4.street=street
    obj4.place=place
    obj4.post=post
    obj4.pin=pin
    obj4.CUSTOMER=obj3
    obj4.save()
    return JsonResponse({"status":"success"})

def user_login(request):
    username=request.POST['username']
    password=request.POST['password']
    data=authenticate(request,username=username,password=password)
    if data:
        login(request,data)
        if data.groups.filter(name="customer").exists():
            if Customer.objects.get(USER=request.user.id).status == "registered":
                cid = Customer.objects.get(USER=request.user.id).id
                request.session['cid'] = cid
                customer = Customer.objects.get(USER=data)
                return JsonResponse({"status":"success","user": customer.id,"name":customer.name})
            elif Customer.objects.get(USER=request.user.id).status == "blocked":
                return JsonResponse({"status": "blocked"})
            else:
                return JsonResponse({"status":"error"})
        else:
            status = "not found"
            return JsonResponse({"status": status})

    else:
        status="not found"
        return JsonResponse({"status":status})

def user_logout(request):
    logout(request)
    return JsonResponse({"status":"logout"})

def flutter_user(request):
    uid=request.POST['user']
    user=Customer.objects.get(id=uid)
    address=Deliveryaddress.objects.get(CUSTOMER=user.id)
    # print(user.name)
    name=user.name
    email=user.email
    phone=user.phone
    house=address.housename
    street=address.street
    place=address.place
    post=address.post
    pin=address.pin
    return JsonResponse({
        "status":"success",
        "name":name,
        "email":email,
        "phone":phone,
        "house":house,
        "street":street,
        "place":place,
        "post":post,
        "pin":pin})

def user_profile(request):
    user=request.POST['user_id']
    # print(user)
    user=Customer.objects.get(id=user)
    address=Deliveryaddress.objects.get(CUSTOMER=user.id)
    # print(profile)
    name = request.POST['name']
    email = request.POST['email']
    phone = request.POST['phone']
    house = request.POST['house']
    street = request.POST['street']
    place = request.POST['place']
    post = request.POST['post']
    pin = request.POST['pin']

    if (user.name == name and user.email == email and user.phone == phone and
                address.housename == house and address.street == street and address.place == place and address.post == post and
                address.pin == pin):
        return JsonResponse({"status": "no changes"})
    else:
        user.name = name
        user.email = email
        user.phone = phone
        user.save()

        address.housename = house
        address.street = street
        address.place = place
        address.post = post
        address.pin = pin
        address.save()

        data={
            "name":user.name,
            "email":user.email,
            "phone":user.phone,
            "house":address.housename,
            "street":address.street,
            "place":address.place,
            "post":address.post,
            "pin":address.pin,
        }

        return JsonResponse({'status': "success","data":data})

def user_change_password(request):
    newpassword = request.POST['newpassword']
    current_pwd = request.POST.get("currentpassword")
    uid = request.POST['user']
    userdata = Customer.objects.get(id=uid)
    user = User.objects.get(id=userdata.USER_id)
    if not check_password(current_pwd, user.password):
        return JsonResponse({"status": "incorrect"})
    user.password = make_password(newpassword)
    user.save()
    return JsonResponse({'status': "success"})

def forgotemail(request):
    from django.core.mail import EmailMultiAlternatives
    from django.http import JsonResponse
    from django.contrib.auth.models import User
    from django.conf import settings
    from datetime import datetime
    import random
    import os
    email = request.POST['email']

    data = User.objects.filter(username=email)

    if data.exists():

        otp = str(random.randint(100000,999999))

        # store in session instead of returning to client
        request.session['otp'] = otp
        request.session['email'] = email

        try:

            project_name = os.path.basename(settings.BASE_DIR)

            subject = "🔑 Forgot Password"

            html = f"""
            <!DOCTYPE html>
            <html>
            <body style="font-family:Arial,sans-serif">

                <div style="
                background:#2c7be5;
                padding:20px;
                text-align:center;
                color:white">

                    <h1>{project_name}</h1>

                </div>

                <div style="padding:25px">

                    <h2>Password Reset Request</h2>

                    <p>Hello,</p>

                    <p>Use the OTP below:</p>

                    <div style="
                    text-align:center;
                    font-size:30px;
                    font-weight:bold;
                    letter-spacing:8px;
                    color:#2c7be5;
                    border:1px dashed #ccc;
                    padding:15px">

                        {otp}

                    </div>

                    <p>Valid for 10 minutes</p>

                    <p>
                    Never share this OTP with anyone.
                    </p>

                    <hr>

                    <small>
                    © {datetime.now().year}
                    {project_name}
                    </small>

                </div>

            </body>
            </html>
            """

            email_message = EmailMultiAlternatives(
                subject=subject,
                body=f"Your OTP: {otp}",
                to=[email]
            )

            email_message.attach_alternative(
                html,
                "text/html"
            )

            email_message.send()

            return JsonResponse({
                'status':'ok',
                "otpp":otp
            })

        except Exception as e:

            print(e)

            return JsonResponse({
                'status':'mail failed'
            })

    return JsonResponse({
        'status':'not found'
    })

def forgotpass(request):
    email = request.POST['email']
    npass = request.POST['password']
    cpass = request.POST['confirmpassword']
    print(email,npass,cpass)
    if npass == cpass:
        User.objects.filter(username=email).update(password = make_password(npass))
        return JsonResponse({'status': 'ok'})
    return JsonResponse({'status':'invalid'})

def user_viewproducts(request):
    products=Product.objects.all()
    ar=[]
    for i in products:
        stats = Review.objects.filter(
            ORDERSUB_PRODUCT_id=i.id
        ).aggregate(
            avg_rating=Avg("rating"),
            total=Count("id"),
        )

        avg = stats["avg_rating"]
        total = stats["total"] or 0
        ar.append({
            "id":i.id,
            "name":i.name,
            "description":i.description,
            "image":i.image,
            "price":i.price,
            "stock":i.stock,
            "seller":i.SELLER.name,
            "rating": round(float(avg), 1) if avg is not None else 0.0,
            "reviews_count": total,
        })
    return JsonResponse({"status":"success","data":ar})

def user_addtocart(request):
    user_id = request.POST['user_id']
    product_id = request.POST['product_id']
    # quantity = request.POST['quantity']
    customer=Customer.objects.get(id=user_id)
    product=Product.objects.get(id=product_id)
    cart=Cart.objects.filter(CUSTOMER_id=user_id,PRODUCT_id=product_id).first()
    if cart:
        cart.quantity += 1
        cart.save()
        return JsonResponse({"status": "success"})
    else:
        obj=Cart()
        obj.quantity=1
        obj.CUSTOMER=customer
        obj.PRODUCT=product
        obj.save()
    return JsonResponse({"status":"success"})

def user_viewcart(request):
    user_id = request.POST['user_id']
    cart=Cart.objects.filter(CUSTOMER_id=user_id)
    ar=[]
    for i in cart:
        ar.append({
            "id":i.id,
            "product_id":i.PRODUCT.id,
            "name":i.PRODUCT.name,
            "description":i.PRODUCT.description,
            "price":i.PRODUCT.price,
            "quantity":i.quantity,
            "image":i.PRODUCT.image,
            "seller": i.PRODUCT.SELLER.name,
            "stock": str(i.PRODUCT.stock if i.PRODUCT.stock is not None else 0),
        })
    return JsonResponse({"status": "success","data":ar})

def user_updatecart(request):
    cart_id=request.POST['cart_id']
    type=request.POST['type']
    cart=Cart.objects.get(id=cart_id)

    product = cart.PRODUCT  # or cart.product

    if type == "-":
        if cart.quantity > 1:
            cart.quantity -= 1
            cart.save()
        return JsonResponse({"status": "success"})

    elif type == "+":
        # ── STOCK CHECK ──
        if cart.quantity + 1 > product.stock:
            return JsonResponse({
                "status": "out_of_stock",
                "message": f"Only {product.stock} left in stock",
                "available": product.stock,
            })

        cart.quantity += 1
        cart.save()
        return JsonResponse({"status": "success"})
    return JsonResponse({"status":"success"})

def user_removecartitem(request):
    id = request.POST['cart_id']
    cart=Cart.objects.get(id=id)
    cart.delete()
    return JsonResponse({"status":"success"})

def user_buynow(request):
    user_id = request.POST['user_id']
    product_id = request.POST['product_id']
    quantity = int(request.POST['quantity'])
    price = request.POST['price']
    mode = request.POST['mode']
    amount = request.POST['amount']
    product=Product.objects.get(id=product_id)
    delivery_address=Deliveryaddress.objects.get(CUSTOMER_id=user_id)
    obj=Order()
    obj.payment_method=mode
    if obj.payment_method == "online":
        obj.payment_status="Paid"
    else:
        obj.payment_status="Pending"
    obj.total_amount=amount
    obj.date=datetime.date.today()
    obj.status="Pending"
    obj.DELIVERY_ADDRESS=delivery_address
    obj.save()

    obj1=Ordersub()
    obj1.PRODUCT=product
    obj1.ORDER=obj
    obj1.quantity=quantity
    obj1.price=price
    obj1.save()

    product.stock = (product.stock)- quantity
    product.save()

    cart=Cart.objects.filter(PRODUCT_id=product_id,CUSTOMER_id=user_id)
    cart.delete()

    return JsonResponse({"status": "success"})

def user_placeorder(request):
    user_id = request.POST['user']
    mode = request.POST['mode']
    amount = request.POST['amount']

    customer = Customer.objects.get(id=user_id)

    cart_items = Cart.objects.filter(CUSTOMER_id=customer.id)

    delivery_address = Deliveryaddress.objects.get(CUSTOMER_id=customer.id)

    # Pre-validate stock
    for c in cart_items:
        if c.PRODUCT.stock < int(c.quantity):
            return JsonResponse({
                "status": "failed",
                "message": f"Not enough stock for {c.PRODUCT.name}"
            })

    # Group by seller
    seller_ids = set()
    for c in cart_items:
        seller_ids.add(c.PRODUCT.SELLER_id)

    for seller_id in seller_ids:
        seller_items = cart_items.filter(PRODUCT__SELLER_id=seller_id)

        seller_total = 0
        for c in seller_items:
            seller_total += int(float(c.PRODUCT.price)) * int(c.quantity)

        order = Order()
        order.date = datetime.date.today()
        order.payment_method = mode
        if order.payment_method == "online":
            order.payment_status = "Paid"
        else:
            order.payment_status = "Pending"
        order.total_amount = str(seller_total)
        order.status = "Pending"
        order.DELIVERY_ADDRESS = delivery_address
        order.save()

        for c in seller_items:
            product = c.PRODUCT

            product.stock -= int(c.quantity)
            product.save()

            sub = Ordersub()
            sub.ORDER_id = order.id
            sub.PRODUCT_id = product.id
            sub.quantity = str(c.quantity)
            sub.price = product.price
            sub.save()

        seller_items.delete()

    return JsonResponse({"status": "success"})

# def user_vieworders(request):
#     user_id = request.POST['user_id']
#     orders=Order.objects.filter(DELIVERY_ADDRESS__CUSTOMER=user_id)
#     ar=[]
#     for i in orders:
#         ar.append({
#             "id":i.id,
#             "total_amount":i.total_amount,
#             "status":i.status,
#             "payment_status":i.payment_status,
#             "payment_method":i.payment_method,
#             "date":i.date,
#         })
#     return JsonResponse({"status": "success","data":ar})

# def user_vieworderitems(request):
#     order_id = request.POST['order_id']
#     orderitems = Ordersub.objects.filter(ORDER_id=order_id)
#     ar = []
#     for i in orderitems:
#         ar.append({
#             "id": i.id,
#             "image": i.PRODUCT.image,
#             "name": i.PRODUCT.name,
#             "description": i.PRODUCT.description,
#             "price": i.price,
#             "quantity": i.quantity,
#         })
#     return JsonResponse({"status": "success", "data": ar})

def user_sendfeedback(request):
    user_id = request.POST['user']
    feedback = request.POST['feedback']
    obj=Feedback()
    obj.CUSTOMER_id=user_id
    obj.feedback=feedback
    obj.date=datetime.date.today()
    obj.save()
    return JsonResponse({"status":"success"})

def user_viewallorderitems(request):

    user_id = request.POST['user_id']
    orderitems = Ordersub.objects.filter(ORDER__DELIVERY_ADDRESS__CUSTOMER=user_id).order_by('-id')
    ar = []
    for i in orderitems:

        ar.append({
            "id": i.id,
            "order_id": i.ORDER.id,
            "product_id":i.PRODUCT.id,
            "image": str(i.PRODUCT.image),
            "name": i.PRODUCT.name,
            "description": i.PRODUCT.description,
            "price": i.price,
            "quantity": i.quantity,
            "payment_method": i.ORDER.payment_method,
            "payment_status": i.ORDER.payment_status,
            "status": i.status,
            "order_status": i.ORDER.status,
            "date": i.ORDER.date,
            "seller_name" : i.PRODUCT.SELLER.name,
        })

    return JsonResponse({"status": "success", "data": ar})

def user_cancelorderitem(request):
    item_id = request.POST['item_id']
    item = Ordersub.objects.get(id=item_id)

    item.status = "Cancelled"
    item.save()

    product = item.PRODUCT
    product.stock += int(item.quantity)
    product.save()

    # --- Sync the parent Order status ---
    order = item.ORDER
    items = Ordersub.objects.filter(ORDER=order)

    if all(i.status == "Cancelled" for i in items):
        order.status = "Cancelled"
        order.save()


    return JsonResponse({
        "status": "success",
        "item_status": item.status,
        "order_status": order.status,
    })

def user_sendreview(request):
    user_id = request.POST['user']
    # product_id = request.POST['product_id']
    ordersub_id = request.POST['ordersub_id']
    rating = request.POST['rating']
    review = request.POST['review']
    if Review.objects.filter(CUSTOMER_id=user_id,ORDERSUB_PRODUCT_id=ordersub_id).exists():
        return JsonResponse({"status": "Already sent"})
    obj = Review()
    obj.CUSTOMER_id=user_id
    obj.ORDERSUB_PRODUCT_id=ordersub_id
    obj.rating = rating
    obj.review = review
    obj.date=datetime.date.today()
    obj.save()
    return JsonResponse({"status": "success"})

def user_viewproductreviews(request):
    product_id = request.POST.get('product_id')

    reviews = Review.objects.filter(ORDERSUB_PRODUCT__PRODUCT_id=product_id
                                    ).select_related('CUSTOMER').order_by('-id')

    data = []
    for r in reviews:
        data.append({
            "customer_name": r.CUSTOMER.name,
            "rating": r.rating,
            "review": r.review,
            "date": r.date,
        })

    return JsonResponse({"status": "success", "data": data})

from django.utils import timezone
def user_returnproduct(request):
    user_id=request.POST['user_id']
    orderitem_id=request.POST['orderitem_id']
    reason=request.POST['reason']
    description=request.POST['description']
    item = Ordersub.objects.get(id=orderitem_id)
    file=request.FILES['file']
    fs=FileSystemStorage()
    file=fs.url(fs.save(file.name,file))

    try:
        order_dt = datetime.datetime.strptime(str(item.ORDER.date).strip(), "%Y-%m-%d")
        order_dt = timezone.make_aware(order_dt)
    except (ValueError, TypeError):
        return JsonResponse({
            "status": "error",
            "message": "Order date is invalid",
        })

    RETURN_WINDOW_DAYS = 20

    expiry = order_dt + datetime.timedelta(days=RETURN_WINDOW_DAYS)
    if timezone.now() > expiry:
        return JsonResponse({
            "status": "error",
            "message": f"Return window of {RETURN_WINDOW_DAYS} days has expired",
        })

    if description:
        combined_reason = f"{reason}. {description}"
    else:
        combined_reason = reason

    item.status = "Returned"
    item.return_reason = combined_reason
    item.return_image = file
    item.return_date = datetime.date.today()
    try:
        item.save()
        is_fraud, confidence = predict_fraud(item)
        item.is_fraud = is_fraud
        item.return_seller_risk = f"{'Fraud' if is_fraud else 'Safe'} {round(confidence*100,1)}%"
        item.save(update_fields=["is_fraud", "return_seller_risk"])
    except Exception as e:
        # don't crash the return submission if ML fails
        pass

    return JsonResponse({"status":"success"})

def user_viewreturns(request):
    user_id=request.POST['user_id']
    returns=Ordersub.objects.filter(ORDER__DELIVERY_ADDRESS__CUSTOMER_id=user_id,
                                    status__in=['Returned','Pickuped & Refunded']).order_by('-id')
    ar=[]
    for i in returns:
        ar.append({
            "id":i.id,
            "product_name":i.PRODUCT.name,
            "return_reason":i.return_reason,
            "return_image":i.return_image,
            "return_date":i.return_date,
            "status":i.status
        })

    return JsonResponse({"status":"success","data":ar})

def user_dashboard(request):
    products = Product.objects.all()
    order_items = Ordersub.objects.all()
    reviews = Review.objects.all()

    pdata = []
    for p in products:
        pdata.append({
            "id": p.id,
            "name": p.name,
            "description": p.description,
            "price": str(p.price),
            "stock": str(p.stock),
            "image": p.image,           # raw string from DB
            "seller": p.SELLER.name,
        })

    odata = []
    for o in order_items:
        odata.append({
            "id": o.id,
            "order_id": o.ORDER.id,
            "status": o.ORDER.status,
            "order_status": o.ORDER.status,
            "item_status": o.status or "",
            "quantity": str(o.quantity),
            "price": str(o.price),
            "total_amount": str(o.ORDER.total_amount),
            "payment_status": o.ORDER.payment_status,
            "payment_method": o.ORDER.payment_method,
            "date": o.ORDER.date,
            "customer_name": o.ORDER.DELIVERY_ADDRESS.CUSTOMER.name,
            "customer_id": o.ORDER.DELIVERY_ADDRESS.CUSTOMER.id,
        })

    rdata = []
    for r in reviews:
        rdata.append({
            "id": r.id,
            "rating": str(r.rating),
            "review": r.review,
            "date": r.date,
            "customer_name": r.CUSTOMER.name,
        })

    return JsonResponse({
        "status": "success",
        "products": pdata,
        "orders": odata,
        "reviews": rdata,
    })


