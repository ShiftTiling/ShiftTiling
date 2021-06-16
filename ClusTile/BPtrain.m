clear all;
close all;
clc;
%% ��ÿһ��(3��ǰ�Ĳ���Ԥ��
trainInput = [];
trainOutput = [];
for secID=0:7
% ��������
    temp = load(['data\1\',num2str(secID),'\C_Input.txt']);
    trainInput = [trainInput;temp(temp(:,11)<999999,[5,6,7,8,9])];
    trainOutput = [trainOutput;temp(temp(:,11)<999999,11)];
end
trainInput=trainInput';
trainOutput=trainOutput';

%% ʹ��׼���õ�ѵ���������Լ�


%��һ��
[mapTrainInput,mapTrainInputPS] = mapminmax(trainInput);
[mapTrainOutput,mapTrainOutputPS] = mapminmax(trainOutput);
%mapTestInput = mapminmax('apply',testInput,mapTrainInputPS);

%%
%����BP�����磬���ò���
net = newff(minmax(mapTrainInput),[10,50,1],{'tansig','tansig','purelin'},'trainlm');
net.trainParam.epochs=200;%��������
net.trainParam.lr=0.01;%ѧϰ����
net.trainParam.goal=0.000250;%Ŀ�����


%%
net=train(net,mapTrainInput,mapTrainOutput);

%% ����
save('BPnet.mat','net','mapTrainInputPS','mapTrainOutputPS');

% load BPnet.mat;
% % ����ѵ��Ч��
% mapResult = sim(net,mapTrainInput);
% result = mapminmax('reverse',mapResult,mapTrainOutputPS);
% 
% scatter(trainOutput,result)