function [] = OpTile_SegFunction(vid)

%Lingo��װλ��
LingoPath = 'C:\Program Files\Lingo'; %��

%% ������ÿ��video/sec/cluster
% �����Ǿ���·������ΪҪ��lingo��
rootBNMC = 'OutputBNMC';
root = 'D:\archive2\INFOCOM2020\code\ClusTileNew\dataOpTile'; %��
rootCInput = 'OutputPredictionData';

% timeP1=0;
% timeP2=0;
% timeILP = 0;
% tic


dirSecs = dir([root,'\',vid]);
dirSecs = dirSecs(3:end);
%debug
for secIndex = 1:length(dirSecs) %��
    sec = dirSecs(secIndex).name;

    
    secPath = [root,'/',vid,'/',sec];
    %time=toc;
    %try
    
    %
    T = 53685; %%%%%%%%%%
    BT = 450;
    C_Input=cell2mat(struct2cell(load([rootCInput,'/',vid,'/',sec,'/C_Input.mat'])));
    Index=zeros(15,15,30,30);
    for i=1:T
        Index(C_Input(i,1),C_Input(i,2),C_Input(i,3),C_Input(i,4))=i;
    end
    
    if ~exist([root,'\M.txt'])
        globalM = zeros(BT,T);
        for i=1:T
            board=zeros(15,30);
            board(C_Input(i,1):C_Input(i,2),C_Input(i,3):C_Input(i,4))=1;
            globalM(:,i)=board(:);
        end
        dlmwrite([root,'/M.txt'],globalM);
    end
    
    % ��Ҫ����������ȡ��һ����ͬ��N
    globalN = zeros(T,1);
    gatherB = zeros(15,30,40);
    nUser=0;
    % ��Ϊ���û���B�������
    for clusID=0:5
        load([rootBNMC,'/',vid,'/',sec,'/',num2str(clusID),'.mat']);
        for u=1:size(B_PerUser,1)
            nUser=nUser+1;
            quadB = reshape(B_PerUser(u,:),Extra(4)-Extra(3)+1,Extra(2)-Extra(1)+1)';
            gatherB(Extra(1)+1:Extra(2)+1,mod(Extra(3):Extra(4),30)+1,nUser)=quadB;
        end
    end
    
    % Ȼ��������db��
    for i=1:size(C_Input,1)
        n=0;
        for u=1:nUser
            n=n+(max(max(gatherB(C_Input(i,1):C_Input(i,2),C_Input(i,3):C_Input(i,4),u)))>=1);
        end
        globalN(i)=n;
    end
    
    %д��txt��Lingoʹ��
    dlmwrite([root,'/',vid,'/',sec,'/N.txt'],globalN);
    
    
    %% ���һ��ILP��ILP_CLUS
    % 'SET MXMEMB 2048' 10 ...
    string_ILP_CLUS = ['SET ECHOIN 0' 10 ... %�ص��������
        'SET TERSEO 1' 10 ... %�ص�����
        'model:' 10 'data:' 10 ' amount_bt=',num2str(BT),';' 10 ' amount_t=',num2str(T) ...
        ';' 10 ' amount_user=',num2str(nUser), ';' 10 'enddata' 10 10 ...
        'sets:' 10 ' mat_n/1..amount_t/: data_N;' 10 ...
        ' mat_m_row/1..amount_bt/;' 10 ' mat_m_col/1..amount_t/;' 10 ' mat_m(mat_m_row,mat_m_col):data_M;' 10 ...
        ' mat_c/1..amount_t/: data_C;' 10 ' mat_x/1..amount_t/: X;' 10 'endsets' 10 10 'data:' 10 ...
        ' data_C=@file(''',secPath,'/C.txt'');' 10 ...
        ' data_N=@file(''',secPath,'/N.txt'');' 10 ...
        ' data_M=@file(''',root,'/M.txt'');' 10 ...
        ' @text(''',secPath,'/X.txt'')=X;' 10 ...
        'enddata' 10 10 ...
        '@for(mat_x(i):@BIN(X(i)));' 10 ...
        'min=@sum(mat_x(i): data_C(i)*(1+1/amount_user*data_N(i))*X(i));' 10 ...
        '@for(mat_m_row(i):' 10 ...
        ' @sum(mat_m_col(j):data_M(i,j)*X(j))=1' 10 ');' 10 ...
        'end' 10 'GO' 10];
    dlmwrite([secPath,'/','ILP_CLUS.ltf'],string_ILP_CLUS,'');
    
    %��д����������Lingoִ�нű�
    string_ILP_CLUS_run = [LingoPath(1:2) 10 ...
        'cd ',LingoPath(4:end) 10 ...
        'runlingo ',secPath,'/','ILP_CLUS.ltf' 10 ...
        'exit'];
    dlmwrite([secPath,'/','ILP_CLUS_run.bat'],string_ILP_CLUS_run,'');
    
    %�ȴ�����һ��X.txt,Ȼ������
    dlmwrite([secPath,'/','X.txt'],[]);
    %timeP2=timeP2+toc-time;
    %time = toc;
    [~,~]=dos([secPath,'/','ILP_CLUS_run.bat']);
    %timeILP = timeILP + toc-time;
    X=load([secPath,'/','X.txt']);
    infoX = C_Input(X==1,1:4);
    save(['..\method\OpTile\',vid,'_',sec,'.mat'],'infoX');
    %disp(['PASS ILP_CLUS ',num2str(vid),'/',secID,'/',num2str(clus)]);
    [vid,' ',sec]
end
end