%% Running grid storage encoding
clear all;
close all;
clc;
V_Height = (Height/180*100);%视窗高度
V_Width = (Width/360*100); %视窗宽度
BasicWidth = 20;   %BasicTile宽度
UserNumber = 30;   %用户数量
frameGap = 30;     %帧率 30fps
H = Height / BasicWidth; %高有多少BasicTile
W = Width / BasicWidth;  %宽有多少BasicTile
Gap_Width = 126;
Gap_Height = 126;

videoLst = cell2mat(struct2cell(load([ShiftTilingPath,'DataSetVideoIndex/VideoIndex.mat'])));
for LL = 1:length(videoLst)
    videoid = videoLst(LL);
    obj_raw = VideoReader(['D:\sourceVideo\',num2str(videoid),'_',num2str(0),'.mp4']);%输入视频位置
    H = obj_raw.Height;
    W = obj_raw.Width;
    for fre = cover_frequency:cover_frequency
        Execu(videoid,fre,H,W)
    end
    
end



function NotcompareIndex = Execu(videoid,fre,H,W)
inputPath = 'D:\'
outputPath = 'D:\Storage\';
mm = 6;
nn = 12;
for seconds = 3:60  %用t时刻预测 [t+3,t+4)时刻，下标从0开始
    [fre,seconds]
    if ~exist([inputPath,'sourceVideo\',num2str(videoid),'_',num2str(seconds-1),'.mp4'], 'file')
        continue
    end
    try
        for Codec = 264:265
            if Codec == 265
                Codec_Path = '265';
            else
                Codec_Path = '264';
            end
            for i = 1:mm
                for j = 1:nn
                    Gap_H = floor(H/mm);
                    if mod(Gap_H,2)~=0
                        Gap_H = Gap_H -1;
                    end
                    Gap_W = floor(W/nn);
                    if mod(Gap_W,2)~=0
                        Gap_W = Gap_W -1;
                    end
                    temp = [double(i-1)*Gap_H,double(j-1)*Gap_W,Gap_H,Gap_W];
                    for qp= 22:5:42
                        fname_i = [outputPath,'/outputVideo',Codec_Path,'/Grid_',num2str(mm),'_',num2str(nn),'/',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                        if ~exist(fname_i,'file')
                            mkdir([outputPath,'/outputVideo',Codec_Path,'/Grid_',num2str(mm),'_',num2str(nn),'/',num2str(videoid),'/'])
                            if Codec == 265
                                command = ['ffmpeg -i ',inputPath,'sourceVideo\',num2str(videoid),'_',num2str(seconds-1),'.mp4 -an  -c:v libx265  -x265-params qp=',num2str(qp),':keyint=30:fps=30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                                    num2str(temp(1)),' ',outputPath,'outputVideo',Codec_Path,'/Grid_6_12/',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                            else
                                command = ['ffmpeg -i ',inputPath,'sourceVideo\',num2str(videoid),'_',num2str(seconds-1),'.mp4 -an  -c:v libx264  -qp ',num2str(qp),' -g 30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                                    num2str(temp(1)),' ',outputPath,'outputVideo',Codec_Path,'/Grid_6_12/',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                            end
                            system(command)
                        end
                    end
                end
            end
        end
    catch
        continue
    end
end

end


function Store(a,path)
save(path,'a');
end
