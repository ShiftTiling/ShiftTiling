clear all;
close all;
clc;

tic

root = 'data';
%% Ȼ���ÿ��C_Input��һ��BP��д��C
%����'BPnet.mat'
load('BPnetOnMultiVideo.mat');%%%
tic
dirVid = dir(root);
dirVid = dirVid(3:end);
for vidIndex=1:length(dirVid) %��
    vid=dirVid(vidIndex).name;
    dirSecs = dir([root,'\',vid]);
    dirSecs = dirSecs(3:end);
    parfor secIndex = 1:length(dirSecs) %��
        sec = dirSecs(secIndex).name;
        
        %C_Input = cell2mat(struct2cell(load([root,'\',vid,'\',sec,'\C_Input.
%         %%%û��C_Input������
%         try
%             C_Input = load([root,'\',num2str(vid),'\',num2str(secIndex),'\C_Input.txt']);
%         catch
%             [vid,secIndex,1:5]
%             continue;
%         end
        
        for clusID = 0:5
            %disp([num2str(vid),'\',num2str(secIndex),'\',num2str(clusID)]);
            temp = load([root,'\',vid,'\',sec,'\',num2str(clusID),'\C_Input.mat']);
            input = cell2mat(struct2cell(temp));
            %ѡ������1e8�Ŀ���Ԥ�⣬��1e8��������ֱ�Ӹ�ֵMAX
            normalInput = input(input(:,5)<1e7,5:9);
            normalInput=normalInput';
            mapInput = mapminmax('apply',normalInput,setting1);
            mapResult = sim(net,mapInput);
            normalResult = mapminmax('reverse',mapResult,setting2);
            
            normalResult = normalResult';
            
            result = zeros(size(input,1),1);
            result(input(:,5)<1e7,1) = normalResult;
            result(input(:,5)>=1e7,1) = 1e8;
            %С��0��ֱ��
            %result(result(:,1)<input(:,10),1) = 1e8;
            %����
            for row=1:size(result,1)
                if result(row,1)>1e7
                    continue;
                end
                area=(input(row,2)-input(row,1)+1)*(input(row,4)-input(row,3)+1);
                result(row,1)=max(result(row,1),area*input(row,10)*0.5);
            end
            %% �ѽ�����浽C.txt
            dlmwrite([root,'\',vid,'\',sec,'\',num2str(clusID),'\C.txt'], result,' ');
            [vid,'\',sec,'\',num2str(clusID)]
            % fid=fopen([path,'C.txt'],'a');
            % for i=1:length(result)
            %     fprintf(fid,'%f\t',result(i));
            % end
            % fclose(fid);
        end
    end
end

'3 Ԥ������'
toc
