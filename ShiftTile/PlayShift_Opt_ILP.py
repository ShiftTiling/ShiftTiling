﻿import urllib
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

from IPython.core.pylabtools import figsize
from kmedoids import kmedoids # kMedoids code is adapted from https://github.com/letiantian/kmedoids
import time


color_lst = plt.rcParams['axes.prop_cycle'].by_key()['color']

color_lst.extend(['firebrick', 'olive', 'indigo', 'khaki', 'teal', 'saddlebrown',
                  'skyblue', 'coral', 'darkorange', 'lime', 'darkorchid', 'dimgray'])
def plot_cluster(traj_lst, cluster_lst,t, videoid, s):
    '''
    Plots given trajectories with a color that is specific for every trajectory's own cluster index.
    Outlier trajectories which are specified with -1 in `cluster_lst` are plotted dashed with black color
    '''

    cluster_count = np.max(cluster_lst) + 1
    fig = plt.figure()
    ax = fig.gca(projection='3d')

    for traj, cluster in zip(traj_lst, cluster_lst):
        if cluster == -1:
            ax.plot(traj[:, 0], traj[:, 1], traj[:, 2], c='k', linestyle='dashed')
        else:
            ax.plot(traj[:, 0], traj[:, 1], traj[:, 2], c=color_lst[cluster % len(color_lst)])

    ax.set_xlim(-1.0, 1.0)
    ax.set_ylim(-1.0, 1.0)
    ax.set_zlim(-1.0, 1.0)

    plt.savefig(str(t)+'/'+str(videoid)+'/'+str(s)+'.png')
    plt.close()



def hausdorff(u, v):
    d = max(directed_hausdorff(u, v)[0], directed_hausdorff(v, u)[0])
    return d


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

def angle(x, y):
    if y>0 and x>=0:
        return math.atan2(y, x)
    if y>0 and x<0:
        return math.atan2(y, x)
    if y<0 and x<0:
        return math.atan2(y, x) + math.pi * 2
    if y<0 and x>=0:
        return math.atan2(y, x) + math.pi * 2


import numpy as np
import math

def function2dToRealViewport(height, width, basicHeight, basicWidth, \
             centerHeight, centerWidth):
    H = int(height / basicHeight)
    W = int(width / basicWidth)
    result = np.zeros(H, W)
    centerX = 1 * math.cos((centerHeight - 0.5) * math.pi) * math.cos(centerWidth * 2 * math.pi)
    centerY = 1 * math.cos((centerHeight - 0.5) * math.pi) * math.sin(centerWidth * 2 * math.pi)
    centerZ = 1 * math.sin((centerHeight - 0.5) * math.pi)
    vC = np.array([centerX, centerY, centerZ])
    for i in range(0, H):
        for j in range(0, W):
                tileCenterHeight = int((i * basic_height + (i + 1) * basic_height) / 2)
                tileCenterWidth = int((j * basic_width + (j + 1) * basic_width) / 2)
                tileX = 1 * math.cos((tileCenterHeight - 0.5) * math.pi) * math.cos(tileCenterWidth * 2 * math.pi)
                tileY = 1 * math.cos((tileCenterHeight - 0.5) * math.pi) * math.sin(tileCenterWidth * 2 * math.pi)
                tileZ = 1 * math.sin((tileCenterHeight - 0.5) * math.pi)
                vT = np.array([tileX, tileY, tileZ])
                Lx = np.sqrt(vC.dot(vC))
                Ly = np.sqrt(vT.dot(vT))
                # 相当于勾股定理，求得斜线的长度
                cos_angle = vC.dot(vT) / (Lx * Ly)
                angle = np.arccos(cos_angle)
                angle2 = angle * 360 / 2 / np.pi
                if angle2 < 100:
                    result[i, j] = 1
    return result

