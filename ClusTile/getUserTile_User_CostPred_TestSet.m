clear all;
close all;
clc;

maxTileAmountPerClus = 10;
LingoPath = 'C:\Program Files\Lingo';

rootPath = 'C:\Users\DELL\Desktop\ClusTile_impl_divideTrainSet\data';
%predPath = 'C:\Users\DELL\Desktop\ClusTile_impl_divideTrainSet\trajectoryDataLR\OutputViewportPredCrossUser';%%%
resultPath = 'C:\Users\DELL\Desktop\ClusTile_impl_divideTrainSet\ResultInUsers';%%%
mkdir(resultPath);

videoDirs = dir(rootPath);

ratioSum=0;
nSum=0;
timeCost=0;

for vid = 1:45
    mkdir([resultPath,'/',num2str(vid)]);
    secDirs = dir([rootPath,'/',num2str(vid)]);
    
    for sec=1:60
        secPath = [rootPath,'\',num2str(vid),'\',num2str(sec)];
        


        disp(['video ',num2str(vid),'  sec ',num2str(sec)]);
        mkdir([resultPath,'/',num2str(vid),'/',num2str(sec)]);
        

     
        mkdir([rootPath,'/',num2str(vid),'/',num2str(sec),'/UserResultOld']);
        for clus = 0:4
            clusPath = [rootPath,'\',num2str(vid),'\',num2str(sec),'\',num2str(clus)];
            clusDir = dir([clusPath,'\User']);
            for user = 3:length(clusDir)
                userID = clusDir(user).name;
                userID = str2num(userID(1:end-3));
        
                
                B = load([clusPath,'/B.txt']);
                basicTileAmountOld = length(B);
                X = load([clusPath,'/X.txt']);
                tileAmountOld = length(X);
                string_ILP_USER = ['SET ECHOIN 0' 10 ... 
                    'SET TERSEO 1' 10 ... 
                    'model:' 10 'data:' 10 ' amount_bt=',num2str(basicTileAmountOld),';' 10 ' amount_t=',num2str(tileAmountOld)...
                    ';' 10 'enddata' 10 10 ...
                    'sets:' 10 ' mat_b/1..amount_bt/: data_B;' 10 ...
                    ' mat_m_row/1..amount_bt/;' 10 ' mat_m_col/1..amount_t/;' 10 ' mat_m(mat_m_row,mat_m_col):data_M;' 10 ...
                    ' mat_c/1..amount_t/: data_C;' 10 ' mat_x/1..amount_t/: data_X;' 10 ...
                    ' mat_xu/1..amount_t/: Xu;' 10 'endsets' 10 10 'data:' 10 ...
                    ' data_C=@file(''',clusPath,'/C.txt'');' 10 ...
                    ' data_B=@file(''',[clusPath,'/User/',num2str(userID),'.txt'],''');' 10 ...
                    ' data_X=@file(''',clusPath,'/X.txt'');' 10 ...
                    ' data_M=@file(''',clusPath,'/M.txt'');' 10 ...
                    ' @text(''',[rootPath,'/',num2str(vid),'/',num2str(sec),'/UserResultOld/',num2str(userID),'.txt'],''')=Xu;' 10 ...%%%userID从1开始
                    'enddata' 10 10 ...
                    'min=@sum(mat_c(i): data_C(i)*Xu(i));' 10 10 ...
                    '@for(mat_xu(i):Xu(i)<=data_X(i));' 10 ...
                    '@for(mat_m_row(i):' 10 ' @sum(mat_m_col(j):data_M(i,j)*Xu(j))>=data_B(i)' 10 ');' 10 10 ...
                    'end' 10 'GO' 10];
                dlmwrite([secPath,'\','ILP_USER.ltf'],string_ILP_USER,''); 
                
    
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
                C_InputOld = load([clusPath,'/C_Input.txt']);
                COld = load([clusPath,'/C.txt']);
                choosenTileOldInfo = C_InputOld(B_userOld==1,1:4);
                %
                dlmwrite([resultPath,'/',num2str(vid),'/',num2str(sec),'/',num2str(userID),'_old.txt'],[choosenTileOldInfo,COld(B_userOld==1)],' ');
                
                timeCost = timeCost+toc;
            end
        end
    end
end