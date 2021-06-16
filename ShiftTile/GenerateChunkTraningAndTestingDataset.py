


from multiprocessing import Process,Pool
import time
import urllib
import zipfile
import os
import scipy.io
import math
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import scipy.io as sio
from mpl_toolkits.mplot3d import Axes3D
from scipy.spatial.distance import directed_hausdorff
from sklearn.cluster import DBSCAN


def mkdir(path):
    # 引入模块
    import os
    path = path.strip()
    path = path.rstrip("\\")
    isExists = os.path.exists(path)
    if not isExists:
        os.makedirs(path)
        return True
    else:
        return False

basic_width = int(20)
basic_height = int(20)
height = int(1440)
width = int(2880)
H = int(height / basic_height)
W = int(width / basic_width)
V_width = int(width / 360 * 100)
V_height = int(height / 180 * 100)
np.set_printoptions(threshold=np.inf)
f = open("out.txt", "w")
trainDataSetNumber = 0.8;
timeWindow = [30] #用来定义所采样的轨迹时间窗口,每隔3s,5s,10s做聚类
for videoid in range(109,150):
        data_folder = 'data'
        filename = '%s/%d.mat' % (data_folder, videoid)
        traj_data = scipy.io.loadmat(filename)['track']
        userNumber = (traj_data.shape)[0]
        trainingSet = list(range(userNumber))  # 训练样本下标
        testSet = []
        for i in range(5):
            randIndex = int(np.random.uniform(0, len(trainingSet)))  # 获得0~len(trainingSet)的一个随机数
            testSet.append(trainingSet[randIndex])
            del (trainingSet[randIndex])
        mkdir('TrainingDataIndex/')
        scipy.io.savemat('TrainingDataIndex/' + str(videoid) + '.mat',{'Training':trainingSet, 'Testing':testSet})


