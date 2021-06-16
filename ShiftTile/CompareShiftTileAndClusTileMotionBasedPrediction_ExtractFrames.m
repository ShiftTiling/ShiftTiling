
clc;
clear all;
close all;

Height = 1440;     %帧高度
Width = 2880;     %帧宽度
V_Height = (Height/180*100)/2-1;%视窗高度
V_Width = (Width/360*100)/2-1; %视窗宽度
BasicWidth = 20;   %BasicTile宽度
UserNumber = 30;   %用户数量
frameGap = 30;     %帧率 30fps
H = Height / BasicWidth; %高有多少BasicTile
W = Width / BasicWidth;  %宽有多少BasicTile
vs = 1;             %视频开始id
ve = 1;             %视频结束id
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




















