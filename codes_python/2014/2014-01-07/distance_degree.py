#!/usr/bin/env python 
#-*- coding:UTF-8 -*- 
#Program: 
#   Automatically parser dogs website information 
#History: 
#   time,       version,    editor, note 
#   20140107,   V1,         CCC,    計算座標間距離與方位 
#Copyright(c) 2014 Chang,Chih-Che(et00026@gmail.com) 

import sys
from geopy.distance import vincenty
from math import *

def cal_distance_degree(lon1, lat1, lon2, lat2):
    run_distance = vincenty((lat1, lon1), (lat2, lon2))
    dLon = 0
    dLon = float(lon2) - float(lon1)
    dLat = float(lat2) - float(lat1)
    #y = sin(dLon) * cos(float(lat2))
    #x = cos(float(lat1)) * sin(float(lat2)) - sin(float(lat1)) * cos(float(lat2)) * cos(float(dLon))

    direction = degrees(atan2(dLon, dLat))
    if direction < 0:
        direction += 360
    return run_distance*1000, direction

if __name__ == '__main__':
    lon1 = 120.289337
    lat1 = 22.733925
    lon2 = 120.286204
    lat2 = 22.733886
    #old_point(lon1,lat1); new_point(lon2,lat2) 
    print cal_distance_degree(lon1, lat1, lon2, lat2)
