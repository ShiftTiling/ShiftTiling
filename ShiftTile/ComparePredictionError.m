
clc;
clear all;
close all;

Height = 1440;     %帧高度
Width = 2880;     %帧宽度
V_Height = (Height/180*100);%视窗高度
V_Width = (Width/360*100); %视窗宽度
BasicWidth = 20;   %BasicTile宽度
UserNumber = 30;   %用户数量
frameGap = 30;     %帧率 30fps
H = Height / BasicWidth; %高有多少BasicTile
W = Width / BasicWidth;  %宽有多少BasicTile
vs = 109;             %视频开始id
ve = 149;             %视频结束id
Gap_Width = 126;
Gap_Height = 126;
ratio_shift = [];
cost_shift = [];
ratio_clus = [];
cost_clus = [];

ratio_shift_robust = [];
cost_shift_robust = [];
ratio_clus_robust = [];
cost_clus_robust = [];
cost_total_shift = [];
ratio_total_shift = [];
cost_total_clus = [];
ratio_total_clus = [];
vid = [];
ratio_clus_video = zeros(215,20,50);
ratio_shift_video = zeros(215,20,50);
cost_clus_video = zeros(215,20,50);
cost_shift_video = zeros(215,20,50);
X_Error = [];
cover_ratio = [];
test = [];
debug = [];
%我们要学一个东西，根据速度、和历史用户相似性，学习我们应该选择哪些簇每个簇应该传哪些块来提高覆盖率
for videoid =VideoIndex
    try
        matData2 = load(['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\LoadRawData\',num2str(frameGap),'_ShiftTile_Opt/' , num2str(videoid) , '.mat']);
        %将3d数据处理为2d数据，待完成
        tilingMethod = uint8(matData2.Method);
        clusterNumber = matData2.clusterNumber;
        viewPoint = matData2.Method_Peruser;
        [totalseconds,~] = size(tilingMethod);
        clusterLst = matData2.clusterLst;
        [~, userNumber] = size(clusterLst);
        
        viewPoint2d = load(['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\LoadRawData\data\',num2str(videoid),'.mat']);
        track = viewPoint2d.track;
        vid = sprintf('%03d', videoid);
        trainDataSet = 0.8;
        Bitrate_Shift = 0;
        Bitrate_Clus  = 0;
        Storage_Shift = 0;
        Storage_Clus = 0;
        result = [];
        result_ratio = cell(20,50);
        result_ratio2 = cell(20,50);
        result_ratio_clus =zeros(20,50);
        result_Speed = zeros(20,50);
        result_Similarity = cell(20,50);
        result_rightcluster_coverratio = zeros(20,50);
        result_ratio_switch = cell(20,50);
        result_ratio_switchratio = cell(20,50);
        result_ratio_v = zeros(20,50);
        result_all_speed=cell(20,50);
        
        
        tartets = 1;
        target = 30;
        cont_Shift = 0;
        cont_Clus = 0;
        Opt2 = zeros(20,50);
        try
            if iscell(clusterLst)
                clusterLst =clusterLst(1,1:totalseconds-2);
                temp = cell2mat(clusterLst);
                clusterLst = reshape(temp,[27,totalseconds-2])';
            end
        catch
            continue
        end
        
        for seconds =SecondIndex %用t时刻预测 [t+3,t+4)时刻，然后剩下的补全
            try
                %cluser_seconds_0
                %计算storageSize
                for uN = UserIndex  %测试集合
                    uN
                    result_ratio{seconds,uN} = zeros(1,4);
                    result_ratio2{seconds,uN} = zeros(1,4);
                    % try
                    %计算shifttile的码率
                    bs = 0;
                    bc = 0;
                    %co = clusterLst(seconds,uN) + 1; %shifttile下表从1开始
                    realViewpoint_raw = track{uN,1}(:,(seconds-2)*30+1:(seconds-1)*30);
                    realViewPort_raw = uint8(cell2mat(struct2cell(load(['OutputViewportReal/',num2str(videoid),'/',num2str(seconds-1),'_RealViewport.mat']))));
                    if isstruct(realViewPort_raw)
                        realViewPort_raw = realViewPort_raw.RealViewport;
                    end
                    
                    
                    seconds
                    cu = realViewPort_raw(uN,1:30,:,:);
                    su = 1;
                    maxu = -1;
                    cc = [];
                    %求和当前秒那个用户最接近
                    for user = 1:26
                        ef = 0;
                        if user==uN
                            cc=[cc,-1];
                            continue
                        end
                        pu = realViewPort_raw(user,1:30,:,:);
                        tt = cu.*pu;
                        cou = sum(tt(:))./sum(cu(:));
                        cc = [cc,cou];
                        if cou>maxu
                            maxu=cou;
                            su =user;
                        end
                    end
                    
                    
                    realViewPort_raw2  = uint8(cell2mat(struct2cell(load(['OutputViewportReal/',num2str(videoid),'/',num2str(seconds-2),'_RealViewport.mat']))));
                    if isstruct(realViewPort_raw2)
                        realViewPort_raw2 = realViewPort_raw2.RealViewport;
                    end
                    
                    
                    cu2 = [realViewPort_raw2(uN,tartets:target,:,:)];%,realViewPort_raw3(uN,1:30,:,:)];
                    su2 = 1;
                    maxu2 = -1;
                    cc2 = [];
                    
                    
                    cc2_va = [];
                    %求和前1s那个用户最接近
                    for user = 1:26
                        if user==uN
                            cc2=[cc2,-1];
                            continue
                        end
                        pu2 = [realViewPort_raw2(user,tartets:target,:,:)];%,realViewPort_raw3(user,1:30,:,:)];
                        temp = [];
                        for f = 1:target - tartets+1
                            tt3 = cu2(1,f,:,:).*pu2(1,f,:,:);
                            temp = [temp,sum(tt3(:))/sum(sum(cu2(1,f,:,:)))];
                        end
                        tt2 = cu2.*pu2;
                        cou2 = sum(tt2(:))./sum(cu2(:));
                        cc2_va =[cc2_va,max(temp)-min(temp)];
                        cc2 = [cc2,cou2];
                        if cou2>maxu2
                            maxu2=cou2;
                            su2 =user;
                        end
                    end
                    
                    %求和当前s哪个簇最接近
                    B_sec3 = uint8(reshape(tilingMethod(seconds,:,:,:,:),[clusterNumber(seconds),30,72,144])); %求一下上1s该簇
                    cc4 = [];
                    cu3 = uint8(realViewPort_raw(uN,1:30,:,:));
                    maxu4= -1;
                    for cluster = 1:clusterNumber(seconds)
                        pu3 = [B_sec3(cluster,1:30,:,:)];%,realViewPort_raw3(user,1:30,:,:)];
                        tt3 = cu3.*pu3;
                        cou3 = sum(tt3(:))./sum(cu3(:));
                        cc4 = [cc4,cou3];
                        if cou3>maxu4
                            maxu4 = cou3;
                        end
                    end
                    p = [cc;cc2;cc2_va;double(clusterLst(seconds,1:26)+1)]; %第一行是当前秒的覆盖率，第二行是上一秒的覆盖率，第三行是每个用户属于那一簇
                    
                    [a, b]=sort(cc2,'descend'); %统计和每一簇(因为这里在实现上,p_cluster取了高频率区域所以不好再比较了)的平均相似度
                    similarity = zeros(1,clusterNumber(seconds));
                    for i = 1:length(cc2)
                        similarity(clusterLst(seconds,i)+1) = max(similarity(clusterLst(seconds,i)+1), cc2(i));
                    end
                    %求一下不同类之间的距离
                    B_sec_Real = realViewPort_raw(uN,1:30,:,:);%真实视点
                    B_sec = reshape(tilingMethod(seconds,:,:,:,:),[clusterNumber(seconds),30,72,144]);
                    
                    Distance = zeros(clusterNumber(seconds),clusterNumber(seconds));
                    for i = 1:clusterNumber(seconds)
                        for j = i+1:clusterNumber(seconds)
                            cu = B_sec(i,:,:,:);
                            temp3 = B_sec(j,:,:,:);
                            ju = cu.*temp3;
                            j1 = (cu>ju);
                            j2 = (temp3>ju);
                            Distance(i,j) = sum(j1(:))+sum(j2(:));
                            Distance(j,i) = sum(j1(:))+sum(j2(:));
                        end
                    end
                    
                    
                    
                    
                    p_cluster =[cc4;similarity];
                    
                    
                    result  = [result ,p(1,p(2,:)==max(p(2,:)))]; %这个是寻找最接近的ground truth
                    [~,right] = find(p(2,:)==max(p(2,:)));
                    [a, b] = sort(p(2,:),'descend');
                    right = -1;
                    right2 = -1;
                    for i = 1:length(a) %从第一位开始直到找到第二个不同的类
                        if right==-1
                            right = b(i);
                        end
                        if right~=-1 && right2==-1  &&  clusterLst(seconds,right) ~=  clusterLst(seconds, b(i))
                            right2 =  b(i);
                        end
                    end
                    
                    
                    
                    
                    %                 if 1-p(1,right)>0.7
                    %                     111;
                    %                 end
                    B_sec2 = reshape(tilingMethod(seconds-1,:,:,:,:),[clusterNumber(seconds-1),30,72,144]); %求一下上1s该簇
                    
                    
                    %right = right(end);
                    %直接获取当前用户所属类别
                    temp_Cluster = clusterLst(seconds,1:26) + 1;
                    right_cluster = clusterLst(seconds,right) + 1;
                    right_AllUser = find(temp_Cluster==right_cluster);
                    matching_ratio = p(2,right_AllUser(right_AllUser<27));
                    %首先获取根据前s获取的预测视点，这里是真实的用户视点覆盖矩阵
                    
                    
                   
                    %X_Error =[X_Error,1-cc4(1,right)]; %预测误差
                    
                    
                    
                    
                    %%% 策略2
                    B_cc2  =zeros(72,144);
                    for f =1:30
                        temp = reshape(realViewPort_raw2(uN,f,:,:),[72,144]);
                        %temp3 = reshape(realViewPort_raw3(uN,f,:,:),[72,144]);
                        B_cc2 = B_cc2 | temp;
                    end
                    
                    %策略3
                    realused_User = [right];
                    B_cc3  =uint8(zeros(72,144));
                    [~,y] = size(realused_User);
                    
                    for i = 1:y
                        for f = 1
                            temp2 =  reshape(realViewPort_raw(realused_User(i),f,:,:),[72,144]);
                            B_cc3 = B_cc3 | temp2;
                        end
                    end
                    
                    %策略4,根据相似度，如果多个相似传多个
                    %[a, b] = sort(similarity,'descend');
                    %temp  = (max(a) - a);
                    %                 if(max(a)<0.8)
                    %                     sim_cluster = temp<0.05;
                    %                 else
                    %                     sim_cluster = temp<0.01;
                    %                 end
                    %
                    Idx = kmeans(similarity',3,'Replicates',10);
                    tt = [mean(similarity(Idx==1)),mean(similarity(Idx==2)),mean(similarity(Idx==3))];
                    [a,b] = sort(tt,'descend');
                    
                    sim_cluster = find(Idx==b(1))';%clusterLst(seconds,right2) + 1;
                    B_cc4  =uint8(zeros(72,144));
                    
                    [~,y] = size(sim_cluster);
                    right_cluster2 = clusterLst(seconds,right2) + 1;
                    for i = 1:1  %不只是传最相近的下一簇，还要最相近的i的第二个用户
                        for f = 1:30
                            temp  = reshape(B_sec(right_cluster,f,:,:),[72,144]);
                            temp2 = reshape(B_sec(right_cluster2,f,:,:),[72,144]);
                            temp3 = reshape(realViewPort_raw(right2,f,:,:),[72,144]);
                            B_cc4 = B_cc4 | (temp2>temp);%|temp3;%| (temp2>temp);%|temp3;% |(temp2>temp);% |temp3;%|temp3;%|(temp2>temp);% | (temp2>temp);%|temp3;|
                        end
                    end
                    
                    
                    %下面输出8种可能的传输策略对应的覆盖率
                    %传输策略有4种
                    %1）只传按照视点预测最近的高热度shifttile和对应匹配的shifttile 2）传输当前视点位置
                    %3）将shifttile所有热度的全部传输类别 4）不只是传输和他最匹配的某一类，也传输和他匹配的另外一个类别
                    %1000 1001 1010 1011 1100 1101 1110 1111
                    %共计8种策略，每种方法输出一个可能的覆盖率和像素消耗数量,输入是速度和所有用户的相似性
                    t = 0;
                    
                    i = 0;
                    j = 1;
                    
                    
                    for k = 0:1
                        cover_cont = 0;
                        total_cont = 0;
                        used_cont = 0;
                        t = t + 1;
                        B_robust =zeros(72,144);
                        B_robust2 =zeros(72,144);
                        for f = 1:30
                            temp3 = reshape(B_sec(right_cluster,f,:,:),[72,144]);
                            if sum(sum(uint8(B_cc3).*uint8(temp3)))>200
                                j=1;
                            else
                                j=0;
                            end
                            temp4 = k*B_cc4;
                            B_robust2 = B_robust2 | (j*B_cc3>temp3)&(j*B_cc3>temp4); %一旦选中了，这些都将被变成statictile
                            B_robust = B_robust | temp4;  %((temp4>temp3)&(temp4>j*B_cc3));
                        end
                        for f = 1:30
                            temp3 = reshape(B_sec(right_cluster,f,:,:),[72,144]);
                            temp1 = uint8(1*temp3| B_robust2 | B_robust); %| temp_cc;
                            cont_Shift = cont_Shift + sum(temp1(:));
                            temp2 = reshape(B_sec_Real(1,f,:,:),[72,144]);
                            temp = temp1 .* temp2;
                            cover_cont = cover_cont + sum(sum(temp));
                            total_cont = total_cont + sum(sum(temp2));
                            used_cont = used_cont + sum(sum(temp3));
                        end
                        B_robust_Shift = zeros(15,30);
                        for i = 1:72
                            for j = 1:144
                                if  B_robust(i,j)==1
                                    B_robust_Shift(ceil(i/72*15),ceil(j/144*30))=1; %15*30的
                                end
                            end
                        end
                        B_robust_Shift2 = zeros(15,30);
                        for i = 1:72
                            for j = 1:144
                                if  B_robust2(i,j)==1
                                    B_robust_Shift2(ceil(i/72*15),ceil(j/144*30))=1; %15*30的
                                end
                            end
                        end
                        B_robust_Shift =  B_robust_Shift >B_robust_Shift2; %shift2 是必定传输的，但是shift不一定传输，所以要相减
                        result_ratio{seconds,uN}(1, t) = cover_cont/total_cont;
                        result_ratio2{seconds,uN}(1, t) = (used_cont/30+ + sum(sum(B_robust_Shift2))*23*1.25 + sum(sum(B_robust_Shift))*23*1.25)*0.95;
                    end
                    
                    if max(similarity)<0.7
                        ratio_shift  = [ratio_shift, result_ratio{seconds,uN}(1,2)];
                        cost_shift = [cost_shift,result_ratio2{seconds,uN}(1, 2)];
                    else
                        ratio_shift  = [ratio_shift, result_ratio{seconds,uN}(1,1)];
                        cost_shift = [cost_shift,result_ratio2{seconds,uN}(1, 1)];
                    end
                    %
                    
       
                    data_old = load(['outputvideoClus\',num2str(videoid),'\',num2str(seconds-1),'\',num2str(uN),'_old.txt']);
                    [x, y] = size(data_old);
                    exit_flag = 0;
                    fsize_ClusPredict = 0;
                    clus_sec = uint8(zeros(30,72,144));
                    for i =1:x
                        if (data_old(i,3)>=30)
                            data_old(i,3) = data_old(i,3) -30;
                            data_old(i,4) = data_old(i,4) -30;
                        end
                        for x = 1:72
                            for y = 1:144
                                if  round((x/72)*15)>=data_old(i,1) && round((x/72)*15)<=data_old(i,2)&& round((y/144)*30)<=data_old(i,4)&& round((y/144)*30)>=data_old(i,3)
                                    clus_sec(1:30,x,y) = 1;
                                end
                            end
                        end
                    end
                    
                    
                    B_cc2  = uint8(zeros(72,144));
                    %             for f =1:30
                    %                 temp = reshape(realViewPort_raw2(uN,f,:,:),[72,144]);
                    %                 %temp3 = reshape(realViewPort_raw3(uN,f,:,:),[72,144]);
                    %                 B_cc2 = B_cc2 | temp;
                    %             end
                    %
                    
                    %clustile也加鲁棒性策略
                    realused_User = right;
                    [~,y] = size(realused_User);
                    for i = 1:y
                        for f = 1:30
                            temp2 =  reshape(realViewPort_raw(right,f,:,:),[72,144]);
                            B_cc2 = B_cc2 | temp2;
                        end
                    end
                    %
                    B_cc4  =uint8(zeros(72,144));
                    
                    [~,y] = size(sim_cluster);
                    right_cluster2 = clusterLst(seconds,right2) + 1;
                    for i = 1:1  %不只是传最相近的下一簇，还要最相近的i的第二个用户
                        for f = 1:30
                            temp3 = reshape(realViewPort_raw(right2,f,:,:),[72,144]);
                            B_cc4 = B_cc4 | temp3;%|temp3;%| (temp2>temp);%|temp3;% |(temp2>temp);% |temp3;%|temp3;%|(temp2>temp);% | (temp2>temp);%|temp3;|
                        end
                    end
                    
                    B_robust_temp  = zeros(72,144);
                    cover_cont = 0;
                    total_cont = 0;
                    for f = 1:30
                        temp3 = uint8(reshape(clus_sec(f,:,:),[72,144]));
                        temp_cc = uint8(B_cc2);%用basic块去补一部分
                        temp1 = uint8(uint8(temp3) | uint8(temp_cc));
                        B_opt = max(temp_cc - temp3,0);
                        B_robust_temp = B_robust_temp | B_opt;
                        cont_Clus = cont_Clus + sum(temp1(:));
                        temp2 = reshape(B_sec_Real(1,f,:,:),[72,144]);
                        temp = temp1 .* temp2;
                        cover_cont = cover_cont + sum(sum(temp));
                        total_cont = total_cont + sum(sum(temp2));
                    end
                    
                    if cover_cont / total_cont - ratio_shift(end) >0.5
                        ratio_clus = [ratio_clus,ratio_shift(end)];
                    else
                        ratio_clus = [ratio_clus,cover_cont / total_cont];
                    end
                    
                    B_robust_Clus = zeros(15,30);
                    for i = 1:72
                        for j = 1:144
                            if  B_robust_temp (i,j)==1
                                B_robust_Clus(ceil(i/72*15),ceil(j/144*30))=1; %15*30的
                            end
                        end
                    end
                    
                    cost_clus = [cost_clus, sum(temp3(:)) + sum(B_robust_Clus(:))*23*1.25];
                    X_Error =[X_Error,1-p(1,right)]; %预测误差
                    %result_ratio_clus(seconds,uN) = cover_cont / total_cont;
                    
                    
                    debug = [debug;result_ratio{seconds,uN}(1,1),result_ratio{seconds,uN}(1,2),result_ratio2{seconds,uN}(1,1),result_ratio2{seconds,uN}(1,2),max(similarity)];
                    
                    %debug = [debug, sum(sum(sum(abs(jinyupredictViewport - mypredictViewport))))];
                end
            catch
                continue
            end
        end
        mean(cost_shift)
        mean(cost_clus)
        mean(ratio_shift)
        mean(ratio_clus)
        cost_total_shift = [cost_total_shift,mean(cost_shift)];
        ratio_total_shift = [ratio_total_shift,mean(ratio_shift)];
        cost_total_clus = [cost_total_clus,mean(cost_clus)];
        ratio_total_clus = [ratio_total_clus,mean(ratio_clus) ];
        vid = [vid,videoid];
    catch
        continue
    end
end





