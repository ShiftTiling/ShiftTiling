clear all;
close all;
clc;
root = 'C:\Users\DELL\Desktop\ClusTile_impl_divideTrainSet\data\1';

%% 然后对每个C_Input做一次BP，写入C
%载入'BPnet.mat'
load('BPnet.mat');
for secID = 11:11%8:11
% 加载数据
    input = load(['data\1\',num2str(secID),'\C_Input.txt']);
        %选出不是1e8的块来预测，是1e8的挑出来直接赋值MAX
        normalInput = input(input(:,11)<1e7,5:9);
        normalInput=normalInput';
        mapInput = mapminmax('apply',normalInput,mapTrainInputPS);
        mapResult = sim(net,mapInput);
        normalResult = mapminmax('reverse',mapResult,mapTrainOutputPS);
        
        normalResult = normalResult';
        
        result = zeros(size(input,1),1);
        result(input(:,11)<1e7,1) = normalResult;
        result(input(:,11)>=1e7,1) = 1e8;
        %% 把结果保存到C.txt
        % fid=fopen([path,'C.txt'],'a');
        % for i=1:length(result)
        %     fprintf(fid,'%f\t',result(i));
        % end
        % fclose(fid);
        temp=input(:,11)<1e7;
        scatter(input(temp,11),result(temp));
end
