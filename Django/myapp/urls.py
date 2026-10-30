from django.conf.urls.static import static
from django.urls import path

from Ecommerce_Return_Fraud_Detection import settings
from myapp import views

urlpatterns = [

    path('',views.index ),
    path('login',views.logins ),
    path('loginpost',views.loginpost ),
    path('logouts',views.logouts ),
    path('forgotpassword',views.forgotpassword ),
    path('forgotpasswordbuttonclick',views.forgotpasswordbuttonclick ),
    path('otp',views.otp ),
    path('otpbuttonclick',views.otpbuttonclick ),
    path('forgotpswdpswed',views.forgotpswdpswed ),
    path('forgotpswdpswedbuttonclick',views.forgotpswdpswedbuttonclick ),


    path('admin_dashboard',views.admin_dashboard),
    path('admin_viewsellers',views.admin_viewsellers),
    path('admin_approveseller/<id>',views.admin_approveseller),
    path('admin_rejectseller/<id>',views.admin_rejectseller),
    path('admin_viewverifiedsellers',views.admin_viewverifiedsellers),
    path('admin_viewusers',views.admin_viewusers),
    path('admin_viewfeedback',views.admin_viewfeedback),
    path('admin_changepassword',views.admin_changepassword),
    path('admin_changepassword_post',views.admin_changepassword_post),
    path('admin_viewsuspiciouscases',views.admin_viewsuspiciouscases),
    path('admin_blockuser/<id>',views.admin_blockuser),
    path('admin_unblockuser/<id>',views.admin_unblockuser),

    path('seller_register',views.seller_register),
    path('seller_registerpost',views.seller_registerpost),
    path('seller_dashboard',views.seller_dashboard),
    path('seller_viewprofile',views.seller_viewprofile),
    path('seller_profileupdate',views.seller_profileupdate),
    path('seller_changepassword',views.seller_changepassword),
    path('seller_changepasswordpost',views.seller_changepasswordpost),
    path('seller_viewproducts',views.seller_viewproducts),
    path('seller_addproduct',views.seller_addproduct),
    path('seller_addproductpost',views.seller_addproductpost),
    path('seller_editproduct/<id>',views.seller_editproduct),
    path('seller_editproductpost',views.seller_editproductpost),
    path('seller_deleteproduct/<id>',views.seller_deleteproduct),
    path('seller_vieworders',views.seller_vieworders),
    path('seller_vieworderitems/<id>',views.seller_vieworderitems),
    path('seller_updateorderstatus',views.seller_updateorderstatus),
    path('seller_viewreviews/<id>',views.seller_viewreviews),
    path('seller_viewreturnrequest',views.seller_viewreturnrequest),
    path('seller_updatereturnrequeststatus/<id>',views.seller_updatereturnrequeststatus),

    path('seller_viewsalesreports', views.seller_viewsalesreports),
    path('seller_downloadsalesreport', views.seller_downloadsalesreport),
    path('seller_downloadsalespdf/', views.seller_downloadsalespdf),

    path("check-fraud/<int:ordersub_id>/", views.check_fraud),


    path('user_register',views.user_register),
    path('user_login',views.user_login),
    path('user_logout',views.user_logout),
    path('flutter_user',views.flutter_user),
    path('user_profile',views.user_profile),
    path('user_change_password',views.user_change_password),
    path('user_viewproducts',views.user_viewproducts),
    path('forgotemail',views.forgotemail),
    path('forgotpass',views.forgotpass),
    path('user_addtocart',views.user_addtocart),
    path('user_viewcart',views.user_viewcart),
    path('user_updatecart',views.user_updatecart),
    path('user_removecartitem',views.user_removecartitem),
    path('user_buynow',views.user_buynow),
    path('user_placeorder',views.user_placeorder),
    # path('user_vieworders',views.user_vieworders),
    # path('user_vieworderitems',views.user_vieworderitems),
    path('user_sendfeedback',views.user_sendfeedback),
    path('user_viewallorderitems',views.user_viewallorderitems),
    path('user_cancelorderitem',views.user_cancelorderitem),
    path('user_sendreview',views.user_sendreview),
    path('user_viewproductreviews',views.user_viewproductreviews),
    path('user_returnproduct',views.user_returnproduct),
    path('user_viewreturns',views.user_viewreturns),
    path('user_dashboard',views.user_dashboard),

]
urlpatterns+=static(settings.MEDIA_URL,document_root=settings.MEDIA_ROOT)
