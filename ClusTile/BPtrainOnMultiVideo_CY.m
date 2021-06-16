clear all;
close all;
clc;
trainInput = [];
trainOutput = [];
root='C:\Users\DELL\Desktop\ClusTile_impl_divideTrainSet\OutputTraingData';

for vid = 1:10
    for sec = 1:60
        temp = load([root,'\',num2str(vid),'\',num2str(sec),'\C_Input.txt']);
        trainInput = [trainInput;temp(temp(:,11)<999999,[5,6,7,8,9])];
        trainOutput = [trainOutput;temp(temp(:,11)<999999,11)];
    end
end


trainData = trainInput;
trainLabel = trainOutput;
[input,setting1] = mapminmax(trainData');
[output,setting2] = mapminmax(trainLabel');

net = feedforwardnet([50,50],'trainscg');
% Setup Division of Data for Training, Validation, Testing
net.divideParam.trainRatio = 0.8;
net.divideParam.valRatio = 0.1;
net.divideParam.testRatio = 0.1;
net.trainParam.max_fail=100000;
net.trainParam.epochs=100000;  % max epochs
net.trainParam.goal=0.00000001;  % training goal
net.performFcn = 'mse';
net.plotFcns = {'plotperform','plottrainstate','ploterrhist', ...
  'plotregression', 'plotfit'};
[net,tr] = train(net,input,output);%,'useGPU','yes');
output_net = net(input);
performance = perform(net,output,output_net);  % 根据设定的net.performFcn
% Recalculate Training, Validation and Test Performance获得训练验证和测试的结果
trainTargets = output.* tr.trainMask{1};
valTargets = output.* tr.valMask{1};
testTargets = output.* tr.testMask{1};
trainPerformance = perform(net,trainTargets,output_net)
valPerformance = perform(net,valTargets,output_net)
testPerformance = perform(net,testTargets,output_net)
%% 测试

BPoutput = mapminmax('reverse',output_test,setting2);

trainOutput = mapminmax('reverse',output_net(trainTargets<=2),setting2);
plot(trainOutput,trainLabel(trainTargets<=2),'ro')
xlim([0,1])
ylim([0,1])
[trainOutput',trainLabel(trainTargets<=2)]

save('BPnetOnMultiVideo.mat','net','setting1','setting2');
