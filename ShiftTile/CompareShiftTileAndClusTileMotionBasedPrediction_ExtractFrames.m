
clc;
clear all;
close all;

Height = 1440;     %֡�߶�
Width = 2880;     %֡���
V_Height = (Height/180*100)/2-1;%�Ӵ��߶�
V_Width = (Width/360*100)/2-1; %�Ӵ����
BasicWidth = 20;   %BasicTile���
UserNumber = 30;   %�û�����
frameGap = 30;     %֡�� 30fps
H = Height / BasicWidth; %���ж���BasicTile
W = Width / BasicWidth;  %���ж���BasicTile
vs = 1;             %��Ƶ��ʼid
ve = 1;             %��Ƶ����id
for videoid = VideoIndex
    matData2 = load(['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\LoadRawData\',num2str(frameGap),'_ShiftTile_Opt/' , num2str(videoid) , '.mat']);
    tilingMethod = matData2.Method;
    clusterNumber = matData2.clusterNumber;
    wasteRatio =  matData2.Performace;
    vid = sprintf('%03d', videoid);
    [~, totalseconds] = size(wasteRatio);
    for seconds = SecondIndex
       % try
            for qp = 22:22
                for c = 1:clusterNumber
                    [num2str(c),' clusters ',num2str(seconds-1),' seconds']
                    mkdir(['OutputFrame_ShiftTileOptimization_AfterEncoded/',num2str(videoid),'/',num2str(seconds-1),'/',num2str(c),'/']);
                    command = ['ffmpeg -i outputVideoShift/',num2str(videoid),'/out_',num2str(c),'_',num2str(seconds-1),'_0.mp4 -r 30 -q:v 2 -f image2 ','OutputFrame_ShiftTileOptimization_AfterEncoded/',num2str(videoid),'/',num2str(seconds-1),'/',num2str(c),'/','%d.png']
                    system(command);
                    
                end
            end
%         catch
%             continue
%         end
    end
    
end




















