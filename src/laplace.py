# -*- coding: utf-8 -*-
"""
Created on Thu Apr 14 15:15:56 2016

@author: talkie
"""
import math

def repart_laplace(x, b):
    if x < 0:
        return 0.5 * math.exp((x/b))
    return 1 - 0.5 * math.exp(((-x)/b))

def tab_X_b(X, b):
    rp = np.zeros(len(X))
    i = 0
    for x in X:
        rp[i] = repart_laplace(x, b)
        i+=1
    return rp
def tab_x_rp(b):
    rp = []
    if(b <= 50):
        for x in range(-b, b, 2):
            rp.add(repart_laplace(x, b))

    elif(b <= 250):
        for x in range(-b, b, 5):
            rp.add(repart_laplace(x, b))
    elif(b <= 500):
        for x in range(-b, b, 10):
            rp.add(repart_laplace(x, b))
    elif(b <= 1000):
        for x in range(-b, b, 20):
            rp.add(repart_laplace(x, b))
    else:
        for x in range(-b, b, 50):
            rp.add(repart_laplace(x, b))
    return rp

def dif_b(B):
    dif = []
    for b in B:
        dif.add(tab_x_rp(b))

    return dif



#tab = dif_b([2, 4, 10, 25, 50, 100, 250, 500, 750, 1000, 10000])
print 0.5 + repart_laplace(150, -200/math.log(0.04)) - repart_laplace(75, -200/math.log(0.04))

import matplotlib.pyplot as plt
import numpy as np
x=np.linspace(-10,10,200)
#plt.plot(x, tab_X_b(x, 0.5))
#plt.plot(x, tab_X_b(x, 1))
#plt.plot(x, tab_X_b(x, 2))
#plt.plot(x, tab_X_b(x, 5))
plt.plot(x, tab_X_b(x, -10/(math.log(0.04))))
#plt.plot(x, tab_X_b(x, -6/math.log(0.04)))
#plt.plot(x, tab_X_b(x, 50))
#plt.plot(x, tab_X_b(x, 100))
#plt.plot(x, tab_X_b(x, 250))
#plt.plot(x, tab_X_b(x, 500))
#plt.plot(x, tab_X_b(x, 1000))
plt.show()
