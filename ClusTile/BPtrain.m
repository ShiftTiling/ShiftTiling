clear all;
close all;
clc;
%% 对每一秒(3秒前的不用预测
trainInput = [];
trainOutput = [];
for secID=0:7
% 加载数据
    temp = load(['data\1\',num2str(secID),'\C_Input.txt']);
    trainInput = [trainInput;temp(temp(:,11)<999999,[5,6,7,8,9])];
    trainOutput = [trainOutput;temp(temp(:,11)<999999,11)];
end
trainInput=trainInput';
trainOutput=trainOutput';

%% 使用准备好的训练集、测试集


%归一化
[mapTrainInput,mapTrainInputPS] = mapminmax(trainInput);
[mapTrainOutput,mapTrainOutputPS] = mapminmax(trainOutput);
%mapTestInput = mapminmax('apply',testInput,mapTrainInputPS);

%%
%创建BP神经网络，设置参数
net = newff(minmax(mapTrainInput),[10,50,1],{'tansig','tansig','purelin'},'trainlm');
net.trainParam.epochs=200;%迭代次数
net.trainParam.lr=0.01;%学习速率
net.trainParam.goal=0.000250;%目标误差


%%
net=train(net,mapTrainInput,mapTrainOutput);

%% 保存
save('BPnet.mat','net','mapTrainInputPS','mapTrainOutputPS');

% load BPnet.mat;
% % 看看训练效果
% mapResult = sim(net,mapTrainInput);
% result = mapminmax('reverse',mapResult,mapTrainOutputPS);
% 
% scatter(trainOutput,result)