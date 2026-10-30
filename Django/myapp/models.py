from django.contrib.auth.models import User
from django.db import models

class Seller(models.Model):
    name=models.CharField(max_length=200)
    email=models.CharField(max_length=200)
    phone=models.CharField(max_length=200)
    place=models.CharField(max_length=200)
    post=models.CharField(max_length=200)
    pin=models.CharField(max_length=200)
    proof=models.CharField(max_length=200)
    status=models.CharField(max_length=200)
    USER=models.ForeignKey(User,on_delete=models.CASCADE)

class Customer(models.Model):
    name=models.CharField(max_length=200)
    email=models.CharField(max_length=200)
    phone=models.CharField(max_length=200)
    status=models.CharField(max_length=200,default="registered")
    USER=models.ForeignKey(User,on_delete=models.CASCADE)

class Product(models.Model):
    name=models.CharField(max_length=200)
    description=models.CharField(max_length=200)
    price=models.CharField(max_length=200)
    stock=models.IntegerField()
    image=models.CharField(max_length=200)
    status=models.CharField(max_length=200)
    SELLER=models.ForeignKey(Seller,on_delete=models.CASCADE)

class Cart(models.Model):
    CUSTOMER=models.ForeignKey(Customer,on_delete=models.CASCADE)
    PRODUCT=models.ForeignKey(Product,on_delete=models.CASCADE)
    quantity=models.IntegerField()

class Deliveryaddress(models.Model):
    housename=models.CharField(max_length=200)
    street=models.CharField(max_length=200)
    place=models.CharField(max_length=200)
    post=models.CharField(max_length=200)
    pin=models.CharField(max_length=200)
    CUSTOMER=models.ForeignKey(Customer,on_delete=models.CASCADE)

class Order(models.Model):
    date=models.CharField(max_length=200)
    payment_method=models.CharField(max_length=200)
    payment_status=models.CharField(max_length=200)
    total_amount=models.CharField(max_length=200)
    status=models.CharField(max_length=200)
    DELIVERY_ADDRESS=models.ForeignKey(Deliveryaddress,on_delete=models.CASCADE)

class Ordersub(models.Model):
    ORDER = models.ForeignKey(Order, on_delete=models.CASCADE)
    PRODUCT = models.ForeignKey(Product, on_delete=models.CASCADE)
    quantity = models.CharField(max_length=200)
    price = models.CharField(max_length=200)

    # --- Merged Return fields (nullable) ---
    status = models.CharField(max_length=200, null=True, blank=True)
    return_reason = models.CharField(max_length=200, null=True, blank=True)
    return_image = models.CharField(max_length=200, null=True, blank=True)
    return_date = models.CharField(max_length=200, null=True, blank=True)
    return_seller_risk = models.CharField(max_length=200, null=True, blank=True)
    is_fraud = models.BooleanField(default=False,null=True)


class Review(models.Model):
    rating=models.CharField(max_length=200)
    review=models.CharField(max_length=200)
    date=models.CharField(max_length=200)
    CUSTOMER=models.ForeignKey(Customer,on_delete=models.CASCADE)
    ORDERSUB_PRODUCT=models.ForeignKey(Ordersub,on_delete=models.CASCADE)

class Feedback(models.Model):
    feedback=models.CharField(max_length=200)
    date=models.CharField(max_length=200)
    CUSTOMER=models.ForeignKey(Customer,on_delete=models.CASCADE)

