clear all;
close all;
clc;


load BPnet.mat;
maxTileAmountPerClus = 10;
LingoPath = 'C:\Program Files\Lingo';
rootPath = 'C:\Users\DELL\Desktop\ClusTile_impl_divideTrainSet\data';
predPath = 'C:\Users\DELL\Desktop\ClusTile_impl_divideTrainSet\trajectoryDataLR\OutputViewportPredCrossUser\1';%%%
resultPath = 'C:\Users\DELL\Desktop\ClusTile_impl_divideTrainSet\ResultInCrossUserPred';%%%
mkdir(resultPath);

videoDirs = dir(rootPath);
TesdDataIndex=[];
ratioSum=0;
nSum=0;

for i=3:length(videoDirs)
    videoID = videoDirs(i).name;
    mkdir([resultPath,'/',videoID]);
    secDirs = dir([rootPath,'/',videoID]);
    
    for j=1:60
        secID = num2str(j);%secDirs(j).name;
        disp(['video ',videoID,'  secID ',secID]);
        mkdir([resultPath,'/',videoID,'/',secID]);

        predMat = load([predPath,'\',num2str(j),'_mUids.mat']);
        predMat = predMat.mUids;
     
        mkdir([rootPath,'/',videoID,'/',num2str(j),'/UserResultOld']);
        for userID=TesdDataIndex

            mUid = predMat(userID);
            for clus = 0:4
                temp = load([rootPath,'/',videoID,'/',num2str(j),'/',num2str(clus),'/UserLst.txt']);
                if sum(temp+1==mUid)>0
                    maxIntersectionClus = clus;
                    break;
                end
            end
            maxIntersectionClusPath = [rootPath,'/',videoID,'/',num2str(j),'/',num2str(maxIntersectionClus)];
            basicTileAmountOld = length(load([maxIntersectionClusPath,'/B.txt']));
            tileAmountOld = length(load([maxIntersectionClusPath,'/X.txt']));
            string_ILP_USER = ['SET ECHOIN 0' 10 ... 
                'SET TERSEO 1' 10 ... 
                'model:' 10 'data:' 10 ' amount_bt=',num2str(basicTileAmountOld),';' 10 ' amount_t=',num2str(tileAmountOld)...
                ';' 10 'enddata' 10 10 ...
                'sets:' 10 ' mat_b/1..amount_bt/: data_B;' 10 ...
                ' mat_m_row/1..amount_bt/;' 10 ' mat_m_col/1..amount_t/;' 10 ' mat_m(mat_m_row,mat_m_col):data_M;' 10 ...
                ' mat_c/1..amount_t/: data_C;' 10 ' mat_x/1..amount_t/: data_X;' 10 ...
                ' mat_xu/1..amount_t/: Xu;' 10 'endsets' 10 10 'data:' 10 ...
                ' data_C=@file(''',maxIntersectionClusPath,'/C.txt'');' 10 ...
                ' data_B=@file(''',[rootPath,'/',videoID,'/',num2str(j),'/',num2str(maxIntersectionClus),'/User/',num2str(mUid-1),'.txt'],''');' 10 ...
                ' data_X=@file(''',maxIntersectionClusPath,'/X.txt'');' 10 ...
                ' data_M=@file(''',maxIntersectionClusPath,'/M.txt'');' 10 ...
                ' @text(''',[rootPath,'/',videoID,'/',num2str(j),'/UserResultOld/',num2str(userID),'.txt'],''')=Xu;' 10 ...
                'enddata' 10 10 ...
                'min=@sum(mat_c(i): data_C(i)*Xu(i));' 10 10 ...
                '@for(mat_xu(i):Xu(i)<=data_X(i));' 10 ...
                '@for(mat_m_row(i):' 10 ' @sum(mat_m_col(j):data_M(i,j)*Xu(j))>=data_B(i)' 10 ');' 10 10 ...
                'end' 10 'GO' 10];
            dlmwrite('ILP_USER.ltf',string_ILP_USER,'');
            

            string_ILP_USER_run = [LingoPath(1:2) 10 ...
                'cd ',LingoPath(4:end) 10 ...
                'runlingo ','ILP_USER.ltf' 10 ...
                'exit'];
            dlmwrite('ILP_USER_run.bat',string_ILP_USER_run,'');

            dlmwrite([rootPath,'/',videoID,'/',num2str(j),'/UserResultOld/',num2str(userID),'.txt'],[]);
            disp(['ILP_USER ',videoID,'/',secID,'/',num2str(userID)]);
            [s,e]=dos('ILP_USER_run.bat');
            
             
            
            B_userOld = load([rootPath,'/',videoID,'/',num2str(j),'/UserResultOld/',num2str(userID),'.txt']);
            C_InputOld = load([rootPath,'/',videoID,'/',num2str(j),'/',num2str(maxIntersectionClus),'/C_Input.txt']);
            COld = load([rootPath,'/',videoID,'/',num2str(j),'/',num2str(maxIntersectionClus),'/C.txt']);
            choosenTileOldInfo = C_InputOld(B_userOld==1,1:4);
            %
            dlmwrite([resultPath,'/',videoID,'/',secID,'/',num2str(userID),'_old.txt'],[choosenTileOldInfo,COld(B_userOld==1)],' ');
            
            
        end
    end
end