def tilesInViewport(H, W, \
                    topMostTile, bottomMostTile, leftMostTile, rightMostTile):
    # print([topMostTile,bottomMostTile,leftMostTile,rightMostTile])
    if topMostTile <= 0:
        return tilesInViewport(H, W, H + topMostTile, H, leftMostTile, rightMostTile) \
               + tilesInViewport(H, W, 1, bottomMostTile, leftMostTile, rightMostTile)
    if bottomMostTile > H:
        return tilesInViewport(H, W, topMostTile, H, leftMostTile, rightMostTile) \
               + tilesInViewport(H, W, 1, bottomMostTile - H, leftMostTile, rightMostTile)
    if leftMostTile <= 0:
        return tilesInViewport(H, W, topMostTile, bottomMostTile, W + leftMostTile, W) \
               + tilesInViewport(H, W, topMostTile, bottomMostTile, 1, rightMostTile)
    if rightMostTile > W:
        return tilesInViewport(H, W, topMostTile, bottomMostTile, leftMostTile, W) \
               + tilesInViewport(H, W, topMostTile, bottomMostTile, 1, rightMostTile - W)

    bkgMatrix = np.zeros((H, W))

    viewportRangeH = slice(topMostTile - 1, bottomMostTile)
    viewportRangeW = slice(leftMostTile - 1, rightMostTile)
    bkgMatrix[viewportRangeH, viewportRangeW] = \
        np.ones((bottomMostTile - topMostTile + 1, rightMostTile - leftMostTile + 1))
    return bkgMatrix


def function(height, width, basicHeight, basicWidth, \
             centerH, centerW, viewportHeight, viewportWidth):
    if viewportHeight >= height or viewportWidth >= width:
        print("error!")
        return None

    H = math.ceil(height / basicHeight)
    W = math.ceil(width / basicWidth)
    # 假设viewport的长宽总是偶数，centerH和centerW表示viewport中心的四个像素中左上角那个
    # 像素和tile都从1开始计数
    topMostPixel = centerH - int(viewportHeight / 2) + 1
    bottomMostPixel = centerH + int(viewportHeight / 2)
    leftMostPixel = centerW - int(viewportWidth / 2) + 1
    rightMostPixel = centerW + int(viewportWidth / 2)

    # 计算上下左右在tile尺度下的边界
    # 除法用//，而不是int(a/b)，因为int(负数)是向上取整
    topMostTile = (topMostPixel - 1) // basicHeight + 1
    bottomMostTile = (bottomMostPixel - 1) // basicHeight + 1
    leftMostTile = (leftMostPixel - 1) // basicWidth + 1
    rightMostTile = (rightMostPixel - 1) // basicWidth + 1

    return tilesInViewport(H, W, \
                           topMostTile, bottomMostTile, leftMostTile, rightMostTile)


# Some visualization stuff, not so important
sns.set()
plt.rcParams['figure.figsize'] = (12, 12)



# Import dataset


