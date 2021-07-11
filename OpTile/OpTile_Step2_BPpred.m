clear all;
close all;
clc;

tic

root = 'dataOpTile';
rootPred = 'OutputPredictionData';
%% 然后对每个C_Input做一次BP，写入C
%载入'BPnet.mat'
load('BPnetOnMultiVideo.mat');%%%
dirVid = dir(rootPred);
dirVid = dirVid(3:end);
parfor vidIndex=1:length(dirVid) %改
    vid=dirVid(vidIndex).name;
    dirSecs = dir([rootPred,'\',vid]);
    dirSecs = dirSecs(3:end);
    for secIndex = 1:length(dirSecs) %改
        sec = dirSecs(secIndex).name;
        
        %C_Input = cell2mat(struct2cell(load([root,'\',vid,'\',sec,'\C_Input.
        %         %%%没有C_Input则跳过
        %         try
        %             C_Input = load([root,'\',num2str(vid),'\',num2str(secIndex),'\C_Input.txt']);
        %         catch
        %             [vid,secIndex,1:5]
        %             continue;
        %         end
        
        %disp([num2str(vid),'\',num2str(secIndex),'\',num2str(clusID)]);
        temp = load([rootPred,'\',vid,'\',sec,'\C_Input.mat']);
        input = cell2mat(struct2cell(temp));
        %选出不是1e8的块来预测，是1e8的挑出来直接赋值MAX
        normalInput = input(input(:,5)<1e7,5:9);
        normalInput=normalInput';
        mapInput = mapminmax('apply',normalInput,setting1);
        mapResult = sim(net,mapInput);
        normalResult = mapminmax('reverse',mapResult,setting2);
        
        normalResult = normalResult';
        
        result = zeros(size(input,1),1);
        result(input(:,5)<1e7,1) = normalResult;
        result(input(:,5)>=1e7,1) = 1e8;
        %小于0的直接
        %result(result(:,1)<input(:,10),1) = 1e8;
        %下限
        for row=1:size(result,1)
            if result(row,1)>1e7
                continue;
            end
            area=(input(row,2)-input(row,1)+1)*(input(row,4)-input(row,3)+1);
            result(row,1)=max(result(row,1),area*input(row,10)*0.5);
        end
        %% 把结果保存到C.txt
        mkdir([root,'\',vid,'\',sec]);
        dlmwrite([root,'\',vid,'\',sec,'\C.txt'], result,' ');
        % fid=fopen([path,'C.txt'],'a');
        % for i=1:length(result)
        %     fprintf(fid,'%f\t',result(i));
        % end
        % fclose(fid);
    end
end

'2 预测'
toc