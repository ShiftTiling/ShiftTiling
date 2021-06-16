%本程序 用于输出 需要的C矩阵，前提是CostEstimation程序运行完毕，切块程序运行完毕 StartRow 下表从0开始
clear all;
close all;
clc;


H = 15;
W = 30;

for videoid = VideoIndex
    obj = VideoReader(['J:\video\RawVideo\',sprintf('%03d',videoid),'.mp4']);
    Height = obj.Height;
    Width = obj.Width;
    
    fname_source = ['H:\comparing-trajectory-clustering-methods-master',...
        '\comparing-trajectory-clustering-methods-master\CostEstimation\video\ClusSourceVideo\out_',...
        num2str(videoid),'_XX30_',num2str(0),'.mp4'];
    
    if ~exist(fname_source,'file')
        command = ['ffmpeg -r 30 -i J:\video\RawVideo\',sprintf('%03d',videoid),'.mp4 -r 30 -an -c:v libx264 -qp 22 -g 30 -f segment -segment_list',' H:\comparing-trajectory-clustering-methods-master',...
            '\comparing-trajectory-clustering-methods-master\CostEstimation\video\ClusSourceVideo\out_',num2str(videoid),'_%d.m3u8 -segment_time 1',' ','H:\comparing-trajectory-clustering-methods-master',...
            '\comparing-trajectory-clustering-methods-master\CostEstimation\video\ClusSourceVideo\out_',...
            num2str(videoid),'_XX30_%d.mp4']
        system(command)
    end
    
    for seconds = SecondIndex
        try
            ['当前秒数：',num2str(seconds)]
            H = 15;
            W = 30;
            tic
            frameStart = (seconds-1)*30+1;
            MotionVector = load(['J:\视频评价调研Backup\simplest_ffmpeg_player-master\simplest_ffmpeg_player-master\ExtractMotionVector\',sprintf('%03d',videoid),'.mp4',num2str(frameStart),'.txt']);
            Gap_Height = floor(Height / H);
            Gap_Width  = floor(Width / W);
            
           
            src_H = MotionVector(:,6); src_W = MotionVector(:,5); dst_H = MotionVector(:,8); dst_W = MotionVector(:,7);
            
            for i = 1:H
                src_H(src_H>=(i-1)*Gap_Height+1 & src_H<= i*Gap_Height) = i; %下标从1开始
                dst_H(dst_H>=(i-1)*Gap_Height+1 & dst_H<= i*Gap_Height) = i;
            end
            
            for j = 1:W
                src_W(src_W>=(j-1)*Gap_Width+1 & src_W<= j*Gap_Width) = j;
                dst_W(dst_W>=(j-1)*Gap_Width+1 & dst_W<= j*Gap_Width) = j;
            end
            MotionVector(:,6) = src_H; MotionVector(:,5) = src_W; MotionVector(:,8) = dst_H; MotionVector(:,7) = dst_W;
            src_H = gpuArray(single(src_H));
            src_W = gpuArray(single(src_W));
            dst_W = gpuArray(single(dst_W));
            dst_H = gpuArray(single(dst_H));
            
            %try
            StartRow = 1;   %下表从0开始
            EndRow = 15;
            StartCol = 1;
            EndCol = 30;
            
            
            
            
            % 计算整个视频全编成一块的码率-----------------------------------------------------------------------------------
            fname_origin = ['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(0),'_',num2str(0),'_',num2str(double(H-1+1)*Gap_Height),'_',num2str(double(W-1+1)*Gap_Width),'_22.mp4'];
            if ~exist(fname_origin,'file')
                temp  = [0,0,double(H-1+1)*Gap_Height,double(W-1+1)*Gap_Width];
                qp =22;
                mkdir(['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\'])
                command = ['ffmpeg -i H:\comparing-trajectory-clustering-methods-master',...
                    '\comparing-trajectory-clustering-methods-master\CostEstimation\video\ClusSourceVideo\out_',...
                    num2str(videoid),'_XX30_',num2str(seconds-1),'.mp4  -an -c:v libx264  -qp ',num2str(qp),' -g 30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                    num2str(temp(1)),' H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                system(command)
            end
            fid = fopen(fname_origin);
            fseek(fid,0,'eof');
            fsize = ftell(fid);
            fclose(fid);
            Sorigin =  fsize/(1024);
            Sorigin = Sorigin*8;
            Stotal = 0;
            
            for r = 1:H
                for co = 1:W
                    fname_i = ['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str((r-1)*Gap_Height),'_',num2str((co-1)*Gap_Width),'_',num2str((r-r+1)*Gap_Height),'_',num2str((co-co+1)*Gap_Width),'_22.mp4'];
                    if ~exist(fname_i,'file')
                        temp  = [(r-1)*Gap_Height,(co-1)*Gap_Width,(r-r+1)*Gap_Height,(co-co+1)*Gap_Width];
                        qp =22;
                        mkdir(['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\'])
                        command = ['ffmpeg -i H:\comparing-trajectory-clustering-methods-master',...
                            '\comparing-trajectory-clustering-methods-master\CostEstimation\video\ClusSourceVideo\out_',...
                            num2str(videoid),'_XX30_',num2str(seconds-1),'.mp4  -an -c:v libx264  -qp ',num2str(qp),' -g 30 -vf crop=',num2str(temp(4)),':',num2str(temp(3)),':',num2str(temp(2)),':',...
                            num2str(temp(1)),' H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'_',num2str(qp), '.mp4'];
                        system(command)
                    end
                    fid = fopen(fname_i);
                    fseek(fid,0,'eof');
                    fsize = ftell(fid);
                    fclose(fid);
                    fsize = fsize /1024;
                    fsize = fsize*8;
                    Stotal =  Stotal + fsize;
                end
            end
            
            temp_Relocated = (dst_H>=1) & (dst_H<=H) & (dst_W>=1) & (dst_W<=W) & (dst_H ~= src_H | dst_W ~= src_W);
            temp_NonRelocated = (dst_H>=1) & (dst_H<=H) & (dst_W>=1) & (dst_W<=W) & (dst_H == src_H & dst_W == src_W);
            MotionVectorCount  = sum(temp_Relocated(:));
            NonLocatedMotionVector = sum(temp_NonRelocated(:));
            o = single(Stotal - Sorigin) / single(MotionVectorCount);
            % 计算整个视频全编成一块的码率-----------------------------------------------------------------------------------
            
            %需要输出每一个类别的总和码率，跨域motionVector，非跨域motionVector,整体降价比，块数n
            ttt = 0;
            
            for sR = StartRow:EndRow
                for eR = sR:EndRow
                    for sC = StartCol:EndCol
                        for eC = sC:EndCol
                            n = (eR - sR +1) * (eC -sC + 1);
                            if (n<4)
                                continue
                            end
                            ttt = ttt +1;
                        end
                    end
                end
            end
            
            result  = gpuArray(single(zeros(ttt,11)));
            BandWidth  = single(zeros(H, W));
            for r = StartRow:EndRow
                for co = StartCol:EndCol
                    fname_i = ['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(double(r-1)*Gap_Height),'_',num2str(double(co-1)*Gap_Width),'_',num2str(double(r-r+1)*Gap_Height),'_',num2str(double(co-co+1)*Gap_Width),'_22.mp4'];
                    fid = fopen(fname_i);
                    fseek(fid,0,'eof');
                    fsize = ftell(fid);
                    fclose(fid);
                    fsize = fsize /1024;
                    fsize = fsize * 8;
                    BandWidth(r,co) = fsize;
                end
            end
            
            ttt = 0;
            for sR = StartRow:EndRow
                for eR = sR:EndRow
                    for sC = StartCol:EndCol
                        for eC = sC:EndCol
                            n = (eR - sR +1) * (eC -sC + 1);
                            if (n<4)
                                continue
                            end
                            ttt
                            ttt = ttt +1;
          
                            fsize = 99999999;
                            %求真实码率
                            try
                                temp=[double(sR-1)*Gap_Height,double(sC-1)*Gap_Width,double(eR-sR+1)*Gap_Height,double(eC-sC+1)*Gap_Width];
                                fname_i = ['H:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'.mp4'];
                                fid = fopen(fname_i);
                                fseek(fid,0,'eof');
                                fsize = ftell(fid);
                                fclose(fid);
                                fsize = fsize /1024;
                                fsize = fsize * 8;
                            catch
                                fsize =99999999;
                            end
                            Stotal =  sum(sum(BandWidth(sR:eR,sC:eC)));
                            Smin  = min(min(BandWidth(sR:eR,sC:eC)));
                            if eC<=H
                                temp_middle = (dst_H>=(sR)) & (dst_H<=(eR)) & (dst_W>=(sC)) & (dst_W<=(eC));
                            else
                                temp_middle = (dst_H>=(sR)) & (dst_H<=(eR)) & (((dst_W>=(sC)) & (dst_W<=H)) |((dst_W>=1) & (dst_W<=eC)));
                            end
                            temp_middle2 = (dst_H ~= src_H) | (dst_W ~= src_W);
                            temp_Relocated = temp_middle & temp_middle2;
                            temp_NonRelocated = temp_middle & ~temp_middle2;
                            ri = sum(temp_Relocated);
                            mt = sum(temp_NonRelocated);
                            result(ttt,:) = [single(sR),single(eR),single(sC),single(eC),single(Stotal), single(ri) ,single(mt), single(o), single(n), single(Smin), single(fsize)];
                            
                        end
                    end
                end
            end
            
            result = gather(result);
            mkdir(['OutputPredictionData/' , num2str(videoid) ,'/', num2str(seconds-1),])
            dlmwrite(['OutputPredictionData/' , num2str(videoid) , '/' , num2str(seconds-1) , '/C_Input.txt'], result,' ')
            toc
            g=gpuDevice(1);    %会清空 GPU 1中的所有数据,,将GPU1 设为当前GPU
            reset(g)  %也可以清空GPU中数据。
            %                 catch
            %                     continue
            %                 end
            %
        catch
            continue
        end
    end
end