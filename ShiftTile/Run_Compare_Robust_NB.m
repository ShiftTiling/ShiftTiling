function Run_Compare_Robust_NB(inputPath,outputPath,userLst,videoid,seconds,shifttilePath,img_Height,img_Width,img_Gap_Height,img_Gap_Width)

Codec = 265;
if Codec == 265
    Codec_Path = '265';
else
    Codec_Path = '';
end

%视点修改为2维的视点，实时读取viewport文件
%由于这个版本直接在ERP切，因而可以直接取
realViewpoint = struct2cell(load([shifttilePath,'data2D\',num2str(videoid),'.mat']));
realViewpoint = realViewpoint{1};
%存储和userLst一样长度的元素 对应clusterLst里面的
[userNumber,~] = size(realViewpoint);
trainingUserIndex = [];%clusterLst是针对trainingUser的
testingUserIndex = [];
for i = 1:userNumber
    if sum(userLst==(i-1))==0
        testingUserIndex = [testingUserIndex,i];
    else
        trainingUserIndex = [trainingUserIndex,i];
    end
end

ShiftTilingStreamingMethod = uint8(cell2mat(struct2cell(load([shifttilePath,'streamingMethod/Shift/',num2str(videoid),'.mat']))));
%这里开始真正计算码率,写完这个程序计算一下PSNR的差距
X_BandWidth_Shift = [];
X_BandWidth_Clus = [];
Y_PSNR_Shift = [];
Y_PSNR_Clus =[];
X_BandWidth_Grid = [];
Y_PSNR_Grid = [];
X_BandWidth_Sphere = [];
Y_PSNR_Shift_Sphere = [];
X_BandWidth_Op = [];
Y_PSNR_Shift_Op = [];
X_BandWidth_Flare = [];
Y_PSNR_Shift_Flare = [];
%开始Evaluation
video_raw = VideoReader([inputPath,'sourceVideo\',num2str(videoid),'_',num2str(seconds-1),'.mp4']);
Height = video_raw.Height;
Width = video_raw.Width;
Gap_Height = floor(Height / 15);
Gap_Width = floor(Width / 30);
H = video_raw.Height;
W = video_raw.Width;
%video_raw = VideoReader(['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\ShiftSourceVideo\',num2str(videoid),'_XX30_',num2str(0),'.mp4']);
img_raw = cell(30,1);
for f = 1:30
    img_raw{f,1}=uint8(rgb2gray(read(video_raw, f)));
end

fname = [outputPath,'outputVideo\BaseVideo_qp42\',num2str(videoid),'_',num2str(seconds-1),'_base_0.mp4'];
if ~exist(fname,'file')
    md([outputPath,'outputVideo',Codec_Path,'\BaseVideo_qp42']);
    base_H = ceil(H/4);
    base_W = ceil(W/4);
    if mod(base_H,2)~=0
        base_H = base_H -1;
    end
    if mod(base_W,2)~=0
        base_W = base_W -1;
    end
    if Codec == 265
         command = ['ffmpeg -i ',inputPath,'sourceVideo\',num2str(videoid),'_',num2str(seconds-1),'.mp4',...
            '  -an -x265-params qp=',num2str(42),':keyint=30:fps=30 -s ',num2str(base_W),'x',num2str(base_H),' -f segment ',...
            '-segment_list ',outputPath,'outputVideo',Codec_Path,'\BaseVideo_qp42\',num2str(videoid),'_',num2str(seconds-1),'_base.m3u8 ','-segment_time 1 ',...
            outputPath,'outputVideo',Codec_Path,'\BaseVideo_qp42\',num2str(videoid),'_',num2str(seconds-1),'_base_%d.mp4'];
    else
        command = ['ffmpeg -i ',inputPath,'sourceVideo\',num2str(videoid),'_',num2str(seconds-1),'.mp4',...
            ' -an  -c:v libx264 -qp ',num2str(42),' -g 30 -s ',num2str(base_W),'x',num2str(base_H),' -f segment ',...
            '-segment_list ',outputPath,'outputVideo\BaseVideo_qp42\',num2str(videoid),'_',num2str(seconds-1),'_base.m3u8 ','-segment_time 1 ',...
            outputPath,'outputVideo\BaseVideo_qp42\',num2str(videoid),'_',num2str(seconds-1),'_base_%d.mp4'];
    end
    system(command);
end

video_baseLayer = VideoReader(fname);
fid = fopen(fname);
fseek(fid,0,'eof');
fsize_base = ftell(fid);
fsize_base = fsize_base / 1024;
fsize_base =  fsize_base * 8;
fclose(fid);
img_Shift = cell(30,1);
img_Clus = cell(30,1);
img_Grid = cell(30,1);
img_op = cell(30,1);
img_flare = cell(30,1);

for f = 1:30
    temp = uint8(rgb2gray(imresize(read(video_baseLayer,f),[H,W])));
    img_Shift{f,1} = temp;
    img_Clus{f,1} = temp;
    img_Grid{f,1} = temp;
    img_op{f,1} = temp;
    img_flare{f,1} = temp;
end


for uN = testingUserIndex
  %  try
        %计算shifttile的码率
        idx1 = ShiftTilingStreamingMethod(:,1)==seconds;
        idx2 = ShiftTilingStreamingMethod(:,2)==uN;
        select_cluster =  ShiftTilingStreamingMethod(idx1&idx2,3);
        fre = ShiftTilingStreamingMethod(idx1&idx2,4);
        frameGap = 30;
        matData2 = load([shifttilePath,  num2str(frameGap),'_TilingMethod/' , num2str(videoid) ,'_',num2str(fre),'.mat']);
        tilingMethod = matData2.Method;
        % 15*30的补充粒度，12*24的补充粒度，6*12的补充粒度，8*16的补充粒度
        Shift_Robust = uint8(cell2mat(struct2cell(load([shifttilePath,'robustMethod/Shift/',num2str(fre),'_',num2str(videoid),'_',num2str(seconds-1),'_',num2str(uN),'.mat'])))); % 15*30粒度
        %Shift_Robust_6_12 = uint8(cell2mat(struct2cell(load(['robustMethod/Shift/',num2str(fre),'_',num2str(videoid),'_',num2str(uN),'_6_12.mat'))));
        Clus_Robust = zeros(15,30);%uint8(cell2mat(struct2cell(load(['robustMethod/Clus/',num2str(fre),'_',num2str(videoid),'_',num2str(seconds-1),'_',num2str(uN),'.mat'])))); % 15*30粒度
        %求和当前s真实视点的补集
        
        
        tM =  uint8(squeeze(tilingMethod(seconds,select_cluster,:,:,:)));
        shifttile_logic = uint8(zeros(30,H,W)); %用来评价ShiftTile
        for frame = 1:30
            for i = 1:72
                for j = 1:144
                    if (tM(frame,i,j)==1)
                        shifttile_logic(frame,(ceil((i-1)*img_Gap_Height)+1:min(ceil(i*img_Gap_Height),img_Height)), (ceil((j-1)*img_Gap_Width)+1:min(ceil(j*img_Gap_Width),img_Width)) ) = 1;
                    end
                end
            end
        end
        

        
        for qp =22:5:42 %这里的码率分配策略过于简单，亟待修改！！！！ 对应五档码率
            %% shiftTile
            fname = [outputPath,'outputVideo',Codec_Path,'/Shift/',num2str(videoid),'/',num2str(fre),'_',num2str(select_cluster),'_',num2str(seconds-1),'_',num2str(qp), '_0.mp4'];
            if ~exist([outputPath,'outputVideo',Codec_Path,'/Shift/',num2str(videoid),'/'],'dir')
                md([outputPath,'outputVideo',Codec_Path,'/Shift/',num2str(videoid),'/'])
            end
            if ~exist(fname,'file') %不存在22就会把22-42都编了
                encodeShiftVideo(inputPath,outputPath,videoid,seconds,fre,select_cluster);
            end
            
            fid = fopen(fname);
            fseek(fid,0,'eof');
            fsize_ShiftPredict = ftell(fid);
            fsize_ShiftPredict = fsize_ShiftPredict / 1024;
            fsize_ShiftPredict =  fsize_ShiftPredict * 8;
            fclose(fid);

            
            test_15_30= 0;
            test_6_12 = 0;
            %增强ShifTile鲁棒性,使用小网格
            for i = 1:15
                for j = 1:30
                    if Shift_Robust(i,j)==1
                        temp = [double(i-1)*Gap_Height,double(j-1)*Gap_Width,Gap_Height,Gap_Width];
                        fname_i = [outputPath,'outputVideo',Codec_Path,'/Shift_Staic/',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '_h264.mp4'];
                        if ~exist(fname_i,'file')
                            if ~exist([outputPath,'outputVideo',Codec_Path,'/Shift_Staic/',num2str(videoid),'/'],'dir')
                                md([outputPath,'outputVideo',Codec_Path,'/Shift_Staic/',num2str(videoid),'/'])
                            end
                            if Codec == 265
                                  command = ['ffmpeg -i ',inputPath,'sourceVideo\',...
                                    num2str(videoid),'_',num2str(seconds-1),'.mp4  -an -loglevel quiet  -c:v libx265  -x265-params qp=',num2str(qp),':keyint=30:fps=30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                                    num2str(temp(1)),' -f hevc ',outputPath,'outputVideo',Codec_Path,'/Shift_Staic/',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '_hevc.hevc'];
                            else
                                command = ['ffmpeg -i ',inputPath,'sourceVideo\',...
                                    num2str(videoid),'_',num2str(seconds-1),'.mp4  -an -loglevel quiet  -c:v libx264  -qp ',num2str(qp),' -g 30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                                    num2str(temp(1)),' -f h264 ',outputPath,'outputVideo',Codec_Path,'/Shift_Staic/',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '_h264.mp4'];
                            end
                            system(command);
                        end
                    end
                end
            end
            
            for i = 1:15
                for j = 1:30
                    if Shift_Robust(i,j)==1
                        temp = [double(i-1)*Gap_Height,double(j-1)*Gap_Width,Gap_Height,Gap_Width];
                        fname_i = [outputPath,'outputVideo',Codec_Path,'/Shift_Staic/',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '_h264.mp4'];
                        fid = fopen(fname_i);
                        fseek(fid,0,'eof');
                        fsize = ftell(fid);
                        fclose(fid);
                        fsize = fsize /1024;
                        fsize = fsize * 8;
                        fsize_ShiftPredict =  fsize_ShiftPredict + fsize;
                        test_15_30 = test_15_30 +fsize;
                        
                        video_Shift = VideoReader(fname_i);
                        temp(1) = temp(1) + 1;
                        temp(2) = temp(2) + 1;
                        for f = 1:30
                            frame = uint8(rgb2gray(read(video_Shift, f)));
                            img_Shift{f,1}(temp(1) : temp(1) + temp(3) - 1, temp(2) : temp(2) + temp(4) - 1) = frame;
                            clear frame;
                        end
                        clear video_Shift;
                    end
                end
            end
            %
            %
            %
            %增强ShifTile鲁棒性6_12
            %             for i = 1:6
            %                 for j = 1:12
            %                     if Shift_Robust_6_12(uN,i,j)==1
            %                         Gap_H = floor(H/6);
            %                         if mod(Gap_H,2)~=0
            %                             Gap_H = Gap_H -1;
            %                         end
            %                         Gap_W = floor(W/12);
            %                         if mod(Gap_W,2)~=0
            %                             Gap_W = Gap_W -1;
            %                         end
            %                         temp = [double(i-1)*Gap_H,double(j-1)*Gap_W,Gap_H,Gap_W];
            %                         fname_i = ['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
            %                         if ~exist(fname_i,'file')
            %                             md(['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\'])
            %                             command = ['ffmpeg -i H:\comparing-trajectory-clustering-methods-master',...
            %                                 '\comparing-trajectory-clustering-methods-master\CostEstimation\video\ClusSourceVideo\',...
            %                                 num2str(videoid),'_XX30_',num2str(seconds-1),'.mp4  -an -loglevel quiet  -c:v libx264  -qp ',num2str(qp),' -g 30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
            %                                 num2str(temp(1)),' H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
            %                             system(command)
            %                         end
            %                     end
            %                 end
            %             end
            
            %             t6 = 0;
            %             for i = 1:6
            %                 for j = 1:12
            %                     if Shift_Robust_6_12(uN,i,j)==1
            %                         try
            %                             Gap_H = floor(H/6);
            %                             if mod(Gap_H,2)~=0
            %                                 Gap_H = Gap_H -1;
            %                             end
            %                             Gap_W = floor(W/12);
            %                             if mod(Gap_W,2)~=0
            %                                 Gap_W = Gap_W -1;
            %                             end
            %                             temp = [double(i-1)*Gap_H,double(j-1)*Gap_W,Gap_H,Gap_W];
            %                             fname_i = ['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
            %                             fid = fopen(fname_i);
            %                             fseek(fid,0,'eof');
            %                             fsize = ftell(fid);
            %                             fclose(fid);
            %                             fsize = fsize /1024;
            %                             fsize = fsize * 8;
            %                             %fsize_ShiftPredict =  fsize_ShiftPredict + fsize;
            %                             t6 = t6 + fsize;
            %                             video_Shift = VideoReader(fname_i);
            %                             temp(1) = temp(1) + 1;
            %                             temp(2) = temp(2) + 1;
            %                             for f = 1:30
            %                                 frame = uint8(rgb2gray(read(video_Shift, f)));
            %                                 img_Shift{f,1}(temp(1) : temp(1) + temp(3) - 1, temp(2) : temp(2) + temp(4) - 1) = frame;
            %                             end
            %                         catch
            %                             continue
            %                         end
            %                     end
            %                 end
            %             end
            
            
            
            
            
    
            command  =['del D:\tempData\',num2str(videoid),'_',num2str(fre),'_',num2str(select_cluster),'_',num2str(seconds-1),'_',num2str(qp),'_*.* /q'];
            system(command);
            
            %% 6*12
            Grid_6_12 = uint8(cell2mat(struct2cell(load([shifttilePath,'streamingMethod/grid6_12/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(uN),'.mat']))));
            for i = 1:6
                for j = 1:12
                    if Grid_6_12(i,j)==1
                        Gap_H = floor(H/6);
                        if mod(Gap_H,2)~=0
                            Gap_H = Gap_H -1;
                        end
                        Gap_W = floor(W/12);
                        if mod(Gap_W,2)~=0
                            Gap_W = Gap_W -1;
                        end
                        temp = [double(i-1)*Gap_H,double(j-1)*Gap_W,Gap_H,Gap_W];
                        fname_i = [outputPath,'outputVideo',Codec_Path,'/Grid_6_12/',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                        if ~exist(fname_i,'file')
                            md([outputPath,'outputVideo',Codec_Path,'/Grid_6_12/',num2str(videoid),'/'])
                            if Codec == 265
                                command = ['ffmpeg -i ',inputPath,'sourceVideo\',num2str(videoid),'_',num2str(seconds-1),'.mp4 -an -loglevel quiet -c:v libx265  -x265-params qp=',num2str(qp),':keyint=30:fps=30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                                    num2str(temp(1)),' ',outputPath,'outputVideo',Codec_Path,'/Grid_6_12/',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                            else
                                command = ['ffmpeg -i ',inputPath,'sourceVideo\',num2str(videoid),'_',num2str(seconds-1),'.mp4 -an -loglevel quiet  -c:v libx264  -qp ',num2str(qp),' -g 30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                                    num2str(temp(1)),' ',outputPath,'outputVideo',Codec_Path,'/Grid_6_12/',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                            end
                            system(command);
                        end
                    end
                end
            end
            
            test_6_12 = 0;
            for i = 1:6
                for j = 1:12
                    if Grid_6_12(i,j)==1
                        % try
                        Gap_H = floor(H/6);
                        if mod(Gap_H,2)~=0
                            Gap_H = Gap_H -1;
                        end
                        Gap_W = floor(W/12);
                        if mod(Gap_W,2)~=0
                            Gap_W = Gap_W -1;
                        end
                        temp = [double(i-1)*Gap_H,double(j-1)*Gap_W,Gap_H,Gap_W];
                        fname_i = [outputPath,'/outputVideo',Codec_Path,'/Grid_6_12/',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                        fid = fopen(fname_i);
                        fseek(fid,0,'eof');
                        fsize = ftell(fid);
                        fclose(fid);
                        fsize = fsize /1024;
                        fsize = fsize * 8;
                        test_6_12 = test_6_12 + fsize;
                        video_Shift = VideoReader(fname_i);
                        temp(1) = temp(1) + 1;
                        temp(2) = temp(2) + 1;
                        for f = 1:30
                            frame = uint8(rgb2gray(read(video_Shift, f)));
                            img_Grid{f,1}(temp(1) : temp(1) + temp(3) - 1, temp(2) : temp(2) + temp(4) - 1) = frame;
                            clear frame;
                        end
                        clear video_Shift;
                        %                     catch
                        %                         continue
                        %                     end
                    end
                end
            end
            %% flare
            mm =4;
            nn =6;
            Grid_4_6 = uint8(cell2mat(struct2cell(load([shifttilePath,'streamingMethod/grid4_6/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(uN),'.mat']))));
            for i = 1:mm
                for j = 1:nn
                    if Grid_4_6(i,j)==1
                        Gap_H = floor(H/mm);
                        if mod(Gap_H,2)~=0
                            Gap_H = Gap_H -1;
                        end
                        Gap_W = floor(W/nn);
                        if mod(Gap_W,2)~=0
                            Gap_W = Gap_W -1;
                        end
                        temp = [double(i-1)*Gap_H,double(j-1)*Gap_W,Gap_H,Gap_W];
                        fname_i = [outputPath,'outputVideo',Codec_Path,'/Grid_4_6/',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                        if ~exist(fname_i,'file')
                            md([outputPath,'outputVideo',Codec_Path,'/Grid_4_6/',num2str(videoid),'/'])
                            if Codec == 265
                                 command = ['ffmpeg -i ',inputPath,'sourceVideo\',num2str(videoid),'_',num2str(seconds-1),'.mp4 -an -loglevel quiet  -c:v libx265  -x265-params qp=',num2str(qp),':keyint=30:fps=30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                                    num2str(temp(1)),' ',outputPath,'outputVideo',Codec_Path,'/Grid_4_6/',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                            else
                                command = ['ffmpeg -i ',inputPath,'sourceVideo\',num2str(videoid),'_',num2str(seconds-1),'.mp4 -an -loglevel quiet  -c:v libx264  -qp ',num2str(qp),' -g 30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                                    num2str(temp(1)),' ',outputPath,'outputVideo',Codec_Path,'/Grid_4_6/',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                            end
                            system(command);
                        end
                    end
                end
            end
            
            test_flare = 0;
            for i = 1:mm
                for j = 1:nn
                    if Grid_4_6(i,j)==1
                        % try
                        Gap_H = floor(H/mm);
                        if mod(Gap_H,2)~=0
                            Gap_H = Gap_H -1;
                        end
                        Gap_W = floor(W/nn);
                        if mod(Gap_W,2)~=0
                            Gap_W = Gap_W -1;
                        end
                        temp = [double(i-1)*Gap_H,double(j-1)*Gap_W,Gap_H,Gap_W];
                        fname_i = [outputPath,'/outputVideo',Codec_Path,'/Grid_4_6/',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                        fid = fopen(fname_i);
                        fseek(fid,0,'eof');
                        fsize = ftell(fid);
                        fclose(fid);
                        fsize = fsize /1024;
                        fsize = fsize * 8;
                        test_flare = test_flare + fsize;
                        video_Shift = VideoReader(fname_i);
                        temp(1) = temp(1) + 1;
                        temp(2) = temp(2) + 1;
                        for f = 1:30
                            frame = uint8(rgb2gray(read(video_Shift, f)));
                            img_flare{f,1}(temp(1) : temp(1) + temp(3) - 1, temp(2) : temp(2) + temp(4) - 1) = frame;
                            clear frame;
                        end
                        clear video_Shift;
                        %                     catch
                        %                         continue
                        %                     end
                    end
                end
            end
            %% clusTile
            data_old = cell2mat(struct2cell(load([shifttilePath,'streamingMethod\ClusTile\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(uN),'.mat'])));
            [x, y] = size(data_old);
            data_old = data_old;
            fsize_ClusPredict = 0;
            
            for i =1:x
                
                if (data_old(i,3)>=30)
                    data_old(i,3) = data_old(i,3) -30;
                    data_old(i,4) = data_old(i,4) -30;
                end
            end
            
            for i =1:x
                temp = [double(data_old(i,1))*Gap_Height,double(data_old(i,3))*Gap_Width,double(data_old(i,2)-data_old(i,1)+1)*Gap_Height,double(data_old(i,4)-data_old(i,3)+1)*Gap_Width];
                fname_i = [outputPath,'outputVideo',Codec_Path,'/clusTile/',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                if ~exist(fname_i,'file')
                    md([outputPath,'outputVideo',Codec_Path,'/clusTile/',num2str(videoid),'\'])
                    if Codec == 265
                        command = ['ffmpeg -i ',inputPath,'sourceVideo\',num2str(videoid),'_',num2str(seconds-1),'.mp4 -an -loglevel quiet  -c:v libx265  -x265-params qp=',num2str(qp),':keyint=30:fps=30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                            num2str(temp(1)),' ',outputPath,'outputVideo',Codec_Path,'/clusTile/',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                    else
                        command = ['ffmpeg -i ',inputPath,'sourceVideo\',num2str(videoid),'_',num2str(seconds-1),'.mp4 -an -loglevel quiet  -c:v libx264  -qp ',num2str(qp),' -g 30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                            num2str(temp(1)),' ',outputPath,'outputVideo',Codec_Path,'/clusTile/',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                    end
                    system(command);
                end
            end
            
            for i =1:x
                temp = [double(data_old(i,1))*Gap_Height,double(data_old(i,3))*Gap_Width,double(data_old(i,2)-data_old(i,1)+1)*Gap_Height,double(data_old(i,4)-data_old(i,3)+1)*Gap_Width];
                fname_i = [outputPath,'outputVideo',Codec_Path,'/clusTile/',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                fid = fopen(fname_i);
                fseek(fid,0,'eof');
                fsize = ftell(fid);
                fclose(fid);
                fsize = fsize /1024;
                fsize = fsize*8;
                fsize_ClusPredict =  fsize_ClusPredict + fsize;
                video_Clus = VideoReader(fname_i);
                temp(1) = temp(1) + 1;
                temp(2) = temp(2) + 1;
                for f = 1:30
                    frame = uint8(rgb2gray(read(video_Clus, f)));
                    img_Clus{f,1}(temp(1) : temp(1) + temp(3) - 1, temp(2) : temp(2) + temp(4) - 1) = frame;
                    clear frame;
                end
                clear video_Clus;
            end
            
            %增强ClusTile鲁棒性
            for i = 1:15
                for j = 1:30
                    if Clus_Robust(i,j)==1
                        temp = [double(i-1)*Gap_Height,double(j-1)*Gap_Width,Gap_Height,Gap_Width];
                        fname_i = [outputPath,'outputVideo',Codec_Path,'/clusTile/',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                        if ~exist(fname_i,'file')
                            md([outputPath,'outputVideo',Codec_Path,'/clusTile/',num2str(videoid)])
                            if Codec == 265
                                 command = ['ffmpeg -i ',inputPath,'sourceVideo\',num2str(videoid),'_',num2str(seconds-1),'.mp4  -an -loglevel quiet -c:v libx265 -x265-params qp=',num2str(qp),':keyint=30:fps=30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                                    num2str(temp(1)),' ',outputPath,'outputVideo',Codec_Path,'/clusTile/',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                            else
                                command = ['ffmpeg -i ',inputPath,'sourceVideo\',num2str(videoid),'_',num2str(seconds-1),'.mp4  -an -loglevel quiet  -c:v libx264  -qp ',num2str(qp),' -g 30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                                    num2str(temp(1)),' ',outputPath,'outputVideo',Codec_Path,'/clusTile/',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                            end
                            system(command);
                        end
                    end
                end
            end
            
            for i = 1:15
                for j = 1:30
                    if Clus_Robust(i,j)==1
                        temp = [double(i-1)*Gap_Height,double(j-1)*Gap_Width,Gap_Height,Gap_Width];
                        fname_i = [outputPath,'outputVideo',Codec_Path,'/clusTile/',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                        fid = fopen(fname_i);
                        fseek(fid,0,'eof');
                        fsize = ftell(fid);
                        fclose(fid);
                        fsize = fsize /1024;
                        fsize = fsize*8;
                        fsize_ClusPredict =  fsize_ClusPredict + fsize;
                        video_Clus = VideoReader(fname_i);
                        temp(1) = temp(1) + 1;
                        temp(2) = temp(2) + 1;
                        for f = 1:30
                            frame = uint8(rgb2gray(read(video_Clus, f)));
                            img_Clus{f,1}(temp(1) : temp(1) + temp(3) - 1, temp(2) : temp(2) + temp(4) - 1) = frame;
                            clear frame;
                        end
                        clear img_Clus;
                    end
                end
            end
            %% opTile
    
            data_old = cell2mat(struct2cell(load([shifttilePath,'streamingMethod\OpTile\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(uN),'.mat'])));
            [x, y] = size(data_old);
            fsize_opPredict = 0;
            data_old = data_old -1;
            
            for i =1:x
                if (data_old(i,3)>=30)
                    data_old(i,3) = data_old(i,3) -30;
                    data_old(i,4) = data_old(i,4) -30;
                end
            end
            
            for i =1:x
                temp = [double(data_old(i,1))*Gap_Height,double(data_old(i,3))*Gap_Width,double(data_old(i,2)-data_old(i,1)+1)*Gap_Height,double(data_old(i,4)-data_old(i,3)+1)*Gap_Width];
                fname_i = [outputPath,'outputVideo',Codec_Path,'/opTile/',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                if ~exist(fname_i,'file')
                    md([outputPath,'outputVideo',Codec_Path,'/opTile/',num2str(videoid),'\'])
                    if Codec == 265
                        command = ['ffmpeg -i ',inputPath,'sourceVideo\',num2str(videoid),'_',num2str(seconds-1),'.mp4 -an -loglevel quiet  -c:v libx265  -x265-params qp=',num2str(qp),':keyint=30:fps=30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                            num2str(temp(1)),' ',outputPath,'outputVideo',Codec_Path,'/opTile/',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                    else
                        command = ['ffmpeg -i ',inputPath,'sourceVideo\',num2str(videoid),'_',num2str(seconds-1),'.mp4 -an -loglevel quiet  -c:v libx264  -qp ',num2str(qp),' -g 30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                            num2str(temp(1)),' ',outputPath,'outputVideo',Codec_Path,'/opTile/',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                    end
                    system(command);
                end
            end
            
            for i =1:x
                temp = [double(data_old(i,1))*Gap_Height,double(data_old(i,3))*Gap_Width,double(data_old(i,2)-data_old(i,1)+1)*Gap_Height,double(data_old(i,4)-data_old(i,3)+1)*Gap_Width];
                fname_i = [outputPath,'outputVideo',Codec_Path,'/opTile/',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                fid = fopen(fname_i);
                fseek(fid,0,'eof');
                fsize = ftell(fid);
                fclose(fid);
                fsize = fsize /1024;
                fsize = fsize*8;
                fsize_opPredict =  fsize_opPredict + fsize;
                video_Clus = VideoReader(fname_i);
                temp(1) = temp(1) + 1;
                temp(2) = temp(2) + 1;
                for f = 1:30
                    frame = uint8(rgb2gray(read(video_Clus, f)));
                    img_op{f,1}(temp(1) : temp(1) + temp(3) - 1, temp(2) : temp(2) + temp(4) - 1) = frame;
                    clear frame;
                end
                clear video_Clus;
            end
            %%
            if fsize_ClusPredict>1000000 || fsize_ClusPredict<=50
                continue
            end
            
            

            
            currentE = realViewpoint{uN}(:,(seconds-1)*30+1:seconds*30); %2*30的矩阵，第一行width,第二行height
            p1 = [];
            p2 = [];
            p3 = [];
            p4 = [];
            p5 = [];
%             s = [];
%             c = [];
            MSE_Shift =0;
            MSE_Clus = 0;
            MSE_Grid = 0;
            MSE_Op =0;
            MSE_flare = 0;
            for f = 1:30
                FOV = load(['D:\PreViewport\',num2str(H),'_',num2str(W),'\',num2str(ceil(currentE(2,ceil(f/2))*72)),'_',num2str(ceil(currentE(1,ceil(f/2))*144)),'.mat']);
                FOV = FOV.a;
                raw_frame = img_raw{f,1}(FOV);
                [x,y] =size(raw_frame);
                v = ones(x,y);
                shift_frame = img_Shift{f,1}(FOV);
                clus_frame = img_Clus{f,1}(FOV);
                grid_frame = img_Grid{f,1}(FOV);
                flare_frame = img_flare{f,1}(FOV);
                op_frame  = img_op{f,1}(FOV);
                %             figure,imshow(shift_frame,[]);
                %             figure,imshow(clus_frame,[]);
                %             figure,imshow(grid_frame,[]);
                [p, temp_shift] = Psnr(raw_frame,shift_frame,v);
                [pp, temp_clus] = Psnr(raw_frame,clus_frame ,v);
                [ppp, temp_grid] = Psnr(raw_frame,grid_frame,v);
                [pppp, temp_flare] = Psnr(raw_frame,flare_frame,v);
                [ppppp, temp_op] = Psnr(raw_frame,op_frame,v);
%                 p1 =[p1,p];
%                 p2 = [p2,pp];
%                 p3 = [p3,ppp];
%                 p4 = [p4,pppp];
%                 p5 = [p5,ppppp];
%                 s = [s,temp_shift];
%                 c = [c, temp_clus];
                MSE_Shift = MSE_Shift + temp_shift;
                MSE_Clus = MSE_Clus + temp_clus;
                MSE_Grid = MSE_Grid + temp_grid;
                MSE_Op = MSE_Op + temp_op;
                MSE_flare = MSE_flare +temp_flare;
                clear  raw_frame  shift_frame clus_frame grid_frame FOV;
            end
            
            
            
            psnr_Shift = 10*log10(255^2 / (MSE_Shift/30));
            psnr_Clus = 10*log10(255^2 / (MSE_Clus/30));
            psnr_Grid = 10*log10(255^2 / (MSE_Grid/30));
            psnr_op = 10*log10(255^2 / (MSE_Op/30));
            psnr_flare = 10*log10(255^2 / (MSE_flare/30));
            %Debug = [Debug;double(seconds),double(uN),double(select_cluster),double(max_cover), double(c) ,double(cover_ratio)];
            
            fname_sphere = [outputPath,'outputVideo',Codec_Path,'/Shift_Sphere/',num2str(videoid),'/',num2str(fre),'_',num2str(select_cluster),'_',num2str(seconds-1),'_',num2str(qp), '_0.mp4'];
            fid = fopen(fname_sphere);
            fseek(fid,0,'eof');
            fsize_SpherePredict = ftell(fid);
            fsize_SpherePredict =fsize_SpherePredict/ 1024;
            fsize_SpherePredict=  fsize_SpherePredict* 8;
            
            X_BandWidth_Shift = [X_BandWidth_Shift,(fsize_ShiftPredict)+fsize_base];
            X_BandWidth_Clus = [X_BandWidth_Clus,fsize_ClusPredict+fsize_base];
            X_BandWidth_Grid = [X_BandWidth_Grid,test_6_12+fsize_base];
            X_BandWidth_Sphere = [X_BandWidth_Sphere,(fsize_SpherePredict)+fsize_base];
            Y_PSNR_Shift_Sphere = [Y_PSNR_Shift_Sphere,psnr_Shift];
            Y_PSNR_Shift = [Y_PSNR_Shift,psnr_Shift];
            Y_PSNR_Clus =[Y_PSNR_Clus,min(psnr_Clus,psnr_flare)];
            Y_PSNR_Grid = [Y_PSNR_Grid,psnr_Grid];
            X_BandWidth_Op = [X_BandWidth_Op, fsize_opPredict+fsize_base];
            Y_PSNR_Shift_Op = [Y_PSNR_Shift_Op,min(psnr_op,psnr_flare)];
            X_BandWidth_Flare = [X_BandWidth_Flare,test_flare+fsize_base];
            Y_PSNR_Shift_Flare = [Y_PSNR_Shift_Flare,psnr_flare];
        end
        clear idx1 idx2 matData2 tilingMethod Shift_Robust  Clus_Robust tM  shifttile_logic;
%     catch
%         continue
%     end
    
end


md(['Result_Tradeoff',Codec_Path,'/',num2str(videoid),'/'])
save(['Result_Tradeoff',Codec_Path,'/',num2str(videoid),'/',num2str(seconds-1),'_XShift.mat'],'X_BandWidth_Shift')
save(['Result_Tradeoff',Codec_Path,'/',num2str(videoid),'/',num2str(seconds-1),'_YShift.mat'],'Y_PSNR_Shift')
save(['Result_Tradeoff',Codec_Path,'/',num2str(videoid),'/',num2str(seconds-1),'_XClus.mat'],'X_BandWidth_Clus')
save(['Result_Tradeoff',Codec_Path,'/',num2str(videoid),'/',num2str(seconds-1),'_YClus.mat'],'Y_PSNR_Clus')
save(['Result_Tradeoff',Codec_Path,'/',num2str(videoid),'/',num2str(seconds-1),'_XGrid.mat'],'X_BandWidth_Grid')
save(['Result_Tradeoff',Codec_Path,'/',num2str(videoid),'/',num2str(seconds-1),'_YGrid.mat'],'Y_PSNR_Grid')
save(['Result_Tradeoff',Codec_Path,'/',num2str(videoid),'/',num2str(seconds-1),'_XSphere.mat'],'X_BandWidth_Sphere')
save(['Result_Tradeoff',Codec_Path,'/',num2str(videoid),'/',num2str(seconds-1),'_YSphere.mat'],'Y_PSNR_Shift_Sphere')
save(['Result_Tradeoff',Codec_Path,'/',num2str(videoid),'/',num2str(seconds-1),'_XOp.mat'],'X_BandWidth_Op')
save(['Result_Tradeoff',Codec_Path,'/',num2str(videoid),'/',num2str(seconds-1),'_YOp.mat'],'Y_PSNR_Shift_Op')
save(['Result_Tradeoff',Codec_Path,'/',num2str(videoid),'/',num2str(seconds-1),'_XFlare.mat'],'X_BandWidth_Flare')
save(['Result_Tradeoff',Codec_Path,'/',num2str(videoid),'/',num2str(seconds-1),'_YFlare.mat'],'Y_PSNR_Shift_Flare')
clear all;
clear functions;
end

function [PSNR, MSE] = Psnr(X, Y, V)
LASTN = maxNumCompThreads(2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 计算峰值信噪比PSNR
% 将RGB转成YCbCr格式进行计算
% 如果直接计算会比转后计算值要小2dB左右（当然是个别测试）
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if size(X,3)~=1   %判断图像时不是彩色图，如果是，结果为3，否则为1
    org=rgb2ycbcr(X);
    test=rgb2ycbcr(Y);
    Y1=org(:,:,1);
    Y2=test(:,:,1);
    Y1=double(Y1);  %计算平方时候需要转成double类型，否则uchar类型会丢失数据
    Y2=double(Y2);
else              %灰度图像，不用转换
    Y1=double(X);
    Y2=double(Y);
end
Y1 = Y1.*V;
Y2 = Y2.*V;
if nargin<2
    D = Y1;
else
    if any(size(Y1)~=size(Y2))
        error('The input size is not equal to each other!');
    end
    D = Y1 - Y2;
end
MSE = sum(D(:).*D(:)) / sum(sum(V>0));
PSNR = 10*log10(255^2 / MSE);
end


function md(path)
if ~exist(path,'dir')
    mkdir(path)
end
end
