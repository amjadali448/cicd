from django.shortcuts import render
from django.http import HttpResponse
# Create your views here.
def helloworld(request):
    return HttpResponse("<html> <body> Hello Abdur Rehman is good </body> </html>")