basic_width = int(96)
basic_height = int(96)
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
for videoid in VideoIndex:
        data_folder = 'data'
        filename = '%s/%d.mat' % (data_folder, videoid)
        traj_data = scipy.io.loadmat(filename)['track']
        userNumber = (traj_data.shape)[0]
        temp_trad_data = []
        testData = testIndex
        userRange = []
        uN = 0
        for temp in  traj_data:
            if uN not in testData:
                 temp_trad_data.append(temp)
                 userRange.append(uN)
            uN = uN + 1
        traj_data = temp_trad_data
        fsize = os.path.getsize(filename)
        fsize = fsize / float(1024)
        if fsize > 20:
            for tW in timeWindow:
                for frequency in [0.25]: #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!这里修改过了！！！！！！！！！！！！！！！！！！！！！！！！！！！！
                    dimen = traj_data[0][0].shape
                    totalLength = dimen[1]
                    tilingClusterNumber = np.zeros(math.ceil(totalLength / 30))
                    tilingPerformace = np.zeros(math.ceil(totalLength / 30))
                    tilingUncoverRatio = np.zeros(math.ceil(totalLength / 30))
                    tilingMethod = []
                    outputtilingMethod = []
                    outputtilineMethor_PerUser = [];
                    outputCluster = []
                    seconds = 0
                    for s in range(0, totalLength, tW):
                        traj_lst = []
                        for data_instance in traj_data:
                            temp = data_instance[0].T
                            temp = temp[s:s + tW][:]
                            # print(temp)
                            if len(temp):
                                traj_lst.append(np.vstack(temp))

                        traj_count = len(traj_lst)
                        D = np.zeros((traj_count, traj_count))

                        # This may take a while
                        for i in range(traj_count):
                            for j in range(i + 1, traj_count):
                                # print(str(i) + ' ' + str(j))
                                # 将轨迹聚类修改为不相交块的数量
                                distance = 0
                                for trad_d_i, trad_d_j in zip(traj_lst[i], traj_lst[j]):
                                    temp_x = angle(trad_d_i[0], trad_d_i[1]) / (2 * math.pi)
                                    temp_y = math.atan2(trad_d_i[2],
                                                        math.sqrt(
                                                            math.pow(trad_d_i[0], 2) + math.pow(trad_d_i[1], 2)))
                                    temp_y = (temp_y + math.pi * 0.5) / math.pi
                                    data_ix = temp_x * width
                                    data_iy = temp_y * height

                                    temp_x = angle(trad_d_j[0], trad_d_j[1]) / (2 * math.pi)
                                    temp_y = math.atan2(trad_d_j[2],
                                                        math.sqrt(
                                                            math.pow(trad_d_j[0], 2) + math.pow(trad_d_j[1], 2)))
                                    temp_y = (temp_y + math.pi * 0.5) / math.pi
                                    data_jx = temp_x * width
                                    data_jy = temp_y * height

                                    viewport_i = function(height, width, basic_height, basic_width, int(data_iy),
                                                          int(data_ix), V_height, V_width)
                                    viewport_j = function(height, width, basic_height, basic_width, int(data_jy),
                                                          int(data_jx), V_height, V_width)
                                    viewport_i = viewport_i.astype(int)
                                    viewport_j = viewport_j.astype(int)
                                    Union_ij = np.bitwise_or(viewport_i, viewport_j)
                                    InterSect_ij = np.bitwise_and(viewport_i, viewport_j)
                                    InterSect_ij_complementary = 1 - InterSect_ij

                                    distance = distance + (np.bitwise_and(Union_ij, InterSect_ij_complementary)).sum()
                                    # distance = np.mean(np.linalg.norm(traj_lst[i]-traj_lst[j], ord=2, axis=-1))
                                    # print(distance)
                                D[i, j] = distance
                                D[j, i] = distance

                        # k-means
                        # The number of clusters
                        max_cluster = 7
                        for k in range(6, max_cluster):
                            cover_ratio = 0
                            uncover_ratio = 0
                            medoid_center_lst, cluster2index_lst = kmedoids.kMedoids(D, k)
                            cluster_lst = np.empty((traj_count,), dtype=int)
                            for cluster in cluster2index_lst:
                                cluster_lst[cluster2index_lst[cluster]] = cluster

                            data_total = []
                            for traj, cluster in zip(traj_lst, cluster_lst):
                                if cluster == -1:
                                    ss = traj.shape
                                    data = np.zeros((ss[0], 2))
                                    td = 0
                                    for traj_d in traj:
                                        temp_x = angle(traj_d[0], traj_d[1]) / (2 * math.pi)
                                        temp_y = math.atan2(traj_d[2],
                                                            math.sqrt(math.pow(traj_d[0], 2) + math.pow(traj_d[1], 2)))
                                        temp_y = (temp_y + math.pi * 0.5) / math.pi
                                        data[td, 0] = temp_x * width
                                        data[td, 1] = temp_y * height
                                        td = td + 1
                                    # ax.plot(data[:, 0], data[:, 1], c='k', linestyle='dashed')
                                    data_total.append(data)
                                else:
                                    ss = traj.shape
                                    data = np.zeros((ss[0], 2))
                                    td = 0
                                    for traj_d in traj:
                                        temp_x = angle(traj_d[0], traj_d[1]) / (2 * math.pi)
                                        temp_y = math.atan2(traj_d[2],
                                                            math.sqrt(math.pow(traj_d[0], 2) + math.pow(traj_d[1], 2)))
                                        temp_y = (temp_y + math.pi * 0.5) / math.pi
                                        data[td, 0] = temp_x * width
                                        data[td, 1] = temp_y * height
                                        td = td + 1
                                    # ax.plot(data[:, 0], data[:, 1], c=color_lst[cluster % len(color_lst)])
                                    data_total.append(data)

                            clusterNumber = max(cluster_lst) + 1

                            M = np.zeros((clusterNumber, 30, H, W))
                            for data_t, cluster in zip(data_total, cluster_lst):  # 求并集
                                if cluster != -1:
                                    t = 0
                                    for d in data_t:
                                        temp = function(height, width, basic_height, basic_width, int(d[1]), int(d[0]),
                                                        V_height, V_width)
                                        M[cluster, t, :, :] = M[cluster, t, :, :] + function(height, width,
                                                                                             basic_height,
                                                                                             basic_width, int(d[1]),
                                                                                             int(d[0]),
                                                                                             V_height, V_width)
                                        t = t + 1

                            tiles = 0
                            totalTiles = 0
                            uncover_tiles = 0
                            uncover_totalTiles = 0
                            for data_t, cluster in zip(data_total, cluster_lst):  # 求覆盖率
                                if cluster != -1:
                                    t = 0
                                    cluster_perNumber = np.sum(cluster_lst == cluster)
                                    for d in data_t:
                                        temp = function(height, width, basic_height, basic_width, int(d[1]), int(d[0]),
                                                        V_height, V_width)
                                        temp2 = M[cluster, t, :, :].copy()
                                        temp = temp.astype(int)  # 为实际视点对应的
                                        temp2 = temp2.astype(int)  # 为实际使用的块，他们的交集为实际覆盖有效的块，未覆盖的块应该为temp-temp2

                                        temp2[temp2 < math.ceil(max(math.ceil(cluster_perNumber * frequency), 1))] = 0
                                        temp2[temp2 >= math.ceil(max(math.ceil(cluster_perNumber * frequency), 1))] = 1
                                        temp3 = 1 - temp2  # 未使用的块的补集
                                        temp3 = temp3.astype(int)
                                        temp3 = np.bitwise_and(temp, temp3)  # 为未覆盖的块

                                        uncover_tiles = uncover_tiles + temp3.sum()  # 计算一下有都少块没被覆盖住
                                        uncover_totalTiles = uncover_totalTiles + temp.sum()

                                        temp = np.bitwise_and(temp, temp2)
                                        tiles = tiles + temp.sum()
                                        totalTiles = totalTiles + temp2.sum()
                                        t = t + 1

                        final_clusterNumber = 6

                        for k in range(final_clusterNumber, final_clusterNumber + 1):
                            cluster_lst = \
                                scipy.io.loadmat('kMeansResult/' + str(videoid) + '/' + str(s) + '.mat')['clusterLst'][0]
                            data_total = []

                            for traj, cluster in zip(traj_lst, cluster_lst):
                                if cluster == -1:
                                    ss = traj.shape
                                    data = np.zeros((ss[0], 2))
                                    td = 0
                                    for traj_d in traj:
                                        temp_x = angle(traj_d[0], traj_d[1]) / (2 * math.pi)
                                        temp_y = math.atan2(traj_d[2],
                                                            math.sqrt(math.pow(traj_d[0], 2) + math.pow(traj_d[1], 2)))
                                        temp_y = (temp_y + math.pi * 0.5) / math.pi
                                        data[td, 0] = temp_x * width
                                        data[td, 1] = temp_y * height
                                        td = td + 1
                                    data_total.append(data)
                                else:
                                    ss = traj.shape
                                    data = np.zeros((ss[0], 2))
                                    td = 0
                                    for traj_d in traj:
                                        temp_x = angle(traj_d[0], traj_d[1]) / (2 * math.pi)
                                        temp_y = math.atan2(traj_d[2],
                                                            math.sqrt(math.pow(traj_d[0], 2) + math.pow(traj_d[1], 2)))
                                        temp_y = (temp_y + math.pi * 0.5) / math.pi
                                        data[td, 0] = temp_x * width
                                        data[td, 1] = temp_y * height
                                        td = td + 1

                                    data_total.append(data)
                            # data_total 存储了当前s所有的轨迹数据，cluster_lst存储了对应的标号

                            clusterNumber = max(cluster_lst) + 1

                            M = np.zeros((clusterNumber, 30, H, W), dtype=int)  # 包含频度的
                            output_M = np.zeros((clusterNumber, 30, H, W), dtype=int)  # 不包含频度的
                            tra = 0
                            for data_t, cluster in zip(data_total, cluster_lst):  # 求并集
                                if cluster != -1:
                                    t = 0
                                    for d in data_t:
                                        temp = function(height, width, basic_height, basic_width, int(d[1]), int(d[0]),
                                                        V_height, V_width)
                                        M[cluster, t, :, :] = M[cluster, t, :, :] + function(height, width,
                                                                                             basic_height,
                                                                                             basic_width, int(d[1]),
                                                                                             int(d[0]),
                                                                                             V_height, V_width)
                                        t = t + 1
                                    tra = tra + 1
                            # 求每秒最大并集
                            total_M = np.zeros((clusterNumber, H, W), dtype=int)  # 计算1s之内总共并集
                            for data_t, cluster in zip(data_total, cluster_lst):  # 求并集
                                if cluster != -1:
                                    t = 0
                                    for d in data_t:
                                        temp = function(height, width, basic_height, basic_width, int(d[1]), int(d[0]),
                                                        V_height, V_width)
                                        temp2 = M[cluster, t, :, :].copy()
                                        temp2 = temp2.astype(int)
                                        temp2[temp2 >= 1] = 1
                                        tiles = tiles + temp.sum()
                                        total_M[cluster, :, :] = np.bitwise_or(total_M[cluster, :, :], temp2)
                                        t = t + 1

                            # 求每秒开始行列
                            M_PerUser = np.zeros((userNumber, 30, H, W), dtype=int)
                            userid = 0
                            for data_t in data_total:
                                t = 0
                                for d in data_t:
                                    temp = function(height, width, basic_height, basic_width, int(d[1]), int(d[0]),
                                                    V_height, V_width)
                                    temp = temp.astype(int)
                                    M_PerUser[userid, t, :, :] = temp
                                    t = t + 1
                                userid = userid + 1

                            for c in range(0, clusterNumber):
                                StartRow = 0
                                EndRow = 0
                                StartCol = 0
                                EndCol = 0
                                if total_M[c, :, 0].sum() > 0 and total_M[c, :, -1].sum() > 0:
                                    total_N_Shape = total_M[c, :, :].shape
                                    for r in range(0, total_N_Shape[0]):
                                        if total_M[c, r, :].sum() > 0:
                                            StartRow = r
                                            break
                                    for r in range(total_N_Shape[0] - 1, -1, -1):
                                        if total_M[c, r, :].sum() > 0:
                                            EndRow = r
                                            break
                                    for co in range(0, total_N_Shape[1] - 1):
                                        if total_M[c, :, co].sum() > 0 and total_M[c, :, co + 1].sum() == 0:
                                            EndCol = co + total_N_Shape[1] - 1
                                            break
                                    for co in range(total_N_Shape[1] - 1, 0, -1):
                                        if total_M[c, :, co].sum() > 0 and total_M[c, :, co - 1].sum() == 0:
                                            StartCol = co
                                            break
                                else:

                                    total_N_Shape = total_M[c, :, :].shape
                                    for r in range(0, total_N_Shape[0]):
                                        if total_M[c, r, :].sum() > 0:
                                            StartRow = r
                                            break
                                    for r in range(total_N_Shape[0] - 1, -1, -1):
                                        if total_M[c, r, :].sum() > 0:
                                            EndRow = r
                                            break
                                    for co in range(0, total_N_Shape[1]):
                                        if total_M[c, :, co].sum() > 0:
                                            StartCol = co
                                            break
                                    for co in range(total_N_Shape[1] - 1, -1, -1):
                                        if total_M[c, :, co].sum() > 0:
                                            EndCol = co
                                            break
                                BasicTileNumber = (EndRow - StartRow + 1) * (EndCol - StartCol + 1)
                                # 先求出shiftile的B矩阵
                                B_Shift = np.zeros((30, (EndRow - StartRow + 1), (EndCol - StartCol + 1)), dtype=int)
                                cluster_perNumber = np.sum(cluster_lst == c)
                                for t in range(0, 30):
                                    temp2 = M[c, t, :, :].copy()
                                    temp2 = temp2.astype(int)  # 为实际使用的块，他们的交集为实际覆盖有效的块，未覆盖的块应该为temp-temp2
                                    temp2[temp2 < math.ceil(max(math.ceil(cluster_perNumber * frequency), 1))] = 0
                                    temp2[temp2 >= math.ceil(max(math.ceil(cluster_perNumber * frequency), 1))] = 1
                                    output_M[c, t, :, :] = temp2.copy()  # 不带频度的
                                    temp_M = np.zeros((EndRow - StartRow + 1, EndCol - StartCol + 1))
                                    for i in range(StartRow, EndRow + 1):
                                        for j in range(StartCol, EndCol + 1):
                                            if output_M[c, t, i, j % total_N_Shape[1]] == 1:
                                                B_Shift[t, i - StartRow, j - StartCol] = 1

                                output_B_PerUser = []
                                userLst = []
                                output_CuttingLocation = []
                                userid = 0
                                for data_t, cluster in zip(data_total, cluster_lst):
                                    if cluster == c:
                                        B_PerUser = np.zeros((30, (EndRow - StartRow + 1), (EndCol - StartCol + 1)),
                                                             dtype=int)
                                        for t in range(0, 30):
                                            for r in range(StartRow, EndRow + 1):  # 行优先顺序排列
                                                for co in range(StartCol, EndCol + 1):
                                                    if M_PerUser[userid, t, r, co % total_N_Shape[1]] == 1:
                                                        B_PerUser[t, r - StartRow, co - StartCol] = 1
                                        for t in range(0,30):
                                            B_PerUser[t,:,:]= B_PerUser[t,:,:]>B_Shift[t,:,:]
                                        B_PerUser_Compression = np.zeros(((EndRow - StartRow + 1), (EndCol - StartCol + 1)),
                                                             dtype=int)
                                        for t in range(0,30):
                                            B_PerUser_Compression = np.bitwise_or(B_PerUser_Compression, B_PerUser[t,:,:])
                                        userLst.append(userid)
                                        output_B_PerUser.append(B_PerUser_Compression)
                                    userid = userid + 1
                                ttt = 0
                                for sr in range(StartRow, EndRow + 1):
                                    for er in range(sr, EndRow + 1):
                                        for sc in range(StartCol, EndCol + 1):
                                            for ec in range(sc, EndCol + 1):
                                                if (er - sr + 1) * (ec - sc + 1) >= 4:
                                                    ttt = ttt + 1
                                                    output_CuttingLocation.append([sr, er, sc, ec])
                                M_Clus = np.zeros((ttt, (EndRow - StartRow + 1), (EndCol - StartCol + 1)),
                                                  dtype=int)
                                ttt = 0
                                for sr in range(StartRow, EndRow + 1):
                                    for er in range(sr, EndRow + 1):
                                        for sc in range(StartCol, EndCol + 1):
                                            for ec in range(sc, EndCol + 1):
                                                if (er - sr + 1) * (ec - sc + 1) < 4:
                                                    continue
                                                temp_M = np.zeros((EndRow - StartRow + 1, EndCol - StartCol + 1),
                                                                  dtype=int)
                                                temp_M[sr - StartRow:er + 1 - StartRow,
                                                sc - StartCol: ec - StartCol + 1] = 1
                                                M_Clus[ttt , :, :] = temp_M
                                                ttt = ttt + 1
                                extraData = np.zeros(4)
                                extraData[0] = StartRow
                                extraData[1] = EndRow
                                extraData[2] = StartCol
                                extraData[3] = EndCol
                                print('当前输出集和类别' + str(videoid) + ' ' + str(int(s / 30)) + ' ' + str(c))
                                mkdir('OutputBNM_ShiftTile/' + str(videoid) + '/' + str(int(s / 30)) + '/' + str(int(frequency*100)) )
                                sio.savemat('OutputBNM_ShiftTile/' + str(videoid) + '/' + str(int(s / 30)) +'/'+ str(int(frequency*100))+ '/' + str(
                                    c) + '.mat', \
                                            {'B_Clus': M_Clus, 'L': output_CuttingLocation, 'B_Shift': B_Shift, \
                                             'Extra': extraData, 'B_PerUser': output_B_PerUser, 'UserLst': userLst},
                                            do_compression=True)

                        tilingMethod.append(M)
                        outputtilingMethod.append(output_M)
                        tilingClusterNumber[seconds] = final_clusterNumber
                        outputCluster.append(cluster_lst)
                        seconds = seconds + 1
                        print(str(seconds) + ' of ' + str(math.ceil(totalLength / 30)) + ' ' + str(videoid))
                    matData2 = sio.savemat(
                        str(tW) + '_ShiftTile_Opt/' + str(videoid) + '_' + str(int(frequency * 100)) + '.mat', \
                        {'Method': outputtilingMethod})

                    #matData2 = sio.savemat('ClusTrajResultFinal/' + str(videoid) + '.mat',
                                       #{'Track': result_tra, 'clusterLabels': result_lbl})
