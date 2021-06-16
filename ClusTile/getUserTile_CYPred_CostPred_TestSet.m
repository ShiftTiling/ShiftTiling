clear all;
close all;
clc;


maxTileAmountPerClus = 10;

%Lingo安装位置
LingoPath = 'C:\Program Files\Lingo';

%% 逐层访问每个video/sec/cluster
rootPath = 'C:\Users\DELL\Desktop\ClusTile_impl_divideTrainSet\data';
predPath = 'C:\Users\DELL\Desktop\ClusTile_impl_divideTrainSet\trajectoryDataLR\OutputViewportPredCrossUser';%%%
resultPath = 'C:\Users\DELL\Desktop\ClusTile_impl_divideTrainSet\ResultInCYPred';%%%
mkdir(resultPath);

videoDirs = dir(rootPath);
TestDataIndex = [];
ratioSum=0;
nSum=0;
timeCost=0;for vid = 1:45
    mkdir([resultPath,'/',num2str(vid)]);
    secDirs = dir([rootPath,'/',num2str(vid)]);
    
    for sec=1:60
        secPath = [rootPath,'\',num2str(vid),'\',num2str(sec)];
        
         %%%没有C_Input则跳过
        try
            C_Input = load([rootPath,'\',num2str(vid),'\',num2str(sec),'\C_Input.txt']);
        catch
            [num2str(vid),num2str(sec)]
            continue;
        end
        
        

        disp(['video ',num2str(vid),'  sec ',num2str(sec)]);
        mkdir([resultPath,'/',num2str(vid),'/',num2str(sec)]);
        

        temp2 = load(['C:\Users\DELL\Desktop\ClusTile_impl_divideTrainSet\trajectoryDataLR\OutputViewportReal_72_144/',num2str(vid),'/',num2str(sec),'_RealViewport.mat']);
        realViewPort_raw = uint8(cell2mat(struct2cell(temp2)));
        if isstruct( realViewPort_raw )
            realViewPort_raw = realViewPort_raw.RealViewport;
        end
        [userNumber,~] = size(realViewPort_raw);
        
        temp = load([predPath,'\',num2str(vid),'\',num2str(sec),'_Best_MatchUser.mat']);%%%
        temp = temp.best_matching_user;
        predMat = temp(TestDataIndex);
   
        mkdir([rootPath,'/',num2str(vid),'/',num2str(sec),'/UserResultOld']);
        %% 开始对video/sec/clus中所有用户遍历
        for userID= TestDataIndex

            maxIntersectionClus = -1;
            %find uid clus
            mUid = predMat(userID)
            for clus = 0:4
                temp = load([rootPath,'/',num2str(vid),'/',num2str(sec),'/',num2str(clus),'/UserLst.txt']);
                if sum(temp+1==mUid)>0
                    maxIntersectionClus = clus;
                    break;
                end
            end
            

            
            maxIntersectionClusPath = [rootPath,'/',num2str(vid),'/',num2str(sec),'/',num2str(maxIntersectionClus)];
            B = load([maxIntersectionClusPath,'/B.txt']);
            basicTileAmountOld = length(B);
            X = load([maxIntersectionClusPath,'/X.txt']);
            tileAmountOld = length(X);
            string_ILP_USER = ['SET ECHOIN 0' 10 ... %关掉变量输出
                'SET TERSEO 1' 10 ... %关掉报告
                'model:' 10 'data:' 10 ' amount_bt=',num2str(basicTileAmountOld),';' 10 ' amount_t=',num2str(tileAmountOld)...
                ';' 10 'enddata' 10 10 ...
                'sets:' 10 ' mat_b/1..amount_bt/: data_B;' 10 ...
                ' mat_m_row/1..amount_bt/;' 10 ' mat_m_col/1..amount_t/;' 10 ' mat_m(mat_m_row,mat_m_col):data_M;' 10 ...
                ' mat_c/1..amount_t/: data_C;' 10 ' mat_x/1..amount_t/: data_X;' 10 ...
                ' mat_xu/1..amount_t/: Xu;' 10 'endsets' 10 10 'data:' 10 ...
                ' data_C=@file(''',maxIntersectionClusPath,'/C.txt'');' 10 ...
                ' data_B=@file(''',[rootPath,'/',num2str(vid),'/',num2str(sec),'/',num2str(maxIntersectionClus),'/User/',num2str(mUid-1),'.txt'],''');' 10 ...
                ' data_X=@file(''',maxIntersectionClusPath,'/X.txt'');' 10 ...
                ' data_M=@file(''',maxIntersectionClusPath,'/M.txt'');' 10 ...
                ' @text(''',[rootPath,'/',num2str(vid),'/',num2str(sec),'/UserResultOld/',num2str(userID),'.txt'],''')=Xu;' 10 ...%%%userID从1开始
                'enddata' 10 10 ...
                'min=@sum(mat_c(i): data_C(i)*Xu(i));' 10 10 ...
                '@for(mat_xu(i):Xu(i)<=data_X(i));' 10 ...
                '@for(mat_m_row(i):' 10 ' @sum(mat_m_col(j):data_M(i,j)*Xu(j))>=data_B(i)' 10 ');' 10 10 ...
                'end' 10 'GO' 10];
            dlmwrite([secPath,'\','ILP_USER.ltf'],string_ILP_USER,''); %重复利用
                 string_ILP_USER_run = [LingoPath(1:2) 10 ...
                'cd ',LingoPath(4:end) 10 ...
                'runlingo ',secPath,'/ILP_USER.ltf' 10 ...
                'exit'];
            dlmwrite([secPath,'/','ILP_USER_run.bat'],string_ILP_USER_run,'');%还是存在clusPath中而不是max...clus...
            
            tic
          
            dlmwrite([rootPath,'/',num2str(vid),'/',num2str(sec),'/UserResultOld/',num2str(userID),'.txt'],[]);
            disp(['ILP_USER ',num2str(vid),'/',num2str(sec),'/',num2str(userID)]);
            [s,e]=dos([secPath,'/','ILP_USER_run.bat']);
            
             
            
            B_userOld = load([rootPath,'/',num2str(vid),'/',num2str(sec),'/UserResultOld/',num2str(userID),'.txt']);
            C_InputOld = load([rootPath,'/',num2str(vid),'/',num2str(sec),'/',num2str(maxIntersectionClus),'/C_Input.txt']);
            COld = load([rootPath,'/',num2str(vid),'/',num2str(sec),'/',num2str(maxIntersectionClus),'/C.txt']);
            choosenTileOldInfo = C_InputOld(B_userOld==1,1:4);
            dlmwrite([resultPath,'/',num2str(vid),'/',num2str(sec),'/',num2str(userID),'_old.txt'],[choosenTileOldInfo,COld(B_userOld==1)],' ');
            
            timeCost = timeCost+toc;
        end
    end
end