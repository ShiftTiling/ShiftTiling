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

from IPython.core.pylabtools import figsize
from kmedoids import kmedoids # kMedoids code is adapted from https://github.com/letiantian/kmedoids
from openpyxl import Workbook
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

    H = int(height / basicHeight)
    W = int(width / basicWidth)
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

def save(data, path):
    wb = Workbook()
    ws = wb.active # 激活 worksheet
    [h, l] = data.shape  # h为行数，l为列数
    for i in range(h):
        row = []
        for j in range(l):
            row.append(data[i,j])
        ws.append(row)
    wb.save(path)

sns.set()
plt.rcParams['figure.figsize'] = (12, 12)



# Import dataset



height = int(1440)
width = int(2880)
H = 15
W = 30
basic_width = math.ceil(height / H)
basic_height = math.ceil(width / W)
V_width = int(width / 360 * 100)
V_height = int(height / 180 * 100)
np.set_printoptions(threshold=np.inf)

trainDataSetNumber = 0.8;
timeWindow = [30] #用来定义所采样的轨迹时间窗口,每隔3s,5s,10s做聚类
for videoid in [90,103,104,133,134]:
        data_folder = 'data'
        filename = '%s/%d.mat' % (data_folder, videoid)
        traj_data = scipy.io.loadmat(filename)['track']
        userNumber = (traj_data.shape)[0]
        temp_trad_data = []
        testData = testDataIndex
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
                mkdir(str(tW) + '_ClusPerformace_ClusTileBest/' + str(videoid) + '/')
                mkdir('ClusTrajResultFinal/')
                dimen = traj_data[0][0].shape
                totalLength = dimen[1]
                tilingClusterNumber = np.zeros(math.ceil(totalLength/30))
                tilingPerformace = np.zeros(math.ceil(totalLength/30))
                tilingMethod = []
                seconds = 0
                for s in range(0, totalLength, tW): #每次只计算30帧的
                    traj_lst = []
                    for data_instance in traj_data:
                        temp = data_instance[0].T
                        temp = temp[s:s + tW][:]
                        #print(temp)
                        if len(temp):
                            traj_lst.append(np.vstack(temp))

                    traj_count = len(traj_lst)
                    # This may take a while

                    # k-means
                    # The number of clusters

                    final_clusterNumber = 6
                    final_coverRatio = 0
                    #做聚类

                    k = final_clusterNumber
                    cover_ratio = 0
                    '''
                    st = time.time()
                    medoid_center_lst, cluster2index_lst = kmedoids.kMedoids(D, k)
                    print(time.time() - st)
                    cluster_lst = np.empty((traj_count,), dtype=int)
                    for cluster in cluster2index_lst:
                        cluster_lst[cluster2index_lst[cluster]] = cluster
                '''
                    cluster_lst = scipy.io.loadmat('kMeansResult/' + str(videoid) + '/' + str(s) + '.mat')['clusterLst'][0]
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
                    print('聚类完成' + str(time.time()))
                    clusterNumber = max(cluster_lst) + 1

                    M = np.zeros((clusterNumber, 30, H, W), dtype=int)  # 计算的每一簇内部的每一帧的并集
                    for data_t, cluster in zip(data_total, cluster_lst):  # 求并集
                        if cluster != -1:
                            t = 0
                            for d in data_t:
                                temp = function(height, width, basic_height, basic_width, int(d[1]), int(d[0]),
                                                V_height, V_width)

                                M[cluster, t, :, :] = M[cluster, t, :, :] + function(height, width, basic_height,
                                                                                     basic_width, int(d[1]),
                                                                                     int(d[0]),
                                                                                     V_height, V_width)
                                t = t + 1
                    print('映射完成' + str(time.time()))
                    tiles = 0
                    totalTiles = 0
                    total_M = np.zeros((clusterNumber, H, W), dtype=int)  # 计算1s之内总共并集
                    for data_t, cluster in zip(data_total, cluster_lst):  # 求并集
                        if cluster != -1:
                            t = 0
                            for d in data_t:
                                temp = function(height, width, basic_height, basic_width, int(d[1]), int(d[0]),
                                                V_height, V_width)
                                temp2 = M[cluster, t, :, :]
                                temp2[temp2 >= 1] = 1
                                M[cluster, t, :, :] = temp2
                                tiles = tiles + temp.sum()
                                total_M[cluster, :, :] = np.bitwise_or(total_M[cluster, :, :], temp2)
                                t = t + 1
                    print('并集完成' + str(time.time()))
                    StartRow = 0
                    EndRow = 0
                    StartCol = 0
                    EndCol = 0

                    M_PerUser = np.zeros((userNumber, H, W), dtype=int)
                    userid = 0
                    for data_t in data_total:
                        for d in data_t:
                            temp = function(height, width, basic_height, basic_width, int(d[1]), int(d[0]),
                                            V_height, V_width)
                            temp = temp.astype(int)
                            M_PerUser[userid, :, :] = np.bitwise_or(M_PerUser[userid, :, :], temp)
                        userid = userid + 1

                    for c in range(0, clusterNumber):

                        if total_M[c, :, 0].sum() > 0 and total_M[c, :, -1].sum() > 0:
                            print(total_M[c, :, :])
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
                            print(total_M[c, :, :])
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
                        B = np.zeros((BasicTileNumber, 1))

                        #输出每个用户的viewport矩阵,每次只输出对应分类的
                        userid = 0
                        userLst = []
                        output_B_PerUser = []
                        for data_t, cluster in zip(data_total, cluster_lst):
                            if cluster == c:
                                 B_PerUser = np.zeros((BasicTileNumber, 1))
                                 ttt = 0
                                 for r in range(StartRow, EndRow + 1):  #行优先顺序排列
                                     for co in range(StartCol, EndCol + 1):
                                         if M_PerUser[userid, r, co % total_N_Shape[1]] == 1:
                                             B_PerUser[ttt, 0] = 1
                                         ttt = ttt + 1
                                 userLst.append(userid)
                                 output_B_PerUser.append(B_PerUser)
                            userid = userid + 1


                        ttt = 0
                        for r in range(StartRow, EndRow + 1):
                            for co in range(StartCol, EndCol + 1):
                                if total_M[c, r, co % total_N_Shape[1]] == 1:
                                    B[ttt, 0] = 1
                                ttt = ttt + 1

                        ttt = 0
                        for sr in range(StartRow, EndRow + 1):
                            for er in range(sr, EndRow + 1):
                                for sc in range(StartCol, EndCol + 1):
                                    for ec in range(sc, EndCol + 1):
                                        if (er - sr + 1) * (ec - sc + 1) >= 4:
                                            ttt = ttt + 1

                        M_output = np.zeros((BasicTileNumber, ttt))  # Basictile按行优先顺序排列,也就是M矩阵
                        N_output = np.zeros((ttt, 1))
                        ttt = 0
                        total_N_Shape = total_M[c, :, :].shape
                        output_CuttingLocation = []
                        for sr in range(StartRow, EndRow + 1):
                            for er in range(sr, EndRow + 1):
                                for sc in range(StartCol, EndCol + 1):
                                    for ec in range(sc, EndCol + 1):
                                        if (er - sr + 1) * (ec - sc + 1) < 4:
                                            continue
                                        '''
                                        if sc < total_N_Shape[1] and ec < total_N_Shape[1]:
                                            temp_M = np.zeros((EndRow - StartRow + 1, EndCol - StartCol + 1))
                                            temp_M[sr - StartRow:er + 1 - StartRow, sc - StartCol:ec + 1 - StartCol] = 1
                                            M_output[:, ttt] = temp_M.flatten()
                                            ttt = ttt + 1
                                    '''
                                       # if sc >= total_N_Shape[1] and ec >= total_N_Shape[1]:
                                        temp_M = np.zeros((EndRow - StartRow + 1, EndCol - StartCol + 1))
                                        temp_M[sr - StartRow:er + 1 - StartRow, sc - StartCol: ec - StartCol + 1] = 1
                                        # temp_M[sr - StartRow:er + 1 - StartRow, total_N_Shape[1] - StartCol : ec - StartCol + 1] = 1
                                        M_output[:, ttt] = temp_M.flatten()
                                        output_CuttingLocation.append([sr,er,sc,ec])
                                        ttt = ttt + 1

                        ttt = 0
                        for sr in range(StartRow, EndRow + 1):
                            for er in range(sr, EndRow + 1):
                                for sc in range(StartCol, EndCol + 1):
                                    for ec in range(sc, EndCol + 1):
                                        if (er - sr + 1) * (ec - sc + 1) < 4:
                                            continue
                                        N_sum = 0
                                        if ec >= total_N_Shape[1]:
                                            N_sum = N_sum + total_M[c, sr:er + 1, sc:total_N_Shape[1]].sum()
                                            N_sum = N_sum + total_M[c, sr:er + 1, 0:(ec % total_N_Shape[1]) + 1].sum()
                                        else:
                                            N_sum = N_sum + total_M[c, sr:er + 1, sc:ec + 1].sum()
                                        N_output[ttt, 0] = N_sum
                                        ttt = ttt + 1
                        extraData = np.zeros(4)
                        extraData[0] = StartRow
                        extraData[1] = EndRow
                        extraData[2] = StartCol
                        extraData[3] = EndCol
                        print('当前输出集和类别' + str(videoid) + ' ' + str(int(s / 30)) + ' ' + str(c))
                        mkdir('OutputBNM/' + str(videoid) + '/' + str(int(s / 30)))
                        # save(M_output, 'OutputBNM/' + str(videoid) + '/' + str(s) + '/' + str(c) + '/' + 'M.xls')
                        # save(B, 'OutputBNM/' + str(videoid) + '/' + str(s) + '/' + str(c) + '/' + 'B.xls')
                        sio.savemat('OutputBNM/' + str(videoid) + '/' + str(int(s / 30)) + '/' + str(c) + '.mat', \
                                    {'M': M_output, 'L':output_CuttingLocation,'B': B, 'N': N_output, 'Extra': extraData, 'B_PerUser': output_B_PerUser,'UserLst': userLst},do_compression=True)



                    #matData2 = sio.savemat('ClusTrajResultFinal/' + str(videoid) + '.mat',
                                       #{'Track': result_tra, 'clusterLabels': result_lbl})
