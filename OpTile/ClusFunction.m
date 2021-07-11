function [] = ClusFunction(vid)

%ÿ��cluster��� ����ʹ�õ�tile
maxTileAmountPerClus = 10;

%Lingo��װλ��
LingoPath = 'C:\Program Files\Lingo'; %��

%% ������ÿ��video/sec/cluster
% �����Ǿ���·������ΪҪ��lingo��
rootBNMC = 'OutputBNMC';
root = 'D:\archive2\INFOCOM2020\code\ClusTileNew\data'; %��

% timeP1=0;
% timeP2=0;
% timeILP = 0;
% tic


dirSecs = dir([root,'\',vid]);
dirSecs = dirSecs(3:end);
for secIndex = 1:length(dirSecs)
    sec = dirSecs(secIndex).name;
    %�������Ķ���
    %disp(['video ',num2str(vid),'  secID ',secID]);
    %mkdir([resultPath,'/',num2str(vid),'/',secID]);
    %time=toc;
    %%û��C_Input������
    %     try
    %         if ~exist([rootPath,'\',num2str(vid),'\',secID,'\C_Input.mat'],'file')
    %             C_Input = load([rootPath,'\',num2str(vid),'\',secID,'\C_Input.txt']);
    %             save([rootPath,'\',num2str(vid),'\',secID,'\C_Input.mat'],'C_Input');
    %         else
    %             load([rootPath,'\',num2str(vid),'\',secID,'\C_Input.mat']);
    %         end
    %     catch
    %         [num2str(vid), secID]
    %         continue;
    %     end
    %timeP1 = timeP1+toc-time;
    
    for clusID = 0:5
        %             fid = fopen(['C:\Users\DELL\Desktop\ClusTile_impl_divideTrainSet\data\',num2str(vid),'\',num2str(sec),'\',num2str(clus),'\X.txt']);
        %             fseek(fid,0,'eof');
        %             fsize = ftell(fid);
        %             fclose(fid);
        %             if ~fsize==0
        %                 continue;
        %             end
        [vid,sec,clusID]
        %             %D
        %             if strcmp(secID,'6')~=1||strcmp(num2str(clus),'0')~=1
        %                 continue;
        %             end
        clusPath = [root,'/',vid,'/',sec,'/',num2str(clusID)];
        %time=toc;
        %try
        
        C_Input=cell2mat(struct2cell(load([clusPath,'\C_Input.mat'])));
        load([rootBNMC,'/',vid,'/',sec,'/',num2str(clusID),'.mat']);
        %д��txt��Lingoʹ��
        dlmwrite([root,'/',vid,'/',sec,'/',num2str(clusID),'/B.txt'],B);
        dlmwrite([root,'/',vid,'/',sec,'/',num2str(clusID),'/N.txt'],N);
        dlmwrite([root,'/',vid,'/',sec,'/',num2str(clusID),'/M.txt'],M);
        basicTileAmount = length(B);
        %         if 1%~exist([rootPath,'/',num2str(vid),'/',secID,'/',num2str(clus),'/C_Input.mat'],'file')
        %             C_Input = load([rootPath,'/',num2str(vid),'/',secID,'/',num2str(clusID),'/C_Input.txt']);
        %             save([rootPath,'/',num2str(vid),'/',secID,'/',num2str(clusID),'/C_Input.mat'],'C_Input');
        %         else
        %             load([rootPath,'/',num2str(vid),'/',secID,'/',num2str(clus),'/C_Input.mat']);
        %         end
        load([root,'/',vid,'/',sec,'/',num2str(clusID),'/C_Input.mat']);
        tileAmount = size(C_Input,1);
        %             catch
        %                 continue;
        %             end
        %% ���һ��ILP��ILP_CLUS
        % 'SET MXMEMB 2048' 10 ...
        string_ILP_CLUS = ['SET ECHOIN 0' 10 ... %�ص��������
            'SET TERSEO 1' 10 ... %�ص�����
            'model:' 10 'data:' 10 ' amount_bt=',num2str(basicTileAmount),';' 10 ' amount_t=',num2str(tileAmount)...
            ';' 10 ' amount_max_t=',num2str(maxTileAmountPerClus), ';' 10 'enddata' 10 10 ...
            'sets:' 10 ' mat_b/1..amount_bt/: data_B;' 10 ' mat_n/1..amount_t/: data_N;' 10 ...
            ' mat_m_row/1..amount_bt/;' 10 ' mat_m_col/1..amount_t/;' 10 ' mat_m(mat_m_row,mat_m_col):data_M;' 10 ''...
            ' mat_c/1..amount_t/: data_C;' 10 ' mat_x/1..amount_t/: X;' 10 'endsets' 10 10 'data:' 10 ...
            ' data_C=@file(''',clusPath,'/C.txt'');' 10 ''...
            ' data_B=@file(''',clusPath,'/B.txt'');' 10 ''...
            ' data_N=@file(''',clusPath,'/N.txt'');' 10 ''...
            ' data_M=@file(''',clusPath,'/M.txt'');' 10 ''...
            ' @text(''',clusPath,'/X.txt'')=X;' 10 ''...
            'enddata' 10 10 '@for(mat_x(i):@BIN(X(i)));' 10 'min=@sum(mat_c(i): data_C(i)*data_N(i)*X(i));' 10 ''...
            '@for(mat_m_row(i):' 10 ' @sum(mat_m_col(j):data_M(i,j)*X(j))>=data_B(i)' 10 ');' 10 ...
            '@sum(mat_x(i):X(i))<=amount_max_t;' 10 10 ...
            'end' 10 'GO' 10];
        dlmwrite([clusPath,'/','ILP_CLUS.ltf'],string_ILP_CLUS,'');
        
        %��д����������Lingoִ�нű�
        string_ILP_CLUS_run = [LingoPath(1:2) 10 ...
            'cd ',LingoPath(4:end) 10 ...
            'runlingo ',clusPath,'/','ILP_CLUS.ltf' 10 ...
            'exit'];
        dlmwrite([clusPath,'/','ILP_CLUS_run.bat'],string_ILP_CLUS_run,'');
        
        %�ȴ�����һ��X.txt,Ȼ������
        dlmwrite([clusPath,'/','X.txt'],[]);
        %timeP2=timeP2+toc-time;
        %time = toc;
        [~,~]=dos([clusPath,'/','ILP_CLUS_run.bat']);
        %timeILP = timeILP + toc-time;
        X=load([clusPath,'/','X.txt']);
        infoX = C_Input(X==1,1:4);
        save(['..\method\ClusTile\',vid,'_',sec,'_',num2str(clusID),'.mat'],'infoX');
        %disp(['PASS ILP_CLUS ',num2str(vid),'/',secID,'/',num2str(clus)]);
    end
end